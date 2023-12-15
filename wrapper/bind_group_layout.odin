package wgpu

// Package
import wgpu "../bindings"

// Handle to a binding group layout.
//
// A `Bind_Group_Layout` is a handle to the GPU-side layout of a binding group. It can be used to
// create a `Bind_Group_Descriptor` object, which in turn can be used to create a `Bind_Group`
// object with `device_create_bind_group`. A series of `Bind_Group_Layout`s can also be used to
// create a `Pipeline_Layout_Descriptor`, which can be used to create a `Pipeline_Layout`.
Bind_Group_Layout :: struct {
	_ptr: WGPU_Bind_Group_Layout,
}

// Set debug label.
bind_group_layout_set_label :: proc(using self: ^Bind_Group_Layout, label: cstring) {
	wgpu.bind_group_layout_set_label(_ptr, label)
}

// Increase the reference count.
bind_group_layout_reference :: proc(using self: ^Bind_Group_Layout) {
	wgpu.bind_group_layout_reference(_ptr)
}

// Release the `Bind_Group_Layout`.
bind_group_layout_release :: proc(using self: ^Bind_Group_Layout) {
	wgpu.bind_group_layout_release(_ptr)
}
