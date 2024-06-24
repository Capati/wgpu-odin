package tutorial3_pipeline_challenge

// Core
import "core:fmt"

// Package
import wgpu "../../../../wrapper"

// Framework
import app "../../../framework/application"
import "../../../framework/application/events"
import "../../../framework/renderer"

State :: struct {
	gpu:                       ^renderer.Renderer,
	render_pipeline:           wgpu.Render_Pipeline,
	challenge_render_pipeline: wgpu.Render_Pipeline,
	use_color:                 bool,
}

Error :: union #shared_nil {
	app.Application_Error,
	wgpu.Error,
}

init_example :: proc() -> (state: State, err: Error) {
	state.gpu = renderer.init() or_return
	defer if err != nil do renderer.deinit(state.gpu)

	// Use the same shader from the Tutorial 3 - Pipeline
	shader_source := #load("./../tutorial3_pipeline/shader.wgsl")
	shader_module := wgpu.device_create_shader_module(
		&state.gpu.device,
		&{source = cstring(raw_data(shader_source))},
	) or_return
	defer wgpu.shader_module_release(&shader_module)

	render_pipeline_layout := wgpu.device_create_pipeline_layout(
		&state.gpu.device,
		&{label = "Render Pipeline Layout"},
	) or_return
	defer wgpu.pipeline_layout_release(&render_pipeline_layout)

	render_pipeline_descriptor := wgpu.Render_Pipeline_Descriptor {
		label = "Render Pipeline",
		layout = render_pipeline_layout.ptr,
		vertex = {module = shader_module.ptr, entry_point = "vs_main"},
		fragment = &{
			module = shader_module.ptr,
			entry_point = "fs_main",
			targets = {
				{
					format = state.gpu.config.format,
					blend = &wgpu.Blend_State_Replace,
					write_mask = wgpu.Color_Write_Mask_All,
				},
			},
		},
		primitive = {topology = .Triangle_List, front_face = .CCW, cull_mode = .Back},
		depth_stencil = nil,
		multisample = {count = 1, mask = ~u32(0), alpha_to_coverage_enabled = false},
	}

	state.render_pipeline = wgpu.device_create_render_pipeline(
		&state.gpu.device,
		&render_pipeline_descriptor,
	) or_return
	defer if err != nil do wgpu.render_pipeline_release(&state.render_pipeline)

	challenge_shader_source := #load("./challenge.wgsl")
	challenge_shader_module := wgpu.device_create_shader_module(
		&state.gpu.device,
		&{source = cstring(raw_data(challenge_shader_source))},
	) or_return
	defer wgpu.shader_module_release(&challenge_shader_module)

	challenge_render_pipeline_descriptor := wgpu.Render_Pipeline_Descriptor {
		label = "Challenge Render Pipeline",
		layout = render_pipeline_layout.ptr,
		vertex = {module = challenge_shader_module.ptr, entry_point = "vs_main"},
		fragment = &{
			module = challenge_shader_module.ptr,
			entry_point = "fs_main",
			targets = {
				{
					format = state.gpu.config.format,
					blend = &wgpu.Blend_State_Replace,
					write_mask = wgpu.Color_Write_Mask_All,
				},
			},
		},
		primitive = {topology = .Triangle_List, front_face = .CCW, cull_mode = .Back},
		depth_stencil = nil,
		multisample = {count = 1, mask = ~u32(0), alpha_to_coverage_enabled = false},
	}

	state.challenge_render_pipeline = wgpu.device_create_render_pipeline(
		&state.gpu.device,
		&challenge_render_pipeline_descriptor,
	) or_return

	return
}

deinit_example :: proc(using state: ^State) {
	wgpu.render_pipeline_release(&challenge_render_pipeline)
	wgpu.render_pipeline_release(&render_pipeline)
	renderer.deinit(gpu)
}

render :: proc(using state: ^State) -> (err: Error) {
	frame := renderer.get_current_texture_frame(gpu) or_return
	defer wgpu.texture_release(&frame.texture)
	if gpu.skip_frame do return

	view := wgpu.texture_create_view(&frame.texture, nil) or_return
	defer wgpu.texture_view_release(&view)

	encoder := wgpu.device_create_command_encoder(
		&gpu.device,
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
					clear_value = {0.1, 0.2, 0.3, 1.0},
				},
			},
			depth_stencil_attachment = nil,
		},
	)
	defer wgpu.render_pass_encoder_release(&render_pass)

	// Use the colored pipeline if `use_color` is `true`
	if use_color {
		wgpu.render_pass_encoder_set_pipeline(&render_pass, challenge_render_pipeline.ptr)
	} else {
		wgpu.render_pass_encoder_set_pipeline(&render_pass, render_pipeline.ptr)
	}

	wgpu.render_pass_encoder_draw(&render_pass, 3)
	wgpu.render_pass_encoder_end(&render_pass) or_return

	command_buffer := wgpu.command_encoder_finish(&encoder) or_return
	defer wgpu.command_buffer_release(&command_buffer)

	wgpu.queue_submit(&gpu.queue, command_buffer.ptr)
	wgpu.surface_present(&gpu.surface)

	return
}

resize_surface :: proc(using state: ^State, size: app.Physical_Size) -> (err: Error) {
	renderer.resize_surface(gpu, {size.width, size.height}) or_return
	return
}

main :: proc() {
	app_properties := app.Default_Properties
	app_properties.title = "Tutorial 3 - Pipeline Challenge"
	if app.init(app_properties) != nil do return
	defer app.deinit()

	state, state_err := init_example()
	if state_err != nil do return
	defer deinit_example(&state)

	fmt.printf("Entering main loop...\n\n")

	main_loop: for {
		event: events.Event
		for app.poll_events(&event) {
			#partial switch &ev in event {
			case events.Quit_Event:
				break main_loop
			case events.Key_Press_Event:
				if ev.key == .Space do state.use_color = true
			case events.Key_Release_Event:
				if ev.key == .Space do state.use_color = false
			case events.Framebuffer_Resize_Event:
				err := resize_surface(&state, {ev.width, ev.height})
				if err != nil do break main_loop
			}
		}

		if err := render(&state); err != nil do break main_loop
	}

	fmt.println("Exiting...")
}
