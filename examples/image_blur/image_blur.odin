package image_blur

// Packages
import "core:log"
import "core:math"

// Vendor
import mu "vendor:microui"

// Local Packages
import app "root:utils/application"
import "root:wgpu"

Settings :: struct {
	filter_size: i32,
	iterations:  i32,
}

Example :: struct {
	blur_pipeline:            wgpu.ComputePipeline,
	fullscreen_quad_pipeline: wgpu.RenderPipeline,
	image_texture:            app.Texture,
	textures:                 [2]struct {
		texture: wgpu.Texture,
		view:    wgpu.TextureView,
	},
	buffer_0:                 wgpu.Buffer,
	buffer_1:                 wgpu.Buffer,
	sampler:                  wgpu.Sampler,
	blur_params_buffer:       wgpu.Buffer,
	compute_constants:        wgpu.BindGroup,
	compute_bind_group_0:     wgpu.BindGroup,
	compute_bind_group_1:     wgpu.BindGroup,
	compute_bind_group_2:     wgpu.BindGroup,
	show_result_bind_group:   wgpu.BindGroup,
	block_dim:                i32,
	blur_settings:            Settings,
	render_pass:              struct {
		color_attachments: [1]wgpu.RenderPassColorAttachment,
		descriptor:        wgpu.RenderPassDescriptor,
	},
}

Context :: app.Context(Example)

// Constants from the shader
TILE_DIM: i32 : 128
BATCH :: 4

SLIDER_FMT :: "%.0f"

EXAMPLE_TITLE :: "Image Blur"

init :: proc(ctx: ^Context) -> (ok: bool) {
	// Initialize example objects
	BLUR_SOURCE :: #load("./blur.wgsl")
	blur_shader := wgpu.device_create_shader_module(
		ctx.gpu.device,
		{source = string(BLUR_SOURCE)},
	) or_return
	defer wgpu.release(blur_shader)
	ctx.blur_pipeline = wgpu.device_create_compute_pipeline(
		ctx.gpu.device,
		{module = blur_shader, entry_point = "main"},
	) or_return
	defer if !ok {
		wgpu.release(ctx.blur_pipeline)
	}

	FULLSCREEN_TEXTURED_QUAD_WGSL :: #load("./fullscreen_textured_quad.wgsl")
	quad_shader_module := wgpu.device_create_shader_module(
		ctx.gpu.device,
		{source = string(FULLSCREEN_TEXTURED_QUAD_WGSL)},
	) or_return
	defer wgpu.release(quad_shader_module)

	ctx.fullscreen_quad_pipeline = wgpu.device_create_render_pipeline(
		ctx.gpu.device,
		{
			vertex = {module = quad_shader_module, entry_point = "vert_main"},
			fragment = &{
				module = quad_shader_module,
				entry_point = "frag_main",
				targets = {
					{
						format = ctx.gpu.config.format,
						blend = nil,
						write_mask = wgpu.COLOR_WRITES_ALL,
					},
				},
			},
			primitive = {topology = .TriangleList, front_face = .CCW, cull_mode = .None},
			multisample = wgpu.DEFAULT_MULTISAMPLE_STATE,
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.fullscreen_quad_pipeline)
	}

	ctx.image_texture = app.create_texture_from_file(ctx, "./assets/textures/nature.jpg") or_return
	defer if !ok {
		app.release(ctx.image_texture)
	}

	image_texture_descriptor := wgpu.texture_descriptor(ctx.image_texture.texture)
	for &t in ctx.textures {
		t.texture = wgpu.device_create_texture(
			ctx.gpu.device,
			{
				usage = {.CopyDst, .StorageBinding, .TextureBinding},
				dimension = image_texture_descriptor.dimension,
				size = image_texture_descriptor.size,
				format = image_texture_descriptor.format,
				mip_level_count = image_texture_descriptor.mip_level_count,
				sample_count = image_texture_descriptor.sample_count,
			},
		) or_return
		t.view = wgpu.texture_create_view(t.texture) or_return
	}
	defer if !ok {
		for t in ctx.textures {
			wgpu.release(t.texture)
			wgpu.release(t.view)
		}
	}

	ctx.buffer_0 = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{contents = wgpu.to_bytes([1]u32{0}), usage = {.Uniform}},
	) or_return
	defer if !ok {
		wgpu.release(ctx.buffer_0)
	}

	ctx.buffer_1 = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{contents = wgpu.to_bytes([1]u32{1}), usage = {.Uniform}},
	) or_return
	defer if !ok {
		wgpu.release(ctx.buffer_1)
	}

	ctx.blur_params_buffer = wgpu.device_create_buffer(
		ctx.gpu.device,
		{size = size_of(Settings), usage = {.CopyDst, .Uniform}},
	) or_return
	defer if !ok {
		wgpu.release(ctx.blur_params_buffer)
	}

	blur_pipeline_layout_0 := wgpu.compute_pipeline_get_bind_group_layout(
		ctx.blur_pipeline,
		0,
	) or_return
	defer wgpu.release(blur_pipeline_layout_0)

	sampler_descriptor := wgpu.DEFAULT_SAMPLER_DESCRIPTOR
	sampler_descriptor.mag_filter = .Linear
	sampler_descriptor.min_filter = .Linear
	ctx.sampler = wgpu.device_create_sampler(ctx.gpu.device, sampler_descriptor) or_return
	defer if !ok {
		wgpu.release(ctx.sampler)
	}

	ctx.compute_constants = wgpu.device_create_bind_group(
		ctx.gpu.device,
		{
			layout = blur_pipeline_layout_0,
			entries = {
				{binding = 0, resource = ctx.sampler},
				{
					binding = 1,
					resource = wgpu.BufferBinding {
						buffer = ctx.blur_params_buffer,
						size = wgpu.buffer_size(ctx.blur_params_buffer),
					},
				},
			},
		},
	) or_return

	blur_pipeline_layout_1 := wgpu.compute_pipeline_get_bind_group_layout(
		ctx.blur_pipeline,
		1,
	) or_return
	defer wgpu.release(blur_pipeline_layout_1)

	ctx.compute_bind_group_0 = wgpu.device_create_bind_group(
		ctx.gpu.device,
		{
			layout = blur_pipeline_layout_1,
			entries = {
				{binding = 1, resource = ctx.image_texture.view},
				{binding = 2, resource = ctx.textures[0].view},
				{
					binding = 3,
					resource = wgpu.BufferBinding {
						buffer = ctx.buffer_0,
						size = wgpu.buffer_size(ctx.buffer_0),
					},
				},
			},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.compute_bind_group_0)
	}

	ctx.compute_bind_group_1 = wgpu.device_create_bind_group(
		ctx.gpu.device,
		{
			layout = blur_pipeline_layout_1,
			entries = {
				{binding = 1, resource = ctx.textures[0].view},
				{binding = 2, resource = ctx.textures[1].view},
				{
					binding = 3,
					resource = wgpu.BufferBinding {
						buffer = ctx.buffer_1,
						size = wgpu.buffer_size(ctx.buffer_1),
					},
				},
			},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.compute_bind_group_1)
	}

	ctx.compute_bind_group_2 = wgpu.device_create_bind_group(
		ctx.gpu.device,
		{
			layout = blur_pipeline_layout_1,
			entries = {
				{binding = 1, resource = ctx.textures[1].view},
				{binding = 2, resource = ctx.textures[0].view},
				{
					binding = 3,
					resource = wgpu.BufferBinding {
						buffer = ctx.buffer_0,
						size = wgpu.buffer_size(ctx.buffer_0),
					},
				},
			},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.compute_bind_group_2)
	}

	fullscreen_quad_pipeline_layout := wgpu.render_pipeline_get_bind_group_layout(
		ctx.fullscreen_quad_pipeline,
		0,
	) or_return
	defer wgpu.release(fullscreen_quad_pipeline_layout)

	ctx.show_result_bind_group = wgpu.device_create_bind_group(
		ctx.gpu.device,
		{
			layout = fullscreen_quad_pipeline_layout,
			entries = {
				{binding = 0, resource = ctx.sampler},
				{binding = 1, resource = ctx.textures[1].view},
			},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.show_result_bind_group)
	}

	ctx.render_pass.color_attachments[0] = {
		view = nil, /* Assigned later */
		ops  = {.Clear, .Store, app.ColorBlack},
	}

	ctx.render_pass.descriptor = {
		label             = "Render pass descriptor",
		color_attachments = ctx.render_pass.color_attachments[:],
	}

	ctx.blur_settings = {
		filter_size = 15,
		iterations  = 2,
	}

	update_settings(ctx) or_return

	return true
}

quit :: proc(ctx: ^Context) {
	wgpu.release(ctx.show_result_bind_group)
	wgpu.release(ctx.compute_bind_group_2)
	wgpu.release(ctx.compute_bind_group_1)
	wgpu.release(ctx.compute_bind_group_0)
	for &t in ctx.textures {
		wgpu.release(t.texture)
		wgpu.release(t.view)
	}
	wgpu.release(ctx.buffer_0)
	wgpu.release(ctx.buffer_1)
	wgpu.release(ctx.sampler)
	wgpu.release(ctx.blur_params_buffer)
	wgpu.release(ctx.compute_constants)
	app.release(ctx.image_texture)
	wgpu.release(ctx.fullscreen_quad_pipeline)
	wgpu.release(ctx.blur_pipeline)
}

update_settings :: proc(ctx: ^Context) -> bool {
	ctx.block_dim = TILE_DIM - (ctx.blur_settings.filter_size - 1)
	wgpu.queue_write_buffer(
		ctx.gpu.queue,
		ctx.blur_params_buffer,
		0,
		wgpu.to_bytes([2]i32{ctx.blur_settings.filter_size, ctx.block_dim}),
	) or_return

	return true
}

handle_event :: proc(ctx: ^Context, event: app.Event) {
	app.ui_handle_event(ctx, event)
}

ui_update :: proc(ctx: ^Context, mu_ctx: ^mu.Context) -> bool {
	if mu.begin_window(mu_ctx, "Settings", {10, 10, 245, 78}, {.NO_RESIZE, .NO_CLOSE}) {
		mu.layout_row(mu_ctx, {-1}, 40)
		mu.layout_begin_column(mu_ctx)
		{
			mu.layout_row(mu_ctx, {60, -1}, 0)
			mu.label(mu_ctx, "Filter size:")
			if .CHANGE in
			   app.ui_slider(mu_ctx, &ctx.blur_settings.filter_size, 2, 34, 2, SLIDER_FMT) {
				update_settings(ctx) or_return
			}
			mu.label(mu_ctx, "Iterations:")
			if .CHANGE in
			   app.ui_slider(mu_ctx, &ctx.blur_settings.iterations, 1, 20, 1, SLIDER_FMT) {
				update_settings(ctx) or_return
			}
		}
		mu.layout_end_column(mu_ctx)

		mu.end_window(mu_ctx)
	}

	return true
}

compute :: proc(ctx: ^Context) -> bool {
	compute_pass := wgpu.command_encoder_begin_compute_pass(ctx.cmd) or_return
	defer wgpu.release(compute_pass)

	wgpu.compute_pass_set_pipeline(compute_pass, ctx.blur_pipeline)
	wgpu.compute_pass_set_bind_group(compute_pass, 0, ctx.compute_constants)

	image_size := wgpu.texture_size(ctx.image_texture.texture)

	wgpu.compute_pass_set_bind_group(compute_pass, 1, ctx.compute_bind_group_0)
	wgpu.compute_pass_dispatch_workgroups(
		compute_pass,
		u32(math.ceil(f32(image_size.width) / f32(ctx.block_dim))),
		u32(math.ceil(f32(image_size.height) / BATCH)),
	)

	wgpu.compute_pass_set_bind_group(compute_pass, 1, ctx.compute_bind_group_1)
	wgpu.compute_pass_dispatch_workgroups(
		compute_pass,
		u32(math.ceil(f32(image_size.height) / f32(ctx.block_dim))),
		u32(math.ceil(f32(image_size.width) / BATCH)),
	)

	for _ in 0 ..< ctx.blur_settings.iterations - 1 {
		wgpu.compute_pass_set_bind_group(compute_pass, 1, ctx.compute_bind_group_2)
		wgpu.compute_pass_dispatch_workgroups(
			compute_pass,
			u32(math.ceil(f32(image_size.width) / f32(ctx.block_dim))),
			u32(math.ceil(f32(image_size.height) / BATCH)),
		)

		wgpu.compute_pass_set_bind_group(compute_pass, 1, ctx.compute_bind_group_1)
		wgpu.compute_pass_dispatch_workgroups(
			compute_pass,
			u32(math.ceil(f32(image_size.height) / f32(ctx.block_dim))),
			u32(math.ceil(f32(image_size.width) / BATCH)),
		)
	}

	wgpu.compute_pass_end(compute_pass) or_return

	return true
}

draw :: proc(ctx: ^Context) -> bool {
	ctx.cmd = wgpu.device_create_command_encoder(ctx.gpu.device) or_return
	defer wgpu.release(ctx.cmd)

	compute(ctx) or_return

	ctx.render_pass.color_attachments[0].view = ctx.frame.view
	render_pass := wgpu.command_encoder_begin_render_pass(ctx.cmd, ctx.render_pass.descriptor)
	defer wgpu.release(render_pass)

	wgpu.render_pass_set_pipeline(render_pass, ctx.fullscreen_quad_pipeline)
	wgpu.render_pass_set_bind_group(render_pass, 0, ctx.show_result_bind_group)
	wgpu.render_pass_draw(render_pass, {0, 6})

	wgpu.render_pass_end(render_pass) or_return

	app.ui_draw(ctx) or_return // MicroUI rendering

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
		init         = init,
		quit         = quit,
		handle_event = handle_event,
		ui_update    = ui_update,
		draw         = draw,
	}

	app.run(example)
}
