package application

// Packages
import "vendor:glfw"

MOUSE_BUTTON_COUNT :: len(Mouse_Button)

Mouse_State :: struct {
	current:             [MOUSE_BUTTON_COUNT]bool,
	previous:            [MOUSE_BUTTON_COUNT]bool,
	last_button_pressed: Mouse_Button,
	position:            [2]f64, // x, y coordinates
	previous_position:   [2]f64,
	scroll:              [2]f64, // x, y scroll offsets
	button_repeat:       bool,
}

mouse_update :: proc(app: ^Application) #no_bounds_check {
	// Update button states
	copy(app.mouse.previous[:], app.mouse.current[:])
	app.mouse.last_button_pressed = .Unknown

	// Update button states
	for button in Mouse_Button {
		if button == .Unknown {
			continue
		}
		state := glfw.GetMouseButton(app.window, i32(button))
		app.mouse.current[button] = state == glfw.PRESS
		if app.mouse.current[button] && !app.mouse.previous[button] {
			app.mouse.last_button_pressed = button
		}
	}

	// Update position
	app.mouse.previous_position = app.mouse.position
	app.mouse.position[0], app.mouse.position[1] = glfw.GetCursorPos(app.window)
}

mouse_button_is_pressed :: #force_inline proc(
	app: ^Application,
	button: Mouse_Button,
) -> bool #no_bounds_check {
	return app.mouse.current[button] && !app.mouse.previous[button]
}

mouse_button_is_down :: #force_inline proc(
	app: ^Application,
	button: Mouse_Button,
) -> bool #no_bounds_check {
	return app.mouse.current[button]
}

mouse_button_is_released :: #force_inline proc(
	app: ^Application,
	button: Mouse_Button,
) -> bool #no_bounds_check {
	return !app.mouse.current[button] && app.mouse.previous[button]
}

mouse_button_is_up :: #force_inline proc(
	app: ^Application,
	button: Mouse_Button,
) -> bool #no_bounds_check {
	return !app.mouse.current[button]
}

mouse_button_get_pressed :: #force_inline proc(app: ^Application) -> Mouse_Button {
	return app.mouse.last_button_pressed
}

mouse_get_position :: #force_inline proc(app: ^Application) -> [2]f64 {
	return app.mouse.position
}

mouse_get_previous_position :: #force_inline proc(app: ^Application) -> [2]f64 {
	return app.mouse.previous_position
}

mouse_get_movement :: #force_inline proc(app: ^Application) -> [2]f64 #no_bounds_check {
	return {
		app.mouse.position[0] - app.mouse.previous_position[0],
		app.mouse.position[1] - app.mouse.previous_position[1],
	}
}

mouse_get_scroll :: #force_inline proc(app: ^Application) -> [2]f64 {
	return app.mouse.scroll
}
