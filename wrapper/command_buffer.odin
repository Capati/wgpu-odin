package wgpu

// Package
import wgpu "../bindings"

// Handle to a command buffer on the GPU.
Command_Buffer :: struct {
    ptr:          WGPU_Command_Buffer,
    using vtable: ^Command_Buffer_VTable,
}

@(private)
Command_Buffer_VTable :: struct {
    set_label: proc(self: ^Command_Buffer, label: cstring),
    reference: proc(self: ^Command_Buffer),
    release:   proc(self: ^Command_Buffer),
}

@(private)
default_command_buffer_vtable := Command_Buffer_VTable {
    set_label = command_buffer_set_label,
    reference = command_buffer_reference,
    release   = command_buffer_release,
}

@(private)
default_command_buffer := Command_Buffer {
    ptr    = nil,
    vtable = &default_command_buffer_vtable,
}

command_buffer_set_label :: proc(using self: ^Command_Buffer, label: cstring) {
    wgpu.command_buffer_set_label(ptr, label)
}

command_buffer_reference :: proc(using self: ^Command_Buffer) {
    wgpu.command_buffer_reference(ptr)
}

// Release the `Command_Buffer`.
command_buffer_release :: proc(using self: ^Command_Buffer) {
    wgpu.command_buffer_release(ptr)
}
