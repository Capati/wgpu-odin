package wgpu

// Package
import wgpu "../bindings"

// Handle to a pipeline layout.
//
// A `Pipeline_Layout` object describes the available binding groups of a pipeline. It can be
// created with `device_create_pipeline_layout`.
Pipeline_Layout :: struct {
	ptr:  Raw_Pipeline_Layout,
	_pad: POINTER_PROMOTION_PADDING,
}

// Set debug label.
pipeline_layout_set_label :: proc "contextless" (using self: Pipeline_Layout, label: cstring) {
	wgpu.pipeline_layout_set_label(ptr, label)
}

// Increase the reference count.
pipeline_layout_reference :: proc "contextless" (using self: Pipeline_Layout) {
	wgpu.pipeline_layout_reference(ptr)
}

// Release the `Pipeline_Layout`.
pipeline_layout_release :: #force_inline proc "contextless" (using self: Pipeline_Layout) {
	wgpu.pipeline_layout_release(ptr)
}

// Release the `Pipeline_Layout` and modify the raw pointer to `nil`.
pipeline_layout_release_and_nil :: proc "contextless" (using self: ^Pipeline_Layout) {
	if ptr == nil do return
	wgpu.pipeline_layout_release(ptr)
	ptr = nil
}
