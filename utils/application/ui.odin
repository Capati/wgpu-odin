package application

// Packages
import intr "base:intrinsics"

// Vendor
import mu "vendor:microui"

// Local packages
import wmu "./../microui"

@(require_results)
setup_ui :: proc(app: ^Application) -> (ok: bool) {
	app.mu_ctx = new(mu.Context)
	assert(app.mu_ctx != nil, "Failed to allocate microui context")
	defer if !ok {
		free(app.mu_ctx)
	}
	mu.init(app.mu_ctx)
	app.mu_ctx.text_width = mu.default_atlas_text_width
	app.mu_ctx.text_height = mu.default_atlas_text_height

	wmu.init(app.gpu.device, app.gpu.queue, app.gpu.config) or_return

	return true
}

destroy_ui :: proc(app: ^Application) {
	if app.mu_ctx != nil {
		wmu.destroy()
		free(app.mu_ctx)
	}
}

@(require_results)
ui_draw :: proc(app: ^Application) -> (ok: bool) {
	return wmu.render(app.mu_ctx, app.cmd, app.frame.view)
}

@(require_results)
ui_mouse_button :: proc(button: MouseButton) -> (mu_mouse: mu.Mouse) {
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
ui_key :: proc(key: Key) -> (mu_key: mu.Key) {
	if key == .LeftShift || key == .RightShift {
		mu_key = .SHIFT
	} else if key == .LeftControl || key == .RightControl {
		mu_key = .CTRL
	} else if key == .LeftAlt || key == .RightAlt {
		mu_key = .ALT
	} else if key == .Backspace {
		mu_key = .BACKSPACE
	} else if key == .Enter {
		mu_key = .RETURN
	}
	return
}

ui_handle_event :: proc(app: ^Application, event: Event) {
	#partial switch &ev in event {
	// case Text_Input_Event:
	// 	mu.input_text(mu_ctx, string(cstring(&ev.buf[0])))
	case KeyEvent:
		if ev.action == .Pressed {
			mu.input_key_down(app.mu_ctx, ui_key(ev.key))
		} else {
			mu.input_key_up(app.mu_ctx, ui_key(ev.key))
		}
	case MouseButtonEvent:
		if ev.action == .Pressed {
			mu.input_mouse_down(
				app.mu_ctx,
				i32(ev.pos.x),
				i32(ev.pos.y),
				ui_mouse_button(ev.button),
			)
		} else {
			mu.input_mouse_up(app.mu_ctx, i32(ev.pos.x), i32(ev.pos.y), ui_mouse_button(ev.button))
		}
	case MouseWheelEvent:
		mu.input_scroll(app.mu_ctx, i32(ev.x * -25), i32(ev.y * -25))
	case MouseMovedEvent:
		mu.input_mouse_move(app.mu_ctx, i32(ev.x), i32(ev.y))
	}
}

ui_combobox :: proc(
	ctx: ^mu.Context,
	name: string,
	current_item: ^u32,
	items: []string,
) -> mu.Result_Set {
	id := mu.get_id(ctx, name)
	rect := mu.layout_next(ctx)
	mu.update_control(ctx, id, rect)

	// Draw main combobox button
	mu.draw_control_frame(ctx, id, rect, .BUTTON)

	// Draw current selection
	text_rect := rect
	text_rect.w -= 20
	mu.draw_control_text(ctx, items[current_item^], text_rect, .TEXT)

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
		for item, i in items {
			if .SUBMIT in mu.button(ctx, item) {
				current_item^ = u32(i)
				res += {.SUBMIT, .CHANGE}
				win.open = false
			}
		}
	}

	return res
}

ui_slider :: proc(
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
