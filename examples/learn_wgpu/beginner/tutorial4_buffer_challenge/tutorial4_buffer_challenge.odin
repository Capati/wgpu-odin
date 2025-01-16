package tutorial4_buffer_challenge

// Packages
import "core:log"
import "core:math"

// Local Packages
import app "root:utils/application"
import "root:wgpu"

Vertex :: struct {
	position: [3]f32,
	color:    [3]f32,
}

Example :: struct {
	render_pipeline:         wgpu.Render_Pipeline,
	vertex_buffer:           wgpu.Buffer,
	index_buffer:            wgpu.Buffer,
	num_indices:             u32,
	num_challenge_indices:   u32,
	challenge_vertex_buffer: wgpu.Buffer,
	challenge_index_buffer:  wgpu.Buffer,
	use_complex:             bool,
	render_pass:             struct {
		color_attachments: [1]wgpu.Render_Pass_Color_Attachment,
		descriptor:        wgpu.Render_Pass_Descriptor,
	},
}

Context :: app.Context(Example)

EXAMPLE_TITLE :: "Tutorial 4 - Buffers"

init :: proc(ctx: ^Context) -> (ok: bool) {
	// Use the same shader from the Tutorial 4 - Buffers
	SHADER_WGSL :: #load("./../tutorial4_buffer/shader.wgsl")
	shader_module := wgpu.device_create_shader_module(
		ctx.gpu.device,
		{source = string(SHADER_WGSL)},
	) or_return
	defer wgpu.release(shader_module)

	render_pipeline_layout := wgpu.device_create_pipeline_layout(
		ctx.gpu.device,
		{label = EXAMPLE_TITLE + " Render Pipeline Layout"},
	) or_return
	defer wgpu.release(render_pipeline_layout)

	vertex_buffer_layout := wgpu.Vertex_Buffer_Layout {
		array_stride = size_of(Vertex),
		step_mode    = .Vertex,
		attributes   = {
			{offset = 0, shader_location = 0, format = .Float32x3},
			{offset = cast(u64)offset_of(Vertex, color), shader_location = 1, format = .Float32x3},
		},
	}

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
					blend = &wgpu.BLEND_STATE_REPLACE,
					write_mask = wgpu.COLOR_WRITES_ALL,
				},
			},
		},
		primitive = {topology = .Triangle_List, front_face = .CCW, cull_mode = .Back},
		multisample = {count = 1, mask = ~u32(0), alpha_to_coverage_enabled = false},
	}

	ctx.render_pipeline = wgpu.device_create_render_pipeline(
		ctx.gpu.device,
		render_pipeline_descriptor,
	) or_return
	defer if !ok {
		wgpu.release(ctx.render_pipeline)
	}

	// vertices := []Vertex{
	//     {position = {0.0, 0.5, 0.0}, color = {1.0, 0.0, 0.0}},
	//     {position = {-0.5, -0.5, 0.0}, color = {0.0, 1.0, 0.0}},
	//     {position = {0.5, -0.5, 0.0}, color = {0.0, 0.0, 1.0}},
	// }

	vertices := []Vertex {
		{position = {-0.0868241, 0.49240386, 0.0}, color = {0.5, 0.0, 0.5}}, // A
		{position = {-0.49513406, 0.06958647, 0.0}, color = {0.5, 0.0, 0.5}}, // B
		{position = {-0.21918549, -0.44939706, 0.0}, color = {0.5, 0.0, 0.5}}, // C
		{position = {0.35966998, -0.3473291, 0.0}, color = {0.5, 0.0, 0.5}}, // D
		{position = {0.44147372, 0.2347359, 0.0}, color = {0.5, 0.0, 0.5}}, // E
	}

	indices: []u16 = {0, 1, 4, 1, 2, 4, 2, 3, 4}

	// num_vertices = cast(u32)len(vertices)
	ctx.num_indices = cast(u32)len(indices)

	ctx.vertex_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		wgpu.Buffer_Data_Descriptor {
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
		wgpu.Buffer_Data_Descriptor {
			label = EXAMPLE_TITLE + " Index Buffer",
			contents = wgpu.to_bytes(indices),
			usage = {.Index},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.index_buffer)
	}

	num_vertices :: 100
	angle := math.PI * 2.0 / f32(num_vertices)
	challenge_verts: [num_vertices]Vertex

	for i := 0; i < num_vertices; i += 1 {
		theta := angle * f32(i)
		theta_sin, theta_cos := math.sincos_f64(f64(theta))

		challenge_verts[i] = Vertex {
			position = {0.5 * f32(theta_cos), -0.5 * f32(theta_sin), 0.0},
			color    = {(1.0 + f32(theta_cos)) / 2.0, (1.0 + f32(theta_sin)) / 2.0, 1.0},
		}
	}

	num_triangles :: num_vertices - 2
	challenge_indices: [num_triangles * 3]u16
	{
		index := 0
		for i := u16(1); i < num_triangles + 1; i += 1 {
			challenge_indices[index] = i + 1
			challenge_indices[index + 1] = i
			challenge_indices[index + 2] = 0
			index += 3
		}
	}

	ctx.num_challenge_indices = cast(u32)len(challenge_indices)

	ctx.challenge_vertex_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		wgpu.Buffer_Data_Descriptor {
			label = EXAMPLE_TITLE + " Vertex Buffer",
			contents = wgpu.to_bytes(challenge_verts[:]),
			usage = {.Vertex},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.challenge_vertex_buffer)
	}

	ctx.challenge_index_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		wgpu.Buffer_Data_Descriptor {
			label = EXAMPLE_TITLE + " Index Buffer",
			contents = wgpu.to_bytes(challenge_indices[:]),
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
	wgpu.release(ctx.challenge_index_buffer)
	wgpu.release(ctx.challenge_vertex_buffer)
	wgpu.release(ctx.index_buffer)
	wgpu.release(ctx.vertex_buffer)
	wgpu.release(ctx.render_pipeline)
}

draw :: proc(ctx: ^Context) -> bool {
	ctx.cmd = wgpu.device_create_command_encoder(ctx.gpu.device) or_return
	defer wgpu.release(ctx.cmd)

	ctx.render_pass.color_attachments[0].view = ctx.frame.view
	render_pass := wgpu.command_encoder_begin_render_pass(ctx.cmd, ctx.render_pass.descriptor)
	defer wgpu.release(render_pass)

	wgpu.render_pass_set_pipeline(render_pass, ctx.render_pipeline)

	if app.key_is_down(ctx, .Space) {
		wgpu.render_pass_set_vertex_buffer(render_pass, 0, {buffer = ctx.challenge_vertex_buffer})
		wgpu.render_pass_set_index_buffer(
			render_pass,
			{buffer = ctx.challenge_index_buffer},
			.Uint16,
		)
		wgpu.render_pass_draw_indexed(render_pass, {0, ctx.num_challenge_indices})
	} else {
		wgpu.render_pass_set_vertex_buffer(render_pass, 0, {buffer = ctx.vertex_buffer})
		wgpu.render_pass_set_index_buffer(render_pass, {buffer = ctx.index_buffer}, .Uint16)
		wgpu.render_pass_draw_indexed(render_pass, {0, ctx.num_indices})
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
