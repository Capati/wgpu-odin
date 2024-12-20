package microui_example

// Packages
import "core:log"

// Vendor
import mu "vendor:microui"

// Local packages
import wgpu "./../../"
import app "./../../utils/application"

Example :: struct {
	log_buf:         [64000]u8,
	log_buf_len:     int,
	log_buf_updated: bool,
	bg:              mu.Color,
	render_pass:     struct {
		color_attachments: [1]wgpu.RenderPassColorAttachment,
		descriptor:        wgpu.RenderPassDescriptor,
	},
}

Context :: app.Context(Example)

EXAMPLE_TITLE :: "MicroUI Example"

init :: proc(ctx: ^Context) -> (ok: bool) {
	// Set initial state
	ctx.bg = {56, 130, 210, 255}

	ctx.render_pass.color_attachments[0] = {
		view        = nil, /* Assigned later */
		depth_slice = wgpu.DEPTH_SLICE_UNDEFINED,
		load_op     = .Clear,
		store_op    = .Store,
		clear_value = get_color_from_mu_color(ctx.bg),
	}

	ctx.render_pass.descriptor = {
		label             = "Render pass descriptor",
		color_attachments = ctx.render_pass.color_attachments[:],
	}

	return true
}

get_color_from_mu_color :: proc(color: mu.Color) -> wgpu.Color {
	return {f64(color.r) / 255.0, f64(color.g) / 255.0, f64(color.b) / 255.0, 1.0}
}

handle_event :: proc(ctx: ^Context, event: app.Event) {
	app.ui_handle_event(ctx, event)
}

ui_update :: proc(ctx: ^Context, mu_ctx: ^mu.Context) -> (ok: bool) {
	// UI definition
	test_window(ctx, mu_ctx)
	log_window(ctx, mu_ctx)
	style_window(ctx, mu_ctx)
	return true
}

update :: proc(ctx: ^Context, dt: f64) -> bool {
	ctx.render_pass.color_attachments[0].clear_value = get_color_from_mu_color(ctx.bg)
	return true
}

draw :: proc(ctx: ^Context) -> bool {
	ctx.cmd = wgpu.device_create_command_encoder(ctx.gpu.device) or_return
	defer wgpu.release(ctx.cmd)

	ctx.render_pass.color_attachments[0].view = ctx.frame.view
	render_pass := wgpu.command_encoder_begin_render_pass(ctx.cmd, ctx.render_pass.descriptor)
	defer wgpu.release(render_pass)
	wgpu.render_pass_end(render_pass) or_return

	app.ui_draw(ctx) or_return

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
		init          = init,
		handle_event = handle_event,
		ui_update     = ui_update,
		update        = update,
		draw          = draw,
	}

	app.run(example) // Start the main loop
}
