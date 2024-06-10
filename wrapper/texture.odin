package wgpu

// Package
import wgpu "../bindings"

// Handle to a texture on the GPU.
//
// It can be created with `device_create_texture`.
Texture :: struct {
	ptr:        Raw_Texture,
	descriptor: Texture_Descriptor,
	_err_data:  ^Error_Data,
}

// Creates a view of this texture.
texture_create_view :: proc(
	self: ^Texture,
	descriptor: ^Texture_View_Descriptor = nil,
	loc := #caller_location,
) -> (
	texture_view: Texture_View,
	err: Error,
) {
	set_and_reset_err_data(self._err_data, loc)

	texture_view.ptr = wgpu.texture_create_view(self.ptr, descriptor)

	if err = get_last_error(); err != nil {
		if texture_view.ptr != nil {
			wgpu.texture_view_release(texture_view.ptr)
		}
	}

	return
}

// Destroy the associated native resources as soon as possible.
texture_destroy :: proc(using self: ^Texture) {
	wgpu.texture_destroy(ptr)
}

// Make an `Image_Copy_Texture` representing the whole texture.
texture_as_image_copy :: proc(using self: ^Texture) -> (image_copy_texture: Image_Copy_Texture) {
	image_copy_texture.texture = ptr
	image_copy_texture.mip_level = 0
	image_copy_texture.origin = {0, 0, 0}
	image_copy_texture.aspect = Texture_Aspect.All
	return
}

// Returns the depth or layer count of this `Texture`.
texture_get_depth_or_array_layers :: proc(using self: ^Texture) -> u32 {
	return wgpu.texture_get_depth_or_array_layers(ptr)
}

// Returns the dimension of this `Texture`.
texture_get_dimension :: proc(using self: ^Texture) -> Texture_Dimension {
	return wgpu.texture_get_dimension(ptr)
}

// Returns the format of this `Texture`.
texture_get_format :: proc(using self: ^Texture) -> Texture_Format {
	return wgpu.texture_get_format(ptr)
}

// Returns the height of this `Texture`.
texture_get_height :: proc(using self: ^Texture) -> u32 {
	return wgpu.texture_get_height(ptr)
}

// Returns the `mip_level_count` of this `Texture`.
texture_get_mip_level_count :: proc(using self: ^Texture) -> u32 {
	return wgpu.texture_get_mip_level_count(ptr)
}

// Returns the sample_count of this `Texture`.
texture_get_sample_count :: proc(using self: ^Texture) -> u32 {
	return wgpu.texture_get_sample_count(ptr)
}

// Returns the allowed usages of this `Texture`.
texture_get_usage :: proc(using self: ^Texture) -> Texture_Usage {
	return wgpu.texture_get_usage(ptr)
}

// Returns the width of this `Texture`.
texture_get_width :: proc(using self: ^Texture) -> u32 {
	return wgpu.texture_get_width(ptr)
}

// Set a debug label for this `Texture`.
texture_set_label :: proc(using self: ^Texture, label: cstring) {
	wgpu.texture_set_label(ptr, label)
}

// Increase the reference count.
texture_reference :: proc(using self: ^Texture) {
	wgpu.texture_reference(ptr)
}

// Release the `Texture`.
texture_release :: proc(using self: ^Texture) {
	wgpu.texture_release(ptr)
}

// Release the `Texture` and modify the raw pointer to `nil`.
texture_release_and_nil :: proc(using self: ^Texture) {
	if ptr == nil do return
	wgpu.texture_release(ptr)
	ptr = nil
}
