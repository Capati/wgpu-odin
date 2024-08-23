package wgpu

// The raw bindings
import wgpu "../bindings"

/*
In-progress recording of a compute pass.

It can be created with `command_encoder_begin_compute_pass`.

Corresponds to [WebGPU `GPUComputePassEncoder`](
https://gpuweb.github.io/gpuweb/#compute-pass-encoder).
*/
Compute_Pass :: wgpu.Compute_Pass_Encoder

/*
Dispatches compute work operations.

`x`, `y` and `z` denote the number of work groups to dispatch in each dimension.
*/
compute_pass_dispatch_workgroups :: proc "contextless" (
	self: Compute_Pass,
	workgroup_count_x: u32,
	workgroup_count_y: u32 = 1,
	workgroup_count_z: u32 = 1,
) {
	wgpu.compute_pass_encoder_dispatch_workgroups(
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
compute_pass_dispatch_workgroups_indirect :: wgpu.compute_pass_encoder_dispatch_workgroups_indirect

/* Record the end of the compute pass. */
compute_pass_end :: proc "contextless" (
	self: Compute_Pass,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	_error_reset_data(loc)
	wgpu.compute_pass_encoder_end(self)
	return get_last_error() == nil
}

/* Inserts debug marker. */
compute_pass_insert_debug_marker :: wgpu.compute_pass_encoder_insert_debug_marker

/* Stops command recording and creates debug group. */
compute_pass_pop_debug_group :: wgpu.compute_pass_encoder_pop_debug_group

/* Start record commands and group it into debug marker group. */
compute_pass_push_debug_group :: wgpu.compute_pass_encoder_push_debug_group

/*
Sets the active bind group for a given bind group index. The bind group layout in the active
pipeline when the `compute_pass_dispatch_workgroups` function is called must match the layout of
this bind group.

If the bind group have dynamic offsets, provide them in the binding order. These offsets have to
be aligned to limits `min_uniform_buffer_offset_alignment` or limits
`min_storage_buffer_offset_alignment` appropriately.
*/
compute_pass_set_bind_group :: proc "contextless" (
	self: Compute_Pass,
	group_index: u32,
	group: Bind_Group,
	dynamic_offsets: []u32 = nil,
) {
	wgpu.compute_pass_encoder_set_bind_group(
		self,
		group_index,
		group,
		len(dynamic_offsets),
		raw_data(dynamic_offsets),
	)
}

/* Set debug label. */
compute_pass_set_label :: wgpu.compute_pass_encoder_set_label

/* Sets the active compute pipeline. */
compute_pass_set_pipeline :: wgpu.compute_pass_encoder_set_pipeline

/*
Start a pipeline statistics query on this compute pass. It can be ended with
`compute_pass_end_pipeline_statistics_query`. Pipeline statistics queries may not be nested.
*/
compute_pass_begin_pipeline_statistics_query ::
	wgpu.compute_pass_encoder_begin_pipeline_statistics_query

/*
End the pipeline statistics query on this compute pass. It can be started with
`compute_pass_begin_pipeline_statistics_query`. Pipeline statistics queries may not be nested.
*/
compute_pass_end_pipeline_statistics_query ::
	wgpu.compute_pass_encoder_end_pipeline_statistics_query

/* Increase the reference count. */
compute_pass_reference :: wgpu.compute_pass_encoder_reference

/* Release the `Compute_Pass` resources. */
compute_pass_release :: wgpu.compute_pass_encoder_release
