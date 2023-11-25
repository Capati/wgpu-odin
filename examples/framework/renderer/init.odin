package renderer

// Core
import "core:fmt"
import "core:reflect"
import "core:runtime"

// Packages
import app "../application"
import "../application/core"
import "../application/events"

// Libs
import wgpu "../../../wrapper"

Renderer :: struct {
    properties: Renderer_Properties,
    surface:    wgpu.Surface,
    device:     wgpu.Device,
    config:     wgpu.Surface_Configuration,
    frame:      wgpu.Texture_View,
    skip_frame: bool,
}

Renderer_Properties :: struct {
    power_preferences: wgpu.Power_Preference,
    required_features: []wgpu.Features,
    required_limits:   wgpu.Limits,
}

Default_Render_Properties :: Renderer_Properties {
    power_preferences = .High_Performance,
}

Renderer_Error :: enum {
    No_Error,
    Gpu_Failed,
    Init_Failed,
    Render_Failed,
    Suboptimal_Surface,
}

init :: proc(
    properties: Renderer_Properties = Default_Render_Properties,
) -> (
    gc: ^Renderer,
    err: Renderer_Error,
) {
    fmt.println("GPU init...\n")

    gc = new(Renderer)
    defer if err != .No_Error do free(gc)

    if !app.is_initialized() {
        panic("Application is not initialized")
    }

    properties := properties

    wgpu.set_log_callback(_wgpu_native_log_callback, nil)
    wgpu.set_log_level(.Warn)

    instance, instance_err := wgpu.create_instance(
        & {
            backends = wgpu.Instance_Backend_Primary,
            dx12_shader_compiler = wgpu.Default_Dx12_Compiler,
        },
    )
    if instance_err != .No_Error {
        fmt.eprintf(
            "Failed to create GPU Instance [%v]: %s\n",
            instance_err,
            wgpu.get_error_message(),
        )
        return nil, .Init_Failed
    }
    defer instance->release()

    gpu_err: wgpu.Error_Type

    gc.surface, gpu_err = app.get_wgpu_surface(&instance)
    if gpu_err != .No_Error {
        fmt.eprintf("Failed to create GPU Surface [%v]: %s\n", gpu_err, wgpu.get_error_message())
        return nil, .Init_Failed
    }
    defer if err != .No_Error do gc.surface->release()

    adapter_options := wgpu.Request_Adapter_Options {
        power_preference       = properties.power_preferences,
        compatible_surface     = &gc.surface,
        force_fallback_adapter = false,
    }

    when core.APPLICATION_TYPE == .Wasm {
        adapter_options.backend_type = .WebGPU
    }

    when core.APPLICATION_TYPE == .Native {
        // Force backend type config
        WGPU_BACKEND_TYPE :: #config(WGPU_BACKEND_TYPE, core.STR_UNDEFINED_CONFIG)

        // Try to read WGPU_BACKEND_TYPE config to see if a backend type should be forced
        if WGPU_BACKEND_TYPE != core.STR_UNDEFINED_CONFIG {
            // Try to get the backend type from the string configuration
            backend, backend_ok := reflect.enum_from_name(wgpu.Backend_Type, WGPU_BACKEND_TYPE)

            if backend_ok {
                adapter_options.backend_type = backend
            } else {
                fmt.eprintf(
                    "Backend type [%v] is invalid, possible values are (case sensitive): \n\tWebGPU\n\tD3D11\n\tD3D12\n\tMetal\n\tVulkan\n\tOpenGL\n\tOpenGLES\n\n",
                    WGPU_BACKEND_TYPE,
                )

                return nil, .Init_Failed
            }
        } else {
            // By default force D3D12 on Windows if none is given
            // https://github.com/gfx-rs/wgpu/issues/2719
            when ODIN_OS == .Windows {
                adapter_options.backend_type = .D3D12
            }
        }
    }

    adapter, adapter_err := instance->request_adapter(&adapter_options)
    if adapter_err != .No_Error {
        fmt.eprintf(
            "Failed to create GPU Adapter [%v]: %s\n",
            adapter_err,
            wgpu.get_error_message(),
        )
        return nil, .Init_Failed
    }
    defer adapter->release()

    // Print selected adapter information
    adapter->print_info()

    device_descriptor := wgpu.Device_Descriptor {
        label    = adapter.info.name,
        limits   = properties.required_limits,
        features = properties.required_features,
    }

    gc.properties = properties

    gc.device, gpu_err = adapter->request_device(&device_descriptor)
    if gpu_err != .No_Error {
        fmt.eprintf("Failed to create GPU Device [%v]: %s\n", gpu_err, wgpu.get_error_message())
        return nil, .Init_Failed
    }
    defer if err != .No_Error do gc.device->release()

    caps, caps_err := gc.surface->get_capabilities(adapter)
    if caps_err != .No_Error {
        fmt.eprintf(
            "Failed to get surface capabilities [%v]: %s\n",
            caps_err,
            wgpu.get_error_message(),
        )
        return nil, .Init_Failed
    }
    defer {
        delete(caps.formats)
        delete(caps.present_modes)
        delete(caps.alpha_modes)
    }

    size := app.get_size()

    surface_format := gc.surface->get_preferred_format(&adapter)

    gc.config = wgpu.Surface_Configuration {
        usage = {.Render_Attachment},
        format = surface_format,
        width = size.width,
        height = size.height,
        present_mode = .Fifo,
        alpha_mode = caps.alpha_modes[0],
    }

    gpu_err = gc.surface->configure(&gc.device, &gc.config)
    if gpu_err != .No_Error {
        fmt.eprintf("Failed to configure surface [%v]: %s\n", gpu_err, wgpu.get_error_message())
        return nil, .Gpu_Failed
    }

    // Set device errors callback
    gc.device->set_uncaptured_error_callback(_on_native_device_uncaptured_error, gc)

    fmt.printf("GPU initialized successfully. \n\n")

    return
}

deinit :: proc(renderer: ^Renderer) {
    renderer.device->release()
    renderer.surface->release()
    free(renderer)
}

@(private = "file")
_wgpu_native_log_callback :: proc "c" (
    level: wgpu.Log_Level,
    message: cstring,
    user_data: rawptr,
) {
    context = runtime.default_context()
    fmt.eprintf("[wgpu] [%v] %s\n\n", level, message)
}

@(private = "file")
_on_native_device_uncaptured_error :: proc "c" (
    type: wgpu.Error_Type,
    message: cstring,
    user_data: rawptr,
) {
    context = runtime.default_context()
    fmt.eprintf("Uncaught WGPU error [%v]:\n\t%s...\n", type, message)

    // Handle device lost in the browser
    when core.APPLICATION_TYPE == .Wasm {
        gpu := cast(^Renderer)user_data
        if type == .Device_Lost {
            if init(gc.properties) != .No_Error {
                app.push_event(events.Quit_Event(true))
            }
        }
    } else {
        app.push_event(events.Quit_Event(true))
    }
}
