#+build !js
package application

// Core
import "base:runtime"
import "core:log"

// Vendor
import "vendor:glfw"

// Libraries
import wgpu "../../"
import wgpu_glfw "../..//utils/glfw"

@(private, init)
_glfw_init :: proc "contextless" () {
    when ODIN_DEBUG {
        _glfw_error_proc :: proc "c" (error: i32, description: cstring) {
            runtime.print_string("[GLFW] --- [")
            runtime.print_int(int(error))
            runtime.print_string("]: ")
            runtime.print_string(string(description))
            runtime.print_string("\n")
        }
        glfw.SetErrorCallback(_glfw_error_proc)
    }
    ensure_contextless(bool(glfw.Init()), "Failed to initialize GLFW")
}

@(private, fini)
_glfw_fini :: proc "contextless" () {
    glfw.Terminate()
}

Window_Impl :: struct {
    using _base: Window_Base,
    handle:      glfw.WindowHandle,
}

@(require_results)
window_create :: proc(
    mode: Video_Mode,
    title: string,
    settings := WINDOW_SETTINGS_DEFAULT,
    allocator := context.allocator,
    loc := #caller_location,
) -> Window {
    assert(mode.width >= MIN_CLIENT_WIDTH, "Invalid window width", loc)
    assert(mode.height >= MIN_CLIENT_HEIGHT, "Invalid window height", loc)

    ensure(bool(glfw.Init()), "Failed to initialize GLFW", loc)

    impl := new(Window_Impl, allocator)
    ensure(impl != nil, "Failed to allocate the window implementation", loc)

    styles := settings.styles
    state := settings.state

    // Default fullscreen video mode
    desktop_mode := get_video_mode()

    mode := mode

    // Fullscreen style requires some tests
    if state == .Fullscreen {
        // Make sure that the chosen video mode is compatible
        if !video_mode_is_valid(mode) {
            log.warn("The requested video mode is not available, switching to default mode")
            mode = desktop_mode
        }
    } else {
        mode.refresh_rate = desktop_mode.refresh_rate // ensure valid refresh rate
    }

    impl.custom_context = context
    impl.custom_context.allocator = allocator
    impl.allocator = allocator
    impl.resize_callbacks.allocator = allocator
    impl.settings = settings

    monitor := glfw.GetPrimaryMonitor()

    glfw.WindowHint_int(glfw.CLIENT_API, glfw.NO_API)

    // Set window hints based on styles
    glfw.WindowHint_bool(glfw.RESIZABLE, .Resizable in styles)
    glfw.WindowHint_bool(glfw.DECORATED, !(.Borderless in styles))

    // Determine monitor and fullscreen mode
    target_monitor: glfw.MonitorHandle = nil
    switch state {
    case .Windowed: target_monitor = nil
    case .Fullscreen: target_monitor = monitor
    case .FullscreenBorderless:
        glfw.WindowHint_bool(glfw.DECORATED, false)
        // For borderless fullscreen, use desktop mode dimensions
        mode = desktop_mode
        styles += {.Centered}
    }

    if .Centered in styles {
        // Calculate the window centered position
        xpos, ypos, width, height := glfw.GetMonitorWorkarea(monitor)
        window_x := xpos + (width - i32(mode.width)) / 2
        glfw.WindowHint_int(glfw.POSITION_X, window_x)
        window_y := ypos + (height - i32(mode.height)) / 2
        glfw.WindowHint_int(glfw.POSITION_Y, window_y)
    }

    // Create the GLFW window
    string_buffer_init(&impl.title_buf, title)
    impl.handle = glfw.CreateWindow(
        i32(mode.width),
        i32(mode.height),
        string_buffer_get_cstring(&impl.title_buf),
        target_monitor,
        nil,
    )

    if impl.handle == nil {
        error_str, error_code := glfw.GetError()
        log.panicf("Failed to create window [%v]: %s", error_code, error_str, location = loc)
    }

    impl.mode = mode

    return cast(Window)impl
}

window_destroy :: proc(window: Window) {
    impl := _window_get_impl(window)
    _window_cleanup_callbacks(window)
    glfw.DestroyWindow(impl.handle)
    delete(impl.resize_callbacks)
    free(impl, impl.allocator)
}

window_process_events :: proc(window: Window) {
    glfw.PollEvents()
}

@(require_results)
window_poll_event :: proc(window: Window, event: ^Event) -> (ok: bool) {
    impl := _window_get_impl(window)
    if events_empty(&impl.events) {
        glfw.PollEvents()
    }
    event^, ok = events_poll(&impl.events)
    return
}

@(require_results)
window_get_handle :: proc "contextless" (window: Window) -> glfw.WindowHandle {
    impl := _window_get_impl(window)
    return impl.handle
}

@(require_results)
window_get_size :: proc(window: Window) -> Vec2u {
    impl := _window_get_impl(window)
    w, h := glfw.GetFramebufferSize(impl.handle)
    return {u32(w), u32(h)}
}

@(require_results)
window_get_title :: proc(window: Window) -> string {
    impl := _window_get_impl(window)
    return string(glfw.GetWindowTitle(impl.handle))
}

window_set_title_string :: proc(window: Window, title: string) {
    impl := _window_get_impl(window)
    string_buffer_init(&impl.title_buf, title)
    window_set_title_cstring(window, string_buffer_get_cstring(&impl.title_buf))
}

window_set_title_cstring :: proc(window: Window, title: cstring) {
    impl := _window_get_impl(window)
    glfw.SetWindowTitle(impl.handle, title)
}

window_set_title :: proc {
    window_set_title_string,
    window_set_title_cstring,
}

window_get_surface :: proc(window: Window, instance: wgpu.Instance) -> wgpu.Surface {
    impl := _window_get_impl(window)
    return wgpu_glfw.create_surface(impl.handle, instance)
}

// -----------------------------------------------------------------------------
// @(private)
// -----------------------------------------------------------------------------

@(private, require_results)
_window_get_user_pointer :: #force_inline proc "c" (
    handle: glfw.WindowHandle,
    loc := #caller_location,
) -> ^Window_Impl {
    window := cast(^Window_Impl)glfw.GetWindowUserPointer(handle)
    assert_contextless(window != nil, "Invalid Window pointer", loc)
    return window
}

@(private)
_window_setup_callbacks :: proc(window: Window) {
    impl := _window_get_impl(window)

    glfw.SetWindowUserPointer(impl.handle, impl)

    // Setup callbacks to populate event queue
    glfw.SetWindowCloseCallback(impl.handle, _window_close_callback)
    glfw.SetFramebufferSizeCallback(impl.handle, _window_framebuffer_size_callback)
    glfw.SetKeyCallback(impl.handle, _window_key_callback)
    glfw.SetCursorPosCallback(impl.handle, _window_cursor_position_callback)
    glfw.SetMouseButtonCallback(impl.handle, _window_mouse_button_callback)
    glfw.SetScrollCallback(impl.handle, _window_scroll_callback)
    glfw.SetWindowIconifyCallback(impl.handle, _window_minimized_callback)
    glfw.SetWindowFocusCallback(impl.handle, _window_focus_callback)
}

@(private)
_window_cleanup_callbacks :: proc(window: Window) {
}

@(private = "file")
_window_close_callback :: proc "c" (handle: glfw.WindowHandle) {
    dispatch_event(Quit_Event{})
}

@(private)
_window_framebuffer_size_callback :: proc "c" (handle: glfw.WindowHandle, width, height: i32) {
    impl := _window_get_user_pointer(handle)
    window := cast(Window)impl

    context = impl.custom_context

    new_size := Vec2u{u32(width), u32(height)}
    impl.aspect = f32(width) / f32(height)

    // First execute all registered resize callbacks immediately.
    //
    // GLFW blocks the calling thread during window resizing, but continues to
    // invoke this callback. To avoid stacking multiple resize events, user
    // callbacks are invoked immediately rather than being queued.
    for &cb in impl.resize_callbacks {
        if cb.callback != nil {
            cb.callback(window, new_size, cb.userdata)
        }
    }

    dispatch_event(Resize_Event{ new_size })
}

@(private)
_window_key_callback :: proc "c" (handle: glfw.WindowHandle, key, scancode, action, mods: i32) {
    // impl := _window_get_user_pointer(handle)
    // window := cast(Window)impl

    event := Key_Event{
        key      = _to_key(key),
        scancode = Scancode(scancode),
        ctrl     = mods & glfw.MOD_CONTROL != 0,
        shift    = mods & glfw.MOD_SHIFT != 0,
        alt      = mods & glfw.MOD_ALT != 0,
    }

    if action == glfw.PRESS {
        dispatch_event(Key_Pressed_Event(event))
    } else {
        dispatch_event(Key_Released_Event(event))
    }
}

@(private)
_window_cursor_position_callback :: proc "c" (handle: glfw.WindowHandle, xpos, ypos: f64) {
    // impl := _window_get_user_pointer(handle)
    // window := cast(Window)impl

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

    dispatch_event(Mouse_Moved_Event {
        pos    = {f32(xpos), f32(ypos)},
        button = button,
        action = action,
    })
}

@(private)
_window_mouse_button_callback :: proc "c" (handle: glfw.WindowHandle, button, action, mods: i32) {
    // impl := _window_get_user_pointer(handle)
    // window := cast(Window)impl

    xpos, ypos := glfw.GetCursorPos(handle)

    event := Mouse_Button_Event {
        button = Mouse_Button(button),
        pos    = {f32(xpos), f32(ypos)},
    }

    if action == glfw.PRESS {
        dispatch_event(Mouse_Button_Pressed_Event(event))
    } else if action == glfw.RELEASE {
        dispatch_event(Mouse_Button_Released_Event(event))
    }
}

@(private)
_window_scroll_callback :: proc "c" (handle: glfw.WindowHandle, xoffset, yoffset: f64) {
    // impl := _window_get_user_pointer(handle)
    // window := cast(Window)impl

    dispatch_event(Mouse_Wheel_Event{f32(xoffset), f32(yoffset)})
}

@(private)
_window_minimized_callback:: proc "c" (handle: glfw.WindowHandle, iconified: i32) {
    impl := _window_get_user_pointer(handle)
    // window := cast(Window)impl

    impl.is_minimized = bool(iconified)
    dispatch_event(Minimized_Event{ impl.is_minimized })
}

@(private)
_window_focus_callback :: proc "c" (handle: glfw.WindowHandle, focused: i32) {
    // impl := _window_get_user_pointer(handle)
    // window := cast(Window)impl

    dispatch_event(Restored_Event{bool(focused)})
}
