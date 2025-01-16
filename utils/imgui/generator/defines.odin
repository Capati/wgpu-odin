package imgui_gen

// Packages
import "core:encoding/json"
import "core:os"
import "core:slice"

/*
Writes the defines from the given JSON data to the specified handle.

Inputs:
- gen: A pointer to the Generator structure.
- handle: The OS file handle to write the defines to.
- json_data: A pointer to the JSON value containing the defines.
*/
write_defines :: proc(gen: ^Generator, handle: os.Handle, json_data: ^json.Value) {
	root := json_data.(json.Object)

	defines, defines_ok := root["defines"]
	assert(defines_ok, "Missing 'defines' root object!")

	// Some definitions to ignore
	defines_to_ignore := []string{"IMGUI_IMPL_API"}
	is_ignored_define :: #force_inline proc(defines: []string, name: string) -> bool {
		return slice.contains(defines, name)
	}

	loop: for &d in defines.(json.Array) {
		defer free_all(gen.tmp_ally)

		define_obj := d.(json.Object)

		// Only use default definitions (assuming not defined)
		if conditionals_value, conditionals_ok := define_obj["conditionals"]; conditionals_ok {
			conditionals := conditionals_value.(json.Array)
			for &c in conditionals {
				if condition, condition_ok := c.(json.Object)["condition"]; condition_ok {
					if condition.(json.String) != "ifndef" {
						continue loop
					}
					continue
				}
			}
		}

		name_raw, name_raw_ok := define_obj["name"].(json.String)
		assert(name_raw_ok, "Missing name definition!")

		if is_ignored_define(defines_to_ignore, name_raw) {
			continue
		}

		if content_value, content_ok := define_obj["content"]; content_ok {
			attached_comments := get_attached_comments(&define_obj, gen.tmp_ally)
			name := remove_imgui(name_raw, gen.tmp_ally)
			write_constant(gen, handle, name, attached_comments, content_value.(json.String))
		}
	}

	os.write_byte(handle, '\n')
}
