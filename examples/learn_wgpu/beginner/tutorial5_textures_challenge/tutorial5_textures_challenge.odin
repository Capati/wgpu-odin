package tutorial5_textures_challenge

// Packages
import "core:log"

// Local Packages
import app "root:utils/application"
import "root:wgpu"

Vertex :: struct {
	position:   [3]f32,
	tex_coords: [2]f32,
}

Example :: struct {
	diffuse_bind_group: wgpu.BindGroup,
	cartoon_bind_group: wgpu.BindGroup,
	render_pipeline:    wgpu.RenderPipeline,
	num_indices:        u32,
	vertex_buffer:      wgpu.Buffer,
	index_buffer:       wgpu.Buffer,
	is_space_pressed:   bool,
	render_pass:        struct {
		color_attachments: [1]wgpu.RenderPassColorAttachment,
		descriptor:        wgpu.RenderPassDescriptor,
	},
}

Context :: app.Context(Example)

EXAMPLE_TITLE :: "Tutorial 5 - Textures Challenge"

init :: proc(ctx: ^Context) -> (ok: bool) {
	// Load our tree image to texture
	diffuse_texture := app.create_texture_from_file(
		"assets/textures/happy-tree.png",
		ctx.gpu.device,
		ctx.gpu.queue,
	) or_return
	defer app.release(diffuse_texture)

	texture_bind_group_layout := wgpu.device_create_bind_group_layout(
		ctx.gpu.device,
		wgpu.BindGroupLayoutDescriptor {
			label = EXAMPLE_TITLE + " Bind Group Layout",
			entries = {
				{
					binding = 0,
					visibility = {.Fragment},
					type = wgpu.TextureBindingLayout {
						multisampled = false,
						view_dimension = .D2,
						sample_type = .Float,
					},
				},
				{
					binding = 1,
					visibility = {.Fragment},
					type = wgpu.SamplerBindingLayout{type = .Filtering},
				},
			},
		},
	) or_return
	defer wgpu.release(texture_bind_group_layout)

	ctx.diffuse_bind_group = wgpu.device_create_bind_group(
		ctx.gpu.device,
		wgpu.BindGroupDescriptor {
			label = EXAMPLE_TITLE + " Diffuse Bind Group",
			layout = texture_bind_group_layout,
			entries = {
				{binding = 0, resource = diffuse_texture.view},
				{binding = 1, resource = diffuse_texture.sampler},
			},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.diffuse_bind_group)
	}

	cartoon_texture := app.create_texture_from_file(
		"assets/textures/happy-tree-cartoon.png",
		ctx.gpu.device,
		ctx.gpu.queue,
	) or_return
	defer app.release(cartoon_texture)

	ctx.cartoon_bind_group = wgpu.device_create_bind_group(
		ctx.gpu.device,
		wgpu.BindGroupDescriptor {
			label = EXAMPLE_TITLE + "Cartoon Bind Group",
			layout = texture_bind_group_layout,
			entries = {
				{binding = 0, resource = cartoon_texture.view},
				{binding = 1, resource = cartoon_texture.sampler},
			},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.cartoon_bind_group)
	}

	render_pipeline_layout := wgpu.device_create_pipeline_layout(
		ctx.gpu.device,
		{
			label = EXAMPLE_TITLE + " Render Pipeline Layout",
			bind_group_layouts = {texture_bind_group_layout},
		},
	) or_return
	defer wgpu.release(render_pipeline_layout)

	vertex_buffer_layout := wgpu.VertexBufferLayout {
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
	SHADER_WGSL :: #load("./../tutorial5_textures/shader.wgsl")
	shader_module := wgpu.device_create_shader_module(
		ctx.gpu.device,
		{source = string(SHADER_WGSL)},
	) or_return
	defer wgpu.release(shader_module)

	render_pipeline_descriptor := wgpu.RenderPipelineDescriptor {
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
					blend = &wgpu.BLEND_STATE_REPLACE,
					write_mask = wgpu.COLOR_WRITES_ALL,
				},
			},
		},
		primitive = {topology = .TriangleList, front_face = .CCW, cull_mode = .Back},
		multisample = {count = 1, mask = ~u32(0), alpha_to_coverage_enabled = false},
	}

	ctx.render_pipeline = wgpu.device_create_render_pipeline(
		ctx.gpu.device,
		render_pipeline_descriptor,
	) or_return
	defer if !ok {
		wgpu.release(ctx.render_pipeline)
	}

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
		wgpu.BufferDataDescriptor {
			label = EXAMPLE_TITLE + " Vertex Buffer",
			contents = wgpu.to_bytes(vertices),
			usage = {.Vertex},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.vertex_buffer)
	}

	ctx.index_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		wgpu.BufferDataDescriptor {
			label = EXAMPLE_TITLE + " Index Buffer",
			contents = wgpu.to_bytes(indices),
			usage = {.Index},
		},
	) or_return

	ctx.render_pass.color_attachments[0] = {
		view = nil, /* Assigned later */
		ops  = {.Clear, .Store, {0.1, 0.2, 0.3, 1.0}},
	}

	ctx.render_pass.descriptor = {
		label             = "Render pass descriptor",
		color_attachments = ctx.render_pass.color_attachments[:],
	}

	return true
}

quit :: proc(ctx: ^Context) {
	wgpu.release(ctx.index_buffer)
	wgpu.release(ctx.vertex_buffer)
	wgpu.release(ctx.render_pipeline)
	wgpu.release(ctx.cartoon_bind_group)
	wgpu.release(ctx.diffuse_bind_group)
}

draw :: proc(ctx: ^Context) -> bool {
	ctx.cmd = wgpu.device_create_command_encoder(ctx.gpu.device) or_return
	defer wgpu.release(ctx.cmd)

	ctx.render_pass.color_attachments[0].view = ctx.frame.view
	render_pass := wgpu.command_encoder_begin_render_pass(ctx.cmd, ctx.render_pass.descriptor)
	defer wgpu.release(render_pass)

	wgpu.render_pass_set_pipeline(render_pass, ctx.render_pipeline)

	if app.key_is_down(ctx, .Space) {
		wgpu.render_pass_set_bind_group(render_pass, 0, ctx.cartoon_bind_group)
	} else {
		wgpu.render_pass_set_bind_group(render_pass, 0, ctx.diffuse_bind_group)
	}

	wgpu.render_pass_set_vertex_buffer(render_pass, 0, {buffer = ctx.vertex_buffer})
	wgpu.render_pass_set_index_buffer(render_pass, {buffer = ctx.index_buffer}, .Uint16)
	wgpu.render_pass_draw_indexed(render_pass, {0, ctx.num_indices})

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

	example, ok := app.create(Context, settings)
	if !ok {
		log.fatalf("Failed to create example [%s]", EXAMPLE_TITLE)
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
