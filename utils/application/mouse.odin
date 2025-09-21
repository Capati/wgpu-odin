package application

// Vendor
import "vendor:glfw"

Mouse_Button :: enum i32 {
	Unknown = -1,
	Left    = glfw.MOUSE_BUTTON_LEFT,
	Middle  = glfw.MOUSE_BUTTON_MIDDLE,
	Right   = glfw.MOUSE_BUTTON_RIGHT,
	Four    = glfw.MOUSE_BUTTON_4,
	Five    = glfw.MOUSE_BUTTON_5,
}

/* Total number of mouse buttons available. */
MOUSE_BUTTON_COUNT :: len(Mouse_Button)

/* State of the mouse, including its position, button states, and other relevant information. */
Mouse_State :: struct {
	current:             [MOUSE_BUTTON_COUNT]bool,
	previous:            [MOUSE_BUTTON_COUNT]bool,
	last_button_pressed: Mouse_Button,
	position:            [2]f64, /* x, y coordinates */
	previous_position:   [2]f64,
	previous_scroll:     [2]f64, /* x, y scroll offsets */
	scroll:              [2]f64, /* x, y scroll offsets */
	button_repeat:       bool,
}

/* Updates the state of the mouse. */
mouse_update :: proc "contextless" (self: ^Application) #no_bounds_check {
	copy(self.mouse.previous[:], self.mouse.current[:])
	self.mouse.last_button_pressed = .Unknown

	// Update button states
	for button in Mouse_Button {
		if button == .Unknown {
			continue
		}
		state := glfw.GetMouseButton(self.window.handle, i32(button))
		self.mouse.current[button] = state == glfw.PRESS
		if self.mouse.current[button] && !self.mouse.previous[button] {
			self.mouse.last_button_pressed = button
		}
	}

	// Update position
	self.mouse.previous_position = self.mouse.position
	self.mouse.position[0], self.mouse.position[1] = glfw.GetCursorPos(self.window.handle)

	self.mouse.previous_scroll = self.mouse.scroll
    self.mouse.scroll = {0, 0}
}

/* Checks if a specific mouse button has been just pressed. */
mouse_button_is_pressed :: #force_inline proc "contextless" (
	self: ^Application,
	button: Mouse_Button,
) -> bool #no_bounds_check {
	return self.mouse.current[button] && !self.mouse.previous[button]
}

/* Checks if a specific mouse button is currently pressed down. */
mouse_button_is_down :: #force_inline proc "contextless" (
	self: ^Application,
	button: Mouse_Button,
) -> bool #no_bounds_check {
	return self.mouse.current[button]
}

/* Checks if a mouse button has been just released. */
mouse_button_is_released :: #force_inline proc "contextless" (
	self: ^Application,
	button: Mouse_Button,
) -> bool #no_bounds_check {
	return !self.mouse.current[button] && self.mouse.previous[button]
}

/* Checks if a specific mouse button is currently not pressed. */
mouse_button_is_up :: #force_inline proc "contextless" (
	self: ^Application,
	button: Mouse_Button,
) -> bool #no_bounds_check {
	return !self.mouse.current[button]
}

/* Returns the currently pressed mouse button. */
mouse_button_get_pressed :: #force_inline proc "contextless" (self: ^Application) -> Mouse_Button {
	return self.mouse.last_button_pressed
}

/* Returns the current position of the mouse cursor. */
mouse_get_position :: #force_inline proc "contextless" (self: ^Application) -> [2]f64 {
	return self.mouse.position
}

/* Returns the previous position of the mouse cursor. */
mouse_get_previous_position :: #force_inline proc "contextless" (self: ^Application) -> [2]f64 {
	return self.mouse.previous_position
}

/* Retrieves the current mouse movement. */
mouse_get_movement :: #force_inline proc "contextless" (
	self: ^Application,
) -> [2]f64 #no_bounds_check {
	return {
		self.mouse.position[0] - self.mouse.previous_position[0],
		self.mouse.position[1] - self.mouse.previous_position[1],
	}
}
/*
Retrieves the current scroll values of the mouse.

Returns:
  - A 2-element array of f64 where the first element is the horizontal scroll value and the second
    element is the vertical scroll value.
*/
mouse_get_scroll :: #force_inline proc "contextless" (self: ^Application) -> [2]f64 {
	return self.mouse.previous_scroll
}
