#+build linux
package wgpu_sdl3

// Vendor
import sdl "vendor:sdl3"

// Local packages
import wgpu "../../"

get_surface_descriptor :: proc "c" (window: ^sdl.Window) -> (descriptor: wgpu.SurfaceDescriptor) {
	switch sdl.GetCurrentVideoDriver() {
	case "wayland":
		display := sdl.GetPointerProperty(
			sdl.GetWindowProperties(window),
			sdl.PROP_WINDOW_WAYLAND_DISPLAY_POINTER,
			nil,
		)
		surface := sdl.GetPointerProperty(
			sdl.GetWindowProperties(window),
			sdl.PROP_WINDOW_WAYLAND_SURFACE_POINTER,
			nil,
		)

		descriptor.target = wgpu.SurfaceSourceWaylandSurface {
			display = display,
			surface = surface,
		}
	case "x11":
		display := sdl.GetPointerProperty(
			sdl.GetWindowProperties(window),
			sdl.PROP_WINDOW_X11_DISPLAY_POINTER,
			nil,
		)
		window := cast(u64)sdl.GetNumberProperty(
			sdl.GetWindowProperties(window),
			sdl.PROP_WINDOW_X11_WINDOW_NUMBER,
			0,
		)
		descriptor.target = wgpu.SurfaceSourceXlibWindow {
			display = display,
			window  = window,
		}
	case:
		panic_contextless("Unsupported video driver, expected Wayland or X11")
	}

	return
}
