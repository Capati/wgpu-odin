package wgpu

// Package
import wgpu "../bindings"

// Pre-prepared reusable bundle of GPU operations.
Render_Bundle :: struct {
    ptr:          WGPU_Render_Bundle,
    using vtable: ^Render_Bundle_VTable,
}

@(private)
Render_Bundle_VTable :: struct {
    set_label: proc(self: ^Render_Bundle, label: cstring),
    reference: proc(self: ^Render_Bundle),
    release:   proc(self: ^Render_Bundle),
}

@(private)
default_render_bundle_vtable := Render_Bundle_VTable {
    set_label = render_bundle_set_label,
    reference = render_bundle_reference,
    release   = render_bundle_release,
}

@(private)
default_render_bundle := Render_Bundle {
    ptr    = nil,
    vtable = &default_render_bundle_vtable,
}

render_bundle_set_label :: proc(using self: ^Render_Bundle, label: cstring) {
    wgpu.render_bundle_set_label(ptr, label)
}

render_bundle_reference :: proc(using self: ^Render_Bundle) {
    wgpu.render_bundle_reference(ptr)
}

render_bundle_release :: proc(using self: ^Render_Bundle) {
    wgpu.render_bundle_release(ptr)
}
