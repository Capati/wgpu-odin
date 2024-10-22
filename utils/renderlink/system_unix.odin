#+build darwin, linux
package renderlink

// STD Library
import "base:runtime"
import "core:c/libc"
import "core:fmt"
import "core:log"

_system_open_url :: proc(url: string) -> bool {
	when ODIN_OS == .Linux {
		// Linux: xdg-open, firefox, x-www-browser, open
		OPEN_URL :: "xdg-open"
	} else when ODIN_OS == .Darwin {
		OPEN_URL :: "open"
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cmd := fmt.ctprintf("%v \"%v\"", OPEN_URL, url)

	if return_value := libc.system(cmd); return_value != 0 {
		log.errorf("Failed to open URL:", return_value)
		return false
	}

	return true
}
