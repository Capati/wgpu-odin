#+build linux
package wgpu_utils_sdl

// Vendor
import sdl "vendor:sdl2"

// Local packages
import "./../../wgpu"

get_surface_descriptor :: proc(
	window: ^sdl.Window,
) -> (
	descriptor: wgpu.SurfaceDescriptor,
	ok: bool,
) {
	wm_info := get_sys_info(window) or_return

	// Setup surface information
	if wm_info.subsystem == .WAYLAND {
		descriptor.target = wgpu.SurfaceSourceWaylandSurface {
			display = wm_info.info.wl.display,
			surface = wm_info.info.wl.surface,
		}
	} else if wm_info.subsystem == .X11 {
		descriptor.target = wgpu.SurfaceSourceXlibWindow {
			display = wm_info.info.x11.display,
			window  = cast(u64)wm_info.info.x11.window,
		}
	}

	return descriptor, true
}
