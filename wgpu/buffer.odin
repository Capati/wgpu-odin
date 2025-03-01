package wgpu

// Packages
import intr "base:intrinsics"

/*
Handle to a GPU-accessible buffer.

Created with `device_create_buffer` or `device_create_buffer_with_data`.

Corresponds to [WebGPU `GPUBuffer`](https://gpuweb.github.io/gpuweb/#buffer-interface)..
*/
Buffer :: distinct rawptr

/*
Describes a `Buffer`

Corresponds to [WebGPU `GPUBufferDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpubufferdescriptor).
*/
Buffer_Descriptor :: struct {
	label:              string,
	usage:              Buffer_Usages,
	size:               u64,
	mapped_at_creation: bool,
}

/* Return the binding view of the entire buffer. */
buffer_as_entire_binding :: proc "contextless" (self: Buffer) -> Buffer_Binding {
	return {buffer = self, offset = 0, size = buffer_size(self)}
}

/* Defines the range of a `Buffer` contents in bytes. */
Buffer_Bounds :: Range(u64)

/*  */
buffer_get_default_bounds :: #force_inline proc "contextless" (
	self: Buffer,
	offset: Buffer_Address = 0,
) -> Buffer_Bounds {
	return {offset, buffer_size(self)}
}

/*
Return a slice of a `Buffer`]s bytes.

Return a `Buffer_Slice` referring to the portion of `self`'s contents
indicated by `bounds`. Regardless of what sort of data `self` stores,
`bounds` start and end are given in bytes.

A `Buffer_Slice` can be used to supply vertex and index data, or to map
buffer contents for access from the CPU. See the `Buffer_Slice`
documentation for details.

The `range` argument can be half or fully unbounded: for example,
`buffer.slice(..)` refers to the entire buffer, and `buffer.slice(n..)`
refers to the portion starting at the `n`th byte and extending to the
end of the buffer.
*/
buffer_slice :: proc "contextless" (
	self: Buffer,
	bounds: Buffer_Bounds = {start = 0, end = WHOLE_SIZE},
) -> Buffer_Slice {
	offset := bounds.start
	size: Buffer_Size
	if bounds.end == WHOLE_SIZE {
		size = buffer_size(self) - offset
	} else {
		// assert(bounds.end > offset, "Buffer slices cannot be empty")
		size = bounds.end - offset
	}
	return Buffer_Slice{buffer = self, offset = offset, size = size}
}

/* Flushes any pending write operations and unmaps the buffer from host memory. */
buffer_unmap :: proc "contextless" (self: Buffer, loc := #caller_location) -> (ok: bool) {
	error_reset_data(loc)
	wgpuBufferUnmap(self)
	return has_no_error()
}

/* Destroy the associated native resources as soon as possible. */
buffer_destroy :: proc "contextless" (self: Buffer) {
	wgpuBufferDestroy(self)
}

/*
Returns the length of the buffer allocation in bytes.

This is always equal to the `size` that was specified when creating the buffer.
*/
buffer_size :: wgpuBufferGetSize

/*
Returns the allowed usages for this `Buffer`.

This is always equal to the `usage` that was specified when creating the buffer.
*/
buffer_usage :: wgpuBufferGetUsage

Buffer_Map_State :: enum i32 {
	Unmapped = 0x00000001,
	Pending  = 0x00000002,
	Mapped   = 0x00000003,
}

/* Returns the current map state for this `Buffer`. */
buffer_map_state :: wgpuBufferGetMapState

/* A slice of a `Buffer`, to be mapped, used for vertex or index data, or the like. */
Buffer_Slice :: struct {
	buffer: Buffer,
	offset: Buffer_Address,
	size:   Buffer_Size,
}

Map_Mode :: enum u64 {
	Read,
	Write,
}

/* Type of buffer mapping. */
Map_Modes :: distinct bit_set[Map_Mode;u64]

MAP_MODE_NONE :: Map_Modes{}

/*
Map the buffer. Buffer is ready to map once the callback is called.

For the callback to complete, either `queue_submit` or `device_poll`
must be called elsewhere in the runtime, possibly integrated into an event loop or run on a separate thread.

The callback will be called on the thread that first calls the above functions after the gpu work
has completed. There are no restrictions on the code you can run in the callback, however on native the
call to the function will not complete until the callback returns, so prefer keeping callbacks short
and used to set flags, send messages, etc.
*/
buffer_map_async :: proc "contextless" (
	self: Buffer,
	mode: Map_Modes,
	bounds: Buffer_Bounds,
	callback_info: Buffer_Map_Callback_Info,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	error_reset_data(loc)
	wgpuBufferMapAsync(
		self,
		mode,
		uint(bounds.start),
		uint(bounds.end) if bounds.end > 0 else uint(WHOLE_SIZE),
		callback_info,
	)
	return has_no_error()
}

/* A view of a mapped buffer's bytes. */
Buffer_View :: struct($T: typeid) {
	slice: Buffer_Slice,
	data:  T,
}

@(require_results)
buffer_get_mapped_range_sliced :: proc "contextless" (
	self: Buffer,
	$T: typeid/[]$U,
	bounds: Buffer_Bounds = {},
	loc := #caller_location,
) -> (
	view: Buffer_View(T),
	ok: bool,
) where intr.type_is_sliceable(T) #optional_ok {
	bounds := bounds if bounds != {} else buffer_get_default_bounds(self)
	length := uint(bounds.end - bounds.start)

	error_reset_data(loc)
	data := wgpuBufferGetMappedRange(self, uint(bounds.start), length)
	if !has_no_error() {
		return
	}

	if data == nil {
		return
	}

	view = {
		slice = buffer_slice(self, bounds),
		data  = ([^]U)(data)[:length],
	}

	return view, true
}

@(require_results)
buffer_get_mapped_range_bytes :: proc "contextless" (
	self: Buffer,
	bounds: Buffer_Bounds = {},
	loc := #caller_location,
) -> (
	view: Buffer_View([]byte),
	ok: bool,
) #optional_ok {
	return buffer_get_mapped_range_sliced(self, []byte, bounds, loc)
}

@(require_results)
buffer_get_mapped_range_typed :: proc "contextless" (
	self: Buffer,
	$T: typeid,
	bounds: Buffer_Bounds = {},
	loc := #caller_location,
) -> (
	view: Buffer_View(T),
	ok: bool,
) where !intr.type_is_sliceable(T) #optional_ok {
	bounds := bounds if bounds != {} else buffer_get_default_bounds(self)
	end := uint(bounds.end - bounds.start)

	error_reset_data(loc)
	data := wgpuBufferGetMappedRange(self, uint(bounds.start), end)
	if !has_no_error() {
		return
	}

	if data == nil {
		return
	}

	view = {
		slice = buffer_slice(self, bounds),
		data  = (^T)(data),
	}

	return view, true
}

/*
Gain write access to the bytes of a mapped `Buffer`.

Return a `BufferViewMut` referring to the buffer range represented by
`self`. See the documentation for `BufferViewMut` for more details.

**Panics**

- This panics if the buffer to which `self` refers is not currently mapped.

- If you try to create overlapping views of a buffer, mutable or
otherwise, `buffer_get_mapped_range_mut` will panic.
*/
@(require_results)
buffer_get_mapped_range_mut :: proc {
	buffer_get_mapped_range_sliced,
	buffer_get_mapped_range_bytes,
	buffer_get_mapped_range_typed,
}

@(require_results)
buffer_get_const_mapped_range_sliced :: proc "contextless" (
	self: Buffer,
	$T: typeid/[]$U,
	bounds: Buffer_Bounds = {},
	loc := #caller_location,
) -> (
	view: Buffer_View(T),
	ok: bool,
) where intr.type_is_sliceable(T) #optional_ok {
	bounds := bounds if bounds != {} else buffer_get_default_bounds(self)
	length := uint(bounds.end - bounds.start)

	error_reset_data(loc)
	data := wgpuBufferGetConstMappedRange(self, uint(bounds.start), length)
	if !has_no_error() {
		return
	}

	if data == nil {
		return
	}

	view = {
		slice = buffer_slice(self, bounds),
		data  = ([^]U)(data)[:length],
	}

	return view, true
}

@(require_results)
buffer_get_const_mapped_range_bytes :: proc "contextless" (
	self: Buffer,
	bounds: Buffer_Bounds = {},
	loc := #caller_location,
) -> (
	view: Buffer_View([]byte),
	ok: bool,
) #optional_ok {
	return buffer_get_const_mapped_range_sliced(self, []byte, bounds, loc)
}

@(require_results)
buffer_get_const_mapped_range_typed :: proc "contextless" (
	self: Buffer,
	$T: typeid,
	bounds: Buffer_Bounds = {},
	loc := #caller_location,
) -> (
	view: Buffer_View(T),
	ok: bool,
) where !intr.type_is_sliceable(T) #optional_ok {
	bounds := bounds if bounds != {} else buffer_get_default_bounds(self)
	end := uint(bounds.end - bounds.start)

	error_reset_data(loc)
	data := wgpuBufferGetConstMappedRange(self, uint(bounds.start), end)
	if !has_no_error() {
		return
	}

	if data == nil {
		return
	}

	view = {
		slice = buffer_slice(self, bounds),
		data  = (^T)(data),
	}

	return view, true
}

/*
Gain read-only access to the bytes of a mapped `Buffer`.

Return a `Buffer_View` referring to the buffer range represented by
`self`. See the documentation for `Buffer_View` for details.

**Panics**

- This panics if the buffer to which `self` refers is not currently mapped.

- If you try to create overlapping views of a buffer, mutable or
otherwise, `buffer_get_mapped_range` will panic.
*/
@(require_results)
buffer_get_mapped_range :: proc {
	buffer_get_const_mapped_range_sliced,
	buffer_get_const_mapped_range_bytes,
	buffer_get_const_mapped_range_typed,
}

/* Sets a debug label for the given `Buffer`. */
@(disabled = !ODIN_DEBUG)
buffer_set_label :: proc "contextless" (self: Buffer, label: string) {
	c_label: String_View_Buffer
	wgpuBufferSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the `Buffer` reference count. */
buffer_add_ref :: wgpuBufferAddRef

/* Release the `Buffer` resources, use to decrease the reference count. */
buffer_release :: wgpuBufferRelease

/*
Safely releases the `Buffer` resources and invalidates the handle.
The procedure checks both the pointer validity and buffer handle before releasing.

Note: After calling this, buffer handle will be set to `nil` and should not be used.
*/
buffer_release_safe :: #force_inline proc(self: ^Buffer) {
	if self != nil && self^ != nil {
		wgpuBufferRelease(self^)
		self^ = nil
	}
}

@(private)
WGPU_Buffer_Descriptor :: struct {
	next_in_chain:      ^Chained_Struct,
	label:              String_View,
	usage:              Buffer_Usages,
	size:               u64,
	mapped_at_creation: b32,
}
