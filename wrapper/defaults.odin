package wgpu

// This is the set of limits that is guaranteed to work on all modern backends and is
// guaranteed to be supported by WebGPU. Applications needing more modern features can
// use this as a reasonable set of limits if they are targeting only desktop and modern
// mobile devices.
Default_Limits :: Limits {
    max_texture_dimension_1d                        = 8192,
    max_texture_dimension_2d                        = 8192,
    max_texture_dimension_3d                        = 2048,
    max_texture_array_layers                        = 256,
    max_bind_groups                                 = 4,
    max_bindings_per_bind_group                     = 640,
    max_dynamic_uniform_buffers_per_pipeline_layout = 8,
    max_dynamic_storage_buffers_per_pipeline_layout = 4,
    max_sampled_textures_per_shader_stage           = 16,
    max_samplers_per_shader_stage                   = 16,
    max_storage_buffers_per_shader_stage            = 8,
    max_storage_textures_per_shader_stage           = 4,
    max_uniform_buffers_per_shader_stage            = 12,
    max_uniform_buffer_binding_size                 = 64 << 10,
    max_storage_buffer_binding_size                 = 128 << 20,
    min_uniform_buffer_offset_alignment             = 256,
    min_storage_buffer_offset_alignment             = 256,
    max_vertex_buffers                              = 8,
    max_buffer_size                                 = 1 << 28,
    max_vertex_attributes                           = 16,
    max_vertex_buffer_array_stride                  = 2048,
    max_inter_stage_shader_components               = 60,
    max_inter_stage_shader_variables                = 16,
    max_color_attachments                           = 8,
    max_color_attachment_bytes_per_sample           = 32,
    max_compute_workgroup_storage_size              = 16384,
    max_compute_invocations_per_workgroup           = 256,
    max_compute_workgroup_size_x                    = 256,
    max_compute_workgroup_size_y                    = 256,
    max_compute_workgroup_size_z                    = 64,
    max_compute_workgroups_per_dimension            = 65535,
    // Extras
    max_push_constant_size                          = 0,
}

// This is a set of limits that is guaranteed to work on almost all backends, including
// “downlevel” backends such as OpenGL and D3D11, other than WebGL. For most applications
// we recommend using these limits, assuming they are high enough for your application,
// and you do not intent to support WebGL.
Downlevel_Limits :: Limits {
    max_texture_dimension_1d                        = 2048,
    max_texture_dimension_2d                        = 2048,
    max_texture_dimension_3d                        = 256,
    max_texture_array_layers                        = 256,
    max_bind_groups                                 = 4,
    max_bindings_per_bind_group                     = 640,
    max_dynamic_uniform_buffers_per_pipeline_layout = 8,
    max_dynamic_storage_buffers_per_pipeline_layout = 4,
    max_sampled_textures_per_shader_stage           = 16,
    max_samplers_per_shader_stage                   = 16,
    max_storage_buffers_per_shader_stage            = 4,
    max_storage_textures_per_shader_stage           = 4,
    max_uniform_buffers_per_shader_stage            = 12,
    max_uniform_buffer_binding_size                 = 16 << 10,
    max_storage_buffer_binding_size                 = 128 << 20,
    min_uniform_buffer_offset_alignment             = 256,
    min_storage_buffer_offset_alignment             = 256,
    max_vertex_buffers                              = 8,
    max_buffer_size                                 = 1 << 28,
    max_vertex_attributes                           = 16,
    max_vertex_buffer_array_stride                  = 2048,
    max_inter_stage_shader_components               = 60,
    max_inter_stage_shader_variables                = 16,
    max_color_attachments                           = 8,
    max_color_attachment_bytes_per_sample           = 32,
    max_compute_workgroup_storage_size              = 16352,
    max_compute_invocations_per_workgroup           = 256,
    max_compute_workgroup_size_x                    = 256,
    max_compute_workgroup_size_y                    = 256,
    max_compute_workgroup_size_z                    = 64,
    max_compute_workgroups_per_dimension            = 65535,
    // Extras
    max_push_constant_size                          = 0,
}

// This is a set of limits that is lower even than the `Downlevel_Limits`, configured
// to be low enough to support running in the browser using WebGL2.
Downlevel_Webgl2_D_Limits :: Limits {
    max_texture_dimension_1d                        = 2048,
    max_texture_dimension_2d                        = 2048,
    max_texture_dimension_3d                        = 256,
    max_texture_array_layers                        = 256,
    max_bind_groups                                 = 4,
    max_bindings_per_bind_group                     = 640,
    max_dynamic_uniform_buffers_per_pipeline_layout = 8,
    max_dynamic_storage_buffers_per_pipeline_layout = 0,
    max_sampled_textures_per_shader_stage           = 16,
    max_samplers_per_shader_stage                   = 16,
    max_storage_buffers_per_shader_stage            = 0,
    max_storage_textures_per_shader_stage           = 0,
    max_uniform_buffers_per_shader_stage            = 11,
    max_uniform_buffer_binding_size                 = 16 << 10,
    max_storage_buffer_binding_size                 = 0,
    min_uniform_buffer_offset_alignment             = 256,
    min_storage_buffer_offset_alignment             = 256,
    max_vertex_buffers                              = 8,
    max_buffer_size                                 = 1 << 28,
    max_vertex_attributes                           = 16,
    max_vertex_buffer_array_stride                  = 255,
    max_inter_stage_shader_components               = 60,
    max_inter_stage_shader_variables                = 16,
    max_color_attachments                           = 8,
    max_color_attachment_bytes_per_sample           = 32,
    max_compute_workgroup_storage_size              = 0,
    max_compute_invocations_per_workgroup           = 0,
    max_compute_workgroup_size_x                    = 0,
    max_compute_workgroup_size_y                    = 0,
    max_compute_workgroup_size_z                    = 0,
    max_compute_workgroups_per_dimension            = 0,
    // Extras
    max_push_constant_size                          = 0,
}

Sampler_Descriptor_Default :: Sampler_Descriptor {
    label          = nil,
    address_mode_u = .Clamp_To_Edge,
    address_mode_v = .Clamp_To_Edge,
    address_mode_w = .Clamp_To_Edge,
    mag_filter     = .Nearest,
    min_filter     = .Nearest,
    mipmap_filter  = .Nearest,
    lod_min_clamp  = 0.0,
    lod_max_clamp  = 32.0,
    compare        = .Undefined,
    max_anisotropy = 1,
}

Multisample_State_Default := Multisample_State {
    next_in_chain             = nil,
    count                     = 1,
    mask                      = ~u32(0), // 0xFFFFFFFF
    alpha_to_coverage_enabled = false,
}
