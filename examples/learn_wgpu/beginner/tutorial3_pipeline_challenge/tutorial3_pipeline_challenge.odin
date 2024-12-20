package tutorial3_pipeline_challenge

// Packages
import "core:log"

// Local Packages
import wgpu "./../../../../"
import app "./../../../../utils/application"

Example :: struct {
	render_pipeline:           wgpu.RenderPipeline,
	challenge_render_pipeline: wgpu.RenderPipeline,
	render_pass:               struct {
		color_attachments: [1]wgpu.RenderPassColorAttachment,
		descriptor:        wgpu.RenderPassDescriptor,
	},
}

Context :: app.Context(Example)

EXAMPLE_TITLE :: "Tutorial 3 - Pipeline Challenge"

init :: proc(ctx: ^Context) -> (ok: bool) {
	// Use the same shader from the Tutorial 3 - Pipeline
	SHADER_WGSL :: #load("./../tutorial3_pipeline/shader.wgsl")
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

	render_pipeline_descriptor := wgpu.RenderPipelineDescriptor {
		label = EXAMPLE_TITLE + " Render Pipeline",
		layout = render_pipeline_layout,
		vertex = {module = shader_module, entry_point = "vs_main"},
		fragment = &{
			module = shader_module,
			entry_point = "fs_main",
			targets = {
				{
					format = ctx.gpu.config.format,
					blend = &wgpu.BLEND_STATE_REPLACE,
					write_mask = wgpu.COLOR_WRITE_MASK_ALL,
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

	CHALLENGE_WGSL :: #load("./challenge.wgsl")
	challenge_shader_module := wgpu.device_create_shader_module(
		ctx.gpu.device,
		{source = string(CHALLENGE_WGSL)},
	) or_return
	defer wgpu.release(challenge_shader_module)

	challenge_render_pipeline_descriptor := wgpu.RenderPipelineDescriptor {
		label = EXAMPLE_TITLE + " Challenge Render Pipeline",
		layout = render_pipeline_layout,
		vertex = {module = challenge_shader_module, entry_point = "vs_main"},
		fragment = &{
			module = challenge_shader_module,
			entry_point = "fs_main",
			targets = {
				{
					format = ctx.gpu.config.format,
					blend = &wgpu.BLEND_STATE_REPLACE,
					write_mask = wgpu.COLOR_WRITE_MASK_ALL,
				},
			},
		},
		primitive = {topology = .TriangleList, front_face = .CCW, cull_mode = .Back},
		depth_stencil = nil,
		multisample = {count = 1, mask = ~u32(0), alpha_to_coverage_enabled = false},
	}

	ctx.challenge_render_pipeline = wgpu.device_create_render_pipeline(
		ctx.gpu.device,
		challenge_render_pipeline_descriptor,
	) or_return

	ctx.render_pass.color_attachments[0] = {
		view        = nil, /* Assigned later */
		depth_slice = wgpu.DEPTH_SLICE_UNDEFINED,
		load_op     = .Clear,
		store_op    = .Store,
		clear_value = {0.1, 0.2, 0.3, 1.0},
	}

	ctx.render_pass.descriptor = {
		label             = "Render pass descriptor",
		color_attachments = ctx.render_pass.color_attachments[:],
	}

	return true
}

quit :: proc(ctx: ^Context) {
	wgpu.release(ctx.challenge_render_pipeline)
	wgpu.release(ctx.render_pipeline)
}

draw :: proc(ctx: ^Context) -> bool {
	ctx.cmd = wgpu.device_create_command_encoder(ctx.gpu.device) or_return
	defer wgpu.release(ctx.cmd)

	ctx.render_pass.color_attachments[0].view = ctx.frame.view
	render_pass := wgpu.command_encoder_begin_render_pass(ctx.cmd, ctx.render_pass.descriptor)
	defer wgpu.release(render_pass)

	if app.key_is_down(ctx, .Space) {
		wgpu.render_pass_set_pipeline(render_pass, ctx.challenge_render_pipeline)
	} else {
		wgpu.render_pass_set_pipeline(render_pass, ctx.render_pipeline)
	}

	wgpu.render_pass_draw(render_pass, {0, 3})

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
