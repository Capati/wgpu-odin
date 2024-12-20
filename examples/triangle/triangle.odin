package triangle

// Packages
import "base:runtime"
import "core:fmt"
import "core:time"

// Vendor
import "vendor:glfw"

// Local packages
import wgpu "./../../"

EXAMPLE_TITLE :: "Colored Triangle"

WIDTH :: 640
HEIGHT :: 480

FramebufferSize :: struct {
	w, h: u32,
}

Example :: struct {
	window:           glfw.WindowHandle,
	surface:          wgpu.Surface,
	device:           wgpu.Device,
	queue:            wgpu.Queue,
	config:           wgpu.SurfaceConfiguration,
	render_pipeline:  wgpu.RenderPipeline,
	framebuffer_size: FramebufferSize,
	minimized:        bool,
	should_resize:    bool,
}

init :: proc(ctx: ^Example) -> (ok: bool) {
	// Initialize GLFW library
	if !glfw.Init() {panic("Failed to initialize GLFW")}
	defer if !ok {
		glfw.Terminate()
	}

	// Set the global width and height as the current framebuffer size
	ctx.framebuffer_size = {WIDTH, HEIGHT}

	// Ensure no OpenGL context is loaded before window creation
	glfw.WindowHint_int(glfw.CLIENT_API, glfw.NO_API)

	// Create a window with the given size and title
	ctx.window = glfw.CreateWindow(
		i32(ctx.framebuffer_size.w),
		i32(ctx.framebuffer_size.h),
		EXAMPLE_TITLE,
		nil,
		nil,
	)
	assert(ctx.window != nil, "Failed to create window")
	defer if !ok {
		glfw.DestroyWindow(ctx.window)
	}

	// Set the example pointer for access within GLFW window callbacks
	glfw.SetWindowUserPointer(ctx.window, ctx)

	// Set the resize callback
	// We need to resize the surface with the new size before render
	glfw.SetFramebufferSizeCallback(ctx.window, size_callback)

	// Set the window minimize callback
	// We need to prevent rendering when minimized
	glfw.SetWindowIconifyCallback(ctx.window, minimize_callback)

	// The log callback provides information based on a log level
	gpu_log_callback :: proc "c" (
		level: wgpu.LogLevel,
		message: wgpu.StringView,
		userdata: rawptr,
	) {
		if message.length > 0 {
			context = runtime.default_context()
			// Strings in the C API are just a pointer and length,
			message_str := string(message.data)[:message.length]
			fmt.eprintf("[wgpu] [%v] %s\n\n", level, message_str)

			// Most of theses StringView are wrapped in the string type, but there is no easy way
			// to handle this for the callbacks
			// But you can use a helper procedure:
			// message_str := wgpu.string_view_get_string(message)
		}
	}

	// Set the Warn log level to get helpful information
	// API errors are handled from uncaptured errors
	wgpu.set_log_level(.Warn)
	// We can pass some userdata to later retrieve it in the callback
	wgpu.set_log_callback(gpu_log_callback, ctx)

	// Options for creating an instance
	instance_descriptor := wgpu.InstanceDescriptor {
		// We only want the backends: Vulkan, Metal, DX12 or BrowserWebGPU
		backends = wgpu.INSTANCE_BACKEND_PRIMARY,
		// Allow to show validation errors
		flags    = {.Validation},
	}

	// Create an new instance of wgpu with the given descriptor (can be nil to use defaults)
	instance := wgpu.create_instance(instance_descriptor) or_return
	defer wgpu.instance_release(instance)

	// Create a surface for the current platform
	// Check each surface file to learn more about the descriptor
	ctx.surface = wgpu.instance_create_surface(
		instance,
		get_surface_descriptor(ctx.window),
	) or_return
	defer if !ok {
		wgpu.surface_release(ctx.surface)
	}

	// Additional information required when requesting an adapter
	adapter_options := wgpu.RequestAdapterOptions {
		// Ensure our surface can be presentable with the requested adapter
		compatible_surface = ctx.surface,
		// Power preference for the adapter
		power_preference   = .HighPerformance,
	}

	// Retrieves an Adapter which matches the given RequestAdapterOptions
	adapter := wgpu.instance_request_adapter(instance, adapter_options) or_return
	defer wgpu.adapter_release(adapter)

	// Get information about the selected adapter
	// The information includes strings such as vendor, architecture, device, and description,
	// which are owned by the user and must be properly managed
	adapter_info := wgpu.adapter_get_info(adapter) or_return
	// Ensure the allocated strings are properly freed after use
	defer wgpu.adapter_info_free_members(adapter_info)

	fmt.println("Selected adapter:")
	wgpu.adapter_info_print_info(adapter_info)

	// Describes a Device.
	device_descriptor := wgpu.DeviceDescriptor {
		// Labels can be used to identify objects in debug mode
		label           = adapter_info.device,
		// This is a set of limits that is guaranteed to work on all primary backends
		required_limits = wgpu.DOWNLEVEL_LIMITS,
	}

	// Requests a connection to a physical device, creating a logical device
	ctx.device = wgpu.adapter_request_device(adapter, device_descriptor) or_return
	defer if !ok {
		wgpu.device_release(ctx.device)
	}

	// Get a handle to a command queue on the device
	ctx.queue = wgpu.device_get_queue(ctx.device)
	defer if !ok {
		wgpu.queue_release(ctx.queue)
	}

	// Returns the capabilities of the surface when used with the given adapter
	caps := wgpu.surface_get_capabilities(ctx.surface, adapter) or_return
	defer wgpu.surface_capabilities_free_members(caps)

	// We can assume that the first texture format is the "preferred" one
	preferred_format := caps.formats[0]

	// Lets use a non srgb format to avoid "washed out texture colors" in srgb displays
	// More information here:
	// https://github.com/gfx-rs/wgpu-native/issues/386#issuecomment-2122157612
	if wgpu.texture_format_is_srgb(preferred_format) {
		preferred_format = wgpu.texture_format_remove_srgb_suffix(preferred_format)
	}

	// Describes a Surface.
	ctx.config = wgpu.SurfaceConfiguration {
		device       = ctx.device,
		// Describes how the surface textures will be used. RenderAttachment specifies that the
		// textures will be used to write to the surface defined in the window.
		usage        = {.RenderAttachment},
		// Defines how the surface texture will be stored on the GPU
		format       = preferred_format,
		// Define the size of the surface texture,
		// which should usually be the width and height of the window
		width        = ctx.framebuffer_size.w,
		height       = ctx.framebuffer_size.h,
		// The Fifo present mode is the default option guaranteed to be available
		present_mode = .Fifo,
		// Let wgpu choose the best alpha mode for performance
		alpha_mode   = .Auto,
	}

	// Initializes Surface for presentation.
	wgpu.surface_configure(ctx.surface, ctx.config) or_return

	// Load and create a shader module
	TRIANGLE_WGSL :: #load("./triangle.wgsl")
	shader_module := wgpu.device_create_shader_module(
		ctx.device,
		{label = EXAMPLE_TITLE + " Module", source = string(TRIANGLE_WGSL)},
	) or_return
	defer wgpu.shader_module_release(shader_module)

	// Create the triangle pipeline
	ctx.render_pipeline = wgpu.device_create_render_pipeline(
	ctx.device,
	{
		label = EXAMPLE_TITLE + " Render Pipeline",
		vertex = {module = shader_module, entry_point = "vs_main"},
		fragment = &{
			module = shader_module,
			entry_point = "fs_main",
			targets = {
				{
					format = ctx.config.format,
					blend = &wgpu.BLEND_STATE_NORMAL,
					write_mask = wgpu.COLOR_WRITE_MASK_ALL,
				},
			},
		},
		primitive = {topology = .TriangleList, front_face = .CCW, cull_mode = .None},
		multisample = {
			count = 1, // 1 means no sampling (will panic if 0)
			mask  = max(u32), // 0xFFFFFFFF
		},
	},
	) or_return
	defer if !ok {
		wgpu.render_pipeline_release(ctx.render_pipeline)
	}

	return true
}

quit :: proc(ctx: ^Example) {
	wgpu.render_pipeline_release(ctx.render_pipeline)
	wgpu.queue_release(ctx.queue)
	wgpu.surface_release(ctx.surface)
	wgpu.device_release(ctx.device)

	glfw.DestroyWindow(ctx.window)
	glfw.Terminate()
}

size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	context = runtime.default_context()
	ctx := cast(^Example)glfw.GetWindowUserPointer(window)
	ctx.framebuffer_size = {u32(width), u32(height)}
	ctx.should_resize = true
}

minimize_callback :: proc "c" (window: glfw.WindowHandle, iconified: i32) {
	context = runtime.default_context()
	ctx := cast(^Example)glfw.GetWindowUserPointer(window)
	ctx.minimized = bool(iconified)
}

resize_surface :: proc(ctx: ^Example, size: FramebufferSize) -> (ok: bool) {
	// WGPU will panic if width or height is zero.
	if size.w == 0 || size.h == 0 {
		fmt.printfln("Invalid framebuffer size: %v", size)
		return
	}

	// Wait for the device to finish all operations
	wgpu.device_poll(ctx.device, true) or_return

	ctx.config.width = u32(size.w)
	ctx.config.height = u32(size.h)

	// Reconfigure the surface
	wgpu.surface_unconfigure(ctx.surface)
	wgpu.surface_configure(ctx.surface, ctx.config) or_return

	return true
}

get_framebuffer_size :: proc(ctx: ^Example) -> FramebufferSize {
	width, height := glfw.GetFramebufferSize(ctx.window)
	return {u32(width), u32(height)}
}

GET_CURRENT_TEXTURE_MAX_ATTEMPTS :: 3
RENDERER_THROTTLE_DURATION :: 16 * time.Millisecond

get_current_frame :: proc(ctx: ^Example) -> (frame: wgpu.SurfaceTexture, ok: bool) {
	loop: for attempt in 0 ..< GET_CURRENT_TEXTURE_MAX_ATTEMPTS {
		// Returns the next texture to be presented by the swapchain for drawing
		frame = wgpu.surface_get_current_texture(ctx.surface) or_return

		switch frame.status {
		case .SuccessOptimal:
			return frame, true
		case .SuccessSuboptimal:
			fmt.println("Surface suboptimal. Resizing and retrying...")
			if frame.texture != nil {
				wgpu.texture_release(frame.texture)
			}
			resize_surface(ctx, get_framebuffer_size(ctx)) or_return
			continue // Try again with the new size
		case .Timeout, .Outdated, .Lost:
			fmt.printfln("Surface texture [%v]. Retrying...", frame.status)
			if frame.texture != nil {
				wgpu.texture_release(frame.texture)
			}
			if ctx.should_resize {
				resize_surface(ctx, get_framebuffer_size(ctx)) or_return
				ctx.should_resize = false
			}
			if attempt < GET_CURRENT_TEXTURE_MAX_ATTEMPTS - 1 {
				time.sleep(RENDERER_THROTTLE_DURATION)
				continue // Try again
			}
			break loop
		case .OutOfMemory, .DeviceLost, .Error:
			break loop
		}
	}

	fmt.printfln("Failed to acquire surface texture: %s\n", frame.status)
	return
}

render :: proc(ctx: ^Example) -> (ok: bool) {
	frame := get_current_frame(ctx) or_return
	defer wgpu.texture_release(frame.texture)

	// Creates a view for the frame texture
	frame_view := wgpu.texture_create_view(frame.texture)
	defer wgpu.texture_view_release(frame_view)

	// Creates an empty CommandEncoder
	encoder := wgpu.device_create_command_encoder(ctx.device) or_return
	defer wgpu.command_encoder_release(encoder)

	// Describes the attachments of a render pass
	render_pass_descriptor := wgpu.RenderPassDescriptor {
		label             = "Render pass descriptor",
		color_attachments = {
			{
				view = frame_view,
				depth_slice = wgpu.DEPTH_SLICE_UNDEFINED,
				load_op = .Clear,
				store_op = .Store,
				clear_value = {0.0, 0.0, 0.0, 1.0},
			},
		},
	}

	// Begins recording of a render pass
	render_pass := wgpu.command_encoder_begin_render_pass(encoder, render_pass_descriptor)
	defer wgpu.render_pass_release(render_pass)

	// Sets the active render pipeline
	wgpu.render_pass_set_pipeline(render_pass, ctx.render_pipeline)
	// Draws primitives in the range of vertices
	wgpu.render_pass_draw(render_pass, {start = 0, end = 3})
	// Record the end of the render pass
	wgpu.render_pass_end(render_pass) or_return

	// Finishes recording and returns a CommandBuffer that can be submitted for execution
	cmdbuf := wgpu.command_encoder_finish(encoder) or_return
	defer wgpu.command_buffer_release(cmdbuf)

	// Submits a series of finished command buffers for execution
	wgpu.queue_submit(ctx.queue, cmdbuf)
	// Schedule the frame texture to be presented on the owning surface
	wgpu.surface_present(ctx.surface) or_return

	return true
}

main :: proc() {
	example: Example
	if !init(&example) {
		fmt.println("Failed to initialize example")
		return
	}
	defer quit(&example)

	for !glfw.WindowShouldClose(example.window) {
		glfw.PollEvents()

		if !example.minimized {
			if !render(&example) {
				fmt.println("Failed to render example")
				break
			}
		} else {
			time.sleep(RENDERER_THROTTLE_DURATION)
		}
	}

	fmt.println("Exiting...")
}
