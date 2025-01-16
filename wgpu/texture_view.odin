package wgpu

/*
Handle to a texture view.

A `Texture_View` object describes a texture and associated metadata needed by a
`Render_Pipeline` or `Bind_Group`.

Corresponds to [WebGPU `GPUTextureView`](https://gpuweb.github.io/gpuweb/#gputextureview).
*/
Texture_View :: distinct rawptr

/* Sets a debug label for the given `Texture_View`. */
@(disabled = !ODIN_DEBUG)
texture_view_set_label :: proc "contextless" (self: Texture_View, label: string) {
	c_label: String_View_Buffer
	wgpuTextureViewSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the `Texture_View` reference count. */
texture_view_add_ref :: wgpuTextureViewAddRef

/* Release the `Texture_View` resources, use to decrease the reference count. */
texture_view_release :: wgpuTextureViewRelease

/*
Safely releases the `Texture_View` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
texture_view_release_safe :: #force_inline proc(self: ^Texture_View) {
	if self != nil && self^ != nil {
		wgpuTextureViewRelease(self^)
		self^ = nil
	}
}
