//+build linux, darwin, windows
package application

// STD Library
import "core:time"

// Vendor
import sdl "vendor:sdl2"

@(private)
g_mouse: Mouse_State

when MOUSE_PACKAGE {
	@(require_results)
	_mouse_init :: proc(allocator := context.allocator) -> (err: Error) {
		g_mouse.allocator = allocator
		g_mouse.system_cursors.allocator = allocator
		return
	}

	_mouse_destroy :: proc() {
		delete(g_mouse.system_cursors)
	}

	_mouse_update_state :: proc "contextless" () {
		g_mouse.previous_state = g_mouse.current_state
		x, y: i32
		g_mouse.current_state = sdl.GetMouseState(&x, &y)
		g_mouse.position = {f32(x), f32(y)}
	}

	_mouse_reset_state :: proc "contextless" () {
		g_mouse.previous_state = 0
		g_mouse.current_state = 0
	}

	@(require_results)
	_mouse_get_cursor :: proc "contextless" () -> rawptr {
		return sdl.GetCursor()
	}

	@(require_results)
	_mouse_get_position :: proc "contextless" () -> (position: Mouse_Position) {
		position = g_mouse.position
		when WINDOW_PACKAGE {
			window_clamp_position(&position.x, &position.y)
			window_to_dpi_coords(&position.x, &position.y)
		}
		return
	}

	@(require_results)
	_mouse_get_relative_mode :: proc "contextless" () -> bool {
		return bool(sdl.GetRelativeMouseMode())
	}

	@(require_results)
	_mouse_get_system_cursor :: proc "contextless" (cursor: System_Cursor) -> rawptr {
		sdl_cursor_type := _cursor_native_to_sdl(cursor)
		return sdl.CreateSystemCursor(sdl_cursor_type)
	}

	@(require_results)
	_mouse_get_x :: proc "contextless" () -> f32 {
		return mouse_get_position().x
	}

	@(require_results)
	_mouse_get_y :: proc "contextless" () -> f32 {
		return mouse_get_position().y
	}

	@(require_results)
	_mouse_is_cursor_supported :: proc "contextless" () -> bool {
		return sdl.GetDefaultCursor() != nil
	}

	@(require_results)
	_mouse_is_pressed :: proc "contextless" (buttons: ..Mouse_Button) -> bool {
		mask := _buttons_to_mask(..buttons)
		return (g_mouse.current_state & mask) != 0 && (g_mouse.previous_state & mask) == 0
	}

	@(require_results)
	_mouse_is_down :: proc "contextless" (buttons: ..Mouse_Button) -> bool {
		mask := _buttons_to_mask(..buttons)
		return (g_mouse.current_state & mask) != 0 && (g_mouse.previous_state & mask) != 0
	}

	@(require_results)
	_mouse_is_released :: proc "contextless" (buttons: ..Mouse_Button) -> bool #no_bounds_check {
		mask := _buttons_to_mask(..buttons)
		return (g_mouse.current_state & mask) == 0 && (g_mouse.previous_state & mask) != 0
	}

	@(require_results)
	_mouse_is_up :: proc "contextless" (buttons: ..Mouse_Button) -> bool {
		mask := _buttons_to_mask(..buttons)
		return (g_mouse.current_state & mask) == 0
	}

	@(require_results)
	_mouse_get_scroll :: proc "contextless" () -> Mouse_Position {
		return g_mouse.scroll
	}

	_mouse_is_grabbed :: proc "contextless" () -> bool {
		when WINDOW_PACKAGE {
			return window_is_mouse_grabbed()
		} else do return false
	}

	@(require_results)
	_mouse_is_visible :: proc "contextless" () -> bool {
		return sdl.ShowCursor(sdl.QUERY) == sdl.ENABLE
	}

	_mouse_set_cursor :: proc "contextless" (cursor: rawptr) {
		sdl.SetCursor(cast(^sdl.Cursor)cursor)
	}

	_mouse_set_grabbed :: proc "contextless" (grab: bool) {
		when WINDOW_PACKAGE {
			window_set_mouse_grab(grab)
		}
	}

	_mouse_set_position :: proc "contextless" (position: Mouse_Position) {
		when WINDOW_PACKAGE {
			window_set_mouse_position(position)
		}
	}

	_mouse_set_relative_mode :: proc "contextless" (enable: bool) {
		sdl.SetRelativeMouseMode(sdl.bool(enable))
	}

	_mouse_set_visible :: proc "contextless" (visible: bool) {
		sdl.ShowCursor(sdl.ENABLE if visible else sdl.DISABLE)
	}

	_mouse_mouse_set_x :: proc "contextless" (x: f32) {
		when WINDOW_PACKAGE {
			window_set_mouse_x(x)
		}
	}

	_mouse_mouse_set_y :: proc "contextless" (y: f32) {
		when WINDOW_PACKAGE {
			window_set_mouse_y(y)
		}
	}

	@(require_results)
	_mouse_is_double_click :: proc "contextless" () -> bool {
		diff := time.diff(g_mouse.tracker.last_click_time, time.now())
		if time.duration_milliseconds(diff) > MULTI_CLICK_TIME_MS {
			return false
		}
		return g_mouse.tracker.click_count == 2
	}
} else {
	_ :: sdl
	_ :: time
	_mouse_init :: proc(_ := context.allocator) -> (err: Error) {return}
	_mouse_destroy :: proc() {}
	_mouse_update_state :: proc() {}
	_mouse_reset_state :: proc "contextless" () {}
	_mouse_get_cursor :: proc "contextless" () -> rawptr {return nil}
	_mouse_get_position :: proc "contextless" () -> Mouse_Position {return {}}
	_mouse_get_relative_mode :: proc "contextless" () -> bool {return false}
	_mouse_get_system_cursor :: proc "contextless" (_: System_Cursor) -> rawptr {return nil}
	_mouse_get_x :: proc "contextless" () -> f32 {return 0.0}
	_mouse_get_y :: proc "contextless" () -> f32 {return 0.0}
	_mouse_is_cursor_supported :: proc "contextless" () -> bool {return false}
	_mouse_is_pressed :: proc "contextless" (_: ..Mouse_Button) -> bool {return false}
	_mouse_is_down :: proc "contextless" (_: ..Mouse_Button) -> bool {return false}
	_mouse_is_released :: proc "contextless" (_: ..Mouse_Button) -> bool {return false}
	_mouse_is_up :: proc "contextless" (_: ..Mouse_Button) -> bool {return false}
	_mouse_get_scroll :: proc "contextless" () -> Mouse_Position {return {}}
	_mouse_is_grabbed :: proc "contextless" () -> bool {return false}
	_mouse_is_visible :: proc "contextless" () -> bool {return false}
	_mouse_set_cursor :: proc "contextless" (_: rawptr) {}
	_mouse_set_grabbed :: proc "contextless" (_: bool) {}
	_mouse_set_position :: proc "contextless" (_: Mouse_Position) {}
	_mouse_set_relative_mode :: proc "contextless" (_: bool) {}
	_mouse_set_visible :: proc "contextless" (_: bool) {}
	_mouse_set_x :: proc "contextless" (_: f32) {}
	_mouse_set_y :: proc "contextless" (_: f32) {}
	_mouse_is_double_click :: proc "contextless" () -> bool {return false}
}
