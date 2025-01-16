package imgui_gen

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

write_constant :: proc(
	gen: ^Generator,
	handle: os.Handle,
	name: string,
	comments: string,
	value: string,
) {
	constant := fmt.aprintf(
		"%s :: %s%s%s\n",
		name,
		value,
		" " if comments != "" else "",
		comments if comments != "" else "",
		allocator = gen.tmp_ally,
	)
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

// Helper to convert type name using map or default conversion
convert_type_name :: proc(
	gen: ^Generator,
	name: string,
	allocator := context.allocator,
) -> string {
	if mapped_name, ok := gen.type_map[name]; ok {
		return mapped_name
	}
	// First remove ImGui prefix, then convert to Ada case
	clean_name := remove_imgui(name, allocator)
	return pascal_to_ada_case(clean_name, allocator)
}

// Helper to process inner type recursively
get_inner_type_string :: proc(
	gen: ^Generator,
	type_obj: json.Object,
	allocator := context.allocator,
) -> (
	string,
	bool,
) {
	ta := context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == ta)

	if kind, kind_ok := type_obj["kind"].(json.String); kind_ok {
		switch kind {
		case "User":
			name, name_ok := type_obj["name"].(json.String)
			if !name_ok {
				return "", false
			}
			return convert_type_name(gen, name, ta), true

		case "Builtin":
			builtin_type, builtin_type_ok := type_obj["builtin_type"].(json.String)
			if !builtin_type_ok {
				return "", false
			}
			if builtin_type == "char" {
				return "cstring", true
			}
			return convert_type_name(gen, builtin_type, ta), true

		case "Pointer":
			inner_type, inner_type_ok := type_obj["inner_type"].(json.Object)
			if !inner_type_ok {
				return "", false
			}

			inner_type_kind: string
			builtin_type: string
			ok: bool

			// Handle special case for char* -> cstring
			if inner_type_kind, ok = inner_type["kind"].(json.String); ok {
				if inner_type_kind == "Builtin" {
					builtin_type, ok = inner_type["builtin_type"].(json.String)
					if ok && builtin_type == "char" {
						return "cstring", true
					}
				}
			}

			inner_name, inner_name_ok := get_inner_type_string(gen, inner_type, ta)
			if !inner_name_ok {
				return "", false
			}
			// Handle remaining special cases
			if inner_name == "void" {
				return "rawptr", true
			}
			inner_name = convert_type_name(gen, inner_name, ta)
			return fmt.tprintf("^%s", inner_name), true

		case "Array":
			inner_type, inner_type_ok := type_obj["inner_type"].(json.Object)
			if !inner_type_ok {
				return "", false
			}
			inner_name, inner_name_ok := get_inner_type_string(gen, inner_type, ta)
			if !inner_name_ok {
				return "", false
			}

			inner_type_kind: string
			builtin_type: string
			next_kind: string
			next_inner: json.Object
			ok: bool

			if inner_type_kind, ok = inner_type["kind"].(json.String); ok {
				if inner_type_kind == "Pointer" {
					if next_inner, ok = inner_type["inner_type"].(json.Object); ok {
						if next_kind, ok = next_inner["kind"].(json.String);
						   ok && next_kind == "Builtin" {
							builtin_type, ok = next_inner["builtin_type"].(json.String)
							if ok {
								if builtin_type == "char" {
									return "[^]cstring", true
								}
							}
						}
					}
				}
			}

			bounds, has_bounds := type_obj["bounds"].(json.String)
			if has_bounds {
				bounds = remove_imgui(bounds, ta)
				bounds = camel_to_constant_case(bounds, ta)
				return fmt.tprintf("[%s]%s", bounds, inner_name), true
			}

			inner_name = fmt.tprintf("[]%s", inner_name)
			return convert_type_name(gen, inner_name, ta), true
		}
	}

	return "", false
}

get_type_string :: proc(
	gen: ^Generator,
	type: ^json.Object,
	is_parameter: bool,
	allocator: mem.Allocator,
) -> string {
	ta := context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == ta)

	b := strings.builder_make(ta)

	// Try to process using description first
	if description_obj, description_ok := type["description"].(json.Object); description_ok {
		if type_str, ok := get_inner_type_string(gen, description_obj, ta); ok {
			// Handle parameter arrays
			if is_parameter && description_obj["kind"].(json.String) == "Array" {
				if !strings.has_prefix(type_str, "[^]") {
					strings.write_string(&b, "^")
				}
			}
			strings.write_string(&b, type_str)
			return strings.clone(strings.to_string(b), allocator)
		}
	}

	// Fallback to declaration parsing
	raw_name: string
	if declaration, declaration_ok := json_get_string(type, "declaration"); declaration_ok {
		raw_name = declaration
	} else {
		name, ok := json_get_string(type, "name")
		assert(ok, "Type name is missing!")
		raw_name = name
	}

	// Process the raw name (similar to original logic but simplified)
	type_name, _ := strings.replace_all(raw_name, "const", "", ta)
	type_name = strings.trim(type_name, " ")

	// Handle pointers and arrays
	if strings.contains(type_name, "*") {
		parts := strings.split(type_name, "*", ta)
		base_type := strings.trim(parts[0], " ")
		if base_type == "char" {
			if len(parts) > 2 {
				return "^cstring"
			}
			return "cstring"
		}
		base_type = convert_type_name(gen, base_type, ta)
		for _ in 0 ..< len(parts) - 1 {
			strings.write_string(&b, "^")
		}
		strings.write_string(&b, base_type)
	} else if array_idx := strings.index(type_name, "["); array_idx >= 0 {
		base_type := strings.trim(type_name[:array_idx], " ")
		array_spec := type_name[array_idx:]
		if array_spec == "[]" {
			if is_parameter {
				strings.write_string(&b, "^")
			}
			strings.write_string(&b, "[]")
		} else {
			strings.write_string(&b, array_spec)
		}
		base_type = convert_type_name(gen, base_type, ta)
		strings.write_string(&b, base_type)
	} else {
		type_name = convert_type_name(gen, type_name, ta)
		strings.write_string(&b, type_name)
	}

	return strings.clone(strings.to_string(b), allocator)
}

get_preceding_comments :: proc(
	obj: ^json.Object,
	tab_count: int = 0,
	merge_attached := false,
	allocator := context.allocator,
) -> (
	string,
	bool,
) {
	ta := context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == ta)
	b := strings.builder_make(ta)

	if comments_value, has_comments := obj["comments"]; has_comments {
		comments_obj := comments_value.(json.Object)
		if comments_preceding_value, has_preceding := comments_obj["preceding"]; has_preceding {
			comments_preceding := comments_preceding_value.(json.Array)
			for &c in comments_preceding {
				comment := c.(json.String)
				for _ in 0 ..< tab_count {
					strings.write_string(&b, TAB_SPACE)
				}
				strings.write_string(&b, comment)
				strings.write_byte(&b, '\n')
			}
		}

		// Merge attached comments with preceding
		if merge_attached {
			if comments_attached_value, has_attached := comments_obj["attached"]; has_attached {
				comment := comments_attached_value.(json.String)
				for _ in 0 ..< tab_count {
					strings.write_string(&b, TAB_SPACE)
				}
				strings.write_string(&b, comment)
				strings.write_byte(&b, '\n')
			}
		}

		comments_preceding := strings.to_string(b)
		if comments_preceding != "" {
			return strings.clone(comments_preceding, allocator), true
		}
	}

	return "", false
}

get_attached_comments :: proc(
	obj: ^json.Object,
	allocator := context.allocator,
) -> (
	string,
	bool,
) #optional_ok {
	if comments_value, has_comments := obj["comments"]; has_comments {
		comments_obj := comments_value.(json.Object)

		if comments_attached_value, has_attached := comments_obj["attached"]; has_attached {
			comment := comments_attached_value.(json.String)
			return strings.clone(comment, allocator), true
		}
	}

	return "", false
}

pascal_to_ada_case :: proc(s: string, allocator := context.allocator) -> string {
	if len(s) == 0 {
		return ""
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == context.temp_allocator)
	b := strings.builder_make(context.temp_allocator)

	// Add first character as-is
	strings.write_byte(&b, s[0])

	for i := 1; i < len(s); i += 1 {
		curr := s[i]
		prev := s[i - 1]

		// Look ahead for next character if possible
		next: byte = 0
		if i < len(s) - 1 {
			next = s[i + 1]
		}

		is_curr_upper := unicode.is_upper(rune(curr))
		is_prev_upper := unicode.is_upper(rune(prev))
		is_next_upper := unicode.is_upper(rune(next))
		is_curr_digit := unicode.is_digit(rune(curr))
		is_prev_digit := unicode.is_digit(rune(prev))
		is_prev_alpha := unicode.is_alpha(rune(prev))

		// Check if previous character was an underscore
		prev_was_underscore := prev == '_'

		// Insert underscore before uppercase letters when:
		// 1. Current char is uppercase
		// 2. Previous char was a letter (alpha)
		// 3. Neither current nor previous char is a digit
		// 4. Previous char isn't underscore
		// AND either:
		//   - Previous char is lowercase
		//   - Or previous char is uppercase AND next char exists and is lowercase (end of acronym)
		if is_curr_upper &&
		   is_prev_alpha &&
		   !is_prev_digit &&
		   !is_curr_digit &&
		   !prev_was_underscore &&
		   (!is_prev_upper || (is_prev_upper && next != 0 && !is_next_upper)) {
			strings.write_byte(&b, '_')
		}

		strings.write_byte(&b, curr)
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
