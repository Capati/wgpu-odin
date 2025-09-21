package tutorial3_pipeline

// Core
import "core:log"

// Local Packages
import wgpu "../../../../" /* root folder */
import app "../../../../utils/application"

CLIENT_WIDTH  :: 640
CLIENT_HEIGHT :: 480
EXAMPLE_TITLE :: "Tutorial 3 - Pipeline"

Application :: struct {
	using _app:      app.Application, /* #subtype */
	render_pipeline: wgpu.RenderPipeline,
	rpass:struct {
		colors:     [1]wgpu.RenderPassColorAttachment,
		descriptor: wgpu.RenderPassDescriptor,
	},
}

create :: proc() -> (self: ^Application) {
	self = new(Application)
	assert(self != nil, "Failed to allocate Application")

	app.init(self,
		mode = {
			width = CLIENT_WIDTH,
			height = CLIENT_HEIGHT,
		},
		title = EXAMPLE_TITLE,
		settings = app.SETTINGS_DEFAULT)

	SHADER_WGSL :: #load("./shader.wgsl", string)
	shader_module := wgpu.DeviceCreateShaderModule(
		self.gpu.device,
		{source = SHADER_WGSL},
	)
	defer wgpu.Release(shader_module)

	render_pipeline_layout := wgpu.DeviceCreatePipelineLayout(
		self.gpu.device,
		{label = EXAMPLE_TITLE + " Layout"},
	)
	defer wgpu.Release(render_pipeline_layout)

	render_pipeline_descriptor := wgpu.RenderPipelineDescriptor {
		label = EXAMPLE_TITLE + " Render Pipeline",
		layout = render_pipeline_layout,
		vertex = {module = shader_module, entryPoint = "vs_main"},
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
	wgpu.Release(self.render_pipeline)

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

	wgpu.RenderPassSetPipeline(rpass, self.render_pipeline)
	wgpu.RenderPassDraw(rpass, {0, 3})

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
