package events

Text_Input_Event :: struct {
	buf: [32]u8,
	ch:  string,
}

Key_Event :: struct {
	key:    Key,
	repeat: bool,
	mods:   Key_Mods,
}

Key_Press_Event :: distinct Key_Event
Key_Release_Event :: distinct Key_Event

Position :: struct {
	x, y: i32,
}

Mouse_Motion_Event :: distinct Position
Mouse_Scroll_Event :: distinct Position

Mouse_Button :: enum {
	Left,
	Right,
	Middle,
	Four,
	Five,
}

Mouse_Button_Event :: struct {
	button: Mouse_Button,
	pos:    Position,
	mods:   Key_Mods,
}

Mouse_Press_Event :: distinct Mouse_Button_Event
Mouse_Release_Event :: distinct Mouse_Button_Event

Framebuffer_Resize_Event :: struct {
	width:  u32,
	height: u32,
}

Minimized_Event :: struct {
	value: bool,
}

Focus_Event :: struct {
	value: bool,
}

Quit_Event :: distinct bool
