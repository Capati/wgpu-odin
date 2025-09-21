package webgpu

// Vendor
import "vendor:wgpu"

/*
Handle to a texture view.

A `TextureView` object describes a texture and associated metadata needed by a
`RenderPipeline` or `BindGroup`.

Corresponds to [WebGPU
`GPUTextureView`](https://gpuweb.github.io/gpuweb/#gputextureview).
*/
TextureView :: wgpu.TextureView

/* Sets a debug label for the given `TextureView`. */
TextureViewSetLabel :: wgpu.TextureViewSetLabel

/* Increase the `TextureView` reference count. */
TextureViewAddRef :: wgpu.TextureViewAddRef

/* Release the `TextureView` resources, use to decrease the reference count. */
TextureViewRelease :: wgpu.TextureViewRelease

/*
Safely releases the `TextureView` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
TextureViewReleaseSafe :: proc "c" (self: ^TextureView) {
	if self != nil && self^ != nil {
		wgpu.TextureViewRelease(self^)
		self^ = nil
	}
}
