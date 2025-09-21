package wgpu_sdl3

// Vendor
import sdl "vendor:sdl3"

// Local packages
import wgpu "../../"

CreateSurface :: proc "c" (
	window: ^sdl.Window,
	instance: wgpu.Instance,
) -> (
	surface: wgpu.Surface,
) {
	descriptor := GetSurfaceDescriptor(window)
	return wgpu.InstanceCreateSurface(instance, descriptor)
}
