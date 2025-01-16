package texture_arrays

// Packages
import "core:log"

// Local packages
import app "root:utils/application"
import "root:wgpu"

Texture_Data :: struct {
	label: string,
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
INDICES: []u16 = {
	// Left rectangle
	0, 1, 2, // First triangle
	2, 0, 3, // Second triangle

	// Right rectangle
	4, 5, 6, // First triangle
	6, 4, 7, // Second triangle
}
// odinfmt: enable

Example :: struct {
	device_has_optional_features: bool,
	use_uniform_workaround:       bool,
	fragment_entry_point:         string,
	vertex_buffer:                wgpu.Buffer,
	index_buffer:                 wgpu.Buffer,
	texture_index_buffer:         wgpu.Buffer,
	textures:                     [Texture_Name]Texture_Data,
	sampler:                      wgpu.Sampler,
	bind_group:                   wgpu.Bind_Group,
	render_pipeline:              wgpu.Render_Pipeline,
	render_pass:                  struct {
		color_attachments: [1]wgpu.Render_Pass_Color_Attachment,
		descriptor:        wgpu.Render_Pass_Descriptor,
	},
}

Context :: app.Context(Example)

EXAMPLE_TITLE :: "Texture Arrays"

init :: proc(ctx: ^Context) -> (ok: bool) {
	ctx.device_has_optional_features = wgpu.device_has_feature(
		ctx.gpu.device,
		ctx.settings.optional_features,
	)

	if ctx.device_has_optional_features {
		ctx.fragment_entry_point = "non_uniform_main"
	} else {
		ctx.use_uniform_workaround = true
		ctx.fragment_entry_point = "uniform_main"
	}

	INDEXING_WGSL: string : #load("./indexing.wgsl", string)
	base_shader_module := wgpu.device_create_shader_module(
		ctx.gpu.device,
		{source = string(INDEXING_WGSL)},
	) or_return
	defer wgpu.release(base_shader_module)

	fragment_shader_module: wgpu.Shader_Module
	if !ctx.use_uniform_workaround {
		NON_UNIFORM_INDEXING_WGSL: string : #load("./non_uniform_indexing.wgsl", string)
		fragment_shader_module = wgpu.device_create_shader_module(
			ctx.gpu.device,
			{source = string(NON_UNIFORM_INDEXING_WGSL)},
		) or_return
	} else {
		fragment_shader_module = base_shader_module
	}
	defer if !ctx.use_uniform_workaround {
		wgpu.release(fragment_shader_module)
	}

	log.infof("Using fragment entry point: %s", ctx.fragment_entry_point)

	ctx.vertex_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{
			label = EXAMPLE_TITLE + " Vertex buffer",
			contents = wgpu.to_bytes(VERTICES),
			usage = {.Vertex},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.vertex_buffer)
	}

	ctx.index_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{
			label = EXAMPLE_TITLE + " Index buffer",
			contents = wgpu.to_bytes(INDICES),
			usage = {.Index},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.index_buffer)
	}

	texture_index_buffer_contents: [128]u32 = {}
	texture_index_buffer_contents[64] = 1

	ctx.texture_index_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{
			label = EXAMPLE_TITLE + "Texture index buffer",
			contents = wgpu.to_bytes(texture_index_buffer_contents),
			usage = {.Uniform},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.texture_index_buffer)
	}

	extent_3d_default: wgpu.Extent_3D = {1, 1, 1}

	texture_descriptor_common: wgpu.Texture_Descriptor = {
		usage           = {.Texture_Binding, .Copy_Dst},
		dimension       = .D2,
		size            = extent_3d_default,
		format          = ctx.gpu.config.format,
		mip_level_count = 1,
		sample_count    = 1,
	}

	texture_data_layout_common: wgpu.Texel_Copy_Buffer_Layout = {
		offset         = 0,
		bytes_per_row  = 4,
		rows_per_image = wgpu.COPY_STRIDE_UNDEFINED,
	}

	ctx.textures[.RED].label = "red"
	ctx.textures[.GREEN].label = "green"
	ctx.textures[.BLUE].label = "blue"
	ctx.textures[.WHITE].label = "white"

	ctx.textures[.RED].data = {255, 0, 0, 255}
	ctx.textures[.GREEN].data = {0, 255, 0, 255}
	ctx.textures[.BLUE].data = {0, 0, 255, 255}
	ctx.textures[.WHITE].data = {255, 255, 255, 255}

	defer if !ok {
		for i in 0 ..< len(ctx.textures) {
			ref := &ctx.textures[cast(Texture_Name)i]
			if ref.view != nil {
				wgpu.release(ref.view)
				wgpu.release(ref.tex)
			}
		}
	}

	for i in 0 ..< len(ctx.textures) {
		ref := &ctx.textures[cast(Texture_Name)i]

		texture_descriptor_common.label = ref.label

		ref.tex = wgpu.device_create_texture(ctx.gpu.device, texture_descriptor_common) or_return

		ref.view = wgpu.texture_create_view(ref.tex) or_return

		wgpu.queue_write_texture(
			ctx.gpu.queue,
			wgpu.texture_as_image_copy(ref.tex),
			wgpu.to_bytes(wgpu.to_bytes(ref.data)),
			texture_data_layout_common,
			extent_3d_default,
		) or_return
	}

	bind_group_layout := wgpu.device_create_bind_group_layout(
		ctx.gpu.device,
		wgpu.Bind_Group_Layout_Descriptor {
			label = EXAMPLE_TITLE + " Bind group layout",
			entries = {
				{
					binding = 0,
					visibility = {.Fragment},
					type = wgpu.Texture_Binding_Layout {
						multisampled = false,
						view_dimension = .D2,
						sample_type = .Float,
					},
					count = 2,
				},
				{
					binding = 1,
					visibility = {.Fragment},
					type = wgpu.Texture_Binding_Layout {
						multisampled = false,
						view_dimension = .D2,
						sample_type = .Float,
					},
					count = 2,
				},
				{
					binding = 2,
					visibility = {.Fragment},
					type = wgpu.Sampler_Binding_Layout{type = .Filtering},
					count = 2,
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
	defer wgpu.release(bind_group_layout)

	ctx.sampler = wgpu.device_create_sampler(ctx.gpu.device) or_return
	defer if !ok {
		wgpu.release(ctx.sampler)
	}

	ctx.bind_group = wgpu.device_create_bind_group(
		ctx.gpu.device,
		{
			label = EXAMPLE_TITLE + " Bind Group",
			layout = bind_group_layout,
			entries = {
				{
					binding = 0,
					resource = []wgpu.Texture_View {
						ctx.textures[.RED].view,
						ctx.textures[.GREEN].view,
					},
				},
				{
					binding = 1,
					resource = []wgpu.Texture_View {
						ctx.textures[.BLUE].view,
						ctx.textures[.WHITE].view,
					},
				},
				{binding = 2, resource = []wgpu.Sampler{ctx.sampler, ctx.sampler}},
				{
					binding = 3,
					resource = wgpu.Buffer_Binding {
						buffer = ctx.texture_index_buffer,
						offset = 0,
						size = 4,
					},
				},
			},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.bind_group)
	}

	pipeline_layout := wgpu.device_create_pipeline_layout(
		ctx.gpu.device,
		{label = EXAMPLE_TITLE + " main", bind_group_layouts = {bind_group_layout}},
	) or_return
	defer wgpu.release(pipeline_layout)

	ctx.render_pipeline = wgpu.device_create_render_pipeline(
		ctx.gpu.device,
		{
			layout = pipeline_layout,
			vertex = {
				module = base_shader_module,
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
				module = fragment_shader_module,
				entry_point = ctx.fragment_entry_point,
				targets = {{format = ctx.gpu.config.format, write_mask = wgpu.COLOR_WRITES_ALL}},
			},
			primitive = wgpu.DEFAULT_PRIMITIVE_STATE,
			multisample = wgpu.DEFAULT_MULTISAMPLE_STATE,
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.render_pipeline)
	}

	ctx.render_pass.color_attachments[0] = {
		view = nil, /* Assigned later */
		ops  = {.Clear, .Store, app.Color_Black},
	}

	ctx.render_pass.descriptor = {
		label             = "Render pass descriptor",
		color_attachments = ctx.render_pass.color_attachments[:],
	}

	return true
}

quit :: proc(ctx: ^Context) {
	wgpu.release(ctx.render_pipeline)
	wgpu.release(ctx.bind_group)
	wgpu.release(ctx.sampler)

	for i in 0 ..< len(ctx.textures) {
		ref := &ctx.textures[cast(Texture_Name)i]
		wgpu.release(ref.view)
		wgpu.texture_destroy(ref.tex)
		wgpu.release(ref.tex)
	}

	wgpu.release(ctx.texture_index_buffer)
	wgpu.release(ctx.index_buffer)
	wgpu.release(ctx.vertex_buffer)
}

draw :: proc(ctx: ^Context) -> bool {
	ctx.cmd = wgpu.device_create_command_encoder(ctx.gpu.device) or_return
	defer wgpu.release(ctx.cmd)

	ctx.render_pass.color_attachments[0].view = ctx.frame.view
	render_pass := wgpu.command_encoder_begin_render_pass(ctx.cmd, ctx.render_pass.descriptor)
	defer wgpu.release(render_pass)

	wgpu.render_pass_set_pipeline(render_pass, ctx.render_pipeline)
	wgpu.render_pass_set_vertex_buffer(render_pass, 0, {buffer = ctx.vertex_buffer})
	wgpu.render_pass_set_index_buffer(render_pass, {buffer = ctx.index_buffer}, .Uint16)

	if ctx.use_uniform_workaround {
		// Draw left rectangle
		wgpu.render_pass_set_bind_group(render_pass, 0, ctx.bind_group, {0})
		wgpu.render_pass_draw_indexed(render_pass, {0, 6})
		// Draw right rectangle
		wgpu.render_pass_set_bind_group(render_pass, 0, ctx.bind_group, {256})
		wgpu.render_pass_draw_indexed(render_pass, {6, 12})
	} else {
		wgpu.render_pass_set_bind_group(render_pass, 0, ctx.bind_group, {0})
		wgpu.render_pass_draw_indexed(render_pass, {0, 12})
	}

	wgpu.render_pass_end(render_pass) or_return

	cmdbuf := wgpu.command_encoder_finish(ctx.cmd) or_return
	defer wgpu.release(cmdbuf)

	wgpu.queue_submit(ctx.gpu.queue, cmdbuf)
	wgpu.surface_present(ctx.gpu.surface) or_return

	return true
}

main :: proc() {
	when ODIN_DEBUG {
		context.logger = log.create_console_logger(opt = {.Level, .Terminal_Color})
		defer log.destroy_console_logger(context.logger)
	}

	settings := app.DEFAULT_SETTINGS
	settings.title = EXAMPLE_TITLE

	// Set optional features to decide for a workaround or feature based
	settings.optional_features = {.Sampled_Texture_And_Storage_Buffer_Array_Non_Uniform_Indexing}
	// Set required features to use texture arrays
	settings.required_features = {.Texture_Binding_Array}

	example, ok := app.create(Context, settings)
	if !ok {
		return
	}
	defer app.destroy(example)

	example.callbacks = {
		init = init,
		quit = quit,
		draw = draw,
	}

	app.run(example) // Start the main loop
}
