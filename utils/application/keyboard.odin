package application

// Vendor
import "vendor:glfw"

Keyboard_State :: struct {
	current:          [KEY_COUNT]bool,
	previous:         [KEY_COUNT]bool,
	last_key_pressed: Key,
	key_repeat:       bool,
}

keyboard_update :: proc "contextless" (self: ^Application) #no_bounds_check {
	copy(self.keyboard.previous[:], self.keyboard.current[:])
	self.keyboard.last_key_pressed = .Unknown
	for key in Key {
		if key == .Unknown { continue }
		state := glfw.GetKey(self.window.handle, i32(key))
		self.keyboard.current[key] = state == glfw.PRESS || state == glfw.REPEAT
		if self.keyboard.current[key] && !self.keyboard.previous[key] {
			self.keyboard.last_key_pressed = key
		}
	}
}

key_is_pressed :: #force_inline proc "contextless" (app: ^Application, key: Key) -> bool {
	return app.keyboard.current[key] && !app.keyboard.previous[key]
}

key_is_down :: #force_inline proc "contextless" (app: ^Application, key: Key) -> bool {
	return app.keyboard.current[key]
}

key_is_released :: #force_inline proc "contextless" (app: ^Application, key: Key) -> bool {
	return !app.keyboard.current[key] && app.keyboard.previous[key]
}

key_is_up :: #force_inline proc "contextless" (app: ^Application, key: Key) -> bool {
	return !app.keyboard.current[key]
}

key_get_pressed :: #force_inline proc "contextless" (app: ^Application) -> Key {
	return app.keyboard.last_key_pressed
}

set_exit_key :: proc "contextless" (app: ^Application, key: Key) {
	app.exit_key = key
}
