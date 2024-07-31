package application

Mouse_Moved_Event :: struct {
	x, y:       f32,
	xrel, yrel: f32,
}

Mouse_Button_Event :: struct {
	button:  Mouse_Button,
	action:  Mouse_Input_Action,
	pos:     Mouse_Position,
	presses: u32,
}

Mouse_Wheel_Event :: distinct Mouse_Position

Mouse_Event :: union {
	Mouse_Moved_Event,
	Mouse_Button_Event,
	Mouse_Wheel_Event,
}
