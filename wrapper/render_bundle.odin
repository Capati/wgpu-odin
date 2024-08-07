package wgpu

// Package
import wgpu "../bindings"

// Pre-prepared reusable bundle of GPU operations.
//
// It only supports a handful of render commands, but it makes them reusable. Executing a
// `Render_Bundle` is often more efficient than issuing the underlying commands manually.
//
// It can be created by use of a `Render_Bundle_Encoder`, and executed onto a `Command_Encoder`
// using `render_pass_encoder_execute_bundles`.
Render_Bundle :: struct {
	ptr:  Raw_Render_Bundle,
	_pad: POINTER_PROMOTION_PADDING,
}

// Set debug label.
render_bundle_set_label :: proc "contextless" (using self: Render_Bundle, label: cstring) {
	wgpu.render_bundle_set_label(ptr, label)
}

// Increase the reference count.
render_bundle_reference :: proc "contextless" (using self: Render_Bundle) {
	wgpu.render_bundle_reference(ptr)
}

// Release the `Render_Bundle`.
render_bundle_release :: #force_inline proc "contextless" (using self: Render_Bundle) {
	wgpu.render_bundle_release(ptr)
}

// Release the `Render_Bundle` and modify the raw pointer to `nil`.
render_bundle_release_and_nil :: proc "contextless" (using self: ^Render_Bundle) {
	if ptr == nil do return
	wgpu.render_bundle_release(ptr)
	ptr = nil
}
