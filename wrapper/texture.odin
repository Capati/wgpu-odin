package wgpu

// Package
import wgpu "../bindings"

// Handle to a texture on the GPU.
//
// It can be created with `device_create_texture`.
Texture :: struct {
	ptr:              Raw_Texture,
	using descriptor: Texture_Descriptor,
	_err_data:        ^Error_Data,
}

DEFAULT_TEXTURE_VIEW_DESCRIPTOR :: Texture_View_Descriptor {
	format           = .Undefined,
	dimension        = .Undefined,
	base_mip_level   = 0,
	base_array_layer = 0,
	aspect           = .All,
}

// Creates a view of this texture.
@(require_results)
texture_create_view :: proc "contextless" (
	self: Texture,
	descriptor: Texture_View_Descriptor = {},
	loc := #caller_location,
) -> (
	texture_view: Texture_View,
	err: Error,
) {
	set_and_reset_err_data(self._err_data, loc)

	descriptor := descriptor
	texture_view.ptr = wgpu.texture_create_view(self.ptr, &descriptor if descriptor != {} else nil)

	if err = get_last_error(); err != nil {
		if texture_view.ptr != nil {
			wgpu.texture_view_release(texture_view.ptr)
		}
	}

	return
}

// Destroy the associated native resources as soon as possible.
texture_destroy :: proc "contextless" (using self: Texture) {
	wgpu.texture_destroy(ptr)
}

// Make an `Image_Copy_Texture` representing the whole texture with the given origin.
texture_as_image_copy :: proc "contextless" (
	using self: Texture,
	origin: Origin_3D = {},
) -> Image_Copy_Texture {
	return {texture = ptr, mip_level = 0, origin = origin, aspect = Texture_Aspect.All}
}

// Returns the size of this `Texture`.
//
// This is always equal to the `size` that was specified when creating the texture.
texture_size :: proc "contextless" (using self: Texture) -> Extent_3D {
	return descriptor.size
}

// Returns the width of this `Texture`.
//
// This is always equal to the `size.width` that was specified when creating the texture.
texture_width :: proc "contextless" (using self: Texture) -> u32 {
	return descriptor.size.width
}

// Returns the height of this `Texture`.
//
// This is always equal to the `size.height` that was specified when creating the texture.
texture_get_height :: proc "contextless" (using self: Texture) -> u32 {
	return descriptor.size.height
}

// Returns the depth or layer count of this `Texture`.
//
// This is always equal to the `size.depth_or_array_layers` that was specified when creating the
// texture.
texture_depth_or_array_layers :: proc "contextless" (using self: Texture) -> u32 {
	return descriptor.size.depth_or_array_layers
}

// Returns the mip_level_count of this `Texture`.
//
// This is always equal to the `mip_level_count` that was specified when creating the texture.
texture_mip_level_count :: proc "contextless" (using self: Texture) -> u32 {
	return descriptor.mip_level_count
}

// Returns the sample_count of this `Texture`.
//
// This is always equal to the `sample_count` that was specified when creating the texture.
texture_sample_count :: proc "contextless" (using self: Texture) -> u32 {
	return descriptor.sample_count
}

// Returns the dimension of this `Texture`.
//
// This is always equal to the `dimension` that was specified when creating the texture.
texture_dimension :: proc "contextless" (using self: Texture) -> Texture_Dimension {
	return descriptor.dimension
}

// Returns the format of this `Texture`.
//
// This is always equal to the `format` that was specified when creating the texture.
texture_format :: proc "contextless" (using self: Texture) -> Texture_Format {
	return descriptor.format
}

// Returns the allowed usages of this `Texture`.
//
// This is always equal to the `usage` that was specified when creating the texture.
texture_usage :: proc "contextless" (using self: Texture) -> Texture_Usage_Flags {
	return descriptor.usage
}

// Set a debug label for this `Texture`.
texture_set_label :: proc "contextless" (self: Texture, label: cstring) {
	wgpu.texture_set_label(self.ptr, label)
}

// Increase the reference count.
texture_reference :: proc "contextless" (using self: Texture) {
	wgpu.texture_reference(ptr)
}

// Release the `Texture`.
texture_release :: #force_inline proc "contextless" (using self: Texture) {
	wgpu.texture_release(ptr)
}

// Release the `Texture` and modify the raw pointer to `nil`.
texture_release_and_nil :: proc "contextless" (using self: ^Texture) {
	if ptr == nil do return
	wgpu.texture_release(ptr)
	ptr = nil
}
