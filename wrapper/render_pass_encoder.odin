package wgpu

// Package
import wgpu "../bindings"

// In-progress recording of a render pass: a list of render commands in a `Command_Encoder`.
//
// It can be created with `command_encoder_begin_render_pass`, whose `Render_Pass_Descriptor`
// specifies the attachments (textures) that will be rendered to.
Render_Pass_Encoder :: struct {
	ptr:       Raw_Render_Pass_Encoder,
	_err_data: ^Error_Data,
}

// Start a occlusion query on this render pass. It can be ended with
// `render_pass_end_occlusion_query`. Occlusion queries may not be nested.
render_pass_encoder_begin_occlusion_query :: proc(
	using self: ^Render_Pass_Encoder,
	query_index: u32,
) {
	wgpu.render_pass_encoder_begin_occlusion_query(ptr, query_index)
}

// Draws primitives from the active vertex buffer(s).
render_pass_encoder_draw :: proc(
	using self: ^Render_Pass_Encoder,
	vertex_count: u32,
	instance_count: u32 = 1,
	first_vertex: u32 = 0,
	first_instance: u32 = 0,
) {
	wgpu.render_pass_encoder_draw(ptr, vertex_count, instance_count, first_vertex, first_instance)
}

// Draws indexed primitives using the active index buffer and the active vertex buffers.
render_pass_encoder_draw_indexed :: proc(
	using self: ^Render_Pass_Encoder,
	index_count: u32,
	instance_count: u32 = 1,
	firstIndex: u32 = 0,
	base_vertex: i32 = 0,
	first_instance: u32 = 0,
) {
	wgpu.render_pass_encoder_draw_indexed(
		ptr,
		index_count,
		instance_count,
		firstIndex,
		base_vertex,
		first_instance,
	)
}

// Draws indexed primitives using the active index buffer and the active vertex buffers,
// based on the contents of the `indirect_buffer`.
render_pass_encoder_draw_indexed_indirect :: proc(
	using self: ^Render_Pass_Encoder,
	indirect_buffer: Raw_Buffer,
	indirect_offset: u64 = 0,
) {
	wgpu.render_pass_encoder_draw_indexed_indirect(ptr, indirect_buffer, indirect_offset)
}

// Draws primitives from the active vertex buffer(s) based on the contents of the
// `indirect_buffer`.
render_pass_encoder_draw_indirect :: proc(
	using self: ^Render_Pass_Encoder,
	indirect_buffer: Raw_Buffer,
	indirect_offset: u64 = 0,
) {
	wgpu.render_pass_encoder_draw_indirect(ptr, indirect_buffer, indirect_offset)
}

// Record the end of the render pass.
render_pass_encoder_end :: proc(
	using self: ^Render_Pass_Encoder,
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
render_pass_encoder_end_occlusion_query :: proc(using self: ^Render_Pass_Encoder) {
	wgpu.render_pass_encoder_end_occlusion_query(ptr)
}

// Execute a render bundle, which is a set of pre-recorded commands that can be run
// together.
render_pass_encoder_execute_bundles :: proc(
	using self: ^Render_Pass_Encoder,
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
render_pass_encoder_insert_debug_marker :: proc(
	using self: ^Render_Pass_Encoder,
	marker_label: cstring,
) {
	wgpu.render_pass_encoder_insert_debug_marker(ptr, marker_label)
}

// Stops command recording and creates debug group.
render_pass_encoder_pop_debug_group :: proc(using self: ^Render_Pass_Encoder) {
	wgpu.render_pass_encoder_pop_debug_group(ptr)
}

// Start record commands and group it into debug marker group.
render_pass_encoder_push_debug_group :: proc(
	using self: ^Render_Pass_Encoder,
	group_label: cstring,
) {
	wgpu.render_pass_encoder_push_debug_group(ptr, group_label)
}

// Sets the active bind group for a given bind group index. The bind group layout in the
// active pipeline when any draw() function is called must match the layout of this bind
// group.
render_pass_encoder_set_bind_group :: proc(
	using self: ^Render_Pass_Encoder,
	group_index: u32,
	group: Raw_Bind_Group,
	dynamic_offsets: []u32 = {},
) {
	if len(dynamic_offsets) == 0 {
		wgpu.render_pass_encoder_set_bind_group(ptr, group_index, group, 0, nil)
	} else {
		wgpu.render_pass_encoder_set_bind_group(
			ptr,
			group_index,
			group,
			uint(len(dynamic_offsets)),
			raw_data(dynamic_offsets),
		)
	}
}

// Sets the blend color as used by some of the blending modes.
render_pass_encoder_set_blend_constant :: proc(using self: ^Render_Pass_Encoder, color: ^Color) {
	wgpu.render_pass_encoder_set_blend_constant(ptr, color)
}

// Sets the active index buffer.
render_pass_encoder_set_index_buffer :: proc(
	using self: ^Render_Pass_Encoder,
	buffer: Raw_Buffer,
	format: Index_Format,
	offset: Buffer_Address = 0,
	size: Buffer_Size = WHOLE_SIZE,
) {
	wgpu.render_pass_encoder_set_index_buffer(ptr, buffer, format, offset, size)
}

// Set debug label.
render_pass_encoder_set_label :: proc(using self: ^Render_Pass_Encoder, label: cstring) {
	wgpu.render_pass_encoder_set_label(ptr, label)
}

// Sets the active render pipeline.
render_pass_encoder_set_pipeline :: proc(
	using self: ^Render_Pass_Encoder,
	pipeline: Raw_Render_Pipeline,
) {
	wgpu.render_pass_encoder_set_pipeline(ptr, pipeline)
}

// Sets the scissor rectangle used during the rasterization stage. After transformation
// into viewport coordinates.
render_pass_encoder_set_scissor_rect :: proc(
	using self: ^Render_Pass_Encoder,
	x, y, width, height: u32,
) {
	wgpu.render_pass_encoder_set_scissor_rect(ptr, x, y, width, height)
}

// Sets the stencil reference.
//
// Subsequent stencil tests will test against this value. If this procedure has not been called,
// the  stencil reference value defaults to `0`.
render_pass_encoder_set_stencil_reference :: proc(self: ^Render_Pass_Encoder, reference: u32) {
	wgpu.render_pass_encoder_set_stencil_reference(self.ptr, reference)
}

// Assign a vertex buffer to a slot.
render_pass_encoder_set_vertex_buffer :: proc(
	using self: ^Render_Pass_Encoder,
	slot: u32,
	buffer: Raw_Buffer,
	offset: Buffer_Address = 0,
	size: Buffer_Size = WHOLE_SIZE,
) {
	wgpu.render_pass_encoder_set_vertex_buffer(ptr, slot, buffer, offset, size)
}

// Sets the viewport used during the rasterization stage to linearly map from normalized
// device coordinates to viewport coordinates.
render_pass_encoder_set_viewport :: proc(
	using self: ^Render_Pass_Encoder,
	x, y, width, height, min_depth, max_depth: f32,
) {
	wgpu.render_pass_encoder_set_viewport(ptr, x, y, width, height, min_depth, max_depth)
}

// Increase the reference count.
render_pass_encoder_reference :: proc(using self: ^Render_Pass_Encoder) {
	wgpu.render_pass_encoder_reference(ptr)
}

// Release the `Render_Pass_Encoder`.
render_pass_encoder_release :: proc(using self: ^Render_Pass_Encoder) {
	wgpu.render_pass_encoder_release(ptr)
}

// Release the `Render_Pass_Encoder` and modify the raw pointer to `nil`.
render_pass_encoder_release_and_nil :: proc(using self: ^Render_Pass_Encoder) {
	if ptr == nil do return
	wgpu.render_pass_encoder_release(ptr)
	ptr = nil
}

// Set push constant data for subsequent draw calls.
//
// Write the bytes in `data` at offset `offset` within push constant storage, all of which are
// accessible by all the pipeline stages in `stages`, and no others. Both `offset` and the length
// of `data` must be multiples of `Push_Constant_Alignment`, which is always `4`.
render_pass_encoder_set_push_constants :: proc(
	using self: ^Render_Pass_Encoder,
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

render_pass_encoder_multi_draw_indirect :: proc(
	using self: ^Render_Pass_Encoder,
	buffer: Raw_Buffer,
	offset: u64,
	count: u32,
) {
	wgpu.render_pass_encoder_multi_draw_indirect(ptr, buffer, offset, count)
}

render_pass_encoder_multi_draw_indexed_indirect :: proc(
	using self: ^Render_Pass_Encoder,
	buffer: Raw_Buffer,
	offset: u64,
	count: u32,
) {
	wgpu.render_pass_encoder_multi_draw_indexed_indirect(ptr, buffer, offset, count)
}

render_pass_encoder_multi_draw_indirect_count :: proc(
	using self: ^Render_Pass_Encoder,
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

render_pass_encoder_multi_draw_indexed_indirect_count :: proc(
	using self: ^Render_Pass_Encoder,
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
render_pass_encoder_begin_pipeline_statistics_query :: proc(
	using self: ^Render_Pass_Encoder,
	query_set: Raw_Query_Set,
	query_index: u32,
) {
	wgpu.render_pass_encoder_begin_pipeline_statistics_query(ptr, query_set, query_index)
}

// End the pipeline statistics query on this render pass. It can be started with
// `begin_pipeline_statistics_query`. Pipeline statistics queries may not be nested.
render_pass_encoder_end_pipeline_statistics_query :: proc(using self: ^Render_Pass_Encoder) {
	wgpu.render_pass_encoder_end_pipeline_statistics_query(ptr)
}
