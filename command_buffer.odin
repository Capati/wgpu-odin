package webgpu

// Vendor
import "vendor:wgpu"

/*
Handle to a command buffer on the GPU.

A `CommandBuffer` represents a complete sequence of commands that may be
submitted to a command queue with `QueueSubmit`. A `CommandBuffer` is obtained
by recording a series of commands to a `CommandEncoder` and then calling
`CommandEncoderFinish`.

Corresponds to [WebGPU
`GPUCommandBuffer`](https://gpuweb.github.io/gpuweb/#command-buffer).
*/
CommandBuffer :: wgpu.CommandBuffer

/* Sets a debug label for the given `CommandBuffer`. */
CommandBufferSetLabel :: #force_inline proc "c" (self: CommandBuffer, label: string) {
	wgpu.CommandBufferSetLabel(self, label)
}

/* Increase the `CommandBuffer` reference count. */
CommandBufferAddRef :: #force_inline proc "c" (self: CommandBuffer) {
	wgpu.CommandBufferAddRef(self)
}

/* Release the `CommandBuffer` resources, use to decrease the reference count. */
CommandBufferRelease :: #force_inline proc "c" (self: CommandBuffer) {
	wgpu.CommandBufferRelease(self)
}

/*
Safely releases the `CommandBuffer` resources and invalidates the handle. The
procedure checks both the pointer validity and Command buffer handle before releasing.

Note: After calling this, Command buffer handle will be set to `nil` and should not be used.
*/
CommandBufferReleaseSafe :: proc "c" (self: ^CommandBuffer) {
	if self != nil && self^ != nil {
		wgpu.CommandBufferRelease(self^)
		self^ = nil
	}
}
