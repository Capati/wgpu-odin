#+vet !unused-imports
package application

// Packages
import intr "base:intrinsics"
import "base:runtime"
import "core:log"
import "core:reflect"
import "core:strings"
import "vendor:glfw"

// Local packages
import wgpu_glfw "./../../utils/glfw"
import wgpu "./../../wgpu"

Window_Settings :: struct {
	title:         string,
	size:          Window_Size,
	min_size:      Window_Size,
	centered:      bool,
	resizable:     bool,
	borderless:    bool,
	use_dpi_scale: bool,
	fullscreen:    bool,
}

GPU_Settings :: struct {
	power_preference:              wgpu.Power_Preference,
	force_fallback_adapter:        bool,
	desired_surface_format:        wgpu.Texture_Format,
	optional_features:             wgpu.Features,
	required_features:             wgpu.Features,
	required_limits:               wgpu.Limits,
	desired_present_mode:          wgpu.Present_Mode,
	present_mode:                  wgpu.Present_Mode,
	remove_srgb_from_surface:      bool,
	desired_maximum_frame_latency: u32,
}

Settings :: struct {
	using window: Window_Settings,
	using gpu:    GPU_Settings,
}

DEFAULT_WINDOW_SETTINGS :: Window_Settings {
	title         = "Untitled",
	size          = {800, 600},
	min_size      = {1, 1},
	centered      = true,
	resizable     = true,
	borderless    = false,
	use_dpi_scale = true,
	fullscreen    = false,
}

DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY :: 2
DEFAULT_GPU_SETTINGS :: GPU_Settings {
	power_preference              = .High_Performance,
	required_limits               = wgpu.DOWNLEVEL_LIMITS,
	desired_present_mode          = .Mailbox,
	present_mode                  = .Fifo,
	desired_maximum_frame_latency = DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY,
	remove_srgb_from_surface      = true,
}

DEFAULT_SETTINGS :: Settings {
	window = DEFAULT_WINDOW_SETTINGS,
	gpu    = DEFAULT_GPU_SETTINGS,
}

Graphics_Context :: struct {
	settings: GPU_Settings,
	instance: wgpu.Instance,
	surface:  wgpu.Surface,
	adapter:  wgpu.Adapter,
	device:   wgpu.Device,
	queue:    wgpu.Queue,
	features: wgpu.Features,
	limits:   wgpu.Limits,
	caps:     wgpu.Surface_Capabilities,
	config:   wgpu.Surface_Configuration,
	is_srgb:  bool,
}

@(default_calling_convention = "c", link_prefix = "glfw")
foreign _ {
	GetMonitorWorkarea :: proc(monitor: Monitor, xpos, ypos, width, height: ^i32) ---
}

@(require_results)
create :: proc(
	$T: typeid,
	settings := DEFAULT_SETTINGS,
	loc := #caller_location,
) -> (
	app: ^T,
	ok: bool,
) where intr.type_is_specialization_of(T, Context) {
	app = new(T)
	ensure(app != nil, "Failed to allocate application")

	app.settings = settings
	app.logger = context.logger

	ensure(bool(glfw.Init()), "Failed to initialize GLFW")
	defer if !ok {
		glfw.Terminate()
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	app.monitor = glfw.GetPrimaryMonitor()
	ensure(app.monitor != nil, "Failed to get primary monitor")

	if app.settings.centered {
		// Calculate the window centered position
		xpos, ypos, width, height: i32
		GetMonitorWorkarea(app.monitor, &xpos, &ypos, &width, &height)
		window_x := xpos + (width - i32(app.settings.size.w)) / 2
		glfw.WindowHint_int(glfw.POSITION_X, window_x)
		window_y := ypos + (height - i32(app.settings.size.h)) / 2
		glfw.WindowHint_int(glfw.POSITION_Y, window_y)
	}

	glfw.WindowHint_int(glfw.CLIENT_API, glfw.NO_API)

	c_title := strings.clone_to_cstring(app.settings.title, context.temp_allocator)
	app.window = glfw.CreateWindow(
		i32(app.settings.size.w),
		i32(app.settings.size.h),
		c_title,
		nil,
		nil,
	)
	ensure(app.window != nil, "Failed to create window")
	defer if !ok {
		glfw.DestroyWindow(app.window)
	}

	event_init(&app.events) or_return

	glfw.SetWindowUserPointer(app.window, app)

	// Setup callbacks to populate event queue
	glfw.SetFramebufferSizeCallback(app.window, size_callback)
	glfw.SetWindowIconifyCallback(app.window, minimize_callback)
	glfw.SetWindowFocusCallback(app.window, focus_callback)
	glfw.SetKeyCallback(app.window, key_callback)
	glfw.SetCursorPosCallback(app.window, cursor_position_callback)
	glfw.SetMouseButtonCallback(app.window, mouse_button_callback)
	glfw.SetScrollCallback(app.window, scroll_callback)

	wgpu.set_log_level(.Warn)
	wgpu.set_log_callback(gpu_log_callback, app)

	instance_descriptor := wgpu.Instance_Descriptor {
		backends = wgpu.BACKENDS_PRIMARY,
		flags    = {.Validation},
	}

	// Force backend type config
	WGPU_BACKEND_TYPE :: #config(WGPU_BACKEND_TYPE, "")
	// Try to read WGPU_BACKEND_TYPE config to see if a backend type should be forced
	if WGPU_BACKEND_TYPE != "" {
		// Try to get the backend type from the string configuration
		backend, backend_ok := reflect.enum_from_name(wgpu.Backend_Bits, WGPU_BACKEND_TYPE)

		if backend_ok {
			instance_descriptor.backends = {backend}
			log.infof("Backend type selected with [WGPU_BACKEND_TYPE]: [%v]", backend)
		} else {
			log_loc(
				"Backend type [%v] is invalid, possible values are from [Backends] (case sensitive): \n\tVulkan,\n\tGL,\n\tMetal,\n\tDX12,\n\tDX11,\n\tBrowser_WebGPU",
				WGPU_BACKEND_TYPE,
				level = .Error,
				loc = loc,
			)
			return
		}
	}

	app.gpu.instance = wgpu.create_instance(instance_descriptor) or_return
	defer if !ok {
		wgpu.instance_release(app.gpu.instance)
	}

	app.gpu.surface = wgpu_glfw.create_surface(app.window, app.gpu.instance) or_return
	defer if !ok {
		wgpu.surface_release(app.gpu.surface)
	}

	adapter_options := wgpu.Request_Adapter_Options {
		compatible_surface     = app.gpu.surface,
		power_preference       = app.settings.power_preference,
		force_fallback_adapter = app.settings.force_fallback_adapter,
	}

	app.gpu.adapter = wgpu.instance_request_adapter(app.gpu.instance, adapter_options) or_return
	defer if !ok {
		wgpu.adapter_release(app.gpu.adapter)
	}

	adapter_info := wgpu.adapter_get_info(app.gpu.adapter) or_return
	defer wgpu.adapter_info_free_members(adapter_info)

	log.infof(
		"Selected adapter:\n%s",
		wgpu.adapter_info_string(adapter_info, context.temp_allocator),
	)

	device_descriptor := wgpu.Device_Descriptor {
		label             = adapter_info.device,
		required_limits   = app.settings.required_limits,
		optional_features = app.settings.optional_features,
		required_features = app.settings.required_features,
	}

	app.gpu.device = wgpu.adapter_request_device(app.gpu.adapter, device_descriptor) or_return
	defer if !ok {
		wgpu.device_release(app.gpu.device)
	}

	app.gpu.features = wgpu.device_features(app.gpu.device)
	app.gpu.limits = wgpu.device_limits(app.gpu.device) or_return

	app.gpu.queue = wgpu.device_get_queue(app.gpu.device)
	defer if !ok {
		wgpu.queue_release(app.gpu.queue)
	}

	app.gpu.caps = wgpu.surface_get_capabilities(app.gpu.surface, app.gpu.adapter) or_return
	defer if !ok {
		wgpu.surface_capabilities_free_members(app.gpu.caps)
	}

	preferred_format: wgpu.Texture_Format
	if app.settings.desired_surface_format != .Undefined {
		for f in app.gpu.caps.formats {
			if app.settings.desired_surface_format == f {
				preferred_format = f
				break
			}
		}
	}
	if preferred_format == .Undefined {
		preferred_format = app.gpu.caps.formats[0]
	}

	log.infof("Preferred surface format: [%v]", preferred_format)

	app.gpu.is_srgb = wgpu.texture_format_is_srgb(preferred_format)

	if app.settings.remove_srgb_from_surface && app.gpu.is_srgb {
		app.gpu.is_srgb = false
		preferred_format_non_srgb := wgpu.texture_format_remove_srgb_suffix(preferred_format)
		log.infof("SRGB removed from surface format, now using: [%v]", preferred_format_non_srgb)
		preferred_format = preferred_format_non_srgb
	}

	if app.settings.desired_maximum_frame_latency != DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY {
		log.infof(
			"Desired maximum frame latency: [%d]",
			app.settings.desired_maximum_frame_latency,
		)
	}

	present_mode := app.settings.present_mode
	// Try to set the desired present mode
	if app.settings.desired_present_mode != .Undefined {
		for p in app.gpu.caps.present_modes {
			if app.settings.desired_present_mode == p {
				present_mode = p
				break
			}
		}
	}
	if present_mode == .Undefined {
		present_mode = .Fifo
	}

	size := get_framebuffer_size(app)

	surface_format_features := wgpu.texture_format_guaranteed_format_features(
		preferred_format,
		app.gpu.features,
	)

	surface_allowed_usages := surface_format_features.allowed_usages
	// DX12 backend doesn't support this usage for surface textures
	if .Texture_Binding in surface_allowed_usages {
		surface_allowed_usages -= {.Texture_Binding}
	}

	app.gpu.config = wgpu.Surface_Configuration {
		device                        = app.gpu.device,
		usage                         = surface_allowed_usages,
		format                        = preferred_format,
		width                         = size.w,
		height                        = size.h,
		present_mode                  = present_mode,
		alpha_mode                    = .Auto,
		desired_maximum_frame_latency = app.settings.desired_maximum_frame_latency,
	}

	app.framebuffer_size = size

	wgpu.surface_configure(app.gpu.surface, app.gpu.config) or_return

	set_aspect(app, size)
	set_target_frame_time(app, DEFAULT_TARGET_FRAME_TIME)

	app.exit_key = .Escape
	app.prepared = true

	return app, true
}

gpu_log_callback :: proc "c" (level: wgpu.Log_Level, message: wgpu.String_View, userdata: rawptr) {
	if message.length == 0 {return}
	app := cast(^Application)userdata
	if app.logger.data == nil {return}
	context = runtime.default_context()
	context.logger = app.logger
	msg := wgpu.string_view_get_string(message)
	#partial switch level {
	case .Error:
		log.errorf("[wgpu] %s", msg)
	case .Warn:
		log.warnf("[wgpu] %s", msg)
	case .Debug:
		log.debugf("[wgpu] %s", msg)
	case:
		log.infof("[wgpu] [%v] %s", level, msg)
	}
}
