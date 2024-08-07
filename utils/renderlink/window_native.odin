//+private
//+build linux, darwin, windows
package application

// STD Library
import "base:runtime"
import "core:log"
import "core:strings"

// Vendor
import sdl "vendor:sdl2"

MIN_WINDOW_DIMENSION :: 1
SDL_INIT_FLAGS :: sdl.InitFlags{.VIDEO}

_set_window :: proc(settings: Window_Settings) -> (err: Error) {
	settings := settings

	// Ensure minimum window dimensions
	settings.min_size.width = max(settings.min_size.width, MIN_WINDOW_DIMENSION)
	settings.min_size.height = max(settings.min_size.height, MIN_WINDOW_DIMENSION)

	// Get the number of available displays
	display_count := _window_get_display_count()
	if display_count < 1 {
		if display_count == 0 {
			log.error("No displays available")
		} else {
			log.errorf("Failed to get number of video displays: %s", sdl.GetError())
		}
		return .No_Displays_Available
	}

	// Ensure the chosen display index is valid
	// Note: display indices are 0-based, but display_count is 1-based,
	// we subtract 1 to get the maximum valid index
	settings.display_index = clamp(settings.display_index, 0, display_count - 1)

	// If no size is specified, use the current display's resolution
	if settings.size.width == 0 && settings.size.height == 0 {
		mode: sdl.DisplayMode
		if sdl.GetDesktopDisplayMode(settings.display_index, &mode) < 0 {
			log.errorf("Failed to get display mode: %s", sdl.GetError())
			return .Failed_To_Get_Display_Mode
		}
		settings.size = {u32(mode.w), u32(mode.h)}
	}

	x, y := _calculate_position(settings)

	// Handle fullscreen mode
	if settings.fullscreen.enabled && settings.fullscreen.type == .Exclusive {
		settings.size = _get_fullscreen_size(settings) or_return
	}

	// Create a new window or update an existing one
	if _is_open() {
		_update_existing_window(settings)
	} else {
		sdl_flags := _get_sdl_flags(settings)
		_create_window(
			settings.title,
			x,
			y,
			i32(settings.size.width),
			i32(settings.size.height),
			sdl_flags,
		) or_return
	}

	_update_settings(settings)
	_set_mouse_grab(g_window.mouse_grabbed)

	sdl.SetWindowMinimumSize(
		g_window.handle,
		i32(settings.min_size.width),
		i32(settings.min_size.height),
	)

	if g_window.settings.display_index != settings.display_index ||
	   settings.use_position ||
	   settings.centered {
		sdl.SetWindowPosition(g_window.handle, x, y)
	}

	// Bring window to front
	sdl.RaiseWindow(g_window.handle)

	return
}

_calculate_position :: proc(settings: Window_Settings) -> (x, y: i32) {
	if settings.use_position {
		// If a specific position is requested, adjust for the display's position
		display_bounds: sdl.Rect
		sdl.GetDisplayBounds(settings.display_index, &display_bounds)
		x = i32(settings.x) + display_bounds.x
		y = i32(settings.y) + display_bounds.y
	} else if settings.centered {
		// Center the window on the chosen display
		x = sdl.WINDOWPOS_CENTERED_DISPLAY(settings.display_index)
		y = sdl.WINDOWPOS_CENTERED_DISPLAY(settings.display_index)
	} else {
		// Let the system decide (usually top-left of the chosen display)
		x = sdl.WINDOWPOS_UNDEFINED_DISPLAY(settings.display_index)
		y = sdl.WINDOWPOS_UNDEFINED_DISPLAY(settings.display_index)
	}

	return
}

// Translates our settings into SDL-specific window flags
_get_sdl_flags :: proc(settings: Window_Settings) -> sdl.WindowFlags {
	flags: sdl.WindowFlags
	if settings.fullscreen.enabled {
		if settings.fullscreen.type == .Exclusive {
			flags += {.FULLSCREEN}
		} else {
			flags += {._INTERNAL_FULLSCREEN_DESKTOP}
		}
	}
	if settings.resizable do flags += {.RESIZABLE}
	if settings.borderless do flags += {.BORDERLESS}
	return flags
}

// Determines the appropriate size for fullscreen mode
_get_fullscreen_size :: proc(settings: Window_Settings) -> (size: Window_Size, err: Error) {
	// Initialize the mode with the requested size
	mode: sdl.DisplayMode = {
		format       = 0, // We don't care about the pixel format here
		w            = i32(settings.size.width),
		h            = i32(settings.size.height),
		refresh_rate = 0, // We're not specifying a refresh rate
		driverdata   = nil,
	}

	// Try to find the closest matching display mode
	// GetClosestDisplayMode returns nil if it can't find a close enough match.
	// This can happen if we request a size larger than any available mode,
	// or if the display doesn't support the requested size at all.
	if sdl.GetClosestDisplayMode(settings.display_index, &mode, &mode) == nil {
		// As a fallback, we'll try to get the largest available mode for this display.
		// The first mode (index 0) is typically the largest/highest resolution mode.
		if sdl.GetDisplayMode(settings.display_index, 0, &mode) < 0 {
			log.errorf("Failed to get any display mode: %s", sdl.GetError())
			return {}, .Fullscreen_Mode_Failed
		}
	}

	// At this point, 'mode' contains either the closest match to our requested size,
	// or the largest available mode if no close match was found.

	size.width = u32(mode.w)
	size.height = u32(mode.h)

	return
}

// Modifies an already open window to match new settings
_update_existing_window :: proc(settings: Window_Settings) {
	if !settings.fullscreen.enabled {
		sdl.SetWindowSize(g_window.handle, i32(settings.size.width), i32(settings.size.height))
	}

	if g_window.resizable != settings.resizable {
		sdl.SetWindowResizable(g_window.handle, sdl.bool(settings.resizable))
	}

	if g_window.borderless != settings.borderless {
		sdl.SetWindowBordered(g_window.handle, sdl.bool(!settings.borderless))
	}
}

_update_settings :: proc "contextless" (
	new_settings: Window_Settings,
	update_renderer: bool = false,
) {
	g_window.title = new_settings.title

	// Get current window size
	window_width, window_height: i32
	sdl.GetWindowSize(g_window.handle, &window_width, &window_height)
	g_window.size = {u32(window_width), u32(window_height)}
	g_window.pixel = g_window.size

	// Get current window flags
	w_flags := sdl.GetWindowFlags(g_window.handle)

	// Update fullscreen state
	g_window.fullscreen = _get_fullscreen_state(w_flags, new_settings)

	// Update other window properties
	g_window.min_size = new_settings.min_size
	g_window.resizable = (w_flags & u32(sdl.WINDOW_RESIZABLE)) != 0
	g_window.borderless = (w_flags & u32(sdl.WINDOW_BORDERLESS)) != 0
	g_window.centered = new_settings.centered

	// Update window position and display index
	g_window.x, g_window.y, g_window.display_index = _get_position()
	g_window.use_dpi_scale = new_settings.use_dpi_scale

	// Set hint for minimizing on focus loss in fullscreen mode
	sdl.SetHint(
		sdl.HINT_VIDEO_MINIMIZE_ON_FOCUS_LOSS,
		g_window.fullscreen.enabled && g_window.fullscreen.type == .Exclusive ? "1" : "0",
	)

	// Get current display mode for refresh rate
	d_mode: sdl.DisplayMode
	sdl.GetCurrentDisplayMode(g_window.display_index, &d_mode)
	g_window.refresh_rate = f32(d_mode.refresh_rate)
}

_get_fullscreen_state :: proc "contextless" (
	w_flags: u32,
	new_settings: Window_Settings,
) -> (
	state: Fullscreen_State,
) {
	if (w_flags & u32(sdl.WINDOW_FULLSCREEN_DESKTOP)) == u32(sdl.WINDOW_FULLSCREEN_DESKTOP) {
		return {enabled = true, type = .Desktop}
	} else if (w_flags & u32(sdl.WINDOW_FULLSCREEN)) == u32(sdl.WINDOW_FULLSCREEN) {
		return {enabled = true, type = .Exclusive}
	} else {
		return {enabled = false, type = new_settings.fullscreen.type}
	}
}

_create_window :: proc(
	title: string,
	x, y, width, height: i32,
	flags: sdl.WindowFlags,
) -> (
	err: Error,
) {
	if g_window.handle != nil {
		sdl.DestroyWindow(g_window.handle)
		sdl.FlushEvent(.WINDOWEVENT)
		g_window.handle = nil
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	c_title := strings.clone_to_cstring(title, context.temp_allocator)

	g_window.handle = sdl.CreateWindow(c_title, x, y, width, height, flags)

	if g_window.handle == nil {
		log.errorf("Failed to create a SDL window: [%s]", sdl.GetError())
		return .Window_Creation_Failed
	}

	g_window.open = true

	return
}

_get_dpi_scale :: proc "contextless" () -> f32 {
	return f32(g_window.pixel.height) / f32(g_window.size.height)
}

_get_position :: proc "contextless" () -> (x, y, display_index: i32) {
	if g_window.handle == nil {
		return 0, 0, 0
	}

	display_index = max(sdl.GetWindowDisplayIndex(g_window.handle), 0)

	sdl.GetWindowPosition(g_window.handle, &x, &y)

	if x != 0 || y != 0 {
		display_bounds: sdl.Rect
		sdl.GetDisplayBounds(display_index, &display_bounds)
		x -= display_bounds.x
		y -= display_bounds.y
	}

	return
}

_is_open :: proc "contextless" () -> bool {
	return g_window.open
}

_show_message_box_c_string :: proc "contextless" (
	title, message: cstring,
	type: Window_Message_Box_Flags,
	attach_to_window: bool,
) {
	sdl.ShowSimpleMessageBox(
		transmute(sdl.MessageBoxFlags)type,
		title,
		message,
		g_window.handle if attach_to_window else nil,
	)
}

_get_size :: proc "contextless" () -> Window_Size {
	width, height: i32
	sdl.GetWindowSize(g_window.handle, &width, &height)
	return {cast(u32)width, cast(u32)height}
}

_get_mouse_position :: proc "contextless" () -> (x, y: i32) {
	sdl.GetMouseState(&x, &y)
	return
}

_to_pixel_coords :: proc "contextless" (x, y: ^f32) {
	if x != nil {
		x^ *= f32(g_window.pixel.width) / f32(g_window.size.width)
	}

	if y != nil {
		y^ *= f32(g_window.pixel.height) / f32(g_window.size.height)
	}
}

_pixel_to_coords :: proc "contextless" (x, y: ^f32) {
	if x != nil {
		x^ *= f32(g_window.size.width) / f32(g_window.pixel.width)
	}

	if y != nil {
		y^ *= f32(g_window.size.height) / f32(g_window.pixel.height)
	}
}

_dpi_to_coords :: proc "contextless" (x, y: ^f32) {
	dpix := x != nil ? x^ : 0.0
	dpiy := y != nil ? y^ : 0.0

	px, py := _to_pixels_values(dpix, dpiy)
	_pixel_to_coords(&px, &py)

	if x != nil do x^ = px
	if y != nil do y^ = py
}

_to_pixels_value :: proc(x: f32) -> f32 {
	return x * _get_dpi_scale()
}

_to_pixels_values :: proc "contextless" (wx, wy: f32) -> (px, py: f32) {
	scale := _get_dpi_scale()
	px = wx * scale
	py = wy * scale
	return
}

_to_pixels :: proc {
	_to_pixels_value,
	_to_pixels_values,
}

// _to_pixels_coords :: proc(x, y: ^f32) {
// 	size := _get_size()

// 	if wx != nil {
// 		wx^ = clamp(wx^, 0.0, f32(size.width - 1))
// 	}

// 	if wy != nil {
// 		wy^ = clamp(wy^, 0.0, f32(size.height - 1))
// 	}
// }

_set_mouse_grab :: proc "contextless" (grab: bool) {
	g_window.mouse_grabbed = grab
	sdl.SetWindowGrab(g_window.handle, sdl.bool(grab))
}

_is_mouse_grabbed :: proc "contextless" () -> bool {
	return bool(sdl.GetWindowGrab(g_window.handle))
}
