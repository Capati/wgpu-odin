package wgpu

// Package
import wgpu "../bindings"

// Encodes a series of GPU operations.
//
// A command encoder can record `Render_Passes`, `Compute_Passes`, and transfer operations between
// driver-managed resources like `Buffer`s and `Texture`s.
//
// When finished recording, call `command_encoder_finish` to obtain a `Command_Buffer` which may be
// submitted for execution.
Command_Encoder :: struct {
	ptr:       Raw_Command_Encoder,
	_err_data: ^Error_Data,
}

// Begins recording of a compute pass.
//
// This function returns a `Compute_Pass_Encoder` object which records a single render pass.
command_encoder_begin_compute_pass :: proc(
	using self: ^Command_Encoder,
	descriptor: ^Compute_Pass_Descriptor,
	loc := #caller_location,
) -> (
	compute_pass: Compute_Pass_Encoder,
	err: Error,
) {
	compute_pass.ptr = wgpu.command_encoder_begin_compute_pass(ptr, descriptor)

	if compute_pass.ptr == nil {
		err = wgpu.Error_Type.Unknown
		set_and_update_err_data(
			_err_data,
			.General,
			err,
			"Failed to acquire Compute_Pass_Encoder",
			loc,
		)
		return
	}

	compute_pass._err_data = _err_data

	return
}

// Describes the attachments of a render pass.
//
// For use with `command_encoder_begin_render_pass`.
//
// Note: separate lifetimes are needed because the texture views ('tex) have to live as long as the
// pass is recorded, while everything else ('desc) doesn’t.
Render_Pass_Descriptor :: struct {
	label:                    cstring,
	color_attachments:        []Render_Pass_Color_Attachment,
	depth_stencil_attachment: ^Render_Pass_Depth_Stencil_Attachment,
	occlusion_query_set:      Raw_Query_Set,
	timestamp_writes:         []Render_Pass_Timestamp_Writes,
	max_draw_count:           u64,
}

// Begins recording of a render pass.
command_encoder_begin_render_pass :: proc(
	using self: ^Command_Encoder,
	descriptor: ^Render_Pass_Descriptor,
) -> (
	render_pass: Render_Pass_Encoder,
) {
	desc: wgpu.Render_Pass_Descriptor
	desc.label = descriptor.label

	if len(descriptor.color_attachments) > 0 {
		desc.color_attachment_count = cast(uint)len(descriptor.color_attachments)
		desc.color_attachments = raw_data(descriptor.color_attachments)
	}

	if descriptor.depth_stencil_attachment != nil {
		desc.depth_stencil_attachment = descriptor.depth_stencil_attachment
	}

	if descriptor.occlusion_query_set != nil {
		desc.occlusion_query_set = descriptor.occlusion_query_set
	}

	if len(descriptor.timestamp_writes) > 0 {
		desc.timestamp_writes = raw_data(descriptor.timestamp_writes)
	}

	max_draw_count: wgpu.Render_Pass_Descriptor_Max_Draw_Count

	if descriptor.max_draw_count > 0 {
		max_draw_count.chain.stype = wgpu.SType.Render_Pass_Descriptor_Max_Draw_Count
		max_draw_count.max_draw_count = descriptor.max_draw_count
		desc.next_in_chain = &max_draw_count.chain
	}

	render_pass.ptr = wgpu.command_encoder_begin_render_pass(ptr, &desc)
	render_pass._err_data = _err_data

	return
}

// Clears buffer to zero.
command_encoder_clear_buffer :: proc(
	using self: ^Command_Encoder,
	buffer: Raw_Buffer,
	offset: u64 = 0,
	size: u64 = 0,
	loc := #caller_location,
) -> (
	err: Error,
) {
	when WGPU_ENABLE_ERROR_HANDLING {
		err = wgpu.Error_Type.Validation

		if offset % 4 != 0 {
			set_and_update_err_data(
				_err_data,
				.Assert,
				err,
				"'offset' must be a multiple of 4",
				loc,
			)
			return
		}

		if size <= 0 {
			set_and_update_err_data(_err_data, .Assert, err, "'size' size must be > 0", loc)
			return
		}

		if size % 4 != 0 {
			set_and_update_err_data(_err_data, .Assert, err, "'size' must be a multiple of 4", loc)
			return
		}

		if offset + size > size {
			set_and_update_err_data(_err_data, .Assert, err, "buffer size out of range", loc)
			return
		}
	}

	set_and_reset_err_data(_err_data, loc)
	wgpu.command_encoder_clear_buffer(ptr, buffer, offset, size)
	err = get_last_error()

	return
}

// Copy data from one buffer to another.
command_encoder_copy_buffer_to_buffer :: proc(
	using self: ^Command_Encoder,
	source: Raw_Buffer,
	source_offset: u64,
	destination: Raw_Buffer,
	destination_offset: u64,
	size: u64,
	loc := #caller_location,
) -> (
	err: Error,
) {
	when WGPU_ENABLE_ERROR_HANDLING {
		err = .Validation

		if source_offset % 4 != 0 {
			set_and_update_err_data(
				_err_data,
				.Assert,
				err,
				"'source_offset' must be a multiple of 4",
				loc,
			)
			return
		}

		if destination_offset % 4 != 0 {
			set_and_update_err_data(
				_err_data,
				.Assert,
				err,
				"'destination_offset' must be a multiple of 4",
				loc,
			)
			return
		}

		if size % 4 != 0 {
			set_and_update_err_data(_err_data, .Assert, err, "'size' must be a multiple of 4", loc)
			return
		}
	}

	set_and_reset_err_data(_err_data, loc)

	wgpu.command_encoder_copy_buffer_to_buffer(
		ptr,
		source,
		source_offset,
		destination,
		destination_offset,
		size,
	)

	err = get_last_error()

	return
}

// Copy data from a buffer to a texture.
command_encoder_copy_buffer_to_texture :: proc(
	using self: ^Command_Encoder,
	source: ^Image_Copy_Buffer,
	destination: ^Image_Copy_Texture,
	copy_size: ^Extent_3D,
	loc := #caller_location,
) -> (
	err: Error,
) {
	when WGPU_ENABLE_ERROR_HANDLING {
		if source != nil && source.layout.bytes_per_row % Copy_Bytes_Per_Row_Alignment != 0 {
			err = .Validation
			set_and_update_err_data(
				_err_data,
				.Assert,
				err,
				"bytes_per_row must be a multiple of 256",
				loc,
			)
			return
		}
	}

	set_and_reset_err_data(_err_data, loc)

	wgpu.command_encoder_copy_buffer_to_texture(ptr, source, destination, copy_size)

	err = get_last_error()

	return
}

// Copy data from a texture to a buffer.
command_encoder_copy_texture_to_buffer :: proc(
	using self: ^Command_Encoder,
	source: ^Image_Copy_Texture,
	destination: ^Image_Copy_Buffer,
	copy_size: ^Extent_3D,
	loc := #caller_location,
) -> (
	err: Error,
) {
	if destination != nil {
		if destination.layout.bytes_per_row % Copy_Bytes_Per_Row_Alignment != 0 {
			err = .Validation
			set_and_update_err_data(
				_err_data,
				.Assert,
				err,
				"bytes_per_row must be a multiple of 256",
				loc,
			)
			return
		}
	}

	set_and_reset_err_data(_err_data, loc)

	wgpu.command_encoder_copy_texture_to_buffer(ptr, source, destination, copy_size)

	err = get_last_error()

	return
}

// Copy data from one texture to another.
command_encoder_copy_texture_to_texture :: proc(
	using self: ^Command_Encoder,
	source: ^Image_Copy_Texture,
	destination: ^Image_Copy_Texture,
	copy_size: ^Extent_3D,
	loc := #caller_location,
) -> (
	err: Error,
) {
	set_and_reset_err_data(_err_data, loc)

	wgpu.command_encoder_copy_texture_to_texture(ptr, source, destination, copy_size)

	err = get_last_error()

	return
}

// Finishes recording commands and creates a new command buffer with the given descriptor.
// Returns a `Command_Buffer` to submit to `Queue`.
command_encoder_finish :: proc(
	using self: ^Command_Encoder,
	descriptor: ^Command_Buffer_Descriptor = nil,
	loc := #caller_location,
) -> (
	command_buffer: Command_Buffer,
	err: Error,
) {
	set_and_reset_err_data(_err_data, loc)

	command_buffer.ptr = wgpu.command_encoder_finish(ptr, descriptor)

	if err = get_last_error(); err != nil {
		if command_buffer.ptr != nil {
			wgpu.command_buffer_release(command_buffer.ptr)
		}
	}

	return
}

// Inserts debug marker.
command_encoder_insert_debug_marker :: proc(
	using self: ^Command_Encoder,
	marker_label: cstring,
	loc := #caller_location,
) -> (
	err: Error,
) {
	set_and_reset_err_data(_err_data, loc)

	wgpu.command_encoder_insert_debug_marker(ptr, marker_label)

	err = get_last_error()

	return
}

// Stops command recording and creates debug group.
command_encoder_pop_debug_group :: proc(
	using self: ^Command_Encoder,
	loc := #caller_location,
) -> (
	err: Error,
) {
	set_and_reset_err_data(_err_data, loc)

	wgpu.command_encoder_pop_debug_group(ptr)

	err = get_last_error()

	return
}

// Start record commands and group it into debug marker group.
command_encoder_push_debug_group :: proc(
	using self: ^Command_Encoder,
	group_label: cstring,
	loc := #caller_location,
) -> (
	err: Error,
) {
	set_and_reset_err_data(_err_data, loc)

	wgpu.command_encoder_push_debug_group(ptr, group_label)

	err = get_last_error()

	return
}

// Resolve a query set, writing the results into the supplied destination buffer.
//
// Queries may be between 8 and 40 bytes each. See `Pipeline_Statistics_Types` for more information.
command_encoder_resolve_query_set :: proc(
	using self: ^Command_Encoder,
	query_set: Raw_Query_Set,
	first_query: u32,
	query_count: u32,
	destination: Raw_Buffer,
	destination_offset: u64,
	loc := #caller_location,
) -> (
	err: Error,
) {
	set_and_reset_err_data(_err_data, loc)

	wgpu.command_encoder_resolve_query_set(
		ptr,
		query_set,
		first_query,
		query_count,
		destination,
		destination_offset,
	)

	err = get_last_error()

	return
}

// Set debug label.
command_encoder_set_label :: proc(using self: ^Command_Encoder, label: cstring) {
	wgpu.command_encoder_set_label(ptr, label)
}

// Issue a timestamp command at this point in the queue. The timestamp will be written to the
// specified query set, at the specified index.
command_encoder_write_timestamp :: proc(
	using self: ^Command_Encoder,
	query_set: Raw_Query_Set,
	query_index: u32,
	loc := #caller_location,
) -> (
	err: Error,
) {
	set_and_reset_err_data(_err_data, loc)

	wgpu.command_encoder_write_timestamp(ptr, query_set, query_index)

	err = get_last_error()

	return
}

// Increase the reference count.
command_encoder_reference :: proc(using self: ^Command_Encoder) {
	wgpu.command_encoder_reference(ptr)
}

// Release the `Command_Encoder`.
command_encoder_release :: proc(using self: ^Command_Encoder) {
	wgpu.command_encoder_release(ptr)
}

// Release the `Command_Encoder` and modify the raw pointer to `nil`.
command_encoder_release_and_nil :: proc(using self: ^Command_Encoder) {
	if ptr == nil do return
	wgpu.command_encoder_release(ptr)
	ptr = nil
}
