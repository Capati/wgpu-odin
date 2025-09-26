package coordinate_system

// Core
import "core:log"

// Vendor
import mu "vendor:microui"

// Local packages
import wgpu "../../"
import wgpu_mu "../../utils/microui"
import app "../../utils/application"

CLIENT_WIDTH       :: 650
CLIENT_HEIGHT      :: 650
EXAMPLE_TITLE      :: "Coordinate System"
VIDEO_MODE_DEFAULT :: app.Video_Mode {
	width  = CLIENT_WIDTH,
	height = CLIENT_HEIGHT,
}
VERTICES_Y_UP      :: 0
VERTICES_Y_DOWN    :: 1

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

Application :: struct {
	using _app:         app.Application, /* #subtype */
	mu_ctx:             ^mu.Context,
	texture_cw:         app.Texture,
	texture_ccw:        app.Texture,
	buffer_indices_ccw: wgpu.Buffer,
	buffer_indices_cw:  wgpu.Buffer,
	bind_group_ccw:     wgpu.BindGroup,
	bind_group_cw:      wgpu.BindGroup,
	pipeline_layout:    wgpu.PipelineLayout,
	shader_module:      wgpu.ShaderModule,
	render_pipeline:    wgpu.RenderPipeline,
	depth_texture:      app.Depth_Stencil_Texture,
	rpass:        struct {
		colors:     [1]wgpu.RenderPassColorAttachment,
		descriptor: wgpu.RenderPassDescriptor,
	},

	// Settings
	selected_quad:  Quad_Type,
	quads:          [Quad_Type]wgpu.Buffer,
	quad_types:     [len(Quad_Type)]app.Combobox_Item(Quad_Type),
	selected_order: Front_Face,
	order_types:    [len(Front_Face)]app.Combobox_Item(Front_Face),
	selected_face:  Face,
	face_types:     [len(Face)]app.Combobox_Item(Face),
}

Vertex :: struct {
	pos: app.Vec3,
	uv:  app.Vec2,
}

init :: proc(self: ^Application) -> (ok: bool) {
	microui_init_info := wgpu_mu.MICROUI_INIT_INFO_DEFAULT
	microui_init_info.surface_config = self.gpu.config
	// This example uses depth stencil created by the application framework
	// The microui renderer will use the same default depth format
	microui_init_info.depth_stencil_format = app.DEFAULT_DEPTH_FORMAT

	self.mu_ctx = new(mu.Context)

	mu.init(self.mu_ctx)
	self.mu_ctx.text_width = mu.default_atlas_text_width
	self.mu_ctx.text_height = mu.default_atlas_text_height

	// Initialize MicroUI context with the given info
	wgpu_mu.init(microui_init_info)

	self.texture_cw = app.create_texture_from_file(self,
		"./assets/textures/texture_orientation_cw_rgba.png")

	self.texture_ccw = app.create_texture_from_file(self,
		"./assets/textures/texture_orientation_ccw_rgba.png")

	aspect := f32(self.gpu.config.width) / f32(self.gpu.config.height)

	vertices_y_pos := [4]Vertex {
		{pos = {-1.0 * aspect, -1.0, 1.0}, uv = {0.0, 1.0}},
		{pos = {-1.0 * aspect,  1.0, 1.0}, uv = {0.0, 0.0}},
		{pos = { 1.0 * aspect,  1.0, 1.0}, uv = {1.0, 0.0}},
		{pos = { 1.0 * aspect, -1.0, 1.0}, uv = {1.0, 1.0}},
	}

	self.quads[.Vertices_Y_Up] = wgpu.DeviceCreateBufferWithData(
		self.gpu.device,
		{
			label = "Vertices buffer - Y up",
			contents = wgpu.ToBytes(vertices_y_pos[:]),
			usage = {.CopyDst, .Vertex},
		},
	)

	vertices_y_neg := [4]Vertex {
		{pos = {-1.0 * aspect,  1.0, 1.0}, uv = {0.0, 1.0}},
		{pos = {-1.0 * aspect, -1.0, 1.0}, uv = {0.0, 0.0}},
		{pos = { 1.0 * aspect, -1.0, 1.0}, uv = {1.0, 0.0}},
		{pos = { 1.0 * aspect,  1.0, 1.0}, uv = {1.0, 1.0}},
	}

	self.quads[.Vertices_Y_Down] = wgpu.DeviceCreateBufferWithData(
		self.gpu.device,
		{
			label = "Vertices buffer - Y down",
			contents = wgpu.ToBytes(vertices_y_neg[:]),
			usage = {.CopyDst, .Vertex},
		},
	)

	indices_ccw := [6]u32  {
		2, 1, 0,
		0, 3, 2,
	}

	self.buffer_indices_ccw = wgpu.DeviceCreateBufferWithData(
		self.gpu.device,
		{
			label = "Indices buffer - CCW",
			contents = wgpu.ToBytes(indices_ccw[:]),
			usage = {.CopyDst, .Index},
		},
	)

	indices_cw := [6]u32  {
		0, 1, 2,
		2, 3, 0,
	}

	self.buffer_indices_cw = wgpu.DeviceCreateBufferWithData(
		self.gpu.device,
		{
			label = "Indices buffer - CW",
			contents = wgpu.ToBytes(indices_cw[:]),
			usage = {.CopyDst, .Index},
		},
	)

	bind_group_layout := wgpu.DeviceCreateBindGroupLayout(
		self.gpu.device,
		wgpu.BindGroupLayoutDescriptor {
			label = "Bind group layout",
			entries = {
				{
					binding = 0,
					visibility = {.Fragment},
					type = wgpu.TextureBindingLayout {
						sampleType = .Float,
						viewDimension = ._2D,
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
	)
	defer wgpu.Release(bind_group_layout)

	self.pipeline_layout = wgpu.DeviceCreatePipelineLayout(
		self.gpu.device,
		{label = "Pipeline layout", bindGroupLayouts = {bind_group_layout}},
	)

	self.bind_group_cw = wgpu.DeviceCreateBindGroup(
		self.gpu.device,
		{
			label = "Bind Group CW",
			layout = bind_group_layout,
			entries = {
				{binding = 0, resource = self.texture_cw.view},
				{binding = 1, resource = self.texture_cw.sampler},
			},
		},
	)

	self.bind_group_ccw = wgpu.DeviceCreateBindGroup(
		self.gpu.device,
		{
			label = "Bind Group CCW",
			layout = bind_group_layout,
			entries = {
				{binding = 0, resource = self.texture_ccw.view},
				{binding = 1, resource = self.texture_ccw.sampler},
			},
		},
	)

	COORDINATE_SYSTEM_WGSL :: #load("./coordinate_system.wgsl", string)
	self.shader_module = wgpu.DeviceCreateShaderModule(
		self.gpu.device,
		{label = EXAMPLE_TITLE + " Module", source = COORDINATE_SYSTEM_WGSL},
	)

	prepare_pipelines(self)

	self.rpass.colors[0] = {
		view = nil, /* Assigned later */
		ops  = {.Clear, .Store, {0.0, 0.0, 0.0, 1.0}},
	}

	self.rpass.descriptor = {
		label                  = "Render pass descriptor",
		colorAttachments       = self.rpass.colors[:],
		depthStencilAttachment = nil, /* Assigned later */
	}

	create_depth_stencil_texture(self)

	self.selected_quad = .Vertices_Y_Up
	self.quad_types = {
		{.Vertices_Y_Up, "WebGPU (Y positive)"},
		{.Vertices_Y_Down, "VK (Y negative)"},
	}

	self.selected_order = .CCW
	self.order_types = {{.CCW, "CCW"}, {.CW, "CW"}}

	self.selected_face = .Back
	self.face_types = {{.None, "None"}, {.Front, "Front"}, {.Back, "Back"}}

	return true
}

step :: proc(self: ^Application, dt: f32) -> (ok: bool) {
	microui_update(self)

	frame := app.gpu_get_current_frame(self.gpu)
	if frame.skip { return }
	defer app.gpu_release_current_frame(&frame)

	encoder := wgpu.DeviceCreateCommandEncoder(self.gpu.device)
	defer wgpu.Release(encoder)

	self.rpass.colors[0].view = frame.view
	rpass := wgpu.CommandEncoderBeginRenderPass(encoder, self.rpass.descriptor)
	defer wgpu.Release(rpass)

	wgpu.RenderPassSetPipeline(rpass, self.render_pipeline)

	surface_width := self.gpu.config.width
	surface_height := self.gpu.config.height

	wgpu.RenderPassSetScissorRect(rpass, 0, 0, surface_width, surface_height)

	/* Render the quad with clock wise and counter clock wise indices, visibility
     is determined by pipeline settings */
	wgpu.RenderPassSetBindGroup(rpass, 0, self.bind_group_cw)
	wgpu.RenderPassSetIndexBuffer(rpass, {buffer = self.buffer_indices_cw}, .Uint32)
	wgpu.RenderPassSetVertexBuffer(rpass, 0, {buffer = self.quads[self.selected_quad]})
	wgpu.RenderPassDrawIndexed(rpass, {0, 6})

	wgpu.RenderPassSetBindGroup(rpass, 0, self.bind_group_ccw)
	wgpu.RenderPassSetIndexBuffer(rpass, {buffer = self.buffer_indices_ccw}, .Uint32)
	wgpu.RenderPassDrawIndexed(rpass, {0, 6})

	wgpu_mu.render(self.mu_ctx, rpass)

	wgpu.RenderPassEnd(rpass)

	cmdbuf := wgpu.CommandEncoderFinish(encoder)
	defer wgpu.Release(cmdbuf)

	wgpu.QueueSubmit(self.gpu.queue, { cmdbuf })
	wgpu.SurfacePresent(self.gpu.surface)

	return true
}

event :: proc(self: ^Application, event: app.Event) -> (ok: bool) {
	app.mu_handle_events(self.mu_ctx, event)
    #partial switch &ev in event {
        case app.Quit_Event:
            log.info("Exiting...")
            return
		case app.Resize_Event:
			resize(self, ev.size)
    }
    return true
}

quit :: proc(self: ^Application) {
	app.gpu_release_depth_stencil_texture(self.depth_texture)

	wgpu.Release(self.render_pipeline)
	wgpu.Release(self.pipeline_layout)
	wgpu.Release(self.shader_module)

	wgpu.Release(self.bind_group_ccw)
	wgpu.Release(self.bind_group_cw)

	wgpu.Release(self.buffer_indices_ccw)
	wgpu.Release(self.buffer_indices_cw)
	wgpu.Release(self.quads[.Vertices_Y_Up])
	wgpu.Release(self.quads[.Vertices_Y_Down])

	app.texture_release(self.texture_ccw)
	app.texture_release(self.texture_cw)

	wgpu_mu.destroy()
	free(self.mu_ctx)
}

resize :: proc(self: ^Application, size: app.Vec2u) {
	recreate_depth_stencil_texture(self)
	wgpu_mu.resize(size.x, size.y)
}

create_depth_stencil_texture :: proc(self: ^Application) {
	self.depth_texture = app.gpu_create_depth_stencil_texture(self.gpu)
	self.rpass.descriptor.depthStencilAttachment = self.depth_texture.descriptor
}

recreate_depth_stencil_texture :: proc(self: ^Application) {
	app.gpu_release_depth_stencil_texture(self.depth_texture)
	create_depth_stencil_texture(self)
}

prepare_pipelines :: proc(self: ^Application) {
	if self.render_pipeline != nil {
		wgpu.RenderPipelineRelease(self.render_pipeline)
	}

	self.render_pipeline = wgpu.DeviceCreateRenderPipeline(
		self.gpu.device,
		{
			label = "Render Pipeline",
			layout = self.pipeline_layout,
			vertex = {
				module = self.shader_module,
				entryPoint = "vs_main",
				buffers = {
					{
						arrayStride = size_of(Vertex),
						stepMode = .Vertex,
						attributes = {
							{format = .Float32x3, offset = 0, shaderLocation = 0},
							{
								format = .Float32x2,
								offset = u64(offset_of(Vertex, uv)),
								shaderLocation = 1,
							},
						},
					},
				},
			},
			fragment = &{
				module = self.shader_module,
				entryPoint = "fs_main",
				targets = {
					{
						format = self.gpu.config.format,
						blend = &wgpu.BLEND_STATE_NORMAL,
						writeMask = wgpu.COLOR_WRITES_ALL,
					},
				},
			},
			depthStencil = app.gpu_create_depth_stencil_state(self),
			primitive = {
				topology = .TriangleList,
				frontFace = wgpu.FrontFace(self.selected_order),
				cullMode = wgpu.Face(self.selected_face),
			},
			multisample = {count = 1, mask = max(u32)},
		},
	)
}

microui_update :: proc(self: ^Application) {
	mu.begin(self.mu_ctx)
	if mu.begin_window(self.mu_ctx, "Settings", {40, 75, 230, 200}, {.NO_CLOSE, .NO_RESIZE}) {
		defer mu.end_window(self.mu_ctx)

		mu.layout_row(self.mu_ctx, {-1})
		mu.label(self.mu_ctx, "Quad Type:")
		mu.layout_row(self.mu_ctx, {-1})
		if .CHANGE in
		   app.mu_combobox(self.mu_ctx, "##quadtype", &self.selected_quad, self.quad_types[:]) {
			log.infof("Quad type: %s", self.selected_quad)
		}

		mu.layout_row(self.mu_ctx, {-1, -1})
		mu.label(self.mu_ctx, "Winding Order:")
		mu.layout_row(self.mu_ctx, {-1})
		if .CHANGE in
		   app.mu_combobox(
			   self.mu_ctx,
			   "##windingorder",
			   &self.selected_order,
			   self.order_types[:],
		   ) {
			log.infof("Winding order: %s", self.selected_order)
			prepare_pipelines(self)
		}

		mu.layout_row(self.mu_ctx, {-1, -1})
		mu.label(self.mu_ctx, "Cull Mode:")
		mu.layout_row(self.mu_ctx, {-1})
		if .CHANGE in
		   app.mu_combobox(self.mu_ctx, "##cullmode", &self.selected_face, self.face_types[:]) {
			log.infof("Cull mode: %s", self.selected_face)
			prepare_pipelines(self)
		}
	}
	mu.end(self.mu_ctx)
}

main :: proc() {
    when ODIN_DEBUG {
        context.logger = log.create_console_logger(opt = {.Level, .Terminal_Color})
        defer log.destroy_console_logger(context.logger)
    }

    callbacks := app.Application_Callbacks{
        init  = app.App_Init_Callback(init),
        step  = app.App_Step_Callback(step),
        event = app.App_Event_Callback(event),
        quit  = app.App_Quit_Callback(quit),
    }

    app.init(Application, VIDEO_MODE_DEFAULT, EXAMPLE_TITLE, callbacks)
}
