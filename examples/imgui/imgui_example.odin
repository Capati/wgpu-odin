package imgui_example

/*
Learn more about Image Loading and Displaying:
https://github.com/ocornut/imgui/wiki/Image-Loading-and-Displaying-Examples
https://github.com/ocornut/imgui/wiki/Image-Loading-and-Displaying-Examples#example-for-webgpu-users
*/

// Core
import "core:log"

// Local packages
import wgpu "../.."
import app "../../utils/application"
import im "../../libs/imgui"
import im_glfw "../../libs/imgui/imgui_impl_glfw"
import im_wgpu "../../utils/imgui"

CLIENT_WIDTH       :: 1024
CLIENT_HEIGHT      :: 768
EXAMPLE_TITLE      :: "ImGui"
VIDEO_MODE_DEFAULT :: app.Video_Mode {
	width  = CLIENT_WIDTH,
	height = CLIENT_HEIGHT,
}

Texture :: app.Texture

Application :: struct {
	using _app:          app.Application,
	texture:             Texture,
	clear_color:         [3]f32,
	show_demo_window:    bool,
	show_another_window: bool,
	im_ctx:              ^im.Context,
	im_io:               ^im.IO,
	rpass: struct {
		colors:     [1]wgpu.RenderPassColorAttachment,
		descriptor: wgpu.RenderPassDescriptor,
	},
}

init :: proc(self: ^Application) -> (ok: bool) {
	self.im_ctx = im.create_context()
	ensure(self.im_ctx != nil, "Failed to create Imgui context")

	im.style_colors_dark()

	// Initialize the platform, application also uses GLFW
	ensure(im_glfw.init_for_other(app.window_get_handle(self.window), true))

	init_info := im_wgpu.INIT_INFO_DEFAULT
	init_info.device = self.gpu.device
	init_info.render_target_format = self.gpu.config.format

	// Initialize the WGPU renderer
	ensure(im_wgpu.init(init_info))

	// Create the texture
	self.texture = app.create_texture_from_file(self, "assets/textures/MyImage01.jpg")

	self.rpass.colors[0] = {
		view = nil, /* Assigned later */
		ops = {load = .Clear, store = .Store, clearValue = app.Color_Black},
	}

	self.clear_color = {0.1, 0.2, 0.3}
	set_clear_value(self, self.clear_color)

	self.im_io = im.get_io()

	self.rpass.descriptor = {
		label            = "Render pass descriptor",
		colorAttachments = self.rpass.colors[:],
	}

	return true
}

step :: proc(self: ^Application, dt: f32) -> (ok: bool) {
	// Update ImGui frame data
	imgui_update(self) or_return

	frame := app.gpu_get_current_frame(self.gpu)
	if frame.skip { return }
	defer app.gpu_release_current_frame(&frame)

	encoder := wgpu.DeviceCreateCommandEncoder(self.gpu.device)
	defer wgpu.Release(encoder)

	self.rpass.colors[0].view = frame.view
	rpass := wgpu.CommandEncoderBeginRenderPass(encoder, self.rpass.descriptor)
	defer wgpu.Release(rpass)

	// Render elements using the given pass
	im_wgpu.render_draw_data(im.get_draw_data(), rpass)

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
	app.texture_release(self.texture)

	im_wgpu.shutdown()
	im_glfw.shutdown()
	im.destroy_context(self.im_ctx)
}

resize :: proc(self: ^Application, size: app.Vec2u) {
	im_wgpu.recreate_device_objects()
}

set_clear_value :: proc(self: ^Application, clear_color: [3]f32) #no_bounds_check {
	r, g, b := expand_values(clear_color)
	self.rpass.colors[0].ops.clearValue = {f64(r), f64(g), f64(b), 1.0}
}

imgui_update :: proc(self: ^Application) -> (ok: bool) {
	im_glfw.new_frame()
	im_wgpu.new_frame()

	// Start a new Dear ImGui frame, you can submit any command from this point
	im.new_frame()

	// Display an image
	if im.begin("WebGPU Texture Test") {
		im.text("Pointer = = %p", self.texture.view)
		im.text("Size = %d x %d", self.texture.size.width, self.texture.size.height)
		im.image(
			im.Texture_ID(uintptr(self.texture.view)),
			{f32(self.texture.size.width), f32(self.texture.size.height)},
		)
	}
	im.end()

	// Show a simple window that we create ourselves.
	// We use a begin/end pair to create a named window
	// Create a window called "Hello, world!" and append into it.
	if im.begin("Hello, world") {
		// Display some text (you can use a format strings too)
		im.text("This is some useful text.")

		// Edit bools storing our window open/close state
		im.checkbox("Demo Window", &self.show_demo_window)
		im.checkbox("Another Window", &self.show_another_window)

		@(static) f: f32
		// Edit 1 float using a slider from 0.0 to 1.0
		im.slider_float("float", &f, 0.0, 1.0)

		// Edit 3 floats representing a color
		if im.color_edit3("Clear Color", &self.clear_color) {
			set_clear_value(self, self.clear_color)
		}

		@(static) counter: int
		// Buttons return true when clicked (most widgets return true when edited/activated)
		if im.button("Button") {
			counter += 1
		}
		im.same_line()
		im.text("counter = %d", counter)

		im.text(
			"Application average %.3f ms/frame (%.1f FPS)",
			1000.0 / self.im_io.framerate,
			self.im_io.framerate,
		)
	}
	im.end()

	// Show the big demo window (Most of the sample code is in im.show_demo_window()! You can
	// browse its code to learn more about Dear ImGui!).
	if self.show_demo_window {
		im.show_demo_window()
	}

	// Show another simple window
	if self.show_another_window {
		// Pass a pointer to our bool variable (the window will have a closing button that will
		// clear the bool when clicked)
		im.begin("Another Window", &self.show_another_window)
		im.text("Hello from another window!")
		if im.button("Close Me") {
			self.show_another_window = false
		}
		im.end()
	}

	// Ends the Dear ImGui frame, finalize the draw data
	im.render()

	return true
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
