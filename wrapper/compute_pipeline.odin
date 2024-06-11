package wgpu

// Package
import wgpu "../bindings"

// Handle to a compute pipeline.
//
// A `Compute_Pipeline` object represents a compute pipeline and its single shader stage. It can be
// created with `device_create_compute_pipeline`.
Compute_Pipeline :: struct {
	ptr:       Raw_Compute_Pipeline,
	_err_data: ^Error_Data,
}

// Get an object representing the bind group layout at a given index.
compute_pipeline_get_bind_group_layout :: proc(
	using self: ^Compute_Pipeline,
	group_index: u32,
	loc := #caller_location,
) -> (
	bind_group_layout: Bind_Group_Layout,
	err: Error,
) {
	set_and_reset_err_data(_err_data, loc)

	bind_group_layout.ptr = wgpu.compute_pipeline_get_bind_group_layout(ptr, group_index)

	if err = get_last_error(); err != nil {
		if bind_group_layout.ptr != nil {
			wgpu.bind_group_layout_release(bind_group_layout.ptr)
			return
		}
	}

	if bind_group_layout.ptr == nil {
		err = Error_Type.Unknown
		update_error_data(_err_data, .Assert, err, "Failed to acquire Bind_Group_Layout")
	}

	return
}

// Set debug label.
compute_pipeline_set_label :: proc(using self: ^Compute_Pipeline, label: cstring) {
	wgpu.compute_pipeline_set_label(ptr, label)
}

// Increase the reference count.
compute_pipeline_reference :: proc(using self: ^Compute_Pipeline) {
	wgpu.compute_pipeline_reference(ptr)
}

// Release the `Compute_Pipeline`.
compute_pipeline_release :: proc(using self: ^Compute_Pipeline) {
	wgpu.compute_pipeline_release(ptr)
}

// Release the `Compute_Pipeline`and modify the raw pointer to `nil`.
compute_pipeline_release_and_nil :: proc(using self: ^Compute_Pipeline) {
	if ptr == nil do return
	wgpu.compute_pipeline_release(ptr)
	ptr = nil
}
