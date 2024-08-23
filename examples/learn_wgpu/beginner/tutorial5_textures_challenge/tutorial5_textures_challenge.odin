package tutorial5_textures_challenge

// STD Library
import "base:runtime"
import "base:builtin"
@(require) import "core:log"

// Local Packages
import "../../../../utils/shaders"
import wgpu "../../../../wrapper"
import "../tutorial5_textures/texture"
import rl "./../../../../utils/renderlink"

Vertex :: struct {
	position   : [3]f32,
	tex_coords : [2]f32,
}

State :: struct {
	diffuse_bind_group : wgpu.Bind_Group,
	cartoon_bind_group : wgpu.Bind_Group,
	render_pipeline    : wgpu.Render_Pipeline,
	num_indices        : u32,
	vertex_buffer      : wgpu.Buffer,
	index_buffer       : wgpu.Buffer,
	is_space_pressed   : bool,
}

State_Context :: rl.Context(State)

EXAMPLE_TITLE :: "Tutorial 5 - Textures Challenge"

init :: proc(ctx: ^State_Context) -> (ok: bool) {
	// Load our tree image to texture
	diffuse_texture := texture.texture_from_image(
		ctx.gpu.device,
		ctx.gpu.queue,
		"assets/learn_wgpu/tutorial5/happy-tree.png",
	) or_return
	defer texture.texture_destroy(diffuse_texture)

	texture_bind_group_layout := wgpu.device_create_bind_group_layout(
		ctx.gpu.device,
		wgpu.Bind_Group_Layout_Descriptor{
			label = EXAMPLE_TITLE + " Bind Group Layout",
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

	ctx.diffuse_bind_group = wgpu.device_create_bind_group(
		ctx.gpu.device,
		wgpu.Bind_Group_Descriptor {
			label = EXAMPLE_TITLE + " Diffuse Bind Group",
			layout = texture_bind_group_layout,
			entries = {
				{binding = 0, resource = diffuse_texture.view},
				{binding = 1, resource = diffuse_texture.sampler},
			},
		},
	) or_return
	defer if !ok do wgpu.bind_group_release(ctx.diffuse_bind_group)

	cartoon_texture := texture.texture_from_image(
		ctx.gpu.device,
		ctx.gpu.queue,
		"assets/learn_wgpu/tutorial5/happy-tree-cartoon.png",
	) or_return
	defer texture.texture_destroy(cartoon_texture)

	ctx.cartoon_bind_group = wgpu.device_create_bind_group(
		ctx.gpu.device,
		wgpu.Bind_Group_Descriptor {
			label = EXAMPLE_TITLE + "Cartoon Bind Group",
			layout = texture_bind_group_layout,
			entries = {
				{binding = 0, resource = cartoon_texture.view},
				{binding = 1, resource = cartoon_texture.sampler},
			},
		},
	) or_return
	defer if !ok do wgpu.bind_group_release(ctx.cartoon_bind_group)

	render_pipeline_layout := wgpu.device_create_pipeline_layout(
		ctx.gpu.device,
		{
			label = EXAMPLE_TITLE + " Render Pipeline Layout",
			bind_group_layouts = {texture_bind_group_layout},
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

	// Use the same shader from the Tutorial 5- Textures
	SHADER_WGSL: string : #load("./../tutorial5_textures/shader.wgsl", string)
	shader_source := shaders.apply_color_conversion(
		SHADER_WGSL,
		ctx.gpu.is_srgb,
		context.temp_allocator,
	) or_return
	shader_module := wgpu.device_create_shader_module(
		ctx.gpu.device,
		{source = shader_source},
	) or_return
	defer wgpu.shader_module_release(shader_module)

	render_pipeline_descriptor := wgpu.Render_Pipeline_Descriptor {
		label = EXAMPLE_TITLE + " Render Pipeline",
		layout = render_pipeline_layout,
		vertex = {
			module = shader_module,
			entry_point = "vs_main",
			buffers = {vertex_buffer_layout},
		},
		fragment = &{
			module = shader_module,
			entry_point = "fs_main",
			targets = {
				{
					format = ctx.gpu.config.format,
					blend = &wgpu.Blend_State_Replace,
					write_mask = wgpu.Color_Write_Mask_All,
				},
			},
		},
		primitive = {topology = .Triangle_List, front_face = .CCW, cull_mode = .Back},
		depth_stencil = nil,
		multisample = {count = 1, mask = ~u32(0), alpha_to_coverage_enabled = false},
	}

	ctx.render_pipeline = wgpu.device_create_render_pipeline(
		ctx.gpu.device,
		render_pipeline_descriptor,
	) or_return
	defer if !ok do wgpu.render_pipeline_release(ctx.render_pipeline)

	vertices := []Vertex {
		{position = {-0.0868241, 0.49240386, 0.0}, tex_coords = {0.4131759, 0.00759614}}, // A
		{position = {-0.49513406, 0.06958647, 0.0}, tex_coords = {0.0048659444, 0.43041354}}, // B
		{position = {-0.21918549, -0.44939706, 0.0}, tex_coords = {0.28081453, 0.949397}}, // C
		{position = {0.35966998, -0.3473291, 0.0}, tex_coords = {0.85967, 0.84732914}}, // D
		{position = {0.44147372, 0.2347359, 0.0}, tex_coords = {0.9414737, 0.2652641}}, // E
	}

	indices: []u16 = {0, 1, 4, 1, 2, 4, 2, 3, 4}

	ctx.num_indices = cast(u32)len(indices)

	ctx.vertex_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		wgpu.Buffer_Data_Descriptor {
			label = EXAMPLE_TITLE + " Vertex Buffer",
			contents = wgpu.to_bytes(vertices),
			usage = {.Vertex},
		},
	) or_return
	defer if !ok do wgpu.buffer_release(ctx.vertex_buffer)

	ctx.index_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		wgpu.Buffer_Data_Descriptor {
			label = EXAMPLE_TITLE + " Index Buffer",
			contents = wgpu.to_bytes(indices),
			usage = {.Index},
		},
	) or_return

	rl.graphics_clear(rl.Color{0.1, 0.2, 0.3, 1.0})

	return true
}

quit :: proc(ctx: ^State_Context) {
	wgpu.buffer_release(ctx.index_buffer)
	wgpu.buffer_release(ctx.vertex_buffer)
	wgpu.render_pipeline_release(ctx.render_pipeline)
	wgpu.bind_group_release(ctx.cartoon_bind_group)
	wgpu.bind_group_release(ctx.diffuse_bind_group)
}

draw :: proc(ctx: ^State_Context) -> bool {
	wgpu.render_pass_set_pipeline(ctx.gpu.render_pass, ctx.render_pipeline)

	if rl.keyboard_is_down(.Space) {
		wgpu.render_pass_set_bind_group(ctx.gpu.render_pass, 0, ctx.cartoon_bind_group)
	} else {
		wgpu.render_pass_set_bind_group(ctx.gpu.render_pass, 0, ctx.diffuse_bind_group)
	}

	wgpu.render_pass_set_vertex_buffer(ctx.gpu.render_pass, 0, ctx.vertex_buffer)
	wgpu.render_pass_set_index_buffer(ctx.gpu.render_pass, ctx.index_buffer, .Uint16)
	wgpu.render_pass_draw_indexed(ctx.gpu.render_pass, {0, ctx.num_indices})

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
		init = init,
		quit = quit,
		draw = draw,
	}

	settings := rl.DEFAULT_SETTINGS
	settings.window.title = EXAMPLE_TITLE

	if ok := rl.init(state, settings); !ok do return

	rl.begin_run(state) // Start the main loop
}
