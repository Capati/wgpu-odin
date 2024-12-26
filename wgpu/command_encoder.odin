package wgpu

// Packages
import sa "core:container/small_array"

/*
Encodes a series of GPU operations.

A command encoder can record `RenderPass`es, `ComputePass`es,
and transfer operations between driver-managed resources like `Buffer`s and `Texture`s.

When finished recording, call `command_encoder_finish` to obtain a `CommandBuffer` which may
be submitted for execution.

Corresponds to [WebGPU `GPUCommandEncoder`](https://gpuweb.github.io/gpuweb/#command-encoder).
*/
CommandEncoder :: distinct rawptr

/* Finishes recording and returns a `CommandBuffer` that can be submitted for execution. */
@(require_results)
command_encoder_finish :: proc "contextless" (
	self: CommandEncoder,
	descriptor: Maybe(CommandBufferDescriptor) = nil,
	loc := #caller_location,
) -> (
	command_buffer: CommandBuffer,
	ok: bool,
) #optional_ok {
	error_reset_data(loc)

	if desc, desc_ok := descriptor.?; desc_ok {
		raw_desc: WGPUCommandBufferDescriptor
		c_label: StringViewBuffer
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
RenderPassColorAttachmentRaw :: sa.Small_Array(
	MAX_COLOR_ATTACHMENTS,
	WGPURenderPassColorAttachment,
)

/*
Begins recording of a render pass.

This procedure returns a `RenderPass` object which records a single render pass.

As long as the returned  `RenderPass` has not ended,
any mutating operation on this command encoder causes an error and invalidates it.
*/
@(require_results)
command_encoder_begin_render_pass :: proc "contextless" (
	self: CommandEncoder,
	descriptor: RenderPassDescriptor,
) -> (
	render_pass: RenderPass,
) {
	raw_desc: WGPURenderPassDescriptor

	when ODIN_DEBUG {
		c_label: StringViewBuffer
		if descriptor.label != "" {
			raw_desc.label = init_string_buffer(&c_label, descriptor.label)
		}
	}

	color_attachments: RenderPassColorAttachmentRaw
	if len(descriptor.color_attachments) > 0 {
		for &attachment in descriptor.color_attachments {
			attachment_raw := WGPURenderPassColorAttachment {
				view = attachment.view,
				resolve_target = attachment.resolve_target,
				depth_slice = DEPTH_SLICE_UNDEFINED,
				load_op = attachment.ops.load,
				store_op = attachment.ops.store,
				clear_value = WGPUColor {
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

	if len(descriptor.timestamp_writes) > 0 {
		raw_desc.timestamp_writes = raw_data(descriptor.timestamp_writes)
	}

	raw_desc.occlusion_query_set = descriptor.occlusion_query_set

	max_draw_count: RenderPassMaxDrawCount
	if descriptor.max_draw_count > 0 {
		max_draw_count = {
			chain = {stype = .RenderPassMaxDrawCount},
			max_draw_count = descriptor.max_draw_count,
		}
		raw_desc.next_in_chain = &max_draw_count.chain
	}

	render_pass = wgpuCommandEncoderBeginRenderPass(self, raw_desc)

	return
}

/*
Begins recording of a compute pass.

This procedure returns a `ComputePass` object which records a single compute pass.

As long as the returned  `ComputePass` has not ended,
any mutating operation on this command encoder causes an error and invalidates it.
*/
@(require_results)
command_encoder_begin_compute_pass :: proc "contextless" (
	self: CommandEncoder,
	descriptor: Maybe(ComputePassDescriptor) = nil,
	loc := #caller_location,
) -> (
	compute_pass: ComputePass,
	ok: bool,
) #optional_ok {
	if desc, desc_ok := descriptor.?; desc_ok {
		raw_desc: WGPUComputePassDescriptor
		when ODIN_DEBUG {
			c_label: StringViewBuffer
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
		error_reset_and_update(ErrorType.Unknown, "Failed to acquire 'ComputePass'", loc)
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
	self: CommandEncoder,
	source: Buffer,
	source_offset: BufferAddress,
	destination: Buffer,
	destination_offset: BufferAddress,
	copy_size: BufferAddress,
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
TexelCopyBufferInfo :: struct {
	layout: TexelCopyBufferLayout,
	buffer: Buffer,
}

/*
View of a texture which can be used to copy to/from a buffer/texture.

Corresponds to [WebGPU `GPUImageCopyTexture`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuimagecopytexture).
*/
TexelCopyTextureInfo :: struct {
	texture:   Texture,
	mip_level: u32,
	origin:    Origin3D,
	aspect:    TextureAspect,
}

/* Copy data from a buffer to a texture. */
command_encoder_copy_buffer_to_texture :: proc "contextless" (
	self: CommandEncoder,
	source: TexelCopyBufferInfo,
	destination: TexelCopyTextureInfo,
	copy_size: Extent3D,
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
	self: CommandEncoder,
	source: TexelCopyTextureInfo,
	destination: TexelCopyBufferInfo,
	copy_size: Extent3D,
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
	self: CommandEncoder,
	source: TexelCopyTextureInfo,
	destination: TexelCopyTextureInfo,
	copy_size: Extent3D,
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
	self: CommandEncoder,
	buffer: Buffer,
	offset: BufferAddress,
	size: BufferAddress = WHOLE_SIZE,
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
	self: CommandEncoder,
	label: string,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	when ODIN_DEBUG {
		error_reset_data(loc)
		c_label: StringViewBuffer
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
	self: CommandEncoder,
	label: string,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	when ODIN_DEBUG {
		error_reset_data(loc)
		c_label: StringViewBuffer
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
	self: CommandEncoder,
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
	self: CommandEncoder,
	query_set: QuerySet,
	query_range: Range(u32),
	destination: Buffer,
	destination_offset: BufferAddress,
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
	self: CommandEncoder,
	query_set: QuerySet,
	query_index: u32,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	error_reset_data(loc)
	wgpuCommandEncoderWriteTimestamp(self, query_set, query_index)
	return has_no_error()
}

/* Sets a debug label for the given `CommandEncoder`. */
@(disabled = !ODIN_DEBUG)
command_encoder_set_label :: proc "contextless" (self: CommandEncoder, label: string) {
	c_label: StringViewBuffer
	wgpuCommandEncoderSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the `CommandEncoder` reference count. */
command_encoder_add_ref :: wgpuCommandEncoderAddRef

/* Release the `CommandEncoder` resources, use to decrease the reference count. */
command_encoder_release :: wgpuCommandEncoderRelease
