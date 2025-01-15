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

/*
Describes a `Sampler`.

For use with `device_create_sampler`.

Corresponds to [WebGPU `GPUSamplerDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpusamplerdescriptor).
*/
SamplerDescriptor :: struct {
	label:          string,
	address_mode_u: AddressMode,
	address_mode_v: AddressMode,
	address_mode_w: AddressMode,
	mag_filter:     FilterMode,
	min_filter:     FilterMode,
	mipmap_filter:  MipmapFilterMode,
	lod_min_clamp:  f32,
	lod_max_clamp:  f32,
	compare:        CompareFunction,
	max_anisotropy: u16,
}

DEFAULT_SAMPLER_DESCRIPTOR :: SamplerDescriptor {
	address_mode_u = .ClampToEdge,
	address_mode_v = .ClampToEdge,
	address_mode_w = .ClampToEdge,
	mag_filter     = .Nearest,
	min_filter     = .Nearest,
	mipmap_filter  = .Nearest,
	lod_min_clamp  = 0.0,
	lod_max_clamp  = 32.0,
	compare        = .Undefined,
	max_anisotropy = 1,
}

/* Sets a debug label for the given `Sampler`. */
@(disabled = !ODIN_DEBUG)
sampler_set_label :: proc "contextless" (self: Sampler, label: string) {
	c_label: StringViewBuffer
	wgpuSamplerSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the `Sampler` reference count. */
sampler_add_ref :: wgpuSamplerAddRef

/* Release the `Sampler` resources, use to decrease the reference count. */
sampler_release :: wgpuSamplerRelease

/*
Safely releases the `Sampler` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
sampler_release_safe :: #force_inline proc(self: ^Sampler) {
	if self != nil && self^ != nil {
		wgpuSamplerRelease(self^)
		self^ = nil
	}
}
