package clear_screen

// Packages
import "core:log"
import "core:math"

// Local packages
import app "root:utils/application"
import "root:wgpu"

EXAMPLE_TITLE :: "Clear Screen"

Example :: struct {
	render_pass: struct {
		color_attachments: [1]wgpu.Render_Pass_Color_Attachment,
		descriptor:        wgpu.Render_Pass_Descriptor,
	},
}

Context :: app.Context(Example)

init :: proc(ctx: ^Context) -> (ok: bool) {
	ctx.render_pass.color_attachments[0] = {
		view = nil, /* Assigned later */
		ops = {load = .Clear, store = .Store, clear_value = {0.0, 0.0, 1.0, 1.0}},
	}

	ctx.render_pass.descriptor = {
		label             = "Render pass descriptor",
		color_attachments = ctx.render_pass.color_attachments[:],
	}

	return true
}

update :: proc(ctx: ^Context, dt: f64) -> (ok: bool) {
	t := math.cos_f64(app.timer_get_time(&ctx.timer)) * 0.5 + 0.5
	color := app.color_lerp({}, {0.0, 0.0, 1.0, 1.0}, t)
	ctx.render_pass.color_attachments[0].ops.clear_value = color
	return true
}

draw :: proc(ctx: ^Context) -> (ok: bool) {
	ctx.cmd = wgpu.device_create_command_encoder(ctx.gpu.device) or_return
	defer wgpu.release(ctx.cmd)

	ctx.render_pass.color_attachments[0].view = ctx.frame.view
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
		init   = init,
		update = update,
		draw   = draw,
	}

	app.run(example)
}
