package wgpu

// Package
import wgpu "../bindings"

// Handle to a binding group.
//
// A `Bind_Group` represents the set of resources bound to the bindings described by a
// Bind_Group_Layout. It can be created with `device_create_bind_group`. A `Bind_Group` can be
// bound to a particular `Render_Pass` with `render_pass_set_bind_group`, or to a `Compute_Pass`
// with `compute_pass_set_bind_group`.
Bind_Group :: struct {
	_ptr: WGPU_Bind_Group,
}

// Set debug label.
bind_group_set_label :: proc(using self: ^Bind_Group, label: cstring) {
	wgpu.bind_group_set_label(_ptr, label)
}

// Increase the reference count.
bind_group_reference :: proc(using self: ^Bind_Group) {
	wgpu.bind_group_reference(_ptr)
}

// Release the `Bind_Group`.
bind_group_release :: proc(using self: ^Bind_Group) {
	wgpu.bind_group_release(_ptr)
}
