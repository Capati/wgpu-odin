package wgpu

// Core
import "core:runtime"

// Package
import wgpu "../bindings"

// Handle to a command queue on a device.
//
// A `Queue` executes recorded `Command_Buffer` objects and provides convenience methods for
// writing to buffers and textures. It can be created along with a `Device` by calling
// `adapter_request_device`.
Queue :: struct {
	ptr:       Raw_Queue,
	_err_data: ^Error_Data,
}

// Registers a callback when the previous call to submit finishes running on the gpu. This callback
// being called implies that all mapped buffer callbacks which were registered before this call
// will have been called.
//
// For the callback to complete, either `queue.submit` or `device.poll` must be called elsewhere in
// the runtime, possibly integrated into an event loop or run on a separate thread.
//
// The callback will be called on the thread that first calls the above functions after the gpu
// work has completed. There are no restrictions on the code you can run in the callback, however
// on native the call to the function will not complete until the callback returns, so prefer
// keeping callbacks short and used to set flags, send messages, etc.
queue_on_submitted_work_done :: proc(
	using self: ^Queue,
	callback: Queue_Work_Done_Callback,
	data: rawptr = nil,
) {
	wgpu.queue_on_submitted_work_done(ptr, callback, data)
}

// Set debug label.
queue_set_label :: proc(using self: ^Queue, label: cstring) {
	wgpu.queue_set_label(ptr, label)
}

queue_submit_raw :: proc(using self: ^Queue, command_count: uint, commands: ^Raw_Command_Buffer) {
	wgpu.queue_submit(ptr, command_count, commands)
}

queue_submit_slice :: proc(using self: ^Queue, commands: ..Raw_Command_Buffer) {
	wgpu.queue_submit(ptr, cast(uint)len(commands), raw_data(commands))
}

queue_submit_single :: proc(using self: ^Queue, command: ^Raw_Command_Buffer) {
	wgpu.queue_submit(ptr, 1, command)
}

queue_submit_empty :: proc(using self: ^Queue) {
	wgpu.queue_submit(ptr, 0, nil)
}

// Submits a series of finished command buffers for execution.
queue_submit :: proc {
	queue_submit_raw,
	queue_submit_slice,
	queue_submit_single,
	queue_submit_empty,
}

queue_submit_for_index_raw :: proc(
	using self: ^Queue,
	command_count: uint,
	commands: ^Raw_Command_Buffer,
) -> Submission_Index {
	return wgpu.queue_submit_for_index(ptr, command_count, commands)
}

queue_submit_for_index_slice :: proc(
	using self: ^Queue,
	commands: ..Raw_Command_Buffer,
) -> Submission_Index {
	return wgpu.queue_submit_for_index(ptr, cast(uint)len(commands), raw_data(commands))
}

queue_submit_for_index_single :: proc(
	using self: ^Queue,
	command: ^Raw_Command_Buffer,
) -> Submission_Index {
	return wgpu.queue_submit_for_index(ptr, 1, command)
}

queue_submit_for_index_empty :: proc(using self: ^Queue) -> Submission_Index {
	return wgpu.queue_submit_for_index(ptr, 0, nil)
}

queue_submit_for_index :: proc {
	queue_submit_for_index_raw,
	queue_submit_for_index_slice,
	queue_submit_for_index_single,
	queue_submit_for_index_empty,
}

// Schedule a data write into `buffer` starting at `offset`.
//
// This method is intended to have low performance costs. As such, the write is not immediately
// submitted, and instead enqueued internally to happen at the start of the next `queue_submit`
// call.
//
// This method fails if `data` overruns the size of `buffer` starting at `offset`.
queue_write_buffer :: proc(
	using self: ^Queue,
	buffer: Raw_Buffer,
	offset: Buffer_Address,
	data: []byte,
) -> (
	err: Error_Type,
) {
	_err_data.type = .No_Error

	if len(data) == 0 {
		wgpu.queue_write_buffer(ptr, buffer, offset, nil, 0)
	} else {
		wgpu.queue_write_buffer(ptr, buffer, offset, raw_data(data), cast(uint)len(data))
	}

	return _err_data.type
}

// Schedule a write of some data into a texture.
//
// - `data` contains the texels to be written, which must be in the same format as the texture.
// - `data_layout` describes the memory layout of data, which does not necessarily have to have
// tightly packed rows.
// - `texture` specifies the texture to write into, and the location within the texture (coordinate
// offset, mip level) that will be overwritten.
// - `size` is the size, in texels, of the region to be written.
//
// This method is intended to have low performance costs. As such, the write is not immediately
// submitted, and instead enqueued internally to happen at the start of the next `queue_submit`
// call. However, `data` will be immediately copied into staging memory; so the caller may discard
// it any time after this call completes.
//
// This method fails if `size` overruns the size of `texture`, or if `data` is too short.
queue_write_texture :: proc(
	using self: ^Queue,
	texture: ^Image_Copy_Texture,
	data: []byte,
	data_layout: ^Texture_Data_Layout,
	size: ^Extent_3D,
) -> (
	err: Error_Type,
) {
	_err_data.type = .No_Error

	if len(data) == 0 {
		wgpu.queue_write_texture(ptr, texture, nil, 0, data_layout, size)
	} else {
		wgpu.queue_write_texture(
			ptr,
			texture,
			raw_data(data),
			cast(uint)len(data),
			data_layout,
			size,
		)
	}

	return _err_data.type
}

// Increase the reference count.
queue_reference :: proc(using self: ^Queue) {
	wgpu.queue_reference(ptr)
}

// Release the `Queue`.
queue_release :: proc(using self: ^Queue) {
	if ptr == nil do return
	wgpu.queue_release(ptr)
	ptr = nil
}
