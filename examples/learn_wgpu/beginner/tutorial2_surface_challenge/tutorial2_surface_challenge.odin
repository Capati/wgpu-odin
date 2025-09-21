package tutorial2_surface_challenge

// Core
import "core:log"

// Local packages
import wgpu "../../../../"
import app "../../../../utils/application"

CLIENT_WIDTH  :: 640
CLIENT_HEIGHT :: 480
EXAMPLE_TITLE :: "Tutorial 2 - Surface Challenge"

Application :: struct {
	using _app:  app.Application, /* #subtype */
	clear_value: app.Color,
	rpass: struct {
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

	self.clear_value = app.Color_Royal_Blue

	self.rpass.colors[0] = {
		view = nil, /* Assigned later */
		ops  = {.Clear, .Store, self.clear_value},
	}

	self.rpass.descriptor = {
		label            = "Render pass descriptor",
		colorAttachments = self.rpass.colors[:],
	}

	return
}

release :: proc(self: ^Application) {
	app.release(self)
	free(self)
}

color_from_mouse_position :: proc(x, y: f32, w, h: u32) -> (color: app.Color) {
	color.r = cast(f64)x / cast(f64)w
	color.g = cast(f64)y / cast(f64)h
	color.b = 1.0
	color.a = 1.0
	return
}

mouse_moved_event :: proc(self: ^Application, event: app.Mouse_Moved_Event) {
	self.clear_value = color_from_mouse_position(
		event.pos.x,
		event.pos.y,
		self.gpu.config.width,
		self.gpu.config.height,
	)
}

draw :: proc(self: ^Application) {
	gpu := self.gpu

	frame := app.gpu_get_current_frame(gpu)
	if frame.skip { return }
	defer app.gpu_release_current_frame(&frame)

	encoder := wgpu.DeviceCreateCommandEncoder(gpu.device)
	defer wgpu.Release(encoder)

	self.rpass.colors[0].view = frame.view
	self.rpass.colors[0].ops.clearValue = self.clear_value
	rpass := wgpu.CommandEncoderBeginRenderPass(encoder, self.rpass.descriptor)
	defer wgpu.Release(rpass)
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
			case app.Mouse_Moved_Event:
				mouse_moved_event(example, ev)

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
