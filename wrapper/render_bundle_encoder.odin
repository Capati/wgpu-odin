package wgpu

// Package
import wgpu "../bindings"

// Encodes a series of GPU operations into a reusable "render bundle".
Render_Bundle_Encoder :: struct {
    ptr:          WGPU_Render_Bundle_Encoder,
    using vtable: ^Render_Bundle_Encoder_VTable,
}

@(private)
Render_Bundle_Encoder_VTable :: struct {
    draw:                  proc(
        self: ^Render_Bundle_Encoder,
        vertex_count: u32,
        instance_count: u32 = 1,
        first_vertex: u32 = 0,
        first_instance: u32 = 0,
    ),
    draw_indexed:          proc(
        self: ^Render_Bundle_Encoder,
        index_count: u32,
        instance_count: u32 = 1,
        firstIndex: u32 = 0,
        base_vertex: i32 = 0,
        first_instance: u32 = 0,
    ),
    draw_indexed_indirect: proc(
        self: ^Render_Bundle_Encoder,
        indirect_buffer: Buffer,
        indirect_offset: u64 = 0,
    ),
    draw_indirect:         proc(
        self: ^Render_Bundle_Encoder,
        indirect_buffer: Buffer,
        indirect_offset: u64 = 0,
    ),
    finish:                proc(
        self: ^Render_Bundle_Encoder,
        descriptor: ^Render_Bundle_Descriptor,
    ) -> (
        Render_Bundle,
        Error_Type,
    ),
    insert_debug_marker:   proc(self: ^Render_Bundle_Encoder, marker_label: cstring),
    pop_debug_group:       proc(self: ^Render_Bundle_Encoder),
    push_debug_group:      proc(self: ^Render_Bundle_Encoder, group_label: cstring),
    set_bind_group:        proc(
        self: ^Render_Bundle_Encoder,
        group_index: u32,
        group: ^Bind_Group,
        dynamic_offsets: []u32 = {},
    ),
    set_index_buffer:      proc(
        self: ^Render_Bundle_Encoder,
        buffer: Buffer,
        format: Index_Format,
        offset: u64 = 0,
        size: u64 = Whole_Size,
    ),
    set_label:             proc(self: ^Render_Bundle_Encoder, label: cstring),
    set_pipeline:          proc(self: ^Render_Bundle_Encoder, pipeline: Render_Pipeline),
    set_vertex_buffer:     proc(
        self: ^Render_Bundle_Encoder,
        slot: u32,
        buffer: Buffer,
        offset: u64 = 0,
        size: u64 = Whole_Size,
    ),
    reference:             proc(self: ^Render_Bundle_Encoder),
    release:               proc(self: ^Render_Bundle_Encoder),
}

@(private)
default_render_bundle_encoder_vtable := Render_Bundle_Encoder_VTable {
    draw                  = render_bundle_encoder_draw,
    draw_indexed          = render_bundle_encoder_draw_indexed,
    draw_indexed_indirect = render_bundle_encoder_draw_indexed_indirect,
    draw_indirect         = render_bundle_encoder_draw_indirect,
    finish                = render_bundle_encoder_finish,
    insert_debug_marker   = render_bundle_encoder_insert_debug_marker,
    pop_debug_group       = render_bundle_encoder_pop_debug_group,
    push_debug_group      = render_bundle_encoder_push_debug_group,
    set_bind_group        = render_bundle_encoder_set_bind_group,
    set_index_buffer      = render_bundle_encoder_set_index_buffer,
    set_label             = render_bundle_encoder_set_label,
    set_pipeline          = render_bundle_encoder_set_pipeline,
    set_vertex_buffer     = render_bundle_encoder_set_vertex_buffer,
    reference             = render_bundle_encoder_reference,
    release               = render_bundle_encoder_release,
}

@(private)
default_render_bundle_encoder := Render_Bundle_Encoder {
    ptr    = nil,
    vtable = &default_render_bundle_encoder_vtable,
}

// Draws primitives from the active vertex buffer(s).
render_bundle_encoder_draw :: proc(
    using self: ^Render_Bundle_Encoder,
    vertex_count: u32,
    instance_count: u32 = 1,
    first_vertex: u32 = 0,
    first_instance: u32 = 0,
) {
    wgpu.render_bundle_encoder_draw(
        ptr,
        vertex_count,
        instance_count,
        first_vertex,
        first_instance,
    )
}

// Draws indexed primitives using the active index buffer and the active vertex buffer(s).
render_bundle_encoder_draw_indexed :: proc(
    using self: ^Render_Bundle_Encoder,
    index_count: u32,
    instance_count: u32 = 1,
    firstIndex: u32 = 0,
    base_vertex: i32 = 0,
    first_instance: u32 = 0,
) {
    wgpu.render_bundle_encoder_draw_indexed(
        ptr,
        index_count,
        instance_count,
        firstIndex,
        base_vertex,
        first_instance,
    )
}

render_bundle_encoder_draw_indexed_indirect :: proc(
    using self: ^Render_Bundle_Encoder,
    indirect_buffer: Buffer,
    indirect_offset: u64 = 0,
) {
    wgpu.render_bundle_encoder_draw_indexed_indirect(ptr, indirect_buffer.ptr, indirect_offset)
}

render_bundle_encoder_draw_indirect :: proc(
    using self: ^Render_Bundle_Encoder,
    indirect_buffer: Buffer,
    indirect_offset: u64 = 0,
) {
    wgpu.render_bundle_encoder_draw_indirect(ptr, indirect_buffer.ptr, indirect_offset)
}

render_bundle_encoder_finish :: proc(
    using self: ^Render_Bundle_Encoder,
    descriptor: ^Render_Bundle_Descriptor,
) -> (
    render_bundle: Render_Bundle,
    err: Error_Type,
) {
    desc: wgpu.Render_Bundle_Descriptor

    if descriptor != nil {
        desc.label = descriptor.label
    }

    render_bundle_ptr := wgpu.render_bundle_encoder_finish(ptr, &desc)

    if render_bundle_ptr == nil {
        update_error_message("Failed to acquire RenderBundle")
        return {}, .Unknown
    }

    render_bundle = default_render_bundle
    render_bundle.ptr = render_bundle_ptr

    return
}

render_bundle_encoder_insert_debug_marker :: proc(
    using self: ^Render_Bundle_Encoder,
    marker_label: cstring,
) {
    wgpu.render_bundle_encoder_insert_debug_marker(ptr, marker_label)
}

render_bundle_encoder_pop_debug_group :: proc(using self: ^Render_Bundle_Encoder) {
    wgpu.render_bundle_encoder_pop_debug_group(ptr)
}

render_bundle_encoder_push_debug_group :: proc(
    using self: ^Render_Bundle_Encoder,
    group_label: cstring,
) {
    wgpu.render_bundle_encoder_push_debug_group(ptr, group_label)
}

render_bundle_encoder_set_bind_group :: proc(
    using self: ^Render_Bundle_Encoder,
    group_index: u32,
    group: ^Bind_Group,
    dynamic_offsets: []u32 = {},
) {
    dynamic_offset_count := cast(uint)len(dynamic_offsets)

    if dynamic_offset_count == 0 {
        wgpu.render_bundle_encoder_set_bind_group(ptr, group_index, group.ptr, 0, nil)
    } else {
        wgpu.render_bundle_encoder_set_bind_group(
            ptr,
            group_index,
            group.ptr,
            dynamic_offset_count,
            raw_data(dynamic_offsets),
        )
    }
}

render_bundle_encoder_set_index_buffer :: proc(
    using self: ^Render_Bundle_Encoder,
    buffer: Buffer,
    format: Index_Format,
    offset: u64 = 0,
    size: u64 = Whole_Size,
) {
    wgpu.render_bundle_encoder_set_index_buffer(ptr, buffer.ptr, format, offset, size)
}

// Sets label.
render_bundle_encoder_set_label :: proc(using self: ^Render_Bundle_Encoder, label: cstring) {
    wgpu.render_bundle_encoder_set_label(ptr, label)
}

// Sets the active render pipeline.
render_bundle_encoder_set_pipeline :: proc(
    using self: ^Render_Bundle_Encoder,
    pipeline: Render_Pipeline,
) {
    wgpu.render_bundle_encoder_set_pipeline(ptr, pipeline.ptr)
}

// Assign a vertex buffer to a slot.
render_bundle_encoder_set_vertex_buffer :: proc(
    using self: ^Render_Bundle_Encoder,
    slot: u32,
    buffer: Buffer,
    offset: u64 = 0,
    size: u64 = Whole_Size,
) {
    wgpu.render_bundle_encoder_set_vertex_buffer(ptr, slot, buffer.ptr, offset, size)
}

render_bundle_encoder_reference :: proc(using self: ^Render_Bundle_Encoder) {
    wgpu.render_bundle_encoder_reference(ptr)
}

render_bundle_encoder_release :: proc(using self: ^Render_Bundle_Encoder) {
    wgpu.render_bundle_encoder_release(ptr)
}
