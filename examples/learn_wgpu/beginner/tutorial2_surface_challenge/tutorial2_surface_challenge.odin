package tutorial2_surface_challenge

// Core
import "core:fmt"

// Package
import wgpu "../../../../wrapper"
import "./../../../common"

// Framework
import app "../../../framework/application"
import "../../../framework/application/events"
import "../../../framework/renderer"

State :: struct {
	using _:     common.State_Base,
	clear_color: wgpu.Color,
}

Error :: common.Error

EXAMPLE_TITLE :: "Tutorial 2 - Surface Challenge"

init :: proc() -> (state: ^State, err: Error) {
	state = new(State) or_return
	defer if err != nil do free(state)

	app_properties := app.Default_Properties
	app_properties.title = EXAMPLE_TITLE
	app.init(app_properties) or_return
	defer if err != nil do app.deinit()

	state.gpu = renderer.init() or_return
	defer if err != nil do renderer.deinit(state)

	state.clear_color = wgpu.Color_Black

	state.render_pass_desc = common.create_render_pass_descriptor(
		EXAMPLE_TITLE + " Render Pass",
		state.clear_color,
	) or_return

	state.color_attachment = &state.render_pass_desc.color_attachments[0]

	return
}

deinit :: proc(using state: ^State) {
	delete(render_pass_desc.color_attachments)
	renderer.deinit(gpu)
	app.deinit()
	free(state)
}

render :: proc(using state: ^State) -> (err: Error) {
	frame := renderer.get_current_texture_frame(gpu) or_return
	if skip_frame do return
	defer renderer.release_current_texture_frame(gpu)

	view := wgpu.texture_create_view(frame.texture) or_return
	defer wgpu.texture_view_release(view)

	encoder := wgpu.device_create_command_encoder(device) or_return
	defer wgpu.command_encoder_release(encoder)

	color_attachment.view = view.ptr
	color_attachment.clear_value = wgpu.color_srgb_color_to_linear(clear_color)
	render_pass := wgpu.command_encoder_begin_render_pass(encoder, render_pass_desc)
	wgpu.render_pass_end(render_pass) or_return
	wgpu.render_pass_release(render_pass)

	command_buffer := wgpu.command_encoder_finish(encoder) or_return
	defer wgpu.command_buffer_release(command_buffer)

	wgpu.queue_submit(queue, command_buffer.ptr)
	wgpu.surface_present(surface)

	return
}

resize_surface :: proc(using state: ^State, size: app.Physical_Size) -> (err: Error) {
	renderer.resize_surface(gpu, {size.width, size.height}) or_return
	return
}

handle_events :: proc(using state: ^State) -> (should_quit: bool, err: Error) {
	event: events.Event
	for app.poll_event(&event) {
		#partial switch ev in event {
		case events.Quit_Event:
			return true, nil
		case events.Mouse_Motion_Event:
			clear_color = {
				r = cast(f64)ev.x / cast(f64)config.width,
				g = cast(f64)ev.y / cast(f64)config.height,
				b = 1.0,
				a = 1.0,
			}
		case events.Framebuffer_Resize_Event:
			if err = resize_surface(state, {ev.width, ev.height}); err != nil {
				return true, err
			}
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
