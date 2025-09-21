package wgpu_sdl2

// Vendor
import sdl "vendor:sdl2"

// Local packages
import wgpu "../../"

@(private)
get_sys_info :: proc "c" (window: ^sdl.Window) -> (wmInfo: sdl.SysWMinfo) {
	sdl.GetVersion(&wmInfo.version)
	ensure_contextless(bool(sdl.GetWindowWMInfo(window, &wmInfo)))
	return
}

CreateSurface :: proc "c" (
	window: ^sdl.Window,
	instance: wgpu.Instance,
) -> (
	surface: wgpu.Surface,
) {
	descriptor := GetSurfaceDescriptor(window)
	return wgpu.InstanceCreateSurface(instance, descriptor)
}
