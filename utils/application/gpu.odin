package application

// Core
import "base:runtime"
import "core:log"
import "core:reflect"
import "core:time"

// Local packages
import wgpu "../../"

GPU_Settings :: struct {
	power_preference:         wgpu.PowerPreference,
	force_fallback_adapter:   bool,
	desired_surface_format:   wgpu.TextureFormat,
	optional_features:        wgpu.Features,
	required_features:        wgpu.Features,
	required_limits:          wgpu.Limits,
	desired_present_mode:     wgpu.PresentMode,
	remove_srgb_from_surface: bool,
}

GPU_SETTINGS_DEFAULT :: GPU_Settings {
	power_preference         = .HighPerformance,
	required_limits          = wgpu.LIMITS_DOWNLEVEL,
	desired_present_mode     = .Fifo,
	remove_srgb_from_surface = true,
}

GPU_Context :: struct {
	/* Initialization */
	custom_context: runtime.Context,
	allocator:      runtime.Allocator,
	window:         ^Window,

	/* GPU Context */
	settings:       GPU_Settings,
	instance:       wgpu.Instance,
	surface:        wgpu.Surface,
	adapter:        wgpu.Adapter,
	device:         wgpu.Device,
	queue:          wgpu.Queue,
	features:       wgpu.Features,
	limits:         wgpu.Limits,
	caps:           wgpu.SurfaceCapabilities,
	config:         wgpu.SurfaceConfiguration,

	/* Settings */
	is_srgb:        bool,
	size:           Vec2u,
}

@(require_results)
gpu_create :: proc(
	window: ^Window,
	settings := GPU_SETTINGS_DEFAULT,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	gpu: ^GPU_Context,
) {
	assert(window != nil, "Invalid window", loc)
	gpu = new(GPU_Context, allocator)
	ensure(gpu != nil, "Failed to allocate GPU_Context", loc)
	gpu_init(gpu, window, settings, allocator, loc)
	return
}

gpu_init :: proc(
	gpu: ^GPU_Context,
	window: ^Window,
	settings := GPU_SETTINGS_DEFAULT,
	allocator := context.allocator,
	loc := #caller_location,
) {
	assert(window != nil, "Invalid window", loc)

	gpu.custom_context  = context
	gpu.allocator = allocator
	gpu.settings = settings
	gpu.window = window

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	ta := context.temp_allocator

	when ODIN_DEBUG {
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
		wgpu.SetLogCallback(_wgpu_log_callback, gpu)
	}

	instance_descriptor := wgpu.InstanceDescriptor {
		backends = wgpu.BACKENDS_PRIMARY,
	}

	when ODIN_DEBUG {
		instance_descriptor.flags = { .Validation }
	}

	// Force backend type config
	WGPU_BACKEND_TYPE :: #config(WGPU_BACKEND_TYPE, "")
	// Try to read WGPU_BACKEND_TYPE config to see if a backend type should be forced
	if WGPU_BACKEND_TYPE != "" {
		// Try to get the backend type from the string configuration
		backend, backend_ok := reflect.enum_from_name(wgpu.InstanceBackend, WGPU_BACKEND_TYPE)

		if backend_ok {
			instance_descriptor.backends = {backend}
			log.warnf("Backend type selected with [WGPU_BACKEND_TYPE]: \x1b[33m%v\x1b[0m", backend)
		} else {
			log_loc(
				"Backend type \x1b[31m%v\x1b[0m is invalid, " +
				"possible values are from [Backends] (case sensitive): " +
				"\n\tVulkan,\n\tGL,\n\tMetal,\n\tDX12,\n\tDX11,\n\tBrowser_WebGPU",
				WGPU_BACKEND_TYPE,
				level = .Error,
				loc = loc,
			)
			return
		}
	}

	gpu.instance = wgpu.CreateInstance(instance_descriptor)

	gpu.surface = window_get_surface(window, gpu.instance)

	adapter_options := wgpu.RequestAdapterOptions {
		compatibleSurface    = gpu.surface,
		powerPreference      = gpu.settings.power_preference,
		forceFallbackAdapter = gpu.settings.force_fallback_adapter,
	}

	adapter_res := wgpu.InstanceRequestAdapter(gpu.instance, adapter_options)
	if (adapter_res.status != .Success) {
		log.panicf(
			"Failed to request the selected adapter [%v]: %s",
			adapter_res.status,
			adapter_res.message,
			location = loc,
		)
	}
	gpu.adapter = adapter_res.adapter

	adapter_info, info_status := wgpu.AdapterGetInfo(gpu.adapter)
	if info_status != .Success {
		log.panicf(
			"Failed to get adapter info for the selected adapter: %v",
			info_status,
			location = loc,
		)
	}
	defer wgpu.AdapterInfoFreeMembers(adapter_info)

	log.infof("Selected adapter:\n%s", wgpu.AdapterInfoString(adapter_info, ta))

	device_descriptor := wgpu.DeviceDescriptor {
		label            = adapter_info.device,
		requiredLimits   = gpu.settings.required_limits,
		optionalFeatures = gpu.settings.optional_features,
		requiredFeatures = gpu.settings.required_features,
	}

	device_res := wgpu.AdapterRequestDevice(gpu.adapter, device_descriptor)
	if (device_res.status != .Success) {
		log.panicf(
			"Failed to request the device [%v]: %s",
			device_res.status,
			device_res.message,
			location = loc,
		)
	}
	gpu.device = device_res.device

	gpu.queue = wgpu.DeviceGetQueue(gpu.device)

	gpu.features = wgpu.DeviceFeatures(gpu.device)
	gpu.limits = wgpu.DeviceLimits(gpu.device)

	caps, caps_ok := wgpu.SurfaceGetCapabilities(gpu.surface, gpu.adapter)
	assert(caps_ok, "Failed to get surface capabilities", loc)
	gpu.caps = caps

	preferred_format: wgpu.TextureFormat
	if gpu.settings.desired_surface_format != .Undefined {
		for f in gpu.caps.formats {
			if gpu.settings.desired_surface_format == f {
				preferred_format = f
				break
			}
		}
	}
	if preferred_format == .Undefined {
		preferred_format = gpu.caps.formats[0]
	}

	log.debugf("Preferred surface format: \x1b[32m%v\x1b[0m", preferred_format)

	gpu.is_srgb = wgpu.TextureFormatIsSrgb(preferred_format)

	if gpu.settings.remove_srgb_from_surface && gpu.is_srgb {
		gpu.is_srgb = false
		preferred_format_non_srgb := wgpu.TextureFormatRemoveSrgbSuffix(preferred_format)
		log.debugf(
			"SRGB removed from surface format, now using: \x1b[32m%v\x1b[0m",
			preferred_format_non_srgb,
		)
		preferred_format = preferred_format_non_srgb
	}

	present_mode := gpu.settings.desired_present_mode
	if present_mode == .Undefined {
		present_mode = .Fifo
	}
	// Try to set the desired present mode
	if present_mode != .Fifo {
		for p in gpu.caps.presentModes {
			if present_mode == p {
				break
			}
		}
	}

	log.debugf("Selected present mode: \x1b[32m%v\x1b[0m", present_mode)

	gpu.size = window_get_size(gpu.window)

	surface_format_features :=
		wgpu.TextureFormatGuaranteedFormatFeatures(preferred_format, gpu.features)

	surface_allowed_usages := surface_format_features.allowedUsages
	// DX12 backend doesn't support this usage for surface textures
	if .TextureBinding in surface_allowed_usages {
		surface_allowed_usages -= { .TextureBinding }
	}

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

	window_add_resize_callback(window, { gpu_resize_surface, gpu })
}

gpu_destroy :: proc(self: ^GPU_Context) {
	wgpu.SurfaceCapabilitiesFreeMembers(self.caps)

	wgpu.Release(self.queue)
	wgpu.Release(self.device)
	wgpu.Release(self.adapter)
	wgpu.Release(self.surface)

	when ODIN_DEBUG {
		wgpu.CheckForMemoryLeaks(self.instance)
	}

	wgpu.Release(self.instance)

	free(self)
}

Frame_Texture :: struct {
	using _texture: wgpu.SurfaceTexture,
	skip:           bool,
	view:           wgpu.TextureView,
}

@(require_results)
gpu_get_current_frame :: proc(
	gpu: ^GPU_Context,
	loc := #caller_location,
) -> (
	frame: Frame_Texture,
) {
	if size := window_get_size(gpu.window); size != gpu.size {
		gpu_resize_surface(gpu.window, size, gpu)
	}

	frame._texture = wgpu.SurfaceGetCurrentTexture(gpu.surface)

	switch frame.status {
	case .SuccessOptimal, .SuccessSuboptimal:
		// All good, could handle suboptimal here
		frame.view = wgpu.TextureCreateView(frame.texture)

	case .Timeout, .Outdated, .Lost:
		// Skip this frame, and re-configure surface.
		gpu_release_current_frame(&frame)
		gpu_resize_surface(gpu.window, window_get_size(gpu.window), gpu)
		frame.skip = true
		return

	case .OutOfMemory, .DeviceLost, .Error:
		log.panicf("Failed to acquire surface texture: %v", frame.status, location = loc)
	}

	assert(frame.texture != nil, "Invalid surface texture", loc)

	return
}

gpu_release_current_frame :: proc(self: ^Frame_Texture) {
	wgpu.ReleaseSafe(&self.view)
	wgpu.ReleaseSafe(&self.texture)
}

gpu_resize_surface :: proc(window: ^Window, size: Vec2u, userdata: rawptr) {
	gpu := cast(^GPU_Context)userdata

	// Wait for the device to finish all operations
	wgpu.DevicePoll(gpu.device, true)

	gpu.config.width = u32(size.x)
	gpu.config.height = u32(size.y)

	// Reconfigure the surface
	wgpu.SurfaceUnconfigure(gpu.surface)
	wgpu.SurfaceConfigure(gpu.surface, gpu.config)

	gpu.size = size
}

Depth_Stencil_State_Descriptor :: struct {
	format:            wgpu.TextureFormat,
	depth_write_enabled: bool,
}

gpu_create_depth_stencil_state :: proc(
	app: ^Application,
	desc: Depth_Stencil_State_Descriptor = { DEFAULT_DEPTH_FORMAT, true },
) -> wgpu.DepthStencilState {
	stencil_state_face_desc := wgpu.StencilFaceState {
		compare     = .Always,
		failOp      = .Keep,
		depthFailOp = .Keep,
		passOp      = .Keep,
	}

	format := desc.format if desc.format != .Undefined else DEFAULT_DEPTH_FORMAT

	return {
		format = format,
		depthWriteEnabled = desc.depth_write_enabled,
		stencil = {
			front     = stencil_state_face_desc,
			back      = stencil_state_face_desc,
			readMask  = max(u32),
			writeMask = max(u32),
		},
	}
}

Depth_Stencil_Texture_Creation_Options :: struct {
	format:       wgpu.TextureFormat,
	sample_count: u32,
}

Depth_Stencil_Texture :: struct {
	format:     wgpu.TextureFormat,
	texture:    wgpu.Texture,
	view:       wgpu.TextureView,
	descriptor: wgpu.RenderPassDepthStencilAttachment,
}

@(require_results)
gpu_create_depth_stencil_texture :: proc(
	gpu: ^GPU_Context,
	options: Depth_Stencil_Texture_Creation_Options = {},
) -> (
	ret: Depth_Stencil_Texture,
) {
	ret.format = options.format if options.format != .Undefined else DEFAULT_DEPTH_FORMAT

	sample_count :=  max(1, options.sample_count)

	texture_descriptor := wgpu.TextureDescriptor {
		usage = { .RenderAttachment, .CopyDst },
		format = ret.format,
		dimension = ._2D,
		mipLevelCount = 1,
		sampleCount = sample_count,
		size = {
			width = gpu.config.width,
			height = gpu.config.height,
			depthOrArrayLayers = 1,
		},
	}

	ret.texture = wgpu.DeviceCreateTexture(gpu.device, texture_descriptor)

	texture_view_descriptor := wgpu.TextureViewDescriptor {
		format          = texture_descriptor.format,
		dimension       = ._2D,
		baseMipLevel    = 0,
		mipLevelCount   = 1,
		baseArrayLayer  = 0,
		arrayLayerCount = 1,
		aspect          = .All,
	}

	ret.view = wgpu.TextureCreateView(
		ret.texture,
		texture_view_descriptor,
	)

	ret.descriptor = {
		view = ret.view,
		depthOps = wgpu.RenderPassDepthOperations{
			load = .Clear,
			store = .Store,
			clearValue = 1.0,
		},
	}

	return
}

gpu_release_depth_stencil_texture :: proc(self: Depth_Stencil_Texture) {
	wgpu.Release(self.texture)
	wgpu.Release(self.view)
}

gpu_pace_frame :: proc(self: ^GPU_Context, t: ^Timer) {
	// Only do frame pacing for fifo mode
    if self.config.presentMode != .Fifo {
        return  // No pacing - run as fast as possible
    }

    sleep_time_ms := t.target_frame_time_ms - timer_get_average_work_ms(t) - t.margin_ms

    if sleep_time_ms > 0.0 {
        sleep_duration := time.Duration(sleep_time_ms * f64(time.Millisecond))
        time.accurate_sleep(sleep_duration)
    }

    // Busy wait the remaining time for precision
    busy_start := time.tick_now()
    remaining_ms := t.margin_ms

    for remaining_ms > 0.0 {
        now := time.tick_now()
        elapsed_duration := time.tick_diff(busy_start, now)
        elapsed_ms := time.duration_milliseconds(elapsed_duration)
        remaining_ms = t.margin_ms - elapsed_ms
    }
}
