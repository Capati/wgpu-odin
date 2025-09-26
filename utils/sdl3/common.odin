package wgpu_sdl3

// Vendor
import sdl "vendor:sdl3"

// Local packages
import wgpu "../../"

create_surface :: proc "c" (
	window: ^sdl.Window,
	instance: wgpu.Instance,
) -> (
	surface: wgpu.Surface,
) {
	descriptor := get_surface_descriptor(window)
	return wgpu.InstanceCreateSurface(instance, descriptor)
}
