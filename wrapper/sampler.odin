package wgpu

// The raw bindings
import wgpu "../bindings"

/*
Handle to a sampler.

A `Sampler` object defines how a pipeline will sample from a `Texture_View`. Samplers define
image filters (including anisotropy) and address (wrapping) modes, among other things. See
the documentation for `Sampler_Descriptor` for more information.

It can be created with `device_create_sampler`.

Corresponds to [WebGPU `GPUSampler`](https://gpuweb.github.io/gpuweb/#sampler-interface).
*/
Sampler :: wgpu.Sampler

/* Set debut label. */
sampler_set_label :: wgpu.sampler_set_label

/* Increase the reference count. */
sampler_reference :: wgpu.sampler_reference

/* Release the `Sampler`. */
sampler_release :: wgpu.sampler_release
