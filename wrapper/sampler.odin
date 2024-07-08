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
	ptr:  Raw_Sampler,
	_pad: POINTER_PROMOTION_PADDING,
}

// Set debut label.
sampler_set_label :: proc "contextless" (using self: Sampler, label: cstring) {
	wgpu.sampler_set_label(ptr, label)
}

// Increase the reference count.
sampler_reference :: proc "contextless" (using self: Sampler) {
	wgpu.sampler_reference(ptr)
}

// Release the `Sampler`.
sampler_release :: #force_inline proc "contextless" (using self: Sampler) {
	wgpu.sampler_release(ptr)
}

// Release the `Sampler` and modify the raw pointer to `nil`.
sampler_release_and_nil :: proc "contextless" (using self: ^Sampler) {
	if ptr == nil do return
	wgpu.sampler_release(ptr)
	ptr = nil
}
