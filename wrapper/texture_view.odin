package wgpu

// Package

import wgpu "../bindings"

Texture_View :: struct {
    ptr:          WGPU_Texture_View,
    using vtable: ^Texture_View_VTable,
}

@(private)
Texture_View_VTable :: struct {
    set_label: proc(self: ^Texture_View, label: cstring),
    reference: proc(self: ^Texture_View),
    release:   proc(self: ^Texture_View),
}

@(private)
default_texture_view_vtable := Texture_View_VTable {
    set_label = texture_view_set_label,
    reference = texture_view_reference,
    release   = texture_view_release,
}

@(private)
default_texture_view := Texture_View {
    vtable = &default_texture_view_vtable,
}

texture_view_set_label :: proc(using texture_view: ^Texture_View, label: cstring) {
    wgpu.texture_view_set_label(ptr, label)
}

texture_view_reference :: proc(using texture_view: ^Texture_View) {
    wgpu.texture_view_reference(ptr)
}

texture_view_release :: proc(using texture_view: ^Texture_View) {
    wgpu.texture_view_release(ptr)
}
