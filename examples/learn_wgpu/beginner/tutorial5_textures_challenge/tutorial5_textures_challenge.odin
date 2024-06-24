package tutorial5_textures_challenge

// Core
import "core:fmt"

// Package
import wgpu "../../../../wrapper"
import "../tutorial5_textures/texture"

// Framework
import app "../../../framework/application"
import "../../../framework/application/events"
import "../../../framework/renderer"

Vertex :: struct {
	position:   [3]f32,
	tex_coords: [2]f32,
}

State :: struct {
	gpu:                ^renderer.Renderer,
	diffuse_bind_group: wgpu.Bind_Group,
	cartoon_bind_group: wgpu.Bind_Group,
	render_pipeline:    wgpu.Render_Pipeline,
	num_indices:        u32,
	vertex_buffer:      wgpu.Buffer,
	index_buffer:       wgpu.Buffer,
	is_space_pressed:   bool,
}

Error :: union #shared_nil {
	app.Application_Error,
	wgpu.Error,
}

init_example :: proc() -> (state: State, err: Error) {
	state.gpu = renderer.init() or_return
	defer if err != nil do renderer.deinit(state.gpu)

	// Load our tree image to texture
	diffuse_texture := texture.texture_from_image(
		&state.gpu.device,
		&state.gpu.queue,
		"assets/learn_wgpu/tutorial5/happy-tree.png",
	) or_return
	defer texture.texture_destroy(&diffuse_texture)

	texture_bind_group_layout := wgpu.device_create_bind_group_layout(
		&state.gpu.device,
		&{
			label = "TextureBindGroupLayout",
			entries = {
				{
					binding = 0,
					visibility = {.Fragment},
					type = wgpu.Texture_Binding_Layout {
						multisampled = false,
						view_dimension = .D2,
						sample_type = .Float,
					},
				},
				{
					binding = 1,
					visibility = {.Fragment},
					type = wgpu.Sampler_Binding_Layout{type = .Filtering},
				},
			},
		},
	) or_return
	defer wgpu.bind_group_layout_release(&texture_bind_group_layout)

	state.diffuse_bind_group = wgpu.device_create_bind_group(
		&state.gpu.device,
		&wgpu.Bind_Group_Descriptor {
			label = "diffuse_bind_group",
			layout = texture_bind_group_layout.ptr,
			entries = {
				{binding = 0, resource = diffuse_texture.view.ptr},
				{binding = 1, resource = diffuse_texture.sampler.ptr},
			},
		},
	) or_return
	defer if err != nil do wgpu.bind_group_release(&state.diffuse_bind_group)

	cartoon_texture := texture.texture_from_image(
		&state.gpu.device,
		&state.gpu.queue,
		"assets/learn_wgpu/tutorial5/happy-tree-cartoon.png",
	) or_return
	defer texture.texture_destroy(&cartoon_texture)

	state.cartoon_bind_group = wgpu.device_create_bind_group(
		&state.gpu.device,
		&wgpu.Bind_Group_Descriptor {
			label = "cartoon_bind_group",
			layout = texture_bind_group_layout.ptr,
			entries = {
				{binding = 0, resource = cartoon_texture.view.ptr},
				{binding = 1, resource = cartoon_texture.sampler.ptr},
			},
		},
	) or_return
	defer if err != nil do wgpu.bind_group_release(&state.cartoon_bind_group)

	render_pipeline_layout := wgpu.device_create_pipeline_layout(
		&state.gpu.device,
		&{label = "Render Pipeline Layout", bind_group_layouts = {texture_bind_group_layout.ptr}},
	) or_return
	defer wgpu.pipeline_layout_release(&render_pipeline_layout)

	vertex_buffer_layout := wgpu.Vertex_Buffer_Layout {
		array_stride = size_of(Vertex),
		step_mode    = .Vertex,
		attributes   = {
			{offset = 0, shader_location = 0, format = .Float32x3},
			{
				offset = cast(u64)offset_of(Vertex, tex_coords),
				shader_location = 1,
				format = .Float32x2,
			},
		},
	}

	// Use the same shader from the Tutorial 5- Textures
	shader_source := #load("./../tutorial5_textures/shader.wgsl")
	shader_module := wgpu.device_create_shader_module(
		&state.gpu.device,
		&{source = cstring(raw_data(shader_source))},
	) or_return
	defer wgpu.shader_module_release(&shader_module)

	render_pipeline_descriptor := wgpu.Render_Pipeline_Descriptor {
		label = "Render Pipeline",
		layout = render_pipeline_layout.ptr,
		vertex = {
			module = shader_module.ptr,
			entry_point = "vs_main",
			buffers = {vertex_buffer_layout},
		},
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

	vertices := []Vertex {
		{position = {-0.0868241, 0.49240386, 0.0}, tex_coords = {0.4131759, 0.00759614}}, // A
		{position = {-0.49513406, 0.06958647, 0.0}, tex_coords = {0.0048659444, 0.43041354}}, // B
		{position = {-0.21918549, -0.44939706, 0.0}, tex_coords = {0.28081453, 0.949397}}, // C
		{position = {0.35966998, -0.3473291, 0.0}, tex_coords = {0.85967, 0.84732914}}, // D
		{position = {0.44147372, 0.2347359, 0.0}, tex_coords = {0.9414737, 0.2652641}}, // E
	}

	indices: []u16 = {0, 1, 4, 1, 2, 4, 2, 3, 4}

	state.num_indices = cast(u32)len(indices)

	state.vertex_buffer = wgpu.device_create_buffer_with_data(
		&state.gpu.device,
		&wgpu.Buffer_Data_Descriptor {
			label = "Vertex Buffer",
			contents = wgpu.to_bytes(vertices),
			usage = {.Vertex},
		},
	) or_return
	defer if err != nil do wgpu.buffer_release(&state.vertex_buffer)

	state.index_buffer = wgpu.device_create_buffer_with_data(
		&state.gpu.device,
		&wgpu.Buffer_Data_Descriptor {
			label = "Index Buffer",
			contents = wgpu.to_bytes(indices),
			usage = {.Index},
		},
	) or_return

	return
}

deinit_example :: proc(using state: ^State) {
	wgpu.buffer_release(&index_buffer)
	wgpu.buffer_release(&vertex_buffer)
	wgpu.render_pipeline_release(&render_pipeline)
	wgpu.bind_group_release(&cartoon_bind_group)
	wgpu.bind_group_release(&diffuse_bind_group)
	renderer.deinit(gpu)
}

render :: proc(using state: ^State) -> (err: Error) {
	frame := renderer.get_current_texture_frame(gpu) or_return
	defer wgpu.texture_release(&frame.texture)
	if gpu.skip_frame do return

	view := wgpu.texture_create_view(&frame.texture, nil) or_return
	defer wgpu.texture_view_release(&view)

	encoder := wgpu.device_create_command_encoder(&gpu.device) or_return
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

	wgpu.render_pass_encoder_set_pipeline(&render_pass, render_pipeline.ptr)

	if is_space_pressed {
		wgpu.render_pass_encoder_set_bind_group(&render_pass, 0, cartoon_bind_group.ptr)
	} else {
		wgpu.render_pass_encoder_set_bind_group(&render_pass, 0, diffuse_bind_group.ptr)
	}

	wgpu.render_pass_encoder_set_vertex_buffer(&render_pass, 0, vertex_buffer.ptr)
	wgpu.render_pass_encoder_set_index_buffer(
		&render_pass,
		index_buffer.ptr,
		.Uint16,
		0,
		wgpu.WHOLE_SIZE,
	)
	wgpu.render_pass_encoder_draw_indexed(&render_pass, num_indices)
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
	app_properties.title = "Tutorial 5 - Textures Challenge"
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
			case events.Key_Press_Event:
				if ev.key == .Space do state.is_space_pressed = true
			case events.Key_Release_Event:
				if ev.key == .Space do state.is_space_pressed = false
			case events.Framebuffer_Resize_Event:
				err := resize_surface(&state, {ev.width, ev.height})
				if err != nil do break main_loop
			}
		}


		if err := render(&state); err != nil do break main_loop
	}

	fmt.println("Exiting...")
}
