package application

Display_Settings :: struct {
	format:       u32,
	width:        i32,
	height:       i32,
	refresh_rate: i32,
}

Display_Mode :: enum u8 {
	Windowed,
	Fullscreen_State,
	Fullscreen_Borderless,
	Fullscreen_Stretch,
}

Fullscreen_Type :: enum u8 {
	Exclusive,
	Desktop,
}

Fullscreen_State :: struct {
	enabled: bool,
	type:    Fullscreen_Type,
}

Vsync_Mode :: enum u8 {
	Off,
	VSync,
	Adaptive_VSync,
	Triple_Buffering,
}

MSAA_Type :: enum u8 {
	None,
	x4,
	x8,
	x16,
}

Window_Size :: struct {
	width, height: u32,
}

Window_Settings :: struct {
	title:         string,
	size:          Window_Size,
	borderless:    bool,
	resizable:     bool,
	min_size:      Window_Size,
	fullscreen:    Fullscreen_State,
	centered:      bool,
	display_index: i32,
	use_dpi_scale: bool,
	refresh_rate:  f32,
	use_position:  bool,
	x, y:          i32,
}

Window_Message_Box_Flag :: enum u32 {
	_                     = 0,
	Error                 = 4,
	Warning               = 5,
	Information           = 6,
	Buttons_Left_To_Right = 7,
	Buttons_Right_To_Left = 8,
}

Window_Message_Box_Flags :: distinct bit_set[Window_Message_Box_Flag;u32]

Display_Orientation :: enum u8 {
	Unknown,
	Landscape,
	Landscape_Flipped,
	Portrait,
	Portrait_Flipped,
}

Window_Error :: enum u8 {
	None,
	Failed_To_Get_Display_Mode,
	Fullscreen_Mode_Failed,
	No_Displays_Available,
	Window_Creation_Failed,
}

DEFAULT_FULLSCREEN :: Fullscreen_State {
	enabled = false,
	type    = .Desktop,
}

DEFAULT_WINDOW_SETTINGS :: Window_Settings {
	title         = "Untitled",
	fullscreen    = DEFAULT_FULLSCREEN,
	resizable     = false,
	size          = {800, 600},
	min_size      = {1, 1},
	borderless    = false,
	centered      = true,
	display_index = 0,
	use_dpi_scale = true,
	refresh_rate  = 0.0,
	use_position  = false,
	x             = 0,
	y             = 0,
}

Window :: struct {
	using settings: Window_Settings,
	pixel:          Window_Size,
	open:           bool,
	mouse_grabbed:  bool,
}

window_from_pixels_value :: _window_from_pixels_value

window_from_pixels_values :: _window_from_pixels_values

// Converts a number from pixels to density-independent units.
window_from_pixels :: proc {
	window_from_pixels_value,
	window_from_pixels_values,
}

// Gets the width and height of the desktop.
window_get_desktop_dimensions :: _window_get_desktop_dimensions

// Gets the width and height of the _window_
window_get_size :: _window_get_size

// Gets the number of connected monitors.
window_get_display_count :: _window_get_display_count

// Gets the name of a display.
window_get_display_name :: _window_get_display_name

// Gets current device display orientation.
window_get_display_orientation :: _window_get_display_orientation

// Gets whether the window is fullscreen.
window_get_fullscreen :: _window_get_fullscreen

// Gets a list of supported fullscreen modes.
window_get_fullscreen_modes :: _window_get_fullscreen_modes

// Gets the window icon.
window_get_icon :: _window_get_icon

// Gets the display properties of the _window_
window_get_settings :: _window_get_settings

// Gets the display properties of the _window_
window_get_mode :: window_get_settings

// Gets the position of the window on the screen.
window_get_position :: _window_get_position

// Gets unobstructed area inside the _window_
window_get_safe_area :: _window_get_safe_area

// Gets the window title.
window_get_title :: _window_get_title

// Gets current vsync type.
window_get_vsync_type :: _window_get_vsync_type

// Checks if the game window has keyboard focus.
window_has_focus :: _window_has_focus

// Checks if the game window has mouse focus.
window_has_mouse_focus :: proc "contextless" () -> bool {
	when MOUSE_PACKAGE {
		return _window_has_mouse_focus()
	}
	return false
}

// Gets whether the display is allowed to sleep while the program is running.
window_is_display_sleep_enabled :: _window_is_display_sleep_enabled

// Gets whether the Window is currently maximized.
window_is_maximized :: _window_is_maximized

// Gets whether the Window is currently minimized.
window_is_minimized :: _window_is_minimized

// Checks if the window is open.
window_is_open :: _window_is_open

// Checks if the game window is visible.
window_is_visible :: _window_is_visible

// Makes the window as large as possible.
window_maximize :: _window_maximize

// Minimizes the window to the system's task bar / dock.
window_minimize :: _window_minimize

// Causes the window to request the attention of the user if it is not in the foreground.
window_request_attention :: _window_request_attention

// Restores the size and position of the window if it was minimized or maximized.
window_restore :: _window_restore

// Sets whether the display is allowed to sleep while the program is running.
window_set_display_sleep_enabled :: _window_set_display_sleep_enabled

// Enters or exits fullscreen.
window_set_fullscreen :: _window_set_fullscreen

// Sets the window icon.
// window_set_icon :: _window_set_icon

// Sets the display mode and properties of the _window_
window_set_settings :: _window_set_settings
window_set_mode :: window_set_settings

// Sets the position of the window on the screen.
window_set_position :: _window_set_position

// Sets the window title.
window_set_title :: _window_set_title_string

// Sets the window title.
window_set_title_c_string :: _window_set_title_c_string

// Displays a message box above the _window_
window_show_message_box :: _window_show_message_box

window_to_pixels_units :: _window_to_pixels_units

window_to_pixels_values :: _window_to_pixels_values

// Converts a number from density-independent units to pixels.
window_to_pixels :: proc {
	window_to_pixels_units,
	window_to_pixels_values,
}

window_set_mouse_position :: proc "contextless" (pos: Mouse_Position) {
	when MOUSE_PACKAGE {
		_window_set_mouse_position(pos.x, pos.y)
	}
}

window_set_mouse_x :: proc "contextless" (x: f32) {
	when MOUSE_PACKAGE {
		pos := mouse_get_position()
		pos.x = x
		window_set_mouse_position(pos)
	}
}

window_set_mouse_y :: proc "contextless" (y: f32) {
	when MOUSE_PACKAGE {
		pos := mouse_get_position()
		pos.y = y
		window_set_mouse_position(pos)
	}
}

window_clamp_position :: _window_clamp_position

window_to_dpi_coords :: _window_to_dpi_coords

window_to_dpi_coords_from_int :: _window_to_dpi_coords_from_int

window_set_mouse_grab :: proc "contextless" (grab: bool) {
	when MOUSE_PACKAGE {
		_window_set_mouse_grab(grab)
	}
}

window_is_mouse_grabbed :: proc "contextless" () -> bool {
	when MOUSE_PACKAGE {
		return _window_is_mouse_grabbed()
	}
	return false
}
