package wgpu

// Base
import "base:runtime"

// Core
import "core:fmt"
import "core:reflect"
import "core:slice"
import "core:strings"

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

// Modify the current limits to use the resolution limits of the other.
limits_using_resolution :: proc(using self: ^Limits, other: Limits) -> Limits {
	max_texture_dimension_1d = other.max_texture_dimension_1d
	max_texture_dimension_2d = other.max_texture_dimension_2d
	max_texture_dimension_3d = other.max_texture_dimension_3d
	return self^
}

// For `Limits` check. Doesn't use `Ada_Case` for consistency with the struct name.
Limits_Name :: enum {
	max_texture_dimension_1d,
	max_texture_dimension_2d,
	max_texture_dimension_3d,
	max_texture_array_layers,
	max_bind_groups,
	max_bind_groups_plus_vertex_buffers,
	max_bindings_per_bind_group,
	max_dynamic_uniform_buffers_per_pipeline_layout,
	max_dynamic_storage_buffers_per_pipeline_layout,
	max_sampled_textures_per_shader_stage,
	max_samplers_per_shader_stage,
	max_storage_buffers_per_shader_stage,
	max_storage_textures_per_shader_stage,
	max_uniform_buffers_per_shader_stage,
	max_uniform_buffer_binding_size,
	max_storage_buffer_binding_size,
	min_uniform_buffer_offset_alignment,
	min_storage_buffer_offset_alignment,
	max_vertex_buffers,
	max_buffer_size,
	max_vertex_attributes,
	max_vertex_buffer_array_stride,
	max_inter_stage_shader_components,
	max_inter_stage_shader_variables,
	max_color_attachments,
	max_color_attachment_bytes_per_sample,
	max_compute_workgroup_storage_size,
	max_compute_invocations_per_workgroup,
	max_compute_workgroup_size_x,
	max_compute_workgroup_size_y,
	max_compute_workgroup_size_z,
	max_compute_workgroups_per_dimension,

	// Native limits (extras)
	max_push_constant_size,
	max_non_sampler_bindings,
}

Limits_Name_Flags :: bit_set[Limits_Name]

Limit_Violation_Value :: struct {
	current: u64,
	allowed: u64,
}

Limit_Violation_Data :: [Limits_Name]Limit_Violation_Value

Limit_Violation :: struct {
	data:             Limit_Violation_Data,
	flags:            Limits_Name_Flags,
	ok:               bool,
	total_violations: u8,
}

/*
Compares two `Limits` structures and identifies any violations where the `self` limits exceed or
fall short of the `allowed` limits.

Parameters
- `self: Limits`: The limits to be checked.
- `allowed: Limits`: The reference limits that `self` is checked against.

Returns
- `violations: Limit_Violation`: A structure containing information about any limit violations.
*/
@(require_results)
limits_check :: proc(self: Limits, allowed: Limits) -> (violations: Limit_Violation) {
	compare :: proc(
		self_value, allowed_value: u64,
		expected_order: slice.Ordering,
	) -> (
		Limit_Violation_Value,
		bool,
	) {
		order := slice.cmp(self_value, allowed_value)
		// Check if the order is different from expected and not equal
		if order != expected_order && order != .Equal {
			return {self_value, allowed_value}, true
		}
		return {}, false
	}

	check :: proc(
		violations: ^Limit_Violation,
		name: Limits_Name,
		self_value, allowed_value: u64,
		expected_order: slice.Ordering,
	) {
		violation, is_violation := compare(self_value, allowed_value, expected_order)
		if is_violation {
			violations.flags += {name}
			violations.data[name] = violation
			violations.total_violations += 1
		}
	}

	fields := reflect.struct_fields_zipped(Limits)
	// Ensure that the number of fields in Limits matches Limit_Violation_Data
	assert(len(fields) == len(Limit_Violation_Data), "Mismatch limits")

	for &field in fields {
		name := field.name

		self_value := reflect.struct_field_value_by_name(self, name)
		allowed_value := reflect.struct_field_value_by_name(allowed, name)

		// Convert both values to u64 for consistent comparison
		self_u64, allowed_u64: u64
		switch v in self_value {
		case u32:
			self_u64 = u64(v)
		case u64:
			self_u64 = v
		case:
			unreachable() // This should never happen if Limits only contains u32 or u64
		}
		switch v in allowed_value {
		case u32:
			allowed_u64 = u64(v)
		case u64:
			allowed_u64 = v
		case:
			unreachable()
		}

		// Get the corresponding Limits_Name enum value
		limits_name, limits_name_ok := reflect.enum_from_name(Limits_Name, name)
		assert(limits_name_ok, "Invalid limit name")

		expected_order := slice.Ordering.Less
		#partial switch limits_name {
		case .min_uniform_buffer_offset_alignment, .min_storage_buffer_offset_alignment:
			expected_order = .Greater
		}

		check(&violations, limits_name, self_u64, allowed_u64, expected_order)
	}

	violations.ok = violations.flags == {}

	return
}

print_limits_violation :: proc(violation: Limit_Violation) {
	if violation.ok || violation.flags == {} {
		fmt.println("No limits violations detected.")
		return
	}

	fmt.println("Limits violations detected:")

	iter := violation.total_violations

	for name in violation.flags {
		data := violation.data[name]
		fmt.printf("  %s:\n", name)
		fmt.printf("    Current value: %d\n", data.current)
		fmt.printf("    Allowed value: %d\n", data.allowed)
		fmt.printf("    Violation: ")

		if data.current > data.allowed {
			fmt.printf("Value exceeds the maximum allowed.\n")
		} else {
			fmt.printf("Value is below the minimum required.\n")
		}

		if iter > 1 do fmt.println()
		iter -= 1
	}
}

limits_violation_to_string :: proc(
	violation: Limit_Violation,
	allocator := context.allocator,
) -> (
	str: string,
) {
	if violation.ok || violation.flags == {} do return

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == context.temp_allocator)

	b := strings.builder_make(context.temp_allocator)
	defer strings.builder_destroy(&b)

	strings.write_string(&b, "Limits violations detected:\n")

	iter := violation.total_violations

	for name in violation.flags {
		data := violation.data[name]
		fmt.sbprintf(&b, "  %s:\n", name)
		fmt.sbprintf(&b, "    Current value: %d\n", data.current)
		fmt.sbprintf(&b, "    Allowed value: %d\n", data.allowed)
		strings.write_string(&b, "    Violation: ")

		if data.current > data.allowed {
			strings.write_string(&b, "Value exceeds the maximum allowed.\n")
		} else {
			strings.write_string(&b, "Value is below the minimum required.\n")
		}

		if iter > 1 do strings.write_string(&b, "\n")
		iter -= 1
	}

	str = strings.clone(strings.to_string(b), allocator)

	return
}

limits_ensure_minimum :: proc(limits: ^Limits, minimum := DOWNLEVEL_WEBGL2_LIMITS) {
	limits.max_texture_dimension_1d = max(
		limits.max_texture_dimension_1d,
		minimum.max_texture_dimension_1d,
	)
	limits.max_texture_dimension_2d = max(
		limits.max_texture_dimension_2d,
		minimum.max_texture_dimension_2d,
	)
	limits.max_texture_dimension_3d = max(
		limits.max_texture_dimension_3d,
		minimum.max_texture_dimension_3d,
	)
	limits.max_texture_array_layers = max(
		limits.max_texture_array_layers,
		minimum.max_texture_array_layers,
	)
	limits.max_bind_groups = max(limits.max_bind_groups, minimum.max_bind_groups)
	limits.max_bind_groups_plus_vertex_buffers = max(
		limits.max_bind_groups_plus_vertex_buffers,
		minimum.max_bind_groups_plus_vertex_buffers,
	)
	limits.max_bindings_per_bind_group = max(
		limits.max_bindings_per_bind_group,
		minimum.max_bindings_per_bind_group,
	)
	limits.max_dynamic_uniform_buffers_per_pipeline_layout = max(
		limits.max_dynamic_uniform_buffers_per_pipeline_layout,
		minimum.max_dynamic_uniform_buffers_per_pipeline_layout,
	)
	limits.max_dynamic_storage_buffers_per_pipeline_layout = max(
		limits.max_dynamic_storage_buffers_per_pipeline_layout,
		minimum.max_dynamic_storage_buffers_per_pipeline_layout,
	)
	limits.max_sampled_textures_per_shader_stage = max(
		limits.max_sampled_textures_per_shader_stage,
		minimum.max_sampled_textures_per_shader_stage,
	)
	limits.max_samplers_per_shader_stage = max(
		limits.max_samplers_per_shader_stage,
		minimum.max_samplers_per_shader_stage,
	)
	limits.max_storage_buffers_per_shader_stage = max(
		limits.max_storage_buffers_per_shader_stage,
		minimum.max_storage_buffers_per_shader_stage,
	)
	limits.max_storage_textures_per_shader_stage = max(
		limits.max_storage_textures_per_shader_stage,
		minimum.max_storage_textures_per_shader_stage,
	)
	limits.max_uniform_buffers_per_shader_stage = max(
		limits.max_uniform_buffers_per_shader_stage,
		minimum.max_uniform_buffers_per_shader_stage,
	)
	limits.max_uniform_buffer_binding_size = max(
		limits.max_uniform_buffer_binding_size,
		minimum.max_uniform_buffer_binding_size,
	)
	limits.max_storage_buffer_binding_size = max(
		limits.max_storage_buffer_binding_size,
		minimum.max_storage_buffer_binding_size,
	)
	limits.min_uniform_buffer_offset_alignment = max(
		limits.min_uniform_buffer_offset_alignment,
		minimum.min_uniform_buffer_offset_alignment,
	)
	limits.min_storage_buffer_offset_alignment = max(
		limits.min_storage_buffer_offset_alignment,
		minimum.min_storage_buffer_offset_alignment,
	)
	limits.max_vertex_buffers = max(limits.max_vertex_buffers, minimum.max_vertex_buffers)
	limits.max_buffer_size = max(limits.max_buffer_size, minimum.max_buffer_size)
	limits.max_vertex_attributes = max(limits.max_vertex_attributes, minimum.max_vertex_attributes)
	limits.max_vertex_buffer_array_stride = max(
		limits.max_vertex_buffer_array_stride,
		minimum.max_vertex_buffer_array_stride,
	)
	limits.max_inter_stage_shader_components = max(
		limits.max_inter_stage_shader_components,
		minimum.max_inter_stage_shader_components,
	)
	limits.max_inter_stage_shader_variables = max(
		limits.max_inter_stage_shader_variables,
		minimum.max_inter_stage_shader_variables,
	)
	limits.max_color_attachments = max(limits.max_color_attachments, minimum.max_color_attachments)
	limits.max_color_attachment_bytes_per_sample = max(
		limits.max_color_attachment_bytes_per_sample,
		minimum.max_color_attachment_bytes_per_sample,
	)
	limits.max_compute_workgroup_storage_size = max(
		limits.max_compute_workgroup_storage_size,
		minimum.max_compute_workgroup_storage_size,
	)
	limits.max_compute_invocations_per_workgroup = max(
		limits.max_compute_invocations_per_workgroup,
		minimum.max_compute_invocations_per_workgroup,
	)
	limits.max_compute_workgroup_size_x = max(
		limits.max_compute_workgroup_size_x,
		minimum.max_compute_workgroup_size_x,
	)
	limits.max_compute_workgroup_size_y = max(
		limits.max_compute_workgroup_size_y,
		minimum.max_compute_workgroup_size_y,
	)
	limits.max_compute_workgroup_size_z = max(
		limits.max_compute_workgroup_size_z,
		minimum.max_compute_workgroup_size_z,
	)
	limits.max_compute_workgroups_per_dimension = max(
		limits.max_compute_workgroups_per_dimension,
		minimum.max_compute_workgroups_per_dimension,
	)
	limits.max_push_constant_size = max(
		limits.max_push_constant_size,
		minimum.max_push_constant_size,
	)
	limits.max_non_sampler_bindings = max(
		limits.max_non_sampler_bindings,
		minimum.max_non_sampler_bindings,
	)
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
