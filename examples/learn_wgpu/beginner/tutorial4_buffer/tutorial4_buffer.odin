package tutorial4_buffer

// Core
import "core:log"

// Local Packages
import wgpu "../../../../" /* root folder */
import app "../../../../utils/application"

CLIENT_WIDTH       :: 640
CLIENT_HEIGHT      :: 480
EXAMPLE_TITLE      :: "Tutorial 4 - Buffers"
VIDEO_MODE_DEFAULT :: app.Video_Mode {
	width  = CLIENT_WIDTH,
	height = CLIENT_HEIGHT,
}

Vertex :: struct {
	position: [3]f32,
	color:    [3]f32,
}

Application :: struct {
	using _app:      app.Application, /* #subtype */
	render_pipeline: wgpu.RenderPipeline,
	vertex_buffer:   wgpu.Buffer,
	index_buffer:    wgpu.Buffer,
	num_indices:     u32,
	rpass: struct {
		colors:     [1]wgpu.RenderPassColorAttachment,
		descriptor: wgpu.RenderPassDescriptor,
	},
}

create :: proc() -> (self: ^Application) {
	self = new(Application)
	assert(self != nil, "Failed to allocate Application")

	app.init(self, VIDEO_MODE_DEFAULT, EXAMPLE_TITLE)

	SHADER_WGSL :: #load("./shader.wgsl", string)
	shader_module := wgpu.DeviceCreateShaderModule(
		self.gpu.device,
		{source = SHADER_WGSL},
	)
	defer wgpu.Release(shader_module)

	render_pipeline_layout := wgpu.DeviceCreatePipelineLayout(
		self.gpu.device,
		{label = EXAMPLE_TITLE + " Render Pipeline Layout"},
	)
	defer wgpu.Release(render_pipeline_layout)

	vertex_buffer_layout := wgpu.VertexBufferLayout {
		arrayStride = size_of(Vertex),
		stepMode    = .Vertex,
		attributes   = {
			{offset = 0, shaderLocation = 0, format = .Float32x3},
			{offset = cast(u64)offset_of(Vertex, color), shaderLocation = 1, format = .Float32x3},
		},
	}

	render_pipeline_descriptor := wgpu.RenderPipelineDescriptor {
		label = EXAMPLE_TITLE + "  Render Pipeline",
		layout = render_pipeline_layout,
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
		primitive = {topology = .TriangleList, frontFace = .CCW, cullMode = .Back},
		multisample = {count = 1, mask = ~u32(0), alphaToCoverageEnabled = false},
	}

	self.render_pipeline = wgpu.DeviceCreateRenderPipeline(
		self.gpu.device,
		render_pipeline_descriptor,
	)

	// vertices := []Vertex{
	//     {position = {0.0, 0.5, 0.0}, color = {1.0, 0.0, 0.0}},
	//     {position = {-0.5, -0.5, 0.0}, color = {0.0, 1.0, 0.0}},
	//     {position = {0.5, -0.5, 0.0}, color = {0.0, 0.0, 1.0}},
	// }

	vertices := []Vertex {
		{position = {-0.0868241, 0.49240386, 0.0}, color = {0.5, 0.0, 0.5}}, // A
		{position = {-0.49513406, 0.06958647, 0.0}, color = {0.5, 0.0, 0.5}}, // B
		{position = {-0.21918549, -0.44939706, 0.0}, color = {0.5, 0.0, 0.5}}, // C
		{position = {0.35966998, -0.3473291, 0.0}, color = {0.5, 0.0, 0.5}}, // D
		{position = {0.44147372, 0.2347359, 0.0}, color = {0.5, 0.0, 0.5}}, // E
	}

	indices: []u16 = {0, 1, 4, 1, 2, 4, 2, 3, 4}

	// num_vertices = cast(u32)len(vertices)
	self.num_indices = cast(u32)len(indices)

	self.vertex_buffer = wgpu.DeviceCreateBufferWithData(
		self.gpu.device,
		wgpu.BufferDataDescriptor {
			label = EXAMPLE_TITLE + " Vertex Buffer",
			contents = wgpu.ToBytes(vertices),
			usage = {.Vertex},
		},
	)

	self.index_buffer = wgpu.DeviceCreateBufferWithData(
		self.gpu.device,
		wgpu.BufferDataDescriptor {
			label = EXAMPLE_TITLE + " Index Buffer",
			contents = wgpu.ToBytes(indices),
			usage = {.Index},
		},
	)

	self.rpass.colors[0] = {
		view = nil, /* Assigned later */
		ops  = {.Clear, .Store, {0.1, 0.2, 0.3, 1.0}},
	}

	self.rpass.descriptor = {
		label            = "Render pass descriptor",
		colorAttachments = self.rpass.colors[:],
	}

	return
}

release :: proc(self: ^Application) {
	wgpu.Release(self.index_buffer)
	wgpu.Release(self.vertex_buffer)
	wgpu.Release(self.render_pipeline)

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

	wgpu.RenderPassSetPipeline(rpass, self.render_pipeline)
	wgpu.RenderPassSetVertexBuffer(rpass, 0, {buffer = self.vertex_buffer})
	wgpu.RenderPassSetIndexBuffer(rpass, {buffer = self.index_buffer}, .Uint16)
	wgpu.RenderPassDrawIndexed(rpass, {0, self.num_indices})

	wgpu.RenderPassEnd(rpass)

	cmdbuf := wgpu.CommandEncoderFinish(encoder)
	defer wgpu.Release(cmdbuf)

	wgpu.QueueSubmit(self.gpu.queue, { cmdbuf })
	wgpu.SurfacePresent(self.gpu.surface)
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
