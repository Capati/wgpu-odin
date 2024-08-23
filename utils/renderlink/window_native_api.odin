//+build linux, darwin, windows
package application

// STD Library
import "base:runtime"
import "core:log"
import "core:mem"
import "core:strings"

// Vendor
import sdl "vendor:sdl2"

// Local Packages
import wgpu_sdl "./../../utils/sdl"
import wgpu "./../../wrapper"

Window_State :: struct {
	using _base  : Window,
	handle       : ^sdl.Window,
}

when WINDOW_PACKAGE {
	@(require_results)
	_window_init :: proc(
		settings: Window_Settings,
		allocator: mem.Allocator,
	) -> (
		ok: bool,
	) {
		if sdl.Init(SDL_INIT_FLAGS) < 0 {
			log.errorf("Could not initialize SDL: [%s]", sdl.GetError())
			return
		}

		_window_set_display_sleep_enabled(false)

		_set_window(settings) or_return

		return true
	}

	_window_destroy :: proc() {
		w := &g_app.window

		if w.handle != nil {
			sdl.DestroyWindow(w.handle)
			sdl.FlushEvent(.WINDOWEVENT)
		}

		w.open = false

		sdl.Quit()
	}

	_window_from_pixels_value :: proc "contextless" (pixel_value: f32) -> f32 {
		return pixel_value / _window_get_dpi_scale()
	}

	_window_from_pixels_values :: proc "contextless" (px, py: f32) -> (wx, wy: f32) {
		scale := _window_get_dpi_scale()
		wx = px / scale
		wy = py / scale
		return
	}

	_window_from_pixels :: proc {
		_window_from_pixels_value,
		_window_from_pixels_values,
	}

	_window_get_dpi_scale :: proc "contextless" () -> f32 {
		return g_app.window.use_dpi_scale ? _get_dpi_scale() : 1.0
	}

	_window_get_size :: proc "contextless" () -> Window_Size {
		return g_app.window.size
	}

	_window_get_desktop_dimensions :: proc "contextless" (
		display_index: i32 = 0,
	) -> (
		size: Window_Size,
	) {
		if display_index >= 0 && display_index < _window_get_display_count() {
			mode: sdl.DisplayMode
			sdl.GetDesktopDisplayMode(display_index, &mode)
			return {u32(mode.w), u32(mode.h)}
		}
		return
	}

	_window_get_display_count :: proc "contextless" () -> i32 {
		return sdl.GetNumVideoDisplays()
	}

	_window_get_display_name :: proc(display_index: i32) -> string {
		return string(sdl.GetDisplayName(display_index))
	}

	_window_get_display_orientation :: proc "contextless" (
		display_index: i32,
	) -> Display_Orientation {
		sdl_orientation := sdl.GetDisplayOrientation(display_index)

		#partial switch sdl_orientation {
		case .LANDSCAPE:
			return .Landscape
		case .LANDSCAPE_FLIPPED:
			return .Landscape_Flipped
		case .PORTRAIT:
			return .Portrait
		case .PORTRAIT_FLIPPED:
			return .Portrait_Flipped
		}

		return .Unknown
	}

	_window_get_fullscreen :: proc "contextless" () -> Fullscreen_State {
		return g_app.window.fullscreen
	}

	_window_get_fullscreen_modes :: proc(
		display_index: i32 = 0,
		filter_modes := true,
		allocator := context.allocator,
	) -> (
		modes: []Display_Settings,
		ok: bool,
	) {
		runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
		temp_modes: [dynamic]Display_Settings
		temp_modes.allocator = context.temp_allocator

		mode_count := sdl.GetNumDisplayModes(display_index)
		main_loop: for i in 0 ..< mode_count {
			mode: sdl.DisplayMode
			sdl.GetDisplayMode(display_index, i, &mode)

			// SDL2's display mode list has multiple entries for modes of the same
			// size with different bits per pixel, so we need to filter those out.
			if filter_modes {
				for &d in temp_modes {
					if d.width == mode.w && d.height == mode.h {
						continue main_loop
					}
				}
			}

			append(
				&temp_modes,
				Display_Settings {
					format = mode.format,
					width = mode.w,
					height = mode.h,
					refresh_rate = mode.refresh_rate,
				},
			)
		}

		modes = make([]Display_Settings, len(temp_modes), allocator)
		copy(modes, temp_modes[:])

		return
	}

	_window_get_icon :: proc "contextless" () {
	}

	_window_get_settings :: proc "contextless" () -> Window_Settings {
		return g_app.window.settings
	}

	_window_get_position :: proc "contextless" () -> (x, y, display_index: i32) {
		return _get_position()
	}

	_window_get_safe_area :: proc "contextless" () -> (x, y, w, h: i32) {
		dw, dh := _window_from_pixels(f32(g_app.window.pixel.width), f32(g_app.window.pixel.height))
		return 0, 0, i32(dw), i32(dh)
	}

	_window_get_title :: proc "contextless" () -> string {
		// return string(sdl.GetWindowTitle(g_app.window.handle))
		return g_app.window.title
	}

	_window_get_vsync_type :: proc "contextless" () -> Vsync_Mode {
		return .Off
	}

	_window_has_focus :: proc "contextless" () -> bool {
		return g_app.window.handle == sdl.GetKeyboardFocus()
	}

	_window_has_mouse_focus :: proc "contextless" () -> bool {
		return g_app.window.handle == sdl.GetMouseFocus()
	}

	_window_is_display_sleep_enabled :: proc "contextless" () -> bool {
		return bool(sdl.IsScreenSaverEnabled())
	}

	_window_is_maximized :: proc "contextless" () -> bool {
		flags := sdl.GetWindowFlags(g_app.window.handle)
		return (u32(sdl.WINDOW_MAXIMIZED) & flags) != 0
	}

	_window_is_minimized :: proc "contextless" () -> bool {
		flags := sdl.GetWindowFlags(g_app.window.handle)
		return (u32(sdl.WINDOW_MINIMIZED) & flags) != 0
	}

	_window_is_open :: proc "contextless" () -> bool {
		return g_app.window.open
	}

	_window_is_visible :: proc "contextless" () -> bool {
		flags := sdl.GetWindowFlags(g_app.window.handle)
		return (u32(sdl.WINDOW_SHOWN) & flags) != 0
	}

	_window_maximize :: proc "contextless" () {
		sdl.MaximizeWindow(g_app.window.handle)
		_update_settings(g_app.window.settings)
	}

	_window_minimize :: proc "contextless" () {
		sdl.MinimizeWindow(g_app.window.handle)
	}

	_window_request_attention :: proc "contextless" () {
		sdl.RaiseWindow(g_app.window.handle)
	}

	_window_restore :: proc "contextless" () {
		sdl.RestoreWindow(g_app.window.handle)
		_update_settings(g_app.window.settings)
	}

	_window_set_display_sleep_enabled :: proc "contextless" (enabled: bool) {
		if enabled {
			sdl.EnableScreenSaver()
		} else {
			sdl.DisableScreenSaver()
		}
	}

	_window_set_fullscreen :: proc "contextless" (state: Fullscreen_State) -> bool {
		new_settings := g_app.window.settings
		new_settings.fullscreen = state

		flags: sdl.WindowFlags

		if state.enabled {
			if state.type == .Desktop {
				flags += {._INTERNAL_FULLSCREEN_DESKTOP}
			} else {
				flags += {.FULLSCREEN}

				mode: sdl.DisplayMode
				mode.w = i32(g_app.window.size.width)
				mode.h = i32(g_app.window.size.height)

				sdl.GetClosestDisplayMode(sdl.GetWindowDisplayIndex(g_app.window.handle), &mode, &mode)
				sdl.SetWindowDisplayMode(g_app.window.handle, &mode)
			}
		}

		if sdl.SetWindowFullscreen(g_app.window.handle, flags) == 0 {
			_update_settings(new_settings)
			return true
		}

		return false
	}

	// window_set_icon :: proc "contextless" (icon: ^sdl.Surface) {
	// 	sdl.SetWindowIcon(window.handle, icon)
	// }

	_window_set_settings :: proc "contextless" (settings: Window_Settings) {
		_update_settings(settings)
		return
	}

	_window_set_position :: proc "contextless" (x, y, display_index: i32) {
		d_index := clamp(display_index, 0, _window_get_display_count() - 1)

		display_bounds: sdl.Rect
		sdl.GetDisplayBounds(d_index, &display_bounds)

		// The position needs to be in the global coordinate space.
		_x := x + display_bounds.x
		_y := y + display_bounds.y

		sdl.SetWindowPosition(g_app.window.handle, _x, _y)

		g_app.window.settings.use_position = true
	}

	_window_set_title_string :: proc(title: string) {
		runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
		c_title := strings.clone_to_cstring(title, context.temp_allocator)
		sdl.SetWindowTitle(g_app.window.handle, c_title)
		g_app.window.settings.title = title
	}

	_window_set_title_c_string :: proc "contextless" (title: cstring) {
		sdl.SetWindowTitle(g_app.window.handle, title)
	}

	_window_set_title :: proc {
		_window_set_title_string,
		_window_set_title_c_string,
	}

	_window_show_message_box :: proc(
		title, message: string,
		type: Window_Message_Box_Flags,
		attach_to_window: bool,
	) {
		runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

		c_title := strings.clone_to_cstring(title, context.temp_allocator)
		c_message := strings.clone_to_cstring(message, context.temp_allocator)

		_show_message_box_c_string(c_title, c_message, type, attach_to_window)
	}

	_window_to_pixels_units :: proc "contextless" (units: f32) -> f32 {
		return units * _window_get_dpi_scale()
	}

	_window_to_pixels_values :: proc "contextless" (wx, wy: f32) -> (px, py: f32) {
		scale := _window_get_dpi_scale()
		px = wx * scale
		py = wy * scale
		return
	}

	_window_to_pixels :: proc {
		_window_to_pixels_units,
		_window_to_pixels_values,
	}

	_window_set_mouse_grab :: proc "contextless" (grab: bool) {
		_set_mouse_grab(grab)
	}

	_window_is_mouse_grabbed :: proc "contextless" () -> bool {
		return _is_mouse_grabbed()
	}

	_window_clamp_position :: proc "contextless" (wx, wy: ^f32) {
		size := _get_size()

		if wx != nil {
			wx^ = clamp(wx^, 0.0, f32(size.width - 1))
		}

		if wy != nil {
			wy^ = clamp(wy^, 0.0, f32(size.height - 1))
		}
	}

	_window_to_dpi_coords :: proc "contextless" (x, y: ^f32) {
		px := x != nil ? x^ : 0.0
		py := y != nil ? y^ : 0.0

		_to_pixel_coords(&px, &py)

		dpix, dpiy := _window_from_pixels_values(px, py)

		if x != nil {
			x^ = dpix
		}

		if y != nil {
			y^ = dpiy
		}
	}

	_window_to_dpi_coords_from_int :: proc "contextless" (x, y: ^i32) {
		if x != nil {
			fx := f32(x^)
			_window_to_dpi_coords(&fx, nil)
			x^ = i32(fx)
		}

		if y != nil {
			fy := f32(y^)
			_window_to_dpi_coords(nil, &fy)
			y^ = i32(fy)
		}
	}

	_window_set_mouse_position :: proc "contextless" (x, y: f32) {
		x, y := x, y
		_dpi_to_coords(&x, &y)
		sdl.WarpMouseInWindow(g_app.window.handle, i32(x), i32(y))
		sdl.PumpEvents()
	}

	_window_create_wgpu_surface :: proc(instance: wgpu.Instance) -> (wgpu.Surface, bool) {
		return wgpu_sdl.create_surface(g_app.window.handle, instance)
	}
} else {
	_ :: runtime
	_ :: log
	_ :: strings
	_ :: wgpu_sdl
	_window_init :: proc(_: Window_Settings, _ := context.allocator) -> (ok: bool) {return}
	_window_destroy :: proc() {}
	_window_from_pixels_value :: proc "contextless" (_: f32) -> f32 {return 0}
	_window_from_pixels_values :: proc "contextless" (_, _: f32) -> (wx, wy: f32) {return}
	_window_from_pixels :: proc {
		_window_from_pixels_value,
		_window_from_pixels_values,
	}
	_window_get_desktop_dimensions :: proc "contextless" (
		_: i32 = 0,
	) -> (
		size: Window_Size,
	) {return}
	_window_get_size :: proc "contextless" () -> Window_Size {return {}}
	_window_get_display_count :: proc "contextless" () -> i32 {return 0}
	_window_get_display_name :: proc(_: i32) -> string {return ""}
	_window_get_display_orientation :: proc "contextless" (_: i32) -> Display_Orientation {
		return {}
	}
	_window_get_fullscreen :: proc "contextless" () -> Fullscreen_State {return {}}
	_window_get_fullscreen_modes :: proc(
		_: i32 = 0,
		_ := true,
		_ := context.allocator,
	) -> (
		modes: []Display_Settings,
		ok: bool,
	) {
		return
	}
	_window_get_icon :: proc "contextless" () {}
	_window_get_settings :: proc "contextless" () -> Window_Settings {return {}}
	_window_get_mode :: _window_get_settings
	_window_get_position :: proc "contextless" () -> (x, y, display_index: i32) {return}
	_window_get_safe_area :: proc "contextless" () -> (x, y, w, h: i32) {return}
	_window_get_title :: proc "contextless" () -> string {return ""}
	_window_get_vsync_type :: proc "contextless" () -> Vsync_Mode {return {}}
	_window_has_focus :: proc "contextless" () -> bool {return false}
	_window_has_mouse_focus :: proc "contextless" () -> bool {return false}
	_window_is_display_sleep_enabled :: proc "contextless" () -> bool {return false}
	_window_is_maximized :: proc "contextless" () -> bool {return false}
	_window_is_minimized :: proc "contextless" () -> bool {return false}
	_window_is_open :: proc "contextless" () -> bool {return false}
	_window_is_visible :: proc "contextless" () -> bool {return false}
	_window_maximize :: proc "contextless" () {}
	_window_minimize :: proc "contextless" () {}
	_window_request_attention :: proc "contextless" () {}
	_window_restore :: proc "contextless" () {}
	_window_set_display_sleep_enabled :: proc "contextless" (_: bool) {}
	_window_set_fullscreen :: proc "contextless" (_: Fullscreen_State) -> bool {return false}
	// window_set_icon ::
	_window_set_settings :: proc "contextless" (_: Window_Settings) {}
	_window_set_mode :: _window_set_settings
	_window_set_position :: proc "contextless" (_, _, _: i32) {}
	_window_set_title_string :: proc(_: string) {}
	_window_set_title_c_string :: proc(_: cstring) {}
	_window_set_title :: proc {
		_window_set_title_string,
		_window_set_title_c_string,
	}
	_window_show_message_box :: proc(_, _: string, _: Window_Message_Box_Flags, _: bool = true) {}
	_window_to_pixels_units :: proc "contextless" (_: f32) -> f32 {return 0.0}
	_window_to_pixels_values :: proc "contextless" (_, _: f32) -> (px, py: f32) {return}
	_window_to_pixels :: proc {
		_window_to_pixels_units,
		_window_to_pixels_values,
	}
	_window_set_mouse_position :: proc "contextless" (x, y: f32) {return}
	_window_set_mouse_x :: proc "contextless" (_: f32) {}
	_window_set_mouse_y :: proc "contextless" (_: f32) {}
	_window_clamp_position :: proc "contextless" (wx, wy: ^f32) {}
	_window_to_dpi_coords :: proc "contextless" (x, y: ^f32) {}
	_window_to_dpi_coords_from_int :: proc "contextless" (_, _: ^i32) {}
	_window_set_mouse_grab :: proc "contextless" (_: bool) {}
	_window_is_mouse_grabbed :: proc "contextless" () -> bool {return false}
	_window_create_wgpu_surface :: proc(_: wgpu.Instance) -> (wgpu.Surface, wgpu.Error) {
		return {}, nil
	}
}
