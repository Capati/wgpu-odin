package wgpu

// Base
import "base:runtime"

// Package
import wgpu "../bindings"

// Encodes a series of GPU operations into a reusable "render bundle".
//
// It only supports a handful of render commands, but it makes them reusable. It can be created
// with `device_create_render_bundle_encoder`. It can be executed onto a `Command_Encoder` using
// `render_pass_encoder_execute_bundles`.
//
// Executing a `Render_Bundle` is often more efficient than issuing the underlying commands
// manually.
Render_Bundle_Encoder :: struct {
	ptr:       Raw_Render_Bundle_Encoder,
	_err_data: ^Error_Data,
}

// Draws primitives from the active vertex buffer(s).
render_bundle_encoder_draw :: proc "contextless" (
	using self: Render_Bundle_Encoder,
	vertex_count: u32,
	instance_count: u32 = 1,
	first_vertex: u32 = 0,
	first_instance: u32 = 0,
) {
	wgpu.render_bundle_encoder_draw(
		ptr,
		vertex_count,
		instance_count,
		first_vertex,
		first_instance,
	)
}

// Draws indexed primitives using the active index buffer and the active vertex buffer(s).
render_bundle_encoder_draw_indexed :: proc "contextless" (
	using self: Render_Bundle_Encoder,
	index_count: u32,
	instance_count: u32 = 1,
	firstIndex: u32 = 0,
	base_vertex: i32 = 0,
	first_instance: u32 = 0,
) {
	wgpu.render_bundle_encoder_draw_indexed(
		ptr,
		index_count,
		instance_count,
		firstIndex,
		base_vertex,
		first_instance,
	)
}

// Draws indexed primitives using the active index buffer and the active vertex buffers, based on
// the contents of the `indirect_buffer`.
render_bundle_encoder_draw_indexed_indirect :: proc "contextless" (
	using self: Render_Bundle_Encoder,
	indirect_buffer: Raw_Buffer,
	indirect_offset: u64 = 0,
) {
	wgpu.render_bundle_encoder_draw_indexed_indirect(ptr, indirect_buffer, indirect_offset)
}

// Draws primitives from the active vertex buffer(s) based on the contents of the `indirect_buffer`.
render_bundle_encoder_draw_indirect :: proc "contextless" (
	using self: Render_Bundle_Encoder,
	indirect_buffer: Raw_Buffer,
	indirect_offset: u64 = 0,
) {
	wgpu.render_bundle_encoder_draw_indirect(ptr, indirect_buffer, indirect_offset)
}

// Finishes recording and returns a `Render_Bundle` that can be executed in other render passes.
@(require_results)
render_bundle_encoder_finish :: proc "contextless" (
	using self: Render_Bundle_Encoder,
	descriptor: Render_Bundle_Descriptor = {},
	loc := #caller_location,
) -> (
	render_bundle: Render_Bundle,
	err: Error,
) {
	set_and_reset_err_data(_err_data, loc)

	descriptor := descriptor
	render_bundle.ptr = wgpu.render_bundle_encoder_finish(
		ptr,
		&descriptor if descriptor != {} else nil,
	)

	if err = get_last_error(); err != nil {
		if render_bundle.ptr != nil {
			wgpu.render_bundle_release(render_bundle.ptr)
		}
		return
	}

	when WGPU_ENABLE_ERROR_HANDLING {
		context = runtime.default_context()
		if render_bundle.ptr == nil {
			err = Error_Type.Unknown
			set_and_update_err_data(nil, .General, err, "Failed to acquire Render_Bundle", loc)
		}
	}

	return
}

// Inserts debug marker.
render_bundle_encoder_insert_debug_marker :: proc "contextless" (
	using self: Render_Bundle_Encoder,
	marker_label: cstring,
) {
	wgpu.render_bundle_encoder_insert_debug_marker(ptr, marker_label)
}

// Stops command recording and creates debug group.
render_bundle_encoder_pop_debug_group :: proc "contextless" (using self: Render_Bundle_Encoder) {
	wgpu.render_bundle_encoder_pop_debug_group(ptr)
}

// Start record commands and group it into debug marker group.
render_bundle_encoder_push_debug_group :: proc "contextless" (
	using self: Render_Bundle_Encoder,
	group_label: cstring,
) {
	wgpu.render_bundle_encoder_push_debug_group(ptr, group_label)
}

// Sets the active bind group for a given bind group index. The bind group layout in the active
// pipeline when any `draw` procedure is called must match the layout of this bind group.
//
// If the bind group have dynamic offsets, provide them in the binding order.
render_bundle_encoder_set_bind_group :: proc "contextless" (
	using self: Render_Bundle_Encoder,
	group_index: u32,
	group: Raw_Bind_Group,
	dynamic_offsets: []u32 = nil,
) {
	wgpu.render_bundle_encoder_set_bind_group(
		ptr,
		group_index,
		group,
		len(dynamic_offsets),
		raw_data(dynamic_offsets),
	)
}

// Sets the active index buffer.
//
// Subsequent calls to draw_indexed on this `Render_Bundle_Encoder` will use buffer as the source
// index buffer.
render_bundle_encoder_set_index_buffer :: proc "contextless" (
	using self: Render_Bundle_Encoder,
	buffer: Raw_Buffer,
	format: Index_Format,
	offset: u64 = 0,
	size: u64 = WHOLE_SIZE,
) {
	wgpu.render_bundle_encoder_set_index_buffer(ptr, buffer, format, offset, size)
}

// Set debug label.
render_bundle_encoder_set_label :: proc "contextless" (
	using self: Render_Bundle_Encoder,
	label: cstring,
) {
	wgpu.render_bundle_encoder_set_label(ptr, label)
}

// Sets the active render pipeline.
//
// Subsequent draw calls will exhibit the behavior defined by pipeline.
render_bundle_encoder_set_pipeline :: proc "contextless" (
	using self: Render_Bundle_Encoder,
	pipeline: Raw_Render_Pipeline,
) {
	wgpu.render_bundle_encoder_set_pipeline(ptr, pipeline)
}

// Assign a vertex buffer to a slot.
//
// Subsequent calls to `draw` and `draw_indexed` on this `Render_Bundle_Encoder` will use buffer as
// one of the source vertex buffers.
//
// The slot refers to the index of the matching descriptor in `VertexState.buffers`.
render_bundle_encoder_set_vertex_buffer :: proc "contextless" (
	using self: Render_Bundle_Encoder,
	slot: u32,
	buffer: Raw_Buffer,
	offset: u64 = 0,
	size: u64 = WHOLE_SIZE,
) {
	wgpu.render_bundle_encoder_set_vertex_buffer(ptr, slot, buffer, offset, size)
}

// Increase the reference count.
render_bundle_encoder_reference :: proc "contextless" (using self: Render_Bundle_Encoder) {
	wgpu.render_bundle_encoder_reference(ptr)
}

// Release the `Render_Bundle_Encoder`.
render_bundle_encoder_release :: #force_inline proc "contextless" (
	using self: Render_Bundle_Encoder,
) {
	wgpu.render_bundle_encoder_release(ptr)
}

// Release the `Render_Bundle_Encoder` and modify the raw pointer to `nil`.
render_bundle_encoder_release_and_nil :: proc "contextless" (using self: ^Render_Bundle_Encoder) {
	if ptr == nil do return
	wgpu.render_bundle_encoder_release(ptr)
	ptr = nil
}
