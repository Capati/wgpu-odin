package wgpu

// Package
import wgpu "../bindings"

Sampler :: struct {
    ptr:          WGPU_Sampler,
    using vtable: ^Sampler_VTable,
}

@(private)
Sampler_VTable :: struct {
    set_label: proc(self: ^Sampler, label: cstring),
    reference: proc(self: ^Sampler),
    release:   proc(self: ^Sampler),
}

@(private)
default_sampler_vtable := Sampler_VTable {
    set_label = sampler_set_label,
    reference = sampler_reference,
    release   = sampler_release,
}

@(private)
default_sampler := Sampler {
    ptr    = nil,
    vtable = &default_sampler_vtable,
}

sampler_set_label :: proc(using self: ^Sampler, label: cstring) {
    wgpu.sampler_set_label(ptr, label)
}

sampler_reference :: proc(using self: ^Sampler) {
    wgpu.sampler_reference(ptr)
}

sampler_release :: proc(using self: ^Sampler) {
    wgpu.sampler_release(ptr)
}
