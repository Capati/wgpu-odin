package wgpu

// Package
import wgpu "../bindings"

// Handle to a rendering (graphics) pipeline.
Render_Pipeline :: struct {
    ptr:          WGPU_Render_Pipeline,
    using vtable: ^Render_Pipeline_VTable,
}

@(private)
Render_Pipeline_VTable :: struct {
    get_bind_group_layout: proc(
        self: ^Render_Pipeline,
        group_index: u32,
    ) -> (
        Bind_Group_Layout,
        Error_Type,
    ),
    set_label:             proc(self: ^Render_Pipeline, label: cstring),
    reference:             proc(self: ^Render_Pipeline),
    release:               proc(self: ^Render_Pipeline),
}

@(private)
default_render_pipeline_vtable := Render_Pipeline_VTable {
    get_bind_group_layout = render_pipeline_get_bind_group_layout,
    set_label             = render_pipeline_set_label,
    reference             = render_pipeline_reference,
    release               = render_pipeline_release,
}

@(private)
default_render_pipeline := Render_Pipeline {
    ptr    = nil,
    vtable = &default_render_pipeline_vtable,
}

// Get an object representing the bind group layout at a given index.
render_pipeline_get_bind_group_layout :: proc(
    using self: ^Render_Pipeline,
    group_index: u32,
) -> (
    bind_group_layout: Bind_Group_Layout,
    err: Error_Type,
) {
    bind_group_layout_ptr := wgpu.render_pipeline_get_bind_group_layout(ptr, group_index)

    if bind_group_layout_ptr == nil {
        update_error_message("Failed to acquire Bind_Group_Layout")
        return {}, .Unknown
    }

    bind_group_layout = default_bind_group_layout
    bind_group_layout.ptr = bind_group_layout_ptr

    return
}

render_pipeline_set_label :: proc(using self: ^Render_Pipeline, label: cstring) {
    wgpu.render_pipeline_set_label(ptr, label)
}

render_pipeline_reference :: proc(using self: ^Render_Pipeline) {
    wgpu.render_pipeline_reference(ptr)
}

// Release the `Render_Pipeline`.
render_pipeline_release :: proc(using self: ^Render_Pipeline) {
    wgpu.render_pipeline_release(ptr)
}
