#+build !js
package webgpu

// Vendor
import "vendor:wgpu"

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
Issue a timestamp command at this point in the queue. The timestamp will be
written to the specified query set, at the specified index.

Must be multiplied by `queue_get_timestamp_period` to get the value in
nanoseconds. Absolute values have no meaning, but timestamps can be subtracted
to get the time it takes for a string of operations to complete.
*/
ComputePassWriteTimestamp :: wgpu.ComputePassEncoderWriteTimestamp

/*
Start a pipeline statistics query on this compute pass. It can be ended with
`compute_pass_end_pipeline_statistics_query`. Pipeline statistics queries may
not be nested.
*/
ComputePassBeginPipelineStatisticsQuery :: wgpu.ComputePassEncoderBeginPipelineStatisticsQuery

/*
End the pipeline statistics query on this compute pass. It can be started with
`compute_pass_begin_pipeline_statistics_query`. Pipeline statistics queries may
not be nested.
*/
ComputePassEndPipelineStatisticsQuery :: wgpu.ComputePassEncoderEndPipelineStatisticsQuery
