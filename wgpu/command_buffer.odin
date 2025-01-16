package wgpu

/*
Handle to a command buffer on the GPU.

A `Command_Buffer` represents a complete sequence of commands that may be submitted to a command
queue with `queue_submit`. A `Command_Buffer` is obtained by recording a series of commands to
a `Command_Encoder` and then calling `command_encoder_finish`.

Corresponds to [WebGPU `GPUCommandBuffer`](https://gpuweb.github.io/gpuweb/#command-buffer).
*/
Command_Buffer :: distinct rawptr

/* Sets a debug label for the given `Command_Buffer`. */
@(disabled = !ODIN_DEBUG)
command_buffer_set_label :: proc "contextless" (self: Command_Buffer, label: string) {
	c_label: String_View_Buffer
	wgpuCommandBufferSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the `Command_Buffer` reference count. */
command_buffer_add_ref :: wgpuCommandBufferAddRef

/* Release the `Command_Buffer` resources, use to decrease the reference count. */
command_buffer_release :: wgpuCommandBufferRelease

/*
Safely releases the `Command_Buffer` resources and invalidates the handle.
The procedure checks both the pointer validity and Command buffer handle before releasing.

Note: After calling this, Command buffer handle will be set to `nil` and should not be used.
*/
command_buffer_release_safe :: #force_inline proc(self: ^Command_Buffer) {
	if self != nil && self^ != nil {
		wgpuCommandBufferRelease(self^)
		self^ = nil
	}
}
