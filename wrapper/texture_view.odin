package wgpu

// The raw bindings
import wgpu "../bindings"

/*
Handle to a texture view.

A `Texture_View` object describes a texture and associated metadata needed by a
`Render_Pipeline` or `Bind_Group`.

Corresponds to [WebGPU `GPUTextureView`](https://gpuweb.github.io/gpuweb/#gputextureview).
*/
Texture_View :: wgpu.Texture_View

/* Set debug label. */
texture_view_set_label :: wgpu.texture_view_set_label

/* Increase the reference count. */
texture_view_reference :: wgpu.texture_view_reference

/* Release the `Texture_View` resources. */
texture_view_release :: wgpu.texture_view_release
