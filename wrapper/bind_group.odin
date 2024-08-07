package wgpu

// Package
import wgpu "../bindings"

// Handle to a binding group.
//
// A `Bind_Group` represents the set of resources bound to the bindings described by a
// Bind_Group_Layout. It can be created with `device_create_bind_group`. A `Bind_Group` can be
// bound to a particular `Render_Pass` with `render_pass_encoder_set_bind_group`, or to a `Compute_Pass_Encoder`
// with `compute_pass_encoder_set_bind_group`.
Bind_Group :: struct {
	ptr:  Raw_Bind_Group,
	_pad: POINTER_PROMOTION_PADDING,
}

// Set debug label.
bind_group_set_label :: proc "contextless" (using self: Bind_Group, label: cstring) {
	wgpu.bind_group_set_label(ptr, label)
}

// Increase the reference count.
bind_group_reference :: proc "contextless" (using self: Bind_Group) {
	wgpu.bind_group_reference(ptr)
}

// Release the `Bind_Group`.
bind_group_release :: #force_inline proc "contextless" (using self: Bind_Group) {
	wgpu.bind_group_release(ptr)
}

// Release the `Bind_Group` and modify the raw pointer to `nil`.
bind_group_release_and_nil :: proc "contextless" (using self: ^Bind_Group) {
	if ptr == nil do return
	wgpu.bind_group_release(ptr)
	ptr = nil
}
