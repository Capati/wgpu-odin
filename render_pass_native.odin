#+build !js
package webgpu

// Vendor
import "vendor:wgpu"

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
Start a pipeline statistics query on this render pass. It can be ended with
`RenderPassEndPipelineStatisticsQuery`. Pipeline statistics queries may not be nested.
*/
RenderPassBeginPipelineStatisticsQuery :: wgpu.RenderPassEncoderBeginPipelineStatisticsQuery

/*
End the pipeline statistics query on this render pass. It can be started with
`BeginPipelineStatisticsQuery`. Pipeline statistics queries may not be nested.
*/
RenderPassEndPipelineStatisticsQuery :: wgpu.RenderPassEncoderEndPipelineStatisticsQuery
