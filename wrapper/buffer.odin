package wgpu

// Core
import "core:fmt"
import "core:mem"
import "core:slice"

// Package
import wgpu "../bindings"

// Handle to a GPU-accessible buffer.
Buffer :: struct {
    ptr:          WGPU_Buffer,
    device_ptr:   WGPU_Device,
    err_data:    ^Error_Data,
    size:         Buffer_Size,
    map_state:    Buffer_Map_State,
    usage:        Buffer_Usage_Flags,
    using vtable: ^Buffer_VTable,
}

@(private)
Buffer_VTable :: struct {
    destroy:                proc(self: ^Buffer),
    get_const_mapped_range: proc(self: ^Buffer),
    get_mapped_range:       proc(
        self: ^Buffer,
        byte_count: uint = 0,
        offset: uint = 0,
    ) -> []byte,
    get_map_state:          proc(self: ^Buffer) -> Buffer_Map_State,
    get_size:               proc(self: ^Buffer) -> u64,
    get_usage:              proc(self: ^Buffer) -> Buffer_Usage_Flags,
    map_read:               proc(self: ^Buffer) -> ([]byte, Buffer_Map_Async_Status),
    map_write:              proc(self: ^Buffer, data: []byte) -> Buffer_Map_Async_Status,
    map_async:              proc(
        self: ^Buffer,
        mode: Map_Mode_Flags,
        offset, size: uint,
    ) -> Buffer_Map_Async_Status,
    set_label:              proc(self: ^Buffer, label: cstring),
    unmap:                  proc(self: ^Buffer) -> Error_Type,
    release:                proc(self: ^Buffer),
}

@(private)
default_buffer_vtable := Buffer_VTable {
    destroy          = buffer_destroy,
    get_mapped_range = buffer_get_mapped_range,
    get_map_state    = buffer_get_map_state,
    get_size         = buffer_get_size,
    get_usage        = buffer_get_usage,
    map_read         = buffer_map_read,
    map_write        = buffer_map_write,
    map_async        = buffer_map_async,
    set_label        = buffer_set_label,
    unmap            = buffer_unmap,
    release          = buffer_release,
}

@(private)
default_buffer := Buffer {
    ptr    = nil,
    vtable = &default_buffer_vtable,
}

// Destroys the `Buffer`.
buffer_destroy :: proc(using self: ^Buffer) {
    wgpu.buffer_destroy(ptr)
}

// Returns a `slice` of `bytes` with the contents of the `Buffer` in the given mapped
// range.
buffer_get_mapped_range :: proc(
    self: ^Buffer,
    offset: uint = 0,
    size: uint = 0,
) -> []byte {
    size := size

    if size == 0 {
        size = cast(uint)self.size
    }

    return slice.bytes_from_ptr(
        wgpu.buffer_get_mapped_range(self.ptr, offset, size),
        cast(int)size,
    )
}

// Get current `Buffer_Map_State` state.
buffer_get_map_state :: proc(using self: ^Buffer) -> Buffer_Map_State {
    return wgpu.buffer_get_map_state(ptr)
}

// Returns the length of the buffer allocation in bytes.
buffer_get_size :: proc(using self: ^Buffer) -> u64 {
    return wgpu.buffer_get_size(ptr)
}

// Returns the allowed usages for this Buffer.
buffer_get_usage :: proc(using self: ^Buffer) -> Buffer_Usage_Flags {
    return transmute(Buffer_Usage_Flags)wgpu.buffer_get_usage(ptr)
}

Buffer_Map_Async_Response :: struct {
    status: Buffer_Map_Async_Status,
}

@(private)
_buffer_map_callback :: proc "c" (status: Buffer_Map_Async_Status, user_data: rawptr) {
    response := cast(^Buffer_Map_Async_Response)user_data
    response.status = status
}

buffer_map_read :: proc(using self: ^Buffer) -> ([]byte, Buffer_Map_Async_Status) {
    if self->map_async({.Read}, 0, cast(uint)size) != .Success {
        return {}, .Validation_Error
    }

    data := slice.bytes_from_ptr(
        wgpu.buffer_get_mapped_range(ptr, 0, cast(uint)size),
        cast(int)size,
    )

    wgpu.buffer_unmap(ptr)

    return data, .Success
}

buffer_map_write :: proc(using self: ^Buffer, data: []byte) -> Buffer_Map_Async_Status {
    if self->map_async({.Write}, 0, cast(uint)size) != .Success {
        return .Validation_Error
    }

    src_ptr := wgpu.buffer_get_mapped_range(ptr, 0, cast(uint)size)
    mem.copy(src_ptr, raw_data(data), cast(int)size)

    wgpu.buffer_unmap(ptr)

    return .Success
}

//TODO(JopStro): Why is this syncronous? It has ASYNC in the bloody name!
// Maps the given range of the buffer.
buffer_map_async :: proc(
    self: ^Buffer,
    mode: Map_Mode_Flags,
    offset, size: uint,
) -> Buffer_Map_Async_Status {
    res := Buffer_Map_Async_Response {
        status = .Unknown,
    }

    self.err_data.type = .No_Error

    self.map_state = .Pending

    wgpu.buffer_map_async(self.ptr, mode, offset, size, _buffer_map_callback, &res)

    if self.err_data.type != .No_Error {
        return .Validation_Error
    }

    wgpu.device_poll(self.device_ptr, true, nil)

    if res.status != .Success {
        fmt.eprintf("ERROR: Could not read buffer data: %v\n", res.status)
        return res.status
    }

    self.map_state = .Mapped

    return res.status
}

// Set debug label.
buffer_set_label :: proc(using self: ^Buffer, label: cstring) {
    wgpu.buffer_set_label(ptr, label)
}

// Unmaps the mapped range of the `Buffer` and makes it's contents available for use
// by the GPU again.
buffer_unmap :: proc(using self: ^Buffer) -> Error_Type {
    err_data.type = .No_Error

    wgpu.buffer_unmap(ptr)

    map_state = .Unmapped

    return err_data.type
}

// Release the `Buffer`.
buffer_release :: proc(using self: ^Buffer) {
    wgpu.device_release(device_ptr)
    wgpu.buffer_release(ptr)
}
