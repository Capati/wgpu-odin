package webgpu

// Vendor
import "vendor:wgpu"

/*
In-progress recording of a render pass: a list of render commands in a
`CommandEncoder`.

It can be created with `CommandEncoderBeginRenderPass`, whose
`RenderPassDescriptor` specifies the attachments (textures) that will be
rendered to.

Most of the procedures for `RenderPass` serve one of two purposes, identifiable
by their names:

* `Draw*()`: Drawing (that is, encoding a render command, which, when executed
  by the GPU, will rasterize something and execute shaders).
* `Set*()`: Setting part of the [render
  state](https://gpuweb.github.io/gpuweb/#renderstate) for future drawing
  commands.

A render pass may contain any number of drawing commands, and before/between
each command the render state may be updated however you wish; each drawing
command will be executed using the render state that has been set when the
`Draw*()` procedure is called.

Corresponds to [WebGPU `GPURenderPassEncoder`](
https://gpuweb.github.io/gpuweb/#render-pass-encoder).
*/
RenderPass :: wgpu.RenderPassEncoder

/*
Operation to perform to the output attachment at the start of a render pass.

Corresponds to [WebGPU
`GPULoadOp`](https://gpuweb.github.io/gpuweb/#enumdef-gpuloadop), plus the
corresponding `clear_value`.
*/
LoadOp :: wgpu.LoadOp

/*
Operation to perform to the output attachment at the end of a render pass.

Corresponds to [WebGPU
`GPUStoreOp`](https://gpuweb.github.io/gpuweb/#enumdef-gpustoreop).
*/
StoreOp :: wgpu.StoreOp

/*
Pair of load and store operations for an attachment aspect.

This type is unique to the `wgpu` API. In the WebGPU specification, separate
`loadOp` and `storeOp` fields are used instead.
*/
Operations :: struct($T: typeid) {
	load:       LoadOp,
	store:      StoreOp,
	clearValue: T, /* For use with LoadOp.Clear */
}

/*
Sets the active bind group for a given bind group index. The bind group layout
in the active pipeline when any `Draw*()` procedure is called must match the
layout of this bind group.

If the bind group have dynamic offsets, provide them in binding order. These
offsets have to be aligned to `Limits.minUniformBufferOffsetAlignment` or
`Limits.minStorageBufferOffsetAlignment` appropriately.

Subsequent draw calls’ shader executions will be able to access data in these
bind groups.
*/
RenderPassSetBindGroup :: wgpu.RenderPassEncoderSetBindGroup

/*
Sets the active render pipeline.

Subsequent draw calls will exhibit the behavior defined by `pipeline`.
*/
RenderPassSetPipeline :: wgpu.RenderPassEncoderSetPipeline

/*
Sets the blend color as used by some of the blending modes.

Subsequent blending tests will test against this value. If this procedure has
not been called, the blend constant defaults to `COLOR_TRANSPARENT` (all
components zero).
*/
RenderPassSetBlendConstant :: proc "c" (
	self: RenderPass,
	color: Color = COLOR_TRANSPARENT,
) {
	color := color
	wgpu.RenderPassEncoderSetBlendConstant(self, &color)
}

/*
Sets the active index buffer.

Subsequent calls to `RenderPassDrawIndexed` on this `RenderPass` will use
`buffer` as the source index buffer.
*/
RenderPassSetIndexBuffer :: proc "c" (
	self: RenderPass,
	bufferSlice: BufferSlice,
	indexFormat: IndexFormat,
) {
	wgpu.RenderPassEncoderSetIndexBuffer(
		self,
		bufferSlice.buffer,
		indexFormat,
		bufferSlice.offset,
		bufferSlice.size if bufferSlice.size > 0 else WHOLE_SIZE,
	)
}

/*
Assign a vertex buffer to a slot.

Subsequent calls to `render_pass_draw` and `RenderPassDrawIndexed` on this
`RenderPass` will use `buffer` as one of the source vertex buffers.

The `slot` refers to the index of the matching descriptor in
`Vertex_State::buffers`.
*/
RenderPassSetVertexBuffer :: proc "c" (
	self: RenderPass,
	slot: u32,
	bufferSlice: BufferSlice,
) {
	wgpu.RenderPassEncoderSetVertexBuffer(
		self,
		slot,
		bufferSlice.buffer,
		bufferSlice.offset,
		bufferSlice.size if bufferSlice.size > 0 else WHOLE_SIZE,
	)
}

/*
Sets the scissor rectangle used during the rasterization stage. After
transformation into [viewport
coordinates](https://www.w3.org/TR/webgpu/#viewport-coordinates).

Subsequent draw calls will discard any fragments which fall outside the scissor
rectangle. If this procedure has not been called, the scissor rectangle defaults
to the entire bounds of the render targets.

The procedure of the scissor rectangle resembles `SetViewport`, but it does not
affect the coordinate system, only which fragments are discarded.
*/
RenderPassSetScissorRect :: wgpu.RenderPassEncoderSetScissorRect

/*
Sets the viewport used during the rasterization stage to linearly map from
normalized device coordinates to viewport coordinates.
*/
RenderPassSetViewport :: wgpu.RenderPassEncoderSetViewport

/*
Sets the stencil reference.

Subsequent stencil tests will test against this value. If this procedure has not
been called, the  stencil reference value defaults to `0`.
*/
RenderPassSetStencilReference :: wgpu.RenderPassEncoderSetStencilReference

/* Inserts debug marker. */
RenderPassInsertDebugMarker :: wgpu.RenderPassEncoderInsertDebugMarker

/* Start record commands and group it into debug marker group. */
RenderPassPushDebugGroup :: wgpu.RenderPassEncoderPushDebugGroup

/* Stops command recording and creates debug group. */
RenderPassPopDebugGroup :: wgpu.RenderPassEncoderPopDebugGroup

/*
Draws primitives from the active vertex buffer(s).

The active vertex buffer(s) can be set with `RenderPassSetVertexBuffer`. Does
not use an Index Buffer. If you need this see `RenderPassDrawIndexed`

Panics if vertices Range is outside of the range of the vertices range of any
set vertex buffer.

This drawing command uses the current render state, as set by preceding
`Set*()` procedures. It is not affected by changes to the state that are
performed after it is called.
*/
RenderPassDraw :: proc "c" (
	self: RenderPass,
	vertices: Range(u32),
	instances: Range(u32) = { start = 0, end = 1 },
) {
	wgpu.RenderPassEncoderDraw(
		self,
		vertices.end - vertices.start,
		instances.end - instances.start,
		vertices.start,
		instances.start,
	)
}

/*
Draws indexed primitives using the active index buffer and the active vertex
buffers.

The active index buffer can be set with `RenderPassSetIndexBuffer` The
active vertex buffers can be set with `RenderPassSetVertexBuffer`.

Panics if indices Range is outside of the range of the indices range of any set
index buffer.

This drawing command uses the current render state, as set by preceding
`Set*()` procedures. It is not affected by changes to the state that are
performed after it is called.
*/
RenderPassDrawIndexed :: proc "c" (
	self: RenderPass,
	indices: Range(u32),
	baseVertex: i32 = 0,
	instances: Range(u32) = { start = 0, end = 1 },
) {
	wgpu.RenderPassEncoderDrawIndexed(
		self,
		indices.end - indices.start,
		instances.end - instances.start,
		indices.start,
		baseVertex,
		instances.start,
	)
}

/*
Draws primitives from the active vertex buffer(s) based on the contents of the
`indirectBuffer`.

This is like calling `RenderPassDraw` but the contents of the call are
specified in the `indirectBuffer`.
*/
RenderPassDrawIndirect :: proc "c" (
	self: RenderPass,
	indirectBuffer: Buffer,
	IndirectOffset: BufferAddress = 0,
) {
	wgpu.RenderPassEncoderDrawIndirect(self, indirectBuffer, IndirectOffset)
}

/*
Draws indexed primitives using the active index buffer and the active vertex buffers,
based on the contents of the `indirectBuffer`.
*/
RenderPassDrawIndexedIndirect :: proc "c" (
	self: RenderPass,
	indirectBuffer: Buffer,
	indirectOffset: BufferAddress = 0,
) {
	wgpu.RenderPassEncoderDrawIndexedIndirect(self, indirectBuffer, indirectOffset)
}

/*
Execute a render bundle, which is a set of pre-recorded commands that can be run
together.

Commands in the bundle do not inherit this render pass's current render state,
and after the bundle has executed, the state is **cleared** (reset to defaults,
not the previous state).
*/
RenderPassExecuteBundles :: wgpu.RenderPassEncoderExecuteBundles

/*
Dispatches multiple draw calls from the active vertex buffer(s) based on the
contents of the `buffer`. `count` draw calls are issued.

The active vertex buffers can be set with `RenderPassSetVertexBuffer`.

This drawing command uses the current render state, as set by preceding
`Set*()` procedures. It is not affected by changes to the state that are
performed after it is called.
*/
RenderPassMultiDrawIndirect :: wgpu.RenderPassEncoderMultiDrawIndirect

/*
Dispatches multiple draw calls from the active index buffer and the active
vertex buffers, based on the contents of the `buffer`. `count` draw
calls are issued.

The active index buffer can be set with `RenderPassSetIndexBuffer`, while
the active vertex buffers can be set with `RenderPassSetVertexBuffer`.

This drawing command uses the current render state, as set by preceding
`Set*()` procedures. It is not affected by changes to the state that are
performed after it is called.
*/
RenderPassMultiDrawIndexedIndirect :: wgpu.RenderPassEncoderMultiDrawIndexedIndirect

/*
Dispatches multiple draw calls from the active vertex buffer(s) based on the
contents of the `indirect_buffer`. The count buffer is read to determine how
many draws to issue.

The indirect buffer must be long enough to account for `maxCount` draws,
however only `count` draws will be read. If `count` is greater than `maxCount`,
`maxCount` will be used.

The active vertex buffers can be set with `RenderPassSetVertexBuffer`.

This drawing command uses the current render state, as set by preceding
`Set*()` procedures. It is not affected by changes to the state that are
performed after it is called.
*/
RenderPassMultiDrawIndirectCount :: wgpu.RenderPassEncoderMultiDrawIndirectCount

/*
Dispatches multiple draw calls from the active index buffer and the active
vertex buffers, based on the contents of the `buffer`. The count buffer
is read to determine how many draws to issue.

The indirect buffer must be long enough to account for `maxCount` draws,
however only `count` draws will be read. If `count` is greater than `maxCount`,
`maxCount` will be used.

The active index buffer can be set with `RenderPassSetIndexBuffer`, while
the active vertex buffers can be set with `RenderPassSetVertexBuffer`.

This drawing command uses the current render state, as set by preceding
`Set*()` procedures. It is not affected by changes to the state that are
performed after it is called.
*/
RenderPassMultiDrawIndexedIndirectCount :: wgpu.RenderPassEncoderMultiDrawIndexedIndirectCount

/*
Set push constant data for subsequent draw calls.

Write the bytes in `data` at offset `offset` within push constant storage, all
of which are accessible by all the pipeline stages in `stages`, and no others.
Both `offset` and the length of `data` must be multiples of
`PUSH_CONSTANT_ALIGNMENT`, which is always 4.

For example, if `offset` is `4` and `data` is eight bytes long, this call will
write `data` to bytes `4..12` of push constant storage.

**Stage matching**

Every byte in the affected range of push constant storage must be accessible to
exactly the same set of pipeline stages, which must match `stages`. If there are
two bytes of storage that are accessible by different sets of pipeline stages -
say, one is accessible by fragment shaders, and the other is accessible by both
fragment shaders and vertex shaders - then no single `set_push_constants` call
may affect both of them; to write both, you must make multiple calls, each with
the appropriate `stages` value.

Which pipeline stages may access a given byte is determined by the pipeline's
`PushConstant` global variable and (if it is a struct) its members' offsets.

For example, suppose you have twelve bytes of push constant storage, where bytes
`0..8` are accessed by the vertex shader, and bytes `4..12` are accessed by the
fragment shader. This means there are three byte ranges each accessed by a
different set of stages:

- Bytes `0..4` are accessed only by the fragment shader.
- Bytes `4..8` are accessed by both the fragment shader and the vertex shader.
- Bytes `8..12` are accessed only by the vertex shader.

To write all twelve bytes requires three `set_push_constants` calls, one for
each range, each passing the matching `stages` mask.
*/
RenderPassSetPushConstants :: proc "c" (
	self: RenderPass,
	stages: ShaderStages,
	offset: u32,
	data: []byte,
) {
	wgpu.RenderPassEncoderSetPushConstants(
		self,
		stages,
		offset,
		cast(u32)len(data),
		raw_data(data),
	)
}

/*
Issue a timestamp command at this point in the queue. The timestamp will be
written to the specified query set, at the specified index.

Must be multiplied by `QueueGetTimestampPeriod` to get the value in
nanoseconds. Absolute values have no meaning, but timestamps can be subtracted
to get the time it takes for a string of operations to complete.
*/
RenderPassWriteTimestamp :: wgpu.RenderPassEncoderWriteTimestamp

/*
Start a occlusion query on this render pass. It can be ended with
`RenderPassEndOcclusionQuery`. Occlusion queries may not be nested.
*/
RenderPassBeginOcclusionQuery :: wgpu.RenderPassEncoderBeginOcclusionQuery

/*
End the occlusion query on this render pass. It can be started with
BeginOcclusionQuery. Occlusion queries may not be nested.
*/
RenderPassEndOcclusionQuery :: wgpu.RenderPassEncoderEndOcclusionQuery

/*
Start a pipeline statistics query on this render pass. It can be ended with
`RenderPassEndPipelineStatisticsQuery`. Pipeline statistics queries may not be nested.
*/
RenderPassBeginPipelineStatisticsQuery :: wgpu.RenderPassEncoderBeginPipelineStatisticsQuery

/*
End the pipeline statistics query on this render pass. It can be started with
`BeginPipelineStatisticsQuery`. Pipeline statistics queries may not be nested.
*/
RenderPassEndPipelineStatisticsQuery :: wgpu.RenderPassEncoderEndPipelineStatisticsQuery

/* Record the end of the render pass. */
RenderPassEnd :: wgpu.RenderPassEncoderEnd

/* Sets a debug label for the given `RenderPass`. */
RenderPassSetLabel :: wgpu.RenderPassEncoderSetLabel

/* Increase the `RenderPass `reference count. */
RenderPassAddRef :: wgpu.RenderPassEncoderAddRef

/* Release the `RenderPass`, use to decrease the reference count. */
RenderPassRelease :: wgpu.RenderPassEncoderRelease

/*
Safely releases the `RenderPass` resources and invalidates the handle. The
procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
RenderPassReleaseSafe :: proc "c" (self: ^RenderPass) {
	if self != nil && self^ != nil {
		wgpu.RenderPassEncoderRelease(self^)
		self^ = nil
	}
}
