package wgpu_utils_sdl

// Vendor
import sdl "vendor:sdl2"

// Local packages
import wgpu "../../wrapper"

get_sys_info :: proc(window: ^sdl.Window) -> (wm_info: sdl.SysWMinfo, ok: bool) {
	sdl.GetVersion(&wm_info.version)
	ok = bool(sdl.GetWindowWMInfo(window, &wm_info))
	return
}

create_surface :: proc(
	window: ^sdl.Window,
	instance: wgpu.Instance,
) -> (
	surface: wgpu.Surface,
	ok: bool,
) #optional_ok {
	surface_descriptor := get_surface_descriptor(window) or_return
	return wgpu.instance_create_surface(instance, surface_descriptor)
}
