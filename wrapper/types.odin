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
    color = Blend_Component{
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

// Represents the sets of limits an adapter/device supports.
Limits :: struct {
    max_texture_dimension_1d:                        u32,
    max_texture_dimension_2d:                        u32,
    max_texture_dimension_3d:                        u32,
    max_texture_array_layers:                        u32,
    max_bind_groups:                                 u32,
    max_bind_groups_plus_vertex_buffers:             u32,
    max_bindings_per_bind_group:                     u32,
    max_dynamic_uniform_buffers_per_pipeline_layout: u32,
    max_dynamic_storage_buffers_per_pipeline_layout: u32,
    max_sampled_textures_per_shader_stage:           u32,
    max_samplers_per_shader_stage:                   u32,
    max_storage_buffers_per_shader_stage:            u32,
    max_storage_textures_per_shader_stage:           u32,
    max_uniform_buffers_per_shader_stage:            u32,
    max_uniform_buffer_binding_size:                 u64,
    max_storage_buffer_binding_size:                 u64,
    min_uniform_buffer_offset_alignment:             u32,
    min_storage_buffer_offset_alignment:             u32,
    max_vertex_buffers:                              u32,
    max_buffer_size:                                 u64,
    max_vertex_attributes:                           u32,
    max_vertex_buffer_array_stride:                  u32,
    max_inter_stage_shader_components:               u32,
    max_inter_stage_shader_variables:                u32,
    max_color_attachments:                           u32,
    max_color_attachment_bytes_per_sample:           u32,
    max_compute_workgroup_storage_size:              u32,
    max_compute_invocations_per_workgroup:           u32,
    max_compute_workgroup_size_x:                    u32,
    max_compute_workgroup_size_y:                    u32,
    max_compute_workgroup_size_z:                    u32,
    max_compute_workgroups_per_dimension:            u32,
    // Limits extras
    max_push_constant_size:                          u32,
    max_non_sampler_bindings:                        u32,
}

// Features that are part of the webgpu standard and extension features supported by
// wgpu when targeting native.
Features :: enum c.int {
    Depth_Clip_Control                       = 0x00000001,
    Depth32_Float_Stencil8                   = 0x00000002,
    Timestamp_Query                          = 0x00000003,
    Pipeline_Statistics_Query                = 0x00000004,
    Texture_Compression_Bc                   = 0x00000005,
    Texture_Compression_Etc2                 = 0x00000006,
    Texture_Compression_Astc                 = 0x00000007,
    Indirect_First_Instance                  = 0x00000008,
    Shader_F16                               = 0x00000009,
    Rg11_B10_Ufloat_Renderable               = 0x0000000A,
    Bgra8_Unorm_Storage                      = 0x0000000B,
    Float32_Filterable                       = 0x0000000C,
    // Native features
    Push_Constants                           = 0x60000001,
    Texture_Adapter_Specific_Format_Features = 0x60000002,
    Multi_Draw_Indirect                      = 0x60000003,
    Multi_Draw_Indirect_Count                = 0x60000004,
    Vertex_Writable_Storage                  = 0x60000005,
}

// View of a texture which can be used to copy to/from a buffer/texture.
Image_Copy_Texture :: struct {
    texture:   ^Texture,
    mip_level: u32,
    origin:    Origin_3D,
    aspect:    Texture_Aspect,
}
