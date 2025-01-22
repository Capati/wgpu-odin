package application

// Packages
import "vendor:glfw"

KEY_COUNT :: Key.Last

Keyboard_State :: struct {
	current:          [KEY_COUNT]bool,
	previous:         [KEY_COUNT]bool,
	last_key_pressed: Key,
	key_repeat:       bool,
}

keyboard_update :: proc(app: ^Application) #no_bounds_check {
	copy(app.keyboard.previous[:], app.keyboard.current[:])
	app.keyboard.last_key_pressed = .Unknown
	for key in Key {
		state := glfw.GetKey(app.window, i32(key))
		app.keyboard.current[key] = state == glfw.PRESS || state == glfw.REPEAT
		if app.keyboard.current[key] && !app.keyboard.previous[key] {
			app.keyboard.last_key_pressed = key
		}
	}
}

key_is_pressed :: #force_inline proc(app: ^Application, key: Key) -> bool {
	return app.keyboard.current[key] && !app.keyboard.previous[key]
}

key_is_down :: #force_inline proc(app: ^Application, key: Key) -> bool {
	return app.keyboard.current[key]
}

key_is_released :: #force_inline proc(app: ^Application, key: Key) -> bool {
	return !app.keyboard.current[key] && app.keyboard.previous[key]
}

key_is_up :: #force_inline proc(app: ^Application, key: Key) -> bool {
	return !app.keyboard.current[key]
}

key_get_pressed :: #force_inline proc(app: ^Application) -> Key {
	return app.keyboard.last_key_pressed
}

set_exit_key :: proc(app: ^Application, key: Key) {
	app.exit_key = key
}
