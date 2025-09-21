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

/*
Set push constant data for subsequent dispatch calls.

Write the bytes in `data` at offset `offset` within push constant storage.  Both
`offset` and the length of `data` must be multiples of
`PUSH_CONSTANT_ALIGNMENT`, which is always 4.

For example, if `offset` is `4` and `data` is eight bytes long, this call will
write `data` to bytes `4..12` of push constant storage.
*/
ComputePassSetPushConstants :: proc "c" (self: ComputePass, offset: u32, data: []byte) {
	wgpu.ComputePassEncoderSetPushConstants(self, offset, u32(len(data)), raw_data(data))
}

/*
Issue a timestamp command at this point in the queue. The timestamp will be written to the specified query set, at the specified index.

Must be multiplied by `queue_get_timestamp_period` to get
the value in nanoseconds. Absolute values have no meaning,
but timestamps can be subtracted to get the time it takes
for a string of operations to complete.
*/
ComputePassWriteTimestamp :: wgpu.ComputePassEncoderWriteTimestamp

/*
Start a pipeline statistics query on this compute pass. It can be ended with
`compute_pass_end_pipeline_statistics_query`. Pipeline statistics queries may not be nested.
*/
ComputePassBeginPipelineStatisticsQuery :: wgpu.ComputePassEncoderBeginPipelineStatisticsQuery

/*
End the pipeline statistics query on this compute pass. It can be started with
`compute_pass_begin_pipeline_statistics_query`. Pipeline statistics queries may not be nested.
*/
ComputePassEndPipelineStatisticsQuery :: wgpu.ComputePassEncoderEndPipelineStatisticsQuery

/* Record the end of the compute pass. */
ComputePassEnd :: wgpu.ComputePassEncoderEnd

/* Sets a debug label for the given `ComputePass`. */
ComputePassSetLabel :: wgpu.ComputePassEncoderSetLabel

/* Increase the `ComputePass` reference count. */
ComputePassAddRef :: wgpu.ComputePassEncoderAddRef

/* Release the `ComputePass` resources, use to decrease the reference count. */
ComputePassRelease :: wgpu.ComputePassEncoderRelease

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
