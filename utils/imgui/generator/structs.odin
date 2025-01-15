package imgui_generator

// Packages
import "base:runtime"
import "core:encoding/json"
import "core:log"
import "core:os"
import "core:strings"

FunctionPointerList :: distinct [dynamic]string

write_structs :: proc(gen: ^Generator, handle: os.Handle, json_data: ^json.Value) {
	root := json_data.(json.Object)

	structs, structs_ok := root["structs"]
	if !structs_ok {
		log.warn("Missing 'structs' root object! Ignoring...")
		return
	}

	ta := context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	// proc_pointer_list: [dynamic]string;proc_pointer_list.allocator = ta

	loop: for &struct_entry in structs.(json.Array) {
		// Ignore obsolete names
		if test_ifndef_condition(&struct_entry.(json.Object), "IMGUI_DISABLE_OBSOLETE_KEYIO") {
			continue
		}

		defer free_all(gen.tmp_ally)

		// Get field name and clean up
		struct_name := get_type_string(gen, &struct_entry.(json.Object), false, ta)

		b := strings.builder_make(ta)
		strings.write_string(&b, struct_name)
		strings.write_string(&b, " :: struct")

		fields_obj, fields_obj_ok := struct_entry.(json.Object)["fields"]
		assert(fields_obj_ok, "Fields array is missing!")

		fields := fields_obj.(json.Array)

		if len(fields) == 0 {
			strings.write_string(&b, " {}\n\n")
		} else {
			strings.write_string(&b, " {\n")
			pad_count: int
			for &field in fields {
				field_obj := field.(json.Object)

				field_type_value := field_obj["type"]
				field_type_obj := field_type_value.(json.Object)
				field_type := get_type_string(gen, &field_type_obj, false, ta)

				// Ignore obsolete names
				if test_ifndef_condition(&field_obj, "IMGUI_DISABLE_OBSOLETE_KEYIO") {
					strings.write_string(&b, TAB_SPACE)
					strings.write_string(&b, "_pad")
					strings.write_int(&b, pad_count)
					switch field_type {
					case "[KEY_COUNT]i32":
						strings.write_string(&b, ": [666]i32,\n")
					case "[KEY_COUNT]bool":
						strings.write_string(&b, ": [666]bool,\n")
					case "[NAV_INPUT_COUNT]f32":
						strings.write_string(&b, ": [16]f32,\n")
					}
					pad_count += 1
					continue
				}

				field_name, field_name_ok := json_get_string(&field_obj, "name")
				assert(field_name_ok, "Field name is missing!")

				// Check for function pointer
				type_details_value, type_details_ok := field_type_obj["type_details"]
				if type_details_ok {
					proc_def := get_proc_definition(
						gen,
						&field_obj,
						&type_details_value.(json.Object),
						gen.tmp_ally,
					)
					strings.write_string(&b, TAB_SPACE)

					field_name, _ = strings.remove(field_name, "_", 1, ta)
					field_name = strings.to_snake_case(field_name, ta)

					strings.write_string(&b, field_name)
					strings.write_string(&b, ": ")
					strings.write_string(&b, proc_def.definition)
					strings.write_string(&b, ",\n")
					continue
				}

				field_name = strings.to_snake_case(field_name, ta)

				strings.write_string(&b, TAB_SPACE)
				strings.write_string(&b, field_name)
				strings.write_string(&b, ": ")
				strings.write_string(&b, field_type)
				strings.write_string(&b, ",\n")
			}
			strings.write_string(&b, "}\n\n")
		}

		os.write_string(handle, strings.to_string(b))
	}

	// if len(proc_pointer_list) > 0 {
	// 	b := strings.builder_make(ta)
	// 	for v in proc_pointer_list {
	// 		strings.write_string(&b, v)
	// 		strings.write_byte(&b, '\n')
	// 	}
	// 	strings.write_byte(&b, '\n')
	// 	os.write_string(handle, strings.to_string(b))
	// }
}
