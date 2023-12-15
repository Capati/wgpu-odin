package wgpu

// Package
import wgpu "../bindings"

// Handle to a command buffer on the GPU.
//
// A `Command_Buffer` represents a complete sequence of commands that may be submitted to a command
// queue with `queue_submit`. A `Command_Buffer` is obtained by recording a series of commands to a
// `Command_Encoder` and then calling `command_encoder_finish`.
Command_Buffer :: struct {
	_ptr: WGPU_Command_Buffer,
}

// Set debug label.
command_buffer_set_label :: proc(using self: ^Command_Buffer, label: cstring) {
	wgpu.command_buffer_set_label(_ptr, label)
}

// Increase the reference count.
command_buffer_reference :: proc(using self: ^Command_Buffer) {
	wgpu.command_buffer_reference(_ptr)
}

// Release the `Command_Buffer`.
command_buffer_release :: proc(using self: ^Command_Buffer) {
	wgpu.command_buffer_release(_ptr)
}
