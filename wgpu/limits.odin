package wgpu

// Packages
import "base:runtime"
import "core:fmt"
import "core:log"
import "core:reflect"
import "core:slice"
import "core:strings"

/*
Represents the sets of limits an adapter/device supports.

We provide three different defaults.
- [`Limits::downlevel_defaults()`].This is a set of limits that is guaranteed to work on almost
all backends, including "downlevel" backends such as OpenGL and D3D11, other than WebGL.For
most applications we recommend using these limits, assuming they are high enough for your
application, and you do not intent to support WebGL.
- [`Limits::downlevel_webgl2_defaults()`] This is a set of limits that is lower even than the
[`downlevel_defaults()`], configured to be low enough to support running in the browser using
WebGL2.
- [`Limits::default()`].This is the set of limits that is guaranteed to work on all modern
backends and is guaranteed to be supported by WebGPU.Applications needing more modern
features can use this as a reasonable set of limits if they are targeting only desktop and
modern mobile devices.

We recommend starting with the most restrictive limits you can and manually increasing the
limits you need boosted.This will let you stay running on all hardware that supports the limits
you need.

Limits "better" than the default must be supported by the adapter and requested when requesting
a device.If limits "better" than the adapter supports are requested, requesting a device will
panic.Once a device is requested, you may only use resources up to the limits requested _even_
if the adapter supports "better" limits.

Requesting limits that are "better" than you need may cause performance to decrease because the
implementation needs to support more than is needed.You should ideally only request exactly
what you need.

Corresponds to [WebGPU `GPUSupportedLimits`](
https://gpuweb.github.io/gpuweb/#gpusupportedlimits).
*/
Limits :: struct {
	// WebGPU
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
	max_inter_stage_shader_variables:                u32,
	max_color_attachments:                           u32,
	max_color_attachment_bytes_per_sample:           u32,
	max_compute_workgroup_storage_size:              u32,
	max_compute_invocations_per_workgroup:           u32,
	max_compute_workgroup_size_x:                    u32,
	max_compute_workgroup_size_y:                    u32,
	max_compute_workgroup_size_z:                    u32,
	max_compute_workgroups_per_dimension:            u32,

	// Native
	max_push_constant_size:                          u32,
	max_non_sampler_bindings:                        u32,
}

/*
This is the set of limits that is guaranteed to work on all modern backends and is
guaranteed to be supported by WebGPU.Applications needing more modern features can
use this as a reasonable set of limits if they are targeting only desktop and modern
mobile devices.
*/
DEFAULT_LIMITS :: Limits {
	// WebGPU
	max_texture_dimension_1d                        = 8192, // 8k
	max_texture_dimension_2d                        = 8192, // 8k
	max_texture_dimension_3d                        = 2048, // 2k
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
	max_uniform_buffer_binding_size                 = 64 << 10, // 64 KiB
	max_storage_buffer_binding_size                 = 128 << 20, // 128MB
	min_uniform_buffer_offset_alignment             = 256,
	min_storage_buffer_offset_alignment             = 256,
	max_vertex_buffers                              = 8,
	max_buffer_size                                 = 256 << 20, // 256MB
	max_vertex_attributes                           = 16,
	max_vertex_buffer_array_stride                  = 2048,
	max_inter_stage_shader_variables                = 60,
	max_color_attachments                           = 8,
	max_color_attachment_bytes_per_sample           = 32,
	max_compute_workgroup_storage_size              = 16384,
	max_compute_invocations_per_workgroup           = 256,
	max_compute_workgroup_size_x                    = 256,
	max_compute_workgroup_size_y                    = 256,
	max_compute_workgroup_size_z                    = 64,
	max_compute_workgroups_per_dimension            = 65535,

	// Native
	max_push_constant_size                          = 0,
	max_non_sampler_bindings                        = 1_000_000,
}

/*
This is a set of limits that is guaranteed to work on almost all backends, including
“downlevel” backends such as OpenGL and D3D11, other than WebGL.For most applications
we recommend using these limits, assuming they are high enough for your application,
and you {
not intent to support WebGL.}
*/
DOWNLEVEL_LIMITS :: Limits {
	// WebGPU
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
	max_inter_stage_shader_variables                = 16,
	max_color_attachments                           = 8,
	max_color_attachment_bytes_per_sample           = 32,
	max_compute_workgroup_storage_size              = 16352,
	max_compute_invocations_per_workgroup           = 256,
	max_compute_workgroup_size_x                    = 256,
	max_compute_workgroup_size_y                    = 256,
	max_compute_workgroup_size_z                    = 64,
	max_compute_workgroups_per_dimension            = 65535,

	// Native
	max_push_constant_size                          = 0,
	max_non_sampler_bindings                        = 1_000_000,
}

/*
This is a set of limits that is lower even than the `DOWNLEVEL_LIMITS`, configured
to be low enough to support running in the browser using WebGL2.
*/
DOWNLEVEL_WEBGL2_LIMITS :: Limits {
	// WebGPU
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

DEFAULT_MINIMUM_LIMITS :: DOWNLEVEL_LIMITS

/*
Modify the current limits to use the resolution limits of the other.

This is useful because the swapchain might need to be larger than any other image in the application.

If your application only needs 512x512, you might be running on a 4k display and need extremely high resolution limits.
*/
limits_using_resolution :: proc(self: ^Limits, other: Limits) -> Limits {
	self.max_texture_dimension_1d = other.max_texture_dimension_1d
	self.max_texture_dimension_2d = other.max_texture_dimension_2d
	self.max_texture_dimension_3d = other.max_texture_dimension_3d
	return self^
}

/*
Modify the current limits to use the buffer alignment limits of the adapter.

This is useful for when you'd like to dynamically use the "best" supported buffer alignments.
*/
limits_using_alignment :: proc(self: ^Limits, other: Limits) -> Limits {
	self.min_uniform_buffer_offset_alignment = other.min_uniform_buffer_offset_alignment
	self.min_storage_buffer_offset_alignment = other.min_storage_buffer_offset_alignment
	return self^
}

/* For `Limits` check.Doesn't use `Pascal` for consistency with the struct name.*/
LimitName :: enum {
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
	max_inter_stage_shader_variables,
	max_color_attachments,
	max_color_attachment_bytes_per_sample,
	max_compute_workgroup_storage_size,
	max_compute_invocations_per_workgroup,
	max_compute_workgroup_size_x,
	max_compute_workgroup_size_y,
	max_compute_workgroup_size_z,
	max_compute_workgroups_per_dimension,

	// Native
	max_push_constant_size,
	max_non_sampler_bindings,
}

LimitsNameFlags :: bit_set[LimitName]

LimitViolationValue :: struct {
	current: u64,
	allowed: u64,
}

LimitViolationData :: [LimitName]LimitViolationValue

LimitViolation :: struct {
	data:             LimitViolationData,
	flags:            LimitsNameFlags,
	ok:               bool,
	total_violations: u8,
}

/*
Compares two `Limits` structures and identifies any violations where the `self` limits exceed or
fall short of the `allowed` limits.

**Inputs**
- `self: Limits`: The limits to be checked.
- `allowed: Limits`: The reference limits that `self` is checked against.

**Returns**
- `violations: LimitViolation`: A structure containing information about any limit violations.
*/
@(require_results)
limits_check :: proc(
	self: Limits,
	allowed: Limits,
) -> (
	violations: LimitViolation,
	ok: bool,
) #optional_ok {
	compare :: proc(
		self_value, allowed_value: u64,
		expected_order: slice.Ordering,
	) -> (
		LimitViolationValue,
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
		violations: ^LimitViolation,
		name: LimitName,
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
	// Ensure that the number of fields in Limits matches LimitViolationData
	assert(len(fields) == len(LimitViolationData), "Mismatch limits")

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

		// Get the corresponding LimitName enum value
		limits_name, limits_name_ok := reflect.enum_from_name(LimitName, name)
		assert(limits_name_ok, "Invalid limit name")

		expected_order := slice.Ordering.Less
		#partial switch limits_name {
		case .min_uniform_buffer_offset_alignment, .min_storage_buffer_offset_alignment:
			expected_order = .Greater
		}

		check(&violations, limits_name, self_u64, allowed_u64, expected_order)
	}

	violations.ok = violations.flags == {}
	ok = violations.ok

	return
}

log_limits_violation :: proc(violation: LimitViolation) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	violation_str := limits_violation_to_string(violation, context.temp_allocator)
	log.fatalf("Limits violations detected:\n%s", violation_str)
}

limits_violation_to_string :: proc(
	violation: LimitViolation,
	allocator := context.allocator,
) -> (
	str: string,
) {
	if violation.ok || violation.flags == {} {
		return
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == context.temp_allocator)

	b := strings.builder_make(context.temp_allocator)
	defer strings.builder_destroy(&b)

	iter := violation.total_violations

	for name in violation.flags {
		data := violation.data[name]
		fmt.sbprintf(&b, "%s:\n", name)
		fmt.sbprintf(&b, "  Current value: %d\n", data.current)
		fmt.sbprintf(&b, "  Allowed value: %d\n", data.allowed)
		strings.write_string(&b, "  Violation: ")

		if data.current > data.allowed {
			strings.write_string(&b, "Value exceeds the maximum allowed.\n")
		} else {
			strings.write_string(&b, "Value is below the minimum required.\n")
		}

		if iter > 1 {
			strings.write_string(&b, "\n")
		}
		iter -= 1
	}

	str = strings.clone(strings.to_string(b), allocator)

	return
}

limits_ensure_minimum :: proc "contextless" (a: ^Limits, b := DEFAULT_MINIMUM_LIMITS) -> Limits {
	// WebGPU
	a.max_texture_dimension_1d = max(a.max_texture_dimension_1d, b.max_texture_dimension_1d)
	a.max_texture_dimension_2d = max(a.max_texture_dimension_2d, b.max_texture_dimension_2d)
	a.max_texture_dimension_3d = max(a.max_texture_dimension_3d, b.max_texture_dimension_3d)
	a.max_texture_array_layers = max(a.max_texture_array_layers, b.max_texture_array_layers)
	a.max_bind_groups = max(a.max_bind_groups, b.max_bind_groups)
	a.max_bind_groups_plus_vertex_buffers = max(
		a.max_bind_groups_plus_vertex_buffers,
		b.max_bind_groups_plus_vertex_buffers,
	)
	a.max_bindings_per_bind_group = max(
		a.max_bindings_per_bind_group,
		b.max_bindings_per_bind_group,
	)
	a.max_dynamic_uniform_buffers_per_pipeline_layout = max(
		a.max_dynamic_uniform_buffers_per_pipeline_layout,
		b.max_dynamic_uniform_buffers_per_pipeline_layout,
	)
	a.max_dynamic_storage_buffers_per_pipeline_layout = max(
		a.max_dynamic_storage_buffers_per_pipeline_layout,
		b.max_dynamic_storage_buffers_per_pipeline_layout,
	)
	a.max_sampled_textures_per_shader_stage = max(
		a.max_sampled_textures_per_shader_stage,
		b.max_sampled_textures_per_shader_stage,
	)
	a.max_samplers_per_shader_stage = max(
		a.max_samplers_per_shader_stage,
		b.max_samplers_per_shader_stage,
	)
	a.max_storage_buffers_per_shader_stage = max(
		a.max_storage_buffers_per_shader_stage,
		b.max_storage_buffers_per_shader_stage,
	)
	a.max_storage_textures_per_shader_stage = max(
		a.max_storage_textures_per_shader_stage,
		b.max_storage_textures_per_shader_stage,
	)
	a.max_uniform_buffers_per_shader_stage = max(
		a.max_uniform_buffers_per_shader_stage,
		b.max_uniform_buffers_per_shader_stage,
	)
	a.max_uniform_buffer_binding_size = max(
		a.max_uniform_buffer_binding_size,
		b.max_uniform_buffer_binding_size,
	)
	a.max_storage_buffer_binding_size = max(
		a.max_storage_buffer_binding_size,
		b.max_storage_buffer_binding_size,
	)
	a.min_uniform_buffer_offset_alignment = min(
		a.min_uniform_buffer_offset_alignment,
		b.min_uniform_buffer_offset_alignment,
	)
	a.min_storage_buffer_offset_alignment = min(
		a.min_storage_buffer_offset_alignment,
		b.min_storage_buffer_offset_alignment,
	)
	a.max_vertex_buffers = max(a.max_vertex_buffers, b.max_vertex_buffers)
	a.max_buffer_size = max(a.max_buffer_size, b.max_buffer_size)
	a.max_vertex_attributes = max(a.max_vertex_attributes, b.max_vertex_attributes)
	a.max_vertex_buffer_array_stride = max(
		a.max_vertex_buffer_array_stride,
		b.max_vertex_buffer_array_stride,
	)
	a.max_inter_stage_shader_variables = max(
		a.max_inter_stage_shader_variables,
		b.max_inter_stage_shader_variables,
	)
	a.max_color_attachments = max(a.max_color_attachments, b.max_color_attachments)
	a.max_color_attachment_bytes_per_sample = max(
		a.max_color_attachment_bytes_per_sample,
		b.max_color_attachment_bytes_per_sample,
	)
	a.max_compute_workgroup_storage_size = max(
		a.max_compute_workgroup_storage_size,
		b.max_compute_workgroup_storage_size,
	)
	a.max_compute_invocations_per_workgroup = max(
		a.max_compute_invocations_per_workgroup,
		b.max_compute_invocations_per_workgroup,
	)
	a.max_compute_workgroup_size_x = max(
		a.max_compute_workgroup_size_x,
		b.max_compute_workgroup_size_x,
	)
	a.max_compute_workgroup_size_y = max(
		a.max_compute_workgroup_size_y,
		b.max_compute_workgroup_size_y,
	)
	a.max_compute_workgroup_size_z = max(
		a.max_compute_workgroup_size_z,
		b.max_compute_workgroup_size_z,
	)
	a.max_compute_workgroups_per_dimension = max(
		a.max_compute_workgroups_per_dimension,
		b.max_compute_workgroups_per_dimension,
	)

	// Native
	a.max_push_constant_size = max(a.max_push_constant_size, b.max_push_constant_size)
	a.max_non_sampler_bindings = max(a.max_non_sampler_bindings, b.max_non_sampler_bindings)

	return a^
}

limits_merge_webgpu_with_native :: proc "contextless" (
	webgpu: WGPULimits,
	native: WGPUNativeLimits,
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
		max_inter_stage_shader_variables                = webgpu.max_inter_stage_shader_variables,
		max_color_attachments                           = webgpu.max_color_attachments,
		max_color_attachment_bytes_per_sample           = webgpu.max_color_attachment_bytes_per_sample,
		max_compute_workgroup_storage_size              = webgpu.max_compute_workgroup_storage_size,
		max_compute_invocations_per_workgroup           = webgpu.max_compute_invocations_per_workgroup,
		max_compute_workgroup_size_x                    = webgpu.max_compute_workgroup_size_x,
		max_compute_workgroup_size_y                    = webgpu.max_compute_workgroup_size_y,
		max_compute_workgroup_size_z                    = webgpu.max_compute_workgroup_size_z,
		max_compute_workgroups_per_dimension            = webgpu.max_compute_workgroups_per_dimension,

		// Native
		max_push_constant_size                          = native.max_push_constant_size,
		max_non_sampler_bindings                        = native.max_non_sampler_bindings,
	}

	return
}
