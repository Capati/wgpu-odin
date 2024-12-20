package wgpu

/*
Handle to a texture view.

A `TextureView` object describes a texture and associated metadata needed by a
`RenderPipeline` or `BindGroup`.

Corresponds to [WebGPU `GPUTextureView`](https://gpuweb.github.io/gpuweb/#gputextureview).
*/
TextureView :: distinct rawptr

/* Set debug label. */
@(disabled = !ODIN_DEBUG)
texture_view_set_label :: proc "contextless" (self: TextureView, label: string) {
	c_label: StringViewBuffer
	wgpuTextureViewSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the reference count. */
texture_view_add_ref :: wgpuTextureViewAddRef

/* Release the `TextureView` resources. */
texture_view_release :: wgpuTextureViewRelease
