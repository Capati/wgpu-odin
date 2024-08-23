//+build windows
package wgpu_utils_glfw

// STD Library
import win "core:sys/windows"

// Vendor
import "vendor:glfw"

// Local packages
import wgpu "../../wrapper"

get_surface_descriptor :: proc(
	window: glfw.WindowHandle,
) -> (
	descriptor: wgpu.Surface_Descriptor,
	ok: bool,
) {
	instance := win.GetModuleHandleW(nil)

	// Setup surface information
	descriptor.target = wgpu.Surface_Descriptor_From_Windows_HWND {
		hinstance = instance,
		hwnd      = glfw.GetWin32Window(window),
	}

	return descriptor, true
}
