#+build linux
package wgpu_sdl2

// Vendor
import sdl "vendor:sdl2"

// Local packages
import wgpu "../../"

get_surface_descriptor :: proc "c" (window: ^sdl.Window) -> (descriptor: wgpu.SurfaceDescriptor) {
	wmInfo := get_sys_info(window)

	// Setup surface information
	if wmInfo.subsystem == .WAYLAND {
		descriptor.target = wgpu.SurfaceSourceWaylandSurface {
			display = wmInfo.info.wl.display,
			surface = wmInfo.info.wl.surface,
		}
	} else if wmInfo.subsystem == .X11 {
		descriptor.target = wgpu.SurfaceSourceXlibWindow {
			display = wmInfo.info.x11.display,
			window  = cast(u64)wmInfo.info.x11.window,
		}
	}

	return
}
