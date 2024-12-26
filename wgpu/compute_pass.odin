package wgpu

/*
In-progress recording of a compute pass.

It can be created with `command_encoder_begin_compute_pass`.

Corresponds to [WebGPU `GPUComputePassEncoder`](
https://gpuweb.github.io/gpuweb/#compute-pass-encoder).
*/
ComputePass :: distinct rawptr

/*
Describes the timestamp writes of a compute pass.

For use with `ComputePassDescriptor`.
At least one of `beginning_of_pass_write_index` and `end_of_pass_write_index` must be valid.

Corresponds to [WebGPU `GPUComputePassTimestampWrites`](
https://gpuweb.github.io/gpuweb/#dictdef-gpucomputepasstimestampwrites).
*/
ComputePassTimestampWrites :: struct {
	query_set:                     QuerySet,
	beginning_of_pass_write_index: u32,
	end_of_pass_write_index:       u32,
}

/*
Describes a `CommandEncoder`.

For use with `device_create_command_encoder`.

Corresponds to [WebGPU `GPUCommandEncoderDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpucommandencoderdescriptor).
*/
ComputePassDescriptor :: struct {
	label:            string,
	timestamp_writes: Maybe(ComputePassTimestampWrites),
}

/*
Sets the active bind group for a given bind group index. The bind group layout in the active
pipeline when the `compute_pass_dispatch_workgroups` function is called must match the layout of
this bind group.

If the bind group have dynamic offsets, provide them in the binding order. These offsets have to
be aligned to limits `min_uniform_buffer_offset_alignment` or limits
`min_storage_buffer_offset_alignment` appropriately.
*/
compute_pass_set_bind_group :: proc "contextless" (
	self: ComputePass,
	index: u32,
	bind_group: BindGroup,
	offsets: []DynamicOffset = nil,
) {
	wgpuComputePassEncoderSetBindGroup(self, index, bind_group, len(offsets), raw_data(offsets))
}

/* Sets the active compute pipeline. */
compute_pass_set_pipeline :: wgpuComputePassEncoderSetPipeline

/* Inserts debug marker. */
compute_pass_insert_debug_marker :: proc(
	self: ComputePass,
	label: string,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	when ODIN_DEBUG {
		error_reset_data(loc)
		c_label: StringViewBuffer
		wgpuComputePassEncoderInsertDebugMarker(
			self,
			init_string_buffer(&c_label, label) if label != "" else {},
		)
		return has_no_error()
	} else {
		return true
	}
}

/* Start record commands and group it into debug marker group. */
compute_pass_push_debug_group :: proc(
	self: ComputePass,
	label: string,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	when ODIN_DEBUG {
		error_reset_data(loc)
		c_label: StringViewBuffer
		wgpuComputePassEncoderPushDebugGroup(
			self,
			init_string_buffer(&c_label, label) if label != "" else {},
		)
		return has_no_error()
	} else {
		return true
	}
}

/* Stops command recording and creates debug group. */
compute_pass_pop_debug_group :: proc "contextless" (
	self: ComputePass,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	when ODIN_DEBUG {
		error_reset_data(loc)
		wgpuComputePassEncoderPopDebugGroup(self)
		return has_no_error()
	} else {
		return true
	}
}

/*
Dispatches compute work operations.

`x`, `y` and `z` denote the number of work groups to dispatch in each dimension.
*/
compute_pass_dispatch_workgroups :: wgpuComputePassEncoderDispatchWorkgroups

/*
Dispatches compute work operations, based on the contents of the `indirect_buffer`.

The structure expected in `indirect_buffer` must conform to `Dispatch_Indirect`.
*/
compute_pass_dispatch_workgroups_indirect :: wgpuComputePassEncoderDispatchWorkgroupsIndirect

/*
Set push constant data for subsequent dispatch calls.

Write the bytes in `data` at offset `offset` within push constant
storage.  Both `offset` and the length of `data` must be
multiples of `PUSH_CONSTANT_ALIGNMENT`, which is always 4.

For example, if `offset` is `4` and `data` is eight bytes long, this
call will write `data` to bytes `4..12` of push constant storage.
*/
compute_pass_set_push_constants :: proc(self: ComputePass, offset: u32, data: []byte) {
	wgpuComputePassEncoderSetPushConstants(self, offset, u32(len(data)), raw_data(data))
}

/*
Issue a timestamp command at this point in the queue. The timestamp will be written to the specified query set, at the specified index.

Must be multiplied by `queue_get_timestamp_period` to get
the value in nanoseconds. Absolute values have no meaning,
but timestamps can be subtracted to get the time it takes
for a string of operations to complete.
*/
compute_pass_write_timestamp :: wgpuComputePassEncoderWriteTimestamp

/*
Start a pipeline statistics query on this compute pass. It can be ended with
`compute_pass_end_pipeline_statistics_query`. Pipeline statistics queries may not be nested.
*/
compute_pass_begin_pipeline_statistics_query :: wgpuComputePassEncoderBeginPipelineStatisticsQuery

/*
End the pipeline statistics query on this compute pass. It can be started with
`compute_pass_begin_pipeline_statistics_query`. Pipeline statistics queries may not be nested.
*/
compute_pass_end_pipeline_statistics_query :: wgpuComputePassEncoderEndPipelineStatisticsQuery

/* Record the end of the compute pass. */
compute_pass_end :: proc "contextless" (self: ComputePass, loc := #caller_location) -> (ok: bool) {
	error_reset_data(loc)
	wgpuComputePassEncoderEnd(self)
	return has_no_error()
}

/* Sets a debug label for the given `ComputePass`. */
@(disabled = !ODIN_DEBUG)
compute_pass_set_label :: proc "contextless" (self: ComputePass, label: string) {
	c_label: StringViewBuffer
	wgpuComputePassEncoderSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the `ComputePass` reference count. */
compute_pass_add_ref :: wgpuComputePassEncoderAddRef

/* Release the `ComputePass` resources, use to decrease the reference count. */
compute_pass_release :: wgpuComputePassEncoderRelease
