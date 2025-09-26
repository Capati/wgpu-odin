#+build darwin
package wgpu_sdl2

// Vendor
import NS "core:sys/darwin/Foundation"
import CA "vendor:darwin/QuartzCore"
import sdl "vendor:sdl2"

// Local packages
import wgpu "../../"

get_surface_descriptor :: proc "c" (window: ^sdl.Window) -> (descriptor: wgpu.SurfaceDescriptor) {
	wmInfo := get_sys_info(window)

	nativeWindow := (^NS.Window)(wmInfo.info.cocoa.window)

	metalLayer := CA.MetalLayer.layer()
	defer metalLayer->release()

	nativeWindow->contentView()->setLayer(metalLayer)

	// Setup surface information
	descriptor.target = wgpu.SurfaceSourceMetalLayer {
		layer = metalLayer,
	}

	return
}
