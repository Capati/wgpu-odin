package wgpu

/*
Handle to a command buffer on the GPU.

A `CommandBuffer` represents a complete sequence of commands that may be submitted to a command
queue with `queue_submit`. A `CommandBuffer` is obtained by recording a series of commands to
a `CommandEncoder` and then calling `command_encoder_finish`.

Corresponds to [WebGPU `GPUCommandBuffer`](https://gpuweb.github.io/gpuweb/#command-buffer).
*/
CommandBuffer :: distinct rawptr

/* Sets a debug label for the given `CommandBuffer`. */
@(disabled = !ODIN_DEBUG)
command_buffer_set_label :: proc "contextless" (self: CommandBuffer, label: string) {
	c_label: StringViewBuffer
	wgpuCommandBufferSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the `CommandBuffer` reference count. */
command_buffer_add_ref :: wgpuCommandBufferAddRef

/* Release the `CommandBuffer` resources, use to decrease the reference count. */
command_buffer_release :: wgpuCommandBufferRelease

/*
Safely releases the `CommandBuffer` resources and invalidates the handle.
The procedure checks both the pointer validity and Command buffer handle before releasing.

Note: After calling this, Command buffer handle will be set to `nil` and should not be used.
*/
command_buffer_release_safe :: #force_inline proc(self: ^CommandBuffer) {
	if self != nil && self^ != nil {
		wgpuCommandBufferRelease(self^)
		self^ = nil
	}
}
