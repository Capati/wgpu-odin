package imgui

// Packages
import win32 "core:sys/windows"
import "vendor:glfw"
import glfw_raw "vendor:glfw/bindings"

_ :: win32

GLFWData :: struct {
	window:                          glfw.WindowHandle,
	time:                            f64,
	mouse_window:                    glfw.WindowHandle,
	mouse_cursors:                   [MOUSE_CURSOR_COUNT]glfw.CursorHandle,
	last_valid_mouse_pos:            Vec2,
	installed_callbacks:             bool,
	callbacks_chain_for_all_windows: bool,
	// Chain GLFW callbacks:
	// Our callbacks will call the user's previously installed callbacks, if any
	prev_user_callback_window_focus: glfw.WindowFocusProc,
	prev_user_callback_cursor_pos:   glfw.CursorPosProc,
	prev_user_callback_cursor_enter: glfw.CursorEnterProc,
	prev_user_callback_mousebutton:  glfw.MouseButtonProc,
	prev_user_callback_scroll:       glfw.ScrollProc,
	prev_user_callback_key:          glfw.KeyProc,
	prev_user_callback_char:         glfw.CharProc,
	prev_user_callback_monitor:      glfw.MonitorProc,
	// when ODIN_OS == .Windows {
	prev_wnd_proc:                   win32.WNDPROC,
	// }
}

/* Retrieves a pointer to the `GLFWData` structure. */
@(require_results)
glfw_get_backend_data :: proc "contextless" () -> ^GLFWData {
	if ctx := get_current_context(); ctx != nil {
		return cast(^GLFWData)(get_io().backend_platform_user_data)
	}
	return nil
}

@(require_results)
glfw_init :: proc(window: glfw.WindowHandle, install_callbacks: bool) -> (ok: bool) {
	io := get_io()
	assert(io.backend_platform_user_data == nil, "Already initialized a platform backend!")

	bd := new(GLFWData)
	defer if !ok {
		free(bd)
	}
	io.backend_platform_user_data = bd
	io.backend_platform_name = "imgui_impl_glfw"
	io.backend_flags += {.HasMouseCursors, .HasSetMousePos}

	bd.window = window

	platform_io := get_platform_io()
	platform_io.platform_set_clipboard_text_fn = _glfw_set_clipboard_text_proc
	platform_io.platform_get_clipboard_text_fn = _glfw_get_clipboard_text_proc

	// Create mouse cursors
	// (By design, on X11 cursors are user configurable and some cursors may be missing.
	// When a cursor doesn't exist, GLFW will emit an error which will often be printed by the app,
	// so we temporarily disable error reporting. Missing cursors will return nullptr and our
	// _UpdateMouseCursor() function will use the Arrow cursor instead.)
	prev_error_callback := glfw.SetErrorCallback(nil)

	bd.mouse_cursors[MouseCursor.Arrow] = glfw.CreateStandardCursor(glfw.ARROW_CURSOR)
	bd.mouse_cursors[MouseCursor.TextInput] = glfw.CreateStandardCursor(glfw.IBEAM_CURSOR)
	bd.mouse_cursors[MouseCursor.ResizeNS] = glfw.CreateStandardCursor(glfw.VRESIZE_CURSOR)
	bd.mouse_cursors[MouseCursor.ResizeEW] = glfw.CreateStandardCursor(glfw.HRESIZE_CURSOR)
	bd.mouse_cursors[MouseCursor.Hand] = glfw.CreateStandardCursor(glfw.HAND_CURSOR)

	bd.mouse_cursors[MouseCursor.ResizeAll] = glfw.CreateStandardCursor(glfw.RESIZE_ALL_CURSOR)
	bd.mouse_cursors[MouseCursor.ResizeNESW] = glfw.CreateStandardCursor(glfw.RESIZE_NESW_CURSOR)
	bd.mouse_cursors[MouseCursor.ResizeNWSE] = glfw.CreateStandardCursor(glfw.RESIZE_NWSE_CURSOR)
	bd.mouse_cursors[MouseCursor.NotAllowed] = glfw.CreateStandardCursor(glfw.NOT_ALLOWED_CURSOR)

	bd.mouse_cursors[MouseCursor.ResizeAll] = glfw.CreateStandardCursor(glfw.ARROW_CURSOR)
	bd.mouse_cursors[MouseCursor.ResizeNESW] = glfw.CreateStandardCursor(glfw.ARROW_CURSOR)
	bd.mouse_cursors[MouseCursor.ResizeNWSE] = glfw.CreateStandardCursor(glfw.ARROW_CURSOR)
	bd.mouse_cursors[MouseCursor.NotAllowed] = glfw.CreateStandardCursor(glfw.ARROW_CURSOR)

	glfw.SetErrorCallback(prev_error_callback)
	glfw_raw.GetError(nil) // Eat errors (see https://github.com/ocornut/imgui/issues/5908)

	if install_callbacks {
		glfw_install_callbacks(window)
	}

	// Set platform dependent data in viewport
	main_viewport := get_main_viewport()
	main_viewport.platform_handle = bd.window

	when ODIN_OS == .Windows {
		main_viewport.platform_handle_raw = glfw.GetWin32Window(bd.window)
	} else when ODIN_OS == .Darwin {
		main_viewport.platform_handle_raw = rawptr(glfw.GetCocoaWindow(bd.window))
	}

	// Windows: register a `prev_wnd_proc` hook so we can intercept some messages.
	when ODIN_OS == .Windows {
		original_window_proc := win32.GetWindowLongPtrW(
			win32.HWND(main_viewport.platform_handle_raw),
			win32.GWLP_WNDPROC,
		)
		bd.prev_wnd_proc = win32.WNDPROC(rawptr(uintptr(original_window_proc)))
		assert(bd.prev_wnd_proc != nil)
		win32.SetWindowLongPtrW(
			win32.HWND(main_viewport.platform_handle_raw),
			win32.GWLP_WNDPROC,
			int(uintptr(rawptr(glfw_wnd_proc))),
		)
	}

	return true
}

@(private)
_glfw_set_clipboard_text_proc :: proc(ctx: ^Context, text: cstring) {
	glfw.SetClipboardString(nil, text)
}

@(private)
_glfw_get_clipboard_text_proc :: proc(ctx: ^Context) -> cstring {
	return glfw_raw.GetClipboardString(nil)
}

when ODIN_OS == .Windows {
	foreign import user32 "system:User32.lib"

	@(default_calling_convention = "system")
	foreign user32 {
		GetMessageExtraInfo :: proc() -> win32.LPARAM ---
	}

	get_mouse_source_from_message_extra_info :: proc "contextless" () -> MouseSource {
		extra_info := GetMessageExtraInfo()
		if (extra_info & 0xFFFFFF80) == 0xFF515700 {
			return .Pen
		}
		if (extra_info & 0xFFFFFF80) == 0xFF515780 {
			return .TouchScreen
		}
		return .Mouse
	}

	glfw_wnd_proc :: proc "system" (
		hWnd: win32.HWND,
		msg: win32.UINT,
		wParam: win32.WPARAM,
		lParam: win32.LPARAM,
	) -> win32.LRESULT {
		bd := glfw_get_backend_data()
		switch msg {
		case win32.WM_MOUSEMOVE,
		     win32.WM_NCMOUSEMOVE,
		     win32.WM_LBUTTONDOWN,
		     win32.WM_LBUTTONDBLCLK,
		     win32.WM_LBUTTONUP,
		     win32.WM_RBUTTONDOWN,
		     win32.WM_RBUTTONDBLCLK,
		     win32.WM_RBUTTONUP,
		     win32.WM_MBUTTONDOWN,
		     win32.WM_MBUTTONDBLCLK,
		     win32.WM_MBUTTONUP,
		     win32.WM_XBUTTONDOWN,
		     win32.WM_XBUTTONDBLCLK,
		     win32.WM_XBUTTONUP:
			io_add_mouse_source_event(get_io(), get_mouse_source_from_message_extra_info())
		}
		return win32.CallWindowProcW(bd.prev_wnd_proc, hWnd, msg, wParam, lParam)
	}
}

glfw_install_callbacks :: proc(window: glfw.WindowHandle) {
	bd := glfw_get_backend_data()
	assert(bd.installed_callbacks == false, "Callbacks already installed!")
	assert(bd.window == window)

	bd.prev_user_callback_window_focus = glfw.SetWindowFocusCallback(
		window,
		glfw_window_focus_callback,
	)
	bd.prev_user_callback_cursor_enter = glfw.SetCursorEnterCallback(
		window,
		glfw_cursor_enter_callback,
	)
	bd.prev_user_callback_cursor_pos = glfw.SetCursorPosCallback(window, glfw_cursor_pos_callback)
	bd.prev_user_callback_mousebutton = glfw.SetMouseButtonCallback(
		window,
		glfw_mouse_button_callback,
	)
	bd.prev_user_callback_scroll = glfw.SetScrollCallback(window, glfw_scroll_callback)
	bd.prev_user_callback_key = glfw.SetKeyCallback(window, glfw_key_callback)
	bd.prev_user_callback_char = glfw.SetCharCallback(window, glfw_char_callback)
	bd.prev_user_callback_monitor = glfw.SetMonitorCallback(window, glfw_monitor_callback)

	bd.installed_callbacks = true
}

glfw_restore_callbacks :: proc(window: glfw.WindowHandle) {
	bd := glfw_get_backend_data()
	assert(bd.installed_callbacks == true, "Callbacks not installed!")
	assert(bd.window == window)

	glfw.SetWindowFocusCallback(window, bd.prev_user_callback_window_focus)
	glfw.SetCursorEnterCallback(window, bd.prev_user_callback_cursor_enter)
	glfw.SetCursorPosCallback(window, bd.prev_user_callback_cursor_pos)
	glfw.SetMouseButtonCallback(window, bd.prev_user_callback_mousebutton)
	glfw.SetScrollCallback(window, bd.prev_user_callback_scroll)
	glfw.SetKeyCallback(window, bd.prev_user_callback_key)
	glfw.SetCharCallback(window, bd.prev_user_callback_char)
	glfw.SetMonitorCallback(window, bd.prev_user_callback_monitor)
	bd.installed_callbacks = false
	bd.prev_user_callback_window_focus = nil
	bd.prev_user_callback_cursor_enter = nil
	bd.prev_user_callback_cursor_pos = nil
	bd.prev_user_callback_mousebutton = nil
	bd.prev_user_callback_scroll = nil
	bd.prev_user_callback_key = nil
	bd.prev_user_callback_char = nil
	bd.prev_user_callback_monitor = nil
}

glfw_should_chain_callback :: proc "contextless" (window: glfw.WindowHandle) -> bool {
	bd := glfw_get_backend_data()
	return bd.callbacks_chain_for_all_windows ? true : (window == bd.window)
}

glfw_window_focus_callback :: proc "c" (window: glfw.WindowHandle, focused: i32) {
	bd := glfw_get_backend_data()
	if bd.prev_user_callback_window_focus != nil && glfw_should_chain_callback(window) {
		bd.prev_user_callback_window_focus(window, focused)
	}
	io := get_io()
	io_add_focus_event(io, focused != 0)
}

glfw_cursor_enter_callback :: proc "c" (window: glfw.WindowHandle, entered: i32) {
	bd := glfw_get_backend_data()
	if bd.prev_user_callback_cursor_enter != nil && glfw_should_chain_callback(window) {
		bd.prev_user_callback_cursor_enter(window, entered)
	}
	io := get_io()
	if entered == 1 {
		bd.mouse_window = window
		io_add_mouse_pos_event(io, bd.last_valid_mouse_pos.x, bd.last_valid_mouse_pos.y)
	}
}

glfw_cursor_pos_callback :: proc "c" (window: glfw.WindowHandle, xpos, ypos: f64) {
	bd := glfw_get_backend_data()
	if bd.prev_user_callback_cursor_pos != nil && glfw_should_chain_callback(window) {
		bd.prev_user_callback_cursor_pos(window, xpos, ypos)
	}
	io := get_io()
	io_add_mouse_pos_event(io, f32(xpos), f32(ypos))
	bd.last_valid_mouse_pos = {f32(xpos), f32(ypos)}
}

glfw_mouse_button_callback :: proc "c" (window: glfw.WindowHandle, button, action, mods: i32) {
	bd := glfw_get_backend_data()
	if bd.prev_user_callback_mousebutton != nil && glfw_should_chain_callback(window) {
		bd.prev_user_callback_mousebutton(window, button, action, mods)
	}

	glfw_update_key_modifiers(window)

	io := get_io()
	if button >= 0 && button < MOUSE_BUTTON_COUNT {
		io_add_mouse_button_event(io, button, action == glfw.PRESS)
	}
}

glfw_scroll_callback :: proc "c" (window: glfw.WindowHandle, xoffset, yoffset: f64) {
	bd := glfw_get_backend_data()
	if bd.prev_user_callback_scroll != nil && glfw_should_chain_callback(window) {
		bd.prev_user_callback_scroll(window, xoffset, yoffset)
	}
	io := get_io()
	io_add_mouse_wheel_event(io, f32(xoffset), f32(yoffset))
}

glfw_key_to_imgui_key :: proc "contextless" (keycode, scancode: i32) -> Key {
	// odinfmt: disable
	switch keycode {
	case glfw.KEY_TAB:           return .Tab
	case glfw.KEY_LEFT:          return .LeftArrow
	case glfw.KEY_RIGHT:         return .RightArrow
	case glfw.KEY_UP:            return .UpArrow
	case glfw.KEY_DOWN:          return .DownArrow
	case glfw.KEY_PAGE_UP:       return .PageUp
	case glfw.KEY_PAGE_DOWN:     return .PageDown
	case glfw.KEY_HOME:          return .Home
	case glfw.KEY_END:           return .End
	case glfw.KEY_INSERT:        return .Insert
	case glfw.KEY_DELETE:        return .Delete
	case glfw.KEY_BACKSPACE:     return .Backspace
	case glfw.KEY_SPACE:         return .Space
	case glfw.KEY_ENTER:         return .Enter
	case glfw.KEY_ESCAPE:        return .Escape
	case glfw.KEY_APOSTROPHE:    return .Apostrophe
	case glfw.KEY_COMMA:         return .Comma
	case glfw.KEY_MINUS:         return .Minus
	case glfw.KEY_PERIOD:        return .Period
	case glfw.KEY_SLASH:         return .Slash
	case glfw.KEY_SEMICOLON:     return .Semicolon
	case glfw.KEY_EQUAL:         return .Equal
	case glfw.KEY_LEFT_BRACKET:  return .LeftBracket
	case glfw.KEY_BACKSLASH:     return .Backslash
	case glfw.KEY_RIGHT_BRACKET: return .RightBracket
	case glfw.KEY_GRAVE_ACCENT:  return .GraveAccent
	case glfw.KEY_CAPS_LOCK:     return .CapsLock
	case glfw.KEY_SCROLL_LOCK:   return .ScrollLock
	case glfw.KEY_NUM_LOCK:      return .NumLock
	case glfw.KEY_PRINT_SCREEN:  return .PrintScreen
	case glfw.KEY_PAUSE:         return .Pause
	case glfw.KEY_KP_0:          return .Keypad0
	case glfw.KEY_KP_1:          return .Keypad1
	case glfw.KEY_KP_2:          return .Keypad2
	case glfw.KEY_KP_3:          return .Keypad3
	case glfw.KEY_KP_4:          return .Keypad4
	case glfw.KEY_KP_5:          return .Keypad5
	case glfw.KEY_KP_6:          return .Keypad6
	case glfw.KEY_KP_7:          return .Keypad7
	case glfw.KEY_KP_8:          return .Keypad8
	case glfw.KEY_KP_9:          return .Keypad9
	case glfw.KEY_KP_DECIMAL:    return .KeypadDecimal
	case glfw.KEY_KP_DIVIDE:     return .KeypadDivide
	case glfw.KEY_KP_MULTIPLY:   return .KeypadMultiply
	case glfw.KEY_KP_SUBTRACT:   return .KeypadSubtract
	case glfw.KEY_KP_ADD:        return .KeypadAdd
	case glfw.KEY_KP_ENTER:      return .KeypadEnter
	case glfw.KEY_KP_EQUAL:      return .KeypadEqual
	case glfw.KEY_LEFT_SHIFT:    return .LeftShift
	case glfw.KEY_LEFT_CONTROL:  return .LeftCtrl
	case glfw.KEY_LEFT_ALT:      return .LeftAlt
	case glfw.KEY_LEFT_SUPER:    return .LeftSuper
	case glfw.KEY_RIGHT_SHIFT:   return .RightShift
	case glfw.KEY_RIGHT_CONTROL: return .RightCtrl
	case glfw.KEY_RIGHT_ALT:     return .RightAlt
	case glfw.KEY_RIGHT_SUPER:   return .RightSuper
	case glfw.KEY_MENU:          return .Menu
	case glfw.KEY_0:             return ._0
	case glfw.KEY_1:             return ._1
	case glfw.KEY_2:             return ._2
	case glfw.KEY_3:             return ._3
	case glfw.KEY_4:             return ._4
	case glfw.KEY_5:             return ._5
	case glfw.KEY_6:             return ._6
	case glfw.KEY_7:             return ._7
	case glfw.KEY_8:             return ._8
	case glfw.KEY_9:             return ._9
	case glfw.KEY_A:             return .A
	case glfw.KEY_B:             return .B
	case glfw.KEY_C:             return .C
	case glfw.KEY_D:             return .D
	case glfw.KEY_E:             return .E
	case glfw.KEY_F:             return .F
	case glfw.KEY_G:             return .G
	case glfw.KEY_H:             return .H
	case glfw.KEY_I:             return .I
	case glfw.KEY_J:             return .J
	case glfw.KEY_K:             return .K
	case glfw.KEY_L:             return .L
	case glfw.KEY_M:             return .M
	case glfw.KEY_N:             return .N
	case glfw.KEY_O:             return .O
	case glfw.KEY_P:             return .P
	case glfw.KEY_Q:             return .Q
	case glfw.KEY_R:             return .R
	case glfw.KEY_S:             return .S
	case glfw.KEY_T:             return .T
	case glfw.KEY_U:             return .U
	case glfw.KEY_V:             return .V
	case glfw.KEY_W:             return .W
	case glfw.KEY_X:             return .X
	case glfw.KEY_Y:             return .Y
	case glfw.KEY_Z:             return .Z
	case glfw.KEY_F1:            return .F1
	case glfw.KEY_F2:            return .F2
	case glfw.KEY_F3:            return .F3
	case glfw.KEY_F4:            return .F4
	case glfw.KEY_F5:            return .F5
	case glfw.KEY_F6:            return .F6
	case glfw.KEY_F7:            return .F7
	case glfw.KEY_F8:            return .F8
	case glfw.KEY_F9:            return .F9
	case glfw.KEY_F10:           return .F10
	case glfw.KEY_F11:           return .F11
	case glfw.KEY_F12:           return .F12
	case glfw.KEY_F13:           return .F13
	case glfw.KEY_F14:           return .F14
	case glfw.KEY_F15:           return .F15
	case glfw.KEY_F16:           return .F16
	case glfw.KEY_F17:           return .F17
	case glfw.KEY_F18:           return .F18
	case glfw.KEY_F19:           return .F19
	case glfw.KEY_F20:           return .F20
	case glfw.KEY_F21:           return .F21
	case glfw.KEY_F22:           return .F22
	case glfw.KEY_F23:           return .F23
	case glfw.KEY_F24:           return .F24
    }
	// odinfmt: enable
	return .None
}

glfw_key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	bd := glfw_get_backend_data()
	if bd.prev_user_callback_key != nil && glfw_should_chain_callback(window) {
		bd.prev_user_callback_key(window, key, scancode, action, mods)
	}

	if action != glfw.PRESS && action != glfw.RELEASE {
		return
	}

	glfw_update_key_modifiers(window)

	// keycode := glfw_translate_untranslated_key(keycode, scancode)

	io := get_io()
	imgui_key := glfw_key_to_imgui_key(key, scancode)
	io_add_key_event(io, imgui_key, action == glfw.PRESS)
	io_set_key_event_native_data(io, imgui_key, key, scancode)
}

glfw_char_callback :: proc "c" (window: glfw.WindowHandle, codepoint: rune) {
	bd := glfw_get_backend_data()
	if bd.prev_user_callback_char != nil && glfw_should_chain_callback(window) {
		bd.prev_user_callback_char(window, codepoint)
	}
	io := get_io()
	io_add_input_character(io, u32(codepoint))
}

glfw_monitor_callback :: proc "c" (window: glfw.WindowHandle, event: i32) {
	bd := glfw_get_backend_data()
	if bd.prev_user_callback_monitor != nil && glfw_should_chain_callback(window) {
		bd.prev_user_callback_monitor(window, event)
	}
	// TODO
}

glfw_new_frame :: proc "contextless" () {
	bd := glfw_get_backend_data()
	assert_contextless(
		bd != nil,
		"Context or backend not initialized! Did you call ImGui_ImplGlfw_InitForXXX()?",
	)
	io := get_io()

	// Setup display size (every frame to accommodate for window resizing)
	w, h := glfw.GetWindowSize(bd.window)
	display_w, display_h := glfw.GetFramebufferSize(bd.window)
	io.display_size = {f32(w), f32(h)}
	if w > 0 && h > 0 {
		io.display_framebuffer_scale = {f32(display_w) / f32(w), f32(display_h) / f32(h)}
	}

	// Setup time step
	// (Accept glfwGetTime() not returning a monotonically increasing value. Seems to happens on
	// disconnecting peripherals and probably on VMs and Emscripten,
	// See #6491, #6189, #6114, #3644)
	current_time := glfw.GetTime()
	if current_time <= bd.time {
		current_time = bd.time + 0.00001
	}
	io.delta_time = bd.time > 0.0 ? f32((current_time - bd.time)) : f32((1.0 / 60.0))
	bd.time = current_time

	glfw_update_mouse_data()
	glfw_update_mouse_cursor()

	// Update game controllers (if enabled and available)
	glfw_update_gamepads()
}

glfw_update_mouse_data :: proc "contextless" () {
	bd := glfw_get_backend_data()
	io := get_io()

	is_window_focused := glfw.GetWindowAttrib(bd.window, glfw.FOCUSED) != 0

	if is_window_focused {
		// (Optional) Set OS mouse position from Dear ImGui if requested (rarely used, only when
		// io.ConfigNavMoveSetMousePos is enabled by user)
		if io.want_set_mouse_pos {
			glfw.SetCursorPos(bd.window, f64(io.mouse_pos.x), f64(io.mouse_pos.y))
		}

		// (Optional) Fallback to provide mouse position when focused
		// ImGui_ImplGlfw_CursorPosCallback already provides this when hovered or captured)
		if bd.mouse_window == nil {
			mouse_x, mouse_y := glfw.GetCursorPos(bd.window)
			bd.last_valid_mouse_pos = {f32(mouse_x), f32(mouse_y)}
			io_add_mouse_pos_event(io, f32(mouse_x), f32(mouse_y))
		}
	}
}

glfw_update_mouse_cursor :: proc "contextless" () {
	bd := glfw_get_backend_data()
	io := get_io()

	if .NoMouseCursorChange in io.config_flags ||
	   glfw.GetInputMode(bd.window, glfw.CURSOR) == glfw.CURSOR_DISABLED {
		return
	}

	imgui_cursor := get_mouse_cursor()

	if imgui_cursor == .None || io.mouse_draw_cursor {
		// Hide OS mouse cursor if imgui is drawing it or if it wants no cursor
		glfw.SetInputMode(bd.window, glfw.CURSOR, glfw.CURSOR_HIDDEN)
	} else {
		// Show OS mouse cursor
		mouse_cursor := bd.mouse_cursors[imgui_cursor]
		glfw.SetCursor(
			bd.window,
			mouse_cursor if mouse_cursor != nil else bd.mouse_cursors[MouseCursor.Arrow],
		)
		glfw.SetInputMode(bd.window, glfw.CURSOR, glfw.CURSOR_NORMAL)
	}
}

glfw_update_key_modifiers :: proc "contextless" (window: glfw.WindowHandle) {
	io := get_io()
	io_add_key_event(
		io,
		Key(KEY_MOD_CTRL),
		(glfw.GetKey(window, glfw.KEY_LEFT_CONTROL) == glfw.PRESS) ||
		(glfw.GetKey(window, glfw.KEY_RIGHT_CONTROL) == glfw.PRESS),
	)
	io_add_key_event(
		io,
		Key(KEY_MOD_SHIFT),
		(glfw.GetKey(window, glfw.KEY_LEFT_SHIFT) == glfw.PRESS) ||
		(glfw.GetKey(window, glfw.KEY_RIGHT_SHIFT) == glfw.PRESS),
	)
	io_add_key_event(
		io,
		Key(KEY_MOD_ALT),
		(glfw.GetKey(window, glfw.KEY_LEFT_ALT) == glfw.PRESS) ||
		(glfw.GetKey(window, glfw.KEY_RIGHT_ALT) == glfw.PRESS),
	)
	io_add_key_event(
		io,
		Key(KEY_MOD_SUPER),
		(glfw.GetKey(window, glfw.KEY_LEFT_SUPER) == glfw.PRESS) ||
		(glfw.GetKey(window, glfw.KEY_RIGHT_SUPER) == glfw.PRESS),
	)
}

glfw_update_gamepads :: proc "contextless" () {
	// bd := glfw_get_backend_data()
	// io := get_io()
	// TODO
}

glfw_shutdown :: proc() {
	bd := glfw_get_backend_data()
	assert(bd != nil, "No platform backend to shutdown, or already shutdown?")
	io := get_io()

	if bd.installed_callbacks {
		glfw_restore_callbacks(bd.window)
	}

	for &cursor in bd.mouse_cursors {
		glfw.DestroyCursor(cursor)
	}

	when ODIN_OS == .Windows {
		main_viewport := get_main_viewport()
		win32.SetWindowLongPtrW(
			win32.HWND(main_viewport.platform_handle_raw),
			win32.GWLP_WNDPROC,
			transmute(win32.LONG_PTR)bd.prev_wnd_proc,
		)
		bd.prev_wnd_proc = nil
	}

	io.backend_platform_name = nil
	io.backend_platform_user_data = nil
	io.backend_flags -= {.HasMouseCursors, .HasSetMousePos, .HasGamepad}

	free(bd)
}
