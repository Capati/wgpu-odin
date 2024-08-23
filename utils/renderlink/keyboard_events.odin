package renderlink

Key_Event :: struct {
	key:       Keyboard_Key,
	scancode:  Keyboard_Scancode,
	is_repeat: bool,
	action:    Key_Action,
}

Text_Input_Event :: struct {
	buf:  [32]u8,
	size: int,
	ch:   rune,
}

// Represents a text editing event (e.g., for IME)
Text_Edited_Event :: struct {
	using _base:   Text_Input_Event,
	start, length: i32,
}

Keyboard_Event :: union {
	Key_Event,
	Text_Input_Event,
	Text_Edited_Event,
}
