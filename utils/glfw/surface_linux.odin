#+build linux
package wgpu_utils_glfw

// Packages
import "vendor:glfw"

// Local packages
import "./../../wgpu"

get_surface_descriptor :: proc(
	window: glfw.WindowHandle,
) -> (
	descriptor: wgpu.SurfaceDescriptor,
	ok: bool,
) {
	switch glfw.GetPlatform() {
	case glfw.PLATFORM_WAYLAND:
		descriptor.target = wgpu.SurfaceSourceWaylandSurface {
			display = glfw.GetWaylandDisplay(),
			surface = glfw.GetWaylandWindow(window),
		}
	case glfw.PLATFORM_X11:
		descriptor.target = wgpu.SurfaceSourceXlibWindow {
			display = glfw.GetX11Display(),
			window  = u64(glfw.GetX11Window(window)),
		}
	case:
		return
	}

	return descriptor, true
}
