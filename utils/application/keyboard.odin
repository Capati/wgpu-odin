package application

Keyboard_State :: struct {
	current:           [KEY_COUNT]bool,
	previous:          [KEY_COUNT]bool,
	last_key_pressed:  Key,
	last_key_released: Key,
	key_repeat:        bool,
}

key_is_pressed :: #force_inline proc "contextless" (key: Key, app := app_context) -> bool {
	return app.keyboard.current[key] && !app.keyboard.previous[key]
}

key_is_down :: #force_inline proc "contextless" (key: Key, app := app_context) -> bool {
	return app.keyboard.current[key]
}

key_is_released :: #force_inline proc "contextless" (key: Key, app := app_context) -> bool {
	return !app.keyboard.current[key] && app.keyboard.previous[key]
}

key_is_up :: #force_inline proc "contextless" (key: Key, app := app_context) -> bool {
	return !app.keyboard.current[key]
}

key_get_pressed :: #force_inline proc "contextless" (app := app_context) -> Key {
	return app.keyboard.last_key_pressed
}

set_exit_key :: proc "contextless" (key: Key, app := app_context) {
	app.exit_key = key
}
