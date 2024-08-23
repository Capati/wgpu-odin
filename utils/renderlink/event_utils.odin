package renderlink

// Vendor
import mu "vendor:microui"

event_mu_mouse :: proc(button: Mouse_Button) -> (mu_mouse: mu.Mouse) {
	if button == .Left do mu_mouse = .LEFT
	else if button == .Right do mu_mouse = .RIGHT
	else if button == .Middle do mu_mouse = .MIDDLE
	return
}

event_mu_key :: proc(key: Keyboard_Key) -> (mu_key: mu.Key) {
	if key == .Left_Shift || key == .Right_Shift do mu_key = .SHIFT
	else if key == .Left_Ctrl || key == .Right_Ctrl do mu_key = .CTRL
	else if key == .Left_Alt || key == .Right_Alt do mu_key = .ALT
	else if key == .Backspace do mu_key = .BACKSPACE
	else if key == .Return do mu_key = .RETURN
	return
}

event_mu_set_event :: proc(mu_ctx: ^mu.Context, event: Event) {
	#partial switch &ev in event {
	case Text_Input_Event:
		mu.input_text(mu_ctx, string(cstring(&ev.buf[0])))
	case Key_Event:
		if ev.action == .Pressed {
			mu.input_key_down(mu_ctx, event_mu_key(ev.key))
		} else {
			mu.input_key_up(mu_ctx, event_mu_key(ev.key))
		}
	case Mouse_Button_Event:
		if ev.action == .Pressed {
			mu.input_mouse_down(mu_ctx, i32(ev.pos.x), i32(ev.pos.y), event_mu_mouse(ev.button))
		} else {
			mu.input_mouse_up(mu_ctx, i32(ev.pos.x), i32(ev.pos.y), event_mu_mouse(ev.button))
		}
	case Mouse_Wheel_Event:
		mu.input_scroll(mu_ctx, i32(ev.x * -25), i32(ev.y * -25))
	case Mouse_Moved_Event:
		mu.input_mouse_move(mu_ctx, i32(ev.x), i32(ev.y))
	}
}
