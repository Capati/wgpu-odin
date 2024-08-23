//+build linux, darwin, windows
package renderlink

// Vendor
import sdl "vendor:sdl2"

when MOUSE_PACKAGE {
	convert_mouse_moved_event :: proc(e: ^sdl.Event) -> (event: Mouse_Moved_Event) {
		x := f32(e.motion.x)
		y := f32(e.motion.y)
		xrel := f32(e.motion.xrel)
		yrel := f32(e.motion.yrel)

		event = Mouse_Moved_Event {
			x    = x,
			y    = y,
			xrel = xrel,
			yrel = yrel,
		}

		return
	}

	convert_mouse_button_event :: proc(e: ^sdl.Event) -> (event: Mouse_Button_Event) {
		button: Mouse_Button

		switch e.button.button {
		case sdl.BUTTON_LEFT:
			button = .Left
		case sdl.BUTTON_MIDDLE:
			button = .Middle
		case sdl.BUTTON_RIGHT:
			button = .Right
		case sdl.BUTTON_X1:
			button = .Four
		case sdl.BUTTON_X2:
			button = .Five
		}

		event = Mouse_Button_Event {
			button = button,
			pos    = {f32(e.button.x), f32(e.button.y)},
			action = e.button.type == .MOUSEBUTTONDOWN ? .Pressed : .Released,
		}

		return
	}

	convert_mouse_scroll_event :: proc(e: ^sdl.Event) -> (event: Mouse_Wheel_Event) {
		event = Mouse_Wheel_Event{f32(e.wheel.x), f32(e.wheel.y)}
		return
	}
} else {
	convert_mouse_moved_event :: proc(_: ^sdl.Event) -> (event: Mouse_Moved_Event) {
		return
	}
	convert_mouse_button_event :: proc(_: ^sdl.Event) -> (event: Mouse_Button_Event) {
		return
	}
	convert_mouse_scroll_event :: proc(_: ^sdl.Event) -> (event: Mouse_Wheel_Event) {
		return
	}
}
