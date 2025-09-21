package application

// Core
import "base:runtime"

Video_Mode :: struct {
	width:             u32,
	height:            u32,
	bits_per_pixel:    u32,
	refresh_rate:      u32,
	frame_time_target: f64, // in seconds
}

video_mode_is_valid :: proc (mode: Video_Mode) -> bool {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	modes := get_video_modes(context.temp_allocator)
	for &curr_mode in modes {
		if video_mode_equals(curr_mode, mode) {
			return true
		}
	}
	return false
}

video_mode_equals :: proc(left: Video_Mode, right: Video_Mode) -> bool {
	return left.width == right.width &&
           left.height == right.height &&
           left.refresh_rate == right.refresh_rate &&
           left.bits_per_pixel == right.bits_per_pixel
}

video_mode_not_equals :: proc(left: Video_Mode, right: Video_Mode) -> bool {
	return !video_mode_equals(left, right)
}
