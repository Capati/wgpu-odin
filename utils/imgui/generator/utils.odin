package imgui_generator

// Packages
import "base:runtime"
import "core:encoding/json"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"
import "core:unicode"

test_ifndef_condition :: proc(o: ^json.Object, expression_value: string) -> bool {
	if conditionals_value, conditionals_ok := o["conditionals"]; conditionals_ok {
		for &c in conditionals_value.(json.Array) {
			condition := json_get_string(&c, "condition") or_return
			expression := json_get_string(&c, "expression") or_return
			if condition == "ifndef" && expression == expression_value {
				return true
			}
		}
	}
	return false
}

remove_imgui :: proc(name: string, allocator: mem.Allocator) -> string {
	ta := context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == ta)

	str := name

	// Most specific first
	str, _ = strings.replace_all(str, "cImGui_Impl", "", ta)
	str, _ = strings.replace_all(str, "ImGui_Impl", "", ta)
	str, _ = strings.replace_all(str, "IMGUI_", "", ta)
	str, _ = strings.replace_all(str, "ImGui_", "", ta)
	str, _ = strings.replace_all(str, "ImGui", "", ta)
	str, _ = strings.replace_all(str, "IM_", "", ta)

	// TODO(Capati): Check other "Im" word conflicts
	if !strings.contains(str, "Image") {
		str, _ = strings.replace_all(str, "Im", "", ta)
	}

	return strings.clone(str, allocator)
}

write_package_name :: proc(gen: ^Generator, handle: os.Handle, name := "imgui", nl := true) {
	defer free_all(gen.tmp_ally)
	package_name := fmt.aprintf("package %s\n%s", name, nl ? "\n" : "", allocator = gen.tmp_ally)
	os.write_string(handle, package_name)
}

write_constant :: proc(gen: ^Generator, handle: os.Handle, name: string, value: string) {
	constant := fmt.aprintf("%s :: %s\n", name, value, allocator = gen.tmp_ally)
	os.write_string(handle, constant)
}

json_get_string_from_object :: proc(o: ^json.Object, name: string) -> (str: string, ok: bool) {
	if str_value, str_ok := o[name]; str_ok {
		return str_value.(json.String), true
	}
	return
}

json_get_string_from_value :: proc(v: ^json.Value, name: string) -> (str: string, ok: bool) {
	if obj, obj_ok := v.(json.Object); obj_ok {
		return json_get_string_from_object(&obj, name)
	}
	return
}

json_get_string :: proc {
	json_get_string_from_object,
	json_get_string_from_value,
}

get_type_string :: proc(
	gen: ^Generator,
	type: ^json.Object,
	is_parameter: bool,
	allocator: mem.Allocator,
) -> string {
	ta := context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == ta)

	// Get raw name from either declaration or name
	raw_name: string
	if declaration, declaration_ok := json_get_string(type, "declaration"); declaration_ok {
		raw_name = declaration
	} else {
		name, name_ok := json_get_string(type, "name")
		assert(name_ok, "Procedure name is missing!")
		raw_name = name
	}

	temp_raw_name := strings.clone(raw_name, ta)
	raw_array_value: string
	inner_array := true

	// Parse array syntax if present
	if array_idx := strings.index(temp_raw_name, "["); array_idx >= 0 {
		if temp_raw_name[array_idx + 1] == ']' {
			inner_array = false
		} else {
			raw_name = temp_raw_name[:array_idx]
			raw_array_value = temp_raw_name[array_idx + 1:len(temp_raw_name) - 1]
		}
	}

	// Get mapped type name or remove ImGui prefix
	type_name: string
	if type_value_name, type_value_name_ok := gen.type_map[raw_name]; type_value_name_ok {
		type_name = type_value_name
	} else {
		type_name = remove_imgui(raw_name, ta)
	}

	// Remove "const " prefix if present
	type_name, _ = strings.replace_all(type_name, "const", "", ta)

	// Remove remain spaces from both left and right
	type_name = strings.trim(type_name, " ")

	// Check if type is array
	is_array: bool
	description_obj, description_obj_ok := type["description"].(json.Object)
	if description_obj_ok {
		kind := description_obj["kind"].(json.String)
		is_array = kind == "Array"
	}

	// is_multi_pointer: bool
	is_multi_pointer_cstring: bool
	if description_obj_ok && is_array {
		inner_type_obj, inner_type_ok := description_obj["inner_type"].(json.Object)
		if inner_type_ok {
			kind := inner_type_obj["kind"].(json.String)
			if kind == "Pointer" {
				// is_multi_pointer = true
				if strings.contains(type_name, "char*") {
					is_multi_pointer_cstring = true
				}
			}
		}
	}

	// Convert char* to cstring if not array
	if strings.contains(type_name, "char*") {
		if is_multi_pointer_cstring {
			type_name = "[^]cstring"
		} else {
			type_name = "cstring"
		}
	}

	// Build final type name
	b := strings.builder_make(ta)

	if is_array && is_parameter && !is_multi_pointer_cstring {
		strings.write_string(&b, "^")
	}

	count := strings.count(type_name, "*")
	if count > 0 {
		type_name, _ = strings.remove_all(type_name, "*", ta)
		for _ in 0 ..< count {
			strings.write_string(&b, "^")
		}
	}

	// Handle array types
	if len(raw_array_value) > 0 {
		if inner_array {
			array_value := remove_imgui(raw_array_value, ta)
			array_value_constant := camel_to_constant_case(array_value, allocator)
			res := fmt.tprintf("[%s]", array_value_constant)
			strings.write_string(&b, res)
		} else {
			strings.write_string(&b, "[]")
		}
	}

	parts := strings.split(type_name, "_", ta)

	// Convert underscores to camel case
	for part, i in parts {
		if i == 0 {
			strings.write_string(&b, part)
		} else if len(part) > 0 {
			strings.write_string(&b, strings.to_upper(part[:1]))
			if len(part) > 1 {
				strings.write_string(&b, part[1:])
			}
		}
	}

	return strings.clone(strings.to_string(b), allocator)
}

camel_to_constant_case :: proc(camel_str: string, allocator: mem.Allocator) -> string {
	// Handle temporary allocator case
	ta := context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == ta)

	// Initialize string builder
	b := strings.builder_make(ta)

	first_char := true
	previous: rune

	// Helper procedure to determine if we need to add an underscore
	should_add_underscore :: proc(current: rune, previous: rune, b: strings.Builder) -> bool {
		return(
			unicode.is_alpha(current) &&
			unicode.is_upper(current) &&
			!unicode.is_upper(previous) &&
			strings.builder_len(b) > 0 \
		)
	}

	for c in camel_str {
		if first_char {
			// First character is always uppercase
			strings.write_rune(&b, unicode.to_upper(c))
			first_char = false
		} else if should_add_underscore(c, previous, b) {
			// Add underscore before new uppercase letter in the middle of a word
			strings.write_byte(&b, '_')
			strings.write_rune(&b, c)
		} else {
			// Convert all other characters to uppercase
			strings.write_rune(&b, unicode.to_upper(c))
		}

		// Reset first_char flag for non-alphabetic characters
		first_char = c == ' ' || !unicode.is_alpha(c)
		previous = c
	}

	return strings.clone(strings.to_string(b), allocator)
}
