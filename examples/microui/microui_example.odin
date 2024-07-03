package microui_example

// Core
import "core:fmt"

// Vendor
import mu "vendor:microui"

// Package
import wgpu "../../wrapper"
import wmu "./../../utils/microui"
import "./../common"

// Framework
import app "../framework/application"
import "../framework/application/events"
import "../framework/renderer"

State :: struct {
	using _:         common.State_Base,
	mu_ctx:          ^mu.Context,
	log_buf:         [64000]u8,
	log_buf_len:     int,
	log_buf_updated: bool,
	bg:              mu.Color,
}

Error :: common.Error

EXAMPLE_TITLE :: "MicroUI"

init :: proc() -> (state: ^State, err: Error) {
	state = new(State) or_return
	defer if err != nil do free(state)

	// Initialize the application
	app_properties := app.Default_Properties
	app_properties.title = EXAMPLE_TITLE
	app.init(app_properties) or_return
	defer if err != nil do app.deinit()

	// Initialize the wgpu renderer
	r_properties := renderer.Default_Render_Properties
	r_properties.desired_maximum_frame_latency = 1
	r_properties.present_mode = .Fifo
	state.gpu = renderer.init(r_properties) or_return
	defer if err != nil do renderer.deinit(state)

	// Initialize the MicroUI renderer and context
	state.mu_ctx = wmu.init(&state.device, &state.queue, &state.surface.config) or_return

	// Set initial state
	state.bg = {56, 130, 210, 255}

	state.render_pass_desc = common.create_render_pass_descriptor(
		EXAMPLE_TITLE + " Render Pass",
		update_clear_value_from_bg(state),
	) or_return

	// Get a reference to the first color attachment
	state.color_attachment = &state.render_pass_desc.color_attachments[0]

	return
}

deinit :: proc(using state: ^State) {
	delete(render_pass_desc.color_attachments)
	wmu.destroy()
	free(mu_ctx)
	renderer.deinit(gpu)
	app.deinit()
	free(state)
}

render :: proc(using state: ^State) -> (err: Error) {
	// UI definition and update
	mu.begin(mu_ctx)
	test_window(state)
	log_window(state)
	style_window(state)
	mu.end(mu_ctx)

	// WebGPU rendering
	frame := renderer.get_current_texture_frame(gpu) or_return
	if skip_frame do return
	defer wgpu.texture_release(&frame.texture)

	view := wgpu.texture_create_view(&frame.texture) or_return
	defer wgpu.texture_view_release(&view)

	encoder := wgpu.device_create_command_encoder(&device) or_return
	defer wgpu.command_encoder_release(&encoder)

	color_attachment.view = view.ptr
	color_attachment.clear_value = update_clear_value_from_bg(state)
	render_pass := wgpu.command_encoder_begin_render_pass(&encoder, &render_pass_desc)
	defer wgpu.render_pass_encoder_release(&render_pass)

	// micro-ui rendering
	wmu.render(mu_ctx, &render_pass) or_return

	wgpu.render_pass_encoder_end(&render_pass) or_return

	command_buffer := wgpu.command_encoder_finish(&encoder) or_return
	defer wgpu.command_buffer_release(&command_buffer)

	wgpu.queue_submit(&queue, command_buffer.ptr)
	wgpu.surface_present(&surface)

	return
}

update_clear_value_from_bg :: proc(using state: ^State) -> wgpu.Color {
	return wgpu.color_srgb_to_linear(
		wgpu.Color{f64(bg.r) / 255.0, f64(bg.g) / 255.0, f64(bg.b) / 255.0, 1.0},
	)
}

resize_surface :: proc(using state: ^State, size: app.Physical_Size) -> (err: Error) {
	renderer.resize_surface(gpu, {size.width, size.height}) or_return
	wmu.resize(i32(size.width), i32(size.height))
	return
}

handle_events :: proc(state: ^State) -> (should_quit: bool, err: Error) {
	event: events.Event
	for app.poll_event(&event) {
		#partial switch &ev in event {
		case events.Quit_Event:
			return true, nil
		case events.Framebuffer_Resize_Event:
			if err = resize_surface(state, {ev.width, ev.height}); err != nil {
				return true, err
			}
		case events.Text_Input_Event:
			mu.input_text(state.mu_ctx, string(cstring(&ev.buf[0])))
		case events.Mouse_Press_Event:
			mu.input_mouse_down(state.mu_ctx, ev.pos.x, ev.pos.y, events.mu_input_mouse(ev.button))
		case events.Mouse_Release_Event:
			mu.input_mouse_up(state.mu_ctx, ev.pos.x, ev.pos.y, events.mu_input_mouse(ev.button))
		case events.Mouse_Scroll_Event:
			mu.input_scroll(state.mu_ctx, ev.x * -25, ev.y * -25)
		case events.Mouse_Motion_Event:
			mu.input_mouse_move(state.mu_ctx, ev.x, ev.y)
		case events.Key_Press_Event:
			mu.input_key_down(state.mu_ctx, events.mu_input_key(ev.key))
		case events.Key_Release_Event:
			mu.input_key_up(state.mu_ctx, events.mu_input_key(ev.key))
		}
	}

	return
}

main :: proc() {
	state, state_err := init()
	if state_err != nil do return
	defer deinit(state)

	fmt.printf("Entering main loop...\n\n")

	main_loop: for {
		should_quit, err := handle_events(state)
		if should_quit || err != nil do break main_loop
		if err = render(state); err != nil do break main_loop
	}

	fmt.println("Exiting...")
}
