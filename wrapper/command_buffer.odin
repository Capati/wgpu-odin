package wgpu

// The raw bindings
import wgpu "../bindings"

/*
Handle to a command buffer on the GPU.

A `Command_Buffer` represents a complete sequence of commands that may be submitted to a command
queue with `queue_submit`. A `Command_Buffer` is obtained by recording a series of commands to
a `Command_Encoder` and then calling `command_encoder_finish`.

Corresponds to [WebGPU `GPUCommandBuffer`](https://gpuweb.github.io/gpuweb/#command-buffer).
*/
Command_Buffer :: wgpu.Command_Buffer

/* Set debug label. */
command_buffer_set_label :: wgpu.command_buffer_set_label

/* Increase the reference count. */
command_buffer_reference :: wgpu.command_buffer_reference

/* Release the `Command_Buffer` resources. */
command_buffer_release :: wgpu.command_buffer_release
