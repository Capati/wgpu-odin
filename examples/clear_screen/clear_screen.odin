package clear_screen

// Core
import "core:log"
import "core:math"

// Local packages
import wgpu "../.."
import app "../../utils/application"

CLIENT_WIDTH       :: 640
CLIENT_HEIGHT      :: 480
EXAMPLE_TITLE      :: "Clear Screen"
VIDEO_MODE_DEFAULT :: app.Video_Mode {
	width  = CLIENT_WIDTH,
	height = CLIENT_HEIGHT,
}

Application :: struct {
	using _app: app.Application,
	clear_value: app.Color,
	rpass: struct {
		colors:     [1]wgpu.RenderPassColorAttachment,
		descriptor: wgpu.RenderPassDescriptor,
	},
}

init :: proc(self: ^Application) -> (ok: bool) {
	self.clear_value = app.Color_Black

	self.rpass.colors[0] = {
		view = nil, /* Assigned later */
		ops = {
			load = .Clear,
			store = .Store,
			clearValue = self.clear_value,
		},
	}

	self.rpass.descriptor = {
		label            = "Render pass descriptor",
		colorAttachments = self.rpass.colors[:],
	}

	return true
}

update :: proc(self: ^Application, dt: f32) -> (ok: bool) {
	current_time := app.get_time()
	color := [4]f64 {
		math.sin(f64(current_time)) * 0.5 + 0.5,
		math.cos(f64(current_time)) * 0.5 + 0.5,
		0.0,
		1.0,
	}
	self.rpass.colors[0].ops.clearValue = color
	return true
}

step :: proc(self: ^Application, dt: f32) -> (ok: bool) {
	update(self, dt) or_return

	frame := app.gpu_get_current_frame(self.gpu)
	if frame.skip { return }
	defer app.gpu_release_current_frame(&frame)

	encoder := wgpu.DeviceCreateCommandEncoder(self.gpu.device)
	defer wgpu.CommandEncoderRelease(encoder)

	self.rpass.colors[0].view = frame.view
	rpass := wgpu.CommandEncoderBeginRenderPass(encoder, self.rpass.descriptor)
	wgpu.RenderPassEnd(rpass)
	wgpu.RenderPassRelease(rpass)

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
    }
    return true
}

quit :: proc(app: ^Application) {
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
