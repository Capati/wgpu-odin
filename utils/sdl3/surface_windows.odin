#+build windows
package wgpu_sdl3

// Vendor
import sdl "vendor:sdl3"

// Local packages
import wgpu "../../"

GetSurfaceDescriptor :: proc "c" (window: ^sdl.Window) -> (descriptor: wgpu.SurfaceDescriptor) {
	hinstance := sdl.GetPointerProperty(
		sdl.GetWindowProperties(window),
		sdl.PROP_WINDOW_WIN32_INSTANCE_POINTER,
		nil,
	)
	hwnd := sdl.GetPointerProperty(
		sdl.GetWindowProperties(window),
		sdl.PROP_WINDOW_WIN32_HWND_POINTER,
		nil,
	)

	ensure_contextless(hwnd != nil)
	ensure_contextless(hinstance != nil)

	// Setup surface information
	descriptor.target = wgpu.SurfaceSourceWindowsHWND {
		hinstance = hinstance,
		hwnd      = hwnd,
	}

	return
}
