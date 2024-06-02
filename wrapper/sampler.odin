package wgpu

// Package
import wgpu "../bindings"

// Handle to a sampler.
//
// A `Sampler` object defines how a pipeline will sample from a `Texture_View`. Samplers define
// image filters (including anisotropy) and address (wrapping) modes, among other things.
//
// It can be created with `device_create_sampler`.
Sampler :: struct {
	ptr: WGPU_Sampler,
}

// Set debut label.
sampler_set_label :: proc(using self: ^Sampler, label: cstring) {
	wgpu.sampler_set_label(ptr, label)
}

// Increase the reference count.
sampler_reference :: proc(using self: ^Sampler) {
	wgpu.sampler_reference(ptr)
}

// Release the `Sampler`.
sampler_release :: proc(using self: ^Sampler) {
	if ptr == nil do return
	wgpu.sampler_release(ptr)
	ptr = nil
}
