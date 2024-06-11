package wgpu

// Package
import wgpu "../bindings"

// Handle to a rendering (graphics) pipeline.
//
// A `Render_Pipeline` object represents a graphics pipeline and its stages, bindings, vertex
// buffers and targets. It can be created with `device_create_render_pipeline`.
Render_Pipeline :: struct {
	ptr:       Raw_Render_Pipeline,
	_err_data: ^Error_Data,
}

// Get an object representing the bind group layout at a given index.
render_pipeline_get_bind_group_layout :: proc(
	using self: ^Render_Pipeline,
	group_index: u32,
	loc := #caller_location,
) -> (
	bind_group_layout: Bind_Group_Layout,
	err: Error,
) {
	set_and_reset_err_data(_err_data, loc)

	bind_group_layout.ptr = wgpu.render_pipeline_get_bind_group_layout(ptr, group_index)

	if err = get_last_error(); err != nil {
		if bind_group_layout.ptr != nil {
			wgpu.bind_group_layout_release(bind_group_layout.ptr)
			return
		}
	}

	if bind_group_layout.ptr == nil {
		err = Error_Type.Unknown
		set_and_update_err_data(
			_err_data,
			.Assert,
			err,
			"Failed to acquire Bind_Group_Layout",
			loc,
		)
	}

	return
}

// set debug label.
render_pipeline_set_label :: proc(using self: ^Render_Pipeline, label: cstring) {
	wgpu.render_pipeline_set_label(ptr, label)
}

// Increase the reference count.
render_pipeline_reference :: proc(using self: ^Render_Pipeline) {
	wgpu.render_pipeline_reference(ptr)
}

// Release the `Render_Pipeline`.
render_pipeline_release :: proc(using self: ^Render_Pipeline) {
	wgpu.render_pipeline_release(ptr)
}

// Release the `Render_Pipeline` and modify the raw pointer to `nil`.
render_pipeline_release_and_nil :: proc(using self: ^Render_Pipeline) {
	if ptr == nil do return
	wgpu.render_pipeline_release(ptr)
	ptr = nil
}
