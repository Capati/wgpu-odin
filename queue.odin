package webgpu

// Vendor
import "vendor:wgpu"

/*
Handle to a command queue on a device.

A `Queue` executes recorded `CommandBuffer` objects and provides convenience
methods for writing to `QueueWriteBuffer` and `QueueWriteTexture`.

It can be created by calling `DeviceGetQueue`.

Corresponds to [WebGPU `GPUQueue`](https://gpuweb.github.io/gpuweb/#gpu-queue).
*/
Queue :: wgpu.Queue

/*
Schedule a data write into `buffer` starting at `offset`.

This procedure fails if `data` overruns the size of `buffer` starting at `offset`.

This does *not* submit the transfer to the GPU immediately. Calls to
`QueueWriteBuffer` begin execution only on the next call to `QueueSubmit`. To
get a set of scheduled transfers started immediately, it's fine to call
`QueueSubmit` with no command buffers at all.

However, `data` will be immediately copied into staging memory, so the caller
may discard it any time after this call completes.
*/
QueueWriteBuffer :: proc "c" (
	self: Queue,
	buffer: Buffer,
	offset: BufferAddress,
	data: []byte,
) {
	wgpu.QueueWriteBuffer(
		self,
		buffer,
		offset,
		raw_data(data),
		uint(AlignSize(len(data), COPY_BUFFER_ALIGNMENT)),
	)
}

/*
Schedule a write of some data into a texture.

- `data` contains the texels to be written, which must be in the same format as
  the texture.
- `dataLayout` describes the memory layout of data, which does not necessarily
  have to have tightly packed rows.
- `texture` specifies the texture to write into, and the location within the
  texture (coordinate offset, mip level) that will be overwritten.
- `size` is the size, in texels, of the region to be written.

This procedure is intended to have low performance costs. As such, the write is
not immediately submitted, and instead enqueued internally to happen at the
start of the next `QueueSubmit` call. However, `data` will be immediately copied
into staging memory; so the caller may discard it any time after this call
completes.

This procedure fails if `size` overruns the size of `texture`, or if `data` is
too short.
*/
QueueWriteTexture :: proc "c" (
	self: Queue,
	destination: TexelCopyTextureInfo,
	data: []byte,
	dataLayout: TexelCopyBufferLayout,
	size: Extent3D,
) {
	destination := destination
	dataLayout := dataLayout
	size := size
	if len(data) == 0 {
		wgpu.QueueWriteTexture(self, &destination, nil, 0, &dataLayout, &size)
	} else {
		wgpu.QueueWriteTexture(
			self,
			&destination,
			raw_data(data),
			uint(len(data)),
			&dataLayout,
			&size,
		)
	}
}

/*
On native backends, block until the given submission has completed execution,
and any callbacks have been invoked.

On WebGPU, this has no effect. Callbacks are invoked from the window event loop.
*/
SubmissionIndex :: wgpu.SubmissionIndex

/* Submits a series of finished command buffers for execution. */
QueueSubmit :: proc "c" (
	self: Queue,
	commands: []CommandBuffer,
) -> (
	index: SubmissionIndex,
) {
	when ODIN_OS != .JS {
		index = wgpu.QueueSubmitForIndex(self, commands)
	} else {
		wgpu.QueueSubmit(self, commands)
	}
	return
}

/*
Registers a callback when the previous call to submit finishes running on the
gpu. This callback being called implies that all mapped buffer callbacks which
were registered before this call will have been called.

For the callback to complete, either `QueueSubmit` or `DevicePoll` must be
called elsewhere in the runtime, possibly integrated into an event loop or run
on a separate thread.

The callback will be called on the thread that first calls the above functions
after the gpu work has completed. There are no restrictions on the code you can
run in the callback, however on native the call to the function will not
complete until the callback returns, so prefer keeping callbacks short and used
to set flags, send messages, etc.
*/
QueueOnSubmittedWorkDone :: proc "c" (
	self: Queue,
	callbackInfo: QueueWorkDoneCallbackInfo,
) -> Future {
	return wgpu.QueueOnSubmittedWorkDone(self, callbackInfo)
}

/* Sets a debug label for the given `Queue`. */
QueueSetLabel :: wgpu.QueueSetLabel

/* Increase the `Queue` reference count. */
QueueAddRef :: #force_inline proc "c" (self: Queue) {
	wgpu.QueueAddRef(self)
}

/* Release the `Queue` resources, use to decrease the reference count. */
QueueRelease :: #force_inline proc "c" (self: Queue) {
	wgpu.QueueRelease(self)
}

/*
Safely releases the `Queue` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
QueueReleaseSafe :: proc "c" (self: ^Queue) {
	if self != nil && self^ != nil {
		wgpu.QueueRelease(self^)
		self^ = nil
	}
}
