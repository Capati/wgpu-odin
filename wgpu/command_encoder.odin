package wgpu

// Packages
import sa "core:container/small_array"

/*
Encodes a series of GPU operations.

A command encoder can record `Render_Pass`es, `Compute_Pass`es,
and transfer operations between driver-managed resources like `Buffer`s and `Texture`s.

When finished recording, call `command_encoder_finish` to obtain a `Command_Buffer` which may
be submitted for execution.

Corresponds to [WebGPU `GPUCommandEncoder`](https://gpuweb.github.io/gpuweb/#command-encoder).
*/
Command_Encoder :: distinct rawptr

/* Finishes recording and returns a `Command_Buffer` that can be submitted for execution. */
@(require_results)
command_encoder_finish :: proc "contextless" (
	self: Command_Encoder,
	descriptor: Maybe(Command_Buffer_Descriptor) = nil,
	loc := #caller_location,
) -> (
	command_buffer: Command_Buffer,
	ok: bool,
) #optional_ok {
	error_reset_data(loc)

	if desc, desc_ok := descriptor.?; desc_ok {
		raw_desc: WGPU_Command_Buffer_Descriptor
		c_label: String_View_Buffer
		if desc.label != "" {
			raw_desc.label = init_string_buffer(&c_label, desc.label)
		}
		command_buffer = wgpuCommandEncoderFinish(self, &raw_desc)
	} else {
		command_buffer = wgpuCommandEncoderFinish(self, nil)
	}

	if get_last_error() != nil {
		if command_buffer != nil {
			wgpuCommandBufferRelease(command_buffer)
		}
		return
	}

	return command_buffer, true
}

/*
Maximum number of color attachments that can be bound to a render pass.

This constant defines the maximum number of color attachments that can be used simultaneously
in a render pass. The value is configurable through the `WGPU_MAX_COLOR_ATTACHMENTS` configuration
option, defaulting to `8` if not specified otherwise.

This limit is hardware dependent and follows WebGPU specifications for maximum color attachments
in a render pass.
*/
MAX_COLOR_ATTACHMENTS :: #config(WGPU_MAX_COLOR_ATTACHMENTS, 8)

@(private)
Render_Pass_Color_Attachment_Raw :: sa.Small_Array(
	MAX_COLOR_ATTACHMENTS,
	WGPU_Render_Pass_Color_Attachment,
)

/*
Begins recording of a render pass.

This procedure returns a `Render_Pass` object which records a single render pass.

As long as the returned  `Render_Pass` has not ended,
any mutating operation on this command encoder causes an error and invalidates it.
*/
@(require_results)
command_encoder_begin_render_pass :: proc "contextless" (
	self: Command_Encoder,
	descriptor: Render_Pass_Descriptor,
) -> (
	render_pass: Render_Pass,
) {
	raw_desc: WGPU_Render_Pass_Descriptor

	when ODIN_DEBUG {
		c_label: String_View_Buffer
		if descriptor.label != "" {
			raw_desc.label = init_string_buffer(&c_label, descriptor.label)
		}
	}

	color_attachments: Render_Pass_Color_Attachment_Raw
	if len(descriptor.color_attachments) > 0 {
		for &attachment in descriptor.color_attachments {
			attachment_raw := WGPU_Render_Pass_Color_Attachment {
				view = attachment.view,
				resolve_target = attachment.resolve_target,
				depth_slice = DEPTH_SLICE_UNDEFINED,
				load_op = attachment.ops.load,
				store_op = attachment.ops.store,
				clear_value = WGPU_Color {
					r = attachment.ops.clear_value.r,
					g = attachment.ops.clear_value.g,
					b = attachment.ops.clear_value.b,
					a = attachment.ops.clear_value.a,
				},
			}
			sa.push_back(&color_attachments, attachment_raw)
		}
		raw_desc.color_attachment_count = uint(sa.len(color_attachments))
		raw_desc.color_attachments = raw_data(sa.slice(&color_attachments))
	}

	raw_desc.depth_stencil_attachment = descriptor.depth_stencil_attachment

	timestamp_writes := descriptor.timestamp_writes
	if timestamp_writes.query_set != nil {
		raw_desc.timestamp_writes = &timestamp_writes
	}

	raw_desc.occlusion_query_set = descriptor.occlusion_query_set

	max_draw_count: Render_Pass_Max_Draw_Count
	if descriptor.max_draw_count > 0 {
		max_draw_count = {
			chain = {stype = .Render_Pass_Max_Draw_Count},
			max_draw_count = descriptor.max_draw_count,
		}
		raw_desc.next_in_chain = &max_draw_count.chain
	}

	render_pass = wgpuCommandEncoderBeginRenderPass(self, raw_desc)

	return
}

/*
Begins recording of a compute pass.

This procedure returns a `Compute_Pass` object which records a single compute pass.

As long as the returned  `Compute_Pass` has not ended,
any mutating operation on this command encoder causes an error and invalidates it.
*/
@(require_results)
command_encoder_begin_compute_pass :: proc "contextless" (
	self: Command_Encoder,
	descriptor: Maybe(Compute_Pass_Descriptor) = nil,
	loc := #caller_location,
) -> (
	compute_pass: Compute_Pass,
	ok: bool,
) #optional_ok {
	if desc, desc_ok := descriptor.?; desc_ok {
		raw_desc: WGPU_Compute_Pass_Descriptor
		when ODIN_DEBUG {
			c_label: String_View_Buffer
			if desc.label != "" {
				raw_desc.label = init_string_buffer(&c_label, desc.label)
			}
		}
		raw_desc.timestamp_writes = &desc.timestamp_writes.? or_else nil
		compute_pass = wgpuCommandEncoderBeginComputePass(self, &raw_desc)
	} else {
		compute_pass = wgpuCommandEncoderBeginComputePass(self, nil)
	}

	if compute_pass == nil {
		error_reset_and_update(Error_Type.Unknown, "Failed to acquire 'Compute_Pass'", loc)
		return
	}

	return compute_pass, true
}

/*
Copy data from one buffer to another.

**Panics**

- Buffer offsets or copy size not a multiple of `COPY_BUFFER_ALIGNMENT`.
- Copy would overrun buffer.
- Copy within the same buffer.
*/
command_encoder_copy_buffer_to_buffer :: proc "contextless" (
	self: Command_Encoder,
	source: Buffer,
	source_offset: Buffer_Address,
	destination: Buffer,
	destination_offset: Buffer_Address,
	copy_size: Buffer_Address,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	error_reset_data(loc)
	wgpuCommandEncoderCopyBufferToBuffer(
		self,
		source,
		source_offset,
		destination,
		destination_offset,
		copy_size,
	)
	return has_no_error()
}

/*
View of a buffer which can be used to copy to/from a texture.

Corresponds to [WebGPU `GPUImageCopyBuffer`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuimagecopybuffer).
*/
Texel_Copy_Buffer_Info :: struct {
	layout: Texel_Copy_Buffer_Layout,
	buffer: Buffer,
}

/*
View of a texture which can be used to copy to/from a buffer/texture.

Corresponds to [WebGPU `GPUImageCopyTexture`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuimagecopytexture).
*/
Texel_Copy_Texture_Info :: struct {
	texture:   Texture,
	mip_level: u32,
	origin:    Origin_3D,
	aspect:    Texture_Aspect,
}

/* Copy data from a buffer to a texture. */
command_encoder_copy_buffer_to_texture :: proc "contextless" (
	self: Command_Encoder,
	source: Texel_Copy_Buffer_Info,
	destination: Texel_Copy_Texture_Info,
	copy_size: Extent_3D,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	error_reset_data(loc)
	wgpuCommandEncoderCopyBufferToTexture(self, source, destination, copy_size)
	return has_no_error()
}

/* Copy data from a texture to a buffer. */
command_encoder_copy_texture_to_buffer :: proc "contextless" (
	self: Command_Encoder,
	source: Texel_Copy_Texture_Info,
	destination: Texel_Copy_Buffer_Info,
	copy_size: Extent_3D,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	error_reset_data(loc)
	wgpuCommandEncoderCopyTextureToBuffer(self, source, destination, copy_size)
	return has_no_error()
}

/*
Copy data from one texture to another.

**Panics**

- Textures are not the same type
- If a depth texture, or a multisampled texture, the entire texture must be copied
- Copy would overrun either texture
*/
command_encoder_copy_texture_to_texture :: proc "contextless" (
	self: Command_Encoder,
	source: Texel_Copy_Texture_Info,
	destination: Texel_Copy_Texture_Info,
	copy_size: Extent_3D,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	error_reset_data(loc)
	wgpuCommandEncoderCopyTextureToTexture(self, source, destination, copy_size)
	return has_no_error()
}

/*
Clears buffer to zero.

**Panics**

- Buffer does not have `COPY_DST` usage.
- Range is out of bounds
*/
command_encoder_clear_buffer :: proc "contextless" (
	self: Command_Encoder,
	buffer: Buffer,
	offset: Buffer_Address,
	size: Buffer_Address = WHOLE_SIZE,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	error_reset_data(loc)
	wgpuCommandEncoderClearBuffer(self, buffer, offset, size)
	return has_no_error()
}

/* Inserts debug marker. */
command_encoder_insert_debug_marker :: proc "contextless" (
	self: Command_Encoder,
	label: string,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	when ODIN_DEBUG {
		error_reset_data(loc)
		c_label: String_View_Buffer
		wgpuCommandEncoderInsertDebugMarker(
			self,
			init_string_buffer(&c_label, label) if label != "" else {},
		)
		return has_no_error()
	} else {
		return true
	}
}

/* Start record commands and group it into debug marker group. */
command_encoder_push_debug_group :: proc "contextless" (
	self: Command_Encoder,
	label: string,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	when ODIN_DEBUG {
		error_reset_data(loc)
		c_label: String_View_Buffer
		wgpuCommandEncoderPushDebugGroup(
			self,
			init_string_buffer(&c_label, label) if label != "" else {},
		)
		return has_no_error()
	} else {
		return true
	}
}

/* Stops command recording and creates debug group. */
command_encoder_pop_debug_group :: proc "contextless" (
	self: Command_Encoder,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	when ODIN_DEBUG {
		error_reset_data(loc)
		wgpuCommandEncoderPopDebugGroup(self)
		return has_no_error()
	} else {
		return true
	}
}

/*
Resolve a query set, writing the results into the supplied destination buffer.

Queries may be between 8 and 40 bytes each. See `Pipeline_Statistics_Types` for more information.
*/
command_encoder_resolve_query_set :: proc "contextless" (
	self: Command_Encoder,
	query_set: Query_Set,
	query_range: Range(u32),
	destination: Buffer,
	destination_offset: Buffer_Address,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	error_reset_data(loc)
	wgpuCommandEncoderResolveQuerySet(
		self,
		query_set,
		query_range.start,
		query_range.end,
		destination,
		destination_offset,
	)
	return has_no_error()
}

/*
Issue a timestamp command at this point in the queue.
The timestamp will be written to the specified query set, at the specified index.

Attention: Since commands within a command recorder may be reordered,
there is no strict guarantee that timestamps are taken after all commands
recorded so far and all before all commands recorded after.
This may depend both on the backend and the driver.
*/
command_encoder_write_timestamp :: proc "contextless" (
	self: Command_Encoder,
	query_set: Query_Set,
	query_index: u32,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	error_reset_data(loc)
	wgpuCommandEncoderWriteTimestamp(self, query_set, query_index)
	return has_no_error()
}

/* Sets a debug label for the given `Command_Encoder`. */
@(disabled = !ODIN_DEBUG)
command_encoder_set_label :: proc "contextless" (self: Command_Encoder, label: string) {
	c_label: String_View_Buffer
	wgpuCommandEncoderSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the `Command_Encoder` reference count. */
command_encoder_add_ref :: wgpuCommandEncoderAddRef

/* Release the `Command_Encoder` resources, use to decrease the reference count. */
command_encoder_release :: wgpuCommandEncoderRelease

/*
Safely releases the `Command_Encoder` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
command_encoder_release_safe :: #force_inline proc(self: ^Command_Encoder) {
	if self != nil && self^ != nil {
		wgpuCommandEncoderRelease(self^)
		self^ = nil
	}
}
