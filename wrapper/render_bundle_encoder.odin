package wgpu

// Package
import wgpu "../bindings"

// Encodes a series of GPU operations into a reusable "render bundle".
//
// It only supports a handful of render commands, but it makes them reusable. It can be created
// with `device_create_render_bundle_encoder`. It can be executed onto a `Command_Encoder` using
// `render_pass_execute_bundles`.
//
// Executing a `Render_Bundle` is often more efficient than issuing the underlying commands
// manually.
Render_Bundle_Encoder :: struct {
	_ptr: WGPU_Render_Bundle_Encoder,
}

// Finishes recording and returns a `Render_Bundle` that can be executed in other render passes.
render_bundle_encoder_finish :: proc(
	using self: ^Render_Bundle_Encoder,
	descriptor: ^Render_Bundle_Descriptor,
) -> (
	render_bundle: Render_Bundle,
	err: Error_Type,
) {
	desc: wgpu.Render_Bundle_Descriptor

	if descriptor != nil {
		desc.label = descriptor.label
	}

	render_bundle_ptr := wgpu.render_bundle_encoder_finish(_ptr, &desc)

	if render_bundle_ptr == nil {
		update_error_message("Failed to acquire RenderBundle")
		return {}, .Unknown
	}

	render_bundle._ptr = render_bundle_ptr

	return
}

// Sets the active bind group for a given bind group index. The bind group layout in the active
// pipeline when any `draw` procedure is called must match the layout of this bind group.
//
// If the bind group have dynamic offsets, provide them in the binding order.
render_bundle_encoder_set_bind_group :: proc(
	using self: ^Render_Bundle_Encoder,
	group_index: u32,
	group: ^Bind_Group,
	dynamic_offsets: []u32 = {},
) {
	dynamic_offset_count := cast(uint)len(dynamic_offsets)

	if dynamic_offset_count == 0 {
		wgpu.render_bundle_encoder_set_bind_group(_ptr, group_index, group._ptr, 0, nil)
	} else {
		wgpu.render_bundle_encoder_set_bind_group(
			_ptr,
			group_index,
			group._ptr,
			dynamic_offset_count,
			raw_data(dynamic_offsets),
		)
	}
}

// Sets the active render pipeline.
//
// Subsequent draw calls will exhibit the behavior defined by pipeline.
render_bundle_encoder_set_pipeline :: proc(
	using self: ^Render_Bundle_Encoder,
	pipeline: Render_Pipeline,
) {
	wgpu.render_bundle_encoder_set_pipeline(_ptr, pipeline._ptr)
}

// Sets the active index buffer.
//
// Subsequent calls to draw_indexed on this `Render_Bundle_Encoder` will use buffer as the source
// index buffer.
render_bundle_encoder_set_index_buffer :: proc(
	using self: ^Render_Bundle_Encoder,
	buffer: Buffer,
	format: Index_Format,
	offset: u64 = 0,
	size: u64 = WHOLE_SIZE,
) {
	wgpu.render_bundle_encoder_set_index_buffer(_ptr, buffer._ptr, format, offset, size)
}

// Assign a vertex buffer to a slot.
//
// Subsequent calls to `draw` and `draw_indexed` on this `Render_Bundle_Encoder` will use buffer as
// one of the source vertex buffers.
//
// The slot refers to the index of the matching descriptor in `VertexState.buffers`.
render_bundle_encoder_set_vertex_buffer :: proc(
	using self: ^Render_Bundle_Encoder,
	slot: u32,
	buffer: Buffer,
	offset: u64 = 0,
	size: u64 = WHOLE_SIZE,
) {
	wgpu.render_bundle_encoder_set_vertex_buffer(_ptr, slot, buffer._ptr, offset, size)
}

// Draws primitives from the active vertex buffer(s).
render_bundle_encoder_draw :: proc(
	using self: ^Render_Bundle_Encoder,
	vertex_count: u32,
	instance_count: u32 = 1,
	first_vertex: u32 = 0,
	first_instance: u32 = 0,
) {
	wgpu.render_bundle_encoder_draw(
		_ptr,
		vertex_count,
		instance_count,
		first_vertex,
		first_instance,
	)
}

// Draws indexed primitives using the active index buffer and the active vertex buffer(s).
render_bundle_encoder_draw_indexed :: proc(
	using self: ^Render_Bundle_Encoder,
	index_count: u32,
	instance_count: u32 = 1,
	firstIndex: u32 = 0,
	base_vertex: i32 = 0,
	first_instance: u32 = 0,
) {
	wgpu.render_bundle_encoder_draw_indexed(
		_ptr,
		index_count,
		instance_count,
		firstIndex,
		base_vertex,
		first_instance,
	)
}

// Draws indexed primitives using the active index buffer and the active vertex buffers, based on
// the contents of the `indirect_buffer`.
render_bundle_encoder_draw_indexed_indirect :: proc(
	using self: ^Render_Bundle_Encoder,
	indirect_buffer: Buffer,
	indirect_offset: u64 = 0,
) {
	wgpu.render_bundle_encoder_draw_indexed_indirect(_ptr, indirect_buffer._ptr, indirect_offset)
}

// Draws primitives from the active vertex buffer(s) based on the contents of the `indirect_buffer`.
render_bundle_encoder_draw_indirect :: proc(
	using self: ^Render_Bundle_Encoder,
	indirect_buffer: Buffer,
	indirect_offset: u64 = 0,
) {
	wgpu.render_bundle_encoder_draw_indirect(_ptr, indirect_buffer._ptr, indirect_offset)
}

// // Set push constant data for subsequent draw calls.
// //
// // Write the bytes in `data` at offset `offset` within push constant storage, all of which are
// // accessible by all the pipeline stages in `stages`, and no others. Both `offset` and the length
// // of `data` must be multiples of `Push_Constant_Alignment`, which is always `4`.
// render_bundle_encoder_set_push_constants :: proc(
// 	using self: ^Render_Bundle_Encoder,
// 	stages: Shader_Stage_Flags,
// 	offset: u32,
// 	data: []byte,
// ) {
// 	size := cast(u32)len(data)

// 	if size == 0 {
// 		wgpu.render_bundle_encoder_set_push_constants(_ptr, stages, offset, 0, nil)
// 		return
// 	}

// 	wgpu.render_bundle_encoder_set_push_constants(_ptr, stages, offset, size, raw_data(data))
// }

// Inserts debug marker.
render_bundle_encoder_insert_debug_marker :: proc(
	using self: ^Render_Bundle_Encoder,
	marker_label: cstring,
) {
	wgpu.render_bundle_encoder_insert_debug_marker(_ptr, marker_label)
}

// Start record commands and group it into debug marker group.
render_bundle_encoder_push_debug_group :: proc(
	using self: ^Render_Bundle_Encoder,
	group_label: cstring,
) {
	wgpu.render_bundle_encoder_push_debug_group(_ptr, group_label)
}

// Stops command recording and creates debug group.
render_bundle_encoder_pop_debug_group :: proc(using self: ^Render_Bundle_Encoder) {
	wgpu.render_bundle_encoder_pop_debug_group(_ptr)
}

// Set debug label.
render_bundle_encoder_set_label :: proc(using self: ^Render_Bundle_Encoder, label: cstring) {
	wgpu.render_bundle_encoder_set_label(_ptr, label)
}

// Increase the reference count.
render_bundle_encoder_reference :: proc(using self: ^Render_Bundle_Encoder) {
	wgpu.render_bundle_encoder_reference(_ptr)
}

// Release the `Render_Bundle_Encoder`.
render_bundle_encoder_release :: proc(using self: ^Render_Bundle_Encoder) {
	wgpu.render_bundle_encoder_release(_ptr)
}
