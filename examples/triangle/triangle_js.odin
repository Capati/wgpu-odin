#+build js
package triangle

// Core
import "base:runtime"
import "core:sys/wasm/js"

// Local packages
import wgpu "../.."

OS :: struct {
	initialized: bool,
}

os_init :: proc() {
	ok := js.add_window_event_listener(.Resize, nil, size_callback)
	assert(ok)
}

// NOTE: frame loop is done by the runtime.js repeatedly calling `step`.
os_run :: proc() {
	state.os.initialized = true
}

@(private="file", export)
step :: proc(dt: f32) -> bool {
	if !state.os.initialized {
		return true
	}

	frame(dt)
	return true
}

os_get_framebuffer_size :: proc() -> (width, height: u32) {
	rect := js.get_bounding_client_rect("body")
	dpi := js.device_pixel_ratio()
	return u32(f64(rect.width) * dpi), u32(f64(rect.height) * dpi)
}

@(private="file", fini)
os_fini :: proc "contextless" () {
	context = runtime.default_context()
	js.remove_window_event_listener(.Resize, nil, size_callback)

	finish()
}

@(private="file")
size_callback :: proc(e: js.Event) {
	resize()
}
