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

init :: proc(self: ^Application) -> (ok: bool) {
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

	return true
}

step :: proc(self: ^Application, dt: f32) -> (ok: bool) {
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

	return true
}

event :: proc(self: ^Application, event: app.Event) -> (ok: bool) {
    #partial switch &ev in event {
        case app.Quit_Event:
            log.info("Exiting...")
            return
    }
    return true
}

quit :: proc(self: ^Application) {
	wgpu.Release(self.render_pipeline)
	wgpu.Release(self.colors_buffer)
	wgpu.Release(self.positions_buffer)
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
