package wgpu

// Integral type used for buffer offsets.
Buffer_Address :: u64
// Integral type used for buffer slice sizes.
Buffer_Size :: u64
// Integral type used for buffer slice sizes.
Shader_Location :: u32
// Integral type used for dynamic bind group offsets.
Dynamic_Offset :: u32

// Buffer-Texture copies must have [`bytes_per_row`] aligned to this number.
COPY_BYTES_PER_ROW_ALIGNMENT: u32 : 256
// An offset into the query resolve buffer has to be aligned to self.
QUERY_RESOLVE_BUFFER_ALIGNMENT: Buffer_Address : 256
// Buffer to buffer copy as well as buffer clear offsets and sizes must be aligned to
// this number.
COPY_BUFFER_ALIGNMENT: Buffer_Address : 4
// Buffer alignment mask to calculate proper size
COPY_BUFFER_ALIGNMENT_MASK :: COPY_BUFFER_ALIGNMENT - 1
// Size to align mappings.
MAP_ALIGNMENT: Buffer_Address : 8
// Vertex buffer strides have to be aligned to this number.
VERTEX_STRIDE_ALIGNMENT: Buffer_Address : 4
// Alignment all push constants need
PUSH_CONSTANT_ALIGNMENT: u32 : 4
// Maximum queries in a query set
QUERY_SET_MAX_QUERIES: u32 : 8192
// Size of a single piece of query data.
QUERY_SIZE: u32 : 8

// Standard blending state that blends source and destination based on source alpha.
Blend_Component_Normal := Blend_Component {
	operation  = .Add,
	src_factor = .Src_Alpha,
	dst_factor = .One_Minus_Src_Alpha,
}

// Default blending state that replaces destination with the source.
Blend_Component_Replace := Blend_Component {
	operation  = .Add,
	src_factor = .One,
	dst_factor = .Zero,
}

// Blend state of (1 * src) + ((1 - src_alpha) * dst)
Blend_Component_Over := Blend_Component {
	operation  = .Add,
	src_factor = .One,
	dst_factor = .One_Minus_Src_Alpha,
}

Default_Blend_Component := Blend_Component_Replace

// Returns `true` if the state relies on the constant color, which is
// set independently on a render command encoder.
blend_component_uses_constant :: proc(using self: ^Blend_Component) -> bool {
	return(
		src_factor == .Constant ||
		src_factor == .One_Minus_Constant ||
		dst_factor == .Constant ||
		dst_factor == .One_Minus_Constant \
	)
}

// Blend mode that uses alpha blending for both color and alpha channels.
Blend_State_Normal := Blend_State {
	color = Blend_Component_Normal,
	alpha = Blend_Component_Normal,
}

// Blend mode that does no color blending, just overwrites the output with the contents
// of the shader.
Blend_State_Replace := Blend_State {
	color = Blend_Component_Replace,
	alpha = Blend_Component_Replace,
}

// Blend mode that does standard alpha blending with non-premultiplied alpha.
Blend_State_Alpha_Blending := Blend_State {
	color = Blend_Component_Normal,
	alpha = Blend_Component_Over,
}

// Blend mode that does standard alpha blending with premultiplied alpha.
Blend_State_Premultiplied_Alpha_Blending := Blend_State {
	color = Blend_Component_Over,
	alpha = Blend_Component_Over,
}
