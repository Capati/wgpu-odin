package stencil_triangles

// Core
import "core:log"
import la "core:math/linalg"

// Local packages
import wgpu "../.."
import app "../../utils/application"

CLIENT_WIDTH       :: 640
CLIENT_HEIGHT      :: 480
EXAMPLE_TITLE      :: "Stencil Triangles"
VIDEO_MODE_DEFAULT :: app.Video_Mode {
	width  = CLIENT_WIDTH,
	height = CLIENT_HEIGHT,
}
STENCIL_FORMAT     :: wgpu.TextureFormat.Stencil8

Application :: struct {
	using _app:          app.Application, /* #subtype */
	outer_vertex_buffer: wgpu.Buffer,
	mask_vertex_buffer:  wgpu.Buffer,
	outer_pipeline:      wgpu.RenderPipeline,
	mask_pipeline:       wgpu.RenderPipeline,
	stencil_buffer:      wgpu.Texture,
	depth_view:          wgpu.TextureView,
	depth_texture:       app.Depth_Stencil_Texture,
	rpass: struct {
		colors:     [1]wgpu.RenderPassColorAttachment,
		descriptor: wgpu.RenderPassDescriptor,
	},
}

Vertex :: struct {
	pos: la.Vector4f32,
}

vertex :: proc(x, y: f32) -> Vertex {
	return {pos = {x, y, 0.0, 1.0}}
}

create :: proc() -> (self: ^Application) {
	self = new(Application)
	assert(self != nil, "Failed to allocate Application")

	app.init(self, VIDEO_MODE_DEFAULT, EXAMPLE_TITLE)

	outer_vertices := []Vertex{vertex(-1.0, -1.0), vertex(1.0, -1.0), vertex(0.0, 1.0)}
	self.outer_vertex_buffer = wgpu.DeviceCreateBufferWithData(
		self.gpu.device,
		{
			label = "Outer Vertex Buffer",
			contents = wgpu.ToBytes(outer_vertices),
			usage = {.Vertex},
		},
	)

	mask_vertices := []Vertex{vertex(-0.5, 0.0), vertex(0.0, -1.0), vertex(0.5, 0.0)}
	self.mask_vertex_buffer = wgpu.DeviceCreateBufferWithData(
		self.gpu.device,
		{
			label = "Mask Vertex Buffer",
			contents = wgpu.ToBytes(mask_vertices),
			usage = {.Vertex},
		},
	)

	pipeline_layout := wgpu.DeviceCreatePipelineLayout(self.gpu.device, {})
	defer wgpu.Release(pipeline_layout)

	shader := wgpu.DeviceCreateShaderModule(
		self.gpu.device,
		{source = #load("./stencil_triangles.wgsl", string)},
	)
	defer wgpu.Release(shader)

	vertex_buffers := [1]wgpu.VertexBufferLayout {
		{
			arrayStride = size_of(Vertex),
			stepMode    = .Vertex,
			attributes  = {{format = .Float32x4, offset = 0, shaderLocation = 0}},
		},
	}

	descriptor := wgpu.RenderPipelineDescriptor {
		layout = pipeline_layout,
		vertex = {module = shader, entryPoint = "vs_main", buffers = vertex_buffers[:]},
		fragment = &{
			module = shader,
			entryPoint = "fs_main",
			targets = {
				{
					format = self.gpu.config.format,
					writeMask = wgpu.COLOR_WRITES_NONE,
				},
			},
		},
		primitive = wgpu.PRIMITIVE_STATE_DEFAULT,
		depthStencil = {
			format = STENCIL_FORMAT,
			depthWriteEnabled = false,
			depthCompare = .Always,
			stencil = {
				front = {
					compare = .Always,
					failOp = .Keep,
					depthFailOp = .Keep,
					passOp = .Replace,
				},
				back = wgpu.STENCIL_FACE_STATE_IGNORE,
				readMask = max(u32),
				writeMask = max(u32),
			},
		},
		multisample = wgpu.MULTISAMPLE_STATE_DEFAULT,
	}

	descriptor.label = "Mask Pipeline"

	self.mask_pipeline = wgpu.DeviceCreateRenderPipeline(self.gpu.device, descriptor)

	descriptor.label = "Outer Pipeline"
	descriptor.depthStencil.stencil.front = {
		compare = .Greater,
		passOp = .Keep,
	}
	descriptor.fragment.targets[0].writeMask = wgpu.COLOR_WRITES_ALL

	self.outer_pipeline = wgpu.DeviceCreateRenderPipeline(self.gpu.device, descriptor)

	self.rpass.colors[0] = {
		view = nil, /* Assigned later */
		ops  = {load = .Clear, store = .Store, clearValue = {0.1, 0.2, 0.3, 1.0}},
	}

	self.rpass.descriptor = {
		label                  = "Render pass descriptor",
		colorAttachments       = self.rpass.colors[:],
		depthStencilAttachment = nil, /* assigned later */
	}

	create_stencil_buffer(self)

	app.add_resize_callback(self, { resize, self })

	return
}

release :: proc(self: ^Application) {
	destroy_stencil_buffer(self)

	wgpu.Release(self.outer_pipeline)
	wgpu.Release(self.mask_pipeline)
	wgpu.Release(self.mask_vertex_buffer)
	wgpu.Release(self.outer_vertex_buffer)

	app.release(self)
	free(self)
}

draw :: proc(self: ^Application) {
	gpu := self.gpu

	frame := app.gpu_get_current_frame(gpu)
	if frame.skip { return }
	defer app.gpu_release_current_frame(&frame)

	encoder := wgpu.DeviceCreateCommandEncoder(gpu.device)
	defer wgpu.Release(encoder)

	self.rpass.colors[0].view = frame.view
	rpass := wgpu.CommandEncoderBeginRenderPass(encoder, self.rpass.descriptor)
	defer wgpu.Release(rpass)

	wgpu.RenderPassSetStencilReference(rpass, 1)

	wgpu.RenderPassSetPipeline(rpass, self.mask_pipeline)
	wgpu.RenderPassSetVertexBuffer(rpass, 0, {buffer = self.mask_vertex_buffer})
	wgpu.RenderPassDraw(rpass, {0, 3})

	wgpu.RenderPassSetPipeline(rpass, self.outer_pipeline)
	wgpu.RenderPassSetVertexBuffer(rpass, 0, {buffer = self.outer_vertex_buffer})
	wgpu.RenderPassDraw(rpass, {0, 3})

	wgpu.RenderPassEnd(rpass)

	cmdbuf := wgpu.CommandEncoderFinish(encoder)
	defer wgpu.Release(cmdbuf)

	wgpu.QueueSubmit(self.gpu.queue, { cmdbuf })
	wgpu.SurfacePresent(self.gpu.surface)
}

resize :: proc(window: ^app.Window, size: app.Vec2u, userdata: rawptr) {
	self := cast(^Application)userdata
	recreate_stencil_buffer(self)
	draw(self)
}

create_stencil_buffer :: proc(self: ^Application) {
	self.stencil_buffer = wgpu.DeviceCreateTexture(
		self.gpu.device,
		{
			label = "Stencil buffer",
			size = {
				width              = self.gpu.config.width,
				height             = self.gpu.config.height,
				depthOrArrayLayers = 1,
			},
			mipLevelCount = 1,
			sampleCount   = 1,
			dimension     = ._2D,
			format        = STENCIL_FORMAT,
			usage         = {.RenderAttachment},
		},
	)

	texture_view_descriptor := wgpu.TextureViewDescriptor {
		format          = STENCIL_FORMAT,
		dimension       = ._2D,
		baseMipLevel    = 0,
		mipLevelCount   = 1,
		baseArrayLayer  = 0,
		arrayLayerCount = 1,
		aspect          = .All,
	}

	self.depth_view = wgpu.TextureCreateView(
		self.stencil_buffer,
		texture_view_descriptor,
	)

	self.rpass.descriptor.depthStencilAttachment = wgpu.RenderPassDepthStencilAttachment{
		view = self.depth_view,
		depthOps = wgpu.RenderPassDepthOperations{
			clearValue = 1.0,
		},
		stencilOps = wgpu.RenderPassStencilOperations{
			load       = .Clear,
			store      = .Store,
			clearValue = 0.0,
		},
	}
}

destroy_stencil_buffer :: proc(self: ^Application) {
	if self.stencil_buffer != nil {
		wgpu.Release(self.stencil_buffer)
	}

	if self.depth_view != nil {
		wgpu.Release(self.depth_view)
	}
}

recreate_stencil_buffer :: proc(self: ^Application) {
	destroy_stencil_buffer(self)
	create_stencil_buffer(self)
}

main :: proc() {
	when ODIN_DEBUG {
		context.logger = log.create_console_logger(opt = {.Level, .Terminal_Color})
		defer log.destroy_console_logger(context.logger)
	}

	example := create()
	defer release(example)

	running := true
	MAIN_LOOP: for running {
		event: app.Event
		for app.poll_event(example, &event) {
			#partial switch &ev in event {
			case app.QuitEvent:
				log.info("Exiting...")
				running = false
			}
		}

		app.begin_frame(example)
		draw(example)
		app.end_frame(example)
	}
}
