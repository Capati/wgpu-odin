#+private
#+build windows
package renderlink

// STD Library
import win "core:sys/windows"

// Vendor
import sdl "vendor:sdl2"

_win_event_watch :: proc "c" (userdata: rawptr, event: ^sdl.Event) -> i32 {
	if event.type == .SYSWMEVENT {
		win_message := event.syswm.msg.msg.win
		if win_message.msg == win.WM_ENTERSIZEMOVE {
			g_app.events.window_dragging = true
		} else if win_message.msg == win.WM_EXITSIZEMOVE {
			g_app.events.window_dragging = false
		}
	}
	return 0
}
