#+private
#+build linux, darwin, windows
package renderlink

// Vendor
import sdl "vendor:sdl2"

_button_to_mask :: proc "contextless" (button: Mouse_Button) -> u32 {
	return u32(sdl.BUTTON(i32(button)))
}

_buttons_to_mask :: proc "contextless" (buttons: ..Mouse_Button) -> u32 {
	mask: u32
	for b in buttons {
		mask |= _button_to_mask(b)
	}
	return mask
}

_get_state :: proc "contextless" (button: sdl.MouseButtonEvent) -> (mouse: Mouse_Button_Event) {
	switch button.button {
	case sdl.BUTTON_LEFT:
		mouse.button = .Left
	case sdl.BUTTON_MIDDLE:
		mouse.button = .Middle
	case sdl.BUTTON_RIGHT:
		mouse.button = .Right
	case sdl.BUTTON_X1:
		mouse.button = .Four
	case sdl.BUTTON_X2:
		mouse.button = .Five
	}

	mouse.pos = {f32(button.x), f32(button.y)}
	mouse.action = button.type == .MOUSEBUTTONDOWN ? .Pressed : .Released

	return
}
