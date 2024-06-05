package wgpu

// Package
import wgpu "../bindings"

// Handle to a pipeline layout.
//
// A `Pipeline_Layout` object describes the available binding groups of a pipeline. It can be
// created with `device_create_pipeline_layout`.
Pipeline_Layout :: struct {
	ptr: Raw_Pipeline_Layout,
}

// Set debug label.
pipeline_layout_set_label :: proc(using self: ^Pipeline_Layout, label: cstring) {
	wgpu.pipeline_layout_set_label(ptr, label)
}

// Increase the reference count.
pipeline_layout_reference :: proc(using self: ^Pipeline_Layout) {
	wgpu.pipeline_layout_reference(ptr)
}

// Release the `Pipeline_Layout`.
pipeline_layout_release :: proc(using self: ^Pipeline_Layout) {
	wgpu.pipeline_layout_release(ptr)
}

// Release the `Pipeline_Layout` and modify the raw pointer to `nil`.
pipeline_layout_release_and_nil :: proc(using self: ^Pipeline_Layout) {
	if ptr == nil do return
	wgpu.pipeline_layout_release(ptr)
	ptr = nil
}
