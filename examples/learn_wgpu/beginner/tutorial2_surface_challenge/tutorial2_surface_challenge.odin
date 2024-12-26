package tutorial2_surface_challenge

// Packages
import "core:log"

// Local packages
import app "root:utils/application"
import "root:wgpu"

Example :: struct {
	clear_value: app.Color,
	render_pass: struct {
		color_attachments: [1]wgpu.RenderPassColorAttachment,
		descriptor:        wgpu.RenderPassDescriptor,
	},
}

Context :: app.Context(Example)

EXAMPLE_TITLE :: "Tutorial 2 - Surface Challenge"

init :: proc(ctx: ^Context) -> (ok: bool) {
	ctx.clear_value = app.ColorRoyalBlue

	ctx.render_pass.color_attachments[0] = {
		view = nil, /* Assigned later */
		ops  = {.Clear, .Store, ctx.clear_value},
	}

	ctx.render_pass.descriptor = {
		label             = "Render pass descriptor",
		color_attachments = ctx.render_pass.color_attachments[:],
	}

	return true
}

calculate_color_from_position :: proc(x, y: f32, w, h: u32) -> (color: app.Color) {
	color.r = cast(f64)x / cast(f64)w
	color.g = cast(f64)y / cast(f64)h
	color.b = 1.0
	color.a = 1.0
	return
}

mouse_position :: proc(ctx: ^Context, event: app.MouseMovedEvent) {
	ctx.clear_value = calculate_color_from_position(
		event.x,
		event.y,
		ctx.gpu.config.width,
		ctx.gpu.config.height,
	)
}

draw :: proc(ctx: ^Context) -> bool {
	ctx.cmd = wgpu.device_create_command_encoder(ctx.gpu.device) or_return
	defer wgpu.release(ctx.cmd)

	ctx.render_pass.color_attachments[0].view = ctx.frame.view
	ctx.render_pass.color_attachments[0].ops.clear_value = ctx.clear_value
	render_pass := wgpu.command_encoder_begin_render_pass(ctx.cmd, ctx.render_pass.descriptor)
	defer wgpu.release(render_pass)
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
		init           = init,
		mouse_position = mouse_position,
		draw           = draw,
	}

	app.run(example) // Start the main loop
}
