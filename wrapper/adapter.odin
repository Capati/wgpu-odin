package wgpu

// Core
import "base:runtime"
import "core:fmt"

// Package
import wgpu "../bindings"

// Handle to a physical graphics and/or compute device.
//
// Adapters can be used to open a connection to the corresponding `Device` on the host system by
// using `adapter_request_device`.
//
// Does not have to be kept alive.
Adapter :: struct {
	ptr:      Raw_Adapter,
	features: Adapter_Features,
	limits:   Limits,
	info:     Adapter_Info,
}

// Features that are available by the adapter.
Adapter_Features :: distinct Features

@(private)
_adapter_get_features :: proc(
	self: Adapter,
	loc := #caller_location,
) -> (
	features: Adapter_Features,
	err: Error,
) {
	count := wgpu.adapter_enumerate_features(self.ptr, nil)

	if count == 0 do return

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	raw_features, alloc_err := make([]wgpu.Feature_Name, count, context.temp_allocator)

	if alloc_err != nil {
		err = alloc_err
		set_and_update_err_data(nil, .General, err, "Failed to get adapter features", loc)
		return
	}

	wgpu.adapter_enumerate_features(self.ptr, raw_data(raw_features))

	features_slice := transmute([]Raw_Feature_Name)raw_features
	features = cast(Adapter_Features)features_slice_to_flags(features_slice)

	return
}

// List all features that are supported with this adapter.
//
// Features must be explicitly requested in `adapter_request_device` in order to use them.
adapter_get_features :: proc "contextless" (self: Adapter) -> Adapter_Features {
	return self.features // filled on request adapter
}

@(private)
_adapter_get_limits :: proc(
	self: Adapter,
	loc := #caller_location,
) -> (
	limits: Limits,
	err: Error,
) {
	native := Supported_Limits_Extras {
		chain = {stype = SType(Native_SType.Supported_Limits_Extras)},
	}

	supported := Supported_Limits {
		next_in_chain = &native.chain,
	}

	set_and_reset_err_data(nil, loc)

	result := bool(wgpu.adapter_get_limits(self.ptr, &supported))

	if !result {
		err = Error_Type.Unknown
		update_error_data(nil, .Request_Adapter, err, "Failed to fill adapter limits")
		return
	}

	limits = limits_merge_webgpu_with_native(supported.limits, native.limits)

	// Enforce minimum values for all limits even if the supported values are lower
	limits_ensure_minimum(&limits, minimum = DOWNLEVEL_WEBGL2_LIMITS)

	return
}

// List the “best” limits that are supported by this adapter.
//
// Limits must be explicitly requested in `adapter_request_device` to set the values that you are
// allowed to use.
adapter_get_limits :: proc "contextless" (self: Adapter) -> Limits {
	return self.limits // filled on request adapter
}

@(private)
_adapter_get_info :: proc(
	self: Adapter,
	loc := #caller_location,
) -> (
	info: Adapter_Info,
	err: Error,
) {
	wgpu.adapter_get_properties(self.ptr, &info)

	if info == {} {
		err = Error_Type.Unknown
		set_and_update_err_data(nil, .Request_Adapter, err, "Failed to fill adapter info", loc)
	}

	return
}

// Get info about the adapter itself.
adapter_get_info :: proc "contextless" (self: Adapter) -> Adapter_Info {
	return self.info // filled on request adapter
}

// Check if adapter support all features in the given flags.
adapter_has_feature :: proc "contextless" (self: Adapter, features: Features) -> bool {
	if features == {} do return true
	for f in features {
		if f not_in self.features || f == .Undefined do return false
	}
	return true
}

// Check if adapter support the given feature name.
adapter_has_feature_name :: proc "contextless" (self: Adapter, feature: Feature_Name) -> bool {
	return feature in self.features
}

@(private = "file")
_adapter_request_device :: proc(
	self: Adapter,
	desc: ^wgpu.Device_Descriptor = nil,
	loc := #caller_location,
) -> (
	device: Device,
	queue: Queue,
	err: Error,
) {
	Device_Response :: struct {
		status:  Request_Device_Status,
		message: cstring,
		device:  Raw_Device,
	}

	res: Device_Response

	adapter_request_device_callback :: proc "c" (
		status: Request_Device_Status,
		device: Raw_Device,
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

	wgpu.adapter_request_device(self.ptr, desc, adapter_request_device_callback, &res)

	if res.status != .Success {
		err = res.status
		message := string(res.message)
		if message == "" do message = "Unknown"
		set_and_update_err_data(nil, .Request_Device, err, message, loc)
		return
	}

	device.ptr = res.device
	defer if err != nil do wgpu.device_release(device.ptr)

	when WGPU_ENABLE_ERROR_HANDLING {
		if device._err_data, err = add_error_data(); err != nil {
			set_and_update_err_data(nil, .Request_Device, err, "Failed to create error data", loc)
			return
		}

		// Errors will propagate from this callback
		wgpu.device_set_uncaptured_error_callback(
			device.ptr,
			uncaptured_error_data_callback,
			device._err_data,
		)
	}

	device.features = _device_get_features(device, loc) or_return
	device.limits = _device_get_limits(device, loc) or_return

	queue = Queue {
		ptr       = wgpu.device_get_queue(res.device),
		_err_data = device._err_data,
	}

	return
}

// Describes a `Device` for use with `adapter_request_device`.
Device_Descriptor :: struct {
	label:                cstring,
	required_features:    Features,
	required_limits:      Limits,
	trace_path:           cstring,
	device_lost_callback: Device_Lost_Callback,
	device_lost_userdata: rawptr,
}

// Requests a connection to a physical device, creating a logical device.
//
// Returns the `Device` together with a `Queue` that executes command buffers.
@(require_results)
adapter_request_device :: proc(
	self: Adapter,
	descriptor: Device_Descriptor = {},
	loc := #caller_location,
) -> (
	device: Device,
	queue: Queue,
	err: Error,
) {
	if descriptor == {} {
		return _adapter_request_device(self, nil, loc)
	}

	desc: wgpu.Device_Descriptor
	desc.label = descriptor.label

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	features_len: int
	features: [dynamic]Raw_Feature_Name
	features.allocator = context.temp_allocator

	if descriptor.required_features != {} {
		for _ in descriptor.required_features do features_len += 1
		if err = reserve(&features, features_len); err != nil {
			set_and_update_err_data(nil, .Request_Device, err, "Failed to allocate features", loc)
			return
		}
		for f in descriptor.required_features {
			if f not_in self.features {
				err = .Validation
				set_and_update_err_data(
					nil,
					.Request_Device,
					err,
					fmt.tprintf(
						"Required feature [%v] not supported by device [%s] using [%s].",
						f,
						self.info.name,
						self.info.backend_type,
					),
					loc,
				)
				return
			}
			append(&features, features_flag_to_raw_feature_name(f))
		}

		desc.required_feature_count = uint(features_len)
		desc.required_features = cast(^wgpu.Feature_Name)raw_data(features[:])
	}

	// If no limits is provided, default to adapter best limits
	// TODO(Capati): Or default to a down level limits?
	limits := descriptor.required_limits if descriptor.required_limits != {} else self.limits

	if limits != self.limits {
		if limit_violation, ok := limits_check(limits, self.limits); !ok {
			err = .Validation
			set_and_update_err_data(
				nil,
				.Request_Device,
				err,
				limits_violation_to_string(limit_violation, context.temp_allocator),
				loc,
			)
			return
		}
	}

	required_limits := Required_Limits {
		next_in_chain = nil,
	}

	required_limits.limits = {
		max_texture_dimension_1d                        = limits.max_texture_dimension_1d,
		max_texture_dimension_2d                        = limits.max_texture_dimension_2d,
		max_texture_dimension_3d                        = limits.max_texture_dimension_3d,
		max_texture_array_layers                        = limits.max_texture_array_layers,
		max_bind_groups                                 = limits.max_bind_groups,
		max_bind_groups_plus_vertex_buffers             = limits.max_bind_groups_plus_vertex_buffers,
		max_bindings_per_bind_group                     = limits.max_bindings_per_bind_group,
		max_dynamic_uniform_buffers_per_pipeline_layout = limits.max_dynamic_uniform_buffers_per_pipeline_layout,
		max_dynamic_storage_buffers_per_pipeline_layout = limits.max_dynamic_storage_buffers_per_pipeline_layout,
		max_sampled_textures_per_shader_stage           = limits.max_sampled_textures_per_shader_stage,
		max_samplers_per_shader_stage                   = limits.max_samplers_per_shader_stage,
		max_storage_buffers_per_shader_stage            = limits.max_storage_buffers_per_shader_stage,
		max_storage_textures_per_shader_stage           = limits.max_storage_textures_per_shader_stage,
		max_uniform_buffers_per_shader_stage            = limits.max_uniform_buffers_per_shader_stage,
		max_uniform_buffer_binding_size                 = limits.max_uniform_buffer_binding_size,
		max_storage_buffer_binding_size                 = limits.max_storage_buffer_binding_size,
		min_uniform_buffer_offset_alignment             = limits.min_uniform_buffer_offset_alignment,
		min_storage_buffer_offset_alignment             = limits.min_storage_buffer_offset_alignment,
		max_vertex_buffers                              = limits.max_vertex_buffers,
		max_buffer_size                                 = limits.max_buffer_size,
		max_vertex_attributes                           = limits.max_vertex_attributes,
		max_vertex_buffer_array_stride                  = limits.max_vertex_buffer_array_stride,
		max_inter_stage_shader_components               = limits.max_inter_stage_shader_components,
		max_inter_stage_shader_variables                = limits.max_inter_stage_shader_variables,
		max_color_attachments                           = limits.max_color_attachments,
		max_color_attachment_bytes_per_sample           = limits.max_color_attachment_bytes_per_sample,
		max_compute_workgroup_storage_size              = limits.max_compute_workgroup_storage_size,
		max_compute_invocations_per_workgroup           = limits.max_compute_invocations_per_workgroup,
		max_compute_workgroup_size_x                    = limits.max_compute_workgroup_size_x,
		max_compute_workgroup_size_y                    = limits.max_compute_workgroup_size_y,
		max_compute_workgroup_size_z                    = limits.max_compute_workgroup_size_z,
		max_compute_workgroups_per_dimension            = limits.max_compute_workgroups_per_dimension,
	}

	required_limits_extras := Required_Limits_Extras {
		chain = {stype = SType(Native_SType.Required_Limits_Extras)},
	}

	if (limits.max_push_constant_size != 0 || limits.max_non_sampler_bindings != 0) {
		required_limits_extras.limits = {
			max_push_constant_size   = limits.max_push_constant_size,
			max_non_sampler_bindings = limits.max_non_sampler_bindings,
		}

		// This limit only affects the d3d12 backend.
		if self.info.backend_type == .D3D12 {
			// TODO(Capati): Make sure a non zero value is set or the application can crash.
			if required_limits_extras.limits.max_non_sampler_bindings == 0 {
				required_limits_extras.limits.max_non_sampler_bindings = 1_000_000
			}
		}

		required_limits.next_in_chain = &required_limits_extras.chain
	}

	desc.required_limits = &required_limits

	if descriptor.device_lost_callback != nil {
		desc.device_lost_callback = descriptor.device_lost_callback
		desc.device_lost_userdata = descriptor.device_lost_userdata
	}

	device_extras := Device_Extras {
		chain = {stype = SType(Native_SType.Device_Extras)},
	}

	// Write a trace of all commands to a file so it can be reproduced
	// elsewhere. The trace is cross-platform.
	if descriptor.trace_path != nil && descriptor.trace_path != "" {
		device_extras.trace_path = descriptor.trace_path
		desc.next_in_chain = &device_extras.chain
	}

	return _adapter_request_device(self, &desc, loc)
}

// Increase the reference count.
adapter_reference :: proc "contextless" (using self: Adapter) {
	wgpu.adapter_reference(ptr)
}

// // Release the `Adapter`.
// @(private = "file")
// _adapter_release :: proc "contextless" (using self: Adapter) {
// 	// TODO(Capati): Wait for upstream update
// 	// wgpu.adapter_info_free_members(&info)
// 	wgpu.adapter_release(ptr)
// }

// Release the `Adapter`.
adapter_release :: #force_inline proc "contextless" (using self: Adapter) {
	wgpu.adapter_release(ptr)
}

// Release the `Adapter` and modify the raw pointer to `nil`.
adapter_release_and_nil :: proc "contextless" (using self: ^Adapter) {
	if ptr == nil do return
	wgpu.adapter_release(ptr)
	ptr = nil
}
