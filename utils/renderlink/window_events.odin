package renderlink

Focus_Event :: struct {
	value: bool,
}

Mouse_Focus_Event :: distinct Focus_Event

Visible_Event :: struct {
	value: bool,
}

Moved_Event :: struct {
	value: bool,
}

Minimized_Event :: struct {
	value: bool,
}

Restored_Event :: struct {
	value: bool,
}

Resize_Event :: distinct Window_Size

Display_Rotated_Event :: struct {
	index:       u32,
	orientation: Display_Orientation,
}

Window_Event :: union {
	Focus_Event,
	Mouse_Focus_Event,
	Visible_Event,
	Resize_Event,
	Display_Rotated_Event,
}
