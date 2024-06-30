package wgpu

// Package
import wgpu "./../bindings"

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

	// Native limits (extras)
	max_push_constant_size:                          u32,
	max_non_sampler_bindings:                        u32,
}

// This is the set of limits that is guaranteed to work on all modern backends and is
// guaranteed to be supported by WebGPU. Applications needing more modern features can
// use this as a reasonable set of limits if they are targeting only desktop and modern
// mobile devices.
DEFAULT_LIMITS :: Limits {
	max_texture_dimension_1d                        = 8192,
	max_texture_dimension_2d                        = 8192,
	max_texture_dimension_3d                        = 2048,
	max_texture_array_layers                        = 256,
	max_bind_groups                                 = 4,
	max_bind_groups_plus_vertex_buffers             = 24,
	max_bindings_per_bind_group                     = 1000,
	max_dynamic_uniform_buffers_per_pipeline_layout = 8,
	max_dynamic_storage_buffers_per_pipeline_layout = 4,
	max_sampled_textures_per_shader_stage           = 16,
	max_samplers_per_shader_stage                   = 16,
	max_storage_buffers_per_shader_stage            = 8,
	max_storage_textures_per_shader_stage           = 4,
	max_uniform_buffers_per_shader_stage            = 12,
	max_uniform_buffer_binding_size                 = 64 << 10, // (64 KiB)
	max_storage_buffer_binding_size                 = 128 << 20, // (128 MiB)
	min_uniform_buffer_offset_alignment             = 256,
	min_storage_buffer_offset_alignment             = 256,
	max_vertex_buffers                              = 8,
	max_buffer_size                                 = 256 << 20, // (256 MiB)
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

	// Native limits (extras)
	max_push_constant_size                          = 0,
	max_non_sampler_bindings                        = 1_000_000,
}

// This is a set of limits that is guaranteed to work on almost all backends, including
// “downlevel” backends such as OpenGL and D3D11, other than WebGL. For most applications
// we recommend using these limits, assuming they are high enough for your application,
// and you do not intent to support WebGL.
DOWNLEVEL_LIMITS :: Limits {
	max_texture_dimension_1d                        = 2048,
	max_texture_dimension_2d                        = 2048,
	max_texture_dimension_3d                        = 256,
	max_texture_array_layers                        = 256,
	max_bind_groups                                 = 4,
	max_bind_groups_plus_vertex_buffers             = 24,
	max_bindings_per_bind_group                     = 1000,
	max_dynamic_uniform_buffers_per_pipeline_layout = 8,
	max_dynamic_storage_buffers_per_pipeline_layout = 4,
	max_sampled_textures_per_shader_stage           = 16,
	max_samplers_per_shader_stage                   = 16,
	max_storage_buffers_per_shader_stage            = 4,
	max_storage_textures_per_shader_stage           = 4,
	max_uniform_buffers_per_shader_stage            = 12,
	max_uniform_buffer_binding_size                 = 16 << 10, // (16 KiB)
	max_storage_buffer_binding_size                 = 128 << 20, // (128 MiB)
	min_uniform_buffer_offset_alignment             = 256,
	min_storage_buffer_offset_alignment             = 256,
	max_vertex_buffers                              = 8,
	max_buffer_size                                 = 256 << 20, // (256 MiB)
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

	// Native limits (extras)
	max_push_constant_size                          = 0,
	max_non_sampler_bindings                        = 1_000_000,
}

// This is a set of limits that is lower even than the `DOWNLEVEL_LIMITS`, configured
// to be low enough to support running in the browser using WebGL2.
DOWNLEVEL_WEBGL2_LIMITS :: Limits {
	max_texture_dimension_1d                        = 2048,
	max_texture_dimension_2d                        = 2048,
	max_texture_dimension_3d                        = 256,
	max_texture_array_layers                        = 256,
	max_bind_groups                                 = 4,
	max_bind_groups_plus_vertex_buffers             = 24,
	max_bindings_per_bind_group                     = 1000,
	max_dynamic_uniform_buffers_per_pipeline_layout = 8,
	max_dynamic_storage_buffers_per_pipeline_layout = 0,
	max_sampled_textures_per_shader_stage           = 16,
	max_samplers_per_shader_stage                   = 16,
	max_storage_buffers_per_shader_stage            = 0,
	max_storage_textures_per_shader_stage           = 0,
	max_uniform_buffers_per_shader_stage            = 11,
	max_uniform_buffer_binding_size                 = 16 << 10, // (16 KiB)
	max_storage_buffer_binding_size                 = 0,
	min_uniform_buffer_offset_alignment             = 256,
	min_storage_buffer_offset_alignment             = 256,
	max_vertex_buffers                              = 8,
	max_buffer_size                                 = 256 << 20, // (256 MiB)
	max_vertex_attributes                           = 16,
	max_vertex_buffer_array_stride                  = 255,
	max_inter_stage_shader_components               = 31,
	max_inter_stage_shader_variables                = 16,
	max_color_attachments                           = 8,
	max_color_attachment_bytes_per_sample           = 32,
	max_compute_workgroup_storage_size              = 0,
	max_compute_invocations_per_workgroup           = 0,
	max_compute_workgroup_size_x                    = 0,
	max_compute_workgroup_size_y                    = 0,
	max_compute_workgroup_size_z                    = 0,
	max_compute_workgroups_per_dimension            = 0,

	// Native limits (extras)
	max_push_constant_size                          = 0,
	max_non_sampler_bindings                        = 1_000_000,
}

@(private)
limits_merge_webgpu_with_native :: proc(
	webgpu: wgpu.Limits,
	native: wgpu.Native_Limits,
) -> (
	limits: Limits,
) {
	limits = {
		max_texture_dimension_1d                        = webgpu.max_texture_dimension_1d,
		max_texture_dimension_2d                        = webgpu.max_texture_dimension_2d,
		max_texture_dimension_3d                        = webgpu.max_texture_dimension_3d,
		max_texture_array_layers                        = webgpu.max_texture_array_layers,
		max_bind_groups                                 = webgpu.max_bind_groups,
		max_bind_groups_plus_vertex_buffers             = webgpu.max_bind_groups_plus_vertex_buffers,
		max_bindings_per_bind_group                     = webgpu.max_bindings_per_bind_group,
		max_dynamic_uniform_buffers_per_pipeline_layout = webgpu.max_dynamic_uniform_buffers_per_pipeline_layout,
		max_dynamic_storage_buffers_per_pipeline_layout = webgpu.max_dynamic_storage_buffers_per_pipeline_layout,
		max_sampled_textures_per_shader_stage           = webgpu.max_sampled_textures_per_shader_stage,
		max_samplers_per_shader_stage                   = webgpu.max_samplers_per_shader_stage,
		max_storage_buffers_per_shader_stage            = webgpu.max_storage_buffers_per_shader_stage,
		max_storage_textures_per_shader_stage           = webgpu.max_storage_textures_per_shader_stage,
		max_uniform_buffers_per_shader_stage            = webgpu.max_uniform_buffers_per_shader_stage,
		max_uniform_buffer_binding_size                 = webgpu.max_uniform_buffer_binding_size,
		max_storage_buffer_binding_size                 = webgpu.max_storage_buffer_binding_size,
		min_uniform_buffer_offset_alignment             = webgpu.min_uniform_buffer_offset_alignment,
		min_storage_buffer_offset_alignment             = webgpu.min_storage_buffer_offset_alignment,
		max_vertex_buffers                              = webgpu.max_vertex_buffers,
		max_buffer_size                                 = webgpu.max_buffer_size,
		max_vertex_attributes                           = webgpu.max_vertex_attributes,
		max_vertex_buffer_array_stride                  = webgpu.max_vertex_buffer_array_stride,
		max_inter_stage_shader_components               = webgpu.max_inter_stage_shader_components,
		max_inter_stage_shader_variables                = webgpu.max_inter_stage_shader_variables,
		max_color_attachments                           = webgpu.max_color_attachments,
		max_color_attachment_bytes_per_sample           = webgpu.max_color_attachment_bytes_per_sample,
		max_compute_workgroup_storage_size              = webgpu.max_compute_workgroup_storage_size,
		max_compute_invocations_per_workgroup           = webgpu.max_compute_invocations_per_workgroup,
		max_compute_workgroup_size_x                    = webgpu.max_compute_workgroup_size_x,
		max_compute_workgroup_size_y                    = webgpu.max_compute_workgroup_size_y,
		max_compute_workgroup_size_z                    = webgpu.max_compute_workgroup_size_z,
		max_compute_workgroups_per_dimension            = webgpu.max_compute_workgroups_per_dimension,

		// Native limits (extras)
		max_push_constant_size                          = native.max_push_constant_size,
		max_non_sampler_bindings                        = native.max_non_sampler_bindings,
	}

	return
}
