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
