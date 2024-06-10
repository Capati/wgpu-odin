package wgpu

import "core:c"

// Integral type used for buffer offsets.
Buffer_Address :: u64
// Integral type used for buffer slice sizes.
Buffer_Size :: u64
// Integral type used for buffer slice sizes.
Shader_Location :: u32
// Integral type used for dynamic bind group offsets.
Dynamic_Offset :: u32

// Buffer-Texture copies must have [`bytes_per_row`] aligned to this number.
Copy_Bytes_Per_Row_Alignment: u32 : 256
// An offset into the query resolve buffer has to be aligned to self.
Query_Resolve_Buffer_Alignment: Buffer_Address : 256
// Buffer to buffer copy as well as buffer clear offsets and sizes must be aligned to
// this number.
Copy_Buffer_Alignment: Buffer_Address : 4
// Buffer alignment mask to calculate proper size
Copy_Buffer_Alignment_Mask :: Copy_Buffer_Alignment - 1
// Size to align mappings.
Map_Alignment: Buffer_Address : 8
// Vertex buffer strides have to be aligned to this number.
Vertex_Stride_Alignment: Buffer_Address : 4
// Alignment all push constants need
Push_Constant_Alignment: u32 : 4
// Maximum queries in a query set
Query_Set_Max_Queries: u32 : 8192
// Size of a single piece of query data.
Query_Size: u32 : 8

Blend_Component_Replace := Blend_Component {
	operation  = .Add,
	src_factor = .One,
	dst_factor = .Zero,
}

Blend_Component_Over := Blend_Component {
	operation  = .Add,
	src_factor = .One,
	dst_factor = .One_Minus_Src_Alpha,
}

Blend_State_Replace := Blend_State {
	color = Blend_Component_Replace,
	alpha = Blend_Component_Replace,
}

Blend_State_Alpha_Blending := Blend_State {
	color = Blend_Component {
		operation = .Add,
		src_factor = .Src_Alpha,
		dst_factor = .One_Minus_Src_Alpha,
	},
	alpha = Blend_Component_Over,
}

Blend_State_Premultiplied_Alpha_Blending := Blend_State {
	color = Blend_Component_Over,
	alpha = Blend_Component_Over,
}

// Features that are part of the webgpu standard and extension features supported by
// wgpu when targeting native.
Feature :: enum c.int {
	Depth_Clip_Control                                            = 0x00000001,
	Depth32_Float_Stencil8                                        = 0x00000002,
	Timestamp_Query                                               = 0x00000003,
	Texture_Compression_Bc                                        = 0x00000004,
	Texture_Compression_Etc2                                      = 0x00000005,
	Texture_Compression_Astc                                      = 0x00000006,
	Indirect_First_Instance                                       = 0x00000007,
	Shader_F16                                                    = 0x00000008,
	Rg11_B10_Ufloat_Renderable                                    = 0x00000009,
	Bgra8_Unorm_Storage                                           = 0x0000000A,
	Float32_Filterable                                            = 0x0000000B,
	// Native features
	Push_Constants                                                = 0x00030001,
	Texture_Adapter_Specific_Format_Features                      = 0x00030002,
	Multi_Draw_Indirect                                           = 0x00030003,
	Multi_Draw_Indirect_Count                                     = 0x00030004,
	Vertex_Writable_Storage                                       = 0x00030005,
	Texture_Binding_Array                                         = 0x00030006,
	Sampled_Texture_And_Storage_Buffer_Array_Non_Uniform_Indexing = 0x00030007,
	Pipeline_Statistics_Query                                     = 0x00030008,
}
