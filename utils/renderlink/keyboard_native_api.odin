//+build linux, darwin, windows
package application

// STD Library
import "core:log"
import "core:mem"

// Vendor
import sdl "vendor:sdl2"

when KEYBOARD_PACKAGE {
@(require_results)
_keyboard_init :: proc(allocator: mem.Allocator) -> (ok: bool) {
	defer if !ok {
		log.errorf("Error occurred during keyboard initialization")
	}

	g_app.keyboard.current_state = sdl.GetKeyboardStateAsSlice()
	g_app.keyboard.num_keys = len(g_app.keyboard.current_state)
	g_app.keyboard.previous_state = make([]u8, g_app.keyboard.num_keys, allocator)

	return true
}

_keyboard_destroy :: proc() {
}

_keyboard_update_state :: proc "contextless" () #no_bounds_check {
	if g_app.keyboard.current_state != nil {
		copy(g_app.keyboard.previous_state[:], g_app.keyboard.current_state[:g_app.keyboard.num_keys])
	}
}

_keyboard_reset_state :: proc "contextless" () {
	for &v in g_app.keyboard.previous_state do v = 0
	if g_app.keyboard.current_state != nil {
		for &v in g_app.keyboard.current_state do v = 0
	}
}

_keyboard_get_key_from_scancode :: proc "contextless" (
	scancode: Keyboard_Scancode,
) -> (
	key: Keyboard_Key,
) {
	if sdl_scancode, ok := _scancode_to_sdl_scancode(scancode); ok {
		sdl_key := sdl.GetKeyFromScancode(sdl_scancode)
		key = _sdl_to_key(sdl_key)
	}
	return
}

_keyboard_get_scancode_from_key :: proc "contextless" (
	key: Keyboard_Key,
) -> (
	scancode: Keyboard_Scancode,
) {
	sdl_key := _key_to_sdl(key)
	sdl_scancode := sdl.GetScancodeFromKey(sdl_key)
	scancode = _sdl_to_keyboard_scancode(sdl_scancode)
	return
}

_keyboard_has_key_repeat :: proc "contextless" () -> bool {
	return g_app.keyboard.key_repeat
}

_keyboard_has_screen_keyboard :: proc "contextless" () -> bool {
	return bool(sdl.HasScreenKeyboardSupport())
}

_keyboard_has_text_input :: proc "contextless" () -> bool {
	return bool(sdl.IsTextInputActive())
}

_keyboard_is_pressed :: proc "contextless" (keys: ..Keyboard_Key) -> bool {
	for key in keys {
		scancode := _key_to_sdl_scancode(key)
		if g_app.keyboard.current_state[scancode] == 1 &&
			g_app.keyboard.previous_state[scancode] == 0 {
			return true
		}
	}
	return false
}

_keyboard_is_down :: proc "contextless" (keys: ..Keyboard_Key) -> bool {
	for key in keys {
		scancode := _key_to_sdl_scancode(key)
		if g_app.keyboard.current_state[scancode] == 1 {
			return true
		}
	}
	return false
}

_keyboard_is_released :: proc "contextless" (keys: ..Keyboard_Key) -> bool {
	for key in keys {
		scancode := _key_to_sdl_scancode(key)
		if g_app.keyboard.current_state[scancode] == 0 &&
			g_app.keyboard.previous_state[scancode] == 1 {
			return true
		}
	}
	return false
}

_keyboard_is_up :: proc "contextless" (keys: ..Keyboard_Key) -> bool {
	for key in keys {
		scancode := _key_to_sdl_scancode(key)
		if g_app.keyboard.current_state[scancode] == 0 {
			return true
		}
	}
	return false
}

_keyboard_scancode_is_pressed :: proc "contextless" (scancodes: ..Keyboard_Scancode) -> bool {
	for scancode in scancodes {
		if sdl_key, ok := _scancode_to_sdl_scancode(scancode); ok {
			if g_app.keyboard.current_state[sdl_key] == 1 &&
				g_app.keyboard.previous_state[sdl_key] == 0 {
				return true
			}
		}
	}
	return false
}

_keyboard_scancode_is_down :: proc "contextless" (scancodes: ..Keyboard_Scancode) -> bool {
	for scancode in scancodes {
		if sdl_key, ok := _scancode_to_sdl_scancode(scancode); ok {
			if g_app.keyboard.current_state[sdl_key] == 1 {
				return true
			}
		}
	}
	return false
}

_keyboard_scancode_is_released :: proc "contextless" (scancodes: ..Keyboard_Scancode) -> bool {
	for scancode in scancodes {
		if sdl_key, ok := _scancode_to_sdl_scancode(scancode); ok {
			if g_app.keyboard.current_state[sdl_key] == 0 &&
				g_app.keyboard.previous_state[sdl_key] == 1 {
				return true
			}
		}
	}
	return false
}

_keyboard_scancode_is_up :: proc "contextless" (scancodes: ..Keyboard_Scancode) -> bool {
	for scancode in scancodes {
		if sdl_key, ok := _scancode_to_sdl_scancode(scancode); ok {
			if g_app.keyboard.current_state[sdl_key] == 0 {
				return true
			}
		}
	}
	return false
}

_keyboard_get_key_pressed :: proc() -> Keyboard_Scancode {
	for scancode in 0 ..< g_app.keyboard.num_keys {
		if g_app.keyboard.current_state[scancode] == 1 &&
			g_app.keyboard.previous_state[scancode] == 0 {
			return Keyboard_Scancode(scancode)
		}
	}
	return .Unknown
}

_keyboard_set_key_repeat :: proc "contextless" (enable: bool) {
	g_app.keyboard.key_repeat = enable
}

_keyboard_set_text_input_enable :: proc "contextless" (enable: bool) {
	if enable {
		sdl.StartTextInput()
	} else {
		sdl.StopTextInput()
	}
}

_keyboard_set_text_input_enable_rect :: proc "contextless" (enable: bool, x, y, w, h: i32) {
	when WINDOW_PACKAGE {
		x, y, w, h := x, y, w, h
		window_to_dpi_coords_from_int(&x, &y)
		window_to_dpi_coords_from_int(&w, &h)
	}
	sdl_rect := sdl.Rect{x, y, w, h}
	sdl.SetTextInputRect(&sdl_rect)
	_keyboard_set_text_input_enable(enable)
}

_keyboard_set_text_input :: proc {
	_keyboard_set_text_input_enable,
	_keyboard_set_text_input_enable_rect,
}

_keyboard_get_mod_state :: proc "contextless" () -> (key_mods: Keyboard_Modifier_Key) {
	sdl_keymod := sdl.GetModState()
	return _sdl_get_mod_state(sdl_keymod)
}
} else {
_ :: log
_ :: sdl
_keyboard_init :: proc(_: mem.Allocator) -> (ok: bool) { return false }
_keyboard_destroy :: proc() {}
_keyboard_update_state :: proc "contextless" () {}
_keyboard_reset_state :: proc "contextless" () {}
_keyboard_get_key_from_scancode :: proc "contextless" (
	_: Keyboard_Scancode,
) -> (
	key: Keyboard_Key,
) {
	return
}
_keyboard_get_scancode_from_key :: proc "contextless" (
	_: Keyboard_Key,
) -> (
	scancode: Keyboard_Scancode,
) {
	return
}
_keyboard_has_key_repeat :: proc "contextless" () -> bool {return false}
_keyboard_has_screen_keyboard :: proc "contextless" () -> bool {return false}
_keyboard_has_text_input :: proc "contextless" () -> bool {return false}
_keyboard_is_pressed :: proc "contextless" (_: ..Keyboard_Key) -> bool {return false}
_keyboard_is_down :: proc "contextless" (_: ..Keyboard_Key) -> bool {return false}
_keyboard_is_released :: proc "contextless" (_: ..Keyboard_Key) -> bool {return false}
_keyboard_is_upp :: proc "contextless" (_: ..Keyboard_Key) -> bool {return false}
_keyboard_scancode_is_pressed :: proc "contextless" (_: ..Keyboard_Scancode) -> bool {
	return false
}
_keyboard_scancode_is_down :: proc "contextless" (_: ..Keyboard_Scancode) -> bool {
	return false
}
_keyboard_scancode_is_released :: proc "contextless" (_: ..Keyboard_Scancode) -> bool {
	return false
}
_keyboard_scancode_is_up :: proc "contextless" (_: ..Keyboard_Scancode) -> bool {return false}
_keyboard_set_key_repeat :: proc "contextless" (_: bool) {return}
_keyboard_set_text_input_enable :: proc "contextless" (_: bool) {return}
_keyboard_set_text_input_enable_rect :: proc "contextless" (_: bool, x, y, w, h: i32) {}
_keyboard_set_text_input :: proc {
	_keyboard_set_text_input_enable,
	_keyboard_set_text_input_enable_rect,
}
_keyboard_get_mod_state :: proc "contextless" () -> (key_mods: Keyboard_Modifier_Key) {return}
}
