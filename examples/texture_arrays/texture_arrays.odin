package texture_arrays_example

// STD Library
import "base:builtin"
import "base:runtime"
@(require) import "core:log"

// Local packages
import rl "./../../utils/renderlink"
import "./../../utils/shaders"
import wgpu "./../../wrapper"

Texture_Data :: struct {
	label : cstring,
	tex   : wgpu.Texture,
	view  : wgpu.Texture_View,
	data  : [4]u8,
}

Texture_Name :: enum {
	RED,
	GREEN,
	BLUE,
	WHITE,
}

Vertex :: struct {
	pos       : [2]f32,
	tex_coord : [2]f32,
	index     : u32,
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

INDICES: []u16 = {
	// Left rectangle
	0, 1, 2,  // First triangle
	2, 0, 3,  // Second triangle

	// Right rectangle
	4, 5, 6,  // First triangle
	6, 4, 7,  // Second triangle
}

State :: struct {
	optional_features            : wgpu.Features,
	device_has_optional_features : bool,
	use_uniform_workaround       : bool,
	fragment_entry_point         : cstring,
	vertex_buffer                : wgpu.Buffer,
	index_buffer                 : wgpu.Buffer,
	texture_index_buffer         : wgpu.Buffer,
	textures                     : [Texture_Name]Texture_Data,
	bind_group_layout            : wgpu.Bind_Group_Layout,
	sampler                      : wgpu.Sampler,
	bind_group                   : wgpu.Bind_Group,
	pipeline_layout              : wgpu.Pipeline_Layout,
	render_pipeline              : wgpu.Render_Pipeline,
}

State_Context :: rl.Context(State)

EXAMPLE_TITLE :: "Texture Arrays"

init :: proc(ctx: ^State_Context) -> (ok: bool) {
	ctx.device_has_optional_features = wgpu.device_has_feature(
		ctx.gpu.device,
		ctx.optional_features,
	)

	if ctx.device_has_optional_features {
		ctx.fragment_entry_point = "non_uniform_main"
	} else {
		ctx.use_uniform_workaround = true
		ctx.fragment_entry_point = "uniform_main"
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	INDEXING_WGSL: string : #load("./indexing.wgsl", string)
	base_shader_source := shaders.apply_color_conversion(
		INDEXING_WGSL,
		ctx.gpu.is_srgb,
		context.temp_allocator,
	) or_return
	base_shader_module := wgpu.device_create_shader_module(
		ctx.gpu.device,
		{source = base_shader_source},
	) or_return
	defer wgpu.shader_module_release(base_shader_module)

	fragment_shader_module: wgpu.Shader_Module

	if !ctx.use_uniform_workaround {
		NON_UNIFORM_INDEXING_WGSL: string : #load("./non_uniform_indexing.wgsl", string)
		non_uniform_shader_source := shaders.apply_color_conversion(
			NON_UNIFORM_INDEXING_WGSL,
			ctx.gpu.is_srgb,
			context.temp_allocator,
		) or_return
		fragment_shader_module = wgpu.device_create_shader_module(
			ctx.gpu.device,
			{source = non_uniform_shader_source},
		) or_return
	} else {
		fragment_shader_module = base_shader_module
	}
	defer wgpu.shader_module_release(fragment_shader_module)

	log.infof("Using fragment entry point: %s", ctx.fragment_entry_point)

	ctx.vertex_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{
			label = EXAMPLE_TITLE + " Vertex buffer",
			contents = wgpu.to_bytes(VERTICES),
			usage = {.Vertex},
		},
	) or_return
	defer if !ok do wgpu.buffer_release(ctx.vertex_buffer)

	ctx.index_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{
			label = EXAMPLE_TITLE + " Index buffer",
			contents = wgpu.to_bytes(INDICES),
			usage = {.Index},
		},
	) or_return
	defer if !ok do wgpu.buffer_release(ctx.index_buffer)

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
	defer if !ok do wgpu.buffer_release(ctx.texture_index_buffer)

	extent_3d_default: wgpu.Extent_3D = {1, 1, 1}

	texture_descriptor_common: wgpu.Texture_Descriptor = {
		usage           = {.Texture_Binding, .Copy_Dst},
		dimension       = .D2,
		size            = extent_3d_default,
		format          = ctx.gpu.config.format,
		mip_level_count = 1,
		sample_count    = 1,
	}

	texture_data_layout_common: wgpu.Texture_Data_Layout = {
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
				wgpu.texture_view_release(ref.view)
				wgpu.texture_release(ref.tex)
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

	ctx.bind_group_layout = wgpu.device_create_bind_group_layout(
		ctx.gpu.device,
		wgpu.Bind_Group_Layout_Descriptor{
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
	defer if !ok do wgpu.bind_group_layout_release(ctx.bind_group_layout)

	ctx.sampler = wgpu.device_create_sampler(ctx.gpu.device) or_return
	defer if !ok do wgpu.sampler_release(ctx.sampler)

	ctx.bind_group = wgpu.device_create_bind_group(
		ctx.gpu.device,
		{
			label = EXAMPLE_TITLE + " Bind Group",
			layout = ctx.bind_group_layout,
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
	defer if !ok do wgpu.bind_group_release(ctx.bind_group)

	ctx.pipeline_layout = wgpu.device_create_pipeline_layout(
		ctx.gpu.device,
		{label = EXAMPLE_TITLE + " main", bind_group_layouts = {ctx.bind_group_layout}},
	) or_return
	defer if !ok do wgpu.pipeline_layout_release(ctx.pipeline_layout)

	ctx.render_pipeline = wgpu.device_create_render_pipeline(
		ctx.gpu.device,
		{
			layout = ctx.pipeline_layout,
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
				targets = {{format = ctx.gpu.config.format, write_mask = wgpu.Color_Write_Mask_All}},
			},
			primitive = wgpu.DEFAULT_PRIMITIVE_STATE,
			multisample = wgpu.DEFAULT_MULTISAMPLE_STATE,
		},
	) or_return
	defer if !ok do wgpu.render_pipeline_release(ctx.render_pipeline)

	return true
}

quit :: proc(ctx: ^State_Context) {
	wgpu.render_pipeline_release(ctx.render_pipeline)
	wgpu.pipeline_layout_release(ctx.pipeline_layout)
	wgpu.bind_group_release(ctx.bind_group)
	wgpu.sampler_release(ctx.sampler)
	wgpu.bind_group_layout_release(ctx.bind_group_layout)

	for i in 0 ..< len(ctx.textures) {
		ref := &ctx.textures[cast(Texture_Name)i]
		wgpu.texture_view_release(ref.view)
		wgpu.texture_destroy(ref.tex)
		wgpu.texture_release(ref.tex)
	}

	wgpu.buffer_release(ctx.texture_index_buffer)
	wgpu.buffer_release(ctx.index_buffer)
	wgpu.buffer_release(ctx.vertex_buffer)
}

draw :: proc(ctx: ^State_Context) -> bool {
	wgpu.render_pass_set_pipeline(ctx.gpu.render_pass, ctx.render_pipeline)
	wgpu.render_pass_set_vertex_buffer(ctx.gpu.render_pass, 0, ctx.vertex_buffer)
	wgpu.render_pass_set_index_buffer(ctx.gpu.render_pass, ctx.index_buffer, .Uint16)

	if ctx.use_uniform_workaround {
		// Draw left rectangle
		wgpu.render_pass_set_bind_group(ctx.gpu.render_pass, 0, ctx.bind_group, {0})
		wgpu.render_pass_draw_indexed(ctx.gpu.render_pass, {0, 6})
		// Draw right rectangle
		wgpu.render_pass_set_bind_group(ctx.gpu.render_pass, 0, ctx.bind_group, {256})
		wgpu.render_pass_draw_indexed(ctx.gpu.render_pass, {6, 12})
	} else {
		wgpu.render_pass_set_bind_group(ctx.gpu.render_pass, 0, ctx.bind_group, {0})
		wgpu.render_pass_draw_indexed(ctx.gpu.render_pass, {0, 12})
	}

	return true
}

main :: proc() {
	when ODIN_DEBUG {
		context.logger = log.create_console_logger(opt = {.Level, .Terminal_Color})
		defer log.destroy_console_logger(context.logger)
	}

	state := builtin.new(State_Context)
	assert(state != nil, "Failed to allocate application state")
	defer builtin.free(state)

	state.callbacks = {
		init   = init,
		quit   = quit,
		draw   = draw,
	}

	settings := rl.DEFAULT_SETTINGS
	settings.window.title = EXAMPLE_TITLE
	settings.window.resizable = true

	// Set optional features to decide for a workaround or feature based
	settings.gpu.optional_features = {
		.Sampled_Texture_And_Storage_Buffer_Array_Non_Uniform_Indexing,
	}

	// Set required features to use texture arrays
	settings.gpu.required_features = {.Texture_Binding_Array}

	if ok := rl.init(state, settings); !ok do return

	rl.begin_run(state) // Start the main loop
}
