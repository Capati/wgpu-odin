package wgpu

/*
Handle to a sampler.

A `Sampler` object defines how a pipeline will sample from a `TextureView`. Samplers define
image filters (including anisotropy) and address (wrapping) modes, among other things. See
the documentation for `SamplerDescriptor` for more information.

It can be created with `device_create_sampler`.

Corresponds to [WebGPU `GPUSampler`](https://gpuweb.github.io/gpuweb/#sampler-interface).
*/
Sampler :: distinct rawptr

/* Set debug label. */
@(disabled = !ODIN_DEBUG)
sampler_set_label :: proc "contextless" (self: Sampler, label: string) {
	c_label: StringViewBuffer
	wgpuSamplerSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the reference count. */
sampler_add_ref :: wgpuSamplerAddRef

/* Release the `Sampler`. */
sampler_release :: wgpuSamplerRelease
