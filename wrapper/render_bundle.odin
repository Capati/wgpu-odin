package wgpu

// Package
import wgpu "../bindings"

Render_Bundle_Encoder :: struct {
    ptr:          WGPU_Render_Bundle_Encoder,
    using vtable: ^GPU_Render_Bundle_Encoder_VTable,
}

@(private)
GPU_Render_Bundle_Encoder_VTable :: struct {
    draw:              proc(
        self: ^Render_Bundle_Encoder,
        vertex_count: u32,
        instance_count: u32 = 1,
        first_vertex: u32 = 0,
        first_instance: u32 = 0,
    ),
    finish:            proc(self: ^Render_Bundle_Encoder) -> WGPU_Render_Bundle,
    set_label:         proc(self: ^Render_Bundle_Encoder, label: cstring),
    set_pipeline:      proc(self: ^Render_Bundle_Encoder, pipeline: Render_Pipeline),
    set_vertex_buffer: proc(
        self: ^Render_Bundle_Encoder,
        slot: u32,
        buffer: Buffer,
        offset: Buffer_Size = 0,
    ),
    reference:         proc(self: ^Render_Bundle_Encoder),
    release:           proc(self: ^Render_Bundle_Encoder),
}

@(private)
default_render_bundle_vtable := GPU_Render_Bundle_Encoder_VTable {
    draw              = render_bundle_draw,
    finish            = render_bundle_finish,
    set_label         = render_bundle_set_label,
    set_pipeline      = render_bundle_set_pipeline,
    set_vertex_buffer = render_bundle_set_vertex_buffer,
    reference         = render_bundle_reference,
    release           = render_bundle_release,
}

@(private)
default_render_bundle_encoder := Render_Bundle_Encoder {
    ptr    = nil,
    vtable = &default_render_bundle_vtable,
}

// Draws primitives from the active vertex buffer(s).
render_bundle_draw :: proc(
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

render_bundle_finish :: proc(using self: ^Render_Bundle_Encoder) -> WGPU_Render_Bundle {
    return wgpu.render_bundle_encoder_finish(ptr, {})
}

// Sets label.
render_bundle_set_label :: proc(using self: ^Render_Bundle_Encoder, label: cstring) {
    wgpu.render_bundle_encoder_set_label(ptr, label)
}

// Sets the active render pipeline.
render_bundle_set_pipeline :: proc(
    using self: ^Render_Bundle_Encoder,
    pipeline: Render_Pipeline,
) {
    wgpu.render_bundle_encoder_set_pipeline(ptr, pipeline.ptr)
}

// Assign a vertex buffer to a slot.
render_bundle_set_vertex_buffer :: proc(
    using self: ^Render_Bundle_Encoder,
    slot: u32,
    buffer: Buffer,
    offset: Buffer_Size = 0,
) {
    wgpu.render_bundle_encoder_set_vertex_buffer(
        ptr,
        slot,
        buffer.ptr,
        offset,
        buffer.size,
    )
}

render_bundle_reference :: proc(using self: ^Render_Bundle_Encoder) {
    wgpu.render_bundle_encoder_reference(ptr)
}

render_bundle_release :: proc(using self: ^Render_Bundle_Encoder) {
    wgpu.render_bundle_encoder_release(ptr)
}
