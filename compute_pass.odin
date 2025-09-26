package webgpu

// Vendor
import "vendor:wgpu"

/*
In-progress recording of a compute pass.

It can be created with `CommandEncoderBeginComputePass`.

Corresponds to [WebGPU `GPUComputePassEncoder`](
https://gpuweb.github.io/gpuweb/#compute-pass-encoder).
*/
ComputePass :: wgpu.ComputePassEncoder

/*
Sets the active bind group for a given bind group index. The bind group layout
in the active pipeline when the `ComputePassDispatchWorkgroups` function is
called must match the layout of this bind group.

If the bind group have dynamic offsets, provide them in the binding order. These
offsets have to be aligned to limits `MinUniformBufferOffsetAlignment` or limits
`MinStorageBufferOffsetAlignment` appropriately.
*/
ComputePassSetBindGroup :: wgpu.ComputePassEncoderSetBindGroup

/* Sets the active compute pipeline. */
ComputePassSetPipeline :: wgpu.ComputePassEncoderSetPipeline

/* Inserts debug marker. */
ComputePassInsertDebugMarker :: wgpu.ComputePassEncoderInsertDebugMarker

/* Start record commands and group it into debug marker group. */
ComputePassPushDebugGroup :: wgpu.ComputePassEncoderPushDebugGroup

/* Stops command recording and creates debug group. */
ComputePassPopDebugGroup :: wgpu.ComputePassEncoderPopDebugGroup

/*
Dispatches compute work operations.

`x`, `y` and `z` denote the number of work groups to dispatch in each dimension.
*/
ComputePassDispatchWorkgroups :: wgpu.ComputePassEncoderDispatchWorkgroups

/*
Dispatches compute work operations, based on the contents of the `indirect_buffer`.

The structure expected in `indirect_buffer` must conform to `Dispatch_Indirect`.
*/
ComputePassDispatchWorkgroupsIndirect :: wgpu.ComputePassEncoderDispatchWorkgroupsIndirect

/* Record the end of the compute pass. */
ComputePassEnd :: wgpu.ComputePassEncoderEnd

/* Sets a debug label for the given `ComputePass`. */
ComputePassSetLabel :: #force_inline proc "c" (self: ComputePass, label: string) {
	wgpu.ComputePassEncoderSetLabel(self, label)
}

/* Increase the `ComputePass` reference count. */
ComputePassAddRef :: #force_inline proc "c" (self: ComputePass) {
	wgpu.ComputePassEncoderAddRef(self)
}

/* Release the `ComputePass` resources, use to decrease the reference count. */
ComputePassRelease :: #force_inline proc "c" (self: ComputePass) {
	wgpu.ComputePassEncoderRelease(self)
}

/*
Safely releases the `ComputePass` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
ComputePassReleaseSafe :: proc "c" (self: ^ComputePass) {
	if self != nil && self^ != nil {
		wgpu.ComputePassEncoderRelease(self^)
		self^ = nil
	}
}
