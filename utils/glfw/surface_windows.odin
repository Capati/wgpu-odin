#+build windows
package wgpu_glfw

// Core
import win "core:sys/windows"

// Vendor
import "vendor:glfw"

// Local packages
import wgpu "../../"

GetSurfaceDescriptor :: proc "c" (
	window: glfw.WindowHandle,
) -> (
	descriptor: wgpu.SurfaceDescriptor,
) {
	instance := win.GetModuleHandleW(nil)

	// Setup surface information
	descriptor.target = wgpu.SurfaceSourceWindowsHWND {
		hinstance = instance,
		hwnd      = glfw.GetWin32Window(window),
	}

	return
}
