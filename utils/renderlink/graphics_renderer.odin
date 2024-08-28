package renderlink

// STD Library
import "core:log"
import "core:mem"
import "core:time"

// Vendor
import wgpu "./../../wrapper"

Framebuffer :: struct {
	texture      : wgpu.Texture,
	view         : wgpu.Texture_View,
	format       : wgpu.Texture_Format,
	sample_count : u32,
	is_depth     : bool,
}

Frame_Texture :: struct {
	using _texture   :   wgpu.Surface_Texture,
	view             : wgpu.Texture_View,
	texture_released : bool,
	view_released    : bool,
}

Renderer_Settings :: struct {
	gpu                     : Graphics_Context_Settings,
	color_attachments_count : u32,
	sample_count            : u32,
	use_depth_stencil       : bool,
	depth_format            : wgpu.Texture_Format,
	gamma_correct           : bool,
}

DEFAULT_RENDERER_SETTINGS :: Renderer_Settings {
	gpu                     = DEFAULT_GRAPHICS_CONTEXT_SETTINGS,
	color_attachments_count = MIN_COLOR_ATTACHMENTS,
	sample_count            = DEFAULT_SAMPLE_COUNT,
	use_depth_stencil       = false,
	depth_format            = DEFAULT_DEPTH_FORMAT,
}

Renderer :: struct {
	gpu                      : Graphics_Context,
	clear_color              : wgpu.Color,
	render_pass_desc         : wgpu.Render_Pass_Descriptor,
	msaa_framebuffer         : Framebuffer,
	depth_framebuffer        : Framebuffer,
	depth_stencil_attachment : wgpu.Render_Pass_Depth_Stencil_Attachment,
	current_frame            : Frame_Texture,
	skip_frame               : bool,
	settings                 : Renderer_Settings,
}

Renderer_Error :: enum {
	None,
	Unsupported_Color_Attachments,
	Unsupported_Depth_Format,
	Unsupported_Sample_Count,
}

DEFAULT_SAMPLE_COUNT: u32 : 1
MIN_COLOR_ATTACHMENTS: u32 : 1
DEFAULT_DEPTH_FORMAT: wgpu.Texture_Format : .Depth24_Plus

_graphics_init :: proc(
	settings: Renderer_Settings,
	allocator: mem.Allocator,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	r := &g_app.renderer

	settings := settings

	gpu_init(&r.gpu, &settings.gpu, loc) or_return
	r.gpu.settings = settings.gpu
	defer if !ok do gpu_destroy(&r.gpu)

	if settings.color_attachments_count < MIN_COLOR_ATTACHMENTS {
		settings.color_attachments_count = MIN_COLOR_ATTACHMENTS
		log.warnf("Color attachments cannot be empty, defaulting to [%d]", MIN_COLOR_ATTACHMENTS)
	}

	settings.color_attachments_count = max(MIN_COLOR_ATTACHMENTS, settings.color_attachments_count)

	if r.gpu.limits.max_color_attachments < MIN_COLOR_ATTACHMENTS {
		log.fatalf(
			"Unsupported minimum color attachments: Device support [%d], minimum required: [%d]",
			r.gpu.limits.max_color_attachments,
			MIN_COLOR_ATTACHMENTS,
		)
		return
	}

	if settings.color_attachments_count > r.gpu.limits.max_color_attachments {
		settings.color_attachments_count = r.gpu.limits.max_color_attachments
		log.warnf(
			"Color attachments is greater than the maximum limits, defaulting to [%d]",
			r.gpu.limits.max_color_attachments,
		)
	}

	r.render_pass_desc.color_attachments = make(
		[]wgpu.Render_Pass_Color_Attachment,
		settings.color_attachments_count,
		allocator,
	)

	r.render_pass_desc.color_attachments[0] = wgpu.Render_Pass_Color_Attachment {
		view           = nil, // Will be set later
		resolve_target = nil, // Will be set later if MSAA is used
		load_op        = .Clear,
		store_op       = .Store,
		clear_value    = r.clear_color,
	}

	if settings.sample_count == 0 {
		settings.sample_count = DEFAULT_SAMPLE_COUNT
		log.warnf("Sample count cannot be zero, defaulting to [%d]", DEFAULT_SAMPLE_COUNT)
	}

	if settings.sample_count > 1 {
		format_features := wgpu.texture_format_guaranteed_format_features(
			r.gpu.config.format,
			r.gpu.features,
		)

		if !wgpu.texture_usage_feature_flags_sample_count_supported(
			format_features.flags,
			settings.sample_count,
		) {
			log.fatalf(
				"Unsupported sample count [%v] for texture format [%v]\n\t" +
				"The current device and surface format combination does not support this level of multisampling.",
				settings.sample_count,
				r.gpu.config.format,
			)

			return
		}

		_create_msaa_framebuffer(settings.sample_count) or_return

		log.infof("Multisample set to X%d", settings.sample_count)
	}

	if settings.use_depth_stencil {
		if settings.depth_format == .Undefined {
			settings.depth_format = DEFAULT_DEPTH_FORMAT
			log.warnf(
				"Depth texture format cannot be undefined, defaulting to [%v]",
				DEFAULT_DEPTH_FORMAT,
			)
		} else {
			if !wgpu.texture_format_is_depth_stencil_format(settings.depth_format) {
				log.errorf(
					"Unsupported depth format: [%v].\n\t" +
					"The specified format is not a valid depth-stencil format.",
					settings.depth_format,
				)
				return
			}
		}

		_create_depth_framebuffer(settings.depth_format, settings.sample_count) or_return

		log.infof("Using depth stencil [%v]", settings.depth_format)
	}

	r.settings = settings

	return true
}

_graphics_destroy :: proc() {
	_graphics_release_current_texture_frame()

	if g_app.renderer.settings.sample_count > 1 {
		_destroy_framebuffer(g_app.renderer.msaa_framebuffer)
	}

	if g_app.renderer.settings.use_depth_stencil {
		_destroy_framebuffer(g_app.renderer.depth_framebuffer)
	}

	gpu_destroy(&g_app.renderer.gpu)
}

_graphics_get_gpu :: proc() -> ^Graphics_Context {
	return &g_app.renderer.gpu
}

THROTTLE_DURATION :: 16 * time.Millisecond // 16ms roughly corresponds to 60 fps
GET_CURRENT_TEXTURE_MAX_ATTEMPTS :: 3
RENDERER_THROTTLE_DURATION :: THROTTLE_DURATION

_graphics_get_current_texture_frame :: proc "contextless" () -> (ok: bool) #no_bounds_check {
	r := &g_app.renderer

	loop: for attempt in 0 ..< GET_CURRENT_TEXTURE_MAX_ATTEMPTS {
		r.current_frame._texture = wgpu.surface_get_current_texture(r.gpu.surface) or_return
		r.current_frame.texture_released = false
		r.skip_frame = false

		switch r.current_frame.status {
		case .Success:
			// Handle suboptimal surface
			if r.current_frame.suboptimal {
				_graphics_resize_surface(_window_get_size()) or_return
				continue // Try again with the new size
			}
			break loop
		case .Timeout:
			if attempt < GET_CURRENT_TEXTURE_MAX_ATTEMPTS - 1 {
				_log_warn_contextless("Timeout getting current texture. Retrying...")
				time.sleep(RENDERER_THROTTLE_DURATION)
				continue
			}
			fallthrough
		case .Outdated, .Lost:
			r.skip_frame = true
			_graphics_resize_surface(_window_get_size()) or_return
			if attempt < GET_CURRENT_TEXTURE_MAX_ATTEMPTS - 1 {
				_log_warn_contextless("Surface outdated or lost. Resized and retrying...")
				time.sleep(RENDERER_THROTTLE_DURATION)
				continue
			}
			return
		case .Out_Of_Memory, .Device_Lost:
			_log_fatal_contextless(
				"Failed to acquire surface texture: %s\n",
				r.current_frame.status,
			)
			return
		}
	}

	r.current_frame.view = wgpu.texture_create_view(r.current_frame.texture) or_return
	r.current_frame.view_released = false

	// Update color attachment with the current frame's view
	main_framebuffer := &r.render_pass_desc.color_attachments[0]
	main_framebuffer.view = r.current_frame.view
	if r.msaa_framebuffer.sample_count > 1 {
		main_framebuffer.resolve_target = r.current_frame.view
		main_framebuffer.view = r.msaa_framebuffer.view
	}

	return true
}

_graphics_release_current_texture_frame :: proc "contextless" () {
	if !g_app.renderer.current_frame.view_released && g_app.renderer.current_frame.view != nil {
		wgpu.texture_view_release(g_app.renderer.current_frame.view)
		g_app.renderer.current_frame.view_released = true
	}

	if !g_app.renderer.current_frame.texture_released && g_app.renderer.current_frame.texture != nil {
		wgpu.texture_release(g_app.renderer.current_frame.texture)
		g_app.renderer.current_frame.texture_released = true
	}
}

_graphics_resize_surface :: proc "contextless" (size: Window_Size) -> (ok: bool) {
	_graphics_release_current_texture_frame()

	// Panic if width or height is zero.
	if size.width == 0 || size.height == 0 {
		g_app.renderer.skip_frame = true
		time.sleep(RENDERER_THROTTLE_DURATION)
		return
	}

	// Wait for the device to finish all operations
	// TODO(Capati): Does this make sense here?
	wgpu.device_poll(g_app.renderer.gpu.device, true)

	_resize_framebuffers(size) or_return

	g_app.renderer.gpu.config.width = u32(size.width)
	g_app.renderer.gpu.config.height = u32(size.height)

	// Reconfigure the surface
	wgpu.surface_unconfigure(g_app.renderer.gpu.surface)
	wgpu.surface_configure(
		g_app.renderer.gpu.surface,
		g_app.renderer.gpu.device,
		g_app.renderer.gpu.config,
	) or_return

	return true
}

_graphics_before_start :: proc "contextless" () -> (ok: bool) {
	_graphics_get_current_texture_frame() or_return

	g_app.renderer.gpu.encoder = wgpu.device_create_command_encoder(
		g_app.renderer.gpu.device,
	) or_return

	return true
}

_graphics_start :: proc "contextless" () -> (ok: bool) {
	g_app.renderer.gpu.render_pass = wgpu.command_encoder_begin_render_pass(
		g_app.renderer.gpu.encoder,
		g_app.renderer.render_pass_desc,
	)

	return true
}

_graphics_end :: proc "contextless" () -> (ok: bool) {
	wgpu.render_pass_end(g_app.renderer.gpu.render_pass) or_return
	wgpu.render_pass_release(g_app.renderer.gpu.render_pass)

	command_buffer := wgpu.command_encoder_finish(g_app.renderer.gpu.encoder) or_return
	wgpu.command_encoder_release(g_app.renderer.gpu.encoder)

	wgpu.queue_submit(g_app.renderer.gpu.queue, command_buffer)
	wgpu.command_buffer_release(command_buffer)

	wgpu.surface_present(g_app.renderer.gpu.surface) or_return

	_graphics_release_current_texture_frame()

	return true
}
