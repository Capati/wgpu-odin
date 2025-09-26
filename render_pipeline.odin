package webgpu

// Vendor
import "vendor:wgpu"

/*
Handle to a rendering (graphics) pipeline.

A `RenderPipeline` object represents a graphics pipeline and its stages,
bindings, vertex buffers and targets. It can be created with
`DeviceCreateRenderPipeline`.

Corresponds to [WebGPU
`GPURenderPipeline`](https://gpuweb.github.io/gpuweb/#render-pipeline).
*/
RenderPipeline :: wgpu.RenderPipeline

/*
Get an object representing the bind group layout at a given index.

If this pipeline was created with a default layout, then bind groups created
with the returned `BindGroupLayout` can only be used with this pipeline.

This method will raise a validation error if there is no bind group layout at `index`.
*/
RenderPipelineGetBindGroupLayout :: wgpu.RenderPipelineGetBindGroupLayout

/* Sets a label for the given `RenderPipeline`. */
RenderPipelineSetLabel :: #force_inline proc "c" (self: RenderPipeline, label: string) {
	wgpu.RenderPipelineSetLabel(self, label)
}

/* Increase the `RenderPipeline` reference count. */
RenderPipelineAddRef :: #force_inline proc "c" (self: RenderPipeline) {
	wgpu.RenderPipelineAddRef(self)
}

/* Release the `RenderPipeline` resources, use to decrease the reference count. */
RenderPipelineRelease :: #force_inline proc "c" (self: RenderPipeline) {
	wgpu.RenderPipelineRelease(self)
}

/*
Safely releases the `RenderPipeline` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
RenderPipelineReleaseSafe :: proc "c" (self: ^RenderPipeline) {
	if self != nil && self^ != nil {
		wgpu.RenderPipelineRelease(self^)
		self^ = nil
	}
}
