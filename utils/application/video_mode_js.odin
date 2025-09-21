#+build js
package application

// Core
import "core:sys/wasm/js"

get_video_modes :: proc(allocator := context.allocator) -> (modes: []Video_Mode) {
	return
}

get_video_mode :: proc() -> (mode: Video_Mode) {
	// Get body dimensions as proxy for viewport
	body_rect := js.get_bounding_client_rect("body")

	// Get device pixel ratio
	dpi := js.device_pixel_ratio()

	// Viewport dimensions
	mode.width = u32(f64(body_rect.width) * dpi)
	mode.height = u32(f64(body_rect.height) * dpi)

	// Default refresh rate
	refresh_rate := 60

	return
}
