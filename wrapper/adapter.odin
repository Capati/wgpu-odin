package wgpu

// Core
import "base:runtime"
import "core:fmt"
import "core:strings"

// Package
import wgpu "../bindings"

// Handle to a physical graphics and/or compute device.
//
// Adapters can be used to open a connection to the corresponding `Device` on the host system by
// using `adapter_request_device`.
//
// Does not have to be kept alive.
Adapter :: struct {
	ptr:        Raw_Adapter,
	features:   []Feature,
	limits:     Limits,
	properties: Adapter_Properties,
}

// List all features that are supported with this adapter.
//
// Features must be explicitly requested in `adapter_request_device` in order to use them.
adapter_get_features :: proc(using self: ^Adapter, allocator := context.allocator) -> []Feature {
	features_count := wgpu.adapter_enumerate_features(ptr, nil)

	if features_count == 0 {
		return {}
	}

	adapter_features := make([]wgpu.Feature_Name, features_count, allocator)
	wgpu.adapter_enumerate_features(ptr, raw_data(adapter_features))

	return transmute([]Feature)adapter_features
}

@(private)
_adapter_get_limits :: proc(adapter: Raw_Adapter) -> (limits: Limits) {
	native := Supported_Limits_Extras {
		chain = {stype = SType(Native_SType.Supported_Limits_Extras)},
	}

	supported := Supported_Limits {
		next_in_chain = &native.chain,
	}

	wgpu.adapter_get_limits(adapter, &supported)

	limits = limits_merge_webgpu_with_native(supported.limits, native.limits)

	return
}

// List the “best” limits that are supported by this adapter.
//
// Limits must be explicitly requested in `adapter_request_device` to set the values that you are
// allowed to use.
adapter_get_limits :: proc(self: ^Adapter) -> Limits {
	return self.limits // filled on request adapter
}

@(private)
_adapter_get_properties :: proc(adapter: Raw_Adapter) -> (properties: Adapter_Properties) {
	wgpu.adapter_get_properties(adapter, &properties)
	return
}

// Get info about the adapter itself.
adapter_get_properties :: proc(self: ^Adapter) -> Adapter_Properties {
	return self.properties // filled on request adapter
}

// Describes a `Device` for use with `adapter->request_device`.
Device_Descriptor :: struct {
	label:                cstring,
	features:             []Feature,
	required_limits:      Limits,
	trace_path:           cstring,
	device_lost_callback: Device_Lost_Callback,
	device_lost_userdata: rawptr,
}

@(private = "file")
Device_Response :: struct {
	status: Request_Device_Status,
	device: Raw_Device,
}

@(private = "file")
_adapter_request_device :: proc(
	self: ^Adapter,
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

	wgpu.adapter_request_device(
		self.ptr,
		desc if desc != nil else nil,
		adapter_request_device_callback,
		&res,
	)

	if res.status != .Success {
		err = res.status
		set_and_update_err_data(nil, .Request_Device, err, string(res.message), loc)
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

	device.features = _device_get_features(device.ptr, loc) or_return
	device.limits = _device_get_limits(device.ptr)

	queue = Queue {
		ptr       = wgpu.device_get_queue(res.device),
		_err_data = device._err_data,
	}

	return
}

// Requests a connection to a physical device, creating a logical device.
//
// Returns the `Device` together with a `Queue` that executes command buffers.
adapter_request_device :: proc(
	self: ^Adapter,
	descriptor: ^Device_Descriptor = nil,
	loc := #caller_location,
) -> (
	device: Device,
	queue: Queue,
	err: Error,
) {
	if descriptor == nil {
		return _adapter_request_device(self, nil, loc)
	}

	desc: wgpu.Device_Descriptor
	desc.label = descriptor.label

	if len(descriptor.features) > 0 {
		desc.required_feature_count = len(descriptor.features)
		desc.required_features = transmute(^wgpu.Feature_Name)raw_data(descriptor.features)
	}

	// If no limits is provided, default to adapter best limits
	// TODO(Capati): Or default to a down level limits?
	limits := descriptor.required_limits if descriptor.required_limits != {} else self.limits

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
		if self.properties.backend_type == .D3D12 {
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
adapter_reference :: proc(using self: ^Adapter) {
	wgpu.adapter_reference(ptr)
}

// Release the `Adapter`.
@(private = "file")
_adapter_release :: proc(using self: ^Adapter) {
	wgpu.adapter_release(ptr)
}

// Release the `Adapter`.
adapter_release :: proc(using self: ^Adapter) {
	_adapter_release(self)
}

// Release the `Adapter` and modify the raw pointer to `nil`..
adapter_release_and_nil :: proc(using self: ^Adapter) {
	if ptr == nil do return
	_adapter_release(self)
	ptr = nil
}
