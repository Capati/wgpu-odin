package webgpu

// Vendor
import "vendor:wgpu"

/*
Handle to a compute pipeline.

A `ComputePipeline` object represents a compute pipeline and its single shader
stage. It can be created with `DeviceCreateComputePipeline`.

Corresponds to [WebGPU
`GPUComputePipeline`](https://gpuweb.github.io/gpuweb/#compute-pipeline).
*/
ComputePipeline :: wgpu.ComputePipeline

/*
Get an object representing the bind group layout at a given index.

If this pipeline was created with a default layout, then bind groups created
with the returned `BindGroupLayout` can only be used with this pipeline.

This method will raise a validation error if there is no bind group layout at `index`.
*/
@(require_results)
ComputePipelineGetBindGroupLayout :: proc "c" (
	self: ComputePipeline,
	group_index: u32,
) -> BindGroupLayout {
	return wgpu.ComputePipelineGetBindGroupLayout(self, group_index)
}

/* Sets a debug label for the given `ComputePipeline`. */
ComputePipelineSetLabel :: #force_inline proc "c" (self: ComputePipeline, label: string) {
	wgpu.ComputePipelineSetLabel(self, label)
}

/* Increase the `ComputePipeline` reference count. */
ComputePipelineAddRef :: #force_inline proc "c" (self: ComputePipeline) {
	wgpu.ComputePipelineAddRef(self)
}

/* Release the `ComputePipeline` resources, use to decrease the reference count. */
ComputePipelineRelease :: #force_inline proc "c" (self: ComputePipeline) {
	wgpu.ComputePipelineRelease(self)
}

/*
Safely releases the `ComputePipeline` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
ComputePipelineReleaseSafe :: proc "c" (self: ^ComputePipeline) {
	if self != nil && self^ != nil {
		wgpu.ComputePipelineRelease(self^)
		self^ = nil
	}
}
