package webgpu

// Vendor
import "vendor:wgpu"

/*
Handle to a pipeline layout.

A `PipelineLayout` object describes the available binding groups of a pipeline.
It can be created with `DeviceCreatePipelineLayout`.

Corresponds to [WebGPU
`GPUPipelineLayout`](https://gpuweb.github.io/gpuweb/#gpupipelinelayout).
*/
PipelineLayout :: wgpu.PipelineLayout

/* Sets a debug label for the given `PipelineLayout`. */
PipelineLayoutSetLabel :: wgpu.PipelineLayoutSetLabel

/* Increase the `PipelineLayout` reference count. */
PipelineLayoutAddRef :: #force_inline proc "c" (self: PipelineLayout) {
	wgpu.PipelineLayoutAddRef(self)
}

/* Release the `PipelineLayout` resources, use to decrease the reference count. */
PipelineLayoutRelease :: #force_inline proc "c" (self: PipelineLayout) {
	wgpu.PipelineLayoutRelease(self)
}

/*
Safely releases the `PipelineLayout` resources and invalidates the handle. The
procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
PipelineLayoutReleaseSafe :: proc "c" (self: ^PipelineLayout) {
	if self != nil && self^ != nil {
		wgpu.PipelineLayoutRelease(self^)
		self^ = nil
	}
}
