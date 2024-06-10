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
	ptr:       Raw_Buffer,
	size:      Buffer_Size,
	usage:     Buffer_Usage_Flags,
	_err_data: ^Error_Data,
}

// Return the binding view of the entire buffer with the current size.
buffer_as_entire_binding :: proc(using self: ^Buffer) -> Buffer_Binding {
	return {buffer = ptr, offset = 0, size = size}
}

// Destroys the `Buffer` from the GPU side.
buffer_destroy :: proc(using self: ^Buffer) {
	wgpu.buffer_destroy(ptr)
}

// Returns a `slice` of `T` with the contents of the `Buffer` in the given mapped
// range. Cannot modify the buffer's data.
buffer_get_const_mapped_range :: proc(
	self: ^Buffer,
	$T: typeid,
	offset: uint = 0,
	size: uint = WHOLE_MAP_SIZE,
	loc := #caller_location,
) -> (
	data: []T,
	err: Error,
) {
	assert(offset % 8 == 0, "Offset must be a multiple of 8.")
	assert(size % 4 == 0, "Size must be a multiple of 4.")

	size := size

	if size == 0 {
		size = cast(uint)self.size
	}

	set_and_reset_err_data(self._err_data, loc)

	raw_data := wgpu.buffer_get_const_mapped_range(self.ptr, offset, size)

	if err = get_last_error(); err != nil do return

	if raw_data == nil do return

	data = slice.reinterpret([]T, slice.bytes_from_ptr(raw_data, cast(int)size))

	return
}

// Get current `Buffer_Map_State` state.
buffer_get_map_state :: proc(using self: ^Buffer) -> Buffer_Map_State {
	return wgpu.buffer_get_map_state(ptr)
}

// Returns a `slice` of `T` with the contents of the `Buffer` in the given mapped range.
buffer_get_mapped_range :: proc(
	self: ^Buffer,
	$T: typeid,
	offset: uint = 0,
	size: uint = WHOLE_MAP_SIZE,
	loc := #caller_location,
) -> (
	data: []T,
	err: Error,
) {
	assert(offset % 8 == 0, "Offset must be a multiple of 8.")
	assert(size % 4 == 0, "Size must be a multiple of 4.")

	size := size

	if size == 0 {
		size = cast(uint)self.size
	}

	set_and_reset_err_data(self._err_data, loc)

	raw_data := wgpu.buffer_get_mapped_range(self.ptr, offset, size)

	if err = get_last_error(); err != nil do return

	if raw_data == nil do return

	data = slice.reinterpret([]T, slice.bytes_from_ptr(raw_data, cast(int)size))

	return
}

// Returns the length of the buffer allocation in bytes.
buffer_get_size :: proc(using self: ^Buffer) -> u64 {
	return size
}

// Returns the allowed usages for this Buffer.
buffer_get_usage :: proc(using self: ^Buffer) -> Buffer_Usage_Flags {
	return usage
}

// Maps the given range of the buffer.
buffer_map_async :: proc(
	self: ^Buffer,
	mode: Map_Mode_Flags,
	callback: Buffer_Map_Callback,
	user_data: rawptr,
	offset: uint = 0,
	size: uint = 0,
	loc := #caller_location,
) -> (
	err: Error,
) {
	size := size
	if size == 0 {
		size = cast(uint)self.size
	}

	set_and_reset_err_data(self._err_data, loc)
	wgpu.buffer_map_async(self.ptr, mode, offset, size, callback, user_data)
	err = get_last_error()

	return
}

// Set debug label.
buffer_set_label :: proc(using self: ^Buffer, label: cstring) {
	wgpu.buffer_set_label(ptr, label)
}

// Unmaps the mapped range of the `Buffer` and makes it's contents available for use
// by the GPU again.
buffer_unmap :: proc(using self: ^Buffer, loc := #caller_location) -> (err: Error) {
	set_and_reset_err_data(_err_data, loc)
	wgpu.buffer_unmap(ptr)
	err = get_last_error()

	return
}

// Increase the reference count.
buffer_reference :: proc(using self: ^Buffer) {
	wgpu.buffer_reference(ptr)
}

// Release the `Buffer`.
buffer_release :: proc(using self: ^Buffer) {
	wgpu.buffer_release(ptr)
}

// Release the `Buffer` and modify the raw pointer to `nil`.
buffer_release_and_nil :: proc(using self: ^Buffer) {
	if ptr == nil do return
	wgpu.buffer_release(ptr)
	ptr = nil
}
