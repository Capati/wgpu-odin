package wgpu

/*
Handle to a command buffer on the GPU.

A `CommandBuffer` represents a complete sequence of commands that may be submitted to a command
queue with `queue_submit`. A `CommandBuffer` is obtained by recording a series of commands to
a `CommandEncoder` and then calling `command_encoder_finish`.

Corresponds to [WebGPU `GPUCommandBuffer`](https://gpuweb.github.io/gpuweb/#command-buffer).
*/
CommandBuffer :: distinct rawptr

/* Set debug label. */
@(disabled = !ODIN_DEBUG)
command_buffer_set_label :: proc "contextless" (self: CommandBuffer, label: string) {
	c_label: StringViewBuffer
	wgpuCommandBufferSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the reference count. */
command_buffer_add_ref :: wgpuCommandBufferAddRef

/* Release the `CommandBuffer` resources. */
command_buffer_release :: wgpuCommandBufferRelease
