package application

Mouse_Position :: struct {
	x, y: f32,
}

Mouse_Button :: enum u8 {
	Left = 1,
	Middle,
	Right,
	Four,
	Five,
}

Mouse_Input_Action :: enum u8 {
	Pressed,
	Released,
}

Mouse_Error :: enum u8 {
	None,
}

Mouse_State :: struct {
	position       : Mouse_Position,
	scroll         : Mouse_Position,
	current_state  : u32,
	previous_state : u32,
	tracker        : Click_Tracker,
	system_cursors : map[System_Cursor]Cursor_Impl,
}

// Initialize the mouse subsystem.
mouse_init :: _mouse_init

// Clean up and free resources used by the mouse subsystem.
mouse_destroy :: _mouse_destroy

// Update the mouse state for the current frame.
mouse_update_state :: _mouse_update_state

// Reset the mouse state to its initial values.
mouse_reset_state :: _mouse_reset_state

// Gets the current cursor.
mouse_get_cursor :: _mouse_get_cursor

// Returns the current position of the mouse.
mouse_get_position :: _mouse_get_position

// Gets whether relative mode is enabled for the mouse.
mouse_get_relative_mode :: _mouse_get_relative_mode

// Gets a cursor pointer representing a system-native hardware cursor.
mouse_get_system_cursor :: _mouse_get_system_cursor

// Returns the current x-position of the mouse.
mouse_get_x :: _mouse_get_x

// Returns the current y-position of the mouse.
mouse_get_y :: _mouse_get_y

// Gets whether cursor functionality is supported.
mouse_is_cursor_supported :: _mouse_is_cursor_supported

// Checks whether any specified mouse button is just pressed once.
mouse_is_pressed :: _mouse_is_pressed

// Checks whether any specified mouse button is being pressed.
mouse_is_down :: _mouse_is_down

// Checks whether any specified mouse button is just released once.
mouse_is_released :: _mouse_is_released

// Checks whether any specified mouse button is NOT being pressed.
mouse_is_up :: _mouse_is_up

// Returns the amount of mouse scroll/wheel.
mouse_get_scroll :: _mouse_get_scroll

// Checks if the mouse is grabbed.
mouse_is_grabbed :: _mouse_is_grabbed

// Checks if the cursor is visible.
mouse_is_visible :: _mouse_is_visible

// Sets the current mouse cursor.
mouse_set_cursor :: _mouse_set_cursor

// Grabs the mouse and confines it to the window.
mouse_set_grabbed :: _mouse_set_grabbed

// Sets the current position of the mouse.
mouse_set_position :: _mouse_set_position

// Sets whether relative mode is enabled for the mouse.
mouse_set_relative_mode :: _mouse_set_relative_mode

// Sets the current visibility of the cursor.
mouse_set_visible :: _mouse_set_visible

// Sets the current X position of the mouse.
mouse_set_x :: _mouse_mouse_set_x

// Sets the current Y position of the mouse.
mouse_set_y :: _mouse_mouse_set_y

// Check if double click is triggered for the current frame.
mouse_is_double_click :: _mouse_is_double_click
