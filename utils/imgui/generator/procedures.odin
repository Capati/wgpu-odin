package imgui_gen

// Packages
import "base:runtime"
import "core:encoding/json"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"

write_procedures :: proc(gen: ^Generator, handle: os.Handle, json_data: ^json.Value) {
	root := json_data.(json.Object)

	functions, functions_ok := root["functions"]
	assert(functions_ok, "Missing 'functions' root object! Ignoring...")

	ta := context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	// Functions to ignore can be missing definitions or wrapped
	functions_to_ignore := []string {
		"ImStr_FromCharStr", // where this is defined?
	}
	is_ignored_function :: #force_inline proc(functions: []string, name: string) -> bool {
		return slice.contains(functions, name)
	}

	// List of reserved names to replace
	reserved_name_map: map[string]string;reserved_name_map.allocator = ta
	reserved_name_map["in"] = "_in"

	// Start foreign block
	os.write_string(handle, "@(default_calling_convention = \"c\")\nforeign lib {\n")

	loop: for &function_entry in functions.(json.Array) {
		function_entry_obj := function_entry.(json.Object)
		assert(function_entry_obj != nil, "Missing function object!")

		// Ignore obsolete names
		if test_ifndef_condition(&function_entry_obj, "IMGUI_DISABLE_OBSOLETE_FUNCTIONS") {
			continue
		}

		proc_name_raw, proc_name_ok := json_get_string(&function_entry, "name")
		assert(proc_name_ok, "Function name is missing!")

		if is_ignored_function(functions_to_ignore, proc_name_raw) {
			continue
		}

		defer free_all(gen.tmp_ally)

		// This is the procedure final string to write
		b := strings.builder_make(gen.tmp_ally)

		// Start by writing preceding comments (if any)
		if preceding_comments, preceding_comments_ok := get_preceding_comments(
			obj = &function_entry_obj,
			tab_count = 1,
			merge_attached = true,
			allocator = gen.tmp_ally,
		); preceding_comments_ok {
			strings.write_string(&b, preceding_comments)
		}

		// Write the link name
		strings.write_string(&b, TAB_SPACE)
		strings.write_string(&b, "@(link_name = \"")
		strings.write_string(&b, proc_name_raw)
		strings.write_string(&b, "\")\n")

		// Get the procedure name and clean up
		proc_name := remove_imgui(proc_name_raw, gen.tmp_ally)
		proc_name = strings.to_snake_case(proc_name, gen.tmp_ally)
		strings.write_string(&b, TAB_SPACE)
		strings.write_string(&b, proc_name)
		strings.write_string(&b, " :: proc(")

		// Arguments
		if arguments, arguments_ok := function_entry_obj["arguments"].(json.Array); arguments_ok {
			for &arg, i in arguments {
				arg_obj := arg.(json.Object)

				arg_name, arg_name_ok := json_get_string(&arg_obj, "name")
				assert(arg_name_ok, "Argument name is missing!")

				reserved_name, reserved_name_ok := reserved_name_map[arg_name]
				if reserved_name_ok {
					arg_name = reserved_name
				}

				arg_type_value, arg_type_value_ok := arg_obj["type"]
				details_value: json.Value
				details_value_ok: bool
				if arg_type_value_ok {
					details_value, details_value_ok = arg_type_value.(json.Object)["type_details"]
				}
				is_varargs_value := arg_obj["is_varargs"]
				is_varargs := is_varargs_value.(json.Boolean)

				if !arg_type_value_ok && is_varargs {
					// Check for varargs first, this occurs when there is no arg type
					strings.write_string(&b, "#c_vararg args: ..any")
				} else if details_value_ok {
					// When there is a type_details field, we assume its a function pointer
					func_def := get_proc_definition(
						gen,
						&arg_obj,
						&details_value.(json.Object),
						gen.tmp_ally,
					)
					strings.write_string(&b, arg_name)
					strings.write_string(&b, ": ")
					strings.write_string(&b, func_def.definition)
				} else {
					// Otherwise its a common type declaration
					declaration_value, declaration_value_ok := json_get_string(
						&arg_type_value,
						"declaration",
					)
					assert(declaration_value_ok, "Argument type declaration is missing!")
					if declaration_value == "va_list" {
						continue loop
					}
					declaration := get_type_string(
						gen,
						&arg_type_value.(json.Object),
						true,
						gen.tmp_ally,
					)
					strings.write_string(&b, arg_name)
					strings.write_string(&b, ": ")
					strings.write_string(&b, declaration)
				}

				default_value, default_value_ok := json_get_string(&arg, "default_value")
				if default_value_ok {
					/* Removes the 'f' suffix from a number string if present */
					remove_float_suffix :: proc(
						value: string,
						allocator: runtime.Allocator,
					) -> (
						string,
						bool,
					) #optional_ok {
						processed, replace_ok := strings.replace_all(value, "f", "", allocator)
						if !replace_ok {
							return value, false
						}

						_, parse_ok := strconv.parse_f32(processed)
						return processed, parse_ok
					}

					// replace_float_constants replaces C++ float constants with Odin equivalents
					// Returns the processed string and success boolean
					replace_float_constants :: proc(
						value: string,
						allocator: runtime.Allocator,
					) -> (
						string,
						bool,
					) #optional_ok {
						result := value
						replaced := false

						if strings.contains(result, "FLT_MAX") {
							new_value, ok := strings.replace_all(
								result,
								"FLT_MAX",
								"max(f32)",
								allocator,
							)
							if ok {
								result = new_value
								replaced = true
							}
						}

						if strings.contains(result, "FLT_MIN") {
							new_value, ok := strings.replace_all(
								result,
								"FLT_MIN",
								"min(f32)",
								allocator,
							)
							if ok {
								result = new_value
								replaced = true
							}
						}

						if strings.contains(result, "IM_COL32_WHITE") {
							new_value, ok := strings.replace_all(
								result,
								"IM_COL32_WHITE",
								"0xff_ff_ff_ff",
								allocator,
							)
							if ok {
								result = new_value
								replaced = true
							}
						}

						return result, replaced
					}

					default_value_to_write := default_value

					default: {
						// NULL values are just nil in Odin
						if default_value == "NULL" || default_value == "nullptr" {
							default_value_to_write = "nil"
							break default
						}

						curr := strings.to_string(b)
						last_word_index := strings.last_index(curr, " ")
						type_str := strings.trim(curr[last_word_index:], " ")

						if default_value == "0" {
							switch type_str {
							case "i32":
								default_value_to_write = "0"
								break default
							}

							default_value_to_write = "{}"
							break default
						}

						int_value, int_value_ok := strconv.parse_int(default_value)

						if int_value_ok && strings.ends_with(type_str, "Flags") {
							gen_flags: for &f in gen.flags {
								if f.name != type_str {
									continue gen_flags
								}
								for &c in f.constants {
									if c.value == int_value {
										default_value_to_write = strings.concatenate(
											{"{.", c.name, "}"},
											gen.tmp_ally,
										)
										break gen_flags
									}
								}
							}
							break default
						}

						default_value_to_write = replace_float_constants(
							default_value,
							gen.tmp_ally,
						)

						// Remove the `f` suffix from numbers
						if strings.ends_with(default_value, "f") {
							default_value_to_write = remove_float_suffix(
								default_value_to_write,
								gen.tmp_ally,
							)
						}

						//
						if strings.contains(default_value, "(") &&
						   !strings.contains(default_value, "\"") {
							start := strings.index(default_value, "(")
							end := len(default_value) - 1
							name := remove_imgui(default_value[:start], gen.tmp_ally)
							value := default_value[start + 1:end]
							value = replace_float_constants(value, gen.tmp_ally)

							if strings.starts_with(name, "sizeof") {
								name = "size_of"
								value = gen.type_map[value]
								default_value_to_write = strings.concatenate(
									{name, "(", value, ")"},
									gen.tmp_ally,
								)
							} else {
								if !strings.contains(value, "f32") {
									value = remove_float_suffix(value, gen.tmp_ally)
								}
								default_value_to_write = strings.concatenate(
									{name, "{", value, "}"},
									gen.tmp_ally,
								)
							}
						}
					}

					strings.write_string(&b, " = ")
					strings.write_string(&b, default_value_to_write)
				}

				if i < len(arguments) - 1 {
					strings.write_string(&b, ", ")
				}
			}
		}

		// Get the function type and clean up
		return_type_raw, return_type_raw_ok := function_entry_obj["return_type"]
		assert(return_type_raw_ok, "Return type is missing!")
		return_type := get_type_string(gen, &return_type_raw.(json.Object), false, gen.tmp_ally)

		strings.write_string(&b, ")")

		if return_type != "void" {
			strings.write_string(&b, " -> ")
			strings.write_string(&b, return_type)
		}

		strings.write_string(&b, " ---\n")

		os.write_string(handle, strings.to_string(b))
	}

	os.write_string(handle, "}") // End of foreign block
}

Proc_Definition :: struct {
	comments:   string,
	name:       string,
	definition: string,
}

get_proc_definition :: proc(
	gen: ^Generator,
	type: ^json.Object,
	details: ^json.Object,
	allocator: mem.Allocator,
) -> Proc_Definition {
	proc_name, proc_name_ok := json_get_string(type, "name")
	assert(proc_name_ok, "Procedure name is missing!")

	ta := context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == ta)

	b := strings.builder_make(ta)

	proc_name, _ = strings.remove(proc_name, "_", 1, ta)
	proc_name = remove_imgui(proc_name, ta)

	// Procedure name
	// strings.write_string(&b, proc_name)
	strings.write_string(&b, "proc(")

	// Arguments
	arguments, arguments_ok := details["arguments"].(json.Array)
	if arguments_ok {
		for &arg, i in arguments {
			arg_name, arg_name_ok := json_get_string(&arg.(json.Object), "name")
			assert(arg_name_ok, "Argument name is missing!")

			strings.write_string(&b, arg_name)
			strings.write_string(&b, ": ")

			arg_type_value, arg_type_value_ok := arg.(json.Object)["type"]
			assert(arg_type_value_ok, "Argument type is missing!")

			arg_type := get_type_string(gen, &arg_type_value.(json.Object), true, ta)
			strings.write_string(&b, arg_type)
			if i < len(arguments) - 1 {
				strings.write_string(&b, ", ")
			}
		}
	}

	strings.write_string(&b, ")")

	// Return type
	return_type_raw, return_type_raw_ok := details["return_type"]
	if return_type_raw_ok {
		return_type := get_type_string(gen, &return_type_raw.(json.Object), false, gen.tmp_ally)
		if return_type != "void" {
			strings.write_string(&b, " -> ")
			strings.write_string(&b, return_type)
		}
	}

	proc_name_out := pascal_to_ada_case(proc_name, allocator)
	proc_definition := strings.clone(strings.to_string(b), allocator)

	return Proc_Definition{name = proc_name_out, definition = proc_definition}
}
