//+build darwin

package wgpu_utils_glfw

// Vendor
import NS "core:sys/darwin/Foundation"
import CA "vendor:darwin/QuartzCore"
import "vendor:glfw"

// Package
import wgpu "../../wrapper"

get_surface_descriptor :: proc(
	w: glfw.WindowHandle,
) -> (
	descriptor: wgpu.Surface_Descriptor,
	err: wgpu.Error_Type,
) {
	native_window := (^NS.Window)(glfw.GetCocoaWindow(w))

	metal_layer := CA.MetalLayer.layer()
	defer metal_layer->release()

	native_window->contentView()->setLayer(metal_layer)

	// Setup surface information
	descriptor.target = wgpu.Surface_Descriptor_From_Metal_Layer {
		layer = metal_layer,
	}

	return
}

