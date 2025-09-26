package webgpu

// Core
import intr "base:intrinsics"

// Vendor
import "vendor:wgpu"

/*
Handle to a GPU-accessible buffer.

Created with `DeviceCreateBuffer` or `DeviceCreateBufferWithData`.

Corresponds to [WebGPU `GPUBuffer`](https://gpuweb.github.io/gpuweb/#buffer-interface)..
*/
Buffer :: wgpu.Buffer

/* Return the binding resource for the entire buffer. */
BufferAsEntireBinding :: proc "c" (self: Buffer) -> BindingResource {
	return BufferAsEntireBufferBinding(self)
}

/* Return the binding view of the entire buffer. */
BufferAsEntireBufferBinding :: proc "c" (self: Buffer) -> BufferBinding {
	return { buffer = self, offset = 0, size = WHOLE_SIZE }
}

/*
Defines the range of a `Buffer` contents in bytes.
*/
BufferBounds :: Range(u64)

/*  */
BufferGetDefaultBounds :: proc "c" (buffer: Buffer) -> BufferBounds {
    size := BufferGetSize(buffer)
    return BufferBounds{
        start = 0,
        end = size,
    }
}

BufferGetSliceBase :: proc "c" (
	self: Buffer,
	bounds: BufferBounds = { start = 0, end = WHOLE_SIZE },
) -> BufferSlice {
	offset := bounds.start
	size: BufferSize
	if bounds.end == WHOLE_SIZE {
		size = BufferGetSize(self) - offset
	} else {
		size = bounds.end - offset
	}
	return BufferSlice{ buffer = self, offset = offset, size = size }
}

BufferGetSliceFullRange :: proc "c" (self: Buffer) -> BufferSlice {
	return BufferGetSliceBase(self, { start = 0, end = WHOLE_SIZE })
}

BufferGetSliceFromStart :: proc "c" (self: Buffer, start: u64) -> BufferSlice {
	return BufferGetSliceBase(self, { start = start, end = WHOLE_SIZE })
}

/*
Return a slice of a `Buffer`]s bytes.

Return a `BufferSlice` referring to the portion of `self`'s contents indicated
by `bounds`. Regardless of what sort of data `self` stores, `bounds` start and
end are given in bytes.

A `BufferSlice` can be used to supply vertex and index data, or to map buffer
contents for access from the CPU.
*/
BufferGetSlice :: proc {
	BufferGetSliceBase,
	BufferGetSliceFullRange,
	BufferGetSliceFromStart,
}

/*
Unmaps the buffer from host memory.

This terminates the effect of all previous `MapAsync` operations and makes the
buffer available for use by the GPU again.
*/
BufferUnmap :: wgpu.BufferUnmap

/*
Destroy the associated native resources as soon as possible.
*/
BufferDestroy :: wgpu.BufferDestroy

/*
Returns the length of the buffer allocation in bytes.

This is always equal to the `size` that was specified when creating the buffer.
*/
BufferGetSize :: wgpu.BufferGetSize

/*
Returns the allowed usages for this `Buffer`.

This is always equal to the `usage` that was specified when creating the buffer.
*/
BufferGetUsage :: wgpu.BufferGetUsage

/* Map state of a `Buffer`. */
BufferMapState :: wgpu.BufferMapState

/*
Returns the current map state for this `Buffer`.
*/
BufferGetMapState :: wgpu.BufferGetMapState

/* A slice of a `Buffer`, to be mapped, used for vertex or index data, or the like. */
BufferSlice :: struct {
	buffer: Buffer,
	offset: BufferAddress,
	size:   BufferSize,
}

/* Map mode of a `Buffer`. */
MapMode :: wgpu.MapMode

/* Type of buffer mapping. */
MapModes :: wgpu.MapModeFlags

/* No map mode. */
MAP_MODE_NONE :: MapModes{}

/*
Map the buffer. Buffer is ready to map once the callback is called.

For the callback to complete, either `QueueSubmit` or `DevicePoll` must be
called elsewhere in the runtime, possibly integrated into an event loop or run
on a separate thread.

The callback will be called on the thread that first calls the above functions
after the gpu work has completed. There are no restrictions on the code you can
run in the callback, however on native the call to the function will not
complete until the callback returns, so prefer keeping callbacks short and used
to set flags, send messages, etc.
*/
BufferMapAsync :: proc "c" (
	self: Buffer,
	mode: MapModes,
	bounds: BufferBounds,
	callbackInfo: BufferMapCallbackInfo,
) {
	wgpu.BufferMapAsync(
		self,
		mode,
		uint(bounds.start),
		uint(bounds.end) if bounds.end > 0 else uint(BufferGetSize(self)),
		callbackInfo,
	)
}

/*
Map the buffer. Buffer is ready to map once the callback is called.

For the callback to complete, either `QueueSubmit` or `DevicePoll` must be
called elsewhere in the runtime, possibly integrated into an event loop or run
on a separate thread.

The callback will be called on the thread that first calls the above functions
after the gpu work has completed. There are no restrictions on the code you can
run in the callback, however on native the call to the function will not
complete until the callback returns, so prefer keeping callbacks short and used
to set flags, send messages, etc.
*/
BufferSliceMapAsync :: proc "c" (
	self: BufferSlice,
	mode: MapModes,
	callbackInfo: BufferMapCallbackInfo,
) {
	wgpu.BufferMapAsync(
		self.buffer,
		mode,
		uint(self.offset),
		uint(self.size) if self.size > 0 else uint(BufferGetSize(self.buffer)),
		callbackInfo,
	)
}

/* A view of a mapped buffer's bytes. */
BufferView :: struct($T: typeid) {
	using slice: BufferSlice,
	data:        T,
}

@(require_results)
BufferGetMappedRangeSlice :: proc "c" (
    self: Buffer,
    $T: typeid/[]$E,
    bounds: BufferBounds = {},
    loc := #caller_location,
) -> (
    view: BufferView(T),
) where intr.type_is_sliceable(T) {
    bounds := bounds if bounds != {} else BufferGetDefaultBounds(self)
    end := bounds.end if bounds.end != WHOLE_SIZE else BufferGetSize(self)

    assert_contextless(bounds.start >= 0 && end >= 0 && end >= bounds.start,
	    "Invalid buffer bounds", loc)

    byte_length := uint(end - bounds.start)
    element_count := byte_length / size_of(E)  // Convert bytes to element count
    data := wgpu.BufferGetMappedRangeSlice(self, uint(bounds.start), E, element_count)

    actual_bounds := BufferBounds{start = bounds.start, end = end}
    view = {
        slice = BufferGetSlice(self, actual_bounds),
        data  = data,
    }

    return
}

@(require_results)
BufferGetMappedRangeBytes :: proc "c" (
	self: Buffer,
	bounds: BufferBounds = {},
	loc := #caller_location,
) -> (
	view: BufferView([]byte),
) {
	return #force_inline BufferGetMappedRangeSlice(self, []byte, bounds, loc)
}

@(require_results)
BufferGetMappedRangeTyped :: proc "c" (
	self: Buffer,
	$T: typeid,
	bounds: BufferBounds = {},
	loc := #caller_location,
) -> (
	view: BufferView(T),
) where !intr.type_is_sliceable(T) {
	bounds := bounds if bounds != {} else BufferGetDefaultBounds(self)
    end := bounds.end if bounds.end != WHOLE_SIZE else BufferGetSize(self)

	assert_contextless(bounds.start >= 0 && end >= 0 && end >= bounds.start,
		"Invalid buffer bounds", loc)

	data := wgpu.BufferGetMappedRangeTyped(self, uint(bounds.start), T)

	actual_bounds := BufferBounds{start = bounds.start, end = end}
	view = {
		slice = BufferGetSlice(self, actual_bounds),
		data  = data,
	}

	return
}

/*
Gain write access to the bytes of a mapped `Buffer`.

Return a `BufferViewMut` referring to the buffer range represented by
`self`. See the documentation for `BufferViewMut` for more details.

**Panics**

- This panics if the buffer to which `self` refers is not currently mapped.

- If you try to create overlapping views of a buffer, mutable or
otherwise, `BufferGetMappedRange` will panic.
*/
@(require_results)
BufferGetMappedRange :: proc {
	BufferGetMappedRangeSlice,
	BufferGetMappedRangeBytes,
	BufferGetMappedRangeTyped,
}

@(require_results)
BufferGetConstMappedRangeSlice :: proc "c" (
    self: Buffer,
    $T: typeid/[]$E,
    bounds: BufferBounds = {},
    loc := #caller_location,
) -> (
    view: BufferView(T),
) where intr.type_is_sliceable(T) {
    bounds := bounds if bounds != {} else BufferGetDefaultBounds(self)
    end := bounds.end if bounds.end != WHOLE_SIZE else BufferGetSize(self)

    assert_contextless(bounds.start >= 0 && end >= 0 && end >= bounds.start,
	    "Invalid buffer bounds", loc)

    byte_length := uint(end - bounds.start)
    element_count := byte_length / size_of(E)  // Convert bytes to element count
    data := wgpu.BufferGetConstMappedRangeSlice(self, uint(bounds.start), element_count, E)

    actual_bounds := BufferBounds{start = bounds.start, end = end}
    view = {
        slice = BufferGetSlice(self, actual_bounds),
        data  = data,
    }

    return
}

@(require_results)
BufferGetConstMappedRangeBytes :: proc "c" (
	self: Buffer,
	bounds: BufferBounds = {},
	loc := #caller_location,
) -> (
	view: BufferView([]byte),
) {
	return #force_inline BufferGetConstMappedRangeSlice(self, []byte, bounds, loc)
}

@(require_results)
BufferGetConstMappedRangeTyped :: proc "c" (
	self: Buffer,
	$T: typeid,
	bounds: BufferBounds = {},
	loc := #caller_location,
) -> (
	view: BufferView(T),
) where !intr.type_is_sliceable(T) {
	bounds := bounds if bounds != {} else BufferGetDefaultBounds(self)
    end := bounds.end if bounds.end != WHOLE_SIZE else BufferGetSize(self)

	assert_contextless(bounds.start >= 0 && end >= 0 && end >= bounds.start,
		"Invalid buffer bounds", loc)

	data := wgpu.BufferGetConstMappedRangeTyped(self, uint(bounds.start), T)

	actual_bounds := BufferBounds{start = bounds.start, end = end}
	view = {
		slice = BufferGetSlice(self, actual_bounds),
		data  = data,
	}

	return
}

/*
Gain read-only access to the bytes of a mapped `Buffer`.

Return a `BufferView` referring to the buffer range represented by
`self`. See the documentation for `BufferView` for details.

**Panics**

- This panics if the buffer to which `self` refers is not currently mapped.

- If you try to create overlapping views of a buffer, mutable or
otherwise, `BufferGetConstMappedRange` will panic.
*/
@(require_results)
BufferGetConstMappedRange :: proc {
	BufferGetConstMappedRangeSlice,
	BufferGetConstMappedRangeBytes,
	BufferGetConstMappedRangeTyped,
}

/* Sets a debug label for the given `Buffer`. */
BufferSetLabel :: #force_inline proc "c" (self: Buffer, label: string) {
	wgpu.BufferSetLabel(self, label)
}

/* Increase the `Buffer` reference count. */
BufferAddRef :: #force_inline proc "c" (self: Buffer) {
	wgpu.BufferAddRef(self)
}

/* Release the `Buffer` resources, use to decrease the reference count. */
BufferRelease :: #force_inline proc "c" (self: Buffer) {
	wgpu.BufferRelease(self)
}

/*
Safely releases the `Buffer` resources and invalidates the handle.
The procedure checks both the pointer validity and buffer handle before releasing.

Note: After calling this, buffer handle will be set to `nil` and should not be used.
*/
BufferReleaseSafe :: proc "c" (self: ^Buffer) {
	if self != nil && self^ != nil {
		wgpu.BufferRelease(self^)
		self^ = nil
	}
}
