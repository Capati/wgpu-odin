package tutorial5_textures

// STD Library
import "base:runtime"

// Local Packages
import "../../../../utils/shaders"
import wgpu "../../../../wrapper"
import rl "./../../../../utils/renderlink"
import "texture"

Vertex :: struct {
	position:   [3]f32,
	tex_coords: [2]f32,
}

State :: struct {
	diffuse_bind_group: wgpu.Bind_Group,
	render_pipeline:    wgpu.Render_Pipeline,
	num_indices:        u32,
	vertex_buffer:      wgpu.Buffer,
	index_buffer:       wgpu.Buffer,
}

App_Context :: rl.Context(State)

EXAMPLE_TITLE :: "Tutorial 5 - Textures"

init :: proc(using ctx: ^App_Context) -> (err: rl.Error) {
	// Load our tree image to texture
	diffuse_texture := texture.texture_from_image(
		gpu.device,
		gpu.queue,
		"assets/learn_wgpu/tutorial5/happy-tree.png",
	) or_return
	defer texture.texture_destroy(diffuse_texture)

	texture_bind_group_layout := wgpu.device_create_bind_group_layout(
		gpu.device,
		{
			label = EXAMPLE_TITLE + "  Bind Group Layout",
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
	defer wgpu.bind_group_layout_release(texture_bind_group_layout)

	state.diffuse_bind_group = wgpu.device_create_bind_group(
		gpu.device,
		wgpu.Bind_Group_Descriptor {
			label = EXAMPLE_TITLE + " Diffuse Bind Group",
			layout = texture_bind_group_layout.ptr,
			entries = {
				{binding = 0, resource = diffuse_texture.view.ptr},
				{binding = 1, resource = diffuse_texture.sampler.ptr},
			},
		},
	) or_return
	defer if err != nil do wgpu.bind_group_release(state.diffuse_bind_group)

	render_pipeline_layout := wgpu.device_create_pipeline_layout(
		gpu.device,
		{
			label = EXAMPLE_TITLE + " Render Pipeline Layout",
			bind_group_layouts = {texture_bind_group_layout.ptr},
		},
	) or_return
	defer wgpu.pipeline_layout_release(render_pipeline_layout)

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

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	SHADER_WGSL: string : #load("./shader.wgsl", string)
	shader_source := shaders.apply_color_conversion(
		SHADER_WGSL,
		gpu.is_srgb,
		context.temp_allocator,
	) or_return
	shader_module := wgpu.device_create_shader_module(
		gpu.device,
		{source = shader_source},
	) or_return
	defer wgpu.shader_module_release(shader_module)

	render_pipeline_descriptor := wgpu.Render_Pipeline_Descriptor {
		label = EXAMPLE_TITLE + " Render Pipeline",
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
					format = gpu.config.format,
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
		gpu.device,
		render_pipeline_descriptor,
	) or_return
	defer if err != nil do wgpu.render_pipeline_release(state.render_pipeline)

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
		gpu.device,
		wgpu.Buffer_Data_Descriptor {
			label = EXAMPLE_TITLE + " Vertex Buffer",
			contents = wgpu.to_bytes(vertices),
			usage = {.Vertex},
		},
	) or_return
	defer if err != nil do wgpu.buffer_release(state.vertex_buffer)

	state.index_buffer = wgpu.device_create_buffer_with_data(
		gpu.device,
		wgpu.Buffer_Data_Descriptor {
			label = EXAMPLE_TITLE + " Index Buffer",
			contents = wgpu.to_bytes(indices),
			usage = {.Index},
		},
	) or_return

	rl.graphics_clear(rl.Color{0.1, 0.2, 0.3, 1.0})

	return
}

quit :: proc(using ctx: ^App_Context) {
	wgpu.buffer_release(index_buffer)
	wgpu.buffer_release(vertex_buffer)
	wgpu.render_pipeline_release(render_pipeline)
	wgpu.bind_group_release(diffuse_bind_group)
}

draw :: proc(using ctx: ^App_Context) -> (err: rl.Error) {
	wgpu.render_pass_set_pipeline(gpu.render_pass, render_pipeline.ptr)
	wgpu.render_pass_set_bind_group(gpu.render_pass, 0, diffuse_bind_group.ptr)
	wgpu.render_pass_set_vertex_buffer(gpu.render_pass, 0, vertex_buffer.ptr)
	wgpu.render_pass_set_index_buffer(gpu.render_pass, index_buffer.ptr, .Uint16)
	wgpu.render_pass_draw_indexed(gpu.render_pass, {0, num_indices})

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

	if err := rl.init(state, settings); err != nil do return

	rl.begin_run(state) // Start the main loop
}
