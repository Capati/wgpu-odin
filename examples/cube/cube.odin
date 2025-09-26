package cube_example

// Core
import "core:log"

// Local packages
import wgpu "../../"
import app "../../utils/application"
import "../common"

CLIENT_WIDTH       :: 640
CLIENT_HEIGHT      :: 480
EXAMPLE_TITLE      :: "Colored Cube"
VIDEO_MODE_DEFAULT :: app.Video_Mode {
	width  = CLIENT_WIDTH,
	height = CLIENT_HEIGHT,
}
DEPTH_FORMAT       :: wgpu.TextureFormat.Depth24Plus

Application :: struct {
	using _app:      app.Application,
	vertex_buffer:   wgpu.Buffer,
	render_pipeline: wgpu.RenderPipeline,
	uniform_buffer:  wgpu.Buffer,
	bind_group:      wgpu.BindGroup,
	depth_view:      wgpu.TextureView,
	rpass: struct {
		colors:     [1]wgpu.RenderPassColorAttachment,
		descriptor: wgpu.RenderPassDescriptor,
	},
}

init :: proc(self: ^Application) -> (ok: bool) {
	CUBE_WGSL :: #load("./cube.wgsl", string)
	shader_module := wgpu.DeviceCreateShaderModule(
		self.gpu.device,
		{
			label = EXAMPLE_TITLE + " Module",
			source = CUBE_WGSL,
		},
	)
	defer wgpu.ShaderModuleRelease(shader_module)

	self.vertex_buffer = wgpu.DeviceCreateBufferWithData(
		self.gpu.device,
		{
			label = EXAMPLE_TITLE + " Buffer",
			contents = wgpu.ToBytes(vertex_data),
			usage = {.Vertex},
		},
	)

	vertex_attributes := wgpu.VertexAttrArray(2, {0, .Float32x3}, {1, .Float32x3})

	// Above line "expands" to:
	// vertex_attributes := [?]wgpu.VertexAttribute {
	// 	{format = .Float32x3, offset = 0, shaderLocation = 0},
	// 	{
	// 		format = .Float32x3,
	// 		offset = 12,
	// 		shaderLocation = 1,
	// 	},
	// }

	vertex_buffer_layout := wgpu.VertexBufferLayout {
		arrayStride = size_of(Vertex),
		stepMode    = .Vertex,
		attributes  = vertex_attributes[: ],
	}

	pipeline_descriptor := wgpu.RenderPipelineDescriptor {
		label = EXAMPLE_TITLE + " Render Pipeline",
		vertex = {
			module = shader_module,
			entryPoint = "vs_main",
			buffers = {vertex_buffer_layout},
		},
		fragment = &{
			module = shader_module,
			entryPoint = "fs_main",
			targets = {
				{
					format = self.gpu.config.format,
					blend = &wgpu.BLEND_STATE_REPLACE,
					writeMask = wgpu.COLOR_WRITES_ALL,
				},
			},
		},
		primitive = {
			topology = .TriangleList,
			frontFace = .CCW,
			cullMode = .Back,
		},
		// Enable depth testing so that the fragment closest to the camera
		// is rendered in front.
		depthStencil = {
			depthWriteEnabled = true,
			depthCompare = .Less,
			format = DEPTH_FORMAT,
			stencil = {
				front = {compare = .Always},
				back = {compare = .Always},
				readMask = 0xFFFFFFFF,
				writeMask = 0xFFFFFFFF,
			},
		},
		multisample = wgpu.MULTISAMPLE_STATE_DEFAULT,
	}

	self.render_pipeline = wgpu.DeviceCreateRenderPipeline(
		self.gpu.device,
		pipeline_descriptor,
	)

	aspect := f32(self.gpu.config.width) / f32(self.gpu.config.height)
	mvp_mat := common.create_view_projection_matrix(aspect)

	self.uniform_buffer = wgpu.DeviceCreateBufferWithData(
		self.gpu.device,
		{
			label = EXAMPLE_TITLE + " Uniform Buffer",
			contents = wgpu.ToBytes(mvp_mat),
			usage = {.Uniform, .CopyDst},
		},
	)

	bind_group_layout := wgpu.RenderPipelineGetBindGroupLayout(
		self.render_pipeline,
		groupIndex = 0,
	)
	defer wgpu.BindGroupLayoutRelease(bind_group_layout)

	self.bind_group = wgpu.DeviceCreateBindGroup(
		self.gpu.device,
		{
			layout = bind_group_layout,
			entries = {
				{
					binding = 0,
					resource = wgpu.BufferBinding {
						buffer = self.uniform_buffer,
						size = wgpu.BufferGetSize(self.uniform_buffer),
					},
				},
			},
		},
	)

	self.rpass.colors[0] = {
		view = nil, /* Assigned later */
		ops = {
			load = .Clear,
			store = .Store,
			clearValue = app.Color_Dark_Gray,
		},
	}

	self.rpass.descriptor = {
		label                  = "Render pass descriptor",
		colorAttachments       = self.rpass.colors[:],
		depthStencilAttachment = nil, /* Assigned later */
	}

	create_depth_framebuffer(self)

	return true
}

step :: proc(self: ^Application, dt: f32) -> (ok: bool) {
	frame := app.gpu_get_current_frame(self.gpu)
	if frame.skip { return }
	defer app.gpu_release_current_frame(&frame)

	encoder := wgpu.DeviceCreateCommandEncoder(self.gpu.device)
	defer wgpu.CommandEncoderRelease(encoder)

	self.rpass.colors[0].view = frame.view
	rpass := wgpu.CommandEncoderBeginRenderPass(encoder, self.rpass.descriptor)
	defer wgpu.RenderPassRelease(rpass)

	wgpu.RenderPassSetPipeline(rpass, self.render_pipeline)
	wgpu.RenderPassSetBindGroup(rpass, 0, self.bind_group)
	wgpu.RenderPassSetVertexBuffer(rpass, 0, {buffer = self.vertex_buffer})
	wgpu.RenderPassDraw(rpass, {0, u32(len(vertex_data))})

	wgpu.RenderPassEnd(rpass)

	cmdbuf := wgpu.CommandEncoderFinish(encoder)
	defer wgpu.CommandBufferRelease(cmdbuf)

	wgpu.QueueSubmit(self.gpu.queue, { cmdbuf })
	wgpu.SurfacePresent(self.gpu.surface)

	return true
}

event :: proc(self: ^Application, event: app.Event) -> (ok: bool) {
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
	wgpu.TextureViewRelease(self.depth_view)
	wgpu.BindGroupRelease(self.bind_group)
	wgpu.BufferRelease(self.uniform_buffer)
	wgpu.RenderPipelineRelease(self.render_pipeline)
	wgpu.BufferRelease(self.vertex_buffer)
}

create_depth_framebuffer :: proc(self: ^Application) {
	format_features := wgpu.TextureFormatGuaranteedFormatFeatures(DEPTH_FORMAT, self.gpu.features)

	size := app.window_get_size(self.window)

	texture_descriptor := wgpu.TextureDescriptor {
		size          = {size.x, size.y, 1},
		mipLevelCount = 1,
		sampleCount   = 1,
		dimension     = ._2D,
		format        = DEPTH_FORMAT,
		usage         = format_features.allowedUsages,
	}

	texture := wgpu.DeviceCreateTexture(self.gpu.device, texture_descriptor)
	defer wgpu.TextureRelease(texture)

	self.depth_view = wgpu.TextureCreateView(texture)

	// Setup depth stencil attachment
	self.rpass.descriptor.depthStencilAttachment = wgpu.RenderPassDepthStencilAttachment{
		view = self.depth_view,
		depthOps = wgpu.RenderPassDepthOperations{
			load       = .Clear,
			store      = .Store,
			clearValue = 1.0,
		},
	}
}

resize :: proc(self: ^Application, size: app.Vec2u) {
	wgpu.TextureViewRelease(self.depth_view)
	create_depth_framebuffer(self)

	// Update uniform buffer with new aspect ratio
	aspect := f32(size.x) / f32(size.y)
	new_matrix := common.create_view_projection_matrix(aspect)
	wgpu.QueueWriteBuffer(
		self.gpu.queue,
		self.uniform_buffer,
		0,
		wgpu.ToBytes(new_matrix),
	)
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
