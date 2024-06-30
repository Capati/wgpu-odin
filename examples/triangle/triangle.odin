package triangle

// Core
import "core:fmt"

// Package
import wgpu "../../wrapper"

// Framework
import app "../framework/application"
import "../framework/application/events"
import "../framework/renderer"

State :: struct {
	using gpu:       ^renderer.Renderer,
	render_pipeline: wgpu.Render_Pipeline,
}

Error :: union #shared_nil {
	app.Application_Error,
	wgpu.Error,
}

init_example :: proc() -> (state: State, err: Error) {
	state.gpu = renderer.init() or_return
	defer if err != nil do renderer.deinit(state)

	shader_source := #load("./triangle.wgsl")

	shader_module := wgpu.device_create_shader_module(
		&state.device,
		&{label = "Red triangle module", source = cstring(raw_data(shader_source))},
	) or_return
	defer wgpu.shader_module_release(&shader_module)

	state.render_pipeline = wgpu.device_create_render_pipeline(
		&state.device,
		&{
			label = "Render Pipeline",
			vertex = {module = shader_module.ptr, entry_point = "vs"},
			fragment = &{
				module = shader_module.ptr,
				entry_point = "fs",
				targets = {
					{
						format = state.config.format,
						blend = &wgpu.Blend_State_Replace,
						write_mask = wgpu.Color_Write_Mask_All,
					},
				},
			},
			multisample = wgpu.Default_Multisample_State,
		},
	) or_return

	return
}

deinit_example :: proc(using state: ^State) {
	wgpu.render_pipeline_release(&render_pipeline)
	renderer.deinit(gpu)
}

render :: proc(using state: ^State) -> (err: Error) {
	frame := renderer.get_current_texture_frame(gpu) or_return
	defer wgpu.texture_release(&frame.texture)
	if skip_frame do return

	view := wgpu.texture_create_view(&frame.texture, nil) or_return
	defer wgpu.texture_view_release(&view)

	encoder := wgpu.device_create_command_encoder(&device) or_return
	defer wgpu.command_encoder_release(&encoder)

	render_pass := wgpu.command_encoder_begin_render_pass(
		&encoder,
		&{
			label = "Red Triangle Render Pass",
			color_attachments = []wgpu.Render_Pass_Color_Attachment {
				{
					view = view.ptr,
					resolve_target = nil,
					load_op = .Clear,
					store_op = .Store,
					clear_value = wgpu.Color_Green,
				},
			},
			depth_stencil_attachment = nil,
		},
	)
	defer wgpu.render_pass_encoder_release(&render_pass)

	wgpu.render_pass_encoder_set_pipeline(&render_pass, render_pipeline.ptr)
	wgpu.render_pass_encoder_draw(&render_pass, 3)
	wgpu.render_pass_encoder_end(&render_pass) or_return

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
	app_properties.title = "Red Triangle"
	if app.init(app_properties) != .No_Error do return
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
				err := resize_surface(&state, {ev.width, ev.height})
				if err != nil do break main_loop
			}
		}

		if err := render(&state); err != nil do break main_loop
	}

	fmt.println("Exiting...")
}
