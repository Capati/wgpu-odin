package native_application

// Core
import "core:fmt"

// Vendor
import sdl "vendor:sdl2"

// Package
import "../core"
import "../events"

// Libs
import wgpu_sdl "../../../../utils/sdl"
import wgpu "../../../../wrapper"

Default_Physical_Size :: core.Default_Physical_Size
Physical_Size :: core.Physical_Size
Platform_Info :: core.Platform_Info

Display_Mode :: enum {
	Windowed,
	Fullscreen,
	Fullscreen_Borderless,
	Fullscreen_Stretch,
}

Native_Application :: struct {
	using properties: Native_Properties,
	events:           events.Event_List,
	window:           ^sdl.Window,
	is_minimized:     bool,
	system_info:      Platform_Info,
}

Native_Properties :: struct {
	offscreen:    bool,
	display_mode: Display_Mode,
	title:        cstring,
	size:         Physical_Size,
	resizable:    bool,
	decorated:    bool,
	centered:     bool,
}

Default_Native_Properties :: Native_Properties {
	offscreen    = false,
	display_mode = .Windowed,
	title        = "Native Game",
	size         = Default_Physical_Size,
	resizable    = true,
	decorated    = true,
	centered     = true,
}

@(private = "package")
_ctx: Native_Application

init :: proc(properties: Native_Properties) -> (err: core.Application_Error) {
	fmt.printf("Application \"%s\" init...\n", properties.title)

	sdl_flags := sdl.InitFlags{.VIDEO, .JOYSTICK, .GAMECONTROLLER, .EVENTS}

	if res := sdl.Init(sdl_flags); res != 0 {
		fmt.eprintf("Failed to initialize SDL: [%s]\n", sdl.GetError())
		return .Canvas_Failed
	}
	defer if err != nil do sdl.Quit()

	current_mode: sdl.DisplayMode
	if res := sdl.GetCurrentDisplayMode(0, &current_mode); res != 0 {
		fmt.eprintf("Failed to get current display mode: [%s]\n", sdl.GetError())
		return .Canvas_Failed
	}

	physical_size := properties.size

	window_flags := sdl.WindowFlags{.ALLOW_HIGHDPI}

	if properties.display_mode == .Windowed {
		window_flags += {.RESIZABLE} if properties.resizable else {}
		window_flags += {.BORDERLESS} if !properties.decorated else {}
	} else {
		window_flags += {.BORDERLESS}
	}

	#partial switch properties.display_mode {
	case .Fullscreen, .Fullscreen_Borderless:
		physical_size = {u32(current_mode.w), u32(current_mode.h)}
	}

	#partial switch properties.display_mode {
	case .Fullscreen, .Fullscreen_Stretch:
		window_flags += {.FULLSCREEN}
	}

	window_pos := properties.centered ? sdl.WINDOWPOS_CENTERED : sdl.WINDOWPOS_UNDEFINED

	_ctx.window = sdl.CreateWindow(
		properties.title,
		i32(window_pos),
		i32(window_pos),
		i32(physical_size.width),
		i32(physical_size.height),
		window_flags,
	)
	if _ctx.window == nil {
		fmt.eprintf("Failed to create a SDL window: [%s]\n", sdl.GetError())
		return .Canvas_Failed
	}
	defer if err != nil do sdl.DestroyWindow(_ctx.window)

	_ctx.properties = properties

	init_system_info() or_return

	if events, events_err := events.init_events(); events_err == .None {
		_ctx.events = events
	} else {
		fmt.eprintf("Failed to initialize events queue.\n")
		return .Init_Failed
	}

	fmt.printf("Application initialized successfully.\n\n")

	return
}

process_events :: proc() -> ^events.Event_List {
	// Process pending events...
	if _ctx.events.len > 0 {
		return &_ctx.events
	}

	e: sdl.Event
	for sdl.PollEvent(&e) {
		#partial switch (e.type) {
		case .QUIT:
			push_event(events.Quit_Event(true))

		case .TEXTINPUT:
			ev: events.Text_Input_Event
			copy(ev.buf[:], e.text.text[:])
			push_event(ev)

		case .KEYDOWN:
			if e.key.keysym.scancode == .ESCAPE {
				push_event(events.Quit_Event(true))
			}
			push_event(cast(events.Key_Press_Event)get_key_state(e.key))

		case .KEYUP:
			push_event(cast(events.Key_Release_Event)get_key_state(e.key))

		case .MOUSEBUTTONDOWN:
			push_event(cast(events.Mouse_Press_Event)get_mouse_state(e.button))

		case .MOUSEBUTTONUP:
			push_event(cast(events.Mouse_Release_Event)get_mouse_state(e.button))

		case .MOUSEMOTION:
			push_event(events.Mouse_Motion_Event{e.motion.x, e.motion.y})

		case .MOUSEWHEEL:
			push_event(events.Mouse_Scroll_Event{e.wheel.x, e.wheel.y})

		case .WINDOWEVENT:
			#partial switch (e.window.event) {
			case .SIZE_CHANGED:
			case .RESIZED:
				new_size := events.Framebuffer_Resize_Event {
					cast(u32)e.window.data1,
					cast(u32)e.window.data2,
				}

				// Avoid multiple .SIZE_CHANGED and .RESIZED events at the same time.
				if _ctx.properties.size.width != new_size.width ||
				   _ctx.properties.size.height != new_size.height {
					_ctx.properties.size = {new_size.width, new_size.height}
					push_event(new_size)
				}

			case .MINIMIZED:
				_ctx.is_minimized = true
				push_event(events.Minimized_Event{true})

			case .RESTORED:
				_ctx.is_minimized = false
				push_event(events.Minimized_Event{false})

			case .FOCUS_GAINED:
				push_event(events.Focus_Event{true})

			case .FOCUS_LOST:
				push_event(events.Focus_Event{false})
			}
		}
	}

	return &_ctx.events
}

push_event :: proc(event: events.Event) {
	events.push(&_ctx.events, event)
}

get_size :: proc "contextless" () -> Physical_Size {
	width, height: i32
	sdl.GetWindowSize(_ctx.window, &width, &height)
	return {cast(u32)width, cast(u32)height}
}

is_minimized :: #force_inline proc "contextless" () -> bool {
	return _ctx.is_minimized
}

get_system_info :: proc() -> Platform_Info {
	return _ctx.system_info
}

get_wgpu_surface :: proc(instance: wgpu.Instance) -> (wgpu.Surface, wgpu.Error) {
	return wgpu_sdl.create_surface(_ctx.window, instance)
}

deinit :: proc() {
	delete(_ctx.events.data)

	sdl.DestroyWindow(_ctx.window)
	sdl.Quit()
}

@(private)
init_system_info :: proc() -> core.Application_Error {
	wm_info: sdl.SysWMinfo
	sdl.GetVersion(&wm_info.version)

	if !sdl.GetWindowWMInfo(_ctx.window, &wm_info) {
		fmt.eprintf("Could not obtain SDL WM info from window.\n")
		return .Init_Failed
	}

	when ODIN_OS == .Windows {
		_ctx.system_info = {
			platform_tag = .Windows,
			windows = {window = wm_info.info.win.window, hinstance = wm_info.info.win.hinstance},
		}
	} else when ODIN_OS == .Darwin {
		_ctx.system_info = {
			platform_tag = .Cocoa,
			cocoa = {window = wm_info.info.cocoa.window},
		}
	} else when ODIN_OS == .Linux {
		if wm_info.subsystem == .X11 {
			_ctx.system_info = {
				platform_tag = .X11,
				x11 = {display = wm_info.info.x11.display, window = wm_info.info.x11.window},
			}
		} else if wm_info.subsystem == .WAYLAND {
			_ctx.system_info = {
				platform_tag = .Wayland,
				wayland = {display = wm_info.info.wl.display, surface = wm_info.info.wl.surface},
			}
		} else {
			return .Init_Failed, fmt.eprintf("Unsupported Unix platform!\n")
		}
	} else {
		#panic("Unsupported native platform!")
	}

	return .No_Error
}
