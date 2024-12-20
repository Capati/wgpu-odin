package wgpu

/*
Encodes a series of GPU operations.

A command encoder can record `RenderPass`es, `ComputePass`es,
and transfer operations between driver-managed resources like `Buffer`s and `Texture`s.

When finished recording, call `command_encoder_finish` to obtain a `CommandBuffer` which may
be submitted for execution.

Corresponds to [WebGPU `GPUCommandEncoder`](https://gpuweb.github.io/gpuweb/#command-encoder).
*/
CommandEncoder :: distinct rawptr

/*
Describes the attachments of a compute pass.

For use with `command_encoder_begin_compute_pass`.

Corresponds to [WebGPU `GPUComputePassDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpucomputepassdescriptor).
*/
ComputePassDescriptor :: struct {
	label:            string,
	timestamp_writes: Maybe(ComputePassTimestampWrites),
}

/*
Begins recording of a compute pass.

This procedure returns a `ComputePass` object which records a single render pass.
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
Describes the attachments of a render pass.

For use with [`command_encoder_begin_render_pass`].

Note: separate lifetimes are needed because the texture views
have to live as long as the pass is recorded, while everything else doesn't.

Corresponds to [WebGPU `GPURenderPassDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpurenderpassdescriptor).
*/
RenderPassDescriptor :: struct {
	label:                    string,
	color_attachments:        []RenderPassColorAttachment,
	depth_stencil_attachment: ^RenderPassDepthStencilAttachment,
	timestamp_writes:         []RenderPassTimestampWrites,
	occlusion_query_set:      QuerySet,
	max_draw_count:           u64,
}

/*
Begins recording of a render pass.

This procedure returns a [`RenderPass`] object which records a single render pass.
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

	if len(descriptor.color_attachments) > 0 {
		raw_desc.color_attachment_count = uint(len(descriptor.color_attachments))
		raw_desc.color_attachments = raw_data(descriptor.color_attachments)
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

/* Clears buffer to zero. */
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

/* Copy data from one buffer to another. */
command_encoder_copy_buffer_to_buffer :: proc "contextless" (
	self: CommandEncoder,
	source: Buffer,
	source_offset: BufferAddress,
	destination: Buffer,
	destination_offset: BufferAddress,
	size: BufferAddress,
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
		size,
	)
	return has_no_error()
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

/* Copy data from one texture to another. */
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

CommandBufferDescriptor :: struct {
	label: string,
}

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

/* Inserts debug marker. */
command_encoder_insert_debug_marker :: proc "contextless" (
	self: CommandEncoder,
	marker_label: string,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	error_reset_data(loc)
	c_label: StringViewBuffer
	wgpuCommandEncoderInsertDebugMarker(
		self,
		init_string_buffer(&c_label, marker_label) if marker_label != "" else {},
	)
	return has_no_error()
}

/* Stops command recording and creates debug group. */
command_encoder_pop_debug_group :: proc "contextless" (
	self: CommandEncoder,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	error_reset_data(loc)
	wgpuCommandEncoderPopDebugGroup(self)
	return has_no_error()
}

/* Start record commands and group it into debug marker group. */
command_encoder_push_debug_group :: proc "contextless" (
	self: CommandEncoder,
	group_label: string,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	error_reset_data(loc)
	c_label: StringViewBuffer
	wgpuCommandEncoderPushDebugGroup(
		self,
		init_string_buffer(&c_label, group_label) if group_label != "" else {},
	)
	return has_no_error()
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

/* Set debug label. */
@(disabled = !ODIN_DEBUG)
command_encoder_set_label :: proc "contextless" (self: CommandEncoder, label: string) {
	c_label: StringViewBuffer
	wgpuCommandEncoderSetLabel(self, init_string_buffer(&c_label, label))
}

/*
Issue a timestamp command at this point in the queue. The timestamp will be written to the
specified query set, at the specified index.
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

/* Increase the reference count. */
command_encoder_add_ref :: wgpuCommandEncoderAddRef

/* Release the `CommandEncoder` resources. */
command_encoder_release :: wgpuCommandEncoderRelease
