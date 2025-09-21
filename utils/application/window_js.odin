#+build js
package application

// Core
import "core:sys/wasm/js"

// Local packages
import wgpu "../../"

Window :: struct {
	using _base: Window_Base,
	canvas_id:   string,
}

@(require_results)
window_create :: proc(
	mode: Video_Mode,
	title: string,
	canvas_id: string,
	settings := WINDOW_SETTINGS_DEFAULT,
	allocator := context.allocator,
	loc := #caller_location,
) -> (window: ^Window) {
	window = new(Window, allocator)
	ensure(window != nil, "Failed to allocate the window implementation", loc)
	window_init(window, mode, title, canvas_id, settings, allocator, loc)
	return
}

window_init :: proc(
	window: ^Window,
	mode: Video_Mode,
	title: string,
	canvas_id: string,
	settings := WINDOW_SETTINGS_DEFAULT,
	allocator := context.allocator,
	loc := #caller_location,
) {
	styles := settings.styles
	state := settings.state

	// Default fullscreen video mode
	desktop_mode := get_video_mode()

	mode := mode

	if state == .Fullscreen {
		// For web, fullscreen means using the full browser viewport
		mode = desktop_mode
	} else {
		mode.refresh_rate = desktop_mode.refresh_rate // ensure valid refresh rate
	}

	window.custom_context = context
	window.allocator = allocator
	window.settings = settings
	window.canvas_id = canvas_id
	window.mode = mode

	// Setup event listeners
	_window_setup_event_listeners(window)

	// Initial size calculation
	window.aspect = f32(mode.width) / f32(mode.height)
}

@(require_results)
window_get_surface :: proc(window: ^Window, instance: wgpu.Instance) -> wgpu.Surface {
	return wgpu.InstanceCreateSurface(
		instance,
		wgpu.SurfaceDescriptor{
			target = wgpu.SurfaceSourceCanvasHTMLSelector{
				selector = "#wgpu-canvas",
			},
		},
	)
}

// -----------------------------------------------------------------------------
// @(private)
// -----------------------------------------------------------------------------

@(private)
_window_setup_event_listeners :: proc(window: ^Window) {
	// Window/document events
	js.add_window_event_listener(.Resize, window, _window_resize_callback)
	js.add_window_event_listener(.Visibility_Change, window, _window_visibility_callback)

	// Canvas-specific events
	js.add_event_listener(window.canvas_id, .Click, window, _window_mouse_button_callback)
	js.add_event_listener(window.canvas_id, .Mouse_Down, window, _window_mouse_button_callback)
	js.add_event_listener(window.canvas_id, .Mouse_Up, window, _window_mouse_button_callback)
	js.add_event_listener(window.canvas_id, .Mouse_Move, window, _window_mouse_move_callback)
	js.add_event_listener(window.canvas_id, .Wheel, window, _window_scroll_callback)
	js.add_event_listener(window.canvas_id, .Context_Menu, window, _window_context_menu_callback)

	// Key events (typically handled at window level)
	js.add_window_event_listener(.Key_Down, window, _window_key_callback)
	js.add_window_event_listener(.Key_Up, window, _window_key_callback)

	// Focus events
	js.add_event_listener(window.canvas_id, .Focus, window, _window_focus_callback)
	js.add_event_listener(window.canvas_id, .Blur, window, _window_focus_callback)
}

@(private)
_window_cleanup_event_listeners :: proc(window: ^Window) {
	js.remove_window_event_listener(.Resize, window, _window_resize_callback)
	js.remove_window_event_listener(.Visibility_Change, window, _window_visibility_callback)
	js.remove_event_listener(window.canvas_id, .Click, window, _window_mouse_button_callback)
	js.remove_event_listener(window.canvas_id, .Mouse_Down, window, _window_mouse_button_callback)
	js.remove_event_listener(window.canvas_id, .Mouse_Up, window, _window_mouse_button_callback)
	js.remove_event_listener(window.canvas_id, .Mouse_Move, window, _window_mouse_move_callback)
	js.remove_event_listener(window.canvas_id, .Wheel, window, _window_scroll_callback)
	js.remove_event_listener(window.canvas_id, .Context_Menu, window, _window_context_menu_callback)
	js.remove_window_event_listener(.Key_Down, window, _window_key_callback)
	js.remove_window_event_listener(.Key_Up, window, _window_key_callback)
	js.remove_event_listener(window.canvas_id, .Focus, window, _window_focus_callback)
	js.remove_event_listener(window.canvas_id, .Blur, window, _window_focus_callback)
}

@(private)
_window_resize_callback :: proc "contextless" (event: js.Event) {
}

@(private)
_window_visibility_callback :: proc "contextless" (event: js.Event) {
}

@(private)
_window_mouse_button_callback :: proc "contextless" (event: js.Event) {
}

@(private)
_window_mouse_move_callback :: proc "contextless" (event: js.Event) {
}

@(private)
_window_scroll_callback :: proc "contextless" (event: js.Event) {
}

@(private)
_window_context_menu_callback :: proc "contextless" (event: js.Event) {
}

@(private)
_window_key_callback :: proc "contextless" (event: js.Event) {
}

@(private)
_window_focus_callback :: proc "contextless" (event: js.Event) {
}
