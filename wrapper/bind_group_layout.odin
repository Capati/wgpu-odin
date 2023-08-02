package wgpu

// Package
import wgpu "../bindings"

Bind_Group_Layout :: struct {
    ptr:          WGPU_Bind_Group_Layout,
    using vtable: ^GPU_Bind_Group_Layout_VTable,
}

@(private)
GPU_Bind_Group_Layout_VTable :: struct {
    set_label: proc(self: ^Bind_Group_Layout, label: cstring),
    reference: proc(self: ^Bind_Group_Layout),
    release:   proc(self: ^Bind_Group_Layout),
}

@(private)
default_bind_group_layout_vtable := GPU_Bind_Group_Layout_VTable {
    set_label = bind_group_layout_set_label,
    reference = bind_group_layout_reference,
    release   = bind_group_layout_release,
}

@(private)
default_bind_group_layout := Bind_Group_Layout {
    ptr    = nil,
    vtable = &default_bind_group_layout_vtable,
}

bind_group_layout_set_label :: proc(using self: ^Bind_Group_Layout, label: cstring) {
    wgpu.bind_group_layout_set_label(ptr, label)
}

bind_group_layout_reference :: proc(using self: ^Bind_Group_Layout) {
    wgpu.bind_group_layout_reference(ptr)
}

// Release the `Bind_Group_Layout`.
bind_group_layout_release :: proc(using self: ^Bind_Group_Layout) {
    wgpu.bind_group_layout_release(ptr)
}
