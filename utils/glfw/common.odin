package wgpu_utils_glfw

// Vendor
import "vendor:glfw"

// Local packages
import wgpu "../../wrapper"

create_surface :: proc(
	window: glfw.WindowHandle,
	instance: wgpu.Instance,
) -> (
	surface: wgpu.Surface,
	ok: bool,
) #optional_ok {
	surface_descriptor := get_surface_descriptor(window) or_return
	return wgpu.instance_create_surface(instance, surface_descriptor)
}
