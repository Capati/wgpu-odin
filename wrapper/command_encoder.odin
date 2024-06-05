package wgpu

// Core
import "core:runtime"

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
) -> (
	compute_pass: Compute_Pass_Encoder,
	err: Error_Type,
) {
	compute_pass.ptr = wgpu.command_encoder_begin_compute_pass(ptr, descriptor)

	if compute_pass.ptr == nil {
		update_error_message("Failed to acquire Compute_Pass_Encoder")
		return {}, .Unknown
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
) -> Error_Type {
	assert(offset % 4 == 0, "'offset' must be a multiple of 4")
	assert(size > 0, "clear_buffer size must be > 0")
	assert(size % 4 == 0, "size must be a multiple of 4")
	assert(offset + size <= size, "buffer size out of range")

	_err_data.type = .No_Error

	wgpu.command_encoder_clear_buffer(ptr, buffer, offset, size)

	return _err_data.type
}

// Copy data from one buffer to another.
command_encoder_copy_buffer_to_buffer :: proc(
	using self: ^Command_Encoder,
	source: Raw_Buffer,
	source_offset: u64,
	destination: Raw_Buffer,
	destination_offset: u64,
	size: u64,
) -> Error_Type {
	assert(source_offset % 4 == 0, "'source_offset' must be a multiple of 4")
	assert(destination_offset % 4 == 0, "'destination_offset' must be a multiple of 4")
	assert(size % 4 == 0, "'size' must be a multiple of 4")

	_err_data.type = .No_Error

	wgpu.command_encoder_copy_buffer_to_buffer(
		ptr,
		source,
		source_offset,
		destination,
		destination_offset,
		size,
	)

	return _err_data.type
}

// Copy data from a buffer to a texture.
command_encoder_copy_buffer_to_texture :: proc(
	using self: ^Command_Encoder,
	source: ^Image_Copy_Buffer,
	destination: ^Image_Copy_Texture,
	copy_size: ^Extent_3D,
) -> Error_Type {
	if source != nil {
		if source.layout.bytes_per_row % Copy_Bytes_Per_Row_Alignment != 0 {
			update_error_message("bytes_per_row must be a multiple of 256")
			return .Validation
		}
	}

	_err_data.type = .No_Error

	wgpu.command_encoder_copy_buffer_to_texture(ptr, source, destination, copy_size)

	return _err_data.type
}

// Copy data from a texture to a buffer.
command_encoder_copy_texture_to_buffer :: proc(
	using self: ^Command_Encoder,
	source: ^Image_Copy_Texture,
	destination: ^Image_Copy_Buffer,
	copy_size: ^Extent_3D,
) -> Error_Type {
	if destination != nil {
		if destination.layout.bytes_per_row % Copy_Bytes_Per_Row_Alignment != 0 {
			update_error_message("bytes_per_row must be a multiple of 256")
			return .Validation
		}
	}

	_err_data.type = .No_Error

	wgpu.command_encoder_copy_texture_to_buffer(ptr, source, destination, copy_size)

	return _err_data.type
}

// Copy data from one texture to another.
command_encoder_copy_texture_to_texture :: proc(
	using self: ^Command_Encoder,
	source: ^Image_Copy_Texture,
	destination: ^Image_Copy_Texture,
	copy_size: ^Extent_3D,
) -> Error_Type {
	_err_data.type = .No_Error

	wgpu.command_encoder_copy_texture_to_texture(ptr, source, destination, copy_size)

	return _err_data.type
}

// Finishes recording commands and creates a new command buffer with the given descriptor.
// Returns a `Command_Buffer` to submit to `Queue`.
command_encoder_finish :: proc(
	using self: ^Command_Encoder,
	descriptor: ^Command_Buffer_Descriptor = nil,
) -> (
	command_buffer: Command_Buffer,
	err: Error_Type,
) {
	_err_data.type = .No_Error

	command_buffer.ptr = wgpu.command_encoder_finish(ptr, descriptor)

	if _err_data.type != .No_Error {
		if command_buffer.ptr != nil {
			wgpu.command_buffer_release(command_buffer.ptr)
		}
		return {}, _err_data.type
	}

	return
}

// Inserts debug marker.
command_encoder_insert_debug_marker :: proc(
	using self: ^Command_Encoder,
	marker_label: cstring,
) -> Error_Type {
	_err_data.type = .No_Error

	wgpu.command_encoder_insert_debug_marker(ptr, marker_label)

	return _err_data.type
}

// Stops command recording and creates debug group.
command_encoder_pop_debug_group :: proc(using self: ^Command_Encoder) -> Error_Type {
	_err_data.type = .No_Error

	wgpu.command_encoder_pop_debug_group(ptr)

	return _err_data.type
}

// Start record commands and group it into debug marker group.
command_encoder_push_debug_group :: proc(
	using self: ^Command_Encoder,
	group_label: cstring,
) -> Error_Type {
	_err_data.type = .No_Error

	wgpu.command_encoder_push_debug_group(ptr, group_label)

	return _err_data.type
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
) -> Error_Type {
	_err_data.type = .No_Error

	wgpu.command_encoder_resolve_query_set(
		ptr,
		query_set,
		first_query,
		query_count,
		destination,
		destination_offset,
	)

	return _err_data.type
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
) -> Error_Type {
	_err_data.type = .No_Error

	wgpu.command_encoder_write_timestamp(ptr, query_set, query_index)

	return _err_data.type
}

// Increase the reference count.
command_encoder_reference :: proc(using self: ^Command_Encoder) {
	wgpu.command_encoder_reference(ptr)
}

// Release the `Command_Encoder`.
command_encoder_release :: proc(using self: ^Command_Encoder) {
	if ptr == nil do return
	wgpu.command_encoder_release(ptr)
	ptr = nil
}
