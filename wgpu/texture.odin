package wgpu

/*
Handle to a texture on the GPU.

It can be created with `device_create_texture`.

Corresponds to [WebGPU `GPUTexture`](https://gpuweb.github.io/gpuweb/#texture-interface).
*/
Texture :: distinct rawptr

TextureViewDescriptor :: struct {
	label:             string,
	format:            TextureFormat,
	dimension:         TextureViewDimension,
	base_mip_level:    u32,
	mip_level_count:   u32,
	base_array_layer:  u32,
	array_layer_count: u32,
	aspect:            TextureAspect,
	usage:             TextureUsage,
}

/* Creates a view of this texture. */
@(require_results)
texture_create_view :: proc "contextless" (
	self: Texture,
	descriptor: Maybe(TextureViewDescriptor) = nil,
	loc := #caller_location,
) -> (
	texture_view: TextureView,
	ok: bool,
) #optional_ok {
	error_reset_data(loc)

	if desc, desc_ok := descriptor.?; desc_ok {
		raw_desc := WGPUTextureViewDescriptor {
			format            = desc.format,
			dimension         = desc.dimension,
			base_mip_level    = desc.base_mip_level,
			mip_level_count   = desc.mip_level_count,
			base_array_layer  = desc.base_array_layer,
			array_layer_count = desc.array_layer_count,
			aspect            = desc.aspect,
			usage             = desc.usage,
		}

		when ODIN_DEBUG {
			c_label: StringViewBuffer
			if desc.label != "" {
				raw_desc.label = init_string_buffer(&c_label, desc.label)
			}
		}

		texture_view = wgpuTextureCreateView(self, &raw_desc)
	} else {
		texture_view = wgpuTextureCreateView(self, nil)
	}

	if get_last_error() != nil {
		if texture_view != nil {
			wgpuTextureViewRelease(texture_view)
		}
		return
	}

	return texture_view, true
}

/* Destroy the associated native resources as soon as possible. */
texture_destroy :: wgpuTextureDestroy

/* Make an `TexelCopyTextureInfo` representing the whole texture with the given origin. */
texture_as_image_copy :: proc "contextless" (
	self: Texture,
	origin: Origin3D = {},
) -> TexelCopyTextureInfo {
	return {texture = self, mip_level = 0, origin = origin, aspect = .All}
}

/*
Returns the size of this `Texture`.

This is always equal to the `size` that was specified when creating the texture.
*/
texture_size :: proc "contextless" (self: Texture) -> Extent3D {
	return {
		width = texture_width(self),
		height = texture_height(self),
		depth_or_array_layers = texture_depth_or_array_layers(self),
	}
}

/*
Returns the width of this `Texture`.

This is always equal to the `size.width` that was specified when creating the texture.
*/
texture_width :: wgpuTextureGetWidth

/*
Returns the height of this `Texture`.

This is always equal to the `size.height` that was specified when creating the texture.
*/
texture_height :: wgpuTextureGetHeight

/*
Returns the depth or layer count of this `Texture`.

This is always equal to the `size.depth_or_array_layers` that was specified when creating the
texture.
*/
texture_depth_or_array_layers :: wgpuTextureGetDepthOrArrayLayers

/*
Returns the mip_level_count of this `Texture`.

This is always equal to the `mip_level_count` that was specified when creating the texture.
*/
texture_mip_level_count :: wgpuTextureGetMipLevelCount

/*
Returns the sample count of this `Texture`.

This is always equal to the `sample_count` that was specified when creating the texture.
*/
texture_sample_count :: wgpuTextureGetSampleCount

/*
Returns the dimension of this `Texture`.

This is always equal to the `dimension` that was specified when creating the texture.
*/
texture_dimension :: wgpuTextureGetDimension

/*
Returns the format of this `Texture`.

This is always equal to the `format` that was specified when creating the texture.
*/
texture_format :: wgpuTextureGetFormat

/*
Returns the allowed usages of this `Texture`.

This is always equal to the `usage` that was specified when creating the texture.
*/
texture_usage :: proc "contextless" (self: Texture) -> TextureUsage {
	return wgpuTextureGetUsage(self)
}

/*
Returns a descriptor for this `Texture`.

This is always equal to the values that was specified when creating the texture.
*/
texture_descriptor :: proc "contextless" (self: Texture) -> (desc: TextureDescriptor) {
	desc.usage = texture_usage(self)
	desc.dimension = texture_dimension(self)
	desc.size = texture_size(self)
	desc.format = texture_format(self)
	desc.mip_level_count = texture_mip_level_count(self)
	desc.sample_count = texture_sample_count(self)
	return
}

/* Set a debug label for this `Texture`. */
@(disabled = !ODIN_DEBUG)
texture_set_label :: proc "contextless" (self: Texture, label: string) {
	c_label: StringViewBuffer
	wgpuTextureSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the reference count. */
texture_add_ref :: wgpuTextureAddRef

/* Release the `Texture` resources. */
texture_release :: wgpuTextureRelease
