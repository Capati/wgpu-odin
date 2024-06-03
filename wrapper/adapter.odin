package wgpu

// Core
import "core:runtime"

// Package
import wgpu "../bindings"

// Handle to a physical graphics and/or compute device.
//
// Adapters can be used to open a connection to the corresponding `Device` on the host system by
// using `adapter_request_device`.
//
// Does not have to be kept alive.
Adapter :: struct {
	ptr:        WGPU_Adapter,
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

// List the “best” limits that are supported by this adapter.
//
// Limits must be explicitly requested in `adapter_request_device` to set the values that you are
// allowed to use.
adapter_get_limits :: proc(self: ^Adapter) -> (limits: Limits) {
	supported_extras := Supported_Limits_Extras {
		chain = {stype = SType(Native_SType.Supported_Limits_Extras)},
	}
	supported_limits := Supported_Limits {
		next_in_chain = &supported_extras.chain,
	}
	wgpu.adapter_get_limits(self.ptr, &supported_limits)

	supported := supported_limits.limits
	extras := supported_extras.limits

	// This is merging base with native limits (extras)
	limits = {
		max_texture_dimension_1d                        = supported.max_texture_dimension_1d,
		max_texture_dimension_2d                        = supported.max_texture_dimension_2d,
		max_texture_dimension_3d                        = supported.max_texture_dimension_3d,
		max_texture_array_layers                        = supported.max_texture_array_layers,
		max_bind_groups                                 = supported.max_bind_groups,
		max_bind_groups_plus_vertex_buffers             = supported.max_bind_groups_plus_vertex_buffers,
		max_bindings_per_bind_group                     = supported.max_bindings_per_bind_group,
		max_dynamic_uniform_buffers_per_pipeline_layout = supported.max_dynamic_uniform_buffers_per_pipeline_layout,
		max_dynamic_storage_buffers_per_pipeline_layout = supported.max_dynamic_storage_buffers_per_pipeline_layout,
		max_sampled_textures_per_shader_stage           = supported.max_sampled_textures_per_shader_stage,
		max_samplers_per_shader_stage                   = supported.max_samplers_per_shader_stage,
		max_storage_buffers_per_shader_stage            = supported.max_storage_buffers_per_shader_stage,
		max_storage_textures_per_shader_stage           = supported.max_storage_textures_per_shader_stage,
		max_uniform_buffers_per_shader_stage            = supported.max_uniform_buffers_per_shader_stage,
		max_uniform_buffer_binding_size                 = supported.max_uniform_buffer_binding_size,
		max_storage_buffer_binding_size                 = supported.max_storage_buffer_binding_size,
		min_uniform_buffer_offset_alignment             = supported.min_uniform_buffer_offset_alignment,
		min_storage_buffer_offset_alignment             = supported.min_storage_buffer_offset_alignment,
		max_vertex_buffers                              = supported.max_vertex_buffers,
		max_buffer_size                                 = supported.max_buffer_size,
		max_vertex_attributes                           = supported.max_vertex_attributes,
		max_vertex_buffer_array_stride                  = supported.max_vertex_buffer_array_stride,
		max_inter_stage_shader_components               = supported.max_inter_stage_shader_components,
		max_inter_stage_shader_variables                = supported.max_inter_stage_shader_variables,
		max_color_attachments                           = supported.max_color_attachments,
		max_color_attachment_bytes_per_sample           = supported.max_color_attachment_bytes_per_sample,
		max_compute_workgroup_storage_size              = supported.max_compute_workgroup_storage_size,
		max_compute_invocations_per_workgroup           = supported.max_compute_invocations_per_workgroup,
		max_compute_workgroup_size_x                    = supported.max_compute_workgroup_size_x,
		max_compute_workgroup_size_y                    = supported.max_compute_workgroup_size_y,
		max_compute_workgroup_size_z                    = supported.max_compute_workgroup_size_z,
		max_compute_workgroups_per_dimension            = supported.max_compute_workgroups_per_dimension,
		// Limits extras
		max_push_constant_size                          = extras.max_push_constant_size,
		max_non_sampler_bindings                        = extras.max_non_sampler_bindings,
	}

	return
}

// Get info about the adapter itself.
adapter_get_properties :: proc(self: ^Adapter) -> (properties: Adapter_Properties) {
	wgpu.adapter_get_properties(self.ptr, &properties)
	return
}

// Check if adapter support a feature.
adapter_has_feature :: proc(using self: ^Adapter, feature: Feature) -> bool {
	return wgpu.adapter_has_feature(ptr, cast(wgpu.Feature_Name)feature)
}

// Describes a `Device` for use with `adapter->request_device`.
Device_Descriptor :: struct {
	label:                cstring,
	features:             []Feature,
	limits:               Limits,
	trace_path:           cstring,
	device_lost_callback: Device_Lost_Callback,
	device_lost_userdata: rawptr,
}

@(private = "file")
Device_Response :: struct {
	status: Request_Device_Status,
	device: WGPU_Device,
}

@(private = "file")
_adapter_request_device_fill :: proc(
	self: ^Adapter,
	res: ^Device_Response,
) -> (
	device: Device,
	queue: Queue,
) {
	device.ptr = res.device
	device.features = device_get_features(&device)
	device.limits = device_get_limits(&device)
	device._err_data = new(Error_Data) // Heap allocate to avoid stack fuckery
	wgpu.device_set_uncaptured_error_callback(
		device.ptr,
		uncaptured_error_callback,
		device._err_data,
	)

	queue = Queue {
		ptr       = wgpu.device_get_queue(res.device),
		_err_data = device._err_data,
	}

	return
}

// Requests a connection to a physical device, creating a logical device.
//
// Returns the `Device` together with a `Queue` that executes command buffers.
adapter_request_device_from_descriptor :: proc(
	self: ^Adapter,
	descriptor: ^Device_Descriptor,
) -> (
	device: Device,
	queue: Queue,
	err: Error_Type,
) {
	desc: wgpu.Device_Descriptor
	desc.label = descriptor.label

	if len(descriptor.features) > 0 {
		desc.required_feature_count = len(descriptor.features)
		desc.required_features = transmute(^wgpu.Feature_Name)raw_data(descriptor.features)
	}

	// If no limits is provided, default to adapter best limits
	// TODO(Capati): Or default to a down level limits?
	limits := descriptor.limits if descriptor.limits != {} else self.limits

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

	res: Device_Response
	wgpu.adapter_request_device(self.ptr, &desc, _on_adapter_request_device, &res)

	if res.status != .Success {
		return {}, {}, .Unknown
	}

	return _adapter_request_device_fill(self, &res), .No_Error
}

adapter_request_device_empty :: proc(
	self: ^Adapter,
) -> (
	device: Device,
	queue: Queue,
	err: Error_Type,
) {
	res: Device_Response
	wgpu.adapter_request_device(self.ptr, nil, _on_adapter_request_device, &res)

	if res.status != .Success {
		return {}, {}, .Unknown
	}

	return _adapter_request_device_fill(self, &res), .No_Error
}

adapter_request_device :: proc {
	adapter_request_device_from_descriptor,
	adapter_request_device_empty,
}

// Increase the reference count.
adapter_reference :: proc(using self: ^Adapter) {
	wgpu.adapter_reference(ptr)
}

// Release the `Adapter`.
adapter_release :: proc(using self: ^Adapter) {
	if ptr == nil do return
	delete(features)
	wgpu.adapter_release(ptr)
	ptr = nil
}

@(private = "file")
_on_adapter_request_device :: proc "c" (
	status: Request_Device_Status,
	device: WGPU_Device,
	message: cstring,
	user_data: rawptr,
) {
	response := cast(^Device_Response)user_data
	response.status = status

	if status == .Success {
		response.device = device
	} else {
		context = runtime.default_context()
		update_error_message(string(message))
	}
}
