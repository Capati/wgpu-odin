package wgpu

// Core
import "core:fmt"
import "core:runtime"

// Package
import wgpu "../bindings"

// Encodes a series of GPU operations.
Command_Encoder :: struct {
    ptr:          WGPU_Command_Encoder,
    err_scope: ^Error_Scope,
    using vtable: ^Command_Encoder_VTable,
}

@(private)
Command_Encoder_VTable :: struct {
    begin_compute_pass:      proc(
        self: ^Command_Encoder,
        descriptor: ^Compute_Pass_Descriptor,
    ) -> Compute_Pass_Encoder,
    begin_render_pass:       proc(
        self: ^Command_Encoder,
        descriptor: ^Render_Pass_Descriptor,
    ) -> Render_Pass_Encoder,
    clear_buffer:            proc(
        self: ^Command_Encoder,
        buffer: Buffer,
        offset, size: u64,
    ) -> Error_Type,
    copy_buffer_to_buffer:   proc(
        self: ^Command_Encoder,
        source: Buffer,
        source_offset: u64,
        destination: Buffer,
        destination_offset: u64,
        size: u64,
    ) -> Error_Type,
    copy_buffer_to_texture:  proc(
        self: ^Command_Encoder,
        source: ^Image_Copy_Buffer,
        destination: ^Image_Copy_Texture,
        copy_size: ^Extent_3D,
    ) -> Error_Type,
    copy_texture_to_buffer:  proc(
        self: ^Command_Encoder,
        source: ^Image_Copy_Texture,
        destination: ^Image_Copy_Buffer,
        copy_size: ^Extent_3D,
    ) -> Error_Type,
    copy_texture_to_texture: proc(
        self: ^Command_Encoder,
        source: ^Image_Copy_Texture,
        destination: ^Image_Copy_Texture,
        copy_size: ^Extent_3D,
    ) -> Error_Type,
    finish:                  proc(
        self: ^Command_Encoder,
        label: cstring = "Default command buffer",
    ) -> (
        Command_Buffer,
        Error_Type,
    ),
    insert_debug_marker:     proc(
        self: ^Command_Encoder,
        marker_label: cstring,
    ) -> Error_Type,
    pop_debug_group:         proc(self: ^Command_Encoder) -> Error_Type,
    push_debug_group:        proc(
        self: ^Command_Encoder,
        group_label: cstring,
    ) -> Error_Type,
    resolve_query_set:       proc(
        self: ^Command_Encoder,
        query_set: Query_Set,
        first_query: u32,
        query_count: u32,
        destination: Buffer,
        destination_offset: u64,
    ) -> Error_Type,
    set_label:               proc(self: ^Command_Encoder, label: cstring),
    write_timestamp:         proc(
        self: ^Command_Encoder,
        query_set: Query_Set,
        query_index: u32,
    ) -> Error_Type,
    reference:               proc(self: ^Command_Encoder),
    release:                 proc(self: ^Command_Encoder),
}

@(private)
default_gpu_command_encoder_vtable := Command_Encoder_VTable {
    begin_compute_pass      = command_encoder_begin_compute_pass,
    begin_render_pass       = command_encoder_begin_render_pass,
    clear_buffer            = command_encoder_clear_buffer,
    copy_buffer_to_buffer   = command_encoder_copy_buffer_to_buffer,
    copy_buffer_to_texture  = command_encoder_copy_buffer_to_texture,
    copy_texture_to_buffer  = command_encoder_copy_texture_to_buffer,
    copy_texture_to_texture = command_encoder_copy_texture_to_texture,
    finish                  = command_encoder_finish,
    insert_debug_marker     = command_encoder_insert_debug_marker,
    pop_debug_group         = command_encoder_pop_debug_group,
    push_debug_group        = command_encoder_push_debug_group,
    resolve_query_set       = command_encoder_resolve_query_set,
    set_label               = command_encoder_set_label,
    write_timestamp         = command_encoder_write_timestamp,
    release                 = command_encoder_release,
}

@(private)
default_gpu_command_encoder := Command_Encoder {
    vtable = &default_gpu_command_encoder_vtable,
}

// Begins recording of a compute pass.
command_encoder_begin_compute_pass :: proc(
    using self: ^Command_Encoder,
    descriptor: ^Compute_Pass_Descriptor,
) -> Compute_Pass_Encoder {
    compute_pass_ptr := wgpu.command_encoder_begin_compute_pass(ptr, descriptor)

    if compute_pass_ptr == nil {
        fmt.panicf("Failed to acquire Compute_Pass_Encoder")
    }


    compute_pass := default_compute_pass_encoder
    compute_pass.ptr = compute_pass_ptr
    compute_pass.err_scope = err_scope

    return compute_pass
}

// Describes a color attachment to a `Render_Pass`.
Render_Pass_Color_Attachment :: struct {
    view:           ^Texture_View,
    resolve_target: ^Texture_View,
    load_op:        Load_Op,
    store_op:       Store_Op,
    clear_value:    Color,
}

Render_Pass_Descriptor :: struct {
    label:                    cstring,
    color_attachments:        []Render_Pass_Color_Attachment,
    depth_stencil_attachment: ^Render_Pass_Depth_Stencil_Attachment,
    occlusion_query_set:      Query_Set,
    timestamp_writes:         []Render_Pass_Timestamp_Write,
}

// Begins recording of a render pass.
command_encoder_begin_render_pass :: proc(
    using self: ^Command_Encoder,
    descriptor: ^Render_Pass_Descriptor,
) -> Render_Pass_Encoder {

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
                &{
                    load_op = color_attachment.load_op,
                    store_op = color_attachment.store_op,
                    clear_value = color_attachment.clear_value,
                }

                if color_attachment.view != nil {
                    desc.color_attachments.view = color_attachment.view.ptr
                }

                if color_attachment.resolve_target != nil {
                    desc.color_attachments.resolve_target =
                        color_attachment.resolve_target.ptr
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
                        color_attachment.view = v.view.ptr
                    }

                    if v.resolve_target != nil {
                        color_attachment.resolve_target = v.resolve_target.ptr
                    }

                    color_attachments_slice[i] = color_attachment
                }

                desc.color_attachment_count = color_attachment_count
                desc.color_attachments = raw_data(color_attachments_slice)
            }
        }

        if descriptor.depth_stencil_attachment != nil {
            desc.depth_stencil_attachment = descriptor.depth_stencil_attachment
        }
    }

    render_pass_encoder_ptr := wgpu.command_encoder_begin_render_pass(ptr, &desc)


    render_pass := default_render_pass_encoder
    render_pass.ptr = render_pass_encoder_ptr

    return render_pass
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

    err_scope.type = .No_Error

    wgpu.command_encoder_clear_buffer(ptr, buffer.ptr, offset, size)

    return err_scope.type
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

    err_scope.type = .No_Error

    wgpu.command_encoder_copy_buffer_to_buffer(
        ptr,
        source.ptr,
        source_offset,
        destination.ptr,
        destination_offset,
        size,
    )

    return err_scope.type
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
            fmt.eprintf(
                "%s: 'bytes_per_row' [%d] must be a multiple of [%d]\n",
                #procedure,
                source.layout.bytes_per_row,
                Copy_Bytes_Per_Row_Alignment,
            )
            return .Validation
        }
    }

    err_scope.type = .No_Error

    wgpu.command_encoder_copy_buffer_to_texture(ptr, source, destination, copy_size)

    return err_scope.type
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
            fmt.eprintf(
                "%s: 'bytes_per_row' [%d] must be a multiple of [%d]\n",
                #procedure,
                destination.layout.bytes_per_row,
                Copy_Bytes_Per_Row_Alignment,
            )
            return .Validation
        }
    }

    err_scope.type = .No_Error

    wgpu.command_encoder_copy_texture_to_buffer(ptr, source, destination, copy_size)

    return err_scope.type
}

// Copy data from one texture to another.
command_encoder_copy_texture_to_texture :: proc(
    using self: ^Command_Encoder,
    source: ^Image_Copy_Texture,
    destination: ^Image_Copy_Texture,
    copy_size: ^Extent_3D,
) -> Error_Type {
    err_scope.type = .No_Error

    wgpu.command_encoder_copy_texture_to_texture(ptr, source, destination, copy_size)

    return err_scope.type
}

// Finish recording. Returns a `Command_Buffer` to submit to `Queue`.
command_encoder_finish :: proc(
    using self: ^Command_Encoder,
    label: cstring = "Default command buffer",
) -> (
    Command_Buffer,
    Error_Type,
) {
    err_scope.type = .No_Error

    command_buffer_ptr := wgpu.command_encoder_finish(
        ptr,
        &Command_Buffer_Descriptor{label = label},
    )

    if err_scope.type != .No_Error {
        if command_buffer_ptr != nil {
            wgpu.command_buffer_release(command_buffer_ptr)
        }
        return {}, err_scope.type
    }

    command_buffer := default_command_buffer
    command_buffer.ptr = command_buffer_ptr

    return command_buffer, .No_Error
}

command_encoder_insert_debug_marker :: proc(
    using self: ^Command_Encoder,
    marker_label: cstring,
) -> Error_Type {
    err_scope.type = .No_Error

    wgpu.command_encoder_insert_debug_marker(ptr, marker_label)

    return err_scope.type
}

command_encoder_pop_debug_group :: proc(using self: ^Command_Encoder) -> Error_Type {
    err_scope.type = .No_Error

    wgpu.command_encoder_pop_debug_group(ptr)

    return err_scope.type
}

command_encoder_push_debug_group :: proc(
    using self: ^Command_Encoder,
    group_label: cstring,
) -> Error_Type {
    err_scope.type = .No_Error

    wgpu.command_encoder_push_debug_group(ptr, group_label)

    return err_scope.type
}

command_encoder_resolve_query_set :: proc(
    using self: ^Command_Encoder,
    query_set: Query_Set,
    first_query: u32,
    query_count: u32,
    destination: Buffer,
    destination_offset: u64,
) -> Error_Type {
    err_scope.type = .No_Error

    wgpu.command_encoder_resolve_query_set(
        ptr,
        query_set.ptr,
        first_query,
        query_count,
        destination.ptr,
        destination_offset,
    )

    return err_scope.type
}

command_encoder_set_label :: proc(using self: ^Command_Encoder, label: cstring) {
    wgpu.command_encoder_set_label(ptr, label)
}

command_encoder_write_timestamp :: proc(
    using self: ^Command_Encoder,
    query_set: Query_Set,
    query_index: u32,
) -> Error_Type {
    err_scope.type = .No_Error

    wgpu.command_encoder_write_timestamp(ptr, query_set.ptr, query_index)

    return err_scope.type
}

command_encoder_reference :: proc(using self: ^Command_Encoder) {
    wgpu.command_encoder_reference(ptr)
}

// Release the `Command_Encoder`.
command_encoder_release :: proc(using self: ^Command_Encoder) {
    wgpu.command_encoder_release(ptr)
}
