package application

// Packages
import "vendor:glfw"

/* Total number of mouse buttons available. */
MOUSE_BUTTON_COUNT :: len(Mouse_Button)

/* State of the mouse, including its position, button states, and other relevant information. */
Mouse_State :: struct {
	current:             [MOUSE_BUTTON_COUNT]bool,
	previous:            [MOUSE_BUTTON_COUNT]bool,
	last_button_pressed: Mouse_Button,
	position:            [2]f64, /* x, y coordinates */
	previous_position:   [2]f64,
	scroll:              [2]f64, /* x, y scroll offsets */
	button_repeat:       bool,
}

/* Updates the state of the mouse. */
mouse_update :: proc(app: ^Application) #no_bounds_check {
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

/* Checks if a specific mouse button has been just pressed. */
mouse_button_is_pressed :: #force_inline proc(
	app: ^Application,
	button: Mouse_Button,
) -> bool #no_bounds_check {
	return app.mouse.current[button] && !app.mouse.previous[button]
}

/* Checks if a specific mouse button is currently pressed down. */
mouse_button_is_down :: #force_inline proc(
	app: ^Application,
	button: Mouse_Button,
) -> bool #no_bounds_check {
	return app.mouse.current[button]
}

/* Checks if a mouse button has been just released. */
mouse_button_is_released :: #force_inline proc(
	app: ^Application,
	button: Mouse_Button,
) -> bool #no_bounds_check {
	return !app.mouse.current[button] && app.mouse.previous[button]
}

/* Checks if a specific mouse button is currently not pressed. */
mouse_button_is_up :: #force_inline proc(
	app: ^Application,
	button: Mouse_Button,
) -> bool #no_bounds_check {
	return !app.mouse.current[button]
}

/* Returns the currently pressed mouse button. */
mouse_button_get_pressed :: #force_inline proc(app: ^Application) -> Mouse_Button {
	return app.mouse.last_button_pressed
}

/* Returns the current position of the mouse cursor. */
mouse_get_position :: #force_inline proc(app: ^Application) -> [2]f64 {
	return app.mouse.position
}

/* Returns the previous position of the mouse cursor. */
mouse_get_previous_position :: #force_inline proc(app: ^Application) -> [2]f64 {
	return app.mouse.previous_position
}

/* Retrieves the current mouse movement. */
mouse_get_movement :: #force_inline proc(app: ^Application) -> [2]f64 #no_bounds_check {
	return {
		app.mouse.position[0] - app.mouse.previous_position[0],
		app.mouse.position[1] - app.mouse.previous_position[1],
	}
}

/*
Retrieves the current scroll values of the mouse.

Returns:
  - A 2-element array of f64 where the first element is the horizontal scroll value and the second
    element is the vertical scroll value.
*/
mouse_get_scroll :: #force_inline proc(app: ^Application) -> [2]f64 {
	return app.mouse.scroll
}
