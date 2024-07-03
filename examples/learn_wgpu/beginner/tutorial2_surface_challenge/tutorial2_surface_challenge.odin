package tutorial2_surface_challenge

// Core
import "core:fmt"

// Package
import wgpu "../../../../wrapper"

// Framework
import app "../../../framework/application"
import "../../../framework/application/events"
import "../../../framework/renderer"

State :: struct {
	using gpu:   ^renderer.Renderer,
	clear_color: wgpu.Color,
}

Error :: union #shared_nil {
	app.Application_Error,
	wgpu.Error,
}

init_example :: proc() -> (state: State, err: Error) {
	state.gpu = renderer.init() or_return
	state.clear_color = wgpu.Color_Black
	return
}

deinit_example :: proc(using state: ^State) {
	renderer.deinit(gpu)
}

render :: proc(using state: ^State) -> (err: Error) {
	frame := renderer.get_current_texture_frame(gpu) or_return
	if skip_frame do return
	defer wgpu.texture_release(&frame.texture)

	view := wgpu.texture_create_view(&frame.texture, nil) or_return
	defer wgpu.texture_view_release(&view)

	encoder := wgpu.device_create_command_encoder(
		&device,
		&wgpu.Command_Encoder_Descriptor{label = "Command Encoder"},
	) or_return
	defer wgpu.command_encoder_release(&encoder)

	render_pass := wgpu.command_encoder_begin_render_pass(
		&encoder,
		&{
			label = "Render Pass",
			color_attachments = []wgpu.Render_Pass_Color_Attachment {
				{
					view = view.ptr,
					resolve_target = nil,
					load_op = .Clear,
					store_op = .Store,
					clear_value = clear_color,
				},
			},
			depth_stencil_attachment = nil,
		},
	)
	wgpu.render_pass_encoder_end(&render_pass) or_return
	wgpu.render_pass_encoder_release(&render_pass)

	command_buffer := wgpu.command_encoder_finish(&encoder) or_return
	defer wgpu.command_buffer_release(&command_buffer)

	wgpu.queue_submit(&queue, command_buffer.ptr)
	wgpu.surface_present(&surface)

	return
}

resize_surface :: proc(using state: ^State, size: app.Physical_Size) -> (err: Error) {
	renderer.resize_surface(gpu, {size.width, size.height}) or_return
	return
}

main :: proc() {
	app_properties := app.Default_Properties
	app_properties.title = "Tutorial 2 - Surface Challenge"
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
			case events.Mouse_Motion_Event:
				state.clear_color = {
					r = cast(f64)ev.x / cast(f64)state.config.width,
					g = cast(f64)ev.y / cast(f64)state.config.height,
					b = 1.0,
					a = 1.0,
				}
			case events.Framebuffer_Resize_Event:
				err := resize_surface(&state, {ev.width, ev.height})
				if err != nil do break main_loop
			}
		}

		if err := render(&state); err != nil do break main_loop
	}

	fmt.println("Exiting...")
}
