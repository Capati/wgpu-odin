package wgpu

// Package
import wgpu "../bindings"

// Handle to a command buffer on the GPU.
//
// A `Command_Buffer` represents a complete sequence of commands that may be submitted to a command
// queue with [`Queue::submit`]. A `Command_Buffer` is obtained by recording a series of commands to
// a [`Command_Encoder`] and then calling [`command_encoder_finish`].
//
// Corresponds to [WebGPU `GPUCommandBuffer`](https://gpuweb.github.io/gpuweb/#command-buffer).
Command_Buffer :: struct {
	ptr:  Raw_Command_Buffer,
	_pad: POINTER_PROMOTION_PADDING,
}

// Set debug label.
command_buffer_set_label :: proc "contextless" (using self: Command_Buffer, label: cstring) {
	wgpu.command_buffer_set_label(ptr, label)
}

// Increase the reference count.
command_buffer_reference :: proc "contextless" (using self: Command_Buffer) {
	wgpu.command_buffer_reference(ptr)
}

// Release the `Command_Buffer`.
command_buffer_release :: #force_inline proc "contextless" (using self: Command_Buffer) {
	wgpu.command_buffer_release(ptr)
}

// Release the `Command_Buffer` and modify the raw pointer to `nil`.
command_buffer_release_and_nil :: proc "contextless" (using self: ^Command_Buffer) {
	if ptr == nil do return
	wgpu.command_buffer_release(ptr)
	ptr = nil
}
