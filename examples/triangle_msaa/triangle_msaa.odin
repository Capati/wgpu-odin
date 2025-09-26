package triangle_msaa

// Core
import "core:log"

// Local packages
import wgpu "../.."
import app "../../utils/application"

CLIENT_WIDTH       :: 640
CLIENT_HEIGHT      :: 480
EXAMPLE_TITLE      :: "Triangle 4x MSAA"
VIDEO_MODE_DEFAULT :: app.Video_Mode {
	width  = CLIENT_WIDTH,
	height = CLIENT_HEIGHT,
}
SAMPLE_COUNT       :: 4 // This value is guaranteed to be supported

Application :: struct {
	using _app:      app.Application,
	render_pipeline: wgpu.RenderPipeline,
	msaa_view:       wgpu.TextureView,
	rpass:       struct {
		color_attachments: [1]wgpu.RenderPassColorAttachment,
		descriptor:        wgpu.RenderPassDescriptor,
	},
}

init :: proc(self: ^Application) -> (ok: bool) {
	// Use the same shader from the triangle example
	TRIANGLE_WGSL :: #load("./../triangle/triangle.wgsl", string)
	shader_module := wgpu.DeviceCreateShaderModule(
		self.gpu.device,
		{
			label = EXAMPLE_TITLE + " Module",
			source = TRIANGLE_WGSL,
		},
	)
	defer wgpu.Release(shader_module)

	self.render_pipeline = wgpu.DeviceCreateRenderPipeline(
		self.gpu.device,
		{
			label = EXAMPLE_TITLE + " Render Pipeline",
			vertex = { module = shader_module, entryPoint = "vs_main" },
			fragment = &{
				module = shader_module,
				entryPoint = "fs_main",
				targets = {
					{
						format    = self.gpu.config.format,
						blend     = &wgpu.BLEND_STATE_NORMAL,
						writeMask = wgpu.COLOR_WRITES_ALL,
					},
				},
			},
			multisample = {count = SAMPLE_COUNT, mask = max(u32)},
		},
	)

	create_msaa_framebuffer(self)

	self.rpass.color_attachments[0] = {
		view = nil, /* Assigned later */
		resolveTarget = nil, /* Assigned later */
		ops = {
			load = .Clear,
			store = .Store,
			clearValue = app.Color_Black,
		},
	}

	self.rpass.descriptor = {
		label            = "Render pass descriptor",
		colorAttachments = self.rpass.color_attachments[:],
	}

	return true
}

step :: proc(self: ^Application, dt: f32) -> (ok: bool) {
	frame := app.gpu_get_current_frame(self.gpu)
	if frame.skip { return }
	defer app.gpu_release_current_frame(&frame)

	encoder := wgpu.DeviceCreateCommandEncoder(self.gpu.device)
	defer wgpu.Release(encoder)

	self.rpass.color_attachments[0].view = self.msaa_view
	self.rpass.color_attachments[0].resolveTarget = frame.view
	rpass := wgpu.CommandEncoderBeginRenderPass(encoder, self.rpass.descriptor)
	defer wgpu.Release(rpass)

	wgpu.RenderPassSetPipeline(rpass, self.render_pipeline)
	wgpu.RenderPassDraw(rpass, {0, 3})
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
		case app.Resize_Event:
			resize(self, ev.size)
    }
    return true
}

quit :: proc(self: ^Application) {
	wgpu.Release(self.msaa_view)
	wgpu.Release(self.render_pipeline)
}

resize :: proc(self: ^Application, size: app.Vec2u) {
	wgpu.Release(self.msaa_view)
	create_msaa_framebuffer(self)
}

create_msaa_framebuffer :: proc(self: ^Application) {
	format_features :=
		wgpu.TextureFormatGuaranteedFormatFeatures(self.gpu.config.format, self.gpu.features)

	size := app.window_get_size(self.window)

	texture_descriptor := wgpu.TextureDescriptor {
		size          = { size.x, size.y, 1 },
		mipLevelCount = 1,
		sampleCount   = SAMPLE_COUNT,
		dimension     = ._2D,
		format        = self.gpu.config.format,
		usage         = format_features.allowedUsages,
	}

	texture := wgpu.DeviceCreateTexture(self.gpu.device, texture_descriptor)
	defer wgpu.Release(texture)

	self.msaa_view = wgpu.TextureCreateView(texture)
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
