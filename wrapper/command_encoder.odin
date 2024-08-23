package wgpu

// The raw bindings
import wgpu "../bindings"

/*
Encodes a series of GPU operations.

A command encoder can record `Render_Pass`es, `Compute_Pass`es,
and transfer operations between driver-managed resources like `Buffer`s and `Texture`s.

When finished recording, call `command_encoder_finish` to obtain a `Command_Buffer` which may
be submitted for execution.

Corresponds to [WebGPU `GPUCommandEncoder`](https://gpuweb.github.io/gpuweb/#command-encoder).
*/
Command_Encoder :: wgpu.Command_Encoder

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
	_error_reset_data(loc)

	descriptor := descriptor
	command_buffer = wgpu.command_encoder_finish(self, &descriptor.? or_else nil)

	if get_last_error() != nil {
		if command_buffer != nil {
			wgpu.command_buffer_release(command_buffer)
		}
		return
	}

	return command_buffer, true
}

/*
Describes the attachments of a render pass.

For use with [`command_encoder_begin_render_pass`].

Note: separate lifetimes are needed because the texture views
have to live as long as the pass is recorded, while everything else doesn't.

Corresponds to [WebGPU `GPURenderPassDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpurenderpassdescriptor).
*/
Render_Pass_Descriptor :: struct {
	label                    : cstring,
	color_attachments        : []Render_Pass_Color_Attachment,
	depth_stencil_attachment : ^Render_Pass_Depth_Stencil_Attachment,
	timestamp_writes         : []Render_Pass_Timestamp_Writes,
	occlusion_query_set      : Query_Set,
	max_draw_count           : u64,
}

/*
Begins recording of a render pass.

This procedure returns a [`Render_Pass`] object which records a single render pass.
*/
@(require_results)
command_encoder_begin_render_pass :: proc "contextless" (
	self: Command_Encoder,
	descriptor: Render_Pass_Descriptor,
) -> (
	render_pass: Render_Pass,
) {
	desc: wgpu.Render_Pass_Descriptor
	desc.label = descriptor.label

	if len(descriptor.color_attachments) > 0 {
		desc.color_attachment_count = uint(len(descriptor.color_attachments))
		desc.color_attachments = raw_data(descriptor.color_attachments)
	}

	if descriptor.depth_stencil_attachment != nil {
		desc.depth_stencil_attachment = descriptor.depth_stencil_attachment
	}

	if len(descriptor.timestamp_writes) > 0 {
		desc.timestamp_writes = raw_data(descriptor.timestamp_writes)
	}

	if descriptor.occlusion_query_set != nil {
		desc.occlusion_query_set = descriptor.occlusion_query_set
	}

	max_draw_count: wgpu.Render_Pass_Descriptor_Max_Draw_Count

	if descriptor.max_draw_count > 0 {
		max_draw_count.chain.stype = wgpu.SType.Render_Pass_Descriptor_Max_Draw_Count
		max_draw_count.max_draw_count = descriptor.max_draw_count
		desc.next_in_chain = &max_draw_count.chain
	}

	render_pass = wgpu.command_encoder_begin_render_pass(self, &desc)

	return
}

/*
Begins recording of a compute pass.

This procedure returns a `Compute_Pass` object which records a single render pass.
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
	descriptor := descriptor
	compute_pass = wgpu.command_encoder_begin_compute_pass(self, &descriptor.? or_else nil)

	if compute_pass == nil {
		error_reset_and_update(wgpu.Error_Type.Unknown, "Failed to acquire 'Compute_Pass'", loc)
		return
	}

	return compute_pass, true
}

/* Copy data from one buffer to another. */
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
	when ENABLE_ERROR_HANDLING {
		if source_offset % COPY_BUFFER_ALIGNMENT != 0 {
			error_reset_and_update(
				.Validation,
				"'source_offset' must be a multiple of 4 COPY_BUFFER_ALIGNMENT",
				loc,
			)
			return
		}

		if destination_offset % COPY_BUFFER_ALIGNMENT != 0 {
			error_reset_and_update(
				.Validation,
				"'destination_offset' must be a multiple of 4 COPY_BUFFER_ALIGNMENT",
				loc,
			)
			return
		}

		if copy_size % COPY_BUFFER_ALIGNMENT != 0 {
			error_reset_and_update(
				.Validation,
				"'size' must be a multiple of 4 COPY_BUFFER_ALIGNMENT",
				loc,
			)
			return
		}
	}

	_error_reset_data(loc)

	wgpu.command_encoder_copy_buffer_to_buffer(
		self,
		source,
		source_offset,
		destination,
		destination_offset,
		copy_size,
	)

	return get_last_error() == nil
}

/* Copy data from a buffer to a texture. */
command_encoder_copy_buffer_to_texture :: proc "contextless" (
	self: Command_Encoder,
	source: Image_Copy_Buffer,
	destination: Image_Copy_Texture,
	copy_size: Extent_3D,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	when ENABLE_ERROR_HANDLING {
		if source.layout.bytes_per_row % COPY_BYTES_PER_ROW_ALIGNMENT != 0 {
			error_reset_and_update(
				.Validation,
				"bytes_per_row must be a multiple of 256",
				loc,
			)
			return
		}
	}

	_error_reset_data(loc)

	source, destination, copy_size := source, destination, copy_size
	wgpu.command_encoder_copy_buffer_to_texture(self, &source, &destination, &copy_size)

	return get_last_error() == nil
}

/* Copy data from a texture to a buffer. */
command_encoder_copy_texture_to_buffer :: proc "contextless" (
	self: Command_Encoder,
	source: Image_Copy_Texture,
	destination: Image_Copy_Buffer,
	copy_size: Extent_3D,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	when ENABLE_ERROR_HANDLING {
		if destination.layout.bytes_per_row % COPY_BYTES_PER_ROW_ALIGNMENT != 0 {
			error_reset_and_update(
				.Validation,
				"'bytes_per_row' must be a multiple of 256",
				loc,
			)
			return
		}
	}

	_error_reset_data(loc)

	source, destination, copy_size := source, destination, copy_size
	wgpu.command_encoder_copy_texture_to_buffer(self, &source, &destination, &copy_size)

	return get_last_error() == nil
}

/* Copy data from one texture to another. */
command_encoder_copy_texture_to_texture :: proc "contextless" (
	self: Command_Encoder,
	source: Image_Copy_Texture,
	destination: Image_Copy_Texture,
	copy_size: Extent_3D,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	_error_reset_data(loc)

	source, destination, copy_size := source, destination, copy_size
	wgpu.command_encoder_copy_texture_to_texture(self, &source, &destination, &copy_size)

	return get_last_error() == nil
}

/* Clears buffer to zero. */
command_encoder_clear_buffer :: proc "contextless" (
	self: Command_Encoder,
	buffer: Buffer,
	offset: Buffer_Address,
	size: Buffer_Address = WHOLE_SIZE,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	when ENABLE_ERROR_HANDLING {
		if offset % COPY_BUFFER_ALIGNMENT != 0 {
			error_reset_and_update(
				.Validation,
				"'offset' must be a multiple of COPY_BUFFER_ALIGNMENT",
				loc,
			)
			return
		}

		if size <= 0 {
			error_reset_and_update(.Validation, "'size' size must be > 0", loc)
			return
		}

		if size % COPY_BUFFER_ALIGNMENT != 0 {
			error_reset_and_update(
				.Validation,
				"'size' must be a multiple of COPY_BUFFER_ALIGNMENT",
				loc,
			)
			return
		}

		if offset + size > size {
			error_reset_and_update(.Validation, "buffer size out of range", loc)
			return
		}
	}

	_error_reset_data(loc)
	wgpu.command_encoder_clear_buffer(self, buffer, offset, size)
	return get_last_error() == nil
}

/* Inserts debug marker. */
command_encoder_insert_debug_marker :: proc "contextless" (
	self: Command_Encoder,
	marker_label: cstring,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	_error_reset_data(loc)
	wgpu.command_encoder_insert_debug_marker(self, marker_label)
	return get_last_error() == nil
}

/* Start record commands and group it into debug marker group. */
command_encoder_push_debug_group :: proc "contextless" (
	self: Command_Encoder,
	group_label: cstring,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	_error_reset_data(loc)
	wgpu.command_encoder_push_debug_group(self, group_label)
	return get_last_error() == nil
}

/* Stops command recording and creates debug group. */
command_encoder_pop_debug_group :: proc "contextless" (
	self: Command_Encoder,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	_error_reset_data(loc)
	wgpu.command_encoder_pop_debug_group(self)
	return get_last_error() == nil
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
	_error_reset_data(loc)

	wgpu.command_encoder_resolve_query_set(
		self,
		query_set,
		query_range.start,
		query_range.end,
		destination,
		destination_offset,
	)

	return get_last_error() == nil
}

/* Set debug label. */
command_encoder_set_label :: wgpu.command_encoder_set_label

/*
Issue a timestamp command at this point in the queue. The timestamp will be written to the
specified query set, at the specified index.
*/
command_encoder_write_timestamp :: proc "contextless" (
	self: Command_Encoder,
	query_set: Query_Set,
	query_index: u32,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	_error_reset_data(loc)
	wgpu.command_encoder_write_timestamp(self, query_set, query_index)
	return get_last_error() == nil
}

/* Increase the reference count. */
command_encoder_reference :: wgpu.command_encoder_reference

/* Release the `Command_Encoder` resources. */
command_encoder_release :: wgpu.command_encoder_release
