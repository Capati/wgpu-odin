#+build windows
package wgpu_sdl2

// Vendor
import sdl "vendor:sdl2"

// Local packages
import wgpu "../../"

GetSurfaceDescriptor :: proc "c" (window: ^sdl.Window) -> (descriptor: wgpu.SurfaceDescriptor) {
	wmInfo := get_sys_info(window)

	// Setup surface information
	descriptor.target = wgpu.SurfaceSourceWindowsHWND {
		hinstance = wmInfo.info.win.hinstance,
		hwnd      = wmInfo.info.win.window,
	}

	return
}
