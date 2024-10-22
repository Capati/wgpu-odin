#+build linux
package wgpu_utils_glfw

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
	switch glfw.GetPlatform() {
	case glfw.PLATFORM_WAYLAND:
		descriptor.target = wgpu.Surface_Descriptor_From_Wayland_Surface {
			display = glfw.GetWaylandDisplay(),
			surface = glfw.GetWaylandWindow(window),
		}
	case glfw.PLATFORM_X11:
		descriptor.target = wgpu.Surface_Descriptor_From_Xlib_Window {
			display = glfw.GetX11Display(),
			window  = u64(glfw.GetX11Window(window)),
		}
	case:
		return
	}

	return descriptor, true
}
