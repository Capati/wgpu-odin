package imgui_example

/*
Learn more about Image Loading and Displaying:
https://github.com/ocornut/imgui/wiki/Image-Loading-and-Displaying-Examples
https://github.com/ocornut/imgui/wiki/Image-Loading-and-Displaying-Examples#example-for-webgpu-users
*/

// Packages
import "core:log"

// Local packages
import app "root:utils/application"
import im "root:utils/imgui"
import "root:wgpu"

Example :: struct {
	texture:             app.Texture,
	clear_color:         [3]f32,
	show_demo_window:    bool,
	show_another_window: bool,
	im_ctx:              ^im.Context,
	im_io:               ^im.IO,
	render_pass:         struct {
		color_attachments: [1]wgpu.Render_Pass_Color_Attachment,
		descriptor:        wgpu.Render_Pass_Descriptor,
	},
}

Context :: app.Context(Example)

EXAMPLE_TITLE :: "ImGui"

init :: proc(ctx: ^Context) -> (ok: bool) {
	ctx.im_ctx = im.create_context()
	ensure(ctx.im_ctx != nil, "Failed to create Imgui context")
	defer if !ok {
		im.destroy_context(ctx.im_ctx)
	}

	im.style_colors_dark()

	// Initialize the platform, application also uses GLFW
	ensure(im.glfw_init(ctx.window, true))
	defer if !ok {
		im.glfw_shutdown()
	}

	init_info := im.DEFAULT_WGPU_INIT_INFO
	init_info.device = ctx.gpu.device
	init_info.render_target_format = ctx.gpu.config.format

	// Initialize the WGPU renderer
	ensure(im.wgpu_init(init_info))
	defer if !ok {
		im.wgpu_shutdown()
	}

	// Create the texture
	ctx.texture = app.create_texture_from_file(ctx, "assets/textures/MyImage01.jpg") or_return
	defer if !ok {
		app.release(ctx.texture)
	}

	ctx.render_pass.color_attachments[0] = {
		view = nil, /* Assigned later */
		ops = {load = .Clear, store = .Store, clear_value = app.Color_Black},
	}

	ctx.clear_color = {0.1, 0.2, 0.3}
	set_clear_value(ctx, ctx.clear_color)

	ctx.im_io = im.get_io()

	ctx.render_pass.descriptor = {
		label             = "Render pass descriptor",
		color_attachments = ctx.render_pass.color_attachments[:],
	}

	return true
}

quit :: proc(ctx: ^Context) {
	app.release(ctx.texture)

	im.wgpu_shutdown()
	im.glfw_shutdown()
	im.destroy_context(ctx.im_ctx)
}

resize :: proc(ctx: ^Context, size: app.Window_Size) -> (ok: bool) {
	im.wgpu_recreate_device_objects() or_return
	return true
}

set_clear_value :: proc(ctx: ^Context, clear_color: [3]f32) #no_bounds_check {
	r, g, b := expand_values(clear_color)
	ctx.render_pass.color_attachments[0].ops.clear_value = {f64(r), f64(g), f64(b), 1.0}
}

imgui_update :: proc(ctx: ^Context) -> (ok: bool) {
	im.wgpu_new_frame() or_return
	im.glfw_new_frame()

	// Start a new Dear ImGui frame, you can submit any command from this point
	im.new_frame()

	// Display an image
	if im.begin("WebGPU Texture Test") {
		im.text("Pointer = = %p", ctx.texture.view)
		im.text("Size = %d x %d", ctx.texture.size.width, ctx.texture.size.height)
		im.image(
			im.Texture_ID(uintptr(ctx.texture.view)),
			{f32(ctx.texture.size.width), f32(ctx.texture.size.height)},
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
		im.checkbox("Demo Window", &ctx.show_demo_window)
		im.checkbox("Another Window", &ctx.show_another_window)

		@(static) f: f32
		// Edit 1 float using a slider from 0.0 to 1.0
		im.slider_float("float", &f, 0.0, 1.0)

		// Edit 3 floats representing a color
		if im.color_edit3("Clear Color", &ctx.clear_color) {
			set_clear_value(ctx, ctx.clear_color)
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
			1000.0 / ctx.im_io.framerate,
			ctx.im_io.framerate,
		)
	}
	im.end()

	// Show the big demo window (Most of the sample code is in im.show_demo_window()! You can
	// browse its code to learn more about Dear ImGui!).
	if ctx.show_demo_window {
		im.show_demo_window()
	}

	// Show another simple window
	if ctx.show_another_window {
		// Pass a pointer to our bool variable (the window will have a closing button that will
		// clear the bool when clicked)
		im.begin("Another Window", &ctx.show_another_window)
		im.text("Hello from another window!")
		if im.button("Close Me") {
			ctx.show_another_window = false
		}
		im.end()
	}

	// Ends the Dear ImGui frame, finalize the draw data
	im.render()

	return true
}

draw :: proc(ctx: ^Context) -> bool {
	// Update ImGui frame data
	imgui_update(ctx) or_return

	ctx.cmd = wgpu.device_create_command_encoder(ctx.gpu.device) or_return
	defer wgpu.release(ctx.cmd)

	ctx.render_pass.color_attachments[0].view = ctx.frame.view
	render_pass := wgpu.command_encoder_begin_render_pass(ctx.cmd, ctx.render_pass.descriptor)
	defer wgpu.release(render_pass)

	// Render elements using the given pass
	im.wgpu_render_draw_data(im.get_draw_data(), render_pass) or_return

	wgpu.render_pass_end(render_pass) or_return

	cmdbuf := wgpu.command_encoder_finish(ctx.cmd) or_return
	defer wgpu.release(cmdbuf)

	wgpu.queue_submit(ctx.gpu.queue, cmdbuf)
	wgpu.surface_present(ctx.gpu.surface) or_return

	return true
}

main :: proc() {
	when ODIN_DEBUG {
		context.logger = log.create_console_logger(opt = {.Level, .Terminal_Color})
		defer log.destroy_console_logger(context.logger)
	}

	settings := app.DEFAULT_SETTINGS
	settings.title = EXAMPLE_TITLE

	example, ok := app.create(Context, settings)
	if !ok {
		log.fatalf("Failed to create example [%s]", EXAMPLE_TITLE)
		return
	}
	defer app.destroy(example)

	example.callbacks = {
		init   = init,
		quit   = quit,
		resize = resize,
		draw   = draw,
	}

	app.run(example) // Start the main loop
}
