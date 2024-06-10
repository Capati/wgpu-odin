//+build linux
package wgpu_utils_glfw

// Core
import "core:fmt"
import "core:os"

// Vendor
import "vendor:glfw"

// Package
import wgpu "../../wrapper"

// temporary versions of the required function prototypes
foreign _ {
	glfwGetX11Display :: proc() -> rawptr ---
	glfwGetX11Window :: proc(window: glfw.WindowHandle) -> u64 ---
	glfwGetWaylandDisplay :: proc() -> rawptr ---
	glfwGetWaylandWindow :: proc(window: glfw.WindowHandle) -> rawptr ---
}

get_surface_descriptor :: proc(
	w: glfw.WindowHandle,
) -> (
	descriptor: wgpu.Surface_Descriptor,
	err: wgpu.Error,
) {
	switch glfw.GetPlatform() {
	case glfw.PLATFORM_WAYLAND:
		descriptor.target = wgpu.Surface_Descriptor_From_Wayland_Surface {
			display = glfwGetWaylandDisplay(),
			surface = glfwGetWaylandWindow(w),
		}
	case glfw.PLATFORM_X11:
		descriptor.target = wgpu.Surface_Descriptor_From_Xlib_Window {
			display = glfwGetX11Display(),
			window  = glfwGetX11Window(w),
		}
	case:
		fmt.eprintf("ERROR: Unable to recognize the current desktop session.")
		return {}, .Internal
	}

	return
}
