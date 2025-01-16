package wgpu

/*
Handle to a texture on the GPU.

It can be created with `device_create_texture`.

Corresponds to [WebGPU `GPUTexture`](https://gpuweb.github.io/gpuweb/#texture-interface).
*/
Texture :: distinct rawptr

/*
Describes a `Texture`.

For use with `device_create_texture`.

Corresponds to [WebGPU `GPUTextureDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gputexturedescriptor).
*/
Texture_Descriptor :: struct {
	label:           string,
	usage:           Texture_Usages,
	dimension:       Texture_Dimension,
	size:            Extent_3D,
	format:          Texture_Format,
	mip_level_count: u32,
	sample_count:    u32,
	view_formats:    []Texture_Format,
}

DEFAULT_TEXTURE_DESCRIPTOR :: Texture_Descriptor {
	mip_level_count = 1,
	sample_count    = 1,
	dimension       = .D2,
}

/* Creates a view of this texture. */
@(require_results)
texture_create_view :: proc "contextless" (
	self: Texture,
	descriptor: Maybe(Texture_View_Descriptor) = nil,
	loc := #caller_location,
) -> (
	texture_view: Texture_View,
	ok: bool,
) #optional_ok {
	error_reset_data(loc)

	if desc, desc_ok := descriptor.?; desc_ok {
		raw_desc := WGPU_Texture_View_Descriptor {
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
			c_label: String_View_Buffer
			if desc.label != "" {
				raw_desc.label = init_string_buffer(&c_label, desc.label)
			}
		}

		texture_view = wgpuTextureCreateView(self, &raw_desc)
	} else {
		texture_view = wgpuTextureCreateView(self, nil)
	}

	if has_error() {
		if texture_view != nil {
			wgpuTextureViewRelease(texture_view)
		}
		return
	}

	return texture_view, true
}

/* Destroy the associated native resources as soon as possible. */
texture_destroy :: wgpuTextureDestroy

/* Make an `Texel_Copy_Texture_Info` representing the whole texture with the given origin. */
texture_as_image_copy :: proc "contextless" (
	self: Texture,
	origin: Origin_3D = {},
) -> Texel_Copy_Texture_Info {
	return {texture = self, mip_level = 0, origin = origin, aspect = .All}
}

/*
Returns the size of this `Texture`.

This is always equal to the `size` that was specified when creating the texture.
*/
texture_size :: proc "contextless" (self: Texture) -> Extent_3D {
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
texture_usage :: proc "contextless" (self: Texture) -> Texture_Usages {
	return wgpuTextureGetUsage(self)
}

/*
Returns a descriptor for this `Texture`.

This is always equal to the values that was specified when creating the texture.
*/
texture_descriptor :: proc "contextless" (self: Texture) -> (desc: Texture_Descriptor) {
	desc.usage = texture_usage(self)
	desc.dimension = texture_dimension(self)
	desc.size = texture_size(self)
	desc.format = texture_format(self)
	desc.mip_level_count = texture_mip_level_count(self)
	desc.sample_count = texture_sample_count(self)
	return
}

/* Set a debug label for the given `Texture`. */
@(disabled = !ODIN_DEBUG)
texture_set_label :: proc "contextless" (self: Texture, label: string) {
	c_label: String_View_Buffer
	wgpuTextureSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the `Texture` reference count. */
texture_add_ref :: wgpuTextureAddRef

/* Release the `Texture` resources, use to decrease the reference count. */
texture_release :: wgpuTextureRelease

/*
Safely releases the `Texture` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
texture_release_safe :: #force_inline proc(self: ^Texture) {
	if self != nil && self^ != nil {
		wgpuTextureRelease(self^)
		self^ = nil
	}
}

@(private)
WGPU_Texture_Descriptor :: struct {
	next_in_chain:     ^Chained_Struct,
	label:             String_View,
	usage:             Texture_Usages,
	dimension:         Texture_Dimension,
	size:              Extent_3D,
	format:            Texture_Format,
	mip_level_count:   u32,
	sample_count:      u32,
	view_format_count: uint,
	view_formats:      [^]Texture_Format,
}
