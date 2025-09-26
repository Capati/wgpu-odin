#+build !js
package triangle

// Core
import "core:time"

// Vendor
import "vendor:glfw"

CLIENT_WIDTH :: 640
CLIENT_HEIGHT :: 480

OS :: struct {
	window:    glfw.WindowHandle,
	minimized: bool,
}

os_init :: proc() {
	// Initialize GLFW library
	ensure(bool(glfw.Init()), "Failed to initialize GLFW")

	// Ensure no OpenGL context is loaded before window creation
	glfw.WindowHint_int(glfw.CLIENT_API, glfw.NO_API)

	// Create a window with the given size and title
	state.os.window = glfw.CreateWindow(CLIENT_WIDTH, CLIENT_HEIGHT, EXAMPLE_TITLE, nil, nil)
	assert(state.os.window != nil, "Failed to create window")

	glfw.SetFramebufferSizeCallback(state.os.window, size_callback)
	glfw.SetWindowIconifyCallback(state.os.window, minimize_callback)
}

os_run :: proc() {
	dt: f32

	for !glfw.WindowShouldClose(state.os.window) {
		start := time.tick_now()

		glfw.PollEvents()
		if !state.os.minimized {
			frame(dt)
		} else {
			time.sleep(100 * time.Millisecond)
			continue
		}

		dt = f32(time.duration_seconds(time.tick_since(start)))
	}

	finish()

	glfw.DestroyWindow(state.os.window)
	glfw.Terminate()
}

os_get_framebuffer_size :: proc() -> (width, height: u32) {
	iw, ih := glfw.GetFramebufferSize(state.os.window)
	return u32(iw), u32(ih)
}

size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	if state.os.minimized do return
	resize()
}

minimize_callback :: proc "c" (window: glfw.WindowHandle, iconified: i32) {
	context = state.ctx
	state.os.minimized = bool(iconified)
}
