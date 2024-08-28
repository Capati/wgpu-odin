package wgpu

// STD Library
import intr "base:intrinsics"

// The raw bindings
import wgpu "../bindings"

/*
Handle to a GPU-accessible buffer.

Created with `device_create_buffer` or `device_create_buffer_with_data`.

Corresponds to [WebGPU `GPUBuffer`](https://gpuweb.github.io/gpuweb/#buffer-interface)..
*/
Buffer :: wgpu.Buffer

/* Return the binding view of the entire buffer with the current size. */
buffer_as_entire_binding :: proc "contextless" (self: Buffer) -> Buffer_Binding {
	size := buffer_get_size(self)
	return {buffer = self, offset = 0, size = size}
}

/* Destroy the associated native resources as soon as possible. */
buffer_destroy :: proc "contextless" (self: Buffer) {
	wgpu.buffer_destroy(self)
}

Buffer_Range :: struct {
	offset : Buffer_Address,
	size   : Buffer_Size,
}

buffer_range_default :: #force_inline proc "contextless" (self: Buffer) -> Buffer_Range {
	size := buffer_get_size(self)
	return {0, size}
}

buffer_range_from_offset :: #force_inline proc "contextless" (
	self: Buffer,
	offset: Buffer_Address,
) -> Buffer_Range {
	size := buffer_get_size(self)
	return {offset, size}
}

buffer_range_from_range :: #force_inline proc "contextless" (
	self: Buffer,
	bounds: Range(Buffer_Address) = {},
) -> Buffer_Range {
	size := buffer_get_size(self)
	return {bounds.start, bounds.end if bounds.end > 0 else size}
}

buffer_range :: proc {
	buffer_range_default,
	buffer_range_from_offset,
	buffer_range_from_range,
}

@(private = "file")
_buffer_get_mapped_range_bytes :: proc "contextless" (
	self: Buffer,
	is_const: bool,
	range: Buffer_Range = {},
	loc := #caller_location,
) -> (
	data: []byte,
	ok: bool,
) {
	range := range if range != {} else buffer_range_default(self)
	end := uint(range.size - range.offset)

	_error_reset_data(loc)

	raw_data :=
		is_const \
		? wgpu.buffer_get_const_mapped_range(self, uint(range.offset), end) \
		: wgpu.buffer_get_mapped_range(self, uint(range.offset), end)

	if get_last_error() != nil do return

	if raw_data == nil {
		return {}, true
	}

	when ODIN_DEBUG {
		data = ([^]byte)(raw_data)[:end]
	} else {
		#no_bounds_check data = ([^]byte)(raw_data)[:end]
	}

	return data, true
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
	ok: bool,
) where !intr.type_is_sliceable(T) {
	size := range.size if range.size > 0 else size_of(T)

	_error_reset_data(loc)
	raw_data :=
		is_const \
		? wgpu.buffer_get_const_mapped_range(self, uint(range.offset), size) \
		: wgpu.buffer_get_mapped_range(self, uint(range.offset), size)

	if get_last_error() != nil do return

	if raw_data == nil {
		return {}, true
	}

	data = (^T)(raw_data)

	return data, true
}

@(private = "file")
_buffer_get_mapped_range_sliced :: proc "contextless" (
	self: Buffer,
	is_const: bool,
	$T: typeid/[]$U,
	range: Buffer_Range = {},
	loc := #caller_location,
) -> (
	data: []U,
	ok: bool,
) where intr.type_is_sliceable(T) {
	range := range if range != {} else buffer_range_default(self)
	length := uint(range.size - range.offset)

	_error_reset_data(loc)

	raw_data :=
		is_const \
		? wgpu.buffer_get_const_mapped_range(self, uint(range.offset), length) \
		: wgpu.buffer_get_mapped_range(self, uint(range.offset), length)

	if get_last_error() != nil do return

	if raw_data == nil {
		return {}, true
	}

	when ODIN_DEBUG {
		data = ([^]U)(raw_data)[:length]
	} else {
		#no_bounds_check data = ([^]U)(raw_data)[:length]
	}

	return data, true
}

buffer_get_const_mapped_range_bytes :: proc "contextless" (
	self: Buffer,
	range: Buffer_Range = {},
	loc := #caller_location,
) -> (
	data: []byte,
	ok: bool,
) #optional_ok {
	return _buffer_get_mapped_range_bytes(self, true, range, loc)
}

buffer_get_const_mapped_range_typed :: proc "contextless" (
	self: Buffer,
	$T: typeid,
	range: Buffer_Range = {},
	loc := #caller_location,
) -> (
	data: ^T,
	ok: bool,
) where !intr.type_is_sliceable(T) #optional_ok {
	return _buffer_get_mapped_range_typed(self, true, T, range, loc)
}

buffer_get_const_mapped_range_sliced :: proc "contextless" (
	self: Buffer,
	$T: typeid/[]$U,
	range: Buffer_Range = {},
	loc := #caller_location,
) -> (
	data: []U,
	ok: bool,
) where intr.type_is_sliceable(T) #optional_ok {
	return _buffer_get_mapped_range_sliced(self, true, T, range, loc)
}

buffer_get_const_mapped_range :: proc {
	buffer_get_const_mapped_range_bytes,
	buffer_get_const_mapped_range_typed,
	buffer_get_const_mapped_range_sliced,
}

buffer_get_mapped_range_bytes :: proc "contextless" (
	self: Buffer,
	range: Buffer_Range = {},
	loc := #caller_location,
) -> (
	data: []byte,
	ok: bool,
) #optional_ok {
	return _buffer_get_mapped_range_bytes(self, false, range, loc)
}

buffer_get_mapped_range_typed :: proc "contextless" (
	self: Buffer,
	$T: typeid,
	range: Buffer_Range = {},
	loc := #caller_location,
) -> (
	data: ^T,
	ok: bool,
) where !intr.type_is_sliceable(T) #optional_ok {
	return _buffer_get_mapped_range_typed(self, false, T, range, loc)
}

buffer_get_mapped_range_sliced :: proc "contextless" (
	self: Buffer,
	$T: typeid/[]$U,
	range: Buffer_Range = {},
	loc := #caller_location,
) -> (
	data: []U,
	ok: bool,
) where intr.type_is_sliceable(T) #optional_ok {
	return _buffer_get_mapped_range_sliced(self, false, T, range, loc)
}

buffer_get_mapped_range :: proc {
	buffer_get_mapped_range_bytes,
	buffer_get_mapped_range_typed,
	buffer_get_mapped_range_sliced,
}

/* Get current `Buffer_Map_State` state. */
buffer_get_map_state :: wgpu.buffer_get_map_state

/*
Returns the length of the buffer allocation in bytes.

This is always equal to the `size` that was specified when creating the buffer.
*/
buffer_get_size :: wgpu.buffer_get_size

/*
Returns the allowed usages for this Buffer.

This is always equal to the `usage` that was specified when creating the buffer.
*/
buffer_get_usage :: proc "contextless" (self: Buffer) -> Buffer_Usage_Flags {
	return transmute(Buffer_Usage_Flags)(wgpu.buffer_get_usage(self))
}

/* Maps the given range of the buffer. */
buffer_map_async :: proc "contextless" (
	self: Buffer,
	mode: Map_Mode_Flags,
	callback: Buffer_Map_Async_Callback,
	user_data: rawptr = nil,
	range: Buffer_Range = {},
	loc := #caller_location,
) -> (
	ok: bool,
) {
	_error_reset_data(loc)

	wgpu.buffer_map_async(
		self,
		mode,
		uint(range.offset),
		uint(range.size) if range.size > 0 else uint(WHOLE_SIZE),
		callback,
		user_data,
	)

	return get_last_error() == nil
}

/*
Flushes any pending write operations and unmaps the buffer from host memory and makes it's
contents available for use by the GPU again.
*/
buffer_unmap :: proc "contextless" (self: Buffer, loc := #caller_location) -> (ok: bool) {
	_error_reset_data(loc)
	wgpu.buffer_unmap(self)
	return get_last_error() == nil
}

/* Set debug label. */
buffer_set_label :: wgpu.buffer_set_label

/* Increase the reference count. */
buffer_reference :: wgpu.buffer_reference

/* Release the `Buffer` resources. */
buffer_release :: wgpu.buffer_release
