#+vet !unused-imports
package triangle_msaa

// Packages
import "core:log"

// Local packages
import wgpu "./../../"
import app "./../../utils/application"

Example :: struct {
	render_pipeline: wgpu.RenderPipeline,
	msaa_view:       wgpu.TextureView,
	render_pass:     struct {
		color_attachments: [1]wgpu.RenderPassColorAttachment,
		descriptor:        wgpu.RenderPassDescriptor,
	},
}

Context :: app.Context(Example)

EXAMPLE_TITLE :: "Triangle 4x MSAA"
SAMPLE_COUNT: u32 : 4 // This value is guaranteed to be supported

init :: proc(ctx: ^Context) -> bool {
	// Use the same shader from the triangle example
	TRIANGLE_WGSL: string : #load("./../triangle/triangle.wgsl", string)
	shader_module := wgpu.device_create_shader_module(
		ctx.gpu.device,
		{label = EXAMPLE_TITLE + " Module", source = string(TRIANGLE_WGSL)},
	) or_return
	defer wgpu.shader_module_release(shader_module)

	ctx.render_pipeline = wgpu.device_create_render_pipeline(
		ctx.gpu.device,
		{
			label = EXAMPLE_TITLE + " Render Pipeline",
			vertex = {module = shader_module, entry_point = "vs_main"},
			fragment = &{
				module = shader_module,
				entry_point = "fs_main",
				targets = {
					{
						format = ctx.gpu.config.format,
						blend = &wgpu.BLEND_STATE_NORMAL,
						write_mask = wgpu.COLOR_WRITE_MASK_ALL,
					},
				},
			},
			multisample = {count = SAMPLE_COUNT, mask = max(u32)},
		},
	) or_return

	create_msaa_framebuffer(ctx) or_return

	ctx.render_pass.color_attachments[0] = {
		view           = nil, /* Assigned later */
		resolve_target = nil, /* Assigned later */
		depth_slice    = wgpu.DEPTH_SLICE_UNDEFINED,
		load_op        = .Clear,
		store_op       = .Store,
		clear_value    = app.ColorBlack,
	}

	ctx.render_pass.descriptor = {
		label             = "Render pass descriptor",
		color_attachments = ctx.render_pass.color_attachments[:],
	}

	return true
}

create_msaa_framebuffer :: proc(ctx: ^Context) -> (ok: bool) {
	format_features := wgpu.texture_format_guaranteed_format_features(
		ctx.gpu.config.format,
		ctx.gpu.features,
	)

	size := ctx.framebuffer_size

	texture_descriptor := wgpu.TextureDescriptor {
		size            = {size.w, size.h, 1},
		mip_level_count = 1,
		sample_count    = SAMPLE_COUNT,
		dimension       = .D2,
		format          = ctx.gpu.config.format,
		usage           = format_features.allowed_usages,
	}

	texture := wgpu.device_create_texture(ctx.gpu.device, texture_descriptor) or_return
	defer wgpu.release(texture)

	ctx.msaa_view = wgpu.texture_create_view(texture) or_return

	return true
}

quit :: proc(ctx: ^Context) {
	wgpu.release(ctx.msaa_view)
	wgpu.render_pipeline_release(ctx.render_pipeline)
}

resize :: proc(ctx: ^Context, size: app.ResizeEvent) -> (ok: bool) {
	wgpu.release(ctx.msaa_view)
	create_msaa_framebuffer(ctx) or_return
	return true
}

draw :: proc(ctx: ^Context) -> bool {
	ctx.cmd = wgpu.device_create_command_encoder(ctx.gpu.device) or_return
	defer wgpu.release(ctx.cmd)

	ctx.render_pass.color_attachments[0].view = ctx.msaa_view
	ctx.render_pass.color_attachments[0].resolve_target = ctx.frame.view
	render_pass := wgpu.command_encoder_begin_render_pass(ctx.cmd, ctx.render_pass.descriptor)
	defer wgpu.release(render_pass)

	wgpu.render_pass_set_pipeline(render_pass, ctx.render_pipeline)
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
		init   = init,
		quit   = quit,
		resize = resize,
		draw   = draw,
	}

	app.run(example) // Start the main loop
}
