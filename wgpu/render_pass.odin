package wgpu

/*
In-progress recording of a render pass: a list of render commands in a `CommandEncoder`.

It can be created with `command_encoder_begin_render_pass`, whose `RenderPassDescriptor`
specifies the attachments (textures) that will be rendered to.

Most of the procedures for `RenderPass` serve one of two purposes, identifiable by their names:

* `draw_*()`: Drawing (that is, encoding a render command, which, when executed by the GPU, will
rasterize something and execute shaders).
* `set_*()`: Setting part of the [render state](https://gpuweb.github.io/gpuweb/#renderstate)
for future drawing commands.

A render pass may contain any number of drawing commands, and before/between each command the
render state may be updated however you wish; each drawing command will be executed using the
render state that has been set when the `draw_*()` procedure is called.

Corresponds to [WebGPU `GPURenderPassEncoder`](
https://gpuweb.github.io/gpuweb/#render-pass-encoder).
*/
RenderPass :: distinct rawptr

/*
Operation to perform to the output attachment at the start of a render pass.

Corresponds to [WebGPU `GPULoadOp`](https://gpuweb.github.io/gpuweb/#enumdef-gpuloadop),
plus the corresponding `clear_value`.
*/
LoadOp :: enum i32 {
	Undefined = 0x00000000,
	Load      = 0x00000001,
	Clear     = 0x00000002,
}

/*
Operation to perform to the output attachment at the end of a render pass.

Corresponds to [WebGPU `GPUStoreOp`](https://gpuweb.github.io/gpuweb/#enumdef-gpustoreop).
*/
StoreOp :: enum i32 {
	Undefined = 0x00000000,
	Store     = 0x00000001,
	Discard   = 0x00000002,
}

/*
Pair of load and store operations for an attachment aspect.

This type is unique to the Rust API of `wgpu`. In the WebGPU specification,
separate `loadOp` and `storeOp` fields are used instead.
*/
Operations :: struct($T: typeid) {
	load:        LoadOp,
	store:       StoreOp,
	clear_value: T, /* For use with LoadOp.Clear */
}

/*
Describes the timestamp writes of a render pass.

For use with `RenderPassDescriptor`.
At least one of `beginning_of_pass_write_index` and `end_of_pass_write_index` must be valid.

Corresponds to [WebGPU `GPURenderPassTimestampWrite`](
https://gpuweb.github.io/gpuweb/#dictdef-gpurenderpasstimestampwrites).
*/
RenderPassTimestampWrites :: struct {
	query_set:                     QuerySet,
	beginning_of_pass_write_index: u32,
	end_of_pass_write_index:       u32,
}

/*
Describes a color attachment to a `RenderPass`.

For use with `RenderPassDescriptor`.

Corresponds to [WebGPU `GPURenderPassColorAttachment`](
https://gpuweb.github.io/gpuweb/#color-attachments).
*/
RenderPassColorAttachment :: struct {
	view:           TextureView,
	resolve_target: TextureView,
	ops:            Operations(Color),
}

/*
Describes a depth/stencil attachment to a `RenderPass`.

For use with `RenderPassDescriptor`.

Corresponds to [WebGPU `GPURenderPassDepthStencilAttachment`](
https://gpuweb.github.io/gpuweb/#depth-stencil-attachments).
*/
RenderPassDepthStencilAttachment :: struct {
	view:                TextureView,
	depth_load_op:       LoadOp,
	depth_store_op:      StoreOp,
	depth_clear_value:   f32,
	depth_read_only:     b32,
	stencil_load_op:     LoadOp,
	stencil_store_op:    StoreOp,
	stencil_clear_value: u32,
	stencil_read_only:   b32,
}

// RenderPassDepthStencilAttachment :: struct {
// 	view:              TextureView,
// 	depth_read_only:   bool,
// 	depth_ops:         Operations(f32),
// 	stencil_read_only: bool,
// 	stencil_ops:       Operations(u32),
// }

/*
Describes the attachments of a render pass.

For use with `command_encoder_begin_render_pass`.

Corresponds to [WebGPU `GPURenderPassDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpurenderpassdescriptor).
*/
RenderPassDescriptor :: struct {
	label:                    string,
	color_attachments:        []RenderPassColorAttachment,
	depth_stencil_attachment: ^RenderPassDepthStencilAttachment,
	timestamp_writes:         RenderPassTimestampWrites,
	occlusion_query_set:      QuerySet,
	/* Extras */
	max_draw_count:           u64,
}

/*
Sets the active bind group for a given bind group index. The bind group layout
in the active pipeline when any `draw_*()` procedure is called must match the layout of
this bind group.

If the bind group have dynamic offsets, provide them in binding order.
These offsets have to be aligned to `Limits.min_uniform_buffer_offset_alignment`
or `Limits.min_storage_buffer_offset_alignment` appropriately.

Subsequent draw calls’ shader executions will be able to access data in these bind groups.
*/
render_pass_set_bind_group :: proc "contextless" (
	self: RenderPass,
	index: u32,
	bind_group: BindGroup,
	offsets: []u32 = nil,
) {
	wgpuRenderPassEncoderSetBindGroup(self, index, bind_group, len(offsets), raw_data(offsets))
}

/*
Sets the active render pipeline.

Subsequent draw calls will exhibit the behavior defined by `pipeline`.
*/
render_pass_set_pipeline :: wgpuRenderPassEncoderSetPipeline

/*
Sets the blend color as used by some of the blending modes.

Subsequent blending tests will test against this value.
If this procedure has not been called, the blend constant defaults to `COLOR_TRANSPARENT`
(all components zero).
*/
render_pass_set_blend_constant :: proc "contextless" (
	self: RenderPass,
	color: Color = COLOR_TRANSPARENT,
) {
	wgpuRenderPassEncoderSetBlendConstant(self, color)
}

/*
Sets the active index buffer.

Subsequent calls to `render_pass_draw_indexed` on this `RenderPass` will
use `buffer` as the source index buffer.
*/
render_pass_set_index_buffer :: proc "contextless" (
	self: RenderPass,
	buffer_slice: BufferSlice,
	index_format: IndexFormat,
) {
	wgpuRenderPassEncoderSetIndexBuffer(
		self,
		buffer_slice.buffer,
		index_format,
		buffer_slice.offset,
		buffer_slice.size if buffer_slice.size > 0 else WHOLE_SIZE,
	)
}

/*
Assign a vertex buffer to a slot.

Subsequent calls to `render_pass_draw` and `render_pass_draw_indexed` on this
`RenderPass` will use `buffer` as one of the source vertex buffers.

The `slot` refers to the index of the matching descriptor in `VertexState::buffers`.
*/
render_pass_set_vertex_buffer :: proc "contextless" (
	self: RenderPass,
	slot: u32,
	buffer_slice: BufferSlice,
) {
	wgpuRenderPassEncoderSetVertexBuffer(
		self,
		slot,
		buffer_slice.buffer,
		buffer_slice.offset,
		buffer_slice.size if buffer_slice.size > 0 else WHOLE_SIZE,
	)
}

/*
Sets the scissor rectangle used during the rasterization stage.
After transformation into [viewport coordinates](https://www.w3.org/TR/webgpu/#viewport-coordinates).

Subsequent draw calls will discard any fragments which fall outside the scissor rectangle.
If this procedure has not been called, the scissor rectangle defaults to the entire bounds of
the render targets.

The procedure of the scissor rectangle resembles [`set_viewport()`](Self::set_viewport),
but it does not affect the coordinate system, only which fragments are discarded.
*/
render_pass_set_scissor_rect :: wgpuRenderPassEncoderSetScissorRect

/*
Sets the viewport used during the rasterization stage to linearly map from normalized
device coordinates to viewport coordinates.
*/
render_pass_set_viewport :: wgpuRenderPassEncoderSetViewport

/*
Sets the stencil reference.

Subsequent stencil tests will test against this value. If this procedure has not been called,
the  stencil reference value defaults to `0`.
*/
render_pass_set_stencil_reference :: wgpuRenderPassEncoderSetStencilReference

/* Inserts debug marker. */
render_pass_insert_debug_marker :: proc(
	self: RenderPass,
	label: string,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	when ODIN_DEBUG {
		error_reset_data(loc)
		c_label: StringViewBuffer
		wgpuRenderPassEncoderInsertDebugMarker(
			self,
			init_string_buffer(&c_label, label) if label != "" else {},
		)
		return has_no_error()
	} else {
		return true
	}
}

/* Start record commands and group it into debug marker group. */
render_pass_push_debug_group :: proc(
	self: RenderPass,
	label: string,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	when ODIN_DEBUG {
		error_reset_data(loc)
		c_label: StringViewBuffer
		wgpuRenderPassEncoderPushDebugGroup(
			self,
			init_string_buffer(&c_label, label) if label != "" else {},
		)
		return has_no_error()
	} else {
		return true
	}
}

/* Stops command recording and creates debug group. */
render_pass_pop_debug_group :: proc "contextless" (
	self: RenderPass,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	when ODIN_DEBUG {
		error_reset_data(loc)
		wgpuRenderPassEncoderPopDebugGroup(self)
		return has_no_error()
	} else {
		return true
	}
}

/*
Draws primitives from the active vertex buffer(s).

The active vertex buffer(s) can be set with [`render_pass_encoder_set_vertex_buffer`].
Does not use an Index Buffer. If you need this see [`render_pass_encoder_draw_indexed`]

Panics if vertices Range is outside of the range of the vertices range of any set vertex buffer.

This drawing command uses the current render state, as set by preceding `set_*()` procedures.
It is not affected by changes to the state that are performed after it is called.
*/
render_pass_draw :: proc "contextless" (
	self: RenderPass,
	vertices: Range(u32),
	instances: Range(u32) = {start = 0, end = 1},
) {
	wgpuRenderPassEncoderDraw(
		self,
		vertices.end - vertices.start,
		instances.end - instances.start,
		vertices.start,
		instances.start,
	)
}

/*
Draws indexed primitives using the active index buffer and the active vertex buffers.

The active index buffer can be set with `render_pass_set_index_buffer`
The active vertex buffers can be set with `render_pass_set_vertex_buffer`.

Panics if indices Range is outside of the range of the indices range of any set index buffer.

This drawing command uses the current render state, as set by preceding `set_*()` procedures.
It is not affected by changes to the state that are performed after it is called.
*/
render_pass_draw_indexed :: proc "contextless" (
	self: RenderPass,
	indices: Range(u32),
	base_vertex: i32 = 0,
	instances: Range(u32) = {start = 0, end = 1},
) {
	wgpuRenderPassEncoderDrawIndexed(
		self,
		indices.end - indices.start,
		instances.end - instances.start,
		indices.start,
		base_vertex,
		instances.start,
	)
}

/*
Draws primitives from the active vertex buffer(s) based on the contents of the `indirect_buffer`.

This is like calling `render_pass_draw` but the contents of the call are specified in the `indirect_buffer`.
*/
render_pass_draw_indirect :: proc "contextless" (
	self: RenderPass,
	indirect_buffer: Buffer,
	indirect_offset: BufferAddress = 0,
) {
	wgpuRenderPassEncoderDrawIndirect(self, indirect_buffer, indirect_offset)
}

/*
Draws indexed primitives using the active index buffer and the active vertex buffers,
based on the contents of the `indirect_buffer`.
*/
render_pass_draw_indexed_indirect :: proc "contextless" (
	self: RenderPass,
	indirect_buffer: Buffer,
	indirect_offset: BufferAddress = 0,
) {
	wgpuRenderPassEncoderDrawIndexedIndirect(self, indirect_buffer, indirect_offset)
}

/*
Execute a render bundle, which is a set of pre-recorded commands that can be run together.

Commands in the bundle do not inherit this render pass's current render state, and after the
bundle has executed, the state is **cleared** (reset to defaults, not the previous state).
*/
render_pass_execute_bundles :: proc "contextless" (self: RenderPass, bundles: ..RenderBundle) {
	if len(bundles) == 0 {
		wgpuRenderPassEncoderExecuteBundles(self, 0, nil)
		return
	}
	wgpuRenderPassEncoderExecuteBundles(self, uint(len(bundles)), raw_data(bundles))
}

/*
Dispatches multiple draw calls from the active vertex buffer(s) based on the contents of the
`indirect_buffer`. `count` draw calls are issued.

The active vertex buffers can be set with `render_pass_set_vertex_buffer`.

This drawing command uses the current render state, as set by preceding `set_*()` procedures.
It is not affected by changes to the state that are performed after it is called.
*/
render_pass_multi_draw_indirect :: proc "contextless" (
	self: RenderPass,
	indirect_buffer: Buffer,
	indirect_offset: BufferAddress,
	count: u32,
) {
	wgpuRenderPassEncoderMultiDrawIndirect(self, indirect_buffer, indirect_offset, count)
}

/*
Dispatches multiple draw calls from the active index buffer and the active vertex buffers,
based on the contents of the `indirect_buffer`. `count` draw calls are issued.

The active index buffer can be set with `render_pass_set_index_buffer`, while the active
vertex buffers can be set with `render_pass_set_vertex_buffer`.

This drawing command uses the current render state, as set by preceding `set_*()` procedures.
It is not affected by changes to the state that are performed after it is called.
*/
render_pass_multi_draw_indexed_indirect :: proc "contextless" (
	self: RenderPass,
	indirect_buffer: Buffer,
	indirect_offset: BufferAddress,
	count: u32,
) {
	wgpuRenderPassEncoderMultiDrawIndexedIndirect(self, indirect_buffer, indirect_offset, count)
}

/*
Dispatches multiple draw calls from the active vertex buffer(s) based on the contents of the
`indirect_buffer`. The count buffer is read to determine how many draws to issue.

The indirect buffer must be long enough to account for `max_count` draws, however only `count`
draws will be read. If `count` is greater than `max_count`, `max_count` will be used.

The active vertex buffers can be set with `render_pass_set_vertex_buffer`.

This drawing command uses the current render state, as set by preceding `set_*()` procedures.
It is not affected by changes to the state that are performed after it is called.
*/
render_pass_multi_draw_indirect_count :: proc "contextless" (
	self: RenderPass,
	indirect_buffer: Buffer,
	indirect_offset: BufferAddress,
	count_buffer: Buffer,
	count_offset: BufferAddress,
	max_count: u32,
) {
	wgpuRenderPassEncoderMultiDrawIndirectCount(
		self,
		indirect_buffer,
		indirect_offset,
		count_buffer,
		count_offset,
		max_count,
	)
}

/*
Dispatches multiple draw calls from the active index buffer and the active vertex buffers,
based on the contents of the `indirect_buffer`. The count buffer is read to determine how many
draws to issue.

The indirect buffer must be long enough to account for `max_count` draws, however only `count`
draws will be read. If `count` is greater than `max_count`, `max_count` will be used.

The active index buffer can be set with `render_pass_set_index_buffer`, while the active
vertex buffers can be set with `render_pass_set_vertex_buffer`.

This drawing command uses the current render state, as set by preceding `set_*()` procedures.
It is not affected by changes to the state that are performed after it is called.
*/
render_pass_multi_draw_indexed_indirect_count :: proc "contextless" (
	self: RenderPass,
	indirect_buffer: Buffer,
	indirect_offset: BufferAddress,
	count_buffer: Buffer,
	count_offset: BufferAddress,
	max_count: u32,
) {
	wgpuRenderPassEncoderMultiDrawIndexedIndirectCount(
		self,
		indirect_buffer,
		indirect_offset,
		count_buffer,
		count_offset,
		max_count,
	)
}

/*
Set push constant data for subsequent draw calls.

Write the bytes in `data` at offset `offset` within push constant
storage, all of which are accessible by all the pipeline stages in
`stages`, and no others.  Both `offset` and the length of `data` must be
multiples of `PUSH_CONSTANT_ALIGNMENT`, which is always 4.

For example, if `offset` is `4` and `data` is eight bytes long, this
call will write `data` to bytes `4..12` of push constant storage.

**Stage matching**

Every byte in the affected range of push constant storage must be
accessible to exactly the same set of pipeline stages, which must match
`stages`. If there are two bytes of storage that are accessible by
different sets of pipeline stages - say, one is accessible by fragment
shaders, and the other is accessible by both fragment shaders and vertex
shaders - then no single `set_push_constants` call may affect both of
them; to write both, you must make multiple calls, each with the
appropriate `stages` value.

Which pipeline stages may access a given byte is determined by the
pipeline's `PushConstant` global variable and (if it is a struct) its
members' offsets.

For example, suppose you have twelve bytes of push constant storage,
where bytes `0..8` are accessed by the vertex shader, and bytes `4..12`
are accessed by the fragment shader. This means there are three byte
ranges each accessed by a different set of stages:

- Bytes `0..4` are accessed only by the fragment shader.

- Bytes `4..8` are accessed by both the fragment shader and the vertex shader.

- Bytes `8..12` are accessed only by the vertex shader.

To write all twelve bytes requires three `set_push_constants` calls, one
for each range, each passing the matching `stages` mask.
*/
render_pass_set_push_constants :: proc "contextless" (
	self: RenderPass,
	stages: ShaderStages,
	offset: u32,
	data: []byte,
) {
	wgpuRenderPassEncoderSetPushConstants(self, stages, offset, cast(u32)len(data), raw_data(data))
}

/*
Issue a timestamp command at this point in the queue. The
timestamp will be written to the specified query set, at the specified index.

Must be multiplied by `queue_get_timestamp_period` to get
the value in nanoseconds. Absolute values have no meaning,
but timestamps can be subtracted to get the time it takes
for a string of operations to complete.
*/
render_pass_write_timestamp :: wgpuRenderPassEncoderWriteTimestamp

/*
Start a occlusion query on this render pass. It can be ended with
`render_pass_end_occlusion_query`. Occlusion queries may not be nested.
*/
render_pass_begin_occlusion_query :: wgpuRenderPassEncoderBeginOcclusionQuery

/*
End the occlusion query on this render pass. It can be started with begin_occlusion_query.
Occlusion queries may not be nested.
*/
render_pass_end_occlusion_query :: wgpuRenderPassEncoderEndOcclusionQuery

/*
Start a pipeline statistics query on this render pass. It can be ended with
`render_pass_end_pipeline_statistics_query`. Pipeline statistics queries may not be nested.
*/
render_pass_begin_pipeline_statistics_query :: wgpuRenderPassEncoderBeginPipelineStatisticsQuery

/*
End the pipeline statistics query on this render pass. It can be started with
`begin_pipeline_statistics_query`. Pipeline statistics queries may not be nested.
*/
render_pass_end_pipeline_statistics_query :: wgpuRenderPassEncoderEndPipelineStatisticsQuery

/* Record the end of the render pass. */
render_pass_end :: proc "contextless" (self: RenderPass, loc := #caller_location) -> (ok: bool) {
	error_reset_data(loc)
	wgpuRenderPassEncoderEnd(self)
	return has_no_error()
}

/* Sets a debug label for the given `RenderPass`. */
@(disabled = !ODIN_DEBUG)
render_pass_set_label :: proc(self: RenderPass, label: string) {
	c_label: StringViewBuffer
	wgpuRenderPassEncoderSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the `RenderPass `reference count. */
render_pass_add_ref :: wgpuRenderPassEncoderAddRef

/* Release the `RenderPass`, use to decrease the reference count. */
render_pass_release :: wgpuRenderPassEncoderRelease

/*
Safely releases the `RenderPass` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
render_pass_release_safe :: #force_inline proc(self: ^RenderPass) {
	if self != nil && self^ != nil {
		wgpuRenderPassEncoderRelease(self^)
		self^ = nil
	}
}

@(private)
WGPURenderPassColorAttachment :: struct {
	next_in_chain:  ^ChainedStruct,
	view:           TextureView,
	depth_slice:    u32,
	resolve_target: TextureView,
	load_op:        LoadOp,
	store_op:       StoreOp,
	clear_value:    WGPUColor,
}

@(private)
WGPURenderPassDepthStencilAttachment :: struct {
	view:                TextureView,
	depth_load_op:       LoadOp,
	depth_store_op:      StoreOp,
	depth_clear_value:   f32,
	depth_read_only:     b32,
	stencil_load_op:     LoadOp,
	stencil_store_op:    StoreOp,
	stencil_clear_value: u32,
	stencil_read_only:   b32,
}
