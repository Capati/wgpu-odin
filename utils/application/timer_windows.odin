#+build windows
package application

// Core
import win32 "core:sys/windows"

_win32_timer_init :: proc "contextless" (t: ^Timer) {
	win32.timeBeginPeriod(1)
}
