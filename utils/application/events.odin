package application

// Core
import sa "core:container/small_array"

EVENTS_MAX_CAPACITY :: #config(VENTS_MAX_CAPACITY, 256)

Input_Action :: enum u8 {
	None,
	Pressed,
	Released,
}

QuitEvent :: struct {}

Resize_Event :: struct {
	size: Vec2u,
}

Key_Event :: struct {
	key:      Key,
	scancode: Scancode,
}

Key_Pressed_Event :: distinct Key_Event

Key_Released_Event :: distinct Key_Event

Mouse_Button_Event :: struct {
	button: Mouse_Button,
	pos:    Vec2f,
}

Mouse_Button_Pressed_Event :: distinct Mouse_Button_Event

Mouse_Button_Released_Event :: distinct Mouse_Button_Event

Mouse_Wheel_Event :: distinct Vec2f

Mouse_Moved_Event :: struct {
	pos:    Vec2f,
	button: Mouse_Button,
	action: Input_Action,
}

Minimized_Event :: struct {
	minimized: bool,
}

Restored_Event :: struct {
	restored: bool,
}

Event :: union {
	QuitEvent,
	Resize_Event,
	Key_Pressed_Event,
	Key_Released_Event,
	Mouse_Button_Pressed_Event,
	Mouse_Button_Released_Event,
	Mouse_Wheel_Event,
	Mouse_Moved_Event,
	Minimized_Event,
	Restored_Event,
}

Events :: struct {
	data: sa.Small_Array(EVENTS_MAX_CAPACITY, Event),
}

events_empty :: proc "contextless" (self: ^Events) -> bool {
	return sa.len(self.data) == 0
}

events_poll :: proc "contextless" (self: ^Events) -> (event: Event, ok: bool) {
	return sa.pop_front_safe(&self.data)
}

events_push :: proc "contextless" (self: ^Events, event: Event) -> bool {
	return sa.push_back(&self.data, event)
}
