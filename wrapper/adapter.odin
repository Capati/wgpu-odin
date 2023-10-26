package wgpu

// Core
import "core:mem"
import "core:runtime"

// Package
import wgpu "../bindings"

// Handle to a physical graphics and/or compute device.
Adapter :: struct {
    ptr:          WGPU_Adapter,
    features:     []Features,
    limits:       Limits,
    info:         Adapter_Info,
    using vtable: ^Adapter_VTable,
}

Adapter_Info :: wgpu.Adapter_Properties

@(private)
Adapter_VTable :: struct {
    get_features:   proc(
        self: ^Adapter,
        allocator: mem.Allocator = context.allocator,
    ) -> []Features,
    get_limits:     proc(self: ^Adapter) -> Limits,
    request_info:   proc(self: ^Adapter) -> Adapter_Info,
    has_feature:    proc(self: ^Adapter, feature: Features) -> bool,
    request_device: proc(
        self: ^Adapter,
        descriptor: ^Device_Descriptor = nil,
    ) -> (
        Device,
        Error_Type,
    ),
    release:        proc(self: ^Adapter),
}

@(private)
default_adapter_vtable := Adapter_VTable {
    get_features   = adapter_get_features,
    get_limits     = adapter_get_limits,
    request_info   = adapter_request_info,
    has_feature    = adapter_has_feature,
    request_device = adapter_request_device,
    release        = adapter_release,
}

@(private)
default_adapter := Adapter {
    ptr    = nil,
    vtable = &default_adapter_vtable,
}

// List all features that are supported with this adapter.
adapter_get_features :: proc(
    using self: ^Adapter,
    allocator := context.allocator,
) -> []Features {
    features_count := wgpu.adapter_enumerate_features(ptr, nil)

    if features_count == 0 {
        return {}
    }

    adapter_features := make([]wgpu.Feature_Name, features_count, allocator)
    wgpu.adapter_enumerate_features(ptr, raw_data(adapter_features))

    return transmute([]Features)adapter_features
}

// List the “best” limits that are supported by this adapter.
adapter_get_limits :: proc(self: ^Adapter) -> Limits {
    extras := Supported_Limits_Extras{}
    supported_limits := Supported_Limits {
        next_in_chain = cast(^Chained_Struct_Out)&extras,
    }
    wgpu.adapter_get_limits(self.ptr, &supported_limits)

    limits := supported_limits.limits

    all_limits: Limits = {
        max_texture_dimension_1d                        = limits.max_texture_dimension_1d,
        max_texture_dimension_2d                        = limits.max_texture_dimension_2d,
        max_texture_dimension_3d                        = limits.max_texture_dimension_3d,
        max_texture_array_layers                        = limits.max_texture_array_layers,
        max_bind_groups                                 = limits.max_bind_groups,
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
        // Limits extras
        max_push_constant_size                          = extras.max_push_constant_size,
    }

    return all_limits
}

// Get info about the adapter itself.
adapter_request_info :: proc(using self: ^Adapter) -> Adapter_Info {
    adapter_properties := Adapter_Info{}
    wgpu.adapter_get_properties(ptr, &adapter_properties)

    return adapter_properties
}

// Check if adapter support a feature.
adapter_has_feature :: proc(using self: ^Adapter, feature: Features) -> bool {
    return wgpu.adapter_has_feature(ptr, cast(wgpu.Feature_Name)feature)
}

// Describes a `Device` for use with `adapter->request_device`.
Device_Descriptor :: struct {
    label:                cstring,
    features:             []Features,
    limits:               Limits,
    trace_path:           cstring,
    device_lost_callback: Device_Lost_Callback,
    device_lost_userdata: rawptr,
}

@(private)
Device_Response :: struct {
    status: Request_Device_Status,
    device: WGPU_Device,
}

// Requests a connection to a physical device, creating a logical device.
adapter_request_device :: proc(
    using self: ^Adapter,
    descriptor: ^Device_Descriptor = nil,
) -> (
    device: Device,
    err: Error_Type,
) {
    // Default descriptor can be NULL...
    desc: ^wgpu.Device_Descriptor = nil

    if descriptor != nil {
        desc = &{}

        if descriptor.label != nil && descriptor.label != "" {
            desc.label = descriptor.label
        } else {
            desc.label = info.name
        }

        if len(descriptor.features) > 0 {
            desc.required_features_count = len(descriptor.features)
            desc.required_features =
            transmute(^wgpu.Feature_Name)raw_data(descriptor.features)
        }

        // Set limits
        required_limits := Required_Limits {
            next_in_chain = nil,
        }

        // If no limits is provided, default to adapter best limits
        limits := descriptor.limits if descriptor.limits != {} else limits

        required_limits.limits = {
            max_texture_dimension_1d                        = limits.max_texture_dimension_1d,
            max_texture_dimension_2d                        = limits.max_texture_dimension_2d,
            max_texture_dimension_3d                        = limits.max_texture_dimension_3d,
            max_texture_array_layers                        = limits.max_texture_array_layers,
            max_bind_groups                                 = limits.max_bind_groups,
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
            max_push_constant_size = limits.max_push_constant_size,
        }
        required_limits.next_in_chain = cast(^Chained_Struct)&required_limits_extras

        desc.required_limits = &required_limits

        if descriptor.device_lost_callback != nil {
            descriptor.device_lost_callback = descriptor.device_lost_callback
            descriptor.device_lost_userdata = descriptor.device_lost_userdata
        }

        // Write a trace of all commands to a file so it can be reproduced
        // elsewhere. The trace is cross-platform.
        if descriptor.trace_path != nil && descriptor.trace_path != "" {
            desc.next_in_chain =
            cast(^Chained_Struct)&Device_Extras{
                chain = Chained_Struct{
                    next = nil,
                    stype = SType(Native_SType.Device_Extras),
                },
                trace_path = descriptor.trace_path,
            }
        }
    }

    res := Device_Response{}
    wgpu.adapter_request_device(ptr, desc, _on_adapter_request_device, &res)

    if res.status != .Success {
        return {}, .Unknown
    }

    device = default_device
    device.ptr = res.device
    device.features = device->get_features()
    device.limits = device->get_limits()
    device.err_data = new(Error_Data) // Heap allocate to avoid stack fuckery
    wgpu.device_set_uncaptured_error_callback(
        device.ptr,
        uncaptured_error_callback,
        device.err_data,
    )

    queue := default_queue
    queue.ptr = wgpu.device_get_queue(res.device)
    queue.err_data = device.err_data

    device.queue = queue

    return device, .No_Error
}

// Release the `Adapter`.
adapter_release :: proc(using self: ^Adapter) {
    delete(features)
    wgpu.adapter_release(ptr)
}

@(private)
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
