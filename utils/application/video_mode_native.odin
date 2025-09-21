#+build !js
package application

// Vendor
import "vendor:glfw"

get_video_modes :: proc(allocator := context.allocator) -> (modes: []Video_Mode) {
	raw_modes := glfw.GetVideoModes(glfw.GetPrimaryMonitor())
	count := len(raw_modes)

	if count == 0 { return {} }

	modes = make([]Video_Mode, count, allocator)

	for i in 0..< count {
		raw_mode := raw_modes[i]
		modes[i] = {
			width             = u32(raw_mode.width),
			height            = u32(raw_mode.height),
			bits_per_pixel    = u32(raw_mode.red_bits + raw_mode.green_bits + raw_mode.blue_bits),
			refresh_rate      = u32(raw_mode.refresh_rate),
			frame_time_target = 1.0 / f64(raw_mode.refresh_rate),
		}
	}

	return modes
}

get_video_mode :: proc() -> (mode: Video_Mode) {
	raw_mode := glfw.GetVideoMode(glfw.GetPrimaryMonitor())
	mode = {
		width             = u32(raw_mode.width),
		height            = u32(raw_mode.height),
		bits_per_pixel    = u32(raw_mode.red_bits + raw_mode.green_bits + raw_mode.blue_bits),
		refresh_rate      = u32(raw_mode.refresh_rate),
		frame_time_target = 1.0 / f64(raw_mode.refresh_rate),
	}
	return
}
