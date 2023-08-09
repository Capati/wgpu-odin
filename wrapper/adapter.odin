package wgpu

// Core
import "core:fmt"
import "core:mem"
import "core:os"

// Package
import wgpu "../bindings"

// Handle to a physical graphics and/or compute device.
Adapter :: struct {
    ptr:           WGPU_Adapter,
    features:      []Feature_Name,
    limits:        Limits,
    limits_extras: Limits_Extras,
    info:          Adapter_Info,
    using vtable:  ^Adapter_VTable,
}

Adapter_Info :: wgpu.Adapter_Properties

@(private)
Adapter_VTable :: struct {
    get_features:   proc(
        self: ^Adapter,
        allocator: mem.Allocator = context.allocator,
    ) -> []Feature_Name,
    get_limits:     proc(self: ^Adapter) -> (Limits, Limits_Extras),
    request_info:   proc(self: ^Adapter) -> Adapter_Info,
    has_feature:    proc(self: ^Adapter, feature: Feature_Name) -> bool,
    request_device: proc(
        self: ^Adapter,
        options: ^Device_Options = nil,
        trace_path: cstring = nil,
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
) -> []Feature_Name {
    features_count := wgpu.adapter_enumerate_features(ptr, nil)

    if features_count == 0 {
        return {}
    }

    adapter_features := make([]Feature_Name, features_count, allocator)
    wgpu.adapter_enumerate_features(ptr, raw_data(adapter_features))

    return adapter_features[:]
}

Limits_Extras :: struct {
    max_push_constant_size: u32,
}

// List the “best” limits that are supported by this adapter.
adapter_get_limits :: proc(using self: ^Adapter) -> (Limits, Limits_Extras) {
    extras := Supported_Limits_Extras{}
    supported_limits := Supported_Limits {
        next_in_chain = cast(^Chained_Struct_Out)&extras,
    }
    wgpu.adapter_get_limits(ptr, &supported_limits)

    return supported_limits.limits,
        {max_push_constant_size = extras.max_push_constant_size}
}

// Get info about the adapter itself.
adapter_request_info :: proc(using self: ^Adapter) -> Adapter_Info {
    adapter_properties := Adapter_Info{}
    wgpu.adapter_get_properties(ptr, &adapter_properties)

    return adapter_properties
}

// Check if adapter support a feature.
adapter_has_feature :: proc(using self: ^Adapter, feature: Feature_Name) -> bool {
    return wgpu.adapter_has_feature(ptr, feature)
}

Device_Options :: struct {
    label:                cstring,
    features:             []Feature_Name,
    native_features:      []Native_Feature,
    limits:               Limits,
    limits_extra:         Limits_Extras,
    trace_path:           cstring,
    device_lost_callback: Device_Lost_Callback,
    device_lost_userdata: rawptr,
}

default_device_options := Device_Options {
    label = "",
    features = nil,
    native_features = nil,
    limits = {},
    limits_extra = {},
    trace_path = nil,
    device_lost_callback = nil,
    device_lost_userdata = nil,
}

Device_Response :: struct {
    status:  Request_Device_Status,
    message: cstring,
    device:  WGPU_Device,
}

// Requests a connection to a physical device, creating a logical device.
adapter_request_device :: proc(
    using self: ^Adapter,
    options: ^Device_Options = nil,
    trace_path: cstring = nil,
) -> (
    device: Device,
    err: Error_Type,
) {
    device_options := Device_Options{}

    if options == nil {
        device_options = default_device_options
    } else {
        device_options.label = options.label
        device_options.features = options.features
        device_options.native_features = options.native_features
        device_options.limits = options.limits
        device_options.limits_extra = options.limits_extra
        device_options.trace_path = options.trace_path
        device_options.device_lost_callback = options.device_lost_callback
        device_options.device_lost_userdata = options.device_lost_userdata
    }

    descriptor := Device_Descriptor {
        label = device_options.label if device_options.label != nil else info.name,
    }

    if device_options.device_lost_callback != nil {
        descriptor.device_lost_callback = device_options.device_lost_callback
        descriptor.device_lost_userdata = device_options.device_lost_userdata
    }

    required_features: [dynamic]Feature_Name
    defer delete(required_features)

    if device_options.features != nil && len(device_options.features) > 0 {
        for f in device_options.features {
            if !wgpu.adapter_has_feature(ptr, f) {
                fmt.eprintf("Feature [%v] is not supported by this adapter.\n", f)
                return {}, .Validation
            }

            append(&required_features, f)
        }
    }

    if device_options.native_features != nil && len(device_options.native_features) > 0 {
        for f in device_options.native_features {
            if !wgpu.adapter_has_feature(ptr, transmute(Feature_Name)f) {
                fmt.eprintf("Native feature [%v] is not supported by this adapter.\n", f)
                return {}, .Validation
            }

            append(&required_features, transmute(Feature_Name)f)
        }
    }

    if len(required_features) > 0 {
        descriptor.required_features_count = len(required_features)
        descriptor.required_features = raw_data(required_features)
    }

    // Set default limits
    required_limits := Required_Limits {
        next_in_chain = nil,
        limits        = Default_Limits,
    }

    if device_options.limits_extra != {} {
        required_limits_extras := Required_Limits_Extras {
            max_push_constant_size = device_options.limits_extra.max_push_constant_size,
        }
        required_limits.next_in_chain = cast(^Chained_Struct)&required_limits_extras
    }

    if device_options.limits != {} {
        required_limits.limits = device_options.limits
    }

    descriptor.required_limits = &required_limits

    // Write a trace of all commands to a file so it can be reproduced
    // elsewhere. The trace is cross-platform.
    if trace_path != nil {
        descriptor.next_in_chain =
        cast(^Chained_Struct)&Device_Extras{
            chain = Chained_Struct{
                next = nil,
                stype = SType(Native_SType.Device_Extras),
            },
            trace_path = trace_path,
        }

        dir := string(trace_path)
        if res := os.is_dir(dir); !res {
            if res := os.make_directory(dir); res != 0 {
                fmt.eprintf("Failed to make trace path directory: [%v]\n", res)
                return {}, .Unknown
            }
        }
    }

    res := Device_Response{}
    wgpu.adapter_request_device(ptr, &descriptor, _on_adapter_request_device, &res)

    if res.status != .Success {
        fmt.eprintf("Failed to request a device: [%v] - %s\n", res.status, res.message)
        return {}, .Internal
    }

    device = default_device
    device.ptr = res.device
    device.features = device->get_features()
    device.limits = device->get_limits()
    device.err_scope = new(Error_Scope) // Heap allocate to avoid stack fuckery
    wgpu.device_set_uncaptured_error_callback(device.ptr, error_scope_callback, device.err_scope)

    queue := default_queue
    queue.ptr = wgpu.device_get_queue(res.device)
    queue.err_scope = device.err_scope

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
    response.message = message

    if status == .Success {
        response.device = device
    }
}
