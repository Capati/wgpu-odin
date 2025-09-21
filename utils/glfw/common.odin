package wgpu_glfw

// Core
import "vendor:glfw"

// Local packages
import wgpu "../../"

CreateSurface :: proc "c" (
	window: glfw.WindowHandle,
	instance: wgpu.Instance,
) -> (
	surface: wgpu.Surface,
) {
	descriptor := GetSurfaceDescriptor(window)
	return wgpu.InstanceCreateSurface(instance, descriptor)
}
