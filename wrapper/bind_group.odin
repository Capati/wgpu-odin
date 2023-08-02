package wgpu

// Package
import wgpu "../bindings"

Bind_Group :: struct {
    ptr:          WGPU_Bind_Group,
    using vtable: ^Bind_Group_VTable,
}

@(private)
Bind_Group_VTable :: struct {
    set_label: proc(self: ^Bind_Group, label: cstring),
    reference: proc(self: ^Bind_Group),
    release:   proc(self: ^Bind_Group),
}

@(private)
default_bind_group_vtable := Bind_Group_VTable {
    set_label = bind_group_set_label,
    reference = bind_group_reference,
    release   = bind_group_release,
}

@(private)
default_bind_group := Bind_Group {
    ptr    = nil,
    vtable = &default_bind_group_vtable,
}

bind_group_set_label :: proc(using self: ^Bind_Group, label: cstring) {
    wgpu.bind_group_set_label(ptr, label)
}

bind_group_reference :: proc(using self: ^Bind_Group) {
    wgpu.bind_group_reference(ptr)
}

// Release the `Bind_Group`.
bind_group_release :: proc(using self: ^Bind_Group) {
    wgpu.bind_group_release(ptr)
}
