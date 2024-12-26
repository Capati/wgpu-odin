package wgpu

/*
Handle to a command queue on a device.

A `Queue` executes recorded `CommandBuffer` objects and provides convenience methods
for writing to `queue_write_buffer` and `queue_write_texture`.

It can be created by calling `device_get_queue`.

Corresponds to [WebGPU `GPUQueue`](https://gpuweb.github.io/gpuweb/#gpu-queue).
*/
Queue :: distinct rawptr

/*
Schedule a data write into `buffer` starting at `offset`.

This procedure fails if `data` overruns the size of `buffer` starting at `offset`.

This does *not* submit the transfer to the GPU immediately. Calls to
`queue_write_buffer` begin execution only on the next call to
`queue_submit`. To get a set of scheduled transfers started
immediately, it's fine to call `queue_submit` with no command buffers at all.

However, `data` will be immediately copied into staging memory, so the
caller may discard it any time after this call completes.
*/
queue_write_buffer :: proc "contextless" (
	self: Queue,
	buffer: Buffer,
	offset: BufferAddress,
	data: []byte,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	error_reset_data(loc)
	wgpuQueueWriteBuffer(self, buffer, offset, raw_data(data), uint(len(data)))
	return has_no_error()
}

/*
Schedule a write of some data into a texture.

- `data` contains the texels to be written, which must be in the same format as the texture.
- `data_layout` describes the memory layout of data, which does not necessarily have to have
tightly packed rows.
- `texture` specifies the texture to write into, and the location within the texture (coordinate
offset, mip level) that will be overwritten.
- `size` is the size, in texels, of the region to be written.

This procedure is intended to have low performance costs. As such, the write is not immediately
submitted, and instead enqueued internally to happen at the start of the next `queue_submit`
call. However, `data` will be immediately copied into staging memory; so the caller may discard
it any time after this call completes.

This procedure fails if `size` overruns the size of `texture`, or if `data` is too short.
*/
queue_write_texture :: proc "contextless" (
	self: Queue,
	destination: TexelCopyTextureInfo,
	data: []byte,
	data_layout: TexelCopyBufferLayout,
	size: Extent3D,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	error_reset_data(loc)
	if len(data) == 0 {
		wgpuQueueWriteTexture(self, destination, nil, 0, data_layout, size)
	} else {
		wgpuQueueWriteTexture(
			self,
			destination,
			raw_data(data),
			uint(len(data)),
			data_layout,
			size,
		)
	}
	return has_no_error()
}

/*
On native backends, block until the given submission has completed execution, and any
callbacks have been invoked.

On WebGPU, this has no effect. Callbacks are invoked from the window event loop.
*/
SubmissionIndex :: distinct u64

/* Submits a series of finished command buffers for execution. */
queue_submit :: proc "contextless" (
	self: Queue,
	commands: ..CommandBuffer,
) -> (
	index: SubmissionIndex,
) {
	when ODIN_OS != .JS {
		index = wgpuQueueSubmitForIndex(self, uint(len(commands)), raw_data(commands))
	} else {
		wgpuQueueSubmit(self, uint(len(commands)), raw_data(commands))
	}
	return
}

/*
Registers a callback when the previous call to submit finishes running on the gpu. This callback
being called implies that all mapped buffer callbacks which were registered before this call
will have been called.

For the callback to complete, either `queue.submit` or `device.poll` must be called elsewhere in
the runtime, possibly integrated into an event loop or run on a separate thread.

The callback will be called on the thread that first calls the above functions after the gpu
work has completed. There are no restrictions on the code you can run in the callback, however
on native the call to the function will not complete until the callback returns, so prefer
keeping callbacks short and used to set flags, send messages, etc.
*/
queue_on_submitted_work_done :: proc "contextless" (
	self: Queue,
	callback_info: QueueWorkDoneCallbackInfo,
	loc := #caller_location,
) -> (
	future: Future,
	ok: bool,
) {
	error_reset_data(loc)
	future = wgpuQueueOnSubmittedWorkDone(self, callback_info)
	return future, has_no_error()
}

/* Sets a debug label for the given `Queue`. */
@(disabled = !ODIN_DEBUG)
queue_set_label :: proc "contextless" (self: Queue, label: string) {
	c_label: StringViewBuffer
	wgpuQueueSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the `Queue` reference count. */
queue_add_ref :: wgpuQueueAddRef

/* Release the `Queue` resources, use to decrease the reference count. */
queue_release :: wgpuQueueRelease
