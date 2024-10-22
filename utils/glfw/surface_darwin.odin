#+build darwin
package wgpu_utils_glfw

// STD Library
import NS "core:sys/darwin/Foundation"

// Vendor
import CA "vendor:darwin/QuartzCore"
import "vendor:glfw"

// Local packages
import wgpu "../../wrapper"

get_surface_descriptor :: proc(
	window: glfw.WindowHandle,
) -> (
	descriptor: wgpu.Surface_Descriptor,
	ok: bool,
) {
	native_window := (^NS.Window)(glfw.GetCocoaWindow(window))

	metal_layer := CA.MetalLayer.layer()
	defer metal_layer->release()

	native_window->contentView()->setLayer(metal_layer)

	// Setup surface information
	descriptor.target = wgpu.Surface_Descriptor_From_Metal_Layer {
		layer = metal_layer,
	}

	return descriptor, true
}
