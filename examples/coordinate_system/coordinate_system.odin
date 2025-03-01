package coordinate_system

// Packages
import "core:log"
import mu "vendor:microui"

// Local packages
import app "root:utils/application"
import "root:wgpu"

EXAMPLE_TITLE :: "Coordinate System"

VERTICES_Y_UP :: 0
VERTICES_Y_DOWN :: 1

Quad_Type :: enum i32 {
	Vertices_Y_Up,
	Vertices_Y_Down,
}

Front_Face :: enum i32 {
	CCW = 1,
	CW  = 2,
}

Face :: enum i32 {
	None  = 1,
	Front = 2,
	Back  = 3,
}

Example :: struct {
	texture_cw:         app.Texture,
	texture_ccw:        app.Texture,
	buffer_indices_ccw: wgpu.Buffer,
	buffer_indices_cw:  wgpu.Buffer,
	bind_group_ccw:     wgpu.Bind_Group,
	bind_group_cw:      wgpu.Bind_Group,
	pipeline_layout:    wgpu.Pipeline_Layout,
	shader_module:      wgpu.Shader_Module,
	render_pipeline:    wgpu.Render_Pipeline,
	render_pass:        struct {
		color_attachments: [1]wgpu.Render_Pass_Color_Attachment,
		descriptor:        wgpu.Render_Pass_Descriptor,
	},

	// Settings
	selected_quad:      Quad_Type,
	quads:              [Quad_Type]wgpu.Buffer,
	quad_types:         [len(Quad_Type)]app.Combobox_Item(Quad_Type),
	selected_order:     Front_Face,
	order_types:        [len(Front_Face)]app.Combobox_Item(Front_Face),
	selected_face:      Face,
	face_types:         [len(Face)]app.Combobox_Item(Face),
}

Vertex :: struct {
	pos: app.Vec3,
	uv:  app.Vec2,
}

Context :: app.Context(Example)

init :: proc(ctx: ^Context) -> (ok: bool) {
	microui_init_info := app.DEFAULT_MICROUI_INIT_INFO
	// This example uses depth stencil created by the application framework
	// The microui renderer will use the same default depth format
	microui_init_info.depth_stencil_format = app.DEFAULT_DEPTH_FORMAT
	// Initialize MicroUI context with the given info
	app.microui_init(ctx, microui_init_info) or_return

	ctx.texture_cw = app.create_texture_from_file(
		ctx,
		"./assets/textures/texture_orientation_cw_rgba.png",
	) or_return
	defer if !ok {
		app.texture_release(ctx.texture_cw)
	}

	ctx.texture_ccw = app.create_texture_from_file(
		ctx,
		"./assets/textures/texture_orientation_ccw_rgba.png",
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

	ctx.quads[.Vertices_Y_Up] = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{
			label = "Vertices buffer - Y up",
			contents = wgpu.to_bytes(vertices_y_pos[:]),
			usage = {.Copy_Dst, .Vertex},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.quads[.Vertices_Y_Up])
	}

	// odinfmt: disable
	vertices_y_neg := [4]Vertex {
		{pos = {-1.0 * aspect,  1.0, 1.0}, uv = {0.0, 1.0}},
		{pos = {-1.0 * aspect, -1.0, 1.0}, uv = {0.0, 0.0}},
		{pos = { 1.0 * aspect, -1.0, 1.0}, uv = {1.0, 0.0}},
		{pos = { 1.0 * aspect,  1.0, 1.0}, uv = {1.0, 1.0}},
	}
	// odinfmt: enable

	ctx.quads[.Vertices_Y_Down] = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{
			label = "Vertices buffer - Y down",
			contents = wgpu.to_bytes(vertices_y_neg[:]),
			usage = {.Copy_Dst, .Vertex},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.quads[.Vertices_Y_Down])
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
			usage = {.Copy_Dst, .Index},
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
			usage = {.Copy_Dst, .Index},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.buffer_indices_cw)
	}

	bind_group_layout := wgpu.device_create_bind_group_layout(
		ctx.gpu.device,
		wgpu.Bind_Group_Layout_Descriptor {
			label = "Bind group layout",
			entries = {
				{
					binding = 0,
					visibility = {.Fragment},
					type = wgpu.Texture_Binding_Layout {
						sample_type = .Float,
						view_dimension = .D2,
						multisampled = false,
					},
				},
				{
					binding = 1,
					visibility = {.Fragment},
					type = wgpu.Sampler_Binding_Layout{type = .Filtering},
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

	ctx.selected_quad = .Vertices_Y_Up
	ctx.quad_types = {
		{.Vertices_Y_Up, "WebGPU (Y positive)"},
		{.Vertices_Y_Down, "VK (Y negative)"},
	}

	ctx.selected_order = .CCW
	ctx.order_types = {{.CCW, "CCW"}, {.CW, "CW"}}

	ctx.selected_face = .Back
	ctx.face_types = {{.None, "None"}, {.Front, "Front"}, {.Back, "Back"}}

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
				topology = .Triangle_List,
				front_face = wgpu.Front_Face(ctx.selected_order),
				cull_mode = wgpu.Face(ctx.selected_face),
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
	wgpu.release(ctx.quads[.Vertices_Y_Up])
	wgpu.release(ctx.quads[.Vertices_Y_Down])

	app.texture_release(ctx.texture_ccw)
	app.texture_release(ctx.texture_cw)
}

microui_update :: proc(ctx: ^Context, mu_ctx: ^mu.Context) -> (ok: bool) {
	if mu.begin_window(mu_ctx, "Settings", {40, 75, 230, 200}, {.NO_CLOSE, .NO_RESIZE}) {
		defer mu.end_window(mu_ctx)

		mu.layout_row(mu_ctx, {-1})
		mu.label(mu_ctx, "Quad Type:")
		mu.layout_row(mu_ctx, {-1})
		if .CHANGE in
		   app.microui_combobox(mu_ctx, "##quadtype", &ctx.selected_quad, ctx.quad_types[:]) {
			log.infof("Quad type: %s", ctx.selected_quad)
		}

		mu.layout_row(mu_ctx, {-1, -1})
		mu.label(mu_ctx, "Winding Order:")
		mu.layout_row(mu_ctx, {-1})
		if .CHANGE in
		   app.microui_combobox(
			   mu_ctx,
			   "##windingorder",
			   &ctx.selected_order,
			   ctx.order_types[:],
		   ) {
			log.infof("Winding order: %s", ctx.selected_order)
			prepare_pipelines(ctx) or_return
		}

		mu.layout_row(mu_ctx, {-1, -1})
		mu.label(mu_ctx, "Cull Mode:")
		mu.layout_row(mu_ctx, {-1})
		if .CHANGE in
		   app.microui_combobox(mu_ctx, "##cullmode", &ctx.selected_face, ctx.face_types[:]) {
			log.infof("Cull mode: %s", ctx.selected_face)
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
	wgpu.render_pass_set_vertex_buffer(render_pass, 0, {buffer = ctx.quads[ctx.selected_quad]})
	wgpu.render_pass_draw_indexed(render_pass, {0, 6})

	wgpu.render_pass_set_bind_group(render_pass, 0, ctx.bind_group_ccw)
	wgpu.render_pass_set_index_buffer(render_pass, {buffer = ctx.buffer_indices_ccw}, .Uint32)
	wgpu.render_pass_draw_indexed(render_pass, {0, 6})

	app.microui_draw(ctx, render_pass) or_return

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
	settings.size = {650, 650}

	example, ok := app.create(Context, settings)
	if !ok {
		log.fatalf("Failed to create example [%s]", EXAMPLE_TITLE)
		return
	}
	defer app.destroy(example)

	example.callbacks = {
		init           = init,
		quit           = quit,
		microui_update = microui_update,
		draw           = draw,
	}

	app.run(example)
}
