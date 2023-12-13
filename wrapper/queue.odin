package wgpu

// Core
import "core:runtime"

// Package
import wgpu "../bindings"

// Handle to a command queue on a device.
Queue :: struct {
    ptr:          WGPU_Queue,
    err_data:     ^Error_Data,
    using vtable: ^Queue_VTable,
}

@(private)
Queue_VTable :: struct {
    on_submitted_work_done: proc(
        self: ^Queue,
        callback: Queue_Work_Done_Callback,
        data: rawptr = nil,
    ),
    set_label:              proc(self: ^Queue, label: cstring),
    submit:                 proc(self: ^Queue, commands: ..Command_Buffer),
    submit_for_index:       proc(self: ^Queue, commands: ..Command_Buffer) -> Submission_Index,
    write_buffer:           proc(
        self: ^Queue,
        buffer: ^Buffer,
        offset: Buffer_Address,
        data: []byte,
    ) -> Error_Type,
    write_texture:          proc(
        self: ^Queue,
        destination: ^Image_Copy_Texture,
        data: []byte,
        data_layout: ^Texture_Data_Layout,
        write_size: ^Extent_3D,
    ) -> Error_Type,
    reference:              proc(self: ^Queue),
    release:                proc(self: ^Queue),
}

@(private)
default_queue_vtable := Queue_VTable {
    on_submitted_work_done = queue_on_submitted_work_done,
    set_label              = queue_set_label,
    submit                 = queue_submit,
    submit_for_index       = queue_submit_for_index,
    write_buffer           = queue_write_buffer,
    write_texture          = queue_write_texture,
    reference              = queue_reference,
    release                = queue_release,
}

@(private)
default_queue := Queue {
    ptr    = nil,
    vtable = &default_queue_vtable,
}

queue_on_submitted_work_done :: proc(
    using self: ^Queue,
    callback: Queue_Work_Done_Callback,
    data: rawptr = nil,
) {
    wgpu.queue_on_submitted_work_done(ptr, callback, data)
}

// Set debug label.
queue_set_label :: proc(using self: ^Queue, label: cstring) {
    wgpu.queue_set_label(ptr, label)
}

// Submits a series of finished command buffers for execution.
queue_submit :: proc(using self: ^Queue, commands: ..Command_Buffer) {
    command_count := cast(uint)len(commands)

    if command_count == 0 {
        wgpu.queue_submit(ptr, 0, nil)
        return
    } else if command_count == 1 {
        wgpu.queue_submit(ptr, 1, &commands[0].ptr)
        return
    }

    runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
    commands_ptrs := make([]WGPU_Command_Buffer, command_count, context.temp_allocator)

    for c, i in commands {
        commands_ptrs[i] = c.ptr
    }

    wgpu.queue_submit(ptr, command_count, raw_data(commands_ptrs))
}

// Submits a series of finished command buffers for execution and return the index of the queue.
queue_submit_for_index :: proc(
    using self: ^Queue,
    commands: ..Command_Buffer,
) -> Submission_Index {
    command_count := cast(uint)len(commands)

    if command_count == 0 {
        return wgpu.queue_submit_for_index(ptr, 0, nil)
    } else if command_count == 1 {
        return wgpu.queue_submit_for_index(ptr, 1, &commands[0].ptr)
    }

    runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
    commands_ptrs := make([]WGPU_Command_Buffer, command_count, context.temp_allocator)

    for c, i in commands {
        commands_ptrs[i] = c.ptr
    }

    return wgpu.queue_submit_for_index(ptr, command_count, raw_data(commands_ptrs))
}

// Schedule a data write into `buffer` starting at `offset`.
queue_write_buffer :: proc(
    using self: ^Queue,
    buffer: ^Buffer,
    offset: Buffer_Address,
    data: []byte,
) -> (
    err: Error_Type,
) {
    err_data.type = .No_Error

    data_size := cast(uint)len(data)

    if data_size == 0 {
        wgpu.queue_write_buffer(ptr, buffer.ptr, offset, nil, 0)
    } else {
        wgpu.queue_write_buffer(ptr, buffer.ptr, offset, raw_data(data), data_size)
    }

    return err_data.type
}

// Schedule a write of some data into a texture.
queue_write_texture :: proc(
    using self: ^Queue,
    destination: ^Image_Copy_Texture,
    data: []byte,
    data_layout: ^Texture_Data_Layout,
    size: ^Extent_3D,
) -> (
    err: Error_Type,
) {
    err_data.type = .No_Error

    dst: wgpu.Image_Copy_Texture

    if destination != nil {
        dst = {
            mip_level = destination.mip_level,
            origin    = destination.origin,
            aspect    = destination.aspect,
        }

        if destination.texture != nil {
            dst.texture = destination.texture.ptr
        }
    }

    data_size := cast(uint)len(data)

    if data_size == 0 {
        wgpu.queue_write_texture(ptr, &dst, nil, 0, data_layout, size)
    } else {
        wgpu.queue_write_texture(ptr, &dst, raw_data(data), data_size, data_layout, size)
    }

    return err_data.type
}

queue_reference :: proc(using self: ^Queue) {
    wgpu.queue_reference(ptr)
}

queue_release :: proc(using self: ^Queue) {
    wgpu.queue_release(ptr)
}
