package wgpu_glfw

// Core
import "vendor:glfw"

// Local packages
import wgpu "../../"

create_surface :: proc "c" (
	window: glfw.WindowHandle,
	instance: wgpu.Instance,
) -> (
	surface: wgpu.Surface,
) {
	descriptor := get_surface_descriptor(window)
	return wgpu.InstanceCreateSurface(instance, descriptor)
}
