package wgpu

// Package
import wgpu "../bindings"

Render_Pass_Encoder :: struct {
    ptr:          WGPU_Render_Pass_Encoder,
    using vtable: ^GPU_Render_Pass_VTable,
}

@(private)
GPU_Render_Pass_VTable :: struct {
    begin_occlusion_query:           proc(self: ^Render_Pass_Encoder),
    begin_pipeline_statistics_query: proc(self: ^Render_Pass_Encoder),
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
    draw_indexed_indirect:           proc(self: ^Render_Pass_Encoder),
    draw_indirect:                   proc(self: ^Render_Pass_Encoder),
    end:                             proc(self: ^Render_Pass_Encoder),
    end_occlusion_query:             proc(self: ^Render_Pass_Encoder),
    end_pipeline_statistics_query:   proc(self: ^Render_Pass_Encoder),
    execute_bundles:                 proc(
        self: ^Render_Pass_Encoder,
        bundles: []WGPU_Render_Bundle,
    ),
    insert_debug_marker:             proc(self: ^Render_Pass_Encoder),
    pop_debug_group:                 proc(self: ^Render_Pass_Encoder),
    push_debug_group:                proc(self: ^Render_Pass_Encoder),
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
    set_label:                       proc(self: ^Render_Pass_Encoder),
    set_pipeline:                    proc(
        self: ^Render_Pass_Encoder,
        pipeline: ^Render_Pipeline,
    ),
    set_scissor_rect:                proc(
        self: ^Render_Pass_Encoder,
        x, y, width, height: u32,
    ),
    set_stencil_reference:           proc(self: ^Render_Pass_Encoder),
    set_vertex_buffer:               proc(
        self: ^Render_Pass_Encoder,
        slot: u32,
        buffer: Buffer,
        offset: Buffer_Address = 0,
        size: Buffer_Size = Whole_Size,
    ),
    set_viewport:                    proc(self: ^Render_Pass_Encoder),
    release:                         proc(self: ^Render_Pass_Encoder),
}

@(private)
default_render_pass_encoder_vtable := GPU_Render_Pass_VTable {
    draw               = render_pass_draw,
    draw_indexed       = render_pass_draw_indexed,
    end                = render_pass_end,
    set_bind_group     = render_pass_set_bind_group,
    set_blend_constant = render_pass_set_blend_constant,
    execute_bundles    = render_pass_execute_bundles,
    set_index_buffer   = render_pass_set_index_buffer,
    set_pipeline       = render_pass_set_pipeline,
    set_scissor_rect   = render_pass_set_scissor_rect,
    set_vertex_buffer  = render_pass_set_vertex_buffer,
    release            = render_pass_release,
}

@(private)
default_render_pass_encoder := Render_Pass_Encoder {
    ptr    = nil,
    vtable = &default_render_pass_encoder_vtable,
}

// Draws indexed primitives using the active index buffer and the active vertex buffers.
render_pass_draw_indexed :: proc(
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

// Draws primitives from the active vertex buffer(s).
render_pass_draw :: proc(
    using self: ^Render_Pass_Encoder,
    vertex_count: u32,
    instance_count: u32 = 1,
    first_vertex: u32 = 0,
    first_instance: u32 = 0,
) {
    wgpu.render_pass_encoder_draw(
        ptr,
        vertex_count,
        instance_count,
        first_vertex,
        first_instance,
    )
}

// Record the end of the render pass.
render_pass_end :: proc(using self: ^Render_Pass_Encoder) {
    wgpu.render_pass_encoder_end(ptr)
}

render_pass_set_bind_group :: proc(
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

render_pass_set_blend_constant :: proc(using self: ^Render_Pass_Encoder, color: ^Color) {
    wgpu.render_pass_encoder_set_blend_constant(ptr, color)
}

render_pass_execute_bundles :: proc(
    using self: ^Render_Pass_Encoder,
    bundles: []WGPU_Render_Bundle,
) {
    wgpu.render_pass_encoder_execute_bundles(ptr, len(bundles), raw_data(bundles))
}

// Sets the active index buffer.
render_pass_set_index_buffer :: proc(
    using self: ^Render_Pass_Encoder,
    buffer: Buffer,
    format: Index_Format,
    offset: Buffer_Size,
    size: Buffer_Size,
) {
    wgpu.render_pass_encoder_set_index_buffer(ptr, buffer.ptr, format, offset, size)
}

// Sets the active render pipeline.
render_pass_set_pipeline :: proc(
    using self: ^Render_Pass_Encoder,
    pipeline: ^Render_Pipeline,
) {
    wgpu.render_pass_encoder_set_pipeline(ptr, pipeline.ptr)
}

render_pass_set_scissor_rect :: proc(
    using self: ^Render_Pass_Encoder,
    x, y, width, height: u32,
) {
    wgpu.render_pass_encoder_set_scissor_rect(ptr, x, y, width, height)
}

// Assign a vertex buffer to a slot.
render_pass_set_vertex_buffer :: proc(
    using self: ^Render_Pass_Encoder,
    slot: u32,
    buffer: Buffer,
    offset: Buffer_Address = 0,
    size: Buffer_Size = Whole_Size,
) {
    wgpu.render_pass_encoder_set_vertex_buffer(ptr, slot, buffer.ptr, offset, size)
}

render_pass_release :: proc(using self: ^Render_Pass_Encoder) {
    wgpu.render_pass_encoder_release(ptr)
}
