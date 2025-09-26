package application

// Core
import "base:runtime"

Window :: distinct uintptr

Window_Styles :: bit_set[Window_Style]
Window_Style :: enum {
	Centered,
	Resizable,
	Borderless,
}

WINDOW_STYLES_DEFAULT :: Window_Styles{.Centered, .Resizable}

Window_State :: enum {
	Windowed,
	Fullscreen,
	FullscreenBorderless,
}

WINDOW_STATE_DEFAULT :: Window_State.Windowed

Window_Settings :: struct {
	styles: Window_Styles,
	state:  Window_State,
}

WINDOW_SETTINGS_DEFAULT :: Window_Settings {
	styles = WINDOW_STYLES_DEFAULT,
	state  = WINDOW_STATE_DEFAULT,
}

MIN_CLIENT_WIDTH :: 1
MIN_CLIENT_HEIGHT :: 1

Window_Resize_Proc :: #type proc(window: Window, size: Vec2u, userdata: rawptr)

Window_Resize_Info :: struct {
	callback: Window_Resize_Proc,
	userdata: rawptr,
}

Window_Base :: struct {
	custom_context:   runtime.Context,
	allocator:        runtime.Allocator,
	settings:         Window_Settings,
	mode:             Video_Mode,
	title_buf:        String_Buffer,
	size:             Vec2u,
	events:           Events,
	resize_callbacks: [dynamic]Window_Resize_Info,
	aspect:           f32,
	is_minimized:     bool,
	is_resizing:      bool,
	is_fullscreen:    bool,
}

window_get_refresh_rate :: proc(window: Window) -> u32 {
	impl := _window_get_impl(window)
	return impl.mode.refresh_rate
}

window_get_aspect :: proc(window: Window) -> f32 {
	impl := _window_get_impl(window)
	return impl.aspect
}

window_add_resize_callback :: proc(window: Window, cb: Window_Resize_Info) {
	impl := _window_get_impl(window)
	append(&impl.resize_callbacks, cb)
}

// -----------------------------------------------------------------------------
// @(private)
// -----------------------------------------------------------------------------

@(private, require_results)
_window_get_impl :: #force_inline proc "contextless" (window: Window) -> ^Window_Impl {
	return cast(^Window_Impl)window
}
