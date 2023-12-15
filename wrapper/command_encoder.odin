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
	_ptr:      WGPU_Command_Encoder,
	_err_data: ^Error_Data,
}

// Begins recording of a compute pass.
//
// This function returns a `Compute_Pass` object which records a single render pass.
command_encoder_begin_compute_pass :: proc(
	using self: ^Command_Encoder,
	descriptor: ^Compute_Pass_Descriptor,
) -> (
	compute_pass: Compute_Pass,
	err: Error_Type,
) {
	compute_pass_ptr := wgpu.command_encoder_begin_compute_pass(_ptr, descriptor)

	if compute_pass_ptr == nil {
		update_error_message("Failed to acquire Compute_Pass")
		return {}, .Unknown
	}

	compute_pass._ptr = compute_pass_ptr
	compute_pass._err_data = _err_data

	return
}

// Describes a color attachment to a `Render_Pass`.
Render_Pass_Color_Attachment :: struct {
	view:           ^Texture_View,
	resolve_target: ^Texture_View,
	load_op:        Load_Op,
	store_op:       Store_Op,
	clear_value:    Color,
}

// Describes a depth/stencil attachment to a `Render_Pass`.
Render_Pass_Depth_Stencil_Attachment :: struct {
	view:                ^Texture_View,
	depth_load_op:       Load_Op,
	depth_store_op:      Store_Op,
	depth_clear_value:   f32,
	depth_read_only:     bool,
	stencil_load_op:     Load_Op,
	stencil_store_op:    Store_Op,
	stencil_clear_value: u32,
	stencil_read_only:   bool,
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
	occlusion_query_set:      Query_Set,
	timestamp_writes:         []Render_Pass_Timestamp_Writes,
}

// Begins recording of a render pass.
command_encoder_begin_render_pass :: proc(
	using self: ^Command_Encoder,
	descriptor: ^Render_Pass_Descriptor,
) -> (
	render_pass: Render_Pass,
) {
	desc := wgpu.Render_Pass_Descriptor {
		next_in_chain = nil,
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	if descriptor != nil {
		desc.label = descriptor.label

		color_attachment_count := cast(uint)len(descriptor.color_attachments)

		if color_attachment_count > 0 {
			if color_attachment_count == 1 {
				desc.color_attachment_count = 1

				color_attachment := descriptor.color_attachments[0]

				desc.color_attachments =
				& {
					load_op = color_attachment.load_op,
					store_op = color_attachment.store_op,
					clear_value = color_attachment.clear_value,
				}

				if color_attachment.view != nil {
					desc.color_attachments.view = color_attachment.view._ptr
				}

				if color_attachment.resolve_target != nil {
					desc.color_attachments.resolve_target = color_attachment.resolve_target._ptr
				}
			} else {
				color_attachments_slice := make(
					[]wgpu.Render_Pass_Color_Attachment,
					color_attachment_count,
					context.temp_allocator,
				)

				for v, i in descriptor.color_attachments {
					color_attachment := wgpu.Render_Pass_Color_Attachment {
						load_op     = v.load_op,
						store_op    = v.store_op,
						clear_value = v.clear_value,
					}

					if v.view != nil {
						color_attachment.view = v.view._ptr
					}

					if v.resolve_target != nil {
						color_attachment.resolve_target = v.resolve_target._ptr
					}

					color_attachments_slice[i] = color_attachment
				}

				desc.color_attachment_count = color_attachment_count
				desc.color_attachments = raw_data(color_attachments_slice)
			}
		}

		if descriptor.depth_stencil_attachment != nil {
			desc.depth_stencil_attachment =
			& {
				depth_load_op = descriptor.depth_stencil_attachment.depth_load_op,
				depth_store_op = descriptor.depth_stencil_attachment.depth_store_op,
				depth_clear_value = descriptor.depth_stencil_attachment.depth_clear_value,
				depth_read_only = descriptor.depth_stencil_attachment.depth_read_only,
				stencil_load_op = descriptor.depth_stencil_attachment.stencil_load_op,
				stencil_store_op = descriptor.depth_stencil_attachment.stencil_store_op,
				stencil_clear_value = descriptor.depth_stencil_attachment.stencil_clear_value,
				stencil_read_only = descriptor.depth_stencil_attachment.stencil_read_only,
			}

			if descriptor.depth_stencil_attachment.view != nil {
				desc.depth_stencil_attachment.view = descriptor.depth_stencil_attachment.view._ptr
			}
		}
	}

	render_pass_encoder_ptr := wgpu.command_encoder_begin_render_pass(_ptr, &desc)

	render_pass._ptr = render_pass_encoder_ptr
	render_pass._err_data = _err_data

	return
}

// Clears buffer to zero.
command_encoder_clear_buffer :: proc(
	using self: ^Command_Encoder,
	buffer: Buffer,
	offset: u64 = 0,
	size: u64 = 0,
) -> Error_Type {
	assert(offset % 4 == 0, "'offset' must be a multiple of 4")

	size := size

	if size == 0 {
		size = buffer.size - offset
	}

	assert(size > 0, "clear_buffer size must be > 0")
	assert(size % 4 == 0, "size must be a multiple of 4")
	assert(offset + size <= buffer.size, "buffer size out of range")

	_err_data.type = .No_Error

	wgpu.command_encoder_clear_buffer(_ptr, buffer._ptr, offset, size)

	return _err_data.type
}

// Copy data from one buffer to another.
command_encoder_copy_buffer_to_buffer :: proc(
	using self: ^Command_Encoder,
	source: Buffer,
	source_offset: u64,
	destination: Buffer,
	destination_offset: u64,
	size: u64,
) -> Error_Type {
	assert(source_offset % 4 == 0, "'source_offset' must be a multiple of 4")
	assert(destination_offset % 4 == 0, "'destination_offset' must be a multiple of 4")
	assert(size % 4 == 0, "'size' must be a multiple of 4")

	_err_data.type = .No_Error

	wgpu.command_encoder_copy_buffer_to_buffer(
		_ptr,
		source._ptr,
		source_offset,
		destination._ptr,
		destination_offset,
		size,
	)

	return _err_data.type
}

// View of a buffer which can be used to copy to/from a texture.
Image_Copy_Buffer :: struct {
	layout: Texture_Data_Layout,
	buffer: ^Buffer,
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

	src: wgpu.Image_Copy_Buffer

	if source != nil {
		if source.buffer != nil {
			src.buffer = source.buffer._ptr
		}

		src.layout = source.layout
	}

	dst: wgpu.Image_Copy_Texture

	if destination != nil {
		dst = {
			mip_level = destination.mip_level,
			origin    = destination.origin,
			aspect    = destination.aspect,
		}

		if destination.texture != nil {
			dst.texture = destination.texture._ptr
		}
	}

	wgpu.command_encoder_copy_buffer_to_texture(_ptr, &src, &dst, copy_size)

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

	src: wgpu.Image_Copy_Texture

	if source != nil {
		src = {
			mip_level = source.mip_level,
			origin    = source.origin,
			aspect    = source.aspect,
		}

		if source.texture != nil {
			src.texture = source.texture._ptr
		}
	}

	dst: wgpu.Image_Copy_Buffer

	if destination != nil {
		if destination.buffer != nil {
			dst.buffer = destination.buffer._ptr
		}

		dst.layout = destination.layout
	}

	wgpu.command_encoder_copy_texture_to_buffer(_ptr, &src, &dst, copy_size)

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

	src: wgpu.Image_Copy_Texture

	if source != nil {
		src = {
			mip_level = source.mip_level,
			origin    = source.origin,
			aspect    = source.aspect,
		}

		if source.texture != nil {
			src.texture = source.texture._ptr
		}
	}

	dst: wgpu.Image_Copy_Texture

	if destination != nil {
		dst = {
			mip_level = destination.mip_level,
			origin    = destination.origin,
			aspect    = destination.aspect,
		}

		if destination.texture != nil {
			dst.texture = destination.texture._ptr
		}
	}

	wgpu.command_encoder_copy_texture_to_texture(_ptr, &src, &dst, copy_size)

	return _err_data.type
}

// Finish recording. Returns a `Command_Buffer` to submit to `Queue`.
command_encoder_finish :: proc(
	using self: ^Command_Encoder,
	label: cstring = "Default command buffer",
) -> (
	command_buffer: Command_Buffer,
	err: Error_Type,
) {
	_err_data.type = .No_Error

	command_buffer_ptr := wgpu.command_encoder_finish(
		_ptr,
		&Command_Buffer_Descriptor{label = label},
	)

	if _err_data.type != .No_Error {
		if command_buffer_ptr != nil {
			wgpu.command_buffer_release(command_buffer_ptr)
		}
		return {}, _err_data.type
	}

	command_buffer._ptr = command_buffer_ptr

	return
}

// Inserts debug marker.
command_encoder_insert_debug_marker :: proc(
	using self: ^Command_Encoder,
	marker_label: cstring,
) -> Error_Type {
	_err_data.type = .No_Error

	wgpu.command_encoder_insert_debug_marker(_ptr, marker_label)

	return _err_data.type
}

// Start record commands and group it into debug marker group.
command_encoder_push_debug_group :: proc(
	using self: ^Command_Encoder,
	group_label: cstring,
) -> Error_Type {
	_err_data.type = .No_Error

	wgpu.command_encoder_push_debug_group(_ptr, group_label)

	return _err_data.type
}

// Stops command recording and creates debug group.
command_encoder_pop_debug_group :: proc(using self: ^Command_Encoder) -> Error_Type {
	_err_data.type = .No_Error

	wgpu.command_encoder_pop_debug_group(_ptr)

	return _err_data.type
}

// Resolve a query set, writing the results into the supplied destination buffer.
//
// Queries may be between 8 and 40 bytes each. See `Pipeline_Statistics_Types` for more information.
command_encoder_resolve_query_set :: proc(
	using self: ^Command_Encoder,
	query_set: ^Query_Set,
	first_query: u32,
	query_count: u32,
	destination: Buffer,
	destination_offset: u64,
) -> Error_Type {
	_err_data.type = .No_Error

	wgpu.command_encoder_resolve_query_set(
		_ptr,
		query_set._ptr,
		first_query,
		query_count,
		destination._ptr,
		destination_offset,
	)

	return _err_data.type
}

// Set debug label.
command_encoder_set_label :: proc(using self: ^Command_Encoder, label: cstring) {
	wgpu.command_encoder_set_label(_ptr, label)
}

// Issue a timestamp command at this point in the queue. The timestamp will be written to the
// specified query set, at the specified index.
command_encoder_write_timestamp :: proc(
	using self: ^Command_Encoder,
	query_set: Query_Set,
	query_index: u32,
) -> Error_Type {
	_err_data.type = .No_Error

	wgpu.command_encoder_write_timestamp(_ptr, query_set._ptr, query_index)

	return _err_data.type
}

// Increase the reference count.
command_encoder_reference :: proc(using self: ^Command_Encoder) {
	wgpu.command_encoder_reference(_ptr)
}

// Release the `Command_Encoder`.
command_encoder_release :: proc(using self: ^Command_Encoder) {
	wgpu.command_encoder_release(_ptr)
}
