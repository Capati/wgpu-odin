package wgpu

// The raw bindings
import wgpu "../bindings"

/*
Handle to a command queue on a device.

A `Queue` executes recorded `Command_Buffer` objects and provides convenience methods
for writing to `queue_write_buffer` and `queue_write_texture`.

It can be created by calling `device_get_queue`.

Corresponds to [WebGPU `GPUQueue`](https://gpuweb.github.io/gpuweb/#gpu-queue).
*/
Queue :: wgpu.Queue

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
	callback: Queue_Work_Done_Callback,
	data: rawptr = nil,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	_error_reset_data(loc)
	wgpu.queue_on_submitted_work_done(self, callback, data)
	return get_last_error() == nil
}

/* Set debug label. */
queue_set_label :: proc "contextless" (self: Queue, label: cstring) {
	wgpu.queue_set_label(self, label)
}

queue_submit_slice :: proc "contextless" (self: Queue, commands: ..Command_Buffer) {
	wgpu.queue_submit(self, uint(len(commands)), raw_data(commands))
}

queue_submit_empty :: proc "contextless" (self: Queue) {
	wgpu.queue_submit(self, 0, nil)
}

/* Submits a series of finished command buffers for execution. */
queue_submit :: proc {
	queue_submit_slice,
	queue_submit_empty,
}

queue_submit_for_index_slice :: proc "contextless" (
	self: Queue,
	commands: ..Command_Buffer,
) -> Submission_Index {
	return wgpu.queue_submit_for_index(self, uint(len(commands)), raw_data(commands))
}

queue_submit_for_index_empty :: proc "contextless" (self: Queue) -> Submission_Index {
	return wgpu.queue_submit_for_index(self, 0, nil)
}

queue_submit_for_index :: proc {
	queue_submit_for_index_slice,
	queue_submit_for_index_empty,
}

queue_write_buffer_bytes :: proc "contextless" (
	self: Queue,
	buffer: Buffer,
	offset: Buffer_Address,
	data: []byte,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	_error_reset_data(loc)

	if len(data) == 0 {
		wgpu.queue_write_buffer(self, buffer, offset, nil, 0)
	} else {
		wgpu.queue_write_buffer(self, buffer, offset, raw_data(data), uint(len(data)))
	}

	return get_last_error() == nil
}

queue_write_buffer_raw :: proc "contextless" (
	self: Queue,
	buffer: Buffer,
	offset: Buffer_Address,
	data: rawptr,
	size: uint,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	_error_reset_data(loc)

	if size == 0 {
		wgpu.queue_write_buffer(self, buffer, offset, nil, 0)
	} else {
		wgpu.queue_write_buffer(self, buffer, offset, data, size)
	}

	return get_last_error() == nil
}

/*
Schedule a data write into `buffer` starting at `offset`.

This method is intended to have low performance costs. As such, the write is not immediately
submitted, and instead enqueued internally to happen at the start of the next `queue_submit`
call.

This method fails if `data` overruns the size of `buffer` starting at `offset`.
*/
queue_write_buffer :: proc {
	queue_write_buffer_bytes,
	queue_write_buffer_raw,
}

/*
Schedule a write of some data into a texture.

- `data` contains the texels to be written, which must be in the same format as the texture.
- `data_layout` describes the memory layout of data, which does not necessarily have to have
tightly packed rows.
- `texture` specifies the texture to write into, and the location within the texture (coordinate
offset, mip level) that will be overwritten.
- `size` is the size, in texels, of the region to be written.

This method is intended to have low performance costs. As such, the write is not immediately
submitted, and instead enqueued internally to happen at the start of the next `queue_submit`
call. However, `data` will be immediately copied into staging memory; so the caller may discard
it any time after this call completes.

This method fails if `size` overruns the size of `texture`, or if `data` is too short.
*/
queue_write_texture :: proc "contextless" (
	self: Queue,
	texture: Image_Copy_Texture,
	data: []byte,
	data_layout: Texture_Data_Layout,
	size: Extent_3D,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	_error_reset_data(loc)

	texture, data_layout, size := texture, data_layout, size
	if len(data) == 0 {
		wgpu.queue_write_texture(self, &texture, nil, 0, &data_layout, &size)
	} else {
		wgpu.queue_write_texture(
			self,
			&texture,
			raw_data(data),
			uint(len(data)),
			&data_layout,
			&size,
		)
	}

	return get_last_error() == nil
}

queue_write_texture_raw :: proc "contextless" (
	self: Queue,
	texture: ^Image_Copy_Texture,
	data: rawptr,
	data_size: uint,
	data_layout: ^Texture_Data_Layout,
	size: ^Extent_3D,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	_error_reset_data(loc)
	wgpu.queue_write_texture(self, texture, data, data_size, data_layout, size)
	return get_last_error() == nil
}

/* Increase the reference count. */
queue_reference :: wgpu.queue_reference

/* Release the `Queue` resources. */
queue_release :: wgpu.queue_release
