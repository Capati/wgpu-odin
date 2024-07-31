package texture_arrays_example

// STD Library
import "base:runtime"
import "core:log"

// Package
import rl "./../../utils/renderlink"
import "./../../utils/shaders"
import wgpu "./../../wrapper"

_ :: log

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
	0, 1, 2,  // First triangle
	2, 0, 3,  // Second triangle

	// Right rectangle
	4, 5, 6,  // First triangle
	6, 4, 7,  // Second triangle
}
// odinfmt: enable

State :: struct {
	optional_features:            wgpu.Features,
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

App_Context :: rl.Context(State)

EXAMPLE_TITLE :: "Texture Arrays"

init :: proc(using ctx: ^App_Context) -> (err: rl.Error) {
	state.device_has_optional_features = wgpu.device_has_feature(
		gpu.device,
		state.optional_features,
	)

	if state.device_has_optional_features {
		state.fragment_entry_point = "non_uniform_main"
	} else {
		state.use_uniform_workaround = true
		state.fragment_entry_point = "uniform_main"
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	INDEXING_WGSL: string : #load("./indexing.wgsl", string)
	base_shader_source := shaders.apply_color_conversion(
		INDEXING_WGSL,
		gpu.is_srgb,
		context.temp_allocator,
	) or_return
	base_shader_module := wgpu.device_create_shader_module(
		gpu.device,
		{source = base_shader_source},
	) or_return
	defer wgpu.shader_module_release(base_shader_module)

	fragment_shader_module: wgpu.Shader_Module

	if !state.use_uniform_workaround {
		NON_UNIFORM_INDEXING_WGSL: string : #load("./non_uniform_indexing.wgsl", string)
		non_uniform_shader_source := shaders.apply_color_conversion(
			NON_UNIFORM_INDEXING_WGSL,
			gpu.is_srgb,
			context.temp_allocator,
		) or_return
		fragment_shader_module = wgpu.device_create_shader_module(
			gpu.device,
			{source = non_uniform_shader_source},
		) or_return
	} else {
		fragment_shader_module = base_shader_module
	}
	defer wgpu.shader_module_release(fragment_shader_module)

	log.infof("Using fragment entry point: %s", state.fragment_entry_point)

	state.vertex_buffer = wgpu.device_create_buffer_with_data(
		gpu.device,
		{
			label = EXAMPLE_TITLE + " Vertex buffer",
			contents = wgpu.to_bytes(VERTICES),
			usage = {.Vertex},
		},
	) or_return
	defer if err != nil do wgpu.buffer_release(state.vertex_buffer)

	state.index_buffer = wgpu.device_create_buffer_with_data(
		gpu.device,
		{
			label = EXAMPLE_TITLE + " Index buffer",
			contents = wgpu.to_bytes(INDICES),
			usage = {.Index},
		},
	) or_return
	defer if err != nil do wgpu.buffer_release(state.index_buffer)

	texture_index_buffer_contents: [128]u32 = {}
	texture_index_buffer_contents[64] = 1

	state.texture_index_buffer = wgpu.device_create_buffer_with_data(
		gpu.device,
		{
			label = EXAMPLE_TITLE + "Texture index buffer",
			contents = wgpu.to_bytes(texture_index_buffer_contents),
			usage = {.Uniform},
		},
	) or_return
	defer if err != nil do wgpu.buffer_release(state.texture_index_buffer)

	extent_3d_default: wgpu.Extent_3D = {1, 1, 1}

	texture_descriptor_common: wgpu.Texture_Descriptor = {
		usage           = {.Texture_Binding, .Copy_Dst},
		dimension       = .D2,
		size            = extent_3d_default,
		format          = gpu.config.format,
		mip_level_count = 1,
		sample_count    = 1,
	}

	texture_data_layout_common: wgpu.Texture_Data_Layout = {
		offset         = 0,
		bytes_per_row  = 4,
		rows_per_image = wgpu.COPY_STRIDE_UNDEFINED,
	}

	state.textures[.RED].label = "red"
	state.textures[.GREEN].label = "green"
	state.textures[.BLUE].label = "blue"
	state.textures[.WHITE].label = "white"

	state.textures[.RED].data = {255, 0, 0, 255}
	state.textures[.GREEN].data = {0, 255, 0, 255}
	state.textures[.BLUE].data = {0, 0, 255, 255}
	state.textures[.WHITE].data = {255, 255, 255, 255}

	defer if err != nil {
		for i in 0 ..< len(state.textures) {
			ref := &state.textures[cast(Texture_Name)i]
			if ref.view.ptr != nil {
				wgpu.texture_view_release(ref.view)
				wgpu.texture_release(ref.tex)
			}
		}
	}

	for i in 0 ..< len(state.textures) {
		ref := &state.textures[cast(Texture_Name)i]

		texture_descriptor_common.label = ref.label

		ref.tex = wgpu.device_create_texture(gpu.device, texture_descriptor_common) or_return

		ref.view = wgpu.texture_create_view(ref.tex) or_return

		wgpu.queue_write_texture(
			gpu.queue,
			wgpu.texture_as_image_copy(ref.tex),
			wgpu.to_bytes(wgpu.to_bytes(ref.data)),
			texture_data_layout_common,
			extent_3d_default,
		) or_return
	}

	state.bind_group_layout = wgpu.device_create_bind_group_layout(
		gpu.device,
		{
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
	defer if err != nil do wgpu.bind_group_layout_release(state.bind_group_layout)

	state.sampler = wgpu.device_create_sampler(gpu.device) or_return
	defer if err != nil do wgpu.sampler_release(state.sampler)

	state.bind_group = wgpu.device_create_bind_group(
		gpu.device,
		{
			label = EXAMPLE_TITLE + " Bind Group",
			layout = state.bind_group_layout.ptr,
			entries = {
				{
					binding = 0,
					resource = []wgpu.Raw_Texture_View {
						state.textures[.RED].view.ptr,
						state.textures[.GREEN].view.ptr,
					},
				},
				{
					binding = 1,
					resource = []wgpu.Raw_Texture_View {
						state.textures[.BLUE].view.ptr,
						state.textures[.WHITE].view.ptr,
					},
				},
				{binding = 2, resource = []wgpu.Raw_Sampler{state.sampler.ptr, state.sampler.ptr}},
				{
					binding = 3,
					resource = wgpu.Buffer_Binding {
						buffer = state.texture_index_buffer.ptr,
						offset = 0,
						size = 4,
					},
				},
			},
		},
	) or_return
	defer if err != nil do wgpu.bind_group_release(state.bind_group)

	state.pipeline_layout = wgpu.device_create_pipeline_layout(
		gpu.device,
		{label = EXAMPLE_TITLE + " main", bind_group_layouts = {state.bind_group_layout.ptr}},
	) or_return
	defer if err != nil do wgpu.pipeline_layout_release(state.pipeline_layout)

	state.render_pipeline = wgpu.device_create_render_pipeline(
		gpu.device,
		{
			layout = state.pipeline_layout.ptr,
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
				entry_point = state.fragment_entry_point,
				targets = {{format = gpu.config.format, write_mask = wgpu.Color_Write_Mask_All}},
			},
			primitive = wgpu.DEFAULT_PRIMITIVE_STATE,
			multisample = wgpu.DEFAULT_MULTISAMPLE_STATE,
		},
	) or_return
	defer if err != nil do wgpu.render_pipeline_release(state.render_pipeline)

	return
}

quit :: proc(using ctx: ^App_Context) {
	wgpu.render_pipeline_release(state.render_pipeline)
	wgpu.pipeline_layout_release(state.pipeline_layout)
	wgpu.bind_group_release(state.bind_group)
	wgpu.sampler_release(state.sampler)
	wgpu.bind_group_layout_release(state.bind_group_layout)

	for i in 0 ..< len(state.textures) {
		ref := &state.textures[cast(Texture_Name)i]
		wgpu.texture_view_release(ref.view)
		wgpu.texture_destroy(ref.tex)
		wgpu.texture_release(ref.tex)
	}

	wgpu.buffer_release(state.texture_index_buffer)
	wgpu.buffer_release(state.index_buffer)
	wgpu.buffer_release(state.vertex_buffer)
}

draw :: proc(using ctx: ^App_Context) -> (err: rl.Error) {
	wgpu.render_pass_set_pipeline(gpu.render_pass, state.render_pipeline.ptr)
	wgpu.render_pass_set_vertex_buffer(gpu.render_pass, 0, state.vertex_buffer.ptr)
	wgpu.render_pass_set_index_buffer(gpu.render_pass, state.index_buffer.ptr, .Uint16)

	if state.use_uniform_workaround {
		// Draw left rectangle
		wgpu.render_pass_set_bind_group(gpu.render_pass, 0, state.bind_group.ptr, {0})
		wgpu.render_pass_draw_indexed(gpu.render_pass, {0, 6})
		// Draw right rectangle
		wgpu.render_pass_set_bind_group(gpu.render_pass, 0, state.bind_group.ptr, {256})
		wgpu.render_pass_draw_indexed(gpu.render_pass, {6, 12})
	} else {
		wgpu.render_pass_set_bind_group(gpu.render_pass, 0, state.bind_group.ptr, {0})
		wgpu.render_pass_draw_indexed(gpu.render_pass, {0, 12})
	}

	return
}

main :: proc() {
	state, state_err := new(App_Context)
	if state_err != nil do return
	defer free(state)

	state.callbacks = {
		init = init,
		quit = quit,
		draw = draw,
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

	if err := rl.init(state, settings); err != nil do return

	rl.begin_run(state) // Start the main loop
}
