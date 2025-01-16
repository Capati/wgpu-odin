#+build darwin
package triangle

// Packages
import NS "core:sys/darwin/Foundation"
import CA "vendor:darwin/QuartzCore"
import "vendor:glfw"

// Local packages
import "root:wgpu"

get_surface_descriptor :: proc(
	window: glfw.WindowHandle,
) -> (
	descriptor: wgpu.Surface_Descriptor,
) {
	native_window := (^NS.Window)(glfw.GetCocoaWindow(window))

	metal_layer := CA.MetalLayer.layer()
	defer metal_layer->release()

	native_window->contentView()->setLayer(metal_layer)

	// Setup surface information
	descriptor.target = wgpu.Surface_Source_Metal_Layer {
		layer = metal_layer,
	}

	return descriptor
}
