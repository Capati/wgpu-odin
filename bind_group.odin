package webgpu

// Vendor
import "vendor:wgpu"

/*
Handle to a binding group.

A `BindGroup` represents the set of resources bound to the bindings described by
a `BindGroupLayout`. It can be created with `DeviceCreateBindGroup`. A
`BindGroup` can be bound to a particular `RenderPass` with
`RenderPassSetBindGroup`, or to a `ComputePass` with `ComputePassSetBindGroup`.

Corresponds to [WebGPU
`GPUBindGroup`](https://gpuweb.github.io/gpuweb/#gpubindgroup).
*/
BindGroup :: wgpu.BindGroup

/* Sets a debug label for the given `BindGroup`. */
BindGroupSetLabel :: wgpu.BindGroupSetLabel

/* Increase reference count. */
BindGroupAddRef :: wgpu.BindGroupAddRef

/* Release resources, use to decrease the reference count. */
BindGroupRelease :: wgpu.BindGroupRelease

/*
Safely releases the `BindGroup` resources and invalidates the handle.
The procedure checks both the pointer validity and the Bind group handle before releasing.

Note: After calling this, the Bind group handle will be set to `nil` and should not be used.
*/
BindGroupReleaseSafe :: proc "c" (self: ^BindGroup) {
	if self != nil && self^ != nil {
		wgpu.BindGroupRelease(self^)
		self^ = nil
	}
}
