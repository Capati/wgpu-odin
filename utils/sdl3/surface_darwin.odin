#+build darwin
package wgpu_sdl3

// Vendor
import sdl "vendor:sdl3"

// Local packages
import wgpu "../../"

GetSurfaceDescriptor :: proc "c" (window: ^sdl.Window) -> (descriptor: wgpu.SurfaceDescriptor) {
	view := sdl.Metal_CreateView(window)
	layer := sdl.Metal_GetLayer(view)

	// Setup surface information
	descriptor.target = wgpu.SurfaceSourceMetalLayer {
		layer = layer,
	}

	return
}
