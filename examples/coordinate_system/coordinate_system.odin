package coordinate_system

// Packages
import "core:log"

// Vendor
import mu "vendor:microui"

// Local packages
import app "root:utils/application"
import "root:wgpu"

EXAMPLE_TITLE :: "Coordinate System"

VERTICES_Y_UP :: 0
VERTICES_Y_DOWN :: 1

Example :: struct {
	texture_cw:         app.Texture,
	texture_ccw:        app.Texture,
	buffer_indices_ccw: wgpu.Buffer,
	buffer_indices_cw:  wgpu.Buffer,
	bind_group_ccw:     wgpu.BindGroup,
	bind_group_cw:      wgpu.BindGroup,
	pipeline_layout:    wgpu.PipelineLayout,
	shader_module:      wgpu.ShaderModule,
	render_pipeline:    wgpu.RenderPipeline,
	render_pass:        struct {
		color_attachments: [1]wgpu.RenderPassColorAttachment,
		descriptor:        wgpu.RenderPassDescriptor,
	},

	// Settings
	quad:               [2]wgpu.Buffer,
	quad_str:           [2]string,
	selected_quad:      u32,
	order:              [2]wgpu.FrontFace,
	order_str:          [2]string,
	selected_order:     u32,
	face:               [3]wgpu.Face,
	face_str:           [3]string,
	selected_face:      u32,
}

Vertex :: struct {
	pos: app.Vec3,
	uv:  app.Vec2,
}

Context :: app.Context(Example)

init :: proc(ctx: ^Context) -> (ok: bool) {
	ctx.texture_cw = app.create_texture_from_file(
		"./assets/textures/texture_orientation_cw_rgba.png",
		ctx.gpu.device,
		ctx.gpu.queue,
	) or_return
	defer if !ok {
		app.texture_release(ctx.texture_cw)
	}

	ctx.texture_ccw = app.create_texture_from_file(
		"./assets/textures/texture_orientation_ccw_rgba.png",
		ctx.gpu.device,
		ctx.gpu.queue,
	) or_return
	defer if !ok {
		app.texture_release(ctx.texture_ccw)
	}

	aspect := f32(ctx.gpu.config.width) / f32(ctx.gpu.config.height)

	// odinfmt: disable
	vertices_y_pos := [4]Vertex {
		{pos = {-1.0 * aspect, -1.0, 1.0}, uv = {0.0, 1.0}},
		{pos = {-1.0 * aspect,  1.0, 1.0}, uv = {0.0, 0.0}},
		{pos = { 1.0 * aspect,  1.0, 1.0}, uv = {1.0, 0.0}},
		{pos = { 1.0 * aspect, -1.0, 1.0}, uv = {1.0, 1.0}},
	}
	// odinfmt: enable

	ctx.quad_str[VERTICES_Y_UP] = "WebGPU (Y positive)"
	ctx.quad[VERTICES_Y_UP] = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{
			label = "Vertices buffer - Y up",
			contents = wgpu.to_bytes(vertices_y_pos[:]),
			usage = {.CopyDst, .Vertex},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.quad[VERTICES_Y_UP])
	}

	ctx.selected_quad = VERTICES_Y_UP

	// odinfmt: disable
	vertices_y_neg := [4]Vertex {
		{pos = {-1.0 * aspect,  1.0, 1.0}, uv = {0.0, 1.0}},
		{pos = {-1.0 * aspect, -1.0, 1.0}, uv = {0.0, 0.0}},
		{pos = { 1.0 * aspect, -1.0, 1.0}, uv = {1.0, 0.0}},
		{pos = { 1.0 * aspect,  1.0, 1.0}, uv = {1.0, 1.0}},
	}
	// odinfmt: enable

	ctx.quad_str[VERTICES_Y_DOWN] = "VK (Y negative)"
	ctx.quad[VERTICES_Y_DOWN] = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{
			label = "Vertices buffer - Y down",
			contents = wgpu.to_bytes(vertices_y_neg[:]),
			usage = {.CopyDst, .Vertex},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.quad[VERTICES_Y_DOWN])
	}

	// odinfmt: disable
	indices_ccw := [6]u32  {
		2, 1, 0,
		0, 3, 2,
	}
	// odinfmt: enable

	ctx.buffer_indices_ccw = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{
			label = "Indices buffer - CCW",
			contents = wgpu.to_bytes(indices_ccw[:]),
			usage = {.CopyDst, .Index},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.buffer_indices_ccw)
	}

	// odinfmt: disable
	indices_cw := [6]u32  {
		0, 1, 2,
		2, 3, 0,
	}
	// odinfmt: enable

	ctx.buffer_indices_cw = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{
			label = "Indices buffer - CW",
			contents = wgpu.to_bytes(indices_cw[:]),
			usage = {.CopyDst, .Index},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.buffer_indices_cw)
	}

	bind_group_layout := wgpu.device_create_bind_group_layout(
		ctx.gpu.device,
		wgpu.BindGroupLayoutDescriptor {
			label = "Bind group layout",
			entries = {
				{
					binding = 0,
					visibility = {.Fragment},
					type = wgpu.TextureBindingLayout {
						sample_type = .Float,
						view_dimension = .D2,
						multisampled = false,
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
	defer wgpu.release(bind_group_layout)

	ctx.pipeline_layout = wgpu.device_create_pipeline_layout(
		ctx.gpu.device,
		{label = "Pipeline layout", bind_group_layouts = {bind_group_layout}},
	) or_return
	defer if !ok {
		wgpu.release(ctx.pipeline_layout)
	}

	ctx.bind_group_cw = wgpu.device_create_bind_group(
		ctx.gpu.device,
		{
			label = "Bind Group CW",
			layout = bind_group_layout,
			entries = {
				{binding = 0, resource = ctx.texture_cw.view},
				{binding = 1, resource = ctx.texture_cw.sampler},
			},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.bind_group_cw)
	}

	ctx.bind_group_ccw = wgpu.device_create_bind_group(
		ctx.gpu.device,
		{
			label = "Bind Group CCW",
			layout = bind_group_layout,
			entries = {
				{binding = 0, resource = ctx.texture_ccw.view},
				{binding = 1, resource = ctx.texture_ccw.sampler},
			},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.bind_group_ccw)
	}

	COORDINATE_SYSTEM_WGSL :: #load("./coordinate_system.wgsl")
	ctx.shader_module = wgpu.device_create_shader_module(
		ctx.gpu.device,
		{label = EXAMPLE_TITLE + " Module", source = string(COORDINATE_SYSTEM_WGSL)},
	) or_return
	defer if !ok {
		wgpu.release(ctx.shader_module)
	}

	ctx.order_str = {"Counter Clock Wise", "Clock Wise"}
	ctx.order = {.CCW, .CW}

	ctx.face_str = {"None", "Front", "Back"}
	ctx.face = {.None, .Front, .Back}

	prepare_pipelines(ctx) or_return

	ctx.render_pass.color_attachments[0] = {
		view = nil, /* Assigned later */
		ops  = {.Clear, .Store, {0.0, 0.0, 0.0, 1.0}},
	}

	app.setup_depth_stencil(ctx) or_return

	ctx.render_pass.descriptor = {
		label                    = "Render pass descriptor",
		color_attachments        = ctx.render_pass.color_attachments[:],
		depth_stencil_attachment = &ctx.depth_stencil.descriptor,
	}

	return true
}

prepare_pipelines :: proc(ctx: ^Context) -> (ok: bool) {
	if ctx.render_pipeline != nil {
		wgpu.render_pipeline_release(ctx.render_pipeline)
	}

	ctx.render_pipeline = wgpu.device_create_render_pipeline(
		ctx.gpu.device,
		{
			label = "Render Pipeline",
			layout = ctx.pipeline_layout,
			vertex = {
				module = ctx.shader_module,
				entry_point = "vs_main",
				buffers = {
					{
						array_stride = size_of(Vertex),
						step_mode = .Vertex,
						attributes = {
							{format = .Float32x3, offset = 0, shader_location = 0},
							{
								format = .Float32x2,
								offset = u64(offset_of(Vertex, uv)),
								shader_location = 1,
							},
						},
					},
				},
			},
			fragment = &{
				module = ctx.shader_module,
				entry_point = "fs_main",
				targets = {
					{
						format = ctx.gpu.config.format,
						blend = &wgpu.BLEND_STATE_NORMAL,
						write_mask = wgpu.COLOR_WRITES_ALL,
					},
				},
			},
			depth_stencil = app.create_depth_stencil_state(ctx),
			primitive = {
				topology = .TriangleList,
				front_face = ctx.order[ctx.selected_order],
				cull_mode = ctx.face[ctx.selected_face],
			},
			multisample = {count = 1, mask = max(u32)},
		},
	) or_return

	return true
}

quit :: proc(ctx: ^Context) {
	wgpu.release(ctx.render_pipeline)
	wgpu.release(ctx.pipeline_layout)
	wgpu.release(ctx.shader_module)

	wgpu.release(ctx.bind_group_ccw)
	wgpu.release(ctx.bind_group_cw)

	wgpu.release(ctx.buffer_indices_ccw)
	wgpu.release(ctx.buffer_indices_cw)
	wgpu.release(ctx.quad[VERTICES_Y_UP])
	wgpu.release(ctx.quad[VERTICES_Y_DOWN])

	app.texture_release(ctx.texture_ccw)
	app.texture_release(ctx.texture_cw)
}

handle_event :: proc(ctx: ^Context, event: app.Event) {
	app.ui_handle_event(ctx, event)
}

ui_update :: proc(ctx: ^Context, mu_ctx: ^mu.Context) -> (ok: bool) {
	if mu.begin_window(mu_ctx, "Settings", {40, 75, 230, 200}, {.NO_CLOSE, .NO_RESIZE}) {
		defer mu.end_window(mu_ctx)

		mu.layout_row(mu_ctx, {-1})
		mu.label(mu_ctx, "Quad Type:")
		mu.layout_row(mu_ctx, {-1})
		if .CHANGE in app.ui_combobox(mu_ctx, "##quadtype", &ctx.selected_quad, ctx.quad_str[:]) {
			log.infof("Quad type: %s", ctx.quad_str[ctx.selected_quad])
		}

		mu.layout_row(mu_ctx, {-1, -1})
		mu.label(mu_ctx, "Winding Order:")
		mu.layout_row(mu_ctx, {-1})
		if .CHANGE in
		   app.ui_combobox(mu_ctx, "##windingorder", &ctx.selected_order, ctx.order_str[:]) {
			log.infof("Winding order: %s", ctx.order_str[ctx.selected_order])
			prepare_pipelines(ctx) or_return
		}

		mu.layout_row(mu_ctx, {-1, -1})
		mu.label(mu_ctx, "Cull Mode:")
		mu.layout_row(mu_ctx, {-1})
		if .CHANGE in app.ui_combobox(mu_ctx, "##cullmode", &ctx.selected_face, ctx.face_str[:]) {
			log.infof("Cull mode: %s", ctx.face_str[ctx.selected_face])
			prepare_pipelines(ctx) or_return
		}
	}

	return true
}

draw :: proc(ctx: ^Context) -> (ok: bool) {
	ctx.cmd = wgpu.device_create_command_encoder(ctx.gpu.device) or_return
	defer wgpu.release(ctx.cmd)

	ctx.render_pass.color_attachments[0].view = ctx.frame.view
	render_pass := wgpu.command_encoder_begin_render_pass(ctx.cmd, ctx.render_pass.descriptor)
	defer wgpu.release(render_pass)

	wgpu.render_pass_set_pipeline(render_pass, ctx.render_pipeline)

	wgpu.render_pass_set_scissor_rect(
		render_pass,
		0,
		0,
		ctx.gpu.config.width,
		ctx.gpu.config.height,
	)

	/* Render the quad with clock wise and counter clock wise indices, visibility
     is determined by pipeline settings */
	wgpu.render_pass_set_bind_group(render_pass, 0, ctx.bind_group_cw)
	wgpu.render_pass_set_index_buffer(render_pass, {buffer = ctx.buffer_indices_cw}, .Uint32)
	wgpu.render_pass_set_vertex_buffer(render_pass, 0, {buffer = ctx.quad[ctx.selected_quad]})
	wgpu.render_pass_draw_indexed(render_pass, {0, 6})

	wgpu.render_pass_set_bind_group(render_pass, 0, ctx.bind_group_ccw)
	wgpu.render_pass_set_index_buffer(render_pass, {buffer = ctx.buffer_indices_ccw}, .Uint32)
	wgpu.render_pass_draw_indexed(render_pass, {0, 6})

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
	settings.size = {650, 650}

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
