package wgpu

/*
Pre-prepared reusable bundle of GPU operations.

It only supports a handful of render commands, but it makes them reusable. Executing a
`Render_Bundle` is often more efficient than issuing the underlying commands manually.

It can be created by use of a `Render_Bundle_Encoder`, and executed onto a `Command_Encoder`
using `render_pass_encoder_execute_bundles`.
*/
Render_Bundle :: distinct rawptr

/*
Describes a `Render_Bundle`.

Corresponds to [WebGPU `GPURenderBundleDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpurenderbundledescriptor).
*/
Render_Bundle_Descriptor :: struct {
	label: string,
}

/* Sets a debug label for the given `Render_Bundle`. */
@(disabled = !ODIN_DEBUG)
render_bundle_set_label :: proc "contextless" (self: Render_Bundle, label: string) {
	c_label: String_View_Buffer
	wgpuRenderBundleSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the `Render_Bundle` reference count. */
render_bundle_add_ref :: wgpuRenderBundleAddRef

/* Release the `Render_Bundle` resources, use to decrease the reference count. */
render_bundle_release :: wgpuRenderBundleRelease

/*
Safely releases the `Render_Bundle` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
render_bundle_release_safe :: #force_inline proc(self: ^Render_Bundle) {
	if self != nil && self^ != nil {
		wgpuRenderBundleRelease(self^)
		self^ = nil
	}
}
