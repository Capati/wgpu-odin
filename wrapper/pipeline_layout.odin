package wgpu

// Package
import wgpu "../bindings"

// Handle to a pipeline layout.
//
// A `Pipeline_Layout` object describes the available binding groups of a pipeline. It can be
// created with `device_create_pipeline_layout`.
Pipeline_Layout :: struct {
	_ptr: WGPU_Pipeline_Layout,
}

// Set debug label.
pipeline_layout_set_label :: proc(using self: ^Pipeline_Layout, label: cstring) {
	wgpu.pipeline_layout_set_label(_ptr, label)
}

// Increase the reference count.
pipeline_layout_reference :: proc(using self: ^Pipeline_Layout) {
	wgpu.pipeline_layout_reference(_ptr)
}

// Executes the `Pipeline_Layout` destructor.
pipeline_layout_release :: proc(using self: ^Pipeline_Layout) {
	wgpu.pipeline_layout_release(_ptr)
}
