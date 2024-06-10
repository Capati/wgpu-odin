package renderer

// Core
import "base:runtime"
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
	queue:      wgpu.Queue,
	config:     wgpu.Surface_Configuration,
	skip_frame: bool,
}

Renderer_Properties :: struct {
	power_preferences: wgpu.Power_Preference,
	required_features: []wgpu.Feature,
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

	instance, instance_err := wgpu.create_instance()
	if instance_err != .No_Error {
		fmt.eprintf(
			"Failed to create GPU Instance [%v]: %s\n",
			instance_err,
			wgpu.get_error_message(),
		)
		return nil, .Init_Failed
	}
	defer wgpu.instance_release(&instance)

	gpu_err: wgpu.Error_Type

	gc.surface, gpu_err = app.get_wgpu_surface(&instance)
	if gpu_err != .No_Error {
		fmt.eprintf("Failed to create GPU Surface [%v]: %s\n", gpu_err, wgpu.get_error_message())
		return nil, .Init_Failed
	}
	defer if err != .No_Error do wgpu.surface_release(&gc.surface)

	adapter_options := wgpu.Request_Adapter_Options {
		power_preference       = properties.power_preferences,
		compatible_surface     = gc.surface.ptr,
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
		}
	}

	adapter, adapter_err := wgpu.instance_request_adapter(&instance, &adapter_options)
	if adapter_err != .No_Error {
		fmt.eprintf(
			"Failed to create GPU Adapter [%v]: %s\n",
			adapter_err,
			wgpu.get_error_message(),
		)
		return nil, .Init_Failed
	}
	defer wgpu.adapter_release(&adapter)

	fmt.printf("Device information:\n\n")

	// Print selected adapter information
	wgpu.adapter_print_info(&adapter)

	device_descriptor := wgpu.Device_Descriptor {
		label    = adapter.properties.name,
		required_limits   = properties.required_limits,
		features = properties.required_features,
	}

	gc.properties = properties

	gc.device, gc.queue, gpu_err = wgpu.adapter_request_device(&adapter, &device_descriptor)
	if gpu_err != .No_Error {
		fmt.eprintf("Failed to create GPU Device [%v]: %s\n", gpu_err, wgpu.get_error_message())
		return nil, .Init_Failed
	}
	defer if err != .No_Error {
		wgpu.queue_release(&gc.queue)
		wgpu.device_release(&gc.device)
	}

	caps, caps_err := wgpu.surface_get_capabilities(&gc.surface, adapter.ptr)
	if caps_err != .No_Error {
		fmt.eprintf(
			"Failed to get surface capabilities [%v]: %s\n",
			caps_err,
			wgpu.get_error_message(),
		)
		return nil, .Init_Failed
	}
	defer {
		wgpu.surface_delete_capabilities(&caps)
	}

	size := app.get_size()

	preferred_format := wgpu.surface_get_preferred_format(&gc.surface, adapter.ptr)

	gc.config = wgpu.Surface_Configuration {
		usage        = {.Render_Attachment},
		format       = preferred_format,
		width        = size.width,
		height       = size.height,
		present_mode = .Fifo,
		alpha_mode   = caps.alpha_modes[0],
	}

	gpu_err = wgpu.surface_configure(&gc.surface, &gc.device, &gc.config)
	if gpu_err != .No_Error {
		fmt.eprintf("Failed to configure surface [%v]: %s\n", gpu_err, wgpu.get_error_message())
		return nil, .Gpu_Failed
	}

	// Set device errors callback
	wgpu.device_set_uncaptured_error_callback(&gc.device, _on_native_device_uncaptured_error, gc)

	fmt.printf("GPU initialized successfully. \n\n")

	return
}

deinit :: proc(renderer: ^Renderer) {
	wgpu.queue_release(&renderer.queue)
	wgpu.device_release(&renderer.device)
	wgpu.surface_release(&renderer.surface)
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
