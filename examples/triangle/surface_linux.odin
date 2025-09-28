#+build linux
package triangle

// Core
import "vendor:glfw"

// Local packages
import wgpu "../.."

os_get_surface :: proc(instance: wgpu.Instance) -> (surface: wgpu.Surface) {
	descriptor: wgpu.SurfaceDescriptor

	switch glfw.GetPlatform() {
	case glfw.PLATFORM_WAYLAND:
		descriptor.target = wgpu.SurfaceSourceWaylandSurface {
			display = glfw.GetWaylandDisplay(),
			surface = glfw.GetWaylandWindow(state.os.window),
		}
	case glfw.PLATFORM_X11:
		descriptor.target = wgpu.SurfaceSourceXlibWindow {
			display = glfw.GetX11Display(),
			window  = u64(glfw.GetX11Window(state.os.window)),
		}
	case:
		panic("Unsupported Linux platform")
	}

	return wgpu.InstanceCreateSurface(instance, descriptor)
}
