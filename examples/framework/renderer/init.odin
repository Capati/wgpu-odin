package renderer

// Core
import "base:runtime"
import "core:fmt"
import "core:reflect"

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
	optional_features: wgpu.Features,
	required_features: wgpu.Features,
	required_limits:   wgpu.Limits,
}

Default_Render_Properties :: Renderer_Properties {
	power_preferences = .High_Performance,
}

init :: proc(
	properties: Renderer_Properties = Default_Render_Properties,
	loc := #caller_location,
) -> (
	gc: ^Renderer,
	err: wgpu.Error,
) {
	fmt.println("GPU init...\n")

	gc = new(Renderer)
	defer if err != nil do free(gc)

	if !app.is_initialized() {
		panic("Application is not initialized")
	}

	properties := properties

	wgpu.set_log_callback(_wgpu_native_log_callback, nil)
	wgpu.set_log_level(.Warn)

	instance_descriptor: wgpu.Instance_Descriptor

	when core.APPLICATION_TYPE == .Native {
		// Force backend type config
		WGPU_BACKEND_TYPE :: #config(WGPU_BACKEND_TYPE, core.STR_UNDEFINED_CONFIG)

		// Try to read WGPU_BACKEND_TYPE config to see if a backend type should be forced
		if WGPU_BACKEND_TYPE != core.STR_UNDEFINED_CONFIG {
			// Try to get the backend type from the string configuration
			backend, backend_ok := reflect.enum_from_name(wgpu.Instance_Backend, WGPU_BACKEND_TYPE)

			if backend_ok {
				instance_descriptor.backends = {backend}
			} else {
				fmt.eprintf(
					"Backend type [%v] is invalid, possible values are from Instance_Backend (case sensitive): \n\tVulkan,\n\tGL,\n\tMetal,\n\tDX12,\n\tDX11,\n\tBrowser_WebGPU",
					WGPU_BACKEND_TYPE,
				)

				err = .Validation
				return
			}
		}
	}

	instance := wgpu.create_instance(&instance_descriptor, loc) or_return
	defer wgpu.instance_release(&instance)

	gc.surface = app.get_wgpu_surface(&instance) or_return
	defer if err != nil do wgpu.surface_release(&gc.surface)

	adapter_options := wgpu.Request_Adapter_Options {
		power_preference       = properties.power_preferences,
		compatible_surface     = gc.surface.ptr,
		force_fallback_adapter = false,
	}

	adapter := wgpu.instance_request_adapter(&instance, &adapter_options, loc) or_return
	defer wgpu.adapter_release(&adapter)

	fmt.printf("Device information:\n\n")

	// Print selected adapter information
	wgpu.adapter_print_info(&adapter)

	device_descriptor := wgpu.Device_Descriptor {
		label             = adapter.properties.name,
		required_limits   = properties.required_limits,
		required_features = properties.required_features,
	}

	for f in properties.optional_features {
		if f in adapter.features {
			device_descriptor.required_features += {f}
		}
	}

	gc.properties = properties

	gc.device, gc.queue = wgpu.adapter_request_device(&adapter, &device_descriptor, loc) or_return
	defer if err != nil {
		wgpu.queue_release(&gc.queue)
		wgpu.device_release(&gc.device)
	}

	caps := wgpu.surface_get_capabilities(
		&gc.surface,
		adapter.ptr,
		context.allocator,
		loc,
	) or_return
	defer wgpu.surface_capabilities_free_members(&caps)

	size := app.get_size()

	preferred_format := wgpu.surface_get_preferred_format(&gc.surface, adapter.ptr) or_return

	gc.config = wgpu.Surface_Configuration {
		usage        = {.Render_Attachment},
		format       = preferred_format,
		width        = size.width,
		height       = size.height,
		present_mode = .Fifo,
		alpha_mode   = caps.alpha_modes[0],
	}

	wgpu.surface_configure(&gc.surface, &gc.device, &gc.config) or_return

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
	// fmt.eprintf("Uncaught WGPU error [%v]:\n\t%s...\n", type, message)

	// Handle device lost in the browser
	when core.APPLICATION_TYPE == .Wasm {
		gpu := cast(^Renderer)user_data
		if type == .Device_Lost {
			if init(gc.properties) != nil {
				// app.push_event(events.Quit_Event(true))
			}
		}
	} else {
		// app.push_event(events.Quit_Event(true))
	}
}
