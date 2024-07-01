package wgpu

// Package
import wgpu "../bindings"

// In-progress recording of a compute pass.
//
// It can be created with `command_encoder_begin_compute_pass`.
Compute_Pass_Encoder :: struct {
	ptr:       Raw_Compute_Pass_Encoder,
	_err_data: ^Error_Data,
}

// Dispatches compute work operations.
//
// `x`, `y` and `z` denote the number of work groups to dispatch in each dimension.
compute_pass_encoder_dispatch_workgroups :: proc(
	using self: ^Compute_Pass_Encoder,
	workgroup_count_x: u32,
	workgroup_count_y: u32 = 1,
	workgroup_count_z: u32 = 1,
) {
	wgpu.compute_pass_encoder_dispatch_workgroups(
		ptr,
		workgroup_count_x,
		workgroup_count_y,
		workgroup_count_z,
	)
}

// Dispatches compute work operations, based on the contents of the `indirect_buffer`.
//
// The structure expected in `indirect_buffer` must conform to `Dispatch_Indirect`.
compute_pass_encoder_dispatch_workgroups_indirect :: proc(
	using self: ^Compute_Pass_Encoder,
	indirect_buffer: Raw_Buffer,
	indirect_offset: u64,
) {
	wgpu.compute_pass_encoder_dispatch_workgroups_indirect(ptr, indirect_buffer, indirect_offset)
}

// Record the end of the compute pass.
compute_pass_encoder_end :: proc(
	using self: ^Compute_Pass_Encoder,
	loc := #caller_location,
) -> (
	err: Error,
) {
	set_and_reset_err_data(_err_data, loc)

	wgpu.compute_pass_encoder_end(ptr)

	err = get_last_error()

	return
}

// Inserts debug marker.
compute_pass_encoder_insert_debug_marker :: proc(
	using self: ^Compute_Pass_Encoder,
	marker_label: cstring,
) {
	wgpu.compute_pass_encoder_insert_debug_marker(ptr, marker_label)
}

// Stops command recording and creates debug group.
compute_pass_encoder_pop_debug_group :: proc(using self: ^Compute_Pass_Encoder) {
	wgpu.compute_pass_encoder_pop_debug_group(ptr)
}

// Start record commands and group it into debug marker group.
compute_pass_encoder_push_debug_group :: proc(
	using self: ^Compute_Pass_Encoder,
	group_label: cstring,
) {
	wgpu.compute_pass_encoder_push_debug_group(ptr, group_label)
}

// Sets the active bind group for a given bind group index. The bind group layout in the active
// pipeline when the `compute_pass_dispatch_workgroups` function is called must match the layout of
// this bind group.
//
// If the bind group have dynamic offsets, provide them in the binding order. These offsets have to
// be aligned to limits `min_uniform_buffer_offset_alignment` or limits
// `min_storage_buffer_offset_alignment` appropriately.
compute_pass_encoder_set_bind_group :: proc(
	using self: ^Compute_Pass_Encoder,
	group_index: u32,
	group: Raw_Bind_Group,
	dynamic_offsets: []Dynamic_Offset = {},
) {
	dynamic_offset_count := uint(len(dynamic_offsets))

	if dynamic_offset_count == 0 {
		wgpu.compute_pass_encoder_set_bind_group(ptr, group_index, group, 0, nil)
	} else {
		wgpu.compute_pass_encoder_set_bind_group(
			ptr,
			group_index,
			group,
			dynamic_offset_count,
			raw_data(dynamic_offsets),
		)
	}
}

// Set debug label.
compute_pass_encoder_set_label :: proc(using self: ^Compute_Pass_Encoder, label: cstring) {
	wgpu.compute_pass_encoder_set_label(ptr, label)
}

// Sets the active compute pipeline.
compute_pass_encoder_set_pipeline :: proc(
	using self: ^Compute_Pass_Encoder,
	pipeline: Raw_Compute_Pipeline,
) {
	wgpu.compute_pass_encoder_set_pipeline(ptr, pipeline)
}

// Start a pipeline statistics query on this compute pass. It can be ended with
// `compute_pass_end_pipeline_statistics_query`. Pipeline statistics queries may not be nested.
compute_pass_encoder_begin_pipeline_statistics_query :: proc(
	using self: ^Compute_Pass_Encoder,
	query_set: Raw_Query_Set,
	query_index: u32,
) {
	wgpu.compute_pass_encoder_begin_pipeline_statistics_query(ptr, query_set, query_index)
}

// End the pipeline statistics query on this compute pass. It can be started with
// `compute_pass_begin_pipeline_statistics_query`. Pipeline statistics queries may not be nested.
compute_pass_encoder_end_pipeline_statistics_query :: proc(using self: ^Compute_Pass_Encoder) {
	wgpu.compute_pass_encoder_end_pipeline_statistics_query(ptr)
}

// Increase the reference count.
compute_pass_encoder_reference :: proc(using self: ^Compute_Pass_Encoder) {
	wgpu.compute_pass_encoder_reference(ptr)
}

// Release the `Compute_Pass_Encoder`.
compute_pass_encoder_release :: proc(using self: ^Compute_Pass_Encoder) {
	wgpu.compute_pass_encoder_release(ptr)
}

// Release the `Compute_Pass_Encoder` and modify the raw pointer to `nil`.
compute_pass_encoder_release_and_nil :: proc(using self: ^Compute_Pass_Encoder) {
	if ptr == nil do return
	wgpu.compute_pass_encoder_release(ptr)
	ptr = nil
}
