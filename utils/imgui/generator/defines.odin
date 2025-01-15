package imgui_generator

// Packages
import "core:encoding/json"
import "core:log"
import "core:os"

write_defines :: proc(gen: ^Generator, handle: os.Handle, json_data: ^json.Value) {
	root := json_data.(json.Object)

	defines, defines_ok := root["defines"]
	if !defines_ok {
		log.warn("Missing 'defines' root object! Ignoring...")
		return
	}

	// Some definitions to ignore
	skip_map: map[string]bool;skip_map.allocator = gen.tmp_ally
	skip_map["IMGUI_IMPL_API"] = true

	loop: for &d in defines.(json.Array) {
		defer free_all(gen.tmp_ally)

		define := d.(json.Object)

		// Only use default definitions (assuming not defined)
		if conditionals_value, conditionals_ok := define["conditionals"]; conditionals_ok {
			for &c in conditionals_value.(json.Array) {
				if condition, condition_ok := c.(json.Object)["condition"]; condition_ok {
					if condition.(json.String) != "ifndef" {
						continue loop
					}
					continue
				}
			}
		}

		name_value := define["name"]

		if content_value, content_ok := define["content"]; content_ok {
			name_raw := name_value.(json.String)
			if _, skip_name := skip_map[name_raw]; skip_name {
				continue
			}
			name := remove_imgui(name_raw, gen.tmp_ally)
			write_constant(gen, handle, name, content_value.(json.String))
		}
	}

	os.write_string(handle, "\n")
}
