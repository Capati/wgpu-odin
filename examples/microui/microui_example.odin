package microui_example

// Core
import "core:log"

// Vendor
import mu "vendor:microui"

// Local packages
import wgpu "../.."
import app "../../utils/application"
import wgpu_mu "../../utils/microui"

CLIENT_WIDTH       :: 800
CLIENT_HEIGHT      :: 600
EXAMPLE_TITLE      :: "MicroUI Example"
VIDEO_MODE_DEFAULT :: app.Video_Mode {
	width  = CLIENT_WIDTH,
	height = CLIENT_HEIGHT,
}

Application :: struct {
	using _app:      app.Application,
	mu_ctx:          ^mu.Context,
	log_buf:         [64000]u8,
	log_buf_len:     int,
	log_buf_updated: bool,
	bg:              mu.Color,
	rpass: struct {
		colors:     [1]wgpu.RenderPassColorAttachment,
		descriptor: wgpu.RenderPassDescriptor,
	},
}

init :: proc(self: ^Application) -> (ok: bool) {
	mu_init_info := wgpu_mu.MICROUI_INIT_INFO_DEFAULT
	mu_init_info.surface_config = self.gpu.config

	self.mu_ctx = new(mu.Context)

	mu.init(self.mu_ctx)
	self.mu_ctx.text_width = mu.default_atlas_text_width
	self.mu_ctx.text_height = mu.default_atlas_text_height

	// Initialize MicroUI context with default settings
	wgpu_mu.init(mu_init_info)

	// Set initial state
	self.bg = {56, 130, 210, 255}

	self.rpass.colors[0] = {
		view = nil, /* Assigned later */
		ops  = {.Clear, .Store, get_color_from_mu_color(self.bg)},
	}

	self.rpass.descriptor = {
		label            = "Render pass descriptor",
		colorAttachments = self.rpass.colors[:],
	}

	return true
}

step :: proc(self: ^Application, dt: f32) -> (ok: bool) {
	mu_update(self)

	frame := app.gpu_get_current_frame(self.gpu)
	if frame.skip { return }
	defer app.gpu_release_current_frame(&frame)

	encoder := wgpu.DeviceCreateCommandEncoder(self.gpu.device)
	defer wgpu.Release(encoder)

	self.rpass.colors[0].ops.clearValue = get_color_from_mu_color(self.bg)
	self.rpass.colors[0].view = frame.view
	rpass := wgpu.CommandEncoderBeginRenderPass(encoder, self.rpass.descriptor)
	defer wgpu.Release(rpass)

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
	wgpu_mu.destroy()
	free(self.mu_ctx)
}

resize :: proc(self: ^Application, size: app.Vec2u) {
	wgpu_mu.resize(i32(size.x), i32(size.y))
}

get_color_from_mu_color :: proc(color: mu.Color) -> wgpu.Color {
	return {f64(color.r) / 255.0, f64(color.g) / 255.0, f64(color.b) / 255.0, 1.0}
}

mu_update :: proc(self: ^Application) {
	// UI definition
	mu.begin(self.mu_ctx)
	test_window(self, self.mu_ctx)
	log_window(self, self.mu_ctx)
	style_window(self, self.mu_ctx)
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
