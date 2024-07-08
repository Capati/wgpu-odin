package wgpu

// Base
import intr "base:intrinsics"

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
buffer_as_entire_binding :: proc "contextless" (using self: Buffer) -> Buffer_Binding {
	return {buffer = ptr, offset = 0, size = size}
}

// Destroys the `Buffer` from the GPU side.
buffer_destroy :: proc "contextless" (using self: Buffer) {
	wgpu.buffer_destroy(ptr)
}

Buffer_Range :: struct {
	offset: Buffer_Address,
	size:   Buffer_Size,
}

buffer_range_default :: #force_inline proc "contextless" (using self: Buffer) -> Buffer_Range {
	return {0, size}
}

buffer_range_from_offset :: #force_inline proc "contextless" (
	using self: Buffer,
	offset: Buffer_Address,
) -> Buffer_Range {
	return {offset, size}
}

buffer_range_from_range :: #force_inline proc "contextless" (
	using self: Buffer,
	bounds: Range(Buffer_Address) = {},
) -> Buffer_Range {
	return {bounds.start, bounds.end if bounds.end > 0 else size}
}

buffer_range :: proc {
	buffer_range_default,
	buffer_range_from_offset,
	buffer_range_from_range,
}

@(private = "file")
_buffer_get_mapped_range_bytes :: proc "contextless" (
	using self: Buffer,
	is_const: bool,
	range: Buffer_Range = {},
	loc := #caller_location,
) -> (
	data: []byte,
	err: Error,
) {
	range := range if range != {} else buffer_range_default(self)
	end := uint(range.size - range.offset)

	set_and_reset_err_data(_err_data, loc)
	raw_data :=
		is_const \
		? wgpu.buffer_get_const_mapped_range(ptr, uint(range.offset), end) \
		: wgpu.buffer_get_mapped_range(ptr, uint(range.offset), end)
	if err = get_last_error(); err != nil do return

	if raw_data == nil {
		err = .Nil_Data
		return
	}

	data = ([^]byte)(raw_data)[:end]

	return
}

@(private = "file")
_buffer_get_mapped_range_typed :: proc "contextless" (
	self: Buffer,
	is_const: bool,
	$T: typeid,
	range: Buffer_Range = {},
	loc := #caller_location,
) -> (
	data: ^T,
	err: Error,
) where !intr.type_is_sliceable(T) {
	size := range.size if range.size > 0 else size_of(T)

	set_and_reset_err_data(_err_data, loc)
	raw_data :=
		is_const \
		? wgpu.buffer_get_const_mapped_range(self.ptr, uint(range.offset), size) \
		: wgpu.buffer_get_mapped_range(self.ptr, uint(range.offset), size)
	if err = get_last_error(); err != nil do return

	if raw_data == nil {
		err = .Nil_Data
		return
	}

	data = (^T)(raw_data)

	return
}

@(private = "file")
_buffer_get_mapped_range_sliced :: proc "contextless" (
	using self: Buffer,
	is_const: bool,
	$T: typeid/[]$U,
	range: Buffer_Range = {},
	loc := #caller_location,
) -> (
	data: []U,
	err: Error,
) where intr.type_is_sliceable(T) {
	range := range if range != {} else buffer_range_default(self)
	length := uint(range.size - range.offset)

	set_and_reset_err_data(_err_data, loc)
	raw_data :=
		is_const \
		? wgpu.buffer_get_const_mapped_range(self.ptr, uint(range.offset), length) \
		: wgpu.buffer_get_mapped_range(self.ptr, uint(range.offset), length)
	if err = get_last_error(); err != nil do return

	if raw_data == nil {
		err = .Nil_Data
		return
	}

	data = ([^]U)(raw_data)[:length]

	return
}

buffer_get_const_mapped_range_bytes :: proc "contextless" (
	using self: Buffer,
	range: Buffer_Range = {},
	loc := #caller_location,
) -> (
	data: []byte,
	err: Error,
) {
	return _buffer_get_mapped_range_bytes(self, true, range, loc)
}

buffer_get_const_mapped_range_typed :: proc "contextless" (
	self: Buffer,
	$T: typeid,
	range: Buffer_Range = {},
	loc := #caller_location,
) -> (
	data: ^T,
	err: Error,
) where !intr.type_is_sliceable(T) {
	return _buffer_get_mapped_range_typed(self, true, T, range, loc)
}

buffer_get_const_mapped_range_sliced :: proc "contextless" (
	using self: Buffer,
	$T: typeid/[]$U,
	range: Buffer_Range = {},
	loc := #caller_location,
) -> (
	data: []U,
	err: Error,
) where intr.type_is_sliceable(T) {
	return _buffer_get_mapped_range_sliced(self, true, T, range, loc)
}

buffer_get_const_mapped_range :: proc {
	buffer_get_const_mapped_range_bytes,
	buffer_get_const_mapped_range_typed,
	buffer_get_const_mapped_range_sliced,
}

buffer_get_mapped_range_bytes :: proc "contextless" (
	using self: Buffer,
	range: Buffer_Range = {},
	loc := #caller_location,
) -> (
	data: []byte,
	err: Error,
) {
	return _buffer_get_mapped_range_bytes(self, false, range, loc)
}

buffer_get_mapped_range_typed :: proc "contextless" (
	self: Buffer,
	$T: typeid,
	range: Buffer_Range = {},
	loc := #caller_location,
) -> (
	data: ^T,
	err: Error,
) where !intr.type_is_sliceable(T) {
	return _buffer_get_mapped_range_typed(self, false, T, range, loc)
}

buffer_get_mapped_range_sliced :: proc "contextless" (
	using self: Buffer,
	$T: typeid/[]$U,
	range: Buffer_Range = {},
	loc := #caller_location,
) -> (
	data: []U,
	err: Error,
) where intr.type_is_sliceable(T) {
	return _buffer_get_mapped_range_sliced(self, false, T, range, loc)
}

buffer_get_mapped_range :: proc {
	buffer_get_mapped_range_bytes,
	buffer_get_mapped_range_typed,
	buffer_get_mapped_range_sliced,
}

// Get current `Buffer_Map_State` state.
buffer_get_map_state :: proc "contextless" (using self: Buffer) -> Buffer_Map_State {
	return wgpu.buffer_get_map_state(ptr)
}

// Returns the length of the buffer allocation in bytes.
buffer_get_size :: proc "contextless" (using self: Buffer) -> u64 {
	return size
}

// Returns the allowed usages for this Buffer.
buffer_get_usage :: proc "contextless" (using self: Buffer) -> Buffer_Usage_Flags {
	return usage
}

// Maps the given range of the buffer.
buffer_map_async :: proc "contextless" (
	using self: Buffer,
	mode: Map_Mode_Flags,
	callback: Buffer_Map_Callback,
	user_data: rawptr = nil,
	range: Buffer_Range = {},
	loc := #caller_location,
) -> (
	err: Error,
) {
	set_and_reset_err_data(self._err_data, loc)
	wgpu.buffer_map_async(
		self.ptr,
		mode,
		uint(range.offset),
		uint(range.size) if range.size > 0 else uint(size),
		callback,
		user_data,
	)
	err = get_last_error()

	return
}

// Set debug label.
buffer_set_label :: proc "contextless" (using self: Buffer, label: cstring) {
	wgpu.buffer_set_label(ptr, label)
}

// Unmaps the mapped range of the `Buffer` and makes it's contents available for use
// by the GPU again.
buffer_unmap :: proc "contextless" (using self: Buffer, loc := #caller_location) -> (err: Error) {
	set_and_reset_err_data(_err_data, loc)
	wgpu.buffer_unmap(ptr)
	err = get_last_error()

	return
}

// Increase the reference count.
buffer_reference :: proc "contextless" (using self: Buffer) {
	wgpu.buffer_reference(ptr)
}

// Release the `Buffer`.
buffer_release :: #force_inline proc "contextless" (using self: Buffer) {
	wgpu.buffer_release(ptr)
}

// Release the `Buffer` and modify the raw pointer to `nil`.
buffer_release_and_nil :: proc "contextless" (using self: ^Buffer) {
	if ptr == nil do return
	wgpu.buffer_release(ptr)
	ptr = nil
}
