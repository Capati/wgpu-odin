#+build darwin
package triangle

// Core
import NS "core:sys/darwin/Foundation"
import CA "vendor:darwin/QuartzCore"

// Vendor
import "vendor:glfw"

// Local packages
import wgpu "../.."

os_get_surface :: proc(instance: wgpu.Instance) -> (surface: wgpu.Surface) {
	native_window := (^NS.Window)(glfw.GetCocoaWindow(window))

	metal_layer := CA.MetalLayer.layer()
	defer metal_layer->release()

	native_window->contentView()->setLayer(metal_layer)

	return wgpu.InstanceCreateSurface(instance, {
		target = wgpu.SurfaceSourceMetalLayer {
			layer = metal_layer,
		}
	})
}
