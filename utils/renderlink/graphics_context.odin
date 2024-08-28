package renderlink

// STD Library
import "base:runtime"
import "core:log"
import "core:reflect"

// Local packages
import wgpu "./../../wrapper"

Graphics_Context :: struct {
	settings    : Graphics_Context_Settings,
	instance    : wgpu.Instance,
	surface     : wgpu.Surface,
	adapter     : wgpu.Adapter,
	device      : wgpu.Device,
	queue       : wgpu.Queue,
	features    : wgpu.Device_Features,
	limits      : wgpu.Limits,
	config      : wgpu.Surface_Configuration,
	is_srgb     : bool,
	render_pass : wgpu.Render_Pass,
	encoder     : wgpu.Command_Encoder,
}

Graphics_Context_Settings :: struct {
	power_preference              : wgpu.Power_Preference,
	force_fallback_adapter        : bool,
	optional_features             : wgpu.Features,
	required_features             : wgpu.Features,
	required_limits               : wgpu.Limits,
	dx12_shader_compiler          : wgpu.Dx12_Compiler,
	present_mode                  : wgpu.Present_Mode,
	remove_srgb_from_surface      : bool,
	desired_maximum_frame_latency : u32,
}

DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY: u32 : 2

DEFAULT_GRAPHICS_CONTEXT_SETTINGS :: Graphics_Context_Settings {
	power_preference              = .High_Performance,
	required_limits               = wgpu.DOWNLEVEL_LIMITS,
	present_mode                  = .Fifo,
	desired_maximum_frame_latency = DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY,
}

gpu_init :: proc(
	gpu: ^Graphics_Context,
	settings: ^Graphics_Context_Settings,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	assert(gpu != nil, "IInvalid 'Graphics_Context'", loc)

	log.info("Initializing graphics context...")

	instance_desc := wgpu.Instance_Descriptor {
		backends             = wgpu.Instance_Backend_Primary,
		dx12_shader_compiler = settings.dx12_shader_compiler,
	}

	when wgpu.LOG_ENABLED {
		instance_desc.flags = { .Validation }
		wgpu.set_log_level(.Error)
		wgpu.set_log_callback(gpu_log_callback, nil)
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
			return
		}
	}

	gpu.instance = wgpu.create_instance(instance_desc) or_return
	defer if !ok do wgpu.instance_release(gpu.instance)

	compatible_surface: wgpu.Surface

	when WINDOW_PACKAGE {
		gpu.surface = _window_create_wgpu_surface(gpu.instance) or_return
		compatible_surface = gpu.surface
		defer if !ok do wgpu.surface_release(gpu.surface)
	}

	adapter_options := wgpu.Request_Adapter_Options {
		power_preference       = settings.power_preference,
		compatible_surface     = compatible_surface,
		force_fallback_adapter = settings.force_fallback_adapter,
	}

	gpu.adapter = wgpu.instance_request_adapter(gpu.instance, adapter_options) or_return
	defer if !ok do wgpu.adapter_release(gpu.adapter)

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	ta := context.temp_allocator

	when ODIN_DEBUG {
		log.infof("Device information:\n%s", wgpu.adapter_info_string(gpu.adapter, ta))
	}

	if settings.required_limits == {} {
		settings.required_limits = wgpu.DOWNLEVEL_LIMITS
		log.warn("Required limits is empty, defaulting to [DOWNLEVEL_LIMITS]")
	}

	adapter_features := wgpu.adapter_get_features(gpu.adapter)

	for f in settings.optional_features {
		if f in adapter_features {
			settings.required_features += {f}
		} else {
			log.warnf("Optional feature unavailable: [%v], ignoring...", f)
		}
	}

	adapter_info := wgpu.adapter_get_info(gpu.adapter) or_return
	defer wgpu.adapter_info_free_members(adapter_info)

	device_descriptor := wgpu.Device_Descriptor {
		label             = adapter_info.description,
		required_limits   = settings.required_limits,
		required_features = settings.required_features,
	}


	gpu.device = wgpu.adapter_request_device(gpu.adapter, device_descriptor) or_return
	defer if !ok do wgpu.device_release(gpu.device)

	gpu.features = wgpu.device_get_features(gpu.device)
	gpu.limits = wgpu.device_get_limits(gpu.device) or_return

	gpu.queue = wgpu.device_get_queue(gpu.device)
	defer if !ok do wgpu.queue_release(gpu.queue)

	caps := wgpu.surface_get_capabilities(gpu.surface, gpu.adapter, ta) or_return
	// defer wgpu.surface_capabilities_free_members(caps)

	preferred_format := caps.formats[0]

	gpu.is_srgb = wgpu.texture_format_is_srgb(preferred_format)

	log.infof("Preferred surface format: [%v]", preferred_format)

	if settings.remove_srgb_from_surface && gpu.is_srgb {
		gpu.is_srgb = false
		preferred_format_non_srgb := wgpu.texture_format_remove_srgb_suffix(preferred_format)
		log.warnf("SRGB removed from surface format, now using: [%v]", preferred_format_non_srgb)
		preferred_format = preferred_format_non_srgb
	}

	if settings.desired_maximum_frame_latency != DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY {
		log.infof("Desired maximum frame latency: [%d]", settings.desired_maximum_frame_latency)
	}

	size := _window_get_size()

	gpu.config = wgpu.Surface_Configuration {
		usage                         = {.Render_Attachment},
		format                        = preferred_format,
		width                         = u32(size.width),
		height                        = u32(size.height),
		present_mode                  = settings.present_mode,
		alpha_mode                    = caps.alpha_modes[0],
		desired_maximum_frame_latency = settings.desired_maximum_frame_latency,
	}

	wgpu.surface_configure(gpu.surface, gpu.device, gpu.config) or_return

	return true
}

gpu_destroy :: proc(gpu: ^Graphics_Context) {
	wgpu.queue_release(gpu.queue)
	wgpu.device_release(gpu.device)
	wgpu.adapter_release(gpu.adapter)
	wgpu.surface_release(gpu.surface)
	wgpu.instance_release(gpu.instance)
}

gpu_log_callback :: proc "c" (level: wgpu.Log_Level, message: cstring, user_data: rawptr) {
	context = runtime.default_context()
	context.logger = g_logger

	#partial switch level {
	case .Error:
		log.error(message)
	}
}
