package wgpu

// Package
import wgpu "../bindings"

// Handle to a texture on the GPU.
//
// It can be created with `device_create_texture`.
Texture :: struct {
	ptr:              Raw_Texture,
	using descriptor: Texture_Descriptor,
	released:         bool,
	_err_data:        ^Error_Data,
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

// Returns the depth or layer count of this `Texture`.
texture_get_depth_or_array_layers :: proc(using self: ^Texture) -> u32 {
	return descriptor.size.depth_or_array_layers
}

// Returns the dimension of this `Texture`.
texture_get_dimension :: proc(using self: ^Texture) -> Texture_Dimension {
	return descriptor.dimension
}

// Returns the format of this `Texture`.
texture_get_format :: proc(using self: ^Texture) -> Texture_Format {
	return descriptor.format
}

// Returns the height of this `Texture`.
texture_get_height :: proc(using self: ^Texture) -> u32 {
	return descriptor.size.height
}

// Returns the `mip_level_count` of this `Texture`.
texture_get_mip_level_count :: proc(using self: ^Texture) -> u32 {
	return descriptor.mip_level_count
}

// Returns the sample_count of this `Texture`.
texture_get_sample_count :: proc(using self: ^Texture) -> u32 {
	return descriptor.sample_count
}

// Returns the allowed usages of this `Texture`.
texture_get_usage :: proc(using self: ^Texture) -> Texture_Usage_Flags {
	return descriptor.usage
}

// Returns the width of this `Texture`.
texture_get_width :: proc(using self: ^Texture) -> u32 {
	return descriptor.size.width
}

// Set a debug label for this `Texture`.
texture_set_label :: proc(self: ^Texture, label: cstring) {
	wgpu.texture_set_label(self.ptr, label)
}

// Increase the reference count.
texture_reference :: proc(using self: ^Texture) {
	wgpu.texture_reference(ptr)
}

// Release the `Texture`.
texture_release :: proc(using self: ^Texture) {
	wgpu.texture_release(ptr)
	released = true
}

// Release the `Texture` and modify the raw pointer to `nil`.
texture_release_and_nil :: proc(using self: ^Texture) {
	if ptr == nil do return
	texture_release(self)
	ptr = nil
}
