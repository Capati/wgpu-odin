#+build !js
package application

// Core
import "core:log"

// Vendor
import "vendor:glfw"

Window :: struct {
	using _base: Window_Base,
	handle:      glfw.WindowHandle,
}

@(require_results)
window_create :: proc(
	mode: Video_Mode,
	title: string,
	settings := WINDOW_SETTINGS_DEFAULT,
	allocator := context.allocator,
	loc := #caller_location,
) -> (window: ^Window) {
	window = new(Window, allocator)
	ensure(window != nil, "Failed to allocate the window implementation", loc)
	window_init(window, mode, title, settings, allocator, loc)
	return
}

window_init :: proc(
	window: ^Window,
	mode: Video_Mode,
	title: string,
	settings := WINDOW_SETTINGS_DEFAULT,
	allocator := context.allocator,
	loc := #caller_location,
) {
	assert(mode.width >= MIN_CLIENT_WIDTH, "Invalid window width", loc)
	assert(mode.height >= MIN_CLIENT_HEIGHT, "Invalid window height", loc)

	styles := settings.styles
	state := settings.state

	// Default fullscreen video mode
	desktop_mode := get_video_mode()

	mode := mode

    // Fullscreen style requires some tests
	if state == .Fullscreen {
        // Make sure that the chosen video mode is compatible
		if !video_mode_is_valid(mode) {
			log.warn("The requested video mode is not available, switching to default mode")
			mode = desktop_mode
		}
	} else {
		mode.refresh_rate = desktop_mode.refresh_rate // ensure valid refresh rate
	}

	window.custom_context = context
	window.allocator = allocator
	window.settings = settings

	monitor := glfw.GetPrimaryMonitor()

	glfw.WindowHint_int(glfw.CLIENT_API, glfw.NO_API)

	// Set window hints based on styles
	glfw.WindowHint_bool(glfw.RESIZABLE, .Resizable in styles)
	glfw.WindowHint_bool(glfw.DECORATED, !(.Borderless in styles))

	// Determine monitor and fullscreen mode
	target_monitor: glfw.MonitorHandle = nil
	switch state {
	case .Windowed:
		target_monitor = nil
	case .Fullscreen:
		target_monitor = monitor
	case .FullscreenBorderless:
		glfw.WindowHint_bool(glfw.DECORATED, false)
		// For borderless fullscreen, use desktop mode dimensions
		mode = desktop_mode
		styles += { .Centered }
	}

	if .Centered in styles {
		// Calculate the window centered position
		xpos, ypos, width, height := glfw.GetMonitorWorkarea(monitor)
		window_x := xpos + (width - i32(mode.width)) / 2
		glfw.WindowHint_int(glfw.POSITION_X, window_x)
		window_y := ypos + (height - i32(mode.height)) / 2
		glfw.WindowHint_int(glfw.POSITION_Y, window_y)
	}

	// Create the GLFW window
	string_buffer_init(&window.title_buf, title)
	window.handle = glfw.CreateWindow(
		i32(mode.width),
		i32(mode.height),
		string_buffer_get_cstring(&window.title_buf),
		target_monitor,
		nil,
	)

	if window.handle == nil {
		error_str, error_code := glfw.GetError()
		log.panicf("Failed to create window [%v]: %s", error_code, error_str, location = loc)
	}

	window.mode = mode

	glfw.SetWindowUserPointer(window.handle, window)

	// Setup callbacks to populate event queue
	glfw.SetWindowCloseCallback(window.handle, _window_close_callback)
	glfw.SetFramebufferSizeCallback(window.handle, _window_framebuffer_size_callback)
	glfw.SetKeyCallback(window.handle, _window_key_callback)
	glfw.SetCursorPosCallback(window.handle, _window_cursor_position_callback)
	glfw.SetMouseButtonCallback(window.handle, _window_mouse_button_callback)
	glfw.SetScrollCallback(window.handle, _window_scroll_callback)
	glfw.SetWindowIconifyCallback(window.handle, _window_minimized_callback)
	glfw.SetWindowFocusCallback(window.handle, _window_focus_callback)
}

window_destroy :: proc(self: ^Window) {
	glfw.DestroyWindow(self.handle)
}
