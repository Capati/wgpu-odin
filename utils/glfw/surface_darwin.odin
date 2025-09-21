#+build darwin
package wgpu_glfw

// Core
import NS "core:sys/darwin/Foundation"
import CA "vendor:darwin/QuartzCore"
import "vendor:glfw"

// Local packages
import wgpu "../../"

GetSurfaceDescriptor :: proc "c" (
	window: glfw.WindowHandle,
) -> (
	descriptor: wgpu.SurfaceDescriptor,
) {
	nativeWindow := (^NS.Window)(glfw.GetCocoaWindow(window))

	metalLayer := CA.MetalLayer.layer()
	defer metalLayer->release()

	nativeWindow->contentView()->setLayer(metalLayer)

	// Setup surface information
	descriptor.target = wgpu.SurfaceSourceMetalLayer {
		layer = metalLayer,
	}

	return
}
