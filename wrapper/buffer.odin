package wgpu

// Core
import "core:mem"
import "core:slice"

// Package
import wgpu "../bindings"

// Handle to a GPU-accessible buffer.
//
// Created with `device_create_buffer` or `device_create_buffer_with_data`.
Buffer :: struct {
	_ptr:        WGPU_Buffer,
	_device_ptr: WGPU_Device,
	_err_data:   ^Error_Data,
	size:        Buffer_Size,
	map_state:   Buffer_Map_State,
	usage:       Buffer_Usage_Flags,
}

// Destroys the `Buffer`.
buffer_destroy :: proc(using self: ^Buffer) {
	wgpu.buffer_destroy(_ptr)
}

// Returns a `slice` of `T` with the contents of the `Buffer` in the given mapped
// range. Cannot modify the buffer's data.
buffer_get_const_mapped_range :: proc(
	self: ^Buffer,
	$T: typeid,
	offset: uint = 0,
	size: uint = 0,
) -> []T {
	size := size

	if size == 0 {
		size = cast(uint)self.size
	}

	raw_data := wgpu.buffer_get_const_mapped_range(self._ptr, offset, size)

	if raw_data == nil {
		return {}
	}

	return slice.reinterpret([]T, slice.bytes_from_ptr(raw_data, cast(int)size))
}

// Returns a `slice` of `T` with the contents of the `Buffer` in the given mapped range.
buffer_get_mapped_range :: proc(
	self: ^Buffer,
	$T: typeid,
	offset: uint = 0,
	size: uint = 0,
) -> []T {
	size := size

	if size == 0 {
		size = cast(uint)self.size
	}

	raw_data := wgpu.buffer_get_mapped_range(self._ptr, offset, size)

	if raw_data == nil {
		return {}
	}

	return slice.reinterpret([]T, slice.bytes_from_ptr(raw_data, cast(int)size))
}

// Get current `Buffer_Map_State` state.
buffer_get_map_state :: proc(using self: ^Buffer) -> Buffer_Map_State {
	return wgpu.buffer_get_map_state(_ptr)
}

// Returns the length of the buffer allocation in bytes.
buffer_get_size :: proc(using self: ^Buffer) -> u64 {
	return wgpu.buffer_get_size(_ptr)
}

// Returns the allowed usages for this Buffer.
buffer_get_usage :: proc(using self: ^Buffer) -> Buffer_Usage_Flags {
	return transmute(Buffer_Usage_Flags)wgpu.buffer_get_usage(_ptr)
}

Buffer_Map_Async_Response :: struct {
	status: Buffer_Map_Async_Status,
}

@(private)
_buffer_map_callback :: proc "c" (status: Buffer_Map_Async_Status, user_data: rawptr) {
	response := cast(^Buffer_Map_Async_Response)user_data
	response.status = status
}

buffer_map_read :: proc(
	self: ^Buffer,
	$T: typeid,
	offset: uint = 0,
	size: uint = 0,
) -> (
	data: []T,
	status: Buffer_Map_Async_Status,
) {
	self._err_data.type = .No_Error

	self.map_state = .Pending

	res := Buffer_Map_Async_Response {
		status = .Unknown,
	}

	size := size
	if size == 0 {
		size = cast(uint)self.size
	}

	wgpu.buffer_map_async(self._ptr, {.Read}, offset, size, _buffer_map_callback, &res)

	if self._err_data.type != .No_Error {
		return {}, .Validation_Error
	}

	wgpu.device_poll(self._device_ptr, true, nil)

	status = res.status

	if status != .Success {
		update_error_message("Could not read buffer data")
		return {}, status
	}

	self.map_state = .Mapped

	data = buffer_get_mapped_range(self, T, offset, size)

	if buffer_unmap(self) != .No_Error {
		return {}, .Error
	}

	return
}

buffer_map_write :: proc(
	self: ^Buffer,
	data: []byte,
	offset: uint = 0,
	size: uint = 0,
) -> Buffer_Map_Async_Status {
	self._err_data.type = .No_Error

	self.map_state = .Pending

	res := Buffer_Map_Async_Response {
		status = .Unknown,
	}

	size := size
	if size == 0 {
		size = cast(uint)self.size
	}

	wgpu.buffer_map_async(self._ptr, {.Write}, offset, size, _buffer_map_callback, &res)

	if self._err_data.type != .No_Error {
		return .Validation_Error
	}

	wgpu.device_poll(self._device_ptr, true, nil)

	if res.status != .Success {
		update_error_message("Could not write buffer data")
		return res.status
	}

	self.map_state = .Mapped

	src_ptr := wgpu.buffer_get_mapped_range(self._ptr, offset, size)
	mem.copy(src_ptr, raw_data(data), cast(int)size)

	if buffer_unmap(self) != .No_Error {
		return .Error
	}

	return .Success
}

// Maps the given range of the buffer.
buffer_map_async :: proc(
	self: ^Buffer,
	mode: Map_Mode_Flags,
	callback: Buffer_Map_Callback,
	user_data: rawptr,
	offset: uint = 0,
	size: uint = 0,
) -> Error_Type {
	size := size
	if size == 0 {
		size = cast(uint)self.size
	}

	self._err_data.type = .No_Error
	wgpu.buffer_map_async(self._ptr, mode, offset, size, callback, user_data)

	return self._err_data.type
}

// Set debug label.
buffer_set_label :: proc(using self: ^Buffer, label: cstring) {
	wgpu.buffer_set_label(_ptr, label)
}

// Unmaps the mapped range of the `Buffer` and makes it's contents available for use
// by the GPU again.
buffer_unmap :: proc(using self: ^Buffer) -> Error_Type {
	_err_data.type = .No_Error

	wgpu.buffer_unmap(_ptr)

	map_state = .Unmapped

	return _err_data.type
}

// Increase the reference count.
buffer_reference :: proc(using self: ^Buffer) {
	wgpu.buffer_reference(_ptr)
}

// Release the `Buffer`.
buffer_release :: proc(using self: ^Buffer) {
	wgpu.device_release(_device_ptr)
	wgpu.buffer_release(_ptr)
}
