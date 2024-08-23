//+build linux, darwin, windows
package renderlink

// STD Library
import "base:runtime"
import "core:strings"

// Vendor
import sdl "vendor:sdl2"

when SYSTEM_PACKAGE {
	_system_get_clipboard_text :: proc(allocator := context.allocator) -> (text: string) {
		c_text := sdl.GetClipboardText()

		if c_text != nil {
			text = strings.clone_from_cstring(c_text, allocator)
			sdl.free(&c_text)
		}

		return
	}

	_system_get_power_info :: proc "contextless" (
	) -> (
		state: Power_State,
		seconds, percent: i32,
	) {
		raw_state := sdl.GetPowerInfo(&seconds, &percent)

		#partial switch raw_state {
		case .ON_BATTERY:
			state = .Battery
		case .NO_BATTERY:
			state = .No_Battery
		case .CHARGING:
			state = .Charging
		case .CHARGED:
			state = .Charged
		case:
			state = .Unknown
		}

		return
	}

	_system_get_processor_count :: proc "contextless" () -> i32 {
		return sdl.GetCPUCount()
	}

	_system_has_background_music :: proc "contextless" () -> bool {return false}

	_system_set_clipboard_text :: proc(text: string) {
		runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
		sdl.SetClipboardText(strings.clone_to_cstring(text, context.temp_allocator))
	}

	_system_vibrate :: proc "contextless" () {}
} else {
	_ :: runtime
	_ :: strings
	_ :: sdl
	_system_get_clipboard_text :: proc(_ := context.allocator) -> (text: string) {return}
	_system_get_os :: proc "contextless" () -> OS_Info {return {}}
	_system_get_info :: proc "contextless" () -> System_Info {return {}}
	_system_get_power_info :: proc "contextless" (
	) -> (
		state: Power_State,
		seconds, percent: i32,
	) {return}
	_system_get_processor_count :: proc "contextless" () -> i32 {return 0}
	_system_has_background_music :: proc "contextless" () -> bool {return false}
	_system_open_url :: proc "contextless" (_: string) {}
	_system_set_clipboard_text :: proc "contextless" (_: string) {}
	_system_vibrate :: proc "contextless" () {}
}
