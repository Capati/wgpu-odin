#+vet !unused-imports
package application

// Core
import "base:runtime"
import "core:log"
import intr "base:intrinsics"

// Libs
import wgpu "../../"

App_Init_Callback :: #type proc(app: ^Application) -> bool

App_Step_Callback :: #type proc(app: ^Application, dt: f32) -> bool

App_Event_Callback :: #type proc(app: ^Application, event: Event) -> bool

App_Quit_Callback :: #type proc(app: ^Application)

Settings :: struct {
	using window: Window_Settings,
	using gpu:    GPU_Settings,
}

SETTINGS_DEFAULT :: Settings {
	window = WINDOW_SETTINGS_DEFAULT,
	gpu    = GPU_SETTINGS_DEFAULT,
}

Application_Callbacks :: struct {
	init:  App_Init_Callback,
	step:  App_Step_Callback,
	event: App_Event_Callback,
	quit:  App_Quit_Callback,
}

Application :: struct {
	/* Initialization */
	custom_context: runtime.Context,
	allocator:      runtime.Allocator,
	window:         Window,
	settings:       Settings,
	gpu:            ^GPU_Context,

	// Callbacks
	callbacks:      Application_Callbacks,

	// State
	title_buf:      String_Buffer,
	timer:          Timer,
	keyboard:       Keyboard_State,
	mouse:          Mouse_State,
	exit_key:       Key,
	running:        bool,
	minimized:      bool,
	prepared:       bool,
}

@(private="file")
package_ctx: Application
@(private)
app_context := &package_ctx

/*
Opens a window and initializes the application context.

Inputs:
- `$T` - The application type to create. Must be a subtype of the base
  `Application` struct (e.g., `#subtype app: Application`).
- `mode` - Video mode configuration (resolution, fullscreen, etc.)
- `window_title` - Title displayed in the window's title bar
- `callbacks` - Application lifecycle callbacks (init, step, event and quit)
- `settings` - Optional window and GPU configuration settings (defaults to SETTINGS_DEFAULT)
- `allocator` - Memory allocator to use (defaults to context.allocator)
*/
init :: proc(
	$T: typeid,
	mode: Video_Mode,
	window_title: string,
	callbacks: Application_Callbacks,
	settings := SETTINGS_DEFAULT,
	allocator := context.allocator,
	loc := #caller_location,
) where intr.type_is_subtype_of(T, Application) {
	// Allocate the custom type T with proper size
	app_context = cast(^Application)new(T, allocator)
	ensure(app_context != nil, "Failed to allocate the application context", loc)
	app := app_context

	// Initialize core application state
	app.custom_context = context
	app.allocator = allocator
	app.settings = settings
	app.callbacks = callbacks

	// Create window
	app.window = window_create(mode, window_title, settings.window, allocator, loc)

	// Allocate and initialize GPU context
	app.gpu = new(GPU_Context, allocator)
	ensure(app.gpu != nil, "Failed to allocate GPU_Context", loc)

	app.gpu.custom_context = context
	app.gpu.allocator = allocator
	app.gpu.settings = settings
	app.gpu.window = app.window

	when ODIN_DEBUG && ODIN_OS != .JS {
		app.exit_key = .Escape

		// Setup WGPU logging (debug builds only)
		_wgpu_log_callback :: proc "c" (level: wgpu.LogLevel, message: string, userdata: rawptr) {
			gpu := cast(^GPU_Context)userdata
			context = gpu.custom_context
			#partial switch level {
			case .Error:
				log.errorf("[WGPU] %s", message)
			case .Warn:
				log.warnf("[WGPU] %s", message)
			case .Debug:
				log.debugf("[WGPU] %s", message)
			case:
				log.infof("[WGPU] [%v] %s", level, message)
			}
		}

		wgpu.SetLogLevel(.Warn)
		wgpu.SetLogCallback(_wgpu_log_callback, app.gpu)
	}

	// Create WGPU instance
	instance_descriptor: wgpu.InstanceDescriptor
	when ODIN_OS != .JS {
		instance_descriptor.backends = wgpu.BACKENDS_PRIMARY
		when ODIN_DEBUG {
			// instance_descriptor.flags = { .Validation }
		}
	}

	app.gpu.instance = wgpu.CreateInstance(instance_descriptor)
	ensure(app.gpu.instance != nil, "Failed to create GPU instance")

	// Create surface from window
	app.gpu.surface = window_get_surface(app.window, app.gpu.instance)

	// Request adapter (async callback chain starts here)
	adapter_options := wgpu.RequestAdapterOptions {
		compatibleSurface    = app.gpu.surface,
		powerPreference      = app.gpu.settings.power_preference,
		forceFallbackAdapter = app.gpu.settings.force_fallback_adapter,
	}

	wgpu.InstanceRequestAdapter(
		app.gpu.instance, adapter_options, { callback = on_adapter })

	// Adapter callback - first step in async initialization chain
	on_adapter :: proc "c" (
		status: wgpu.RequestAdapterStatus,
		adapter: wgpu.Adapter,
		message: string,
		userdata1: rawptr,
		userdata2: rawptr,
	) {
		app := app_context
		context = app.custom_context

		// Validate adapter request
		if status != .Success || adapter == nil {
			log.panicf("Adapter request failed: [%v] %s", status, message)
		}

		gpu := app.gpu
		gpu.adapter = adapter

		when ODIN_OS != .JS {
			runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
			ta := context.temp_allocator

			adapter_info, info_status := wgpu.AdapterGetInfo(gpu.adapter)
			if info_status != .Success {
				log.panicf("Failed to get adapter info: %v", info_status)
			}
			defer wgpu.AdapterInfoFreeMembers(adapter_info)

			log.infof("Selected adapter:\n%s", wgpu.AdapterInfoString(adapter_info, ta))
		}

		// Request device with specified requirements
		device_descriptor := wgpu.DeviceDescriptor {
			requiredLimits   = gpu.settings.required_limits,
			optionalFeatures = gpu.settings.optional_features,
			requiredFeatures = gpu.settings.required_features,
		}

		wgpu.AdapterRequestDevice(gpu.adapter, device_descriptor, { callback = on_device })
	}

	// Device callback - final step in async initialization chain
	on_device :: proc "c" (
		status: wgpu.RequestDeviceStatus,
		device: wgpu.Device,
		message: string,
		userdata1: rawptr,
		userdata2: rawptr,
	) {
		app := app_context
		context = app.custom_context

		// Validate device request
		if status != .Success || device == nil {
			log.panicf("Device request failed: [%v] %s", status, message)
		}

		gpu := app.gpu
		gpu.device = device

		// Initialize device resources
		gpu.queue = wgpu.DeviceGetQueue(gpu.device)
		gpu.features = wgpu.DeviceFeatures(gpu.device)
		gpu.limits = wgpu.DeviceLimits(gpu.device)

		// Get surface capabilities
		caps, caps_ok := wgpu.SurfaceGetCapabilities(gpu.surface, gpu.adapter)
		assert(caps_ok, "Failed to get surface capabilities")
		gpu.caps = caps

		// Determine best surface format
		preferred_format: wgpu.TextureFormat
		if gpu.settings.desired_surface_format != .Undefined {
			// Check if desired format is supported
			for format in gpu.caps.formats {
				if gpu.settings.desired_surface_format == format {
					preferred_format = format
					break
				}
			}
		}

		// Fallback to first available format if desired format not found
		if preferred_format == .Undefined {
			preferred_format = gpu.caps.formats[0]
		}

		log.debugf("Preferred surface format: \x1b[32m%v\x1b[0m", preferred_format)

		// Handle sRGB configuration
		gpu.is_srgb = wgpu.TextureFormatIsSrgb(preferred_format)
		if gpu.settings.remove_srgb_from_surface && gpu.is_srgb {
			gpu.is_srgb = false
			preferred_format_non_srgb := wgpu.TextureFormatRemoveSrgbSuffix(preferred_format)
			log.debugf(
				"sRGB removed from surface format, now using: \x1b[32m%v\x1b[0m",
				preferred_format_non_srgb,
			)
			preferred_format = preferred_format_non_srgb
		}

		// Determine present mode with validation
		present_mode := gpu.settings.desired_present_mode
		if present_mode == .Undefined {
			present_mode = .Fifo  // Safe default
		} else if present_mode != .Fifo {
			// Validate that desired present mode is supported
			mode_supported := false
			for mode in gpu.caps.presentModes {
				if present_mode == mode {
					mode_supported = true
					break
				}
			}

			if !mode_supported {
				log.warnf(
					"Desired present mode %v not supported, falling back to Fifo", present_mode)
				present_mode = .Fifo
			}
		}

		log.debugf("Selected present mode: \x1b[32m%v\x1b[0m", present_mode)

		// Get current window size
		gpu.size = window_get_size(gpu.window)

		// Configure surface usage based on format capabilities
		surface_format_features :=
			wgpu.TextureFormatGuaranteedFormatFeatures(preferred_format, gpu.features)

		surface_allowed_usages := surface_format_features.allowedUsages
		// DX12 backend limitation: remove TextureBinding usage for surface textures
		if .TextureBinding in surface_allowed_usages {
			surface_allowed_usages -= { .TextureBinding }
		}

		// Create final surface configuration
		gpu.config = wgpu.SurfaceConfiguration {
			device      = gpu.device,
			usage       = surface_allowed_usages,
			format      = preferred_format,
			width       = gpu.size.x,
			height      = gpu.size.y,
			presentMode = present_mode,
			alphaMode   = .Auto,
		}

		wgpu.SurfaceConfigure(gpu.surface, gpu.config)

		window_add_resize_callback(app.window, { gpu_resize_surface, app.gpu })

		// Initialization complete - start main application loop
		run(app)
	}
}

destroy :: proc(app := app_context) {
	assert(app != nil, "Invalid application")
	context = app.custom_context

	gpu_destroy(app.gpu)
	window_destroy(app.window)

	free(app)
	app_context = nil
}

set_context :: proc "contextless" (app := app_context) {
	app_context = app
}

set_callbacks :: proc "contextless" (callbacks: Application_Callbacks, app := app_context) {
	app.callbacks = callbacks
}

@(require_results)
get_time :: proc(app := app_context) -> f32 {
	return f32(timer_get_time(&app.timer))
}

@(require_results)
get_delta_time :: proc(app := app_context) -> f32 {
	return f32(timer_get_delta(&app.timer))
}

dispatch_event :: proc "contextless" (event: Event, app := app_context) {
	context = app.custom_context

	if app.callbacks.event != nil {
		if !app.callbacks.event(app, event) {
			app.running = false
		}
	}

	when ODIN_DEBUG && ODIN_OS != .JS {
		#partial switch &ev in event {
		case Key_Pressed_Event:
			if app.exit_key != .Unknown && app.exit_key == ev.key {
				app.running = false
				dispatch_event(Quit_Event{}, app)
			}
		}
	}
}
