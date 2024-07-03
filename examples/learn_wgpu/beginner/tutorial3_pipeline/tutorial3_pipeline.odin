package tutorial3_pipeline

// Core
import "core:fmt"

// Package
import "../../../../utils/shaders"
import wgpu "../../../../wrapper"
import "./../../../common"

// Framework
import app "../../../framework/application"
import "../../../framework/application/events"
import "../../../framework/renderer"

State :: struct {
	using _:         common.State_Base,
	render_pipeline: wgpu.Render_Pipeline,
}

Error :: common.Error

EXAMPLE_TITLE :: "Tutorial 3 - Pipeline"

init :: proc() -> (state: ^State, err: Error) {
	state = new(State) or_return
	defer if err != nil do free(state)

	app_properties := app.Default_Properties
	app_properties.title = EXAMPLE_TITLE
	app.init(app_properties) or_return
	defer if err != nil do app.deinit()

	state.gpu = renderer.init() or_return
	defer if err != nil do renderer.deinit(state)

	SHADER_SRC: string : #load("./shader.wgsl", string)
	COMBINED_SHADER_SRC :: shaders.SRGB_TO_LINEAR_WGSL + SHADER_SRC
	shader_module := wgpu.device_create_shader_module(
		&state.device,
		&{source = COMBINED_SHADER_SRC},
	) or_return
	defer wgpu.shader_module_release(&shader_module)

	render_pipeline_layout := wgpu.device_create_pipeline_layout(
		&state.device,
		&{label = EXAMPLE_TITLE + " Layout"},
	) or_return
	defer wgpu.pipeline_layout_release(&render_pipeline_layout)

	render_pipeline_descriptor := wgpu.Render_Pipeline_Descriptor {
		label = EXAMPLE_TITLE + " Render Pipeline",
		layout = render_pipeline_layout.ptr,
		vertex = {module = shader_module.ptr, entry_point = "vs_main"},
		fragment = &{
			module = shader_module.ptr,
			entry_point = "fs_main",
			targets = {
				{
					format = state.config.format,
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
		&state.device,
		&render_pipeline_descriptor,
	) or_return

	state.render_pass_desc = common.create_render_pass_descriptor(
		EXAMPLE_TITLE + " Render Pass",
		wgpu.color_srgb_to_linear(wgpu.Color{0.1, 0.2, 0.3, 1.0}),
	) or_return

	// Get a reference to the first color attachment
	state.color_attachment = &state.render_pass_desc.color_attachments[0]

	return
}

deinit :: proc(using state: ^State) {
	delete(render_pass_desc.color_attachments)
	wgpu.render_pipeline_release(&render_pipeline)
	renderer.deinit(gpu)
	app.deinit()
	free(state)
}

render :: proc(using state: ^State) -> (err: Error) {
	frame := renderer.get_current_texture_frame(gpu) or_return
	if skip_frame do return
	defer wgpu.texture_release(&frame.texture)

	view := wgpu.texture_create_view(&frame.texture) or_return
	defer wgpu.texture_view_release(&view)

	encoder := wgpu.device_create_command_encoder(&device) or_return
	defer wgpu.command_encoder_release(&encoder)

	color_attachment.view = view.ptr
	render_pass := wgpu.command_encoder_begin_render_pass(&encoder, &render_pass_desc)
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

handle_events :: proc(using state: ^State) -> (should_quit: bool, err: Error) {
	event: events.Event
	for app.poll_event(&event) {
		#partial switch &ev in event {
		case events.Quit_Event:
			return true, nil
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
