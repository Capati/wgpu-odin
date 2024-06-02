package wgpu

import wgpu "../bindings"

// Surface texture that can be rendered to. Result of a successful call to
// `surface_get_current_texture`.
//
// This type is unique to the wgpu-native. In the WebGPU specification, the `GPUCanvasContext`
// provides a texture without any additional information.
Surface_Texture :: struct {
	texture:    Texture,
	suboptimal: bool,
	status:     wgpu.Surface_Get_Current_Texture_Status,
}

// Release the texture that belongs to this `Surface_Texture`.
surface_texture_release :: proc(using self: ^Surface_Texture) {
	if texture.ptr == nil do return
	texture_release(&texture)
}
