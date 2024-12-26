#+vet !unused-imports
package square

// Packages
import "base:builtin"
import "core:log"

// Local packages
import "root:examples/common"
import app "root:utils/application"
import "root:wgpu"

// odinfmt: disable
POSITIONS := [?]f32 {
    -0.5,  0.5, 0.0, // v0
     0.5,  0.5, 0.0, // v1
    -0.5, -0.5, 0.0, // v2
     0.5, -0.5, 0.0, // v3
}

COLORS := [?]f32 {
    1.0, 0.0, 0.0, 1.0, // v0
    0.0, 1.0, 0.0, 1.0, // v1
    0.0, 0.0, 1.0, 1.0, // v2
    1.0, 1.0, 0.0, 1.0, // v3
}
// odinfmt: enable

Example :: struct {
	render_pass:      struct {
		color_attachments: [1]wgpu.RenderPassColorAttachment,
		descriptor:        wgpu.RenderPassDescriptor,
	},
	positions_buffer: wgpu.Buffer,
	colors_buffer:    wgpu.Buffer,
	render_pipeline:  wgpu.RenderPipeline,
}

Context :: app.Context(Example)

EXAMPLE_TITLE :: "Square"

init :: proc(ctx: ^Context) -> (ok: bool) {
	ctx.positions_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{
			label = "Positions buffer",
			contents = wgpu.to_bytes(POSITIONS),
			usage = {.Vertex, .CopyDst},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.positions_buffer)
	}

	ctx.colors_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{label = "Colors buffer", contents = wgpu.to_bytes(COLORS), usage = {.Vertex, .CopyDst}},
	) or_return
	defer if !ok {
		wgpu.release(ctx.colors_buffer)
	}

	CUBE_WGSL :: #load("./square.wgsl")
	shader_module := wgpu.device_create_shader_module(
		ctx.gpu.device,
		{label = EXAMPLE_TITLE + " Module", source = string(CUBE_WGSL)},
	) or_return
	defer wgpu.release(shader_module)

	pipeline_descriptor := wgpu.RenderPipelineDescriptor {
		label = EXAMPLE_TITLE + " Render Pipeline",
		vertex = {
			module = shader_module,
			entry_point = "vs_main",
			buffers = {
				{
					array_stride = 3 * 4,
					step_mode = .Vertex,
					attributes = {{shader_location = 0, format = .Float32x3, offset = 0}},
				},
				{
					array_stride = 4 * 4,
					step_mode = .Vertex,
					attributes = {{shader_location = 1, format = .Float32x4, offset = 0}},
				},
			},
		},
		fragment = &{
			module = shader_module,
			entry_point = "fs_main",
			targets = {
				{
					format = ctx.gpu.config.format,
					blend = &wgpu.BLEND_STATE_NORMAL,
					write_mask = wgpu.COLOR_WRITES_ALL,
				},
			},
		},
		primitive = {
			topology = .TriangleStrip,
			strip_index_format = .Uint32,
			front_face = .CCW,
			cull_mode = .Front,
		},
		multisample = wgpu.DEFAULT_MULTISAMPLE_STATE,
	}

	ctx.render_pipeline = wgpu.device_create_render_pipeline(
		ctx.gpu.device,
		pipeline_descriptor,
	) or_return
	defer if !ok {
		wgpu.release(ctx.render_pipeline)
	}

	ctx.render_pass.color_attachments[0] = {
		view = nil, /* Assigned later */
		ops  = {.Clear, .Store, app.ColorBlack},
	}

	ctx.render_pass.descriptor = {
		label             = "Render pass descriptor",
		color_attachments = ctx.render_pass.color_attachments[:],
	}

	return true
}

quit :: proc(ctx: ^Context) {
	wgpu.release(ctx.render_pipeline)
	wgpu.release(ctx.colors_buffer)
	wgpu.release(ctx.positions_buffer)
}

draw :: proc(ctx: ^Context) -> bool {
	encoder := wgpu.device_create_command_encoder(ctx.gpu.device) or_return
	defer wgpu.release(encoder)

	ctx.render_pass.color_attachments[0].view = ctx.frame.view
	render_pass := wgpu.command_encoder_begin_render_pass(encoder, ctx.render_pass.descriptor)
	defer wgpu.release(render_pass)

	// Bind the rendering pipeline
	wgpu.render_pass_set_pipeline(render_pass, ctx.render_pipeline)

	// Bind vertex buffers (contain position & colors)
	wgpu.render_pass_set_vertex_buffer(render_pass, 0, {buffer = ctx.positions_buffer})
	wgpu.render_pass_set_vertex_buffer(render_pass, 1, {buffer = ctx.colors_buffer})

	// Draw quad
	wgpu.render_pass_draw(render_pass, {0, 4})

	// End render pass
	wgpu.render_pass_end(render_pass) or_return

	cmdbuf := wgpu.command_encoder_finish(encoder) or_return
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
