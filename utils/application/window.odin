#+build !js
package application

// Core
import "base:runtime"
import sa "core:container/small_array"

// Vendor
import "vendor:glfw"

// Local packages
import wgpu "../../"
import wgpu_glfw "../../utils/glfw"

Window_Styles :: bit_set[Window_Style]
Window_Style :: enum {
	Centered,
	Resizable,
	Borderless,
}

WINDOW_STYLES_DEFAULT :: Window_Styles{ .Centered, .Resizable }

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

Window_Resize_Proc :: #type proc (window: ^Window, size: Vec2u, userdata: rawptr)

Window_Resize_Info :: struct {
	callback: Window_Resize_Proc,
	userdata: rawptr,
}

MIN_CLIENT_WIDTH :: 1
MIN_CLIENT_HEIGHT :: 1

MAX_RESIZE_CALLBACKS :: #config(MAX_RESIZE_CALLBACKS, 4)
Resize_Callbacks :: sa.Small_Array(MAX_RESIZE_CALLBACKS, Window_Resize_Info)

Window_Base :: struct {
	custom_context:   runtime.Context,
	allocator:        runtime.Allocator,
	settings:         Window_Settings,
	mode:             Video_Mode,
	title_buf:        String_Buffer,
	size:             Vec2u,
	events:           Events,
	resize_callbacks: Resize_Callbacks,
	aspect:           f32,
	is_minimized:     bool,
	is_resizing:      bool,
	is_fullscreen:    bool,
}

@(require_results)
window_poll_event :: proc(self: ^Window, event: ^Event) -> (ok: bool) {
	if events_empty(&self.events) {
		glfw.PollEvents()
	}
	event^, ok = events_poll(&self.events)
	return
}

@(require_results)
window_get_handle :: proc(self: ^Window) -> glfw.WindowHandle {
	return self.handle
}

@(require_results)
window_get_size :: proc(self: ^Window) -> Vec2u {
	w, h := glfw.GetFramebufferSize(self.handle)
	return {u32(w), u32(h)}
}

@(require_results)
window_get_title :: proc(self: ^Window) -> string {
	return string(glfw.GetWindowTitle(self.handle))
}

window_set_title_string :: proc(self: ^Window, title: string) {
	string_buffer_init(&self.title_buf, title)
	window_set_title_cstring(self, string_buffer_get_cstring(&self.title_buf))
}

window_set_title_cstring :: proc(self: ^Window, title: cstring) {
	glfw.SetWindowTitle(self.handle, title)
}

window_set_title :: proc {
	window_set_title_string,
	window_set_title_cstring,
}

window_get_refresh_rate :: proc(self: ^Window) -> u32 {
	return self.mode.refresh_rate
}

window_add_resize_callback :: proc(self: ^Window, cb: Window_Resize_Info) {
	sa.push_back(&self.resize_callbacks, cb)
}

window_get_aspect :: proc(self: ^Window) -> f32 {
	return self.aspect
}

window_get_surface :: proc(self: ^Window, instance: wgpu.Instance) -> wgpu.Surface {
	return wgpu_glfw.CreateSurface(self.handle, instance)
}

// -----------------------------------------------------------------------------
// @(private)
// -----------------------------------------------------------------------------

@(private, require_results)
_window_get_user_pointer :: #force_inline proc "c" (
	handle: glfw.WindowHandle,
	loc := #caller_location,
) -> ^Window {
	window := cast(^Window)glfw.GetWindowUserPointer(handle)
	assert_contextless(window != nil, "Invalid Window pointer", loc)
	return window
}

@(private)
_window_close_callback :: proc "c" (handle: glfw.WindowHandle) {
	window := _window_get_user_pointer(handle)
	events_push(&window.events, QuitEvent{})
}

@(private)
_window_framebuffer_size_callback :: proc "c" (handle: glfw.WindowHandle, width, height: i32) {
	window := _window_get_user_pointer(handle)

	context = window.custom_context

	new_size := Vec2u{ u32(width), u32(height) }

	window.aspect = f32(width) / f32(height)

	// Execute all registered resize callbacks immediately.
	//
	// GLFW blocks the calling thread during window resizing, but continues to
	// invoke this callback. To avoid stacking multiple resize events, user
	// callbacks are invoked immediately rather than being queued.
	resize_callbacks := sa.slice(&window.resize_callbacks)
	for &cb in resize_callbacks {
		if cb.callback != nil {
			cb.callback(window, new_size, cb.userdata)
		}
	}
}

@(private)
_window_key_callback :: proc "c" (handle: glfw.WindowHandle, key, scancode, action, mods: i32) {
	window := _window_get_user_pointer(handle)
	event := Key_Event{ Key(key), Scancode(scancode) }
	if action == glfw.PRESS {
		events_push(&window.events, Key_Pressed_Event(event))
	} else {
		events_push(&window.events, Key_Released_Event(event))
	}
}

@(private)
_window_cursor_position_callback :: proc "c" (handle: glfw.WindowHandle, xpos, ypos: f64) {
	window := _window_get_user_pointer(handle)

	action: Input_Action
	button: Mouse_Button

	if glfw.GetMouseButton(handle, glfw.MOUSE_BUTTON_LEFT) == glfw.PRESS {
		button = .Left
		action = .Pressed
	} else if glfw.GetMouseButton(handle, glfw.MOUSE_BUTTON_MIDDLE) == glfw.PRESS {
		button = .Middle
		action = .Pressed
	} else if glfw.GetMouseButton(handle, glfw.MOUSE_BUTTON_RIGHT) == glfw.PRESS {
		button = .Right
		action = .Pressed
	} else if glfw.GetMouseButton(handle, glfw.MOUSE_BUTTON_4) == glfw.PRESS {
		button = .Four
		action = .Pressed
	} else if glfw.GetMouseButton(handle, glfw.MOUSE_BUTTON_5) == glfw.PRESS {
		button = .Five
		action = .Pressed
	}

	event := Mouse_Moved_Event {
		pos    = { f32(xpos), f32(ypos) },
		button = button,
		action = action,
	}

	events_push(&window.events, event)
}

@(private)
_window_mouse_button_callback :: proc "c" (handle: glfw.WindowHandle, button, action, mods: i32) {
	window := _window_get_user_pointer(handle)

	xpos, ypos := glfw.GetCursorPos(handle)

	event := Mouse_Button_Event{
		button = Mouse_Button(button),
		pos    = { f32(xpos), f32(ypos) },
	}

	if action == glfw.PRESS {
		events_push(&window.events, Mouse_Button_Pressed_Event(event))
	} else if action == glfw.RELEASE {
		events_push(&window.events, Mouse_Button_Released_Event(event))
	}
}

@(private)
_window_scroll_callback :: proc "c" (handle: glfw.WindowHandle, xoffset, yoffset: f64) {
	window := _window_get_user_pointer(handle)
	events_push(&window.events, Mouse_Wheel_Event{f32(xoffset), f32(yoffset)})
}

@(private)
_window_minimized_callback:: proc "c" (handle: glfw.WindowHandle, iconified: i32) {
	window := _window_get_user_pointer(handle)
	window.is_minimized = bool(iconified)
	events_push(&window.events, Minimized_Event{ window.is_minimized })
}

@(private)
_window_focus_callback :: proc "c" (handle: glfw.WindowHandle, focused: i32) {
	window := _window_get_user_pointer(handle)
	events_push(&window.events, Restored_Event{bool(focused)})
}
