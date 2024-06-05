package wgpu

// Package
import wgpu "../bindings"

// Handle to a texture view.
//
// A `Texture_View` object describes a texture and associated metadata needed by a
// `Render_Pipeline` or `Bind_Group`.
Texture_View :: struct {
	ptr: Raw_Texture_View,
}

// Set debug label.
texture_view_set_label :: proc(using texture_view: ^Texture_View, label: cstring) {
	wgpu.texture_view_set_label(ptr, label)
}

// Increase the reference count.
texture_view_reference :: proc(using texture_view: ^Texture_View) {
	wgpu.texture_view_reference(ptr)
}

// Release the `Texture_View`.
texture_view_release :: proc(using texture_view: ^Texture_View) {
	if ptr == nil do return
	wgpu.texture_view_release(ptr)
	ptr = nil
}
