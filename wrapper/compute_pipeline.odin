package wgpu

// Package
import wgpu "../bindings"

// Handle to a compute pipeline.
Compute_Pipeline :: struct {
    ptr:          WGPU_Compute_Pipeline,
    using vtable: ^Compute_Pipeline_VTable,
}

@(private)
Compute_Pipeline_VTable :: struct {
    get_bind_group_layout: proc(
        self: ^Compute_Pipeline,
        group_index: u32,
    ) -> (
        Bind_Group_Layout,
        Error_Type,
    ),
    set_label:             proc(self: ^Compute_Pipeline, label: cstring),
    reference:             proc(self: ^Compute_Pipeline),
    release:               proc(self: ^Compute_Pipeline),
}

@(private)
default_compute_pipeline_vtable := Compute_Pipeline_VTable {
    get_bind_group_layout = compute_pipeline_get_bind_group_layout,
    set_label             = compute_pipeline_set_label,
    reference             = compute_pipeline_reference,
    release               = compute_pipeline_release,
}

@(private)
default_compute_pipeline := Compute_Pipeline {
    ptr    = nil,
    vtable = &default_compute_pipeline_vtable,
}

// Get an object representing the bind group layout at a given index.
compute_pipeline_get_bind_group_layout :: proc(
    using self: ^Compute_Pipeline,
    group_index: u32,
) -> (
    bind_group_layout: Bind_Group_Layout,
    err: Error_Type,
) {
    bind_group_layout_ptr := wgpu.compute_pipeline_get_bind_group_layout(ptr, group_index)

    if bind_group_layout_ptr == nil {
        update_error_message("Failed to acquire Bind_Group_Layout")
        return {}, .Unknown
    }

    bind_group_layout = default_bind_group_layout
    bind_group_layout.ptr = bind_group_layout_ptr

    return
}

compute_pipeline_set_label :: proc(using self: ^Compute_Pipeline, label: cstring) {
    wgpu.compute_pipeline_set_label(ptr, label)
}

compute_pipeline_reference :: proc(using self: ^Compute_Pipeline) {
    wgpu.compute_pipeline_reference(ptr)
}

// Release `Compute_Pipeline`.
compute_pipeline_release :: proc(using self: ^Compute_Pipeline) {
    wgpu.compute_pipeline_release(ptr)
}
