package wgpu

// The raw bindings
import wgpu "../bindings"

/*
In-progress recording of a render pass: a list of render commands in a `Command_Encoder`.

It can be created with `command_encoder_begin_render_pass`, whose `Render_Pass_Descriptor`
specifies the attachments (textures) that will be rendered to.

Most of the methods on `RenderPass` serve one of two purposes, identifiable by their names:

* `draw_*()`: Drawing (that is, encoding a render command, which, when executed by the GPU, will
rasterize something and execute shaders).
* `set_*()`: Setting part of the [render state](https://gpuweb.github.io/gpuweb/#renderstate)
for future drawing commands.

A render pass may contain any number of drawing commands, and before/between each command the
render state may be updated however you wish; each drawing command will be executed using the
render state that has been set when the `draw_*()` function is called.

Corresponds to [WebGPU `GPURenderPassEncoder`](
https://gpuweb.github.io/gpuweb/#render-pass-encoder).
*/
Render_Pass :: wgpu.Render_Pass_Encoder

/*
Start a occlusion query on this render pass. It can be ended with
`render_pass_end_occlusion_query`. Occlusion queries may not be nested.
*/
render_pass_begin_occlusion_query :: wgpu.render_pass_encoder_begin_occlusion_query

/*
Draws primitives from the active vertex buffer(s).

The active vertex buffer(s) can be set with [`render_pass_encoder_set_vertex_buffer`].
Does not use an Index Buffer. If you need this see [`render_pass_encoder_draw_indexed`]

Panics if vertices Range is outside of the range of the vertices range of any set vertex buffer.
*/
render_pass_draw :: proc "contextless" (
	self: Render_Pass,
	vertices: Range(u32),
	instances: Range(u32) = {start = 0, end = 1},
) {
	wgpu.render_pass_encoder_draw(
		self,
		vertices.end - vertices.start,
		instances.end - vertices.start,
		vertices.start,
		instances.start,
	)
}

/* Draws indexed primitives using the active index buffer and the active vertex buffers. */
render_pass_draw_indexed :: proc "contextless" (
	self: Render_Pass,
	indices: Range(u32),
	base_vertex: i32 = 0,
	instances: Range(u32) = {start = 0, end = 1},
) {
	wgpu.render_pass_encoder_draw_indexed(
		self,
		indices.end - indices.start,
		instances.end - indices.start,
		indices.start,
		base_vertex,
		instances.start,
	)
}

/*
Draws indexed primitives using the active index buffer and the active vertex buffers,
based on the contents of the `indirect_buffer`.
*/
render_pass_draw_indexed_indirect :: proc "contextless" (
	self: Render_Pass,
	indirect_buffer: Buffer,
	indirect_offset: Buffer_Address = 0,
) {
	wgpu.render_pass_encoder_draw_indexed_indirect(self, indirect_buffer, indirect_offset)
}

/*
Draws primitives from the active vertex buffer(s) based on the contents of the `indirect_buffer`.
*/
render_pass_draw_indirect :: proc "contextless" (
	self: Render_Pass,
	indirect_buffer: Buffer,
	indirect_offset: Buffer_Address = 0,
) {
	wgpu.render_pass_encoder_draw_indirect(self, indirect_buffer, indirect_offset)
}

/* Record the end of the render pass. */
render_pass_end :: proc "contextless" (
	self: Render_Pass,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	_error_reset_data(loc)
	wgpu.render_pass_encoder_end(self)
	return get_last_error() == nil
}

/*
End the occlusion query on this render pass. It can be started with begin_occlusion_query.
Occlusion queries may not be nested.
*/
render_pass_end_occlusion_query :: wgpu.render_pass_encoder_end_occlusion_query

/*
Execute a render bundle, which is a set of pre-recorded commands that can be run
together.
*/
render_pass_execute_bundles :: proc "contextless" (
	self: Render_Pass,
	bundles: ..Render_Bundle,
) {
	if len(bundles) == 0 {
		wgpu.render_pass_encoder_execute_bundles(self, 0, nil)
		return
	} else if len(bundles) == 1 {
		wgpu.render_pass_encoder_execute_bundles(self, 1, &bundles[0])
		return
	}

	wgpu.render_pass_encoder_execute_bundles(self, uint(len(bundles)), raw_data(bundles))
}

/* Inserts debug marker. */
render_pass_insert_debug_marker :: wgpu.render_pass_encoder_insert_debug_marker

/* Stops command recording and creates debug group. */
render_pass_pop_debug_group :: wgpu.render_pass_encoder_pop_debug_group

/* Start record commands and group it into debug marker group. */
render_pass_push_debug_group :: wgpu.render_pass_encoder_push_debug_group

/*
Sets the active bind group for a given bind group index. The bind group layout in the
active pipeline when any draw() function is called must match the layout of this bind
group.
*/
render_pass_set_bind_group :: proc "contextless" (
	self: Render_Pass,
	group_index: u32,
	group: Bind_Group,
	dynamic_offsets: []u32 = nil,
) {
	wgpu.render_pass_encoder_set_bind_group(
		self,
		group_index,
		group,
		len(dynamic_offsets),
		raw_data(dynamic_offsets),
	)
}

/* Sets the blend color as used by some of the blending modes. */
render_pass_set_blend_constant :: proc "contextless" (self: Render_Pass, color: Color) {
	color := color
	wgpu.render_pass_encoder_set_blend_constant(self, &color)
}

/* Sets the active index buffer. */
render_pass_set_index_buffer :: proc "contextless" (
	self: Render_Pass,
	buffer: Buffer,
	index_format: Index_Format,
	range: Buffer_Range = {},
) {
	wgpu.render_pass_encoder_set_index_buffer(
		self,
		buffer,
		index_format,
		range.offset,
		range.size if range.size > 0 else WHOLE_SIZE,
	)
}

/* Set debug label. */
render_pass_set_label :: wgpu.render_pass_encoder_set_label

/* Sets the active render pipeline. */
render_pass_set_pipeline :: wgpu.render_pass_encoder_set_pipeline

/*
Sets the scissor rectangle used during the rasterization stage.
After transformation into [viewport coordinates](https://www.w3.org/TR/webgpu/#viewport-coordinates).

Subsequent draw calls will discard any fragments which fall outside the scissor rectangle.
If this method has not been called, the scissor rectangle defaults to the entire bounds of
the render targets.

The function of the scissor rectangle resembles [`set_viewport()`](Self::set_viewport),
but it does not affect the coordinate system, only which fragments are discarded.
*/
render_pass_set_scissor_rect :: wgpu.render_pass_encoder_set_scissor_rect

/*
Sets the stencil reference.

Subsequent stencil tests will test against this value. If this procedure has not been called,
the  stencil reference value defaults to `0`.
*/
render_pass_set_stencil_reference :: wgpu.render_pass_encoder_set_stencil_reference

/* Assign a vertex buffer to a slot. */
render_pass_set_vertex_buffer :: proc "contextless" (
	self: Render_Pass,
	slot: u32,
	buffer: Buffer,
	range: Buffer_Range = {},
) {
	wgpu.render_pass_encoder_set_vertex_buffer(
		self,
		slot,
		buffer,
		range.offset,
		range.size if range.size > 0 else WHOLE_SIZE,
	)
}

/*
Sets the viewport used during the rasterization stage to linearly map from normalized
device coordinates to viewport coordinates.
*/
render_pass_set_viewport :: wgpu.render_pass_encoder_set_viewport

/* Increase the reference count. */
render_pass_reference :: wgpu.render_pass_encoder_reference

/* Release the `Render_Pass`. */
render_pass_release :: wgpu.render_pass_encoder_release

/*
Set push constant data for subsequent draw calls.

Write the bytes in `data` at offset `offset` within push constant storage, all of which are
accessible by all the pipeline stages in `stages`, and no others. Both `offset` and the length
of `data` must be multiples of `PUSH_CONSTANT_ALIGNMENT`, which is always `4`.
*/
render_pass_set_push_constants :: proc "contextless" (
	self: Render_Pass,
	stages: Shader_Stage_Flags,
	offset: u32,
	data: []byte,
) {
	if len(data) == 0 {
		wgpu.render_pass_encoder_set_push_constants(self, stages, offset, 0, nil)
		return
	}

	wgpu.render_pass_encoder_set_push_constants(
		self,
		stages,
		offset,
		cast(u32)len(data),
		raw_data(data),
	)
}

render_pass_multi_draw_indirect :: proc "contextless" (
	self: Render_Pass,
	buffer: Buffer,
	offset: u64,
	count: u32,
) {
	wgpu.render_pass_encoder_multi_draw_indirect(self, buffer, offset, count)
}

render_pass_multi_draw_indexed_indirect :: proc "contextless" (
	self: Render_Pass,
	buffer: Buffer,
	offset: u64,
	count: u32,
) {
	wgpu.render_pass_encoder_multi_draw_indexed_indirect(self, buffer, offset, count)
}

render_pass_multi_draw_indirect_count :: proc "contextless" (
	self: Render_Pass,
	buffer: Buffer,
	offset: u64,
	count_buffer: Buffer,
	count_buffer_offset, max_count: u32,
) {
	wgpu.render_pass_encoder_multi_draw_indirect_count(
		self,
		buffer,
		offset,
		count_buffer,
		count_buffer_offset,
		max_count,
	)
}

render_pass_multi_draw_indexed_indirect_count :: proc "contextless" (
	self: Render_Pass,
	buffer: Buffer,
	offset: u64,
	count_buffer: Buffer,
	count_buffer_offset, max_count: u32,
) {
	wgpu.render_pass_encoder_multi_draw_indexed_indirect_count(
		self,
		buffer,
		offset,
		count_buffer,
		count_buffer_offset,
		max_count,
	)
}

/*
Start a pipeline statistics query on this render pass. It can be ended with
`render_pass_end_pipeline_statistics_query`. Pipeline statistics queries may not be nested.
*/
render_pass_begin_pipeline_statistics_query ::
	wgpu.render_pass_encoder_begin_pipeline_statistics_query

/*
End the pipeline statistics query on this render pass. It can be started with
`begin_pipeline_statistics_query`. Pipeline statistics queries may not be nested.
*/
render_pass_end_pipeline_statistics_query ::
	wgpu.render_pass_encoder_end_pipeline_statistics_query
