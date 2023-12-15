package wgpu

// Package
import wgpu "../bindings"

// Handle to a rendering (graphics) pipeline.
//
// A `Render_Pipeline` object represents a graphics pipeline and its stages, bindings, vertex
// buffers and targets. It can be created with `device_create_render_pipeline`.
Render_Pipeline :: struct {
	_ptr: WGPU_Render_Pipeline,
}

// Get an object representing the bind group layout at a given index.
render_pipeline_get_bind_group_layout :: proc(
	using self: ^Render_Pipeline,
	group_index: u32,
) -> (
	bind_group_layout: Bind_Group_Layout,
	err: Error_Type,
) {
	bind_group_layout_ptr := wgpu.render_pipeline_get_bind_group_layout(_ptr, group_index)

	if bind_group_layout_ptr == nil {
		update_error_message("Failed to acquire Bind_Group_Layout")
		return {}, .Unknown
	}

	bind_group_layout._ptr = bind_group_layout_ptr

	return
}

// set debug label.
render_pipeline_set_label :: proc(using self: ^Render_Pipeline, label: cstring) {
	wgpu.render_pipeline_set_label(_ptr, label)
}

// Increase the reference count.
render_pipeline_reference :: proc(using self: ^Render_Pipeline) {
	wgpu.render_pipeline_reference(_ptr)
}

// Release the `Render_Pipeline`.
render_pipeline_release :: proc(using self: ^Render_Pipeline) {
	wgpu.render_pipeline_release(_ptr)
}
