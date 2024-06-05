package wgpu

// Package
import wgpu "../bindings"

// Handle to a compute pipeline.
//
// A `Compute_Pipeline` object represents a compute pipeline and its single shader stage. It can be
// created with `device_create_compute_pipeline`.
Compute_Pipeline :: struct {
	ptr: Raw_Compute_Pipeline,
}

// Get an object representing the bind group layout at a given index.
compute_pipeline_get_bind_group_layout :: proc(
	using self: ^Compute_Pipeline,
	group_index: u32,
) -> (
	bind_group_layout: Bind_Group_Layout,
	err: Error_Type,
) {
	bind_group_layout.ptr = wgpu.compute_pipeline_get_bind_group_layout(ptr, group_index)

	if bind_group_layout.ptr == nil {
		update_error_message("Failed to acquire Bind_Group_Layout")
		return {}, .Unknown
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
