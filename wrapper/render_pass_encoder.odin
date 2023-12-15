package wgpu

// Core
import "core:runtime"

// Package
import wgpu "../bindings"

// In-progress recording of a render pass: a list of render commands in a `Command_Encoder`.
//
// It can be created with `command_encoder_begin_render_pass`, whose `Render_Pass_Descriptor`
// specifies the attachments (textures) that will be rendered to.
Render_Pass :: struct {
	_ptr:      WGPU_Render_Pass_Encoder,
	_err_data: ^Error_Data,
}

// Sets the active bind group for a given bind group index. The bind group layout in the
// active pipeline when any draw() function is called must match the layout of this bind
// group.
render_pass_set_bind_group :: proc(
	using self: ^Render_Pass,
	group_index: u32,
	group: ^Bind_Group,
	dynamic_offsets: []u32 = {},
) {
	dynamic_offset_count := cast(uint)len(dynamic_offsets)

	if dynamic_offset_count == 0 {
		wgpu.render_pass_encoder_set_bind_group(_ptr, group_index, group._ptr, 0, nil)
	} else {
		wgpu.render_pass_encoder_set_bind_group(
			_ptr,
			group_index,
			group._ptr,
			dynamic_offset_count,
			raw_data(dynamic_offsets),
		)
	}
}

// Sets the active render pipeline.
render_pass_set_pipeline :: proc(using self: ^Render_Pass, pipeline: ^Render_Pipeline) {
	wgpu.render_pass_encoder_set_pipeline(_ptr, pipeline._ptr)
}

// Sets the blend color as used by some of the blending modes.
render_pass_set_blend_constant :: proc(using self: ^Render_Pass, color: ^Color) {
	wgpu.render_pass_encoder_set_blend_constant(_ptr, color)
}

// Sets the active index buffer.
render_pass_set_index_buffer :: proc(
	using self: ^Render_Pass,
	buffer: Buffer,
	format: Index_Format,
	offset: Buffer_Size,
	size: Buffer_Size,
) {
	wgpu.render_pass_encoder_set_index_buffer(_ptr, buffer._ptr, format, offset, size)
}

// Assign a vertex buffer to a slot.
render_pass_set_vertex_buffer :: proc(
	using self: ^Render_Pass,
	slot: u32,
	buffer: Buffer,
	offset: Buffer_Address = 0,
	size: Buffer_Size = WHOLE_SIZE,
) {
	wgpu.render_pass_encoder_set_vertex_buffer(_ptr, slot, buffer._ptr, offset, size)
}

// Sets the scissor rectangle used during the rasterization stage. After transformation
// into viewport coordinates.
render_pass_set_scissor_rect :: proc(using self: ^Render_Pass, x, y, width, height: u32) {
	wgpu.render_pass_encoder_set_scissor_rect(_ptr, x, y, width, height)
}

// Sets the viewport used during the rasterization stage to linearly map from normalized
// device coordinates to viewport coordinates.
render_pass_set_viewport :: proc(
	using self: ^Render_Pass,
	x, y, width, height, min_depth, max_depth: f32,
) {
	wgpu.render_pass_encoder_set_viewport(_ptr, x, y, width, height, min_depth, max_depth)
}

// Sets the stencil reference.
//
// Subsequent stencil tests will test against this value. If this procedure has not been called,
// the  stencil reference value defaults to `0`.
render_pass_set_stencil_reference :: proc(self: ^Render_Pass, reference: u32) {
	wgpu.render_pass_encoder_set_stencil_reference(self._ptr, reference)
}

// Draws primitives from the active vertex buffer(s).
render_pass_draw :: proc(
	using self: ^Render_Pass,
	vertex_count: u32,
	instance_count: u32 = 1,
	first_vertex: u32 = 0,
	first_instance: u32 = 0,
) {
	wgpu.render_pass_encoder_draw(_ptr, vertex_count, instance_count, first_vertex, first_instance)
}

// Inserts debug marker.
render_pass_insert_debug_marker :: proc(using self: ^Render_Pass, marker_label: cstring) {
	wgpu.render_pass_encoder_insert_debug_marker(_ptr, marker_label)
}

// Start record commands and group it into debug marker group.
render_pass_push_debug_group :: proc(using self: ^Render_Pass, group_label: cstring) {
	wgpu.render_pass_encoder_push_debug_group(_ptr, group_label)
}

// Stops command recording and creates debug group.
render_pass_pop_debug_group :: proc(using self: ^Render_Pass) {
	wgpu.render_pass_encoder_pop_debug_group(_ptr)
}

// Draws indexed primitives using the active index buffer and the active vertex buffers.
render_pass_draw_indexed :: proc(
	using self: ^Render_Pass,
	index_count: u32,
	instance_count: u32 = 1,
	firstIndex: u32 = 0,
	base_vertex: i32 = 0,
	first_instance: u32 = 0,
) {
	wgpu.render_pass_encoder_draw_indexed(
		_ptr,
		index_count,
		instance_count,
		firstIndex,
		base_vertex,
		first_instance,
	)
}

// Draws primitives from the active vertex buffer(s) based on the contents of the
// `indirect_buffer`.
render_pass_draw_indirect :: proc(
	using self: ^Render_Pass,
	indirect_buffer: Buffer,
	indirect_offset: u64 = 0,
) {
	wgpu.render_pass_encoder_draw_indirect(_ptr, indirect_buffer._ptr, indirect_offset)
}

// Draws indexed primitives using the active index buffer and the active vertex buffers,
// based on the contents of the `indirect_buffer`.
render_pass_draw_indexed_indirect :: proc(
	using self: ^Render_Pass,
	indirect_buffer: Buffer,
	indirect_offset: u64 = 0,
) {
	wgpu.render_pass_encoder_draw_indexed_indirect(_ptr, indirect_buffer._ptr, indirect_offset)
}

// Record the end of the render pass.
render_pass_end :: proc(using self: ^Render_Pass) -> Error_Type {
	_err_data.type = .No_Error
	wgpu.render_pass_encoder_end(_ptr)

	return _err_data.type
}

// Execute a render bundle, which is a set of pre-recorded commands that can be run
// together.
render_pass_execute_bundles :: proc(using self: ^Render_Pass, bundles: ..Render_Bundle) {
	bundles_count := cast(uint)len(bundles)

	if bundles_count == 0 {
		wgpu.render_pass_encoder_execute_bundles(_ptr, 0, nil)
		return
	} else if bundles_count == 1 {
		wgpu.render_pass_encoder_execute_bundles(_ptr, 1, &bundles[0]._ptr)
		return
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	bundles_ptrs := make([]wgpu.Render_Bundle, bundles_count, context.temp_allocator)

	for v, i in bundles {
		bundles_ptrs[i] = v._ptr
	}

	wgpu.render_pass_encoder_execute_bundles(_ptr, bundles_count, raw_data(bundles_ptrs))
}

// Set push constant data for subsequent draw calls.
//
// Write the bytes in `data` at offset `offset` within push constant storage, all of which are
// accessible by all the pipeline stages in `stages`, and no others. Both `offset` and the length
// of `data` must be multiples of `Push_Constant_Alignment`, which is always `4`.
render_pass_set_push_constants :: proc(
	using self: ^Render_Pass,
	stages: Shader_Stage_Flags,
	offset: u32,
	data: []byte,
) {
	size := cast(u32)len(data)

	if size == 0 {
		wgpu.render_pass_encoder_set_push_constants(_ptr, stages, offset, 0, nil)
		return
	}

	wgpu.render_pass_encoder_set_push_constants(_ptr, stages, offset, size, raw_data(data))
}

// Start a occlusion query on this render pass. It can be ended with
// `render_pass_end_occlusion_query`. Occlusion queries may not be nested.
render_pass_begin_occlusion_query :: proc(using self: ^Render_Pass, query_index: u32) {
	wgpu.render_pass_encoder_begin_occlusion_query(_ptr, query_index)
}

// End the occlusion query on this render pass. It can be started with begin_occlusion_query.
// Occlusion queries may not be nested.
render_pass_end_occlusion_query :: proc(using self: ^Render_Pass) {
	wgpu.render_pass_encoder_end_occlusion_query(_ptr)
}

// Start a pipeline statistics query on this render pass. It can be ended with
// `render_pass_end_pipeline_statistics_query`. Pipeline statistics queries may not be nested.
render_pass_begin_pipeline_statistics_query :: proc(
	using self: ^Render_Pass,
	query_set: Query_Set,
	query_index: u32,
) {
	wgpu.render_pass_encoder_begin_pipeline_statistics_query(_ptr, query_set._ptr, query_index)
}

// End the pipeline statistics query on this render pass. It can be started with
// `begin_pipeline_statistics_query`. Pipeline statistics queries may not be nested.
render_pass_end_pipeline_statistics_query :: proc(using self: ^Render_Pass) {
	wgpu.render_pass_encoder_end_pipeline_statistics_query(_ptr)
}

// Set debug label.
render_pass_set_label :: proc(using self: ^Render_Pass, label: cstring) {
	wgpu.render_pass_encoder_set_label(_ptr, label)
}

// Increase the reference count.
render_pass_reference :: proc(using self: ^Render_Pass) {
	wgpu.render_pass_encoder_reference(_ptr)
}

// Release the `Render_Pass`.
render_pass_release :: proc(using self: ^Render_Pass) {
	wgpu.render_pass_encoder_release(_ptr)
}
