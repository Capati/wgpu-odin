package application

// Packages
import "core:mem"
import "vendor:glfw"

Window_Size :: struct {
	w, h: u32,
}

Framebuffer_Size :: Window_Size

get_framebuffer_size :: proc(app: ^Application) -> Window_Size {
	width, height := glfw.GetFramebufferSize(app.window)
	return {u32(width), u32(height)}
}

set_window_title :: proc(app: ^Application, title: string) {
	str_buf := transmute([]u8)title
	mem.zero_slice(app.title_buffer[:])
	copy(app.title_buffer[:], str_buf)
	app.settings.title = string(app.title_buffer[:])
	nul := nul_search_bytes(app.title_buffer[:])
	app.title_buffer[nul] = 0
	glfw.SetWindowTitle(app.window, cstring(raw_data(app.title_buffer[:nul + 1])))
}

Monitor_Info :: struct {
	refresh_rate:      u32,
	frame_time_target: f64, // in seconds
}

get_primary_monitor_info :: proc() -> (info: Monitor_Info) {
	mode := glfw.GetVideoMode(glfw.GetPrimaryMonitor())
	info = Monitor_Info {
		refresh_rate      = u32(mode.refresh_rate),
		frame_time_target = 1.0 / f64(mode.refresh_rate),
	}
	return
}
