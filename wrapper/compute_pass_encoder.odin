package wgpu

// Package
import wgpu "../bindings"

// In-progress recording of a compute pass.
//
// It can be created with `command_encoder_begin_compute_pass`.
Compute_Pass :: struct {
	_ptr:      WGPU_Compute_Pass_Encoder,
	_err_data: ^Error_Data,
}

// Sets the active bind group for a given bind group index. The bind group layout in the active
// pipeline when the `compute_pass_dispatch_workgroups` function is called must match the layout of
// this bind group.
//
// If the bind group have dynamic offsets, provide them in the binding order. These offsets have to
// be aligned to limits `min_uniform_buffer_offset_alignment` or limits
// `min_storage_buffer_offset_alignment` appropriately.
compute_pass_set_bind_group :: proc(
	using self: ^Compute_Pass,
	group_index: u32,
	group: ^Bind_Group,
	dynamic_offsets: []u32 = {},
) {
	dynamic_offset_count := cast(uint)len(dynamic_offsets)

	if dynamic_offset_count == 0 {
		wgpu.compute_pass_encoder_set_bind_group(_ptr, group_index, group._ptr, 0, nil)
	} else {
		wgpu.compute_pass_encoder_set_bind_group(
			_ptr,
			group_index,
			group._ptr,
			dynamic_offset_count,
			raw_data(dynamic_offsets),
		)
	}
}

// Sets the active compute pipeline.
compute_pass_set_pipeline :: proc(using self: ^Compute_Pass, pipeline: ^Compute_Pipeline) {
	wgpu.compute_pass_encoder_set_pipeline(_ptr, pipeline._ptr)
}

// Inserts debug marker.
compute_pass_insert_debug_marker :: proc(using self: ^Compute_Pass, marker_label: cstring) {
	wgpu.compute_pass_encoder_insert_debug_marker(_ptr, marker_label)
}

// Start record commands and group it into debug marker group.
compute_pass_push_debug_group :: proc(using self: ^Compute_Pass, group_label: cstring) {
	wgpu.compute_pass_encoder_push_debug_group(_ptr, group_label)
}

// Stops command recording and creates debug group.
compute_pass_pop_debug_group :: proc(using self: ^Compute_Pass) {
	wgpu.compute_pass_encoder_pop_debug_group(_ptr)
}

// Dispatches compute work operations.
//
// `x`, `y` and `z` denote the number of work groups to dispatch in each dimension.
compute_pass_dispatch_workgroups :: proc(
	using self: ^Compute_Pass,
	workgroup_count_x: u32,
	workgroup_count_y: u32 = 1,
	workgroup_count_z: u32 = 1,
) {
	wgpu.compute_pass_encoder_dispatch_workgroups(
		_ptr,
		workgroup_count_x,
		workgroup_count_y,
		workgroup_count_z,
	)
}

// Dispatches compute work operations, based on the contents of the `indirect_buffer`.
//
// The structure expected in `indirect_buffer` must conform to `Dispatch_Indirect`.
compute_pass_dispatch_workgroups_indirect :: proc(
	using self: ^Compute_Pass,
	indirect_buffer: Buffer,
	indirect_offset: u64,
) {
	wgpu.compute_pass_encoder_dispatch_workgroups_indirect(
		_ptr,
		indirect_buffer._ptr,
		indirect_offset,
	)
}

// Record the end of the compute pass.
compute_pass_end :: proc(using self: ^Compute_Pass) -> Error_Type {
	_err_data.type = .No_Error

	wgpu.compute_pass_encoder_end(_ptr)

	return _err_data.type
}

// Start a pipeline statistics query on this compute pass. It can be ended with
// `compute_pass_end_pipeline_statistics_query`. Pipeline statistics queries may not be nested.
compute_pass_begin_pipeline_statistics_query :: proc(
	using self: ^Compute_Pass,
	query_set: Query_Set,
	query_index: u32,
) {
	wgpu.compute_pass_encoder_begin_pipeline_statistics_query(_ptr, query_set._ptr, query_index)
}

// End the pipeline statistics query on this compute pass. It can be started with
// `compute_pass_begin_pipeline_statistics_query`. Pipeline statistics queries may not be nested.
compute_pass_end_pipeline_statistics_query :: proc(using self: ^Compute_Pass) {
	wgpu.compute_pass_encoder_end_pipeline_statistics_query(_ptr)
}

// Set debug label.
compute_pass_set_label :: proc(using self: ^Compute_Pass, label: cstring) {
	wgpu.compute_pass_encoder_set_label(_ptr, label)
}

// Increase the reference count.
compute_pass_reference :: proc(using self: ^Compute_Pass) {
	wgpu.compute_pass_encoder_reference(_ptr)
}

// Release the `Compute_Pass`.
compute_pass_release :: proc(using self: ^Compute_Pass) {
	wgpu.compute_pass_encoder_release(_ptr)
}
