//+build linux
package wgpu_utils_glfw

// Core
import "core:fmt"

// Vendor
import "vendor:glfw"

// Package
import wgpu "../../wrapper"

get_surface_descriptor :: proc(
	w: glfw.WindowHandle,
) -> (
	descriptor: wgpu.Surface_Descriptor,
	err: wgpu.Error,
) {
	switch glfw.GetPlatform() {
	case glfw.PLATFORM_WAYLAND:
		descriptor.target = wgpu.Surface_Descriptor_From_Wayland_Surface {
			display = glfw.GetWaylandDisplay(),
			surface = glfw.GetWaylandWindow(w),
		}
	case glfw.PLATFORM_X11:
		descriptor.target = wgpu.Surface_Descriptor_From_Xlib_Window {
			display = glfw.GetX11Display(),
			window  = glfw.GetX11Window(w),
		}
	case:
		fmt.eprintf("ERROR: Unable to recognize the current desktop session.")
		return {}, .Internal
	}

	return
}
