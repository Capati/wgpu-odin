#+build !js
package application

// Vendor
import "vendor:glfw"

/* Updates the state of the mouse. */
mouse_update :: proc "contextless" (app := app_context) #no_bounds_check {
	copy(app.mouse.previous[:], app.mouse.current[:])
	app.mouse.last_button_pressed = .Unknown

	// Update button states
	for button in Mouse_Button {
		if button == .Unknown {
			continue
		}
		state := glfw.GetMouseButton(window_get_handle(app.window), i32(button))
		app.mouse.current[button] = state == glfw.PRESS
		if app.mouse.current[button] && !app.mouse.previous[button] {
			app.mouse.last_button_pressed = button
		}
	}

	// Update position
	app.mouse.previous_position = app.mouse.position
	app.mouse.position[0], app.mouse.position[1] = glfw.GetCursorPos(window_get_handle(app.window))

	app.mouse.previous_scroll = app.mouse.scroll
	app.mouse.scroll = {0, 0}
}
