package application

// Core
import intr "base:intrinsics"

// Vendor
import mu "vendor:microui"

@(require_results)
mu_mouse_button :: proc(button: Mouse_Button) -> (mu_mouse: mu.Mouse) {
	if button == .Left {
		mu_mouse = .LEFT
	} else if button == .Right {
		mu_mouse = .RIGHT
	} else if button == .Middle {
		mu_mouse = .MIDDLE
	}
	return
}

@(require_results)
mu_key :: proc(key: Key) -> (mu_key: mu.Key) {
	if key == .Left_Shift || key == .Right_Shift {
		mu_key = .SHIFT
	} else if key == .Left_Control || key == .Right_Control {
		mu_key = .CTRL
	} else if key == .Left_Alt || key == .Right_Alt {
		mu_key = .ALT
	} else if key == .Backspace {
		mu_key = .BACKSPACE
	} else if key == .Enter {
		mu_key = .RETURN
	}
	return
}

mu_handle_events :: proc(mu_ctx: ^mu.Context, event: Event) {
	#partial switch &ev in event {
	// case Text_Input_Event:
	// 	mu.input_text(mu_ctx, string(cstring(&ev.buf[0])))
	case Key_Pressed_Event:
		mu.input_key_down(mu_ctx, mu_key(ev.key))

	case Key_Released_Event:
		mu.input_key_up(mu_ctx, mu_key(ev.key))

	case Mouse_Button_Pressed_Event:
		mu.input_mouse_down(
			mu_ctx,
			i32(ev.pos.x),
			i32(ev.pos.y),
			mu_mouse_button(ev.button),
		)

	case Mouse_Button_Released_Event:
		mu.input_mouse_up(
			mu_ctx,
			i32(ev.pos.x),
			i32(ev.pos.y),
			mu_mouse_button(ev.button),
		)

	case Mouse_Wheel_Event:
		mu.input_scroll(mu_ctx, i32(ev.x * -25), i32(ev.y * -25))

	case Mouse_Moved_Event:
		mu.input_mouse_move(mu_ctx, i32(ev.pos.x), i32(ev.pos.y))
	}
}

Combobox_Item :: struct($T: typeid) where intr.type_is_enum(T) {
	item: T,
	name: string,
}

mu_combobox :: proc(
	ctx: ^mu.Context,
	name: string,
	current_item: ^$T,
	items: []Combobox_Item(T),
) -> mu.Result_Set where intr.type_is_enum(T) {
	id := mu.get_id(ctx, name)
	rect := mu.layout_next(ctx)
	mu.update_control(ctx, id, rect)

	// Draw main combobox button
	mu.draw_control_frame(ctx, id, rect, .BUTTON)

	// Draw current selection
	text_rect := rect
	text_rect.w -= 20
	// Find the name for the current item
	current_name := ""
	for item in items {
		if item.item == current_item^ {
			current_name = item.name
			break
		}
	}
	mu.draw_control_text(ctx, current_name, text_rect, .TEXT)

	// Draw dropdown arrow
	arrow_rect := rect
	arrow_rect.x = rect.x + rect.w - 20
	arrow_rect.w = 20
	mu.draw_icon(ctx, .EXPANDED, arrow_rect, ctx.style.colors[.TEXT])

	res: mu.Result_Set
	mouseover := mu.mouse_over(ctx, rect)

	// Initialize container before click check
	cnt := mu.get_container(ctx, name)
	if cnt.rect.w == 0 { 	// If container is newly created
		cnt.open = false
	}

	// Handle input for main button
	if .LEFT in ctx.mouse_pressed_bits && mouseover {
		cnt.open = !cnt.open
		if cnt.open {
			ctx.hover_root = cnt
			ctx.next_hover_root = cnt
			popup_rect := rect
			popup_rect.y += rect.h + ctx.style.padding - 4
			popup_rect.h = min(200, i32(len(items)) * 24)
			cnt.rect = popup_rect
			mu.bring_to_front(ctx, cnt)
		}
	}

	if mu.begin_popup(ctx, name) {
		defer mu.end_popup(ctx)
		win := mu.get_current_container(ctx)
		mu.draw_rect(ctx, mu.get_current_container(ctx).rect, ctx.style.colors[.BASE])
		mu.layout_row(ctx, {rect.w - ctx.style.padding * 2})

		for item in items {
			if .SUBMIT in mu.button(ctx, item.name) {
				current_item^ = item.item
				res += {.SUBMIT, .CHANGE}
				win.open = false
			}
		}
	}

	return res
}

mu_slider :: proc(
	ctx: ^mu.Context,
	val: ^$T,
	lo, hi: T,
	step: mu.Real = 0.0,
	fmt_string: string = mu.SLIDER_FMT,
	options: mu.Options = {.ALIGN_CENTER},
) -> (
	res: mu.Result_Set,
) where intr.type_is_numeric(T) {
	mu.push_id(ctx, uintptr(val))

	@(static) tmp: mu.Real

	tmp = mu.Real(val^)
	res = mu.slider(ctx, &tmp, mu.Real(lo), mu.Real(hi), step, fmt_string, options)
	val^ = T(tmp)
	mu.pop_id(ctx)

	return
}
