package square

// Core
import "core:log"

// Local packages
import wgpu "../../"
import app "../../utils/application"

POSITIONS := [?]f32 {
    -0.5,  0.5, 0.0, // v0
     0.5,  0.5, 0.0, // v1
    -0.5, -0.5, 0.0, // v2
     0.5, -0.5, 0.0, // v3
}

COLORS := [?]f32 {
    1.0, 0.0, 0.0, 1.0, // v0
    0.0, 1.0, 0.0, 1.0, // v1
    0.0, 0.0, 1.0, 1.0, // v2
    1.0, 1.0, 0.0, 1.0, // v3
}

CLIENT_WIDTH  :: 640
CLIENT_HEIGHT :: 480
EXAMPLE_TITLE :: "Square"
VIDEO_MODE_DEFAULT :: app.Video_Mode {
	width  = CLIENT_WIDTH,
	height = CLIENT_HEIGHT,
}

Application :: struct {
	using _app:       app.Application, /* #subtype */
	positions_buffer: wgpu.Buffer,
	colors_buffer:    wgpu.Buffer,
	render_pipeline:  wgpu.RenderPipeline,
	rpass: struct {
		colors:     [1]wgpu.RenderPassColorAttachment,
		descriptor: wgpu.RenderPassDescriptor,
	},
}

create :: proc() -> (self: ^Application) {
	self = new(Application)
	assert(self != nil, "Failed to allocate Application")

	app.init(self, VIDEO_MODE_DEFAULT, EXAMPLE_TITLE)

	self.positions_buffer = wgpu.DeviceCreateBufferWithData(
		self.gpu.device,
		{
			label = "Positions buffer",
			contents = wgpu.ToBytes(POSITIONS),
			usage = {.Vertex, .CopyDst},
		},
	)

	self.colors_buffer = wgpu.DeviceCreateBufferWithData(
		self.gpu.device,
		{
			label = "Colors buffer",
			contents = wgpu.ToBytes(COLORS),
			usage = {.Vertex, .CopyDst},
		},
	)

	CUBE_WGSL :: #load("./square.wgsl")
	shader_module := wgpu.DeviceCreateShaderModule(
		self.gpu.device,
		{label = EXAMPLE_TITLE + " Module", source = string(CUBE_WGSL)},
	)
	defer wgpu.Release(shader_module)

	pipeline_descriptor := wgpu.RenderPipelineDescriptor {
		label = EXAMPLE_TITLE + " Render Pipeline",
		vertex = {
			module = shader_module,
			entryPoint = "vs_main",
			buffers = {
				{
					arrayStride = 3 * 4,
					stepMode = .Vertex,
					attributes = {{shaderLocation = 0, format = .Float32x3, offset = 0}},
				},
				{
					arrayStride = 4 * 4,
					stepMode = .Vertex,
					attributes = {{shaderLocation = 1, format = .Float32x4, offset = 0}},
				},
			},
		},
		fragment = &{
			module = shader_module,
			entryPoint = "fs_main",
			targets = {
				{
					format = self.gpu.config.format,
					blend = &wgpu.BLEND_STATE_NORMAL,
					writeMask = wgpu.COLOR_WRITES_ALL,
				},
			},
		},
		primitive = {
			topology = .TriangleStrip,
			stripIndexFormat = .Uint32,
			frontFace = .CCW,
			cullMode = .Front,
		},
		multisample = wgpu.MULTISAMPLE_STATE_DEFAULT,
	}

	self.render_pipeline = wgpu.DeviceCreateRenderPipeline(
		self.gpu.device,
		pipeline_descriptor,
	)

	self.rpass.colors[0] = {
		view = nil, /* Assigned later */
		ops  = {.Clear, .Store, app.Color_Black},
	}

	self.rpass.descriptor = {
		label             = "Render pass descriptor",
		colorAttachments = self.rpass.colors[:],
	}

	app.add_resize_callback(self, { resize, self })

	return
}

release :: proc(self: ^Application) {
	wgpu.Release(self.render_pipeline)
	wgpu.Release(self.colors_buffer)
	wgpu.Release(self.positions_buffer)

	app.release(self)
	free(self)
}

draw :: proc(self: ^Application) {
	frame := app.gpu_get_current_frame(self.gpu)
	if frame.skip { return }
	defer app.gpu_release_current_frame(&frame)

	encoder := wgpu.DeviceCreateCommandEncoder(self.gpu.device)
	defer wgpu.Release(encoder)

	self.rpass.colors[0].view = frame.view
	rpass := wgpu.CommandEncoderBeginRenderPass(encoder, self.rpass.descriptor)
	defer wgpu.Release(rpass)

	// Bind the rendering pipeline
	wgpu.RenderPassSetPipeline(rpass, self.render_pipeline)

	// Bind vertex buffers (contain position & colors)
	wgpu.RenderPassSetVertexBuffer(rpass, 0, {buffer = self.positions_buffer})
	wgpu.RenderPassSetVertexBuffer(rpass, 1, {buffer = self.colors_buffer})

	// Draw quad
	wgpu.RenderPassDraw(rpass, {0, 4})

	// End render pass
	wgpu.RenderPassEnd(rpass)

	cmdbuf := wgpu.CommandEncoderFinish(encoder)
	defer wgpu.Release(cmdbuf)

	wgpu.QueueSubmit(self.gpu.queue, { cmdbuf })
	wgpu.SurfacePresent(self.gpu.surface)
}

resize :: proc(window: ^app.Window, size: app.Vec2u, userdata: rawptr) {
	self := cast(^Application)userdata
	draw(self)
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
