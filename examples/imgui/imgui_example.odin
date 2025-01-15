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
	im_io:               ^im.IO,
	render_pass:         struct {
		color_attachments: [1]wgpu.RenderPassColorAttachment,
		descriptor:        wgpu.RenderPassDescriptor,
	},
}

Context :: app.Context(Example)

EXAMPLE_TITLE :: "ImGui"

init :: proc(ctx: ^Context) -> (ok: bool) {
	// Create ImGui context with default settings and initialize platform/renderer backends
	app.imgui_init(ctx) or_return

	// Create the texture
	ctx.texture = app.create_texture_from_file(ctx, "assets/textures/MyImage01.jpg") or_return
	defer if !ok {
		app.release(ctx.texture)
	}

	ctx.render_pass.color_attachments[0] = {
		view = nil, /* Assigned later */
		ops = {load = .Clear, store = .Store, clear_value = app.ColorBlack},
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
}

set_clear_value :: proc(ctx: ^Context, clear_color: [3]f32) #no_bounds_check {
	r, g, b := expand_values(clear_color)
	ctx.render_pass.color_attachments[0].ops.clear_value = {f64(r), f64(g), f64(b), 1.0}
}

imgui_update :: proc(ctx: ^Context, im_ctx: ^im.Context) -> (ok: bool) {
	// Display an image
	if im.begin("WebGPU Texture Test") {
		im.text("Pointer = = %p", ctx.texture.view)
		im.text("Size = %d x %d", ctx.texture.size.width, ctx.texture.size.height)
		im.image(
			im.TextureID(uintptr(ctx.texture.view)),
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

	return true
}

draw :: proc(ctx: ^Context) -> bool {
	ctx.cmd = wgpu.device_create_command_encoder(ctx.gpu.device) or_return
	defer wgpu.release(ctx.cmd)

	ctx.render_pass.color_attachments[0].view = ctx.frame.view
	render_pass := wgpu.command_encoder_begin_render_pass(ctx.cmd, ctx.render_pass.descriptor)
	defer wgpu.release(render_pass)

	// Render elements using the given pass
	app.imgui_draw(ctx, render_pass) or_return

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
		init         = init,
		quit         = quit,
		imgui_update = imgui_update, // Set the callback to update ui
		draw         = draw,
	}

	app.run(example) // Start the main loop
}
