#+build windows
package triangle

// Packages
import win "core:sys/windows"
import "vendor:glfw"

// Local packages
import "root:wgpu"

get_surface_descriptor :: proc(window: glfw.WindowHandle) -> (descriptor: wgpu.SurfaceDescriptor) {
	instance := win.GetModuleHandleW(nil)

	// Setup surface information
	descriptor.target = wgpu.SurfaceSourceWindowsHWND {
		hinstance = instance,
		hwnd      = glfw.GetWin32Window(window),
	}

	return descriptor
}
