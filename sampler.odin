package webgpu

// Vendor
import "vendor:wgpu"

/*
Handle to a sampler.

A `Sampler` object defines how a pipeline will sample from a `TextureView`.
Samplers define image filters (including anisotropy) and address (wrapping)
modes, among other things. See the documentation for `SamplerDescriptor` for
more information.

It can be created with `DeviceCreateSampler`.

Corresponds to [WebGPU
`GPUSampler`](https://gpuweb.github.io/gpuweb/#sampler-interface).
*/
Sampler :: wgpu.Sampler

/* Sets a debug label for the given `Sampler`. */
SamplerSetLabel :: wgpu.SamplerSetLabel

/* Increase the `Sampler` reference count. */
SamplerAddRef :: wgpu.SamplerAddRef

/* Release the `Sampler` resources, use to decrease the reference count. */
SamplerRelease :: wgpu.SamplerRelease

/*
Safely releases the `Sampler` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
SamplerReleaseSafe :: proc "c" (self: ^Sampler) {
	if self != nil && self^ != nil {
		wgpu.SamplerRelease(self^)
		self^ = nil
	}
}
