package wgpu

// STD Library
import "base:runtime"
import "core:fmt"

// The raw bindings
import wgpu "../bindings"

/*
Handle to a physical graphics and/or compute device.

Adapters can be used to open a connection to the corresponding `Device` on the host system by
using `adapter_request_device`.

Does not have to be kept alive.

Corresponds to [WebGPU GPUAdapter](https://gpuweb.github.io/gpuweb/#gpu-adapter).
*/
Adapter :: wgpu.Adapter

/* Features that are supported/available by an adapter. */
Adapter_Features :: distinct Features

/*
List all features that are supported with this adapter. Features must be explicitly requested in
`adapter_request_device` in order to use them.
*/
adapter_get_features :: proc "contextless" (
	self: Adapter,
) -> (
	features: Adapter_Features,
) #no_bounds_check {
	count := wgpu.adapter_enumerate_features(self, nil)
	if count == 0 do return

	raw_features: [MAX_FEATURES]wgpu.Feature_Name

	wgpu.adapter_enumerate_features(self, raw_data(raw_features[:count]))

	features = cast(Adapter_Features)features_slice_to_flags(raw_features[:count])

	return
}

/*
List the “best” limits that are supported by this adapter. Limits must be explicitly requested in
`adapter_request_device` to set the values that you are allowed to use.
*/
adapter_get_limits :: proc "contextless" (
	self: Adapter,
	loc := #caller_location,
) -> (
	limits: Limits,
	ok: bool,
) #optional_ok {
	native := Supported_Limits_Extras {
		stype = SType(Native_SType.Supported_Limits_Extras),
	}
	supported := Supported_Limits {
		next_in_chain = &native.chain,
	}

	_error_reset_data(loc)

	ok = bool(wgpu.adapter_get_limits(self, &supported))

	if get_last_error() != nil do return

	if !ok {
		error_update_data(Error_Type.Unknown, "Failed to fill adapter limits")
		return
	}

	limits = limits_merge_webgpu_with_native(supported.limits, native.limits)

	// Why wgpu returns 0 for some supported limits?
	// Enforce minimum values for all limits even if the returned values are lower
	limits_ensure_minimum(&limits, minimum = DOWNLEVEL_WEBGL2_LIMITS)

	return limits, true
}

/* Get info about the adapter itself. */
adapter_get_info :: proc "contextless" (
	self: Adapter,
	loc := #caller_location,
) -> (
	info: Adapter_Info,
	ok: bool,
) #optional_ok {
	wgpu.adapter_get_info(self, &info)

	if info == {} {
		error_reset_and_update(Error_Type.Unknown, "Failed to fill adapter information", loc)
		return
	}

	return info, true
}

/* Check if adapter support all features in the given flags. */
adapter_has_feature :: proc "contextless" (
	self: Adapter,
	features: Features,
	loc := #caller_location,
) -> bool {
	if features == {} do return true
	available := adapter_get_features(self)
	if available == {} do return false
	for f in features {
		if f not_in available || f == .Undefined do return false
	}
	return true
}

/* Check if adapter support the given feature name. */
adapter_has_feature_name :: proc "contextless" (self: Adapter, feature: Feature_Name) -> bool {
	return adapter_has_feature(self, {feature})
}

/*
Describes a `Device`.

For use with `adapter_request_device`.

Corresponds to [WebGPU `GPUDeviceDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpudevicedescriptor).
*/
Device_Descriptor :: struct {
	label                : cstring,
	required_features    : Features,
	required_limits      : Limits,
	trace_path           : cstring,
	device_lost_callback : Device_Lost_Callback,
	device_lost_userdata : rawptr,
}

/*
Requests a connection to a physical device, creating a logical device.

[Per the WebGPU specification], an `Adapter` may only be used once to create a device.
If another device is wanted, call `adapter_request_device` again to get a fresh
`Adapter`. However, `wgpu` does not currently enforce this restriction.

**Panics**:
- `adapter_request_device()` was already called on this `Adapter`.
- Features specified by `descriptor` are not supported by this adapter.
- Unsafe features were requested but not enabled when requesting the adapter.
- Limits requested exceed the values provided by the adapter.
- Adapter does not support all features wgpu requires to safely operate.

[Per the WebGPU specification]: https://www.w3.org/TR/webgpu/#dom-gpuadapter-requestdevice
*/
@(require_results)
adapter_request_device :: proc(
	self: Adapter,
	descriptor: Maybe(Device_Descriptor) = nil,
	loc := #caller_location,
) -> (
	device: Device,
	ok: bool,
) #optional_ok {
	desc, desc_ok := descriptor.?
	if !desc_ok {
		return adapter_request_device_raw(self, nil, loc)
	}

	raw_desc: wgpu.Device_Descriptor
	raw_desc.label = desc.label

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	ta := context.temp_allocator

	features_len: int
	features: [dynamic]Raw_Feature_Name
	features.allocator = ta

	adapter_info := adapter_get_info(self, loc) or_return

	// Check for unsupported features
	if desc.required_features != {} {
		for _ in desc.required_features do features_len += 1
		if err := reserve(&features, features_len); err != nil {
			error_reset_and_update(err, "Failed to allocate features", loc)
			return
		}

		adapter_features := adapter_get_features(self)

		for f in desc.required_features {
			if f not_in adapter_features {
				error_reset_and_update(
					.Validation,
					fmt.aprintf(
						"Required feature [%v] not supported by device [%s] using [%s].",
						f,
						adapter_info.description,
						adapter_info.backend_type,
						allocator = ta,
					),
					loc,
				)
				return
			}
			append(&features, features_flag_to_raw_feature_name(f))
		}

		raw_desc.required_feature_count = uint(features_len)
		raw_desc.required_features = cast(^wgpu.Feature_Name)raw_data(features[:])
	}

	adapter_limits := adapter_get_limits(self, loc) or_return

	// If no limits is provided, default to adapter best limits
	// TODO(Capati): Or default to a down level limits?
	limits := desc.required_limits if desc.required_limits != {} else adapter_limits

	// Check for unsupported limits
	if limits != adapter_limits {
		if limit_violation, limits_ok := limits_check(limits, adapter_limits); !limits_ok {
			error_reset_and_update(
				.Validation,
				limits_violation_to_string(limit_violation, ta),
				loc,
			)
			return
		}
	}

	required_limits: Required_Limits

	required_limits.limits = {
		max_texture_dimension_1d = limits.max_texture_dimension_1d,
		max_texture_dimension_2d = limits.max_texture_dimension_2d,
		max_texture_dimension_3d = limits.max_texture_dimension_3d,
		max_texture_array_layers = limits.max_texture_array_layers,
		max_bind_groups = limits.max_bind_groups,
		max_bind_groups_plus_vertex_buffers = limits.max_bind_groups_plus_vertex_buffers,
		max_bindings_per_bind_group = limits.max_bindings_per_bind_group,
		max_dynamic_uniform_buffers_per_pipeline_layout = \
			limits.max_dynamic_uniform_buffers_per_pipeline_layout,
		max_dynamic_storage_buffers_per_pipeline_layout = \
			limits.max_dynamic_storage_buffers_per_pipeline_layout,
		max_sampled_textures_per_shader_stage = limits.max_sampled_textures_per_shader_stage,
		max_samplers_per_shader_stage = limits.max_samplers_per_shader_stage,
		max_storage_buffers_per_shader_stage = limits.max_storage_buffers_per_shader_stage,
		max_storage_textures_per_shader_stage = limits.max_storage_textures_per_shader_stage,
		max_uniform_buffers_per_shader_stage = limits.max_uniform_buffers_per_shader_stage,
		max_uniform_buffer_binding_size = limits.max_uniform_buffer_binding_size,
		max_storage_buffer_binding_size = limits.max_storage_buffer_binding_size,
		min_uniform_buffer_offset_alignment = limits.min_uniform_buffer_offset_alignment,
		min_storage_buffer_offset_alignment = limits.min_storage_buffer_offset_alignment,
		max_vertex_buffers = limits.max_vertex_buffers,
		max_buffer_size = limits.max_buffer_size,
		max_vertex_attributes = limits.max_vertex_attributes,
		max_vertex_buffer_array_stride = limits.max_vertex_buffer_array_stride,
		max_inter_stage_shader_components = limits.max_inter_stage_shader_components,
		max_inter_stage_shader_variables = limits.max_inter_stage_shader_variables,
		max_color_attachments = limits.max_color_attachments,
		max_color_attachment_bytes_per_sample = limits.max_color_attachment_bytes_per_sample,
		max_compute_workgroup_storage_size = limits.max_compute_workgroup_storage_size,
		max_compute_invocations_per_workgroup = limits.max_compute_invocations_per_workgroup,
		max_compute_workgroup_size_x = limits.max_compute_workgroup_size_x,
		max_compute_workgroup_size_y = limits.max_compute_workgroup_size_y,
		max_compute_workgroup_size_z = limits.max_compute_workgroup_size_z,
		max_compute_workgroups_per_dimension = limits.max_compute_workgroups_per_dimension,
	}

	required_limits_extras := Required_Limits_Extras {
		stype = SType(Native_SType.Required_Limits_Extras),
	}

	if (limits.max_push_constant_size != 0 || limits.max_non_sampler_bindings != 0) {
		required_limits_extras.limits = {
			max_push_constant_size   = limits.max_push_constant_size,
			max_non_sampler_bindings = limits.max_non_sampler_bindings,
		}

		// This limit only affects the d3d12 backend.
		if adapter_info.backend_type == .D3D12 {
			// TODO(Capati): Make sure a non zero value is set or the application can crash.
			if required_limits_extras.limits.max_non_sampler_bindings == 0 {
				required_limits_extras.limits.max_non_sampler_bindings = 1_000_000
			}
		}

		required_limits.next_in_chain = &required_limits_extras.chain
	}

	raw_desc.required_limits = &required_limits

	if desc.device_lost_callback != nil {
		raw_desc.device_lost_callback = desc.device_lost_callback
		raw_desc.device_lost_userdata = desc.device_lost_userdata
	}

	device_extras := Device_Extras {
		stype = SType(Native_SType.Device_Extras),
	}

	// Write a trace of all commands to a file so it can be reproduced
	// elsewhere. The trace is cross-platform.
	if desc.trace_path != nil && desc.trace_path != "" {
		device_extras.trace_path = desc.trace_path
		raw_desc.next_in_chain = &device_extras.chain
	}

	return adapter_request_device_raw(self, &raw_desc, loc)
}

Device_Response :: struct {
	status  : Request_Device_Status,
	message : cstring,
	device  : Device,
}

adapter_request_device_callback :: proc "c" (
	status: Request_Device_Status,
	device: Device,
	message: cstring,
	user_data: rawptr,
) {
	response := cast(^Device_Response)user_data

	response.status = status
	response.message = message

	if status == .Success {
		response.device = device
	}
}

adapter_request_device_raw :: proc(
	self: Adapter,
	desc: ^wgpu.Device_Descriptor,
	loc := #caller_location,
) -> (
	device: Device,
	ok: bool,
) {
	has_error_callback: bool
	if desc.uncaptured_error_callback_info.callback != nil {
		set_uncaptured_error_callback(
			desc.uncaptured_error_callback_info.callback,
			desc.uncaptured_error_callback_info.userdata,
		)
		has_error_callback = true
	}

	if ENABLE_ERROR_HANDLING || has_error_callback {
		desc.uncaptured_error_callback_info = {
			/* Errors will propagate from this callback */
			callback = uncaptured_error_data_callback,
		}
	}

	res: Device_Response
	wgpu.adapter_request_device(self, desc, adapter_request_device_callback, &res)

	if res.status != .Success {
		message := string(res.message)
		// A non success status with no message means unknown error, like unsupported limits...
		if message == "" do message = "Unknown"
		error_reset_and_update(res.status, message, loc)
		return
	}

	device = res.device

	return device, true
}

/* Free the adapter info resources. */
adapter_info_free_members :: wgpu.adapter_info_free_members

/*  Increase the reference count. */
adapter_reference :: wgpu.adapter_reference

/*  Release the `Adapter` resources. */
adapter_release :: wgpu.adapter_release
