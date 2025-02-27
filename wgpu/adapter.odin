package wgpu

// Packages
import "base:runtime"
import sa "core:container/small_array"
import "core:fmt"
import "core:log"
import "core:strings"

/*
Handle to a physical graphics and/or compute device.

Adapters can be created using `instance_request_adapter`.

Adapters can be used to open a connection to the corresponding `Device`
on the host system by using `adapter_request_device`.

Does not have to be kept alive.

Corresponds to [WebGPU `GPUAdapter`](https://gpuweb.github.io/gpuweb/#gpu-adapter).
*/
Adapter :: distinct rawptr

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

	raw_desc: WGPU_Device_Descriptor

	c_label: String_View_Buffer
	if desc.label != "" {
		raw_desc.label = init_string_buffer(&c_label, desc.label)
	}

	features: sa.Small_Array(MAX_FEATURES, Feature_Name)

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	ta := context.temp_allocator

	adapter_info := adapter_get_info(self, ta, loc) or_return
	adapter_features := adapter_features(self)

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
						adapter_info.backend,
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

	adapter_limits := adapter_limits(self, loc) or_return

	// If no limits is provided, default to the most restrictive limits
	limits := desc.required_limits if desc.required_limits != {} else DEFAULT_MINIMUM_LIMITS

	// WGPU returns 0 for unused limits
	// Enforce minimum values for all limits even if the current values are lower
	limits_ensure_minimum(&limits, DEFAULT_MINIMUM_LIMITS)

	// Check for unsupported limits
	if limits != DEFAULT_MINIMUM_LIMITS {
		if limit_violation, limits_ok := limits_check(limits, adapter_limits); !limits_ok {
			error_reset_and_update(
				.Validation,
				fmt.tprintf(
					"Limits violations detected:\n%s",
					limits_violation_to_string(limit_violation, ta),
				),
				loc,
			)
			return
		}
	}

	base_limits := WGPU_Limits {
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

	native_limits := WGPU_Native_Limits {
		chain = {stype = SType.Native_Limits},
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
		device_extras := WGPU_Device_Extras {
			chain = {stype = .Device_Extras},
		}
		// Write a trace of all commands to a file so it can be reproduced
		// elsewhere. The trace is cross-platform.
		c_trace_path: String_View_Buffer
		if desc.trace_path != "" {
			device_extras.trace_path = init_string_buffer(&c_trace_path, desc.trace_path)
			raw_desc.next_in_chain = &device_extras.chain
		}
	}

	return adapter_request_device_raw(self, &raw_desc, loc)
}

Request_Device_Status :: enum i32 {
	Success          = 0x00000001,
	Instance_Dropped = 0x00000002,
	Error            = 0x00000003,
	Unknown          = 0x00000004,
}

@(private)
adapter_request_device_raw :: proc(
	self: Adapter,
	descriptor: ^WGPU_Device_Descriptor = nil,
	loc := #caller_location,
) -> (
	device: Device,
	ok: bool,
) {
	Device_Response :: struct {
		status:  Request_Device_Status,
		device:  Device,
		message: String_View,
	}

	adapter_request_device_callback :: proc "c" (
		status: Request_Device_Status,
		device: Device,
		message: String_View,
		userdata1: rawptr,
		userdata2: rawptr,
	) {
		response := cast(^Device_Response)userdata1

		response.status = status
		response.message = message

		if status == .Success {
			response.device = device
		}
	}

	res: Device_Response
	callback_info := Request_Device_Callback_Info {
		callback  = adapter_request_device_callback,
		userdata1 = &res,
	}

	// Force the uncaptured error callback in debug mode
	when ODIN_DEBUG {
		desc: WGPU_Device_Descriptor
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

/* Returns whether this adapter may present to the passed surface. */
adapter_is_surface_supported :: proc(self: Adapter, surface: Surface) -> bool {
	raw_caps: WGPU_Surface_Capabilities
	status := wgpuSurfaceGetCapabilities(surface, self, &raw_caps)
	defer wgpuSurfaceCapabilitiesFreeMembers(raw_caps)
	// If wgpuSurfaceGetCapabilities returns Error, then the API does not advertise
	// support for the given surface.
	return status == .Success
}

/* The features which can be used to create devices on this adapter. */
adapter_features :: proc "contextless" (self: Adapter) -> (features: Features) #no_bounds_check {
	supported: WGPU_Supported_Features
	wgpuAdapterGetFeatures(self, &supported)
	defer wgpuSupportedFeaturesFreeMembers(supported)

	raw_features := supported.features[:supported.feature_count]
	features = features_slice_to_flags(raw_features)

	return
}

adapter_has_feature :: proc "contextless" (self: Adapter, features: Features) -> bool {
	if features == {} {
		return true
	}
	available := adapter_features(self)
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

/* The best limits which can be used to create devices on this adapter. */
adapter_limits :: proc "contextless" (
	self: Adapter,
	loc := #caller_location,
) -> (
	limits: Limits,
	ok: bool,
) #optional_ok {
	native := WGPU_Native_Limits {
		chain = {stype = SType.Native_Limits},
	}
	base := WGPU_Limits {
		next_in_chain = &native.chain,
	}

	error_reset_data(loc)
	status := wgpuAdapterGetLimits(self, &base)
	if get_last_error() != nil {
		return
	}
	if status != .Success {
		error_update_data(Error_Type.Unknown, "Failed to fill adapter limits")
		return
	}

	limits = limits_merge_webgpu_with_native(base, native)

	// WGPU returns 0 for unused limits
	// Enforce minimum values for all limits even if the returned values are lower
	limits_ensure_minimum(&limits, DEFAULT_MINIMUM_LIMITS)

	return limits, true
}

/* Get info about the adapter itself. */
adapter_get_info :: proc(
	self: Adapter,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	info: Adapter_Info,
	ok: bool,
) #optional_ok {
	raw_info: WGPU_Adapter_Info
	status := wgpuAdapterGetInfo(self, &raw_info)
	defer wgpuAdapterInfoFreeMembers(raw_info)

	if status != .Success {
		// TODO(Capati): its failing on Unix, even when information is filled ok
		// error_reset_and_update(Error_Type.Unknown, "Failed to fill adapter information", loc)
		// return
	}

	fill_adapter_info(&info, &raw_info, allocator)

	return info, true
}

@(private)
fill_adapter_info :: proc(
	self: ^Adapter_Info,
	raw_info: ^WGPU_Adapter_Info,
	allocator: runtime.Allocator,
) {
	if raw_info.vendor.length > 0 {
		self.vendor = strings.clone(string_view_get_string(raw_info.vendor), allocator)
	}

	if raw_info.architecture.length > 0 {
		self.architecture = strings.clone(string_view_get_string(raw_info.architecture), allocator)
	}

	if raw_info.device.length > 0 {
		self.device = strings.clone(string_view_get_string(raw_info.device), allocator)
	}

	if raw_info.description.length > 0 {
		self.description = strings.clone(string_view_get_string(raw_info.description), allocator)
	}

	self.backend = raw_info.backend
	self.device_type = raw_info.device_type
	self.vendor_id = raw_info.vendor_id
	self.device_id = raw_info.device_id
}

/* Release the `Adapter_Info` resources (remove the allocated strings). */
adapter_info_free_members :: proc(self: Adapter_Info, allocator := context.allocator) {
	context.allocator = allocator
	if len(self.vendor) > 0 {delete(self.vendor)}
	if len(self.architecture) > 0 {delete(self.architecture)}
	if len(self.device) > 0 {delete(self.device)}
	if len(self.description) > 0 {delete(self.description)}
}

/* Get info about the adapter itself as `string`. */
adapter_info_string :: proc(
	info: Adapter_Info,
	allocator := context.allocator,
) -> (
	str: string,
	ok: bool,
) #optional_ok {
	sb: strings.Builder
	err: runtime.Allocator_Error

	ta := context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == ta)
	if sb, err = strings.builder_make(ta); err != nil {
		return
	}
	defer strings.builder_destroy(&sb)

	strings.write_string(&sb, info.device)
	strings.write_byte(&sb, '\n')

	strings.write_string(&sb, "  - Driver: ")
	strings.write_string(&sb, info.description if info.description != "" else "Unknown")
	strings.write_byte(&sb, '\n')

	device_type: string
	switch info.device_type {
	case .Discrete_GPU:
		device_type = "Discrete GPU with separate CPU/GPU memory"
	case .Integrated_GPU:
		device_type = "Integrated GPU with shared CPU/GPU memory"
	case .CPU:
		device_type = "Cpu / Software Rendering"
	case .Unknown:
		device_type = "Unknown"
	}
	strings.write_string(&sb, "  - Type: ")
	strings.write_string(&sb, device_type)
	strings.write_byte(&sb, '\n')

	backend: string
	#partial switch info.backend {
	case .Null:
		backend = "Empty"
	case .WebGPU:
		backend = "WebGPU in the browser"
	case .D3D11:
		backend = "Direct3D-11"
	case .D3D12:
		backend = "Direct3D-12"
	case .Metal:
		backend = "Metal API"
	case .Vulkan:
		backend = "Vulkan API"
	case .OpenGL:
		backend = "OpenGL"
	case .OpenGLES:
		backend = "OpenGLES"
	}
	strings.write_string(&sb, "  - Backend: ")
	strings.write_string(&sb, backend)

	if str, err = strings.clone(strings.to_string(sb), allocator); err != nil {
		return
	}

	return str, true
}

/* Print info about the adapter itself. */
adapter_info_print_info :: proc(info: Adapter_Info) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	fmt.printfln("%s", adapter_info_string(info, context.temp_allocator))
}

/*
Returns the features supported for a given texture format by this adapter.

Note that the WebGPU spec further restricts the available usages/features.
To disable these restrictions on a device, request the [`Features::TEXTURE_ADAPTER_SPECIFIC_FORMAT_FEATURES`] feature.
*/
adapter_get_texture_format_features :: proc(
	self: Adapter,
	format: Texture_Format,
	loc := #caller_location,
) -> (
	features: Texture_Format_Features,
) {
	adapter_features := adapter_features(self)
	return texture_format_guaranteed_format_features(format, adapter_features)
}

/*  Increase the `Adapter` reference count. */
adapter_add_ref :: wgpuAdapterAddRef

/*  Release the `Adapter` resources, use to decrease the reference count. */
adapter_release :: wgpuAdapterRelease

/*
Safely releases the `Adapter` resources and invalidates the handle.
The procedure checks both the pointer validity and the adapter handle before releasing.

Note: After calling this, the adapter handle will be set to `nil` and should not be used.
*/
adapter_release_safe :: #force_inline proc(self: ^Adapter) {
	if self != nil && self^ != nil {
		wgpuAdapterRelease(self^)
		self^ = nil
	}
}

@(private)
WGPU_Device_Extras :: struct {
	chain:      Chained_Struct,
	trace_path: String_View,
}

@(private)
WGPU_Device_Descriptor :: struct {
	next_in_chain:                  ^Chained_Struct,
	label:                          String_View,
	required_feature_count:         uint,
	required_features:              [^]Feature_Name,
	required_limits:                ^WGPU_Limits,
	default_queue:                  Queue_Descriptor,
	device_lost_callback_info:      Device_Lost_Callback_Info,
	uncaptured_error_callback_info: Uncaptured_Error_Callback_Info,
}

@(private)
WGPU_Adapter_Info :: struct {
	next_in_chain: ^Chained_Struct_Out,
	vendor:        String_View,
	architecture:  String_View,
	device:        String_View,
	description:   String_View,
	backend:       Backend,
	device_type:   Device_Type,
	vendor_id:     u32,
	device_id:     u32,
}
