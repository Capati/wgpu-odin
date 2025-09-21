package triangle

// Core
import "base:runtime"
import "core:fmt"
import "core:time"
import "vendor:glfw"

// Local packages
import wgpu "../.."

EXAMPLE_TITLE :: "Colored Triangle (Verbose)"

WIDTH :: 640
HEIGHT :: 480

Framebuffer_Size :: struct {
	w, h: u32,
}

Example :: struct {
	window:           glfw.WindowHandle,
	surface:          wgpu.Surface,
	device:           wgpu.Device,
	queue:            wgpu.Queue,
	config:           wgpu.SurfaceConfiguration,
	render_pipeline:  wgpu.RenderPipeline,
	framebuffer_size: Framebuffer_Size,
	minimized:        bool,
	should_resize:    bool,
}

init :: proc(ctx: ^Example) -> (ok: bool) {
	// Initialize GLFW library
	ensure(bool(glfw.Init()), "Failed to initialize GLFW")
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
		message: string,
		userdata: rawptr,
	) {
		context = runtime.default_context()
		fmt.eprintf("[WGPU] [%v] %s\n\n", level, message)
	}

	// Set the Warn log level to get helpful information
	// API errors are handled from uncaptured errors
	wgpu.SetLogLevel(.Warn)
	// We can pass some userdata to later retrieve it in the callback
	wgpu.SetLogCallback(gpu_log_callback, ctx)

	// Options for creating an instance
	instance_descriptor := wgpu.InstanceDescriptor {
		// We only want the backends: Vulkan, Metal, DX12 or Browser_WebGPU
		backends = wgpu.BACKENDS_PRIMARY,
		// Allow to show validation errors
		flags    = {.Validation},
	}

	// Create a new instance of wgpu with the given descriptor (can be nil to use defaults)
	instance := wgpu.CreateInstance(instance_descriptor)
	defer wgpu.Release(instance)

	// Create a surface for the current platform
	// Check each surface_<platform>.odin file to learn more about the descriptor
	ctx.surface = wgpu.InstanceCreateSurface(
		instance,
		get_surface_descriptor(ctx.window),
	)
	defer if !ok {
		wgpu.Release(ctx.surface)
	}

	// Additional information required when requesting an adapter
	adapter_options := wgpu.RequestAdapterOptions {
		// Ensure our surface can be presentable with the requested adapter
		compatibleSurface = ctx.surface,
		// Power preference for the adapter
		powerPreference   = .HighPerformance,
	}

	// Retrieves an Adapter which matches the given RequestAdapterOptions
	adapter_res := wgpu.InstanceRequestAdapter(instance, adapter_options)
	if (adapter_res.status != .Success) {
		fmt.eprintfln(
			"Failed to request the adapter [%v]: %s",
			adapter_res.status,
			adapter_res.message,
		)
		return
	}

	adapter := adapter_res.adapter
	defer wgpu.Release(adapter)

	// Get information about the selected adapter
	// The information includes strings such as vendor, architecture, device, and description,
	// which are owned by the user and must be properly managed
	adapter_info, info_status := wgpu.AdapterGetInfo(adapter)
	if info_status != .Success {
		fmt.eprintln("Failed to get adapter info")
		return
	}
	// Ensure the allocated strings are properly freed after use
	defer wgpu.AdapterInfoFreeMembers(adapter_info)

	fmt.println("Selected adapter:")
	wgpu.AdapterInfoPrint(adapter_info)

	// Describes a Device.
	device_descriptor := wgpu.DeviceDescriptor {
		// Labels can be used to identify objects in debug mode
		label          = adapter_info.device,
		// This is a set of limits that is guaranteed to work on all primary backends
		requiredLimits = wgpu.LIMITS_DOWNLEVEL,
	}

	// Requests a connection to a physical device, creating a logical device
	device_res := wgpu.AdapterRequestDevice(adapter, device_descriptor)
	if (device_res.status != .Success) {
		fmt.eprintfln(
			"Failed to request the device [%v]: %s",
			device_res.status,
			device_res.message,
		)
		return
	}

	ctx.device = device_res.device
	defer if !ok {
		wgpu.Release(ctx.device)
	}

	// Get a handle to a command queue on the device
	ctx.queue = wgpu.DeviceGetQueue(ctx.device)
	defer if !ok {
		wgpu.Release(ctx.queue)
	}

	// Returns the capabilities of the surface when used with the given adapter
	caps := wgpu.SurfaceGetCapabilities(ctx.surface, adapter)
	defer wgpu.SurfaceCapabilitiesFreeMembers(caps)

	// We can assume that the first texture format is the "preferred" one
	preferred_format := caps.formats[0]

	// Lets use a non srgb format to avoid "washed out texture colors" in srgb displays
	// More information here:
	// https://github.com/gfx-rs/wgpu-native/issues/386#issuecomment-2122157612
	if wgpu.TextureFormatIsSrgb(preferred_format) {
		preferred_format = wgpu.TextureFormatRemoveSrgbSuffix(preferred_format)
	}

	// Describes a Surface.
	ctx.config = wgpu.SurfaceConfiguration {
		device      = ctx.device,
		// Describes how the surface textures will be used. RenderAttachment specifies that the
		// textures will be used to write to the surface defined in the window.
		usage       = {.RenderAttachment},
		// Defines how the surface texture will be stored on the GPU
		format      = preferred_format,
		// Define the size of the surface texture,
		// which should usually be the width and height of the window
		width       = ctx.framebuffer_size.w,
		height      = ctx.framebuffer_size.h,
		// The Fifo present mode is the default option guaranteed to be available
		presentMode = .Fifo,
		// Let wgpu choose the best alpha mode for performance
		alphaMode   = .Auto,
	}

	// Initializes Surface for presentation.
	wgpu.SurfaceConfigure(ctx.surface, ctx.config)

	// Load and create a shader module
	TRIANGLE_WGSL :: #load("./triangle.wgsl")
	shader_module := wgpu.DeviceCreateShaderModule(
		ctx.device,
		{label = EXAMPLE_TITLE + " Module", source = string(TRIANGLE_WGSL)},
	)
	defer wgpu.Release(shader_module)

	// Create the triangle pipeline
	ctx.render_pipeline = wgpu.DeviceCreateRenderPipeline(
	ctx.device,
	{
		label = EXAMPLE_TITLE + " Render Pipeline",
		vertex = {module = shader_module, entryPoint = "vs_main"},
		fragment = &{
			module = shader_module,
			entryPoint = "fs_main",
			targets = {
				{
					format = ctx.config.format,
					blend = &wgpu.BLEND_STATE_NORMAL,
					writeMask = wgpu.COLOR_WRITES_ALL,
				},
			},
		},
		primitive = {topology = .TriangleList, frontFace = .CCW, cullMode = .None},
		multisample = {
			count = 1, // 1 means no sampling (will panic if 0)
			mask  = max(u32), // 0xFFFFFFFF
		},
	},
	)
	defer if !ok {
		wgpu.Release(ctx.render_pipeline)
	}

	return true
}

quit :: proc(ctx: ^Example) {
	wgpu.Release(ctx.render_pipeline)
	wgpu.Release(ctx.queue)
	wgpu.Release(ctx.surface)
	wgpu.Release(ctx.device)

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

resize_surface :: proc(ctx: ^Example, size: Framebuffer_Size) -> (ok: bool) {
	// WGPU will panic if width or height is zero.
	if size.w == 0 || size.h == 0 {
		fmt.printfln("Invalid framebuffer size: %v", size)
		return
	}

	// Wait for the device to finish all operations
	wgpu.DevicePoll(ctx.device, true)

	ctx.config.width = u32(size.w)
	ctx.config.height = u32(size.h)

	// Reconfigure the surface
	wgpu.SurfaceUnconfigure(ctx.surface)
	wgpu.SurfaceConfigure(ctx.surface, ctx.config)

	return true
}

get_framebuffer_size :: proc(ctx: ^Example) -> Framebuffer_Size {
	width, height := glfw.GetFramebufferSize(ctx.window)
	return {u32(width), u32(height)}
}

GET_CURRENT_TEXTURE_MAX_ATTEMPTS :: 3
RENDERER_THROTTLE_DURATION :: 16 * time.Millisecond

get_current_frame :: proc(ctx: ^Example) -> (frame: wgpu.SurfaceTexture, ok: bool) {
	loop: for attempt in 0 ..< GET_CURRENT_TEXTURE_MAX_ATTEMPTS {
		// Returns the next texture to be presented by the swapchain for drawing
		frame = wgpu.SurfaceGetCurrentTexture(ctx.surface)

		switch frame.status {
		case .SuccessOptimal:
			return frame, true
		case .SuccessSuboptimal:
			fmt.println("Surface suboptimal. Resizing and retrying...")
			if frame.texture != nil {
				wgpu.Release(frame.texture)
			}
			resize_surface(ctx, get_framebuffer_size(ctx)) or_return
			continue // Try again with the new size
		case .Timeout, .Outdated, .Lost:
			fmt.printfln("Surface texture [%v]. Retrying...", frame.status)
			if frame.texture != nil {
				wgpu.Release(frame.texture)
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
	defer wgpu.Release(frame.texture)

	// Creates a view for the frame texture
	frame_view := wgpu.TextureCreateView(frame.texture)
	defer wgpu.Release(frame_view)

	// Creates an empty Command_Encoder
	encoder := wgpu.DeviceCreateCommandEncoder(ctx.device)
	defer wgpu.Release(encoder)

	// Describes the attachments of a render pass
	render_pass_descriptor := wgpu.RenderPassDescriptor {
		label             = "Render pass descriptor",
		colorAttachments = {
			{
				view = frame_view,
				ops = {.Clear, .Store, {0.0, 0.0, 0.0, 1.0}},
			},
		},
	}

	// Begins recording of a render pass
	render_pass := wgpu.CommandEncoderBeginRenderPass(encoder, render_pass_descriptor)
	defer wgpu.Release(render_pass)

	// Sets the active render pipeline
	wgpu.RenderPassSetPipeline(render_pass, ctx.render_pipeline)
	// Draws primitives in the range of vertices
	wgpu.RenderPassDraw(render_pass, {start = 0, end = 3})
	// Record the end of the render pass
	wgpu.RenderPassEnd(render_pass)

	// Finishes recording and returns a Command_Buffer that can be submitted for execution
	cmdbuf := wgpu.CommandEncoderFinish(encoder)
	defer wgpu.Release(cmdbuf)

	// Submits a series of finished command buffers for execution
	wgpu.QueueSubmit(ctx.queue, {cmdbuf})
	// Schedule the frame texture to be presented on the owning surface
	wgpu.SurfacePresent(ctx.surface)

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
