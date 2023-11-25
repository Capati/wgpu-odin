package wgpu

// Core
import "core:runtime"

// Package
import wgpu "../bindings"

Render_Pass_Encoder :: struct {
    ptr:          WGPU_Render_Pass_Encoder,
    err_data:     ^Error_Data,
    using vtable: ^GPU_Render_Pass_VTable,
}

@(private)
GPU_Render_Pass_VTable :: struct {
    begin_occlusion_query:           proc(self: ^Render_Pass_Encoder, query_index: u32),
    begin_pipeline_statistics_query: proc(
        self: ^Render_Pass_Encoder,
        query_set: Query_Set,
        query_index: u32,
    ),
    draw:                            proc(
        self: ^Render_Pass_Encoder,
        vertex_count: u32,
        instance_count: u32 = 1,
        first_vertex: u32 = 0,
        first_instance: u32 = 0,
    ),
    draw_indexed:                    proc(
        self: ^Render_Pass_Encoder,
        index_count: u32,
        instance_count: u32 = 1,
        firstIndex: u32 = 0,
        base_vertex: i32 = 0,
        first_instance: u32 = 0,
    ),
    draw_indexed_indirect:           proc(
        self: ^Render_Pass_Encoder,
        indirect_buffer: Buffer,
        indirect_offset: u64 = 0,
    ),
    draw_indirect:                   proc(
        self: ^Render_Pass_Encoder,
        indirect_buffer: Buffer,
        indirect_offset: u64 = 0,
    ),
    end:                             proc(self: ^Render_Pass_Encoder) -> Error_Type,
    end_occlusion_query:             proc(self: ^Render_Pass_Encoder),
    end_pipeline_statistics_query:   proc(self: ^Render_Pass_Encoder),
    execute_bundles:                 proc(self: ^Render_Pass_Encoder, bundles: ..Render_Bundle),
    insert_debug_marker:             proc(self: ^Render_Pass_Encoder, marker_label: cstring),
    pop_debug_group:                 proc(self: ^Render_Pass_Encoder),
    push_debug_group:                proc(self: ^Render_Pass_Encoder, group_label: cstring),
    set_bind_group:                  proc(
        self: ^Render_Pass_Encoder,
        group_index: u32,
        group: ^Bind_Group,
        dynamic_offsets: []u32 = {},
    ),
    set_blend_constant:              proc(self: ^Render_Pass_Encoder, color: ^Color),
    set_index_buffer:                proc(
        self: ^Render_Pass_Encoder,
        buffer: Buffer,
        format: Index_Format,
        offset: Buffer_Size,
        size: Buffer_Size,
    ),
    set_label:                       proc(self: ^Render_Pass_Encoder, label: cstring),
    set_pipeline:                    proc(self: ^Render_Pass_Encoder, pipeline: ^Render_Pipeline),
    set_scissor_rect:                proc(self: ^Render_Pass_Encoder, x, y, width, height: u32),
    set_stencil_reference:           proc(self: ^Render_Pass_Encoder, reference: u32),
    set_vertex_buffer:               proc(
        self: ^Render_Pass_Encoder,
        slot: u32,
        buffer: Buffer,
        offset: Buffer_Address = 0,
        size: Buffer_Size = Whole_Size,
    ),
    set_viewport:                    proc(
        self: ^Render_Pass_Encoder,
        x, y, width, height, min_depth, max_depth: f32,
    ),
    reference:                       proc(self: ^Render_Pass_Encoder),
    release:                         proc(self: ^Render_Pass_Encoder),
}

@(private)
default_render_pass_encoder_vtable := GPU_Render_Pass_VTable {
    begin_occlusion_query           = render_pass_encoder_begin_occlusion_query,
    begin_pipeline_statistics_query = render_pass_encoder_begin_pipeline_statistics_query,
    draw                            = render_pass_encoder_draw,
    draw_indexed                    = render_pass_encoder_draw_indexed,
    draw_indexed_indirect           = render_pass_encoder_draw_indexed_indirect,
    draw_indirect                   = render_pass_encoder_draw_indirect,
    end                             = render_pass_encoder_end,
    end_occlusion_query             = render_pass_encoder_end_occlusion_query,
    end_pipeline_statistics_query   = render_pass_encoder_end_pipeline_statistics_query,
    execute_bundles                 = render_pass_encoder_execute_bundles,
    insert_debug_marker             = render_pass_encoder_insert_debug_marker,
    pop_debug_group                 = render_pass_encoder_pop_debug_group,
    push_debug_group                = render_pass_encoder_push_debug_group,
    set_bind_group                  = render_pass_encoder_set_bind_group,
    set_blend_constant              = render_pass_encoder_set_blend_constant,
    set_index_buffer                = render_pass_encoder_set_index_buffer,
    set_label                       = render_pass_encoder_set_label,
    set_pipeline                    = render_pass_encoder_set_pipeline,
    set_scissor_rect                = render_pass_encoder_set_scissor_rect,
    set_stencil_reference           = render_pass_encoder_set_stencil_reference,
    set_vertex_buffer               = render_pass_encoder_set_vertex_buffer,
    set_viewport                    = render_pass_encoder_set_viewport,
    reference                       = render_pass_encoder_reference,
    release                         = render_pass_encoder_release,
}

@(private)
default_render_pass_encoder := Render_Pass_Encoder {
    ptr    = nil,
    vtable = &default_render_pass_encoder_vtable,
}

render_pass_encoder_begin_occlusion_query :: proc(
    using self: ^Render_Pass_Encoder,
    query_index: u32,
) {
    wgpu.render_pass_encoder_begin_occlusion_query(ptr, query_index)
}

// Start a pipeline statistics query on this render pass.
render_pass_encoder_begin_pipeline_statistics_query :: proc(
    using self: ^Render_Pass_Encoder,
    query_set: Query_Set,
    query_index: u32,
) {
    wgpu.render_pass_encoder_begin_pipeline_statistics_query(ptr, query_set.ptr, query_index)
}

// Draws primitives from the active vertex buffer(s).
render_pass_encoder_draw :: proc(
    using self: ^Render_Pass_Encoder,
    vertex_count: u32,
    instance_count: u32 = 1,
    first_vertex: u32 = 0,
    first_instance: u32 = 0,
) {
    wgpu.render_pass_encoder_draw(ptr, vertex_count, instance_count, first_vertex, first_instance)
}

// Draws indexed primitives using the active index buffer and the active vertex buffers.
render_pass_encoder_draw_indexed :: proc(
    using self: ^Render_Pass_Encoder,
    index_count: u32,
    instance_count: u32 = 1,
    firstIndex: u32 = 0,
    base_vertex: i32 = 0,
    first_instance: u32 = 0,
) {
    wgpu.render_pass_encoder_draw_indexed(
        ptr,
        index_count,
        instance_count,
        firstIndex,
        base_vertex,
        first_instance,
    )
}

// Draws indexed primitives using the active index buffer and the active vertex buffers,
// based on the contents of the `indirect_buffer`.
render_pass_encoder_draw_indexed_indirect :: proc(
    using self: ^Render_Pass_Encoder,
    indirect_buffer: Buffer,
    indirect_offset: u64 = 0,
) {
    wgpu.render_pass_encoder_draw_indexed_indirect(ptr, indirect_buffer.ptr, indirect_offset)
}

// Draws primitives from the active vertex buffer(s) based on the contents of the
// `indirect_buffer`.
render_pass_encoder_draw_indirect :: proc(
    using self: ^Render_Pass_Encoder,
    indirect_buffer: Buffer,
    indirect_offset: u64 = 0,
) {
    wgpu.render_pass_encoder_draw_indirect(ptr, indirect_buffer.ptr, indirect_offset)
}

// Record the end of the render pass.
render_pass_encoder_end :: proc(using self: ^Render_Pass_Encoder) -> Error_Type {
    err_data.type = .No_Error
    wgpu.render_pass_encoder_end(ptr)

    return err_data.type
}

render_pass_encoder_end_occlusion_query :: proc(using self: ^Render_Pass_Encoder) {
    wgpu.render_pass_encoder_end_occlusion_query(ptr)
}

// End the pipeline statistics query on this render pass. It can be started with
// `begin_pipeline_statistics_query`. Pipeline statistics queries may not be nested.
render_pass_encoder_end_pipeline_statistics_query :: proc(using self: ^Render_Pass_Encoder) {
    wgpu.render_pass_encoder_end_pipeline_statistics_query(ptr)
}

// Execute a render bundle, which is a set of pre-recorded commands that can be run
// together.
render_pass_encoder_execute_bundles :: proc(
    using self: ^Render_Pass_Encoder,
    bundles: ..Render_Bundle,
) {
    bundles_count := cast(uint)len(bundles)

    if bundles_count == 0 {
        wgpu.render_pass_encoder_execute_bundles(ptr, 0, nil)
        return
    } else if bundles_count == 1 {
        wgpu.render_pass_encoder_execute_bundles(ptr, 1, &bundles[0].ptr)
        return
    }

    runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

    bundles_ptrs := make([]wgpu.Render_Bundle, bundles_count, context.temp_allocator)

    for v, i in bundles {
        bundles_ptrs[i] = v.ptr
    }

    wgpu.render_pass_encoder_execute_bundles(ptr, bundles_count, raw_data(bundles_ptrs))
}

// Inserts debug marker.
render_pass_encoder_insert_debug_marker :: proc(
    using self: ^Render_Pass_Encoder,
    marker_label: cstring,
) {
    wgpu.render_pass_encoder_insert_debug_marker(ptr, marker_label)
}

// Stops command recording and creates debug group.
render_pass_encoder_pop_debug_group :: proc(using self: ^Render_Pass_Encoder) {
    wgpu.render_pass_encoder_pop_debug_group(ptr)
}

// Start record commands and group it into debug marker group.
render_pass_encoder_push_debug_group :: proc(
    using self: ^Render_Pass_Encoder,
    group_label: cstring,
) {
    wgpu.render_pass_encoder_push_debug_group(ptr, group_label)
}

// Sets the active bind group for a given bind group index. The bind group layout in the
// active pipeline when any draw() function is called must match the layout of this bind
// group.
render_pass_encoder_set_bind_group :: proc(
    using self: ^Render_Pass_Encoder,
    group_index: u32,
    group: ^Bind_Group,
    dynamic_offsets: []u32 = {},
) {
    dynamic_offset_count := cast(uint)len(dynamic_offsets)

    if dynamic_offset_count == 0 {
        wgpu.render_pass_encoder_set_bind_group(ptr, group_index, group.ptr, 0, nil)
    } else {
        wgpu.render_pass_encoder_set_bind_group(
            ptr,
            group_index,
            group.ptr,
            dynamic_offset_count,
            raw_data(dynamic_offsets),
        )
    }
}

// Sets the blend color as used by some of the blending modes.
render_pass_encoder_set_blend_constant :: proc(using self: ^Render_Pass_Encoder, color: ^Color) {
    wgpu.render_pass_encoder_set_blend_constant(ptr, color)
}

// Sets the active index buffer.
render_pass_encoder_set_index_buffer :: proc(
    using self: ^Render_Pass_Encoder,
    buffer: Buffer,
    format: Index_Format,
    offset: Buffer_Size,
    size: Buffer_Size,
) {
    wgpu.render_pass_encoder_set_index_buffer(ptr, buffer.ptr, format, offset, size)
}

render_pass_encoder_set_label :: proc(using self: ^Render_Pass_Encoder, label: cstring) {
    wgpu.render_pass_encoder_set_label(ptr, label)
}

// Sets the active render pipeline.
render_pass_encoder_set_pipeline :: proc(
    using self: ^Render_Pass_Encoder,
    pipeline: ^Render_Pipeline,
) {
    wgpu.render_pass_encoder_set_pipeline(ptr, pipeline.ptr)
}

// Sets the scissor rectangle used during the rasterization stage. After transformation
// into viewport coordinates.
render_pass_encoder_set_scissor_rect :: proc(
    using self: ^Render_Pass_Encoder,
    x, y, width, height: u32,
) {
    wgpu.render_pass_encoder_set_scissor_rect(ptr, x, y, width, height)
}

render_pass_encoder_set_stencil_reference :: proc(self: ^Render_Pass_Encoder, reference: u32) {
    wgpu.render_pass_encoder_set_stencil_reference(self.ptr, reference)
}

// Assign a vertex buffer to a slot.
render_pass_encoder_set_vertex_buffer :: proc(
    using self: ^Render_Pass_Encoder,
    slot: u32,
    buffer: Buffer,
    offset: Buffer_Address = 0,
    size: Buffer_Size = Whole_Size,
) {
    wgpu.render_pass_encoder_set_vertex_buffer(ptr, slot, buffer.ptr, offset, size)
}

// Sets the viewport used during the rasterization stage to linearly map from normalized
// device coordinates to viewport coordinates.
render_pass_encoder_set_viewport :: proc(
    using self: ^Render_Pass_Encoder,
    x, y, width, height, min_depth, max_depth: f32,
) {
    wgpu.render_pass_encoder_set_viewport(ptr, x, y, width, height, min_depth, max_depth)
}

render_pass_encoder_reference :: proc(using self: ^Render_Pass_Encoder) {
    wgpu.render_pass_encoder_reference(ptr)
}

render_pass_encoder_release :: proc(using self: ^Render_Pass_Encoder) {
    wgpu.render_pass_encoder_release(ptr)
}
