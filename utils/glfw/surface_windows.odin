//+build windows
package wgpu_utils_glfw

// Core
import win "core:sys/windows"

// Vendor
import "vendor:glfw"

// Package
import wgpu "../../wrapper"

get_surface_descriptor :: proc(
	w: glfw.WindowHandle,
) -> (
	descriptor: wgpu.Surface_Descriptor,
	err: wgpu.Error_Type,
) {
	instance := win.GetModuleHandleW(nil)

	// Setup surface information
	descriptor.target = wgpu.Surface_Descriptor_From_Windows_HWND {
		hinstance = instance,
		hwnd      = glfw.GetWin32Window(w),
	}

	return
}
