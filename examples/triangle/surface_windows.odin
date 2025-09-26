#+build windows
package triangle

// Core
import win32 "core:sys/windows"

// Vendor
import "vendor:glfw"

// Local packages
import wgpu "../.."

os_get_surface :: proc(instance: wgpu.Instance) -> (surface: wgpu.Surface) {
	return wgpu.InstanceCreateSurface(instance, {
		target = wgpu.SurfaceSourceWindowsHWND {
			hinstance = win32.GetModuleHandleW(nil),
			hwnd      = glfw.GetWin32Window(state.os.window),
		},
	})
}
