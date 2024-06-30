package microui_example

// Core
import "core:fmt"
import "core:mem"

// Vendor
import mu "vendor:microui"

// Package
import wgpu "../../wrapper"
import wmu "./../../utils/microui"

// Framework
import app "../framework/application"
import "../framework/application/events"
import "../framework/renderer"

State :: struct {
	using gpu:       ^renderer.Renderer,
	mu_ctx:          ^mu.Context,
	log_buf:         [64000]u8,
	log_buf_len:     int,
	log_buf_updated: bool,
	bg:              mu.Color,
	clear_value:     wgpu.Color,
}

Error :: union #shared_nil {
	app.Application_Error,
	wgpu.Error,
	mem.Allocator_Error,
}

init_example :: proc() -> (state: State, err: Error) {
	r_properties := renderer.Default_Render_Properties
	r_properties.remove_srgb_from_surface = true // TODO(Capati): Fix srgb color
	r_properties.desired_maximum_frame_latency = 1
	r_properties.present_mode = .Fifo
	state.gpu = renderer.init(r_properties) or_return
	defer if err != nil do renderer.deinit(state)

	state.mu_ctx = wmu.init(&state.device, &state.queue, &state.surface.config) or_return

	state.bg = {56, 130, 210, 255}
	state.clear_value.a = 1.0

	return
}

render_example :: proc(using state: ^State) -> (err: Error) {
	frame := renderer.get_current_texture_frame(gpu) or_return
	defer wgpu.texture_release(&frame.texture)
	if skip_frame do return

	view := wgpu.texture_create_view(&frame.texture, nil) or_return
	defer wgpu.texture_view_release(&view)

	encoder := wgpu.device_create_command_encoder(&device) or_return
	defer wgpu.command_encoder_release(&encoder)

	// UI definition
	mu.begin(mu_ctx)
	test_window(state)
	log_window(state)
	style_window(state)
	mu.end(mu_ctx)

	clear_value.r = f64(bg.r) / 255.0
	clear_value.g = f64(bg.g) / 255.0
	clear_value.b = f64(bg.b) / 255.0

	render_pass := wgpu.command_encoder_begin_render_pass(
		&encoder,
		&{
			label = "Render Pass",
			color_attachments = []wgpu.Render_Pass_Color_Attachment {
				{view = view.ptr, load_op = .Clear, store_op = .Store, clear_value = clear_value},
			},
		},
	)

	// micro-ui rendering
	wmu.render(mu_ctx, &render_pass) or_return

	wgpu.render_pass_encoder_end(&render_pass) or_return
	wgpu.render_pass_encoder_release(&render_pass)

	command_buffer := wgpu.command_encoder_finish(&encoder) or_return
	defer wgpu.command_buffer_release(&command_buffer)

	wgpu.queue_submit(&queue, command_buffer.ptr)
	wgpu.surface_present(&surface)

	return
}

deinit_example :: proc(using s: ^State) {
	wmu.destroy()
	renderer.deinit(gpu)
	free(mu_ctx)
}

resize_surface :: proc(using state: ^State, size: app.Physical_Size) -> (err: Error) {
	renderer.resize_surface(gpu, {size.width, size.height}) or_return
	wmu.resize(i32(size.width), i32(size.height))
	return
}

main :: proc() {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)
	defer mem.tracking_allocator_destroy(&track)

	defer {
		for _, leak in track.allocation_map {
			fmt.printf("%v leaked %v bytes\n", leak.location, leak.size)
		}
		for bad_free in track.bad_free_array {
			fmt.printf("%v allocation %p was freed badly\n", bad_free.location, bad_free.memory)
		}
	}

	app_properties := app.Default_Properties
	app_properties.title = "microui Example"
	if app.init(app_properties) != nil do return
	defer app.deinit()

	state, state_err := init_example()
	if state_err != nil do return
	defer deinit_example(&state)

	fmt.printf("Entering main loop...\n\n")

	main_loop: for {
		event: events.Event
		for app.poll_event(&event) {
			#partial switch &ev in event {
			case events.Quit_Event:
				break main_loop
			case events.Framebuffer_Resize_Event:
				if err := resize_surface(&state, {ev.width, ev.height}); err != nil {
					break main_loop
				}
			case events.Text_Input_Event:
				mu.input_text(state.mu_ctx, string(cstring(&ev.buf[0])))
			case events.Mouse_Press_Event:
				mu.input_mouse_down(
					state.mu_ctx,
					ev.pos.x,
					ev.pos.y,
					mu_input_mouse_button(ev.button),
				)
			case events.Mouse_Release_Event:
				mu.input_mouse_up(
					state.mu_ctx,
					ev.pos.x,
					ev.pos.y,
					mu_input_mouse_button(ev.button),
				)
			case events.Mouse_Scroll_Event:
				mu.input_scroll(state.mu_ctx, ev.x * -25, ev.y * -25)
			case events.Mouse_Motion_Event:
				mu.input_mouse_move(state.mu_ctx, ev.x, ev.y)
			case events.Key_Press_Event:
				mu.input_key_down(state.mu_ctx, mu_input_key(ev.key))
			case events.Key_Release_Event:
				mu.input_key_up(state.mu_ctx, mu_input_key(ev.key))
			}
		}

		if err := render_example(&state); err != nil {
			break main_loop
		}
	}

	fmt.println("Exiting...")
}

mu_input_mouse_button :: proc(button: events.Mouse_Button) -> (mu_mouse: mu.Mouse) {
	if button == .Left do mu_mouse = .LEFT
	else if button == .Right do mu_mouse = .RIGHT
	else if button == .Middle do mu_mouse = .MIDDLE
	return
}

mu_input_key :: proc(key: events.Key) -> (mu_key: mu.Key) {
	if key == .Lshift || key == .Rshift do mu_key = .SHIFT
	else if key == .Lctrl || key == .Rctrl do mu_key = .CTRL
	else if key == .Lalt || key == .Ralt do mu_key = .ALT
	else if key == .Backspace do mu_key = .BACKSPACE
	else if key == .Return do mu_key = .RETURN
	return
}
