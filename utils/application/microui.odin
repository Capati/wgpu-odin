package application

// Packages
import intr "base:intrinsics"
import mu "vendor:microui"

// Local packages
import "./../../wgpu"
import wmu "./../microui"

MicroUI_Init_Info :: struct {
	num_frames_in_flight:       u32,
	depth_stencil_format:       wgpu.Texture_Format,
	pipeline_multisample_state: wgpu.Multisample_State,
	atlas_text_width:           proc(font: mu.Font, text: string) -> (width: i32),
	atlas_text_height:          proc(font: mu.Font) -> i32,
}

DEFAULT_MICROUI_INIT_INFO :: MicroUI_Init_Info {
	num_frames_in_flight       = wmu.DEFAULT_MICROUI_FRAMES_IN_FLIGHT,
	depth_stencil_format       = .Undefined,
	pipeline_multisample_state = wgpu.DEFAULT_MULTISAMPLE_STATE,
	atlas_text_width           = mu.default_atlas_text_width,
	atlas_text_height          = mu.default_atlas_text_height,
}

/* Initializes the microui library for use in the application. */
@(require_results)
microui_init :: proc(
	app: ^Application,
	init_info := DEFAULT_MICROUI_INIT_INFO,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	app._mu_ctx = new(mu.Context, loc = loc)
	ensure(app._mu_ctx != nil, "Failed to allocate MicroUI context")
	defer if !ok {
		free(app._mu_ctx)
	}
	mu.init(app._mu_ctx)
	app._mu_ctx.text_width = init_info.atlas_text_width
	app._mu_ctx.text_height = init_info.atlas_text_height

	microui_init_info := wmu.Init_Info {
		num_frames_in_flight       = init_info.num_frames_in_flight,
		surface_config             = app.gpu.config,
		depth_stencil_format       = init_info.depth_stencil_format,
		pipeline_multisample_state = init_info.pipeline_multisample_state,
	}
	wmu.init(microui_init_info, loc) or_return

	return true
}

microui_destroy :: proc(app: ^Application) {
	if microui_is_initialized(app) {
		wmu.destroy()
		free(app._mu_ctx)
	}
}

@(require_results)
microui_is_initialized :: #force_inline proc(app: ^Application) -> bool {
	return app._mu_ctx != nil
}

microui_new_frame :: proc(app: ^Application) {
	mu.begin(app._mu_ctx)
}

microui_end_frame :: proc(app: ^Application) {
	mu.end(app._mu_ctx)
}

@(require_results)
microui_draw :: proc(app: ^Application, pass: wgpu.Render_Pass) -> (ok: bool) {
	return wmu.render(app._mu_ctx, pass)
}

@(require_results)
microui_mouse_button :: proc(button: Mouse_Button) -> (mu_mouse: mu.Mouse) {
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
microui_key :: proc(key: Key) -> (mu_key: mu.Key) {
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

microui_handle_events :: proc(app: ^Application, event: Event) {
	#partial switch &ev in event {
	// case Text_Input_Event:
	// 	mu.input_text(mu_ctx, string(cstring(&ev.buf[0])))
	case Key_Event:
		if ev.action == .Pressed {
			mu.input_key_down(app._mu_ctx, microui_key(ev.key))
		} else {
			mu.input_key_up(app._mu_ctx, microui_key(ev.key))
		}
	case Mouse_Button_Event:
		if ev.action == .Pressed {
			mu.input_mouse_down(
				app._mu_ctx,
				i32(ev.pos.x),
				i32(ev.pos.y),
				microui_mouse_button(ev.button),
			)
		} else {
			mu.input_mouse_up(
				app._mu_ctx,
				i32(ev.pos.x),
				i32(ev.pos.y),
				microui_mouse_button(ev.button),
			)
		}
	case Mouse_Wheel_Event:
		mu.input_scroll(app._mu_ctx, i32(ev.x * -25), i32(ev.y * -25))
	case Mouse_Moved_Event:
		mu.input_mouse_move(app._mu_ctx, i32(ev.x), i32(ev.y))
	}
}

Combobox_Item :: struct($T: typeid) where intr.type_is_enum(T) {
	item: T,
	name: string,
}

microui_combobox :: proc(
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

microui_slider :: proc(
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
