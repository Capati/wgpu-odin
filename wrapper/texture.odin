package wgpu

// The raw bindings
import wgpu "../bindings"

/*
Handle to a texture on the GPU.

It can be created with `device_create_texture`.

Corresponds to [WebGPU `GPUTexture`](https://gpuweb.github.io/gpuweb/#texture-interface).
*/
Texture :: wgpu.Texture

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
	_error_reset_data(loc)

	descriptor := descriptor
	texture_view = wgpu.texture_create_view(self, &descriptor.? or_else nil)

	if get_last_error() != nil {
		if texture_view != nil {
			wgpu.texture_view_release(texture_view)
		}
		return
	}

	return texture_view, true
}

/* Destroy the associated native resources as soon as possible. */
texture_destroy :: wgpu.texture_destroy

/* Make an `Image_Copy_Texture` representing the whole texture with the given origin. */
texture_as_image_copy :: proc "contextless" (
	self: Texture,
	origin: Origin_3D = {},
) -> Image_Copy_Texture {
	return { texture = self, mip_level = 0, origin = origin, aspect = Texture_Aspect.All }
}

/*
Returns the size of this `Texture`.

This is always equal to the `size` that was specified when creating the texture.
*/
texture_size :: proc "contextless" (self: Texture) -> Extent_3D {
	return {
		texture_width(self),
		texture_height(self),
		texture_depth_or_array_layers(self),
	}
}

/*
Returns the width of this `Texture`.

This is always equal to the `size.width` that was specified when creating the texture.
*/
texture_width :: wgpu.texture_get_width

/*
Returns the height of this `Texture`.

This is always equal to the `size.height` that was specified when creating the texture.
*/
texture_height :: wgpu.texture_get_height

/*
Returns the depth or layer count of this `Texture`.

This is always equal to the `size.depth_or_array_layers` that was specified when creating the
texture.
*/
texture_depth_or_array_layers :: wgpu.texture_get_depth_or_array_layers

/*
Returns the mip_level_count of this `Texture`.

This is always equal to the `mip_level_count` that was specified when creating the texture.
*/
texture_mip_level_count :: wgpu.texture_get_mip_level_count

/*
Returns the sample count of this `Texture`.

This is always equal to the `sample_count` that was specified when creating the texture.
*/
texture_sample_count :: wgpu.texture_get_sample_count

/*
Returns the dimension of this `Texture`.

This is always equal to the `dimension` that was specified when creating the texture.
*/
texture_dimension :: wgpu.texture_get_dimension

/*
Returns the format of this `Texture`.

This is always equal to the `format` that was specified when creating the texture.
*/
texture_format :: wgpu.texture_get_format

/*
Returns the allowed usages of this `Texture`.

This is always equal to the `usage` that was specified when creating the texture.
*/
texture_usage :: proc "contextless" (self: Texture) -> Texture_Usage_Flags {
	return transmute(Texture_Usage_Flags)(wgpu.texture_get_usage(self))
}

/*
Returns a descriptor for this `Texture`.

This is always equal to the values that was specified when creating the texture.
*/
texture_descriptor :: proc "contextless" (self: Texture) -> (desc: Texture_Descriptor) {
	desc.usage           = texture_usage(self)
	desc.dimension       = texture_dimension(self)
	desc.size            = texture_size(self)
	desc.format          = texture_format(self)
	desc.mip_level_count = texture_mip_level_count(self)
	desc.sample_count    = texture_sample_count(self)
	return
}

/* Set a debug label for this `Texture`. */
texture_set_label :: wgpu.texture_set_label

/* Increase the reference count. */
texture_reference :: wgpu.texture_reference

/* Release the `Texture` resources. */
texture_release :: wgpu.texture_release
