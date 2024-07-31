package application

// STD Library
import "base:runtime"
import "core:log"
import "core:reflect"

// Vendor Package
import wgpu "./../../wrapper"

_ :: runtime

Graphics_Context :: struct {
	settings:    Graphics_Context_Settings,
	instance:    wgpu.Instance,
	surface:     wgpu.Surface,
	adapter:     wgpu.Adapter,
	device:      wgpu.Device,
	queue:       wgpu.Queue,
	config:      wgpu.Surface_Configuration,
	is_srgb:     bool,
	render_pass: wgpu.Render_Pass,
	encoder:     wgpu.Command_Encoder,
}

Graphics_Context_Error :: enum {
	None,
}

Graphics_Context_Settings :: struct {
	power_preference:              wgpu.Power_Preference,
	force_fallback_adapter:        bool,
	optional_features:             wgpu.Features,
	required_features:             wgpu.Features,
	required_limits:               wgpu.Limits,
	present_mode:                  wgpu.Present_Mode,
	remove_srgb_from_surface:      bool,
	desired_maximum_frame_latency: u32,
}

DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY: u32 : 2

DEFAULT_GRAPHICS_CONTEXT_SETTINGS :: Graphics_Context_Settings {
	power_preference              = .High_Performance,
	required_limits               = wgpu.DOWNLEVEL_LIMITS,
	present_mode                  = .Fifo,
	desired_maximum_frame_latency = DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY,
}

gpu_init :: proc(
	settings: ^Graphics_Context_Settings,
	allocator := context.allocator,
) -> (
	out: ^Graphics_Context,
	err: Error,
) {
	log.info("Initializing graphics context...")

	out = new(Graphics_Context, allocator)
	defer if err != nil do free(out, allocator)

	instance_desc := wgpu.Instance_Descriptor {
		backends = wgpu.Instance_Backend_Primary,
	}

	// Force backend type config
	WGPU_BACKEND_TYPE :: #config(WGPU_BACKEND_TYPE, "")

	// Try to read WGPU_BACKEND_TYPE config to see if a backend type should be forced
	if WGPU_BACKEND_TYPE != "" {
		// Try to get the backend type from the string configuration
		backend, backend_ok := reflect.enum_from_name(wgpu.Instance_Backend, WGPU_BACKEND_TYPE)

		if backend_ok {
			instance_desc.backends = {backend}
			log.infof("Backend type selected with [WGPU_BACKEND_TYPE]: [%v]", backend)
		} else {
			log.errorf(
				"Backend type [%v] is invalid, possible values are from [Instance_Backend] (case sensitive): \n\tVulkan,\n\tGL,\n\tMetal,\n\tDX12,\n\tDX11,\n\tBrowser_WebGPU",
				WGPU_BACKEND_TYPE,
			)

			err = wgpu.Error_Type.Validation
			return
		}
	}

	out.instance = wgpu.create_instance(instance_desc) or_return
	defer if err != nil do wgpu.instance_release(out.instance)

	compatible_surface: wgpu.Raw_Surface = nil

	when WINDOW_PACKAGE {
		out.surface = _window_create_wgpu_surface(out.instance) or_return
		compatible_surface = out.surface.ptr
		defer if err != nil do wgpu.surface_release(out.surface)
	}

	adapter_options := wgpu.Request_Adapter_Options {
		power_preference       = settings.power_preference,
		compatible_surface     = compatible_surface,
		force_fallback_adapter = settings.force_fallback_adapter,
	}

	out.adapter = wgpu.instance_request_adapter(out.instance, adapter_options) or_return
	defer if err != nil do wgpu.adapter_release(out.adapter)

	when ODIN_DEBUG {
		runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
		log.infof(
			"Device information:\n%s",
			wgpu.adapter_info_string(out.adapter, context.temp_allocator),
		)
	}

	if settings.required_limits == {} {
		settings.required_limits = wgpu.DOWNLEVEL_LIMITS
		log.warn("Required limits is empty, defaulting to [DOWNLEVEL_LIMITS]")
	}

	for f in settings.optional_features {
		if f in out.adapter.features {
			settings.required_features += {f}
		} else {
			log.warnf("Optional feature unavailable: [%v], ignoring...", f)
		}
	}

	device_descriptor := wgpu.Device_Descriptor {
		label             = out.adapter.info.name,
		required_limits   = settings.required_limits,
		required_features = settings.required_features,
	}

	out.device, out.queue = wgpu.adapter_request_device(out.adapter, device_descriptor) or_return
	defer if err != nil do wgpu.device_release(out.device)

	caps := wgpu.surface_get_capabilities(
		out.surface,
		out.adapter.ptr,
		context.allocator,
	) or_return
	defer wgpu.surface_capabilities_free_members(caps)

	preferred_format := caps.formats[0]

	out.is_srgb = wgpu.texture_format_is_srgb(preferred_format)

	log.infof("Preferred surface format: [%v]", preferred_format)

	if settings.remove_srgb_from_surface && out.is_srgb {
		out.is_srgb = false
		preferred_format_non_srgb := wgpu.texture_format_remove_srgb_suffix(preferred_format)
		log.warnf("SRGB removed from surface format, now using: [%v]", preferred_format_non_srgb)
		preferred_format = preferred_format_non_srgb
	}

	if settings.desired_maximum_frame_latency != DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY {
		log.infof("Desired maximum frame latency: [%d]", settings.desired_maximum_frame_latency)
	}

	size := _window_get_size()

	out.config = wgpu.Surface_Configuration {
		usage                         = {.Render_Attachment},
		format                        = preferred_format,
		width                         = u32(size.width),
		height                        = u32(size.height),
		present_mode                  = settings.present_mode,
		alpha_mode                    = caps.alpha_modes[0],
		desired_maximum_frame_latency = settings.desired_maximum_frame_latency,
	}

	wgpu.surface_configure(&out.surface, out.device, out.config) or_return

	return
}

gpu_destroy :: proc(gpu: ^Graphics_Context) {
	wgpu.queue_release(gpu.queue)
	wgpu.device_release(gpu.device)
	wgpu.adapter_release(gpu.adapter)
	wgpu.surface_release(gpu.surface)
	wgpu.instance_release(gpu.instance)
}
