#+build darwin
package wgpu_utils_glfw

// Packages
import NS "core:sys/darwin/Foundation"
import CA "vendor:darwin/QuartzCore"
import "vendor:glfw"

// Local packages
import "./../../wgpu"

get_surface_descriptor :: proc(
	window: glfw.WindowHandle,
) -> (
	descriptor: wgpu.SurfaceDescriptor,
	ok: bool,
) {
	native_window := (^NS.Window)(glfw.GetCocoaWindow(window))

	metal_layer := CA.MetalLayer.layer()
	defer metal_layer->release()

	native_window->contentView()->setLayer(metal_layer)

	// Setup surface information
	descriptor.target = wgpu.SurfaceSourceMetalLayer {
		layer = metal_layer,
	}

	return descriptor, true
}
