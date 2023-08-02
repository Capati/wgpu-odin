package wgpu

// Package
import wgpu "../bindings"

Render_Pipeline :: struct {
    ptr:          WGPU_Render_Pipeline,
    using vtable: ^Render_Pipeline_VTable,
}

@(private)
Render_Pipeline_VTable :: struct {
    get_bind_group_layout: proc(
        self: ^Render_Pipeline,
        group_index: u32,
    ) -> Bind_Group_Layout,
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
    vtable = &default_render_pipeline_vtable,
}

render_pipeline_get_bind_group_layout :: proc(
    using self: ^Render_Pipeline,
    group_index: u32,
) -> Bind_Group_Layout {
    return(
        {
            ptr = wgpu.render_pipeline_get_bind_group_layout(ptr, group_index),
            vtable = &default_bind_group_layout_vtable,
        } \
    )
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
