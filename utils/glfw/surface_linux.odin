#+build linux
package wgpu_glfw

// Core
import "vendor:glfw"

// Local packages
import wgpu "../../"

get_surface_descriptor :: proc "c" (
	window: glfw.WindowHandle,
) -> (
	descriptor: wgpu.SurfaceDescriptor,
) {
	switch glfw.GetPlatform() {
	case glfw.PLATFORM_WAYLAND:
		descriptor.target = wgpu.Surface_Source_Wayland_Surface {
			display = glfw.GetWaylandDisplay(),
			surface = glfw.GetWaylandWindow(window),
		}
	case glfw.PLATFORM_X11:
		descriptor.target = wgpu.Surface_Source_Xlib_Window {
			display = glfw.GetX11Display(),
			window  = u64(glfw.GetX11Window(window)),
		}
	case:
		panic_contextless("Unsupported platform")
	}

	return
}
