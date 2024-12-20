package wgpu

/*
In-progress recording of a compute pass.

It can be created with `command_encoder_begin_compute_pass`.

Corresponds to [WebGPU `GPUComputePassEncoder`](
https://gpuweb.github.io/gpuweb/#compute-pass-encoder).
*/
ComputePass :: distinct rawptr

/*
Dispatches compute work operations.

`x`, `y` and `z` denote the number of work groups to dispatch in each dimension.
*/
compute_pass_dispatch_workgroups :: proc "contextless" (
	self: ComputePass,
	workgroup_count_x: u32,
	workgroup_count_y: u32 = 1,
	workgroup_count_z: u32 = 1,
) {
	wgpuComputePassEncoderDispatchWorkgroups(
		self,
		workgroup_count_x,
		workgroup_count_y,
		workgroup_count_z,
	)
}

/*
Dispatches compute work operations, based on the contents of the `indirect_buffer`.

The structure expected in `indirect_buffer` must conform to `Dispatch_Indirect`.
*/
compute_pass_dispatch_workgroups_indirect :: wgpuComputePassEncoderDispatchWorkgroupsIndirect

/* Record the end of the compute pass. */
compute_pass_end :: proc "contextless" (self: ComputePass, loc := #caller_location) -> (ok: bool) {
	error_reset_data(loc)
	wgpuComputePassEncoderEnd(self)
	return has_no_error()
}

/* Inserts debug marker. */
compute_pass_insert_debug_marker :: wgpuComputePassEncoderInsertDebugMarker

/* Stops command recording and creates debug group. */
compute_pass_pop_debug_group :: wgpuComputePassEncoderPopDebugGroup

/* Start record commands and group it into debug marker group. */
compute_pass_push_debug_group :: wgpuComputePassEncoderPushDebugGroup

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
	group_index: u32,
	group: BindGroup,
	offsets: []DynamicOffset = nil,
) {
	wgpuComputePassEncoderSetBindGroup(self, group_index, group, len(offsets), raw_data(offsets))
}

/* Set debug label. */
@(disabled = !ODIN_DEBUG)
compute_pass_set_label :: proc "contextless" (self: ComputePass, label: string) {
	c_label: StringViewBuffer
	wgpuComputePassEncoderSetLabel(self, init_string_buffer(&c_label, label))
}

/* Sets the active compute pipeline. */
compute_pass_set_pipeline :: wgpuComputePassEncoderSetPipeline

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

/* Increase the reference count. */
compute_pass_add_ref :: wgpuComputePassEncoderAddRef

/* Release the `ComputePass` resources. */
compute_pass_release :: wgpuComputePassEncoderRelease
