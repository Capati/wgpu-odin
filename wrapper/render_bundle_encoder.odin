package wgpu

// Local packages
import wgpu "../bindings"

/*
Encodes a series of GPU operations into a reusable "render bundle".

It only supports a handful of render commands, but it makes them reusable.
It can be created with `device_create_render_bundle_encoder`.
It can be executed onto a `Command_Encoder` using `render_pass_execute_bundles`.

Executing a `Render_Bundle` is often more efficient than issuing the underlying commands
manually.

Corresponds to [WebGPU `GPURenderBundleEncoder`](
https://gpuweb.github.io/gpuweb/#gpurenderbundleencoder).
*/
Render_Bundle_Encoder :: wgpu.Render_Bundle_Encoder

/* Draws primitives from the active vertex buffer(s). */
render_bundle_encoder_draw :: proc "contextless" (
	self: Render_Bundle_Encoder,
	vertex_count: u32,
	instance_count: u32 = 1,
	first_vertex: u32 = 0,
	first_instance: u32 = 0,
) {
	wgpu.render_bundle_encoder_draw(
		self,
		vertex_count,
		instance_count,
		first_vertex,
		first_instance,
	)
}

/* Draws indexed primitives using the active index buffer and the active vertex buffer(s). */
render_bundle_encoder_draw_indexed :: proc "contextless" (
	self: Render_Bundle_Encoder,
	index_count: u32,
	instance_count: u32 = 1,
	firstIndex: u32 = 0,
	base_vertex: i32 = 0,
	first_instance: u32 = 0,
) {
	wgpu.render_bundle_encoder_draw_indexed(
		self,
		index_count,
		instance_count,
		firstIndex,
		base_vertex,
		first_instance,
	)
}

/*
Draws indexed primitives using the active index buffer and the active vertex buffers, based on
the contents of the `indirect_buffer`.
*/
render_bundle_encoder_draw_indexed_indirect :: proc "contextless" (
	self: Render_Bundle_Encoder,
	indirect_buffer: Buffer,
	indirect_offset: u64 = 0,
) {
	wgpu.render_bundle_encoder_draw_indexed_indirect(self, indirect_buffer, indirect_offset)
}

/*
Draws primitives from the active vertex buffer(s) based on the contents of the `indirect_buffer`.
*/
render_bundle_encoder_draw_indirect :: proc "contextless" (
	self: Render_Bundle_Encoder,
	indirect_buffer: Buffer,
	indirect_offset: u64 = 0,
) {
	wgpu.render_bundle_encoder_draw_indirect(self, indirect_buffer, indirect_offset)
}

/*
Finishes recording and returns a `Render_Bundle` that can be executed in other render passes.
 */
@(require_results)
render_bundle_encoder_finish :: proc "contextless" (
	self: Render_Bundle_Encoder,
	descriptor: Maybe(Render_Bundle_Descriptor) = nil,
	loc := #caller_location,
) -> (
	render_bundle: Render_Bundle,
	ok: bool,
) #optional_ok {
	_error_reset_data(loc)

	descriptor := descriptor
	render_bundle = wgpu.render_bundle_encoder_finish(
		self,
		&descriptor.? or_else nil,
	)

	if get_last_error() != nil {
		if render_bundle != nil {
			wgpu.render_bundle_release(render_bundle)
		}
		return
	}

	if render_bundle == nil {
		error_update_data(Error_Type.Unknown, "Failed to acquire 'Render_Bundle'")
		return
	}

	return render_bundle, true
}

/* Inserts debug marker. */
render_bundle_encoder_insert_debug_marker :: wgpu.render_bundle_encoder_insert_debug_marker

/* Stops command recording and creates debug group. */
render_bundle_encoder_pop_debug_group :: wgpu.render_bundle_encoder_pop_debug_group

/* Start record commands and group it into debug marker group. */
render_bundle_encoder_push_debug_group :: wgpu.render_bundle_encoder_push_debug_group

/*
Sets the active bind group for a given bind group index. The bind group layout in the active
pipeline when any `draw` procedure is called must match the layout of this bind group.

If the bind group have dynamic offsets, provide them in the binding order.
*/
render_bundle_encoder_set_bind_group :: proc "contextless" (
	self: Render_Bundle_Encoder,
	group_index: u32,
	group: Bind_Group,
	dynamic_offsets: []u32 = nil,
) {
	wgpu.render_bundle_encoder_set_bind_group(
		self,
		group_index,
		group,
		len(dynamic_offsets),
		raw_data(dynamic_offsets),
	)
}

/*
Sets the active index buffer.

Subsequent calls to draw_indexed on this `Render_Bundle_Encoder` will use buffer as the source
index buffer.
*/
render_bundle_encoder_set_index_buffer :: proc "contextless" (
	self: Render_Bundle_Encoder,
	buffer: Buffer,
	format: Index_Format,
	offset: u64 = 0,
	size: u64 = WHOLE_SIZE,
) {
	wgpu.render_bundle_encoder_set_index_buffer(self, buffer, format, offset, size)
}

/* Set debug label. */
render_bundle_encoder_set_label :: wgpu.render_bundle_encoder_set_label

/*
Sets the active render pipeline.

Subsequent draw calls will exhibit the behavior defined by pipeline.
*/
render_bundle_encoder_set_pipeline :: wgpu.render_bundle_encoder_set_pipeline

/*
Assign a vertex buffer to a slot.

Subsequent calls to `draw` and `draw_indexed` on this `Render_Bundle_Encoder` will use buffer as
one of the source vertex buffers.

The slot refers to the index of the matching descriptor in `VertexState.buffers`.
*/
render_bundle_encoder_set_vertex_buffer :: proc "contextless" (
	self: Render_Bundle_Encoder,
	slot: u32,
	buffer: Buffer,
	offset: u64 = 0,
	size: u64 = WHOLE_SIZE,
) {
	wgpu.render_bundle_encoder_set_vertex_buffer(self, slot, buffer, offset, size)
}

/* Increase the reference count. */
render_bundle_encoder_reference :: wgpu.render_bundle_encoder_reference

/* Release the `Render_Bundle_Encoder` resources. */
render_bundle_encoder_release :: wgpu.render_bundle_encoder_release
