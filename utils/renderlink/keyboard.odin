package application

Key_Action :: enum u8 {
	Pressed,
	Released,
}

Keyboard_State :: struct {
	current_state  : []u8,
	previous_state : []u8,
	num_keys       : int,
	key_repeat     : bool,
}

// Gets the key corresponding to the given hardware scancode.
keyboard_get_key_from_scancode :: _keyboard_get_key_from_scancode

// Gets the hardware scancode corresponding to the given key.
keyboard_get_scancode_from_key :: _keyboard_get_scancode_from_key

// Gets whether key repeat is enabled.
keyboard_has_key_repeat :: _keyboard_has_key_repeat

// Gets whether screen keyboard is supported.
keyboard_has_screen_keyboard :: _keyboard_has_screen_keyboard

// Gets whether text input events are enabled.
keyboard_has_text_input :: _keyboard_has_text_input

// Checks whether any specified key is just pressed once.
keyboard_is_pressed :: _keyboard_is_pressed

// Checks whether any specified key is being pressed.
keyboard_is_down :: _keyboard_is_down

// Checks whether any specified key is just released once.
keyboard_is_released :: _keyboard_is_released

// Checks whether any specified key is NOT being pressed.
keyboard_is_up :: _keyboard_is_up

// Checks whether any specified scancode key is just pressed once.
keyboard_scancode_is_pressed :: _keyboard_scancode_is_pressed

// Checks whether any specified scancode key is being pressed.
keyboard_scancode_is_down :: _keyboard_scancode_is_down

// Checks whether any specified scancode key is just released once.
keyboard_scancode_is_released :: _keyboard_scancode_is_released

// Checks whether any specified scancode key is NOT being pressed.
keyboard_scancode_is_up :: _keyboard_scancode_is_up

// Get key pressed (keycode)
keyboard_get_key_pressed :: _keyboard_get_key_pressed

// Enables or disables key repeat for `key_pressed` callback.
keyboard_set_key_repeat :: _keyboard_set_key_repeat

keyboard_set_text_input_enable :: _keyboard_set_text_input_enable

keyboard_set_text_input_enable_rect :: _keyboard_set_text_input_enable_rect

// Enables or disables text input events.
keyboard_set_text_input :: proc {
	keyboard_set_text_input_enable,
	keyboard_set_text_input_enable_rect,
}

// Get the current state of modifier keys.
keyboard_get_mod_state :: _keyboard_get_mod_state
