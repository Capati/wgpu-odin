package wgpu_utils_sdl

// Core
import "core:fmt"

// Vendor
import sdl "vendor:sdl2"

// Package
import wgpu "../../wrapper"

get_sys_info :: proc(window: ^sdl.Window) -> (wm_info: sdl.SysWMinfo, err: wgpu.Error) {
	sdl.GetVersion(&wm_info.version)

	if !sdl.GetWindowWMInfo(window, &wm_info) {
		fmt.eprintf("ERROR: Could not obtain SDL WM info from window.\n")
		return {}, .Internal
	}

	return
}

create_surface :: proc(
	window: ^sdl.Window,
	instance: wgpu.Instance,
) -> (
	surface: wgpu.Surface,
	err: wgpu.Error,
) {
	surface_descriptor := get_surface_descriptor(window) or_return
	return wgpu.instance_create_surface(instance, surface_descriptor)
}
