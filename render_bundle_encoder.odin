package webgpu

// Vendor
import "vendor:wgpu"

/*
Encodes a series of GPU operations into a reusable "render bundle".

It only supports a handful of render commands, but it makes them reusable. It
can be created with `DeviceCreateRenderBundleEncoder`. It can be executed onto a
`CommandEncoder` using `RenderPassExecuteBundles`.

Executing a `RenderBundle` is often more efficient than issuing the underlying
commands manually.

Corresponds to [WebGPU `GPURenderBundleEncoder`](
https://gpuweb.github.io/gpuweb/#gpurenderbundleencoder).
*/
RenderBundleEncoder :: wgpu.RenderBundleEncoder

/* Draws primitives from the active vertex buffer(s). */
RenderBundleEncoderDraw :: proc "c" (
	self: RenderBundleEncoder,
	vertices: Range(u32),
	instances: Range(u32) = { start = 0, end = 1 },
) {
	wgpu.RenderBundleEncoderDraw(
		self,
		vertices.end - vertices.start,
		instances.end - instances.start,
		vertices.start,
		instances.start,
	)
}

/* Draws indexed primitives using the active index buffer and the active vertex buffer(s). */
RenderBundleEncoderDrawIndexed :: proc "c" (
	self: RenderBundleEncoder,
	indices: Range(u32),
	base_vertex: i32 = 0,
	instances: Range(u32) = { start = 0, end = 1 },
) {
	wgpu.RenderBundleEncoderDrawIndexed(
		self,
		indices.end - indices.start,
		instances.end - instances.start,
		indices.start,
		base_vertex,
		instances.start,
	)
}

/*
Draws indexed primitives using the active index buffer and the active vertex
buffers, based on the contents of the `indirectBuffer`.
*/
RenderBundleEncoderDrawIndexedIndirect :: proc "c" (
	self: RenderBundleEncoder,
	indirectBuffer: Buffer,
	indirectOffset: u64 = 0,
) {
	wgpu.RenderBundleEncoderDrawIndexedIndirect(self, indirectBuffer, indirectOffset)
}

/*
Draws primitives from the active vertex buffer(s) based on the contents of the `indirectBuffer`.
*/
RenderBundleEncoderDrawIndirect :: proc "c" (
	self: RenderBundleEncoder,
	indirectBuffer: Buffer,
	indirectOffset: u64 = 0,
) {
	wgpu.RenderBundleEncoderDrawIndirect(self, indirectBuffer, indirectOffset)
}

/*
Describes a `RenderBundle`.

Corresponds to [WebGPU `GPURenderBundleDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpurenderbundledescriptor).
*/
RenderBundleDescriptor :: wgpu.RenderBundleDescriptor

/*
Finishes recording and returns a `RenderBundle` that can be executed in other render passes.
 */
@(require_results)
RenderBundleEncoderFinish :: proc "c" (
	self: RenderBundleEncoder,
	descriptor: Maybe(RenderBundleDescriptor) = nil,
) -> (
	renderBundle: RenderBundle,
) {
	if desc, desc_ok := descriptor.?; desc_ok {
		renderBundle = wgpu.RenderBundleEncoderFinish(self, &desc)
	} else {
		renderBundle = wgpu.RenderBundleEncoderFinish(self, nil)
	}
	return
}

/* Inserts debug marker. */
RenderBundleEncoderInsertDebugMarker :: wgpu.RenderBundleEncoderInsertDebugMarker

/* Start record commands and group it into debug marker group. */
RenderBundleEncoderPushDebugGroup :: wgpu.RenderBundleEncoderPushDebugGroup

/* Stops command recording and creates debug group. */
RenderBundleEncoderPopDebugGroup :: wgpu.RenderBundleEncoderPopDebugGroup

/*
Sets the active bind group for a given bind group index. The bind group layout
in the active pipeline when any `draw` procedure is called must match the layout
of this bind group.

If the bind group have dynamic offsets, provide them in the binding order.
*/
RenderBundleEncoderSetBindGroup :: wgpu.RenderBundleEncoderSetBindGroup

/*
Sets the active index buffer.

Subsequent calls to draw_indexed on this `RenderBundleEncoder` will use buffer
as the source index buffer.
*/
RenderBundleEncoderSetIndexBuffer :: proc "c" (
	self: RenderBundleEncoder,
	bufferSlice: BufferSlice,
	format: IndexFormat,
) {
	wgpu.RenderBundleEncoderSetIndexBuffer(
		self,
		bufferSlice.buffer,
		format,
		bufferSlice.offset,
		bufferSlice.size if bufferSlice.size > 0 else WHOLE_SIZE,
	)
}

/* Sets a debug label for the given `RenderBundleEncoder`. */
RenderBundleEncoderSetLabel :: wgpu.RenderBundleEncoderSetLabel

/*
Sets the active render pipeline.

Subsequent draw calls will exhibit the behavior defined by pipeline.
*/
RenderBundleEncoderSetPipeline :: wgpu.RenderBundleEncoderSetPipeline

/*
Assign a vertex buffer to a slot.

Subsequent calls to `Draw` and `DrawIndexed` on this `RenderBundleEncoder` will
use buffer as one of the source vertex buffers.

The slot refers to the index of the matching descriptor in `VertexState.buffers`.
*/
RenderBundleEncoderSetVertexBuffer :: proc "c" (
	self: RenderBundleEncoder,
	slot: u32,
	bufferSlice: BufferSlice,
) {
	wgpu.RenderBundleEncoderSetVertexBuffer(
		self,
		slot,
		bufferSlice.buffer,
		bufferSlice.offset,
		bufferSlice.size if bufferSlice.size > 0 else WHOLE_SIZE,
	)
}

/* Increase the `RenderBundleEncoder` reference count. */
RenderBundleEncoderAddRef :: #force_inline proc "c" (self: RenderBundleEncoder)  {
	wgpu.RenderBundleEncoderAddRef(self)
}

/* Release the `RenderBundleEncoder` resources, use to decrease the reference count. */
RenderBundleEncoderRelease :: #force_inline proc "c" (self: RenderBundleEncoder)  {
	wgpu.RenderBundleEncoderRelease(self)
}

/*
Safely releases the `RenderBundleEncoder` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
RenderBundleEncoderReleaseSafe :: proc "c" (self: ^RenderBundleEncoder) {
	if self != nil && self^ != nil {
		wgpu.RenderBundleEncoderRelease(self^)
		self^ = nil
	}
}
