package wgpu

// Package
import wgpu "../bindings"

// Handle to a texture on the GPU.
//
// It can be created with `device_create_texture`.
Texture :: struct {
	ptr:        WGPU_Texture,
	descriptor: Texture_Descriptor,
	_err_data:  ^Error_Data,
}

// Creates a view of this texture.
texture_create_view :: proc(
	self: ^Texture,
	descriptor: ^Texture_View_Descriptor = nil,
) -> (
	texture_view: Texture_View,
	err: Error_Type,
) {
	self._err_data.type = .No_Error

	texture_view.ptr = wgpu.texture_create_view(self.ptr, descriptor)

	if self._err_data.type != .No_Error {
		if texture_view.ptr != nil {
			wgpu.texture_view_release(texture_view.ptr)
		}
		return {}, self._err_data.type
	}

	return
}

// Destroy the associated native resources as soon as possible.
texture_destroy :: proc(using self: ^Texture) {
	wgpu.texture_destroy(ptr)
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
	if ptr == nil do return
	wgpu.texture_release(ptr)
	ptr = nil
}
