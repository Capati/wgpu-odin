package wgpu

// Make an `Image_Copy_Texture` representing the whole texture.
texture_as_image_copy :: proc(using self: ^Texture) -> (image_copy_texture: Image_Copy_Texture) {
	image_copy_texture.texture = ptr
	image_copy_texture.mip_level = 0
	image_copy_texture.origin = {0, 0, 0}
	image_copy_texture.aspect = Texture_Aspect.All
	return
}
