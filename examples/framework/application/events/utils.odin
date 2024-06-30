package events

// Vendor
import mu "vendor:microui"

mu_input_mouse :: proc(button: Mouse_Button) -> (mu_mouse: mu.Mouse) {
	if button == .Left do mu_mouse = .LEFT
	else if button == .Right do mu_mouse = .RIGHT
	else if button == .Middle do mu_mouse = .MIDDLE
	return
}

mu_input_key :: proc(key: Key) -> (mu_key: mu.Key) {
	if key == .Lshift || key == .Rshift do mu_key = .SHIFT
	else if key == .Lctrl || key == .Rctrl do mu_key = .CTRL
	else if key == .Lalt || key == .Ralt do mu_key = .ALT
	else if key == .Backspace do mu_key = .BACKSPACE
	else if key == .Return do mu_key = .RETURN
	return
}
