#+build linux
package triangle

// Packages
import "vendor:glfw"

// Local packages
import wgpu "./../../"

get_surface_descriptor :: proc(window: glfw.WindowHandle) -> (descriptor: wgpu.SurfaceDescriptor) {
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
		panic("Unsupported Linux platform")
	}

	return descriptor
}
