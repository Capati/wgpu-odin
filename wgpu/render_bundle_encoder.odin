package wgpu

/*
Encodes a series of GPU operations into a reusable "render bundle".

It only supports a handful of render commands, but it makes them reusable.
It can be created with `device_create_render_bundle_encoder`.
It can be executed onto a `Command_Encoder` using `render_pass_execute_bundles`.

Executing a `Render_Bundle` is often more efficient than issuing the underlying commands manually.

Corresponds to [WebGPU `GPURenderBundleEncoder`](
https://gpuweb.github.io/gpuweb/#gpurenderbundleencoder).
*/
Render_Bundle_Encoder :: distinct rawptr

/*
Describes a `Render_Bundle`.

For use with `render_bundle_encoder_finish`.

Corresponds to [WebGPU `GPURenderBundleDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpurenderbundledescriptor).
*/
Render_Bundle_Encoder_Descriptor :: struct {
	label:                string,
	color_formats:        []Texture_Format,
	depth_stencil_format: Texture_Format,
	sample_count:         u32,
	depth_read_only:      bool,
	stencil_read_only:    bool,
}

/* Draws primitives from the active vertex buffer(s). */
render_bundle_encoder_draw :: proc "contextless" (
	self: Render_Bundle_Encoder,
	vertices: Range(u32),
	instances: Range(u32) = {start = 0, end = 1},
) {
	wgpuRenderBundleEncoderDraw(
		self,
		vertices.end - vertices.start,
		instances.end - instances.start,
		vertices.start,
		instances.start,
	)
}

/* Draws indexed primitives using the active index buffer and the active vertex buffer(s). */
render_bundle_encoder_draw_indexed :: proc "contextless" (
	self: Render_Bundle_Encoder,
	indices: Range(u32),
	base_vertex: i32 = 0,
	instances: Range(u32) = {start = 0, end = 1},
) {
	wgpuRenderBundleEncoderDrawIndexed(
		self,
		indices.end - indices.start,
		instances.end - instances.start,
		indices.start,
		base_vertex,
		instances.start,
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
	wgpuRenderBundleEncoderDrawIndexedIndirect(self, indirect_buffer, indirect_offset)
}

/*
Draws primitives from the active vertex buffer(s) based on the contents of the `indirect_buffer`.
*/
render_bundle_encoder_draw_indirect :: proc "contextless" (
	self: Render_Bundle_Encoder,
	indirect_buffer: Buffer,
	indirect_offset: u64 = 0,
) {
	wgpuRenderBundleEncoderDrawIndirect(self, indirect_buffer, indirect_offset)
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
	error_reset_data(loc)

	if desc, desc_ok := descriptor.?; desc_ok {
		raw_desc: WGPU_Render_Bundle_Descriptor
		when ODIN_DEBUG {
			c_label: String_View_Buffer
			if desc.label != "" {
				raw_desc.label = init_string_buffer(&c_label, desc.label)
			}
		}
		render_bundle = wgpuRenderBundleEncoderFinish(self, &raw_desc)
	} else {
		render_bundle = wgpuRenderBundleEncoderFinish(self, nil)
	}

	if get_last_error() != nil {
		if render_bundle != nil {
			wgpuRenderBundleRelease(render_bundle)
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
render_bundle_encoder_insert_debug_marker :: proc(
	self: Render_Bundle_Encoder,
	label: string,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	when ODIN_DEBUG {
		error_reset_data(loc)
		c_label: String_View_Buffer
		wgpuRenderBundleEncoderPushDebugGroup(
			self,
			init_string_buffer(&c_label, label) if label != "" else {},
		)
		return has_no_error()
	} else {
		return true
	}
}

/* Start record commands and group it into debug marker group. */
render_bundle_encoder_push_debug_group :: proc(
	self: Render_Bundle_Encoder,
	label: string,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	when ODIN_DEBUG {
		error_reset_data(loc)
		c_label: String_View_Buffer
		wgpuRenderBundleEncoderPushDebugGroup(
			self,
			init_string_buffer(&c_label, label) if label != "" else {},
		)
		return has_no_error()
	} else {
		return true
	}
}

/* Stops command recording and creates debug group. */
render_bundle_encoder_pop_debug_group :: proc "contextless" (
	self: Render_Bundle_Encoder,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	when ODIN_DEBUG {
		error_reset_data(loc)
		wgpuRenderBundleEncoderPopDebugGroup(self)
		return has_no_error()
	} else {
		return true
	}
}

/*
Sets the active bind group for a given bind group index. The bind group layout in the active
pipeline when any `draw` procedure is called must match the layout of this bind group.

If the bind group have dynamic offsets, provide them in the binding order.
*/
render_bundle_encoder_set_bind_group :: proc "contextless" (
	self: Render_Bundle_Encoder,
	group_index: u32,
	group: Bind_Group,
	offsets: []Dynamic_Offset = nil,
) {
	wgpuRenderBundleEncoderSetBindGroup(self, group_index, group, len(offsets), raw_data(offsets))
}

/*
Sets the active index buffer.

Subsequent calls to draw_indexed on this `Render_Bundle_Encoder` will use buffer as the source
index buffer.
*/
render_bundle_encoder_set_index_buffer :: proc "contextless" (
	self: Render_Bundle_Encoder,
	buffer_slice: Buffer_Slice,
	format: Index_Format,
) {
	wgpuRenderBundleEncoderSetIndexBuffer(
		self,
		buffer_slice.buffer,
		format,
		buffer_slice.offset,
		buffer_slice.size if buffer_slice.size > 0 else WHOLE_SIZE,
	)
}

/* Sets a debug label for the given `Render_Bundle_Encoder`. */
@(disabled = !ODIN_DEBUG)
render_bundle_encoder_set_label :: proc(self: Render_Bundle_Encoder, label: string) {
	c_label: String_View_Buffer
	wgpuRenderBundleEncoderSetLabel(self, init_string_buffer(&c_label, label))
}

/*
Sets the active render pipeline.

Subsequent draw calls will exhibit the behavior defined by pipeline.
*/
render_bundle_encoder_set_pipeline :: wgpuRenderBundleEncoderSetPipeline

/*
Assign a vertex buffer to a slot.

Subsequent calls to `draw` and `draw_indexed` on this `Render_Bundle_Encoder` will use buffer as
one of the source vertex buffers.

The slot refers to the index of the matching descriptor in `Vertex_State.buffers`.
*/
render_bundle_encoder_set_vertex_buffer :: proc "contextless" (
	self: Render_Bundle_Encoder,
	slot: u32,
	buffer_slice: Buffer_Slice,
) {
	wgpuRenderBundleEncoderSetVertexBuffer(
		self,
		slot,
		buffer_slice.buffer,
		buffer_slice.offset,
		buffer_slice.size if buffer_slice.size > 0 else WHOLE_SIZE,
	)
}

/* Increase the `Render_Bundle_Encoder` reference count. */
render_bundle_encoder_add_ref :: wgpuRenderBundleEncoderAddRef

/* Release the `Render_Bundle_Encoder` resources, use to decrease the reference count. */
render_bundle_encoder_release :: wgpuRenderBundleEncoderRelease

/*
Safely releases the `Render_Bundle_Encoder` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
render_bundle_encoder_release_safe :: #force_inline proc(self: ^Render_Bundle_Encoder) {
	if self != nil && self^ != nil {
		wgpuRenderBundleEncoderRelease(self^)
		self^ = nil
	}
}
