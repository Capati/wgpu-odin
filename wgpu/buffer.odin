package wgpu

// Packages
import intr "base:intrinsics"

/*
Handle to a GPU-accessible buffer.

Created with `device_create_buffer` or `device_create_buffer_with_data`.

Corresponds to [WebGPU `GPUBuffer`](https://gpuweb.github.io/gpuweb/#buffer-interface)..
*/
Buffer :: distinct rawptr

BufferRange :: struct {
	offset: BufferAddress,
	size:   BufferSize,
}

buffer_get_default_range :: #force_inline proc "contextless" (
	self: Buffer,
	offset: BufferAddress = 0,
) -> BufferRange {
	return {offset, buffer_get_size(self)}
}

/* Return the binding view of the entire buffer with the current size. */
buffer_as_entire_binding :: proc "contextless" (self: Buffer) -> BufferBinding {
	return {buffer = self, offset = 0, size = buffer_get_size(self)}
}

/* Destroy the associated native resources as soon as possible. */
buffer_destroy :: proc "contextless" (self: Buffer) {
	wgpuBufferDestroy(self)
}

BufferSlice :: struct {
	buffer:      Buffer,
	using range: BufferRange,
}

buffer_slice :: proc(
	self: Buffer,
	range: BufferRange = {offset = 0, size = WHOLE_SIZE},
) -> BufferSlice {
	range := range
	range.size = range.size if range.size > 0 else WHOLE_SIZE
	return {buffer = self, range = range}
}

BufferView :: struct($T: typeid) {
	slice: BufferSlice,
	data:  T,
}

@(require_results)
buffer_get_mapped_range_sliced :: proc "contextless" (
	self: Buffer,
	$T: typeid/[]$U,
	range: BufferRange = {},
	loc := #caller_location,
) -> (
	view: BufferView(T),
	ok: bool,
) where intr.type_is_sliceable(T) #optional_ok {
	range := range if range != {} else buffer_get_default_range(self)
	length := uint(range.size - range.offset)

	error_reset_data(loc)
	data := wgpuBufferGetMappedRange(self, uint(range.offset), length)
	if !has_no_error() {
		return
	}

	if data == nil {
		return
	}

	view = {
		slice = {buffer = self, range = range},
		data = ([^]U)(data)[:length],
	}

	return view, true
}

@(require_results)
buffer_get_mapped_range_bytes :: proc "contextless" (
	self: Buffer,
	range: BufferRange = {},
	loc := #caller_location,
) -> (
	view: BufferView([]byte),
	ok: bool,
) #optional_ok {
	return buffer_get_mapped_range_sliced(self, []byte, range, loc)
}

@(require_results)
buffer_get_mapped_range_typed :: proc "contextless" (
	self: Buffer,
	$T: typeid,
	range: BufferRange = {},
	loc := #caller_location,
) -> (
	view: BufferView(T),
	ok: bool,
) where !intr.type_is_sliceable(T) #optional_ok {
	range := range if range != {} else buffer_get_default_range(self)
	end := uint(range.size - range.offset)

	error_reset_data(loc)
	data := wgpuBufferGetMappedRange(self, uint(range.offset), end)
	if !has_no_error() {
		return
	}

	if data == nil {
		return
	}

	view = {
		slice = {buffer = self, range = range},
		data = (^T)(data),
	}

	return view, true
}

@(require_results)
buffer_get_mapped_range :: proc {
	buffer_get_mapped_range_sliced,
	buffer_get_mapped_range_bytes,
	buffer_get_mapped_range_typed,
}

@(require_results)
buffer_get_const_mapped_range_sliced :: proc "contextless" (
	self: Buffer,
	$T: typeid/[]$U,
	range: BufferRange = {},
	loc := #caller_location,
) -> (
	view: BufferView(T),
	ok: bool,
) where intr.type_is_sliceable(T) #optional_ok {
	range := range if range != {} else buffer_get_default_range(self)
	length := uint(range.size - range.offset)

	error_reset_data(loc)
	data := wgpuBufferGetConstMappedRange(self, uint(range.offset), length)
	if !has_no_error() {
		return
	}

	if data == nil {
		return
	}

	view = {
		slice = {buffer = self, range = range},
		data = ([^]U)(data)[:length],
	}

	return view, true
}

@(require_results)
buffer_get_const_mapped_range_bytes :: proc "contextless" (
	self: Buffer,
	range: BufferRange = {},
	loc := #caller_location,
) -> (
	view: BufferView([]byte),
	ok: bool,
) #optional_ok {
	return buffer_get_const_mapped_range_sliced(self, []byte, range, loc)
}

@(require_results)
buffer_get_const_mapped_range_typed :: proc "contextless" (
	self: Buffer,
	$T: typeid,
	range: BufferRange = {},
	loc := #caller_location,
) -> (
	view: BufferView(T),
	ok: bool,
) where !intr.type_is_sliceable(T) #optional_ok {
	range := range if range != {} else buffer_get_default_range(self)
	end := uint(range.size - range.offset)

	error_reset_data(loc)
	data := wgpuBufferGetConstMappedRange(self, uint(range.offset), end)
	if !has_no_error() {
		return
	}

	if data == nil {
		return
	}

	view = {
		slice = {buffer = self, range = range},
		data = (^T)(data),
	}

	return view, true
}

@(require_results)
buffer_get_const_mapped_range :: proc {
	buffer_get_const_mapped_range_sliced,
	buffer_get_const_mapped_range_bytes,
	buffer_get_const_mapped_range_typed,
}


/* Get current `Buffer_Map_State` state. */
buffer_get_map_state :: wgpuBufferGetMapState

/*
Returns the length of the buffer allocation in bytes.

This is always equal to the `size` that was specified when creating the buffer.
*/
buffer_get_size :: wgpuBufferGetSize

/*
Returns the allowed usages for this Buffer.

This is always equal to the `usage` that was specified when creating the buffer.
*/
buffer_get_usage :: proc "contextless" (self: Buffer) -> BufferUsage {
	return wgpuBufferGetUsage(self)
}

/* Maps the given range of the buffer. */
buffer_map_async :: proc "contextless" (
	self: Buffer,
	mode: MapMode,
	range: BufferRange,
	callback_info: BufferMapCallbackInfo,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	error_reset_data(loc)
	wgpuBufferMapAsync(
		self,
		mode,
		uint(range.offset),
		uint(range.size) if range.size > 0 else uint(WHOLE_SIZE),
		callback_info,
	)
	return has_no_error()
}

/*
Flushes any pending write operations and unmaps the buffer from host memory and makes it's
contents available for use by the GPU again.
*/
buffer_unmap :: proc "contextless" (self: Buffer, loc := #caller_location) -> (ok: bool) {
	error_reset_data(loc)
	wgpuBufferUnmap(self)
	return has_no_error()
}

/* Set debug label. */
@(disabled = !ODIN_DEBUG)
buffer_set_label :: proc "contextless" (self: Buffer, label: string) {
	c_label: StringViewBuffer
	wgpuBufferSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the reference count. */
buffer_add_ref :: wgpuBufferAddRef

/* Release the `Buffer` resources. */
buffer_release :: wgpuBufferRelease
