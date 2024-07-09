package wgpu

// Package
import wgpu "../bindings"

// In-progress recording of a render pass: a list of render commands in a `Command_Encoder`.
//
// It can be created with `command_encoder_begin_render_pass`, whose `Render_Pass_Descriptor`
// specifies the attachments (textures) that will be rendered to.
Render_Pass :: struct {
	ptr:       Raw_Render_Pass_Encoder,
	_err_data: ^Error_Data,
}

// Start a occlusion query on this render pass. It can be ended with
// `render_pass_end_occlusion_query`. Occlusion queries may not be nested.
render_pass_begin_occlusion_query :: proc "contextless" (
	using self: Render_Pass,
	query_index: u32,
) {
	wgpu.render_pass_encoder_begin_occlusion_query(ptr, query_index)
}

// Draws primitives from the active vertex buffer(s).
//
// The active vertex buffer(s) can be set with [`render_pass_encoder_set_vertex_buffer`].
// Does not use an Index Buffer. If you need this see [`render_pass_encoder_draw_indexed`]
//
// Panics if vertices Range is outside of the range of the vertices range of any set vertex buffer.
render_pass_draw :: proc "contextless" (
	using self: Render_Pass,
	vertices: Range(u32),
	instances: Range(u32) = {start = 0, end = 1},
) {
	wgpu.render_pass_encoder_draw(
		ptr,
		vertices.end - vertices.start,
		instances.end - vertices.start,
		vertices.start,
		instances.start,
	)
}

// Draws indexed primitives using the active index buffer and the active vertex buffers.
render_pass_draw_indexed :: proc "contextless" (
	using self: Render_Pass,
	indices: Range(u32),
	base_vertex: i32 = 0,
	instances: Range(u32) = {start = 0, end = 1},
) {
	wgpu.render_pass_encoder_draw_indexed(
		ptr,
		indices.end - indices.start,
		instances.end - indices.start,
		indices.start,
		base_vertex,
		instances.start,
	)
}

// Draws indexed primitives using the active index buffer and the active vertex buffers,
// based on the contents of the `indirect_buffer`.
render_pass_draw_indexed_indirect :: proc "contextless" (
	using self: Render_Pass,
	indirect_buffer: Raw_Buffer,
	indirect_offset: Buffer_Address = 0,
) {
	wgpu.render_pass_encoder_draw_indexed_indirect(ptr, indirect_buffer, indirect_offset)
}

// Draws primitives from the active vertex buffer(s) based on the contents of the
// `indirect_buffer`.
render_pass_draw_indirect :: proc "contextless" (
	using self: Render_Pass,
	indirect_buffer: Raw_Buffer,
	indirect_offset: Buffer_Address = 0,
) {
	wgpu.render_pass_encoder_draw_indirect(ptr, indirect_buffer, indirect_offset)
}

// Record the end of the render pass.
render_pass_end :: proc "contextless" (
	using self: Render_Pass,
	loc := #caller_location,
) -> (
	err: Error,
) {
	set_and_reset_err_data(_err_data, loc)
	wgpu.render_pass_encoder_end(ptr)
	err = get_last_error()

	return
}

// End the occlusion query on this render pass. It can be started with begin_occlusion_query.
// Occlusion queries may not be nested.
render_pass_end_occlusion_query :: proc "contextless" (using self: Render_Pass) {
	wgpu.render_pass_encoder_end_occlusion_query(ptr)
}

// Execute a render bundle, which is a set of pre-recorded commands that can be run
// together.
render_pass_execute_bundles :: proc "contextless" (
	using self: Render_Pass,
	bundles: ..Raw_Render_Bundle,
) {
	if len(bundles) == 0 {
		wgpu.render_pass_encoder_execute_bundles(ptr, 0, nil)
		return
	} else if len(bundles) == 1 {
		wgpu.render_pass_encoder_execute_bundles(ptr, 1, &bundles[0])
		return
	}

	wgpu.render_pass_encoder_execute_bundles(ptr, uint(len(bundles)), raw_data(bundles))
}

// Inserts debug marker.
render_pass_insert_debug_marker :: proc "contextless" (
	using self: Render_Pass,
	marker_label: cstring,
) {
	wgpu.render_pass_encoder_insert_debug_marker(ptr, marker_label)
}

// Stops command recording and creates debug group.
render_pass_pop_debug_group :: proc "contextless" (using self: Render_Pass) {
	wgpu.render_pass_encoder_pop_debug_group(ptr)
}

// Start record commands and group it into debug marker group.
render_pass_push_debug_group :: proc "contextless" (
	using self: Render_Pass,
	group_label: cstring,
) {
	wgpu.render_pass_encoder_push_debug_group(ptr, group_label)
}

// Sets the active bind group for a given bind group index. The bind group layout in the
// active pipeline when any draw() function is called must match the layout of this bind
// group.
render_pass_set_bind_group :: proc "contextless" (
	using self: Render_Pass,
	group_index: u32,
	group: Raw_Bind_Group,
	dynamic_offsets: []u32 = nil,
) {
	wgpu.render_pass_encoder_set_bind_group(
		ptr,
		group_index,
		group,
		len(dynamic_offsets),
		raw_data(dynamic_offsets),
	)
}

// Sets the blend color as used by some of the blending modes.
render_pass_set_blend_constant :: proc "contextless" (using self: Render_Pass, color: Color) {
	color := color
	wgpu.render_pass_encoder_set_blend_constant(ptr, &color)
}

// Sets the active index buffer.
render_pass_set_index_buffer :: proc "contextless" (
	using self: Render_Pass,
	buffer: Raw_Buffer,
	index_format: Index_Format,
	range: Buffer_Range = {},
) {
	wgpu.render_pass_encoder_set_index_buffer(
		ptr,
		buffer,
		index_format,
		range.offset,
		range.size if range.size > 0 else WHOLE_SIZE,
	)
}

// Set debug label.
render_pass_set_label :: proc "contextless" (using self: Render_Pass, label: cstring) {
	wgpu.render_pass_encoder_set_label(ptr, label)
}

// Sets the active render pipeline.
render_pass_set_pipeline :: proc "contextless" (
	using self: Render_Pass,
	pipeline: Raw_Render_Pipeline,
) {
	wgpu.render_pass_encoder_set_pipeline(ptr, pipeline)
}

// Sets the scissor rectangle used during the rasterization stage.
// After transformation into [viewport coordinates](https://www.w3.org/TR/webgpu/#viewport-coordinates).
//
// Subsequent draw calls will discard any fragments which fall outside the scissor rectangle.
// If this method has not been called, the scissor rectangle defaults to the entire bounds of
// the render targets.
//
// The function of the scissor rectangle resembles [`set_viewport()`](Self::set_viewport),
// but it does not affect the coordinate system, only which fragments are discarded.
render_pass_set_scissor_rect :: proc "contextless" (
	using self: Render_Pass,
	x, y, width, height: u32,
) {
	wgpu.render_pass_encoder_set_scissor_rect(ptr, x, y, width, height)
}

// Sets the stencil reference.
//
// Subsequent stencil tests will test against this value. If this procedure has not been called,
// the  stencil reference value defaults to `0`.
render_pass_set_stencil_reference :: proc "contextless" (self: Render_Pass, reference: u32) {
	wgpu.render_pass_encoder_set_stencil_reference(self.ptr, reference)
}

// Assign a vertex buffer to a slot.
render_pass_set_vertex_buffer :: proc "contextless" (
	using self: Render_Pass,
	slot: u32,
	buffer: Raw_Buffer,
	range: Buffer_Range = {},
) {
	wgpu.render_pass_encoder_set_vertex_buffer(
		ptr,
		slot,
		buffer,
		range.offset,
		range.size if range.size > 0 else WHOLE_SIZE,
	)
}

// Sets the viewport used during the rasterization stage to linearly map from normalized
// device coordinates to viewport coordinates.
render_pass_set_viewport :: proc "contextless" (
	using self: Render_Pass,
	x, y, width, height, min_depth, max_depth: f32,
) {
	wgpu.render_pass_encoder_set_viewport(ptr, x, y, width, height, min_depth, max_depth)
}

// Increase the reference count.
render_pass_reference :: proc "contextless" (using self: Render_Pass) {
	wgpu.render_pass_encoder_reference(ptr)
}

// Release the `Render_Pass`.
render_pass_release :: #force_inline proc "contextless" (using self: Render_Pass) {
	wgpu.render_pass_encoder_release(ptr)
}

// Release the `Render_Pass` and modify the raw pointer to `nil`.
render_pass_release_and_nil :: proc "contextless" (using self: ^Render_Pass) {
	if ptr == nil do return
	wgpu.render_pass_encoder_release(ptr)
	ptr = nil
}

// Set push constant data for subsequent draw calls.
//
// Write the bytes in `data` at offset `offset` within push constant storage, all of which are
// accessible by all the pipeline stages in `stages`, and no others. Both `offset` and the length
// of `data` must be multiples of `PUSH_CONSTANT_ALIGNMENT`, which is always `4`.
render_pass_set_push_constants :: proc "contextless" (
	using self: Render_Pass,
	stages: Shader_Stage_Flags,
	offset: u32,
	data: []byte,
) {
	if len(data) == 0 {
		wgpu.render_pass_encoder_set_push_constants(ptr, stages, offset, 0, nil)
		return
	}

	wgpu.render_pass_encoder_set_push_constants(
		ptr,
		stages,
		offset,
		cast(u32)len(data),
		raw_data(data),
	)
}

render_pass_multi_draw_indirect :: proc "contextless" (
	using self: Render_Pass,
	buffer: Raw_Buffer,
	offset: u64,
	count: u32,
) {
	wgpu.render_pass_encoder_multi_draw_indirect(ptr, buffer, offset, count)
}

render_pass_multi_draw_indexed_indirect :: proc "contextless" (
	using self: Render_Pass,
	buffer: Raw_Buffer,
	offset: u64,
	count: u32,
) {
	wgpu.render_pass_encoder_multi_draw_indexed_indirect(ptr, buffer, offset, count)
}

render_pass_multi_draw_indirect_count :: proc "contextless" (
	using self: Render_Pass,
	buffer: Raw_Buffer,
	offset: u64,
	count_buffer: Raw_Buffer,
	count_buffer_offset, max_count: u32,
) {
	wgpu.render_pass_encoder_multi_draw_indirect_count(
		ptr,
		buffer,
		offset,
		count_buffer,
		count_buffer_offset,
		max_count,
	)
}

render_pass_multi_draw_indexed_indirect_count :: proc "contextless" (
	using self: Render_Pass,
	buffer: Raw_Buffer,
	offset: u64,
	count_buffer: Raw_Buffer,
	count_buffer_offset, max_count: u32,
) {
	wgpu.render_pass_encoder_multi_draw_indexed_indirect_count(
		ptr,
		buffer,
		offset,
		count_buffer,
		count_buffer_offset,
		max_count,
	)
}

// Start a pipeline statistics query on this render pass. It can be ended with
// `render_pass_end_pipeline_statistics_query`. Pipeline statistics queries may not be nested.
render_pass_begin_pipeline_statistics_query :: proc "contextless" (
	using self: Render_Pass,
	query_set: Raw_Query_Set,
	query_index: u32,
) {
	wgpu.render_pass_encoder_begin_pipeline_statistics_query(ptr, query_set, query_index)
}

// End the pipeline statistics query on this render pass. It can be started with
// `begin_pipeline_statistics_query`. Pipeline statistics queries may not be nested.
render_pass_end_pipeline_statistics_query :: proc "contextless" (using self: Render_Pass) {
	wgpu.render_pass_encoder_end_pipeline_statistics_query(ptr)
}
