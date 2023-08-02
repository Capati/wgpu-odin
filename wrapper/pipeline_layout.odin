package wgpu

// Package
import wgpu "../bindings"

Pipeline_Layout :: struct {
    ptr:          WGPU_Pipeline_Layout,
    using vtable: ^GPU_Pipeline_Layout_VTable,
}

@(private)
GPU_Pipeline_Layout_VTable :: struct {
    set_label: proc(self: ^Pipeline_Layout, label: cstring),
    reference: proc(self: ^Pipeline_Layout),
    release:   proc(self: ^Pipeline_Layout),
}

@(private)
default_pipeline_layout_vtable := GPU_Pipeline_Layout_VTable {
    set_label = pipeline_layout_set_label,
    reference = pipeline_layout_reference,
    release   = pipeline_layout_release,
}

@(private)
default_pipeline_layout := Pipeline_Layout {
    ptr    = nil,
    vtable = &default_pipeline_layout_vtable,
}

pipeline_layout_set_label :: proc(using self: ^Pipeline_Layout, label: cstring) {
    wgpu.pipeline_layout_set_label(ptr, label)
}

pipeline_layout_reference :: proc(using self: ^Pipeline_Layout) {
    wgpu.pipeline_layout_reference(ptr)
}

// Executes the `Pipeline_Layout` destructor.
pipeline_layout_release :: proc(using self: ^Pipeline_Layout) {
    wgpu.pipeline_layout_release(ptr)
}
