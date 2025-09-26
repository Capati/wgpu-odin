#+build js
package triangle

// Local packages
import wgpu "../.."

os_get_surface :: proc(instance: wgpu.Instance) -> (surface: wgpu.Surface) {
	return wgpu.InstanceCreateSurface(instance, {
		target = wgpu.SurfaceSourceCanvasHTMLSelector {
			selector = "#canvas",
		},
	})
}
