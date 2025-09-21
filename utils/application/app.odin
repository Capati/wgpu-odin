package application

// Core
import "base:runtime"

Settings :: struct {
	using window: Window_Settings,
	using gpu:    GPU_Settings,
}

SETTINGS_DEFAULT :: Settings {
	window = WINDOW_SETTINGS_DEFAULT,
	gpu    = GPU_SETTINGS_DEFAULT,
}

Application :: struct {
	/* Initialization */
	custom_context: runtime.Context,
	allocator:      runtime.Allocator,
	settings:       Settings,
	window:         ^Window,
	gpu:            ^GPU_Context,

	// State
	title_buf:      String_Buffer,
	timer:          Timer,
	keyboard:       Keyboard_State,
	mouse:          Mouse_State,
	exit_key:       Key,
	minimized:      bool,
	prepared:       bool,
}

init :: proc(
	self: ^Application,
	mode: Video_Mode,
	title: string,
	settings := SETTINGS_DEFAULT,
	allocator := context.allocator,
	loc := #caller_location,
) {
	self.custom_context = context
	self.allocator = allocator
	self.settings = settings

	self.window = window_create(mode, title, settings.window, allocator, loc)
	self.gpu = gpu_create(self.window, settings.gpu, allocator, loc)

	margin_ms := 0.5 // Wake up early for busy wait accuracy
	target_frame_time_ms := 1000.0 / f64(window_get_refresh_rate(self.window))
	timer_init(&self.timer, margin_ms, target_frame_time_ms)

	when ODIN_DEBUG {
		self.exit_key = .Escape
	}

	self.prepared = true
}

release :: proc(self: ^Application) {
	gpu_destroy(self.gpu)
	window_destroy(self.window)
}

begin_frame :: proc(self: ^Application) {
	timer_begin_frame(&self.timer)
	when ODIN_DEBUG {
		_update_window_title_with_fps(self)
	}
	keyboard_update(self)
	mouse_update(self)
}

end_frame :: proc(self: ^Application) {
	timer_end_frame(&self.timer)
	gpu_pace_frame(self.gpu, &self.timer)
}

@(require_results)
poll_event :: proc(self: ^Application, event: ^Event) -> (ok: bool) {
	ok = window_poll_event(self.window, event)
	if ok {
		#partial switch &ev in event {
		case Key_Pressed_Event:
			when ODIN_DEBUG {
				if ev.key == self.exit_key {
					events_push(&self.window.events, QuitEvent{})
				}
			}

		case Mouse_Wheel_Event:
			self.mouse.scroll.x += f64(ev.x)
			self.mouse.scroll.y += f64(ev.y)
		}
	}
	return
}

@(require_results)
get_aspect :: proc(self: ^Application) -> f32 {
	return window_get_aspect(self.window)
}

add_resize_callback :: proc(self: ^Application, cb: Window_Resize_Info) {
	window_add_resize_callback(self.window, cb)
}

@(require_results)
get_time :: proc(self: ^Application) -> f32 {
	return f32(timer_get_time(&self.timer))
}

@(require_results)
get_delta_time :: proc(self: ^Application) -> f32 {
	return f32(timer_get_delta(&self.timer))
}

// -----------------------------------------------------------------------------
// @(private)
// -----------------------------------------------------------------------------

@(private, disabled = !ODIN_DEBUG)
_update_window_title_with_fps :: proc(self: ^Application) {
	if !timer_get_fps_update(&self.timer) {
		return
	}

	title := string_buffer_get_string(&self.window.title_buf)

	title_buf: String_Buffer
	string_buffer_init(&title_buf, title)
	string_buffer_append(&title_buf, " - FPS = ")

	fps_buf: [4]u8
	fps := timer_get_fps(&self.timer)
	string_buffer_append_f64(&title_buf, fps_buf[:], fps, decimals = 1)

	// This call does not change window.title_buf
	window_set_title_cstring(self.window, string_buffer_get_cstring(&title_buf))
}
