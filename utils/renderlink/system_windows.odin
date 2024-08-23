//+build windows
package renderlink

// STD Library
import "base:runtime"
import "core:log"
import win "core:sys/windows"

_system_open_url :: proc(url: string) -> bool {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	err := win.ShellExecuteW(nil, nil, win.utf8_to_wstring(url), nil, nil, win.SW_SHOW)

	if transmute(int)err <= 32 {
		log.errorf("Failed to open URL:", err)
		return false
	}

	return true
}
