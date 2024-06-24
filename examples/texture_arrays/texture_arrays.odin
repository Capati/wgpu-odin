package texture_arrays_example

// Core
import "core:fmt"

// Package
import wgpu "../../wrapper"

// Framework
import app "../framework/application"
import "../framework/application/events"
import "../framework/renderer"

Texture_Data :: struct {
	label: cstring,
	tex:   wgpu.Texture,
	view:  wgpu.Texture_View,
	data:  [4]u8,
}

Texture_Name :: enum {
	RED,
	GREEN,
	BLUE,
	WHITE,
}

State :: struct {
	gpu:                          ^renderer.Renderer,
	device_has_optional_features: bool,
	use_uniform_workaround:       bool,
	fragment_entry_point:         cstring,
	vertex_buffer:                wgpu.Buffer,
	index_buffer:                 wgpu.Buffer,
	texture_index_buffer:         wgpu.Buffer,
	textures:                     [Texture_Name]Texture_Data,
	bind_group_layout:            wgpu.Bind_Group_Layout,
	sampler:                      wgpu.Sampler,
	bind_group:                   wgpu.Bind_Group,
	pipeline_layout:              wgpu.Pipeline_Layout,
	render_pipeline:              wgpu.Render_Pipeline,
}

Vertex :: struct {
	pos:       [2]f32,
	tex_coord: [2]f32,
	index:     u32,
}

VERTICES: []Vertex : {
	// left rectangle
	{{-1, -1}, {0, 1}, 0},
	{{-1, 1}, {0, 0}, 0},
	{{0, 1}, {1, 0}, 0},
	{{0, -1}, {1, 1}, 0},
	// right rectangle
	{{0, -1}, {0, 1}, 1},
	{{0, 1}, {0, 0}, 1},
	{{1, 1}, {1, 0}, 1},
	{{1, -1}, {1, 1}, 1},
}

// odinfmt: disable
INDICES: []u16: {
	// Left rectangle
    0, 1, 2, // 1st
    2, 0, 3, // 2nd
    // Right rectangle
    4, 5, 6, // 1st
    6, 4, 7, // 2nd
}
// odinfmt: enable

init_example :: proc() -> (state: State, err: wgpu.Error) {
	using state

	r_properties := renderer.Default_Render_Properties
	r_properties.optional_features = {
		.Sampled_Texture_And_Storage_Buffer_Array_Non_Uniform_Indexing,
	}
	r_properties.required_features = {.Texture_Binding_Array}
	gpu = renderer.init(r_properties) or_return
	defer if err != nil do renderer.deinit(gpu)

	device_has_optional_features = wgpu.device_has_feature(
		&gpu.device,
		r_properties.optional_features,
	)

	if device_has_optional_features {
		fragment_entry_point = "non_uniform_main"
	} else {
		use_uniform_workaround = true
		fragment_entry_point = "uniform_main"
	}

	base_shader_source := #load("./indexing.wgsl", cstring)

	base_shader_module := wgpu.device_create_shader_module(
		&gpu.device,
		&{source = base_shader_source},
	) or_return
	defer wgpu.shader_module_release(&base_shader_module)

	fragment_shader_module: wgpu.Shader_Module

	if !use_uniform_workaround {
		fragment_shader_source := #load("./non_uniform_indexing.wgsl", cstring)
		fragment_shader_module = wgpu.device_create_shader_module(
			&gpu.device,
			&{source = fragment_shader_source},
		) or_return
	} else {
		fragment_shader_module = wgpu.device_create_shader_module(
			&gpu.device,
			&{source = base_shader_source},
		) or_return
	}
	defer wgpu.shader_module_release(&fragment_shader_module)

	fmt.printfln("Using fragment entry point: %s", fragment_entry_point)

	vertex_buffer = wgpu.device_create_buffer_with_data(
		&gpu.device,
		&{label = "Vertex buffer", contents = wgpu.to_bytes(VERTICES), usage = {.Vertex}},
	) or_return
	defer if err != nil do wgpu.buffer_release(&vertex_buffer)

	index_buffer = wgpu.device_create_buffer_with_data(
		&gpu.device,
		&{label = "Index buffer", contents = wgpu.to_bytes(INDICES), usage = {.Index}},
	) or_return
	defer if err != nil do wgpu.buffer_release(&index_buffer)

	texture_index_buffer_contents: [128]u32 = {}
	texture_index_buffer_contents[64] = 1

	texture_index_buffer = wgpu.device_create_buffer_with_data(
		&gpu.device,
		&{
			label = "Texture index buffer",
			contents = wgpu.to_bytes(texture_index_buffer_contents),
			usage = {.Uniform},
		},
	) or_return
	defer if err != nil do wgpu.buffer_release(&texture_index_buffer)

	extent_3d_default: wgpu.Extent_3D = {1, 1, 1}

	texture_descriptor_common: wgpu.Texture_Descriptor = {
		usage           = {.Texture_Binding, .Copy_Dst},
		dimension       = .D2,
		size            = extent_3d_default,
		format          = .Rgba8_Unorm_Srgb,
		mip_level_count = 1,
		sample_count    = 1,
	}

	texture_data_layout_common: wgpu.Texture_Data_Layout = {
		offset         = 0,
		bytes_per_row  = 4,
		rows_per_image = wgpu.COPY_STRIDE_UNDEFINED,
	}

	textures[.RED].label = "red"
	textures[.GREEN].label = "green"
	textures[.BLUE].label = "blue"
	textures[.WHITE].label = "white"

	textures[.RED].data = {255, 0, 0, 255}
	textures[.GREEN].data = {0, 255, 0, 255}
	textures[.BLUE].data = {0, 0, 255, 255}
	textures[.WHITE].data = {255, 255, 255, 255}

	defer if err != nil {
		for i in 0 ..< len(textures) {
			ref := &textures[cast(Texture_Name)i]
			if ref.view.ptr != nil {
				wgpu.texture_view_release(&ref.view)
				wgpu.texture_release(&ref.tex)
			}
		}
	}

	for i in 0 ..< len(textures) {
		ref := &textures[cast(Texture_Name)i]

		texture_descriptor_common.label = ref.label

		ref.tex = wgpu.device_create_texture(&gpu.device, &texture_descriptor_common) or_return

		ref.view = wgpu.texture_create_view(&ref.tex) or_return

		image_copy_texture := wgpu.texture_as_image_copy(&ref.tex)
		wgpu.queue_write_texture(
			&gpu.queue,
			&image_copy_texture,
			wgpu.to_bytes(wgpu.to_bytes(ref.data)),
			&texture_data_layout_common,
			&extent_3d_default,
		) or_return
	}

	bind_group_layout = wgpu.device_create_bind_group_layout(
		&gpu.device,
		&{
			label = "Bind group layout",
			entries = {
				{
					binding = 0,
					visibility = {.Fragment},
					type = wgpu.Texture_Binding_Layout {
						multisampled = false,
						view_dimension = .D2,
						sample_type = .Float,
					},
					extras = &{count = 2},
				},
				{
					binding = 1,
					visibility = {.Fragment},
					type = wgpu.Texture_Binding_Layout {
						multisampled = false,
						view_dimension = .D2,
						sample_type = .Float,
					},
					extras = &{count = 2},
				},
				{
					binding = 2,
					visibility = {.Fragment},
					type = wgpu.Sampler_Binding_Layout{type = .Filtering},
					extras = &{count = 2},
				},
				{
					binding = 3,
					visibility = {.Fragment},
					type = wgpu.Buffer_Binding_Layout {
						type = .Uniform,
						has_dynamic_offset = true,
						min_binding_size = 4,
					},
				},
			},
		},
	) or_return
	defer if err != nil do wgpu.bind_group_layout_release(&bind_group_layout)

	sampler = wgpu.device_create_sampler(&gpu.device) or_return
	defer if err != nil do wgpu.sampler_release(&sampler)

	bind_group = wgpu.device_create_bind_group(
		&gpu.device,
		&{
			label = "Bind group layout",
			layout = bind_group_layout.ptr,
			entries = {
				{
					binding = 0,
					extras = &{
						texture_views = {textures[.RED].view.ptr, textures[.GREEN].view.ptr},
					},
				},
				{
					binding = 1,
					extras = &{
						texture_views = {textures[.BLUE].view.ptr, textures[.WHITE].view.ptr},
					},
				},
				{binding = 2, extras = &{samplers = {sampler.ptr, sampler.ptr}}},
				{
					binding = 3,
					resource = wgpu.Buffer_Binding {
						buffer = texture_index_buffer.ptr,
						offset = 0,
						size = 4,
					},
				},
			},
		},
	) or_return
	defer if err != nil do wgpu.bind_group_release(&bind_group)

	pipeline_layout = wgpu.device_create_pipeline_layout(
		&gpu.device,
		&{label = "main", bind_group_layouts = {bind_group_layout.ptr}},
	) or_return
	defer if err != nil do wgpu.pipeline_layout_release(&pipeline_layout)

	render_pipeline = wgpu.device_create_render_pipeline(
		&gpu.device,
		&{
			layout = pipeline_layout.ptr,
			vertex = {
				module = base_shader_module.ptr,
				entry_point = "vert_main",
				buffers = {
					{
						array_stride = size_of(Vertex),
						step_mode = .Vertex,
						attributes = {
							{format = .Float32x2, offset = 0, shader_location = 0},
							{
								format = .Float32x2,
								offset = u64(offset_of(Vertex, tex_coord)),
								shader_location = 1,
							},
							{
								format = .Sint32,
								offset = u64(offset_of(Vertex, index)),
								shader_location = 2,
							},
						},
					},
				},
			},
			fragment = &{
				module = fragment_shader_module.ptr,
				entry_point = fragment_entry_point,
				targets = {{format = gpu.config.format, write_mask = wgpu.Color_Write_Mask_All}},
			},
			primitive = wgpu.Default_Primitive_State,
			multisample = wgpu.Default_Multisample_State,
		},
	) or_return

	return
}

deinit_example :: proc(using state: ^State) {
	wgpu.render_pipeline_release(&render_pipeline)
	wgpu.pipeline_layout_release(&pipeline_layout)
	wgpu.bind_group_release(&bind_group)
	wgpu.sampler_release(&sampler)
	wgpu.bind_group_layout_release(&bind_group_layout)

	for i in 0 ..< len(textures) {
		ref := &textures[cast(Texture_Name)i]
		wgpu.texture_view_release(&ref.view)
		wgpu.texture_destroy(&ref.tex)
		wgpu.texture_release(&ref.tex)
	}

	wgpu.buffer_release(&texture_index_buffer)
	wgpu.buffer_release(&index_buffer)
	wgpu.buffer_release(&vertex_buffer)

	renderer.deinit(gpu)
}

render :: proc(using state: ^State) -> (err: wgpu.Error) {
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
			label = "render_pass_encoder",
			color_attachments = []wgpu.Render_Pass_Color_Attachment {
				{
					view = view.ptr,
					resolve_target = nil,
					load_op = .Clear,
					store_op = .Store,
					clear_value = wgpu.Color_Black,
				},
			},
			depth_stencil_attachment = nil,
		},
	)
	defer wgpu.render_pass_encoder_release(&render_pass)

	wgpu.render_pass_encoder_set_pipeline(&render_pass, render_pipeline.ptr)
	wgpu.render_pass_encoder_set_vertex_buffer(&render_pass, 0, vertex_buffer.ptr)
	wgpu.render_pass_encoder_set_index_buffer(&render_pass, index_buffer.ptr, .Uint16)
	wgpu.render_pass_encoder_set_bind_group(&render_pass, 0, bind_group.ptr, {0})

	if use_uniform_workaround {
		wgpu.render_pass_encoder_draw_indexed(&render_pass, 6)
		wgpu.render_pass_encoder_set_bind_group(&render_pass, 0, bind_group.ptr, {256})
		wgpu.render_pass_encoder_draw_indexed(&render_pass, 6, 1, 6)
	} else {
		wgpu.render_pass_encoder_draw_indexed(&render_pass, 12)
	}

	wgpu.render_pass_encoder_end(&render_pass) or_return

	command_buffer := wgpu.command_encoder_finish(&encoder) or_return
	defer wgpu.command_buffer_release(&command_buffer)

	wgpu.queue_submit(&gpu.queue, command_buffer.ptr)
	wgpu.surface_present(&gpu.surface)

	return
}

resize_surface :: proc(using state: ^State, size: app.Physical_Size) -> (err: wgpu.Error) {
	renderer.resize_surface(gpu, {size.width, size.height}) or_return

	return
}

main :: proc() {
	app_properties := app.Default_Properties
	app_properties.title = "Texture Arrays Example"
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
				err := resize_surface(&state, {ev.width, ev.height})
				if err != nil do break main_loop
			}
		}

		if err := render(&state); err != nil do break main_loop
	}

	fmt.println("Exiting...")
}
