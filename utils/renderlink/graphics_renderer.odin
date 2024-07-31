package application

// STD Library
import "base:runtime"
import "core:log"
import "core:time"

// Vendor Package
import wgpu "./../../wrapper"

Framebuffer :: struct {
	texture:      wgpu.Texture,
	view:         wgpu.Texture_View,
	format:       wgpu.Texture_Format,
	sample_count: u32,
	is_depth:     bool,
}

Frame_Texture :: struct {
	using _texture:   wgpu.Surface_Texture,
	view:             wgpu.Texture_View,
	texture_released: bool,
	view_released:    bool,
}

Renderer_Settings :: struct {
	gpu:                     Graphics_Context_Settings,
	color_attachments_count: u32,
	sample_count:            u32,
	use_depth_stencil:       bool,
	depth_format:            wgpu.Texture_Format,
	gamma_correct:           bool,
}

DEFAULT_RENDERER_SETTINGS :: Renderer_Settings {
	gpu                     = DEFAULT_GRAPHICS_CONTEXT_SETTINGS,
	color_attachments_count = MIN_COLOR_ATTACHMENTS,
	sample_count            = DEFAULT_SAMPLE_COUNT,
	use_depth_stencil       = false,
	depth_format            = DEFAULT_DEPTH_FORMAT,
}

Renderer :: struct {
	gpu:                      ^Graphics_Context,
	allocator:                runtime.Allocator,
	clear_color:              wgpu.Color,
	render_pass_desc:         wgpu.Render_Pass_Descriptor,
	msaa_framebuffer:         Framebuffer,
	depth_framebuffer:        Framebuffer,
	depth_stencil_attachment: wgpu.Render_Pass_Depth_Stencil_Attachment,
	current_frame:            Frame_Texture,
	skip_frame:               bool,
	settings:                 Renderer_Settings,
}

Renderer_Error :: enum {
	None,
	Unsupported_Color_Attachments,
	Unsupported_Depth_Format,
	Unsupported_Sample_Count,
}

g_graphics: Renderer

DEFAULT_SAMPLE_COUNT: u32 : 1
MIN_COLOR_ATTACHMENTS: u32 : 1
DEFAULT_DEPTH_FORMAT: wgpu.Texture_Format : .Depth24_Plus

_graphics_init :: proc(
	settings: Renderer_Settings,
	allocator := context.allocator,
) -> (
	err: Error,
) {
	g_graphics.allocator = allocator

	settings := settings

	g_graphics.gpu = gpu_init(&settings.gpu) or_return
	g_graphics.gpu.settings = settings.gpu
	defer if err != nil do gpu_destroy(g_graphics.gpu)

	if settings.color_attachments_count < MIN_COLOR_ATTACHMENTS {
		settings.color_attachments_count = MIN_COLOR_ATTACHMENTS
		log.warnf("Color attachments cannot be empty, defaulting to [%d]", MIN_COLOR_ATTACHMENTS)
	}

	settings.color_attachments_count = max(MIN_COLOR_ATTACHMENTS, settings.color_attachments_count)

	if g_graphics.gpu.device.limits.max_color_attachments < MIN_COLOR_ATTACHMENTS {
		err = .Unsupported_Color_Attachments
		log.fatalf(
			"Unsupported minimum color attachments: Device support [%d], minimum required: [%d]",
			g_graphics.gpu.device.limits.max_color_attachments,
			MIN_COLOR_ATTACHMENTS,
		)
		return
	}

	if settings.color_attachments_count > g_graphics.gpu.device.limits.max_color_attachments {
		settings.color_attachments_count = g_graphics.gpu.device.limits.max_color_attachments
		log.warnf(
			"Color attachments is greater than the maximum limits, defaulting to [%d]",
			g_graphics.gpu.device.limits.max_color_attachments,
		)
	}

	g_graphics.render_pass_desc.color_attachments = make(
		[]wgpu.Render_Pass_Color_Attachment,
		settings.color_attachments_count,
		allocator,
	) or_return

	g_graphics.render_pass_desc.color_attachments[0] = wgpu.Render_Pass_Color_Attachment {
		view           = nil, // Will be set later
		resolve_target = nil, // Will be set later if MSAA is used
		load_op        = .Clear,
		store_op       = .Store,
		clear_value    = g_graphics.clear_color,
	}

	if settings.sample_count == 0 {
		settings.sample_count = DEFAULT_SAMPLE_COUNT
		log.warnf("Sample count cannot be zero, defaulting to [%d]", DEFAULT_SAMPLE_COUNT)
	}

	if settings.sample_count > 1 {
		format_features := wgpu.texture_format_guaranteed_format_features(
			g_graphics.gpu.config.format,
			g_graphics.gpu.device.features,
		)

		if !wgpu.texture_usage_feature_flags_sample_count_supported(
			format_features.flags,
			settings.sample_count,
		) {
			err = .Unsupported_Sample_Count

			log.fatalf(
				"Unsupported sample count [%v] for texture format [%v]\n\t" +
				"The current device and surface format combination does not support this level of multisampling.",
				settings.sample_count,
				g_graphics.gpu.config.format,
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
				err = .Unsupported_Depth_Format
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

	g_graphics.settings = settings

	return
}

_graphics_destroy :: proc() {
	context.allocator = g_graphics.allocator

	_graphics_release_current_texture_frame()

	if g_graphics.settings.sample_count > 1 {
		_destroy_framebuffer(g_graphics.msaa_framebuffer)
	}

	if g_graphics.settings.use_depth_stencil {
		_destroy_framebuffer(g_graphics.depth_framebuffer)
	}

	delete(g_graphics.render_pass_desc.color_attachments)

	gpu_destroy(g_graphics.gpu)
}

_graphics_get_gpu :: proc() -> ^Graphics_Context {
	return g_graphics.gpu
}

THROTTLE_DURATION :: 16 * time.Millisecond // 16ms roughly corresponds to 60 fps
GET_CURRENT_TEXTURE_MAX_ATTEMPTS :: 3
RENDERER_THROTTLE_DURATION :: THROTTLE_DURATION

_graphics_get_current_texture_frame :: proc "contextless" () -> (err: Error) {
	loop: for attempt in 0 ..< GET_CURRENT_TEXTURE_MAX_ATTEMPTS {
		g_graphics.current_frame._texture = wgpu.surface_get_current_texture(
			g_graphics.gpu.surface,
		) or_return
		g_graphics.current_frame.texture_released = false
		g_graphics.skip_frame = false

		switch g_graphics.current_frame.status {
		case .Success:
			// Handle suboptimal surface
			if g_graphics.current_frame.suboptimal {
				_graphics_resize_surface(_window_get_size()) or_return
				continue // Try again with the new size
			}
			break loop
		case .Timeout:
			if attempt < GET_CURRENT_TEXTURE_MAX_ATTEMPTS - 1 {
				when ODIN_DEBUG {
					context = runtime.default_context()
					log.info("Timeout getting current texture. Retrying...")
				}
				time.sleep(RENDERER_THROTTLE_DURATION)
				continue
			}
			fallthrough
		case .Outdated, .Lost:
			g_graphics.skip_frame = true
			_graphics_resize_surface(_window_get_size()) or_return
			if attempt < GET_CURRENT_TEXTURE_MAX_ATTEMPTS - 1 {
				when ODIN_DEBUG {
					context = runtime.default_context()
					log.warn("Surface outdated or lost. Resized and retrying...")
				}
				time.sleep(RENDERER_THROTTLE_DURATION)
				continue
			}
			return g_graphics.current_frame.status
		case .Out_Of_Memory, .Device_Lost:
			when ODIN_DEBUG {
				context = runtime.default_context()
				log.errorf(
					"Failed to acquire surface texture: %s\n",
					g_graphics.current_frame.status,
				)
			}
			return g_graphics.current_frame.status
		}
	}

	g_graphics.current_frame.view = wgpu.texture_create_view(
		g_graphics.current_frame.texture,
	) or_return
	g_graphics.current_frame.view_released = false

	// Update color attachment with the current frame's view
	main_framebuffer := &g_graphics.render_pass_desc.color_attachments[0]
	main_framebuffer.view = g_graphics.current_frame.view.ptr
	if g_graphics.msaa_framebuffer.sample_count > 1 {
		main_framebuffer.resolve_target = g_graphics.current_frame.view.ptr
		main_framebuffer.view = g_graphics.msaa_framebuffer.view.ptr
	}

	return
}

_graphics_release_current_texture_frame :: proc "contextless" () {
	if !g_graphics.current_frame.view_released && g_graphics.current_frame.view.ptr != nil {
		wgpu.texture_view_release(g_graphics.current_frame.view)
		g_graphics.current_frame.view_released = true
	}

	if !g_graphics.current_frame.texture_released && g_graphics.current_frame.texture.ptr != nil {
		wgpu.texture_release(g_graphics.current_frame.texture)
		g_graphics.current_frame.texture_released = true
	}
}

_graphics_resize_surface :: proc "contextless" (size: Window_Size) -> (err: Error) {
	_graphics_release_current_texture_frame()

	// Panic if width or height is zero.
	if size.width == 0 || size.height == 0 {
		g_graphics.skip_frame = true
		time.sleep(RENDERER_THROTTLE_DURATION)
		return
	}

	// Wait for the device to finish all operations
	// TODO(Capati): Does this make sense here?
	wgpu.device_poll(g_graphics.gpu.device, true)

	_resize_framebuffers(size) or_return

	g_graphics.gpu.config.width = u32(size.width)
	g_graphics.gpu.config.height = u32(size.height)

	// Reconfigure the surface
	wgpu.surface_unconfigure(g_graphics.gpu.surface)
	wgpu.surface_configure(
		&g_graphics.gpu.surface,
		g_graphics.gpu.device,
		g_graphics.gpu.config,
	) or_return

	return
}

_graphics_start :: proc "contextless" () -> (err: Error) {
	_graphics_get_current_texture_frame() or_return

	g_graphics.gpu.encoder = wgpu.device_create_command_encoder(g_graphics.gpu.device) or_return
	g_graphics.gpu.render_pass = wgpu.command_encoder_begin_render_pass(
		g_graphics.gpu.encoder,
		g_graphics.render_pass_desc,
	)

	return
}

_graphics_end :: proc "contextless" () -> (err: Error) {
	wgpu.render_pass_end(g_graphics.gpu.render_pass) or_return
	wgpu.render_pass_release(g_graphics.gpu.render_pass)

	command_buffer := wgpu.command_encoder_finish(g_graphics.gpu.encoder) or_return
	wgpu.command_encoder_release(g_graphics.gpu.encoder)

	wgpu.queue_submit(g_graphics.gpu.queue, command_buffer.ptr)
	wgpu.command_buffer_release(command_buffer)

	wgpu.surface_present(g_graphics.gpu.surface) or_return

	_graphics_release_current_texture_frame()

	return
}
