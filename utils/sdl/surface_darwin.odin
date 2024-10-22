#+build darwin
package wgpu_utils_sdl

// Vendor
import NS "core:sys/darwin/Foundation"
import CA "vendor:darwin/QuartzCore"
import sdl "vendor:sdl2"

// Local packages
import wgpu "../../wrapper"

get_surface_descriptor :: proc(
	window: ^sdl.Window,
) -> (
	descriptor: wgpu.Surface_Descriptor,
	ok: bool,
) {
	wm_info := get_sys_info(window) or_return

	native_window := (^NS.Window)(wm_info.info.cocoa.window)

	metal_layer := CA.MetalLayer.layer()
	defer metal_layer->release()

	native_window->contentView()->setLayer(metal_layer)

	// Setup surface information
	descriptor.target = wgpu.Surface_Descriptor_From_Metal_Layer {
		layer = metal_layer,
	}

	return descriptor, true
}
