package wgpu

import "base:runtime"
import sa "core:container/small_array"
import "core:fmt"
import "core:log"
import "core:strings"

/*
Handle to a physical graphics and/or compute device.

Adapters can be used to open a connection to the corresponding `Device` on the host system by
using `adapter_request_device`.

Does not have to be kept alive.

Corresponds to [WebGPU GPUAdapter](https://gpuweb.github.io/gpuweb/#gpu-adapter).
*/
Adapter :: distinct rawptr

/* Features that are supported/available by an adapter. */
AdapterFeatures :: distinct Features

/*
List all features that are supported with this adapter. Features must be explicitly requested in
`adapter_request_device` in order to use them.
*/
adapter_get_features :: proc "contextless" (
	self: Adapter,
) -> (
	features: AdapterFeatures,
) #no_bounds_check {
	supported: SupportedFeatures
	wgpuAdapterGetFeatures(self, &supported)

	raw_features := supported.features[:supported.feature_count]
	features = cast(AdapterFeatures)features_slice_to_flags(raw_features)

	return
}

AdapterInfo :: struct {
	vendor:       string,
	architecture: string,
	device:       string,
	description:  string,
	backend_type: BackendType,
	adapter_type: AdapterType,
	vendor_id:    u32,
	device_id:    u32,
}

/* Get info about the adapter itself. */
adapter_get_info :: proc(
	self: Adapter,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	info: AdapterInfo,
	ok: bool,
) #optional_ok {
	raw_info: WGPUAdapterInfo
	status := wgpuAdapterGetInfo(self, &raw_info)
	defer wgpuAdapterInfoFreeMembers(raw_info)

	if status != .Success {
		error_reset_and_update(ErrorType.Unknown, "Failed to fill adapter information", loc)
		return
	}

	if raw_info.vendor.length > 0 {
		info.vendor = strings.clone(string_view_get_string(raw_info.vendor), allocator)
	}

	if raw_info.architecture.length > 0 {
		info.architecture = strings.clone(string_view_get_string(raw_info.architecture), allocator)
	}

	if raw_info.device.length > 0 {
		info.device = strings.clone(string_view_get_string(raw_info.device), allocator)
	}

	if raw_info.description.length > 0 {
		info.description = strings.clone(string_view_get_string(raw_info.description), allocator)
	}

	info.backend_type = raw_info.backend_type
	info.adapter_type = raw_info.adapter_type
	info.vendor_id = raw_info.vendor_id
	info.device_id = raw_info.device_id

	return info, true
}

/* Free the adapter info resources. */
adapter_info_free_members :: proc(self: AdapterInfo, allocator := context.allocator) {
	context.allocator = allocator
	if len(self.vendor) > 0 {delete(self.vendor)}
	if len(self.architecture) > 0 {delete(self.architecture)}
	if len(self.device) > 0 {delete(self.device)}
	if len(self.description) > 0 {delete(self.description)}
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
	native := NativeLimits {
		chain = {stype = SType.NativeLimits},
	}
	base := WGPULimits {
		next_in_chain = &native.chain,
	}

	error_reset_data(loc)
	status := wgpuAdapterGetLimits(self, &base)
	if get_last_error() != nil {
		return
	}
	if status != .Success {
		error_update_data(ErrorType.Unknown, "Failed to fill adapter limits")
		return
	}

	limits = limits_merge_base_with_native(base, native)

	// Why wgpu returns 0 for some supported limits?
	// Enforce minimum values for all limits even if the returned values are lower
	limits_ensure_minimum(&limits, minimum = DOWNLEVEL_WEBGL2_LIMITS)

	return limits, true
}

/* Check if adapter support all features in the given flags. */
adapter_has_feature :: proc "contextless" (
	self: Adapter,
	features: Features,
	loc := #caller_location,
) -> bool {
	if features == {} {
		return true
	}
	available := adapter_get_features(self)
	if available == {} {
		return false
	}
	for f in features {
		if f not_in available {
			return false
		}
	}
	return true
}

/*
Describes a `Device`.

For use with `adapter_request_device`.

Corresponds to [WebGPU `GPUDeviceDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpudevicedescriptor).
*/
DeviceDescriptor :: struct {
	label:                          string,
	optional_features:              Features,
	required_features:              Features,
	required_limits:                Limits,
	device_lost_callback_info:      DeviceLostCallbackInfo,
	uncaptured_error_callback_info: UncapturedErrorCallbackInfo,
	trace_path:                     string,
}

/*
Requests a connection to a physical device, creating a logical device.

[Per the WebGPU specification], an `Adapter` may only be used once to create a device.
If another device is wanted, call `instance_request_adapter` again to get a fresh
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
	descriptor: Maybe(DeviceDescriptor) = nil,
	loc := #caller_location,
) -> (
	device: Device,
	ok: bool,
) #optional_ok {
	desc, desc_ok := descriptor.?
	if !desc_ok {
		return adapter_request_device_raw(self, nil, loc)
	}

	raw_desc: WGPUDeviceDescriptor

	c_label: StringViewBuffer
	if desc.label != "" {
		raw_desc.label = init_string_buffer(&c_label, desc.label)
	}

	features: sa.Small_Array(int(MAX_FEATURES), FeatureName)

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	ta := context.temp_allocator

	adapter_info := adapter_get_info(self, ta, loc) or_return
	adapter_features := adapter_get_features(self)

	required_features := desc.required_features
	for f in desc.optional_features {
		if f in adapter_features {
			required_features += {f}
		} else {
			log.warnf("WGPU: Ignoring unsupported optional feature: [%v]", f)
		}
	}

	// Check for unsupported features
	if required_features != {} {
		for f in required_features {
			if f not_in adapter_features {
				error_reset_and_update(
					.Validation,
					fmt.tprintf(
						"Required feature [%v] not supported by device [%s] using [%s].",
						f,
						adapter_info.device,
						adapter_info.backend_type,
					),
					loc,
				)
				return
			}
			sa.push_back(&features, features_flag_to_raw_feature_name(f))
		}

		raw_desc.required_feature_count = uint(sa.len(features))
		raw_desc.required_features = raw_data(sa.slice(&features))
	}

	adapter_limits := adapter_get_limits(self, loc) or_return

	// If no limits is provided, default to adapter best limits
	limits := desc.required_limits if desc.required_limits != {} else adapter_limits

	// Why wgpu returns 0 for some supported limits?
	// Enforce minimum values for all limits even if the current values are lower
	limits_ensure_minimum(&limits, minimum = DOWNLEVEL_WEBGL2_LIMITS)

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

	base_limits := WGPULimits {
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

	native_limits := NativeLimits {
		chain = {stype = SType.NativeLimits},
	}
	native_limits = {
		max_push_constant_size   = limits.max_push_constant_size,
		max_non_sampler_bindings = limits.max_non_sampler_bindings,
	}
	base_limits.next_in_chain = &native_limits.chain

	raw_desc.required_limits = &base_limits

	raw_desc.device_lost_callback_info = desc.device_lost_callback_info
	raw_desc.uncaptured_error_callback_info = desc.uncaptured_error_callback_info

	when ODIN_DEBUG {
		device_extras := DeviceExtras {
			chain = {stype = .DeviceExtras},
		}
		// Write a trace of all commands to a file so it can be reproduced
		// elsewhere. The trace is cross-platform.
		c_trace_path: StringViewBuffer
		if desc.trace_path != "" {
			device_extras.trace_path = init_string_buffer(&c_trace_path, desc.trace_path)
			raw_desc.next_in_chain = &device_extras.chain
		}
	}

	return adapter_request_device_raw(self, &raw_desc, loc)
}

DeviceResponse :: struct {
	status:  RequestDeviceStatus,
	device:  Device,
	message: StringView,
}

adapter_request_device_callback :: proc "c" (
	status: RequestDeviceStatus,
	device: Device,
	message: StringView,
	userdata1: rawptr,
	userdata2: rawptr,
) {
	response := cast(^DeviceResponse)userdata1

	response.status = status
	response.message = message

	if status == .Success {
		response.device = device
	}
}

adapter_request_device_raw :: proc(
	self: Adapter,
	descriptor: ^WGPUDeviceDescriptor = nil,
	loc := #caller_location,
) -> (
	device: Device,
	ok: bool,
) {
	res: DeviceResponse
	callback_info := RequestDeviceCallbackInfo {
		callback  = adapter_request_device_callback,
		userdata1 = &res,
	}

	// Force the uncaptured error callback in debug mode
	when ODIN_DEBUG {
		desc: WGPUDeviceDescriptor
		desc = descriptor^ if descriptor != nil else {}
		// Errors will propagate from this callback
		desc.uncaptured_error_callback_info.callback = uncaptured_error_data_callback
		wgpuAdapterRequestDevice(self, &desc, callback_info)
	} else {
		wgpuAdapterRequestDevice(self, descriptor, callback_info)
	}

	if res.status != .Success {
		// A non success status with no message means unknown error, like unsupported limits...
		message := string_view_get_string(res.message)
		error_reset_and_update(res.status, message if message != "" else "Unknown", loc)
		return
	}

	device = res.device

	when ODIN_DEBUG {
		// Set a error handling for this device
		set_uncaptured_error_callback(
			device,
			descriptor.uncaptured_error_callback_info.callback if descriptor != nil else nil,
			descriptor.uncaptured_error_callback_info.userdata1 if descriptor != nil else nil,
			descriptor.uncaptured_error_callback_info.userdata2 if descriptor != nil else nil,
		)
	}

	return device, true
}

/*  Increase the reference count. */
adapter_add_ref :: wgpuAdapterAddRef

/*  Release the `Adapter` resources. */
adapter_release :: wgpuAdapterRelease
