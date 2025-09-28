package triangle

// Core
import "base:runtime"
import "core:fmt"

// Local packages
import wgpu "../.."

EXAMPLE_TITLE :: "Colored Triangle (Verbose)"

state: struct {
	ctx:             runtime.Context,
	os:              OS,
	instance:        wgpu.Instance,
	surface:         wgpu.Surface,
	adapter:         wgpu.Adapter,
	device:          wgpu.Device,
	queue:           wgpu.Queue,
	config:          wgpu.SurfaceConfiguration,
	render_pipeline: wgpu.RenderPipeline,
}

main :: proc() {
	state.ctx = context

	os_init()

	when ODIN_OS != .JS {
		// The log callback provides information based on a log level
		gpu_log_callback :: proc "c" (
			level: wgpu.LogLevel,
			message: string,
			userdata: rawptr,
		) {
			context = state.ctx
			fmt.eprintf("[WGPU] [%v] %s\n\n", level, message)
		}

		// Set the Warn log level to get helpful information
		// API errors are handled from uncaptured errors
		wgpu.SetLogLevel(.Warn)
	}

	instance_descriptor := wgpu.InstanceDescriptor {
		backends = wgpu.BACKENDS_PRIMARY,
	}

	// Create a new instance of wgpu with defaults
	state.instance = wgpu.CreateInstance(instance_descriptor)

	// Create a surface for the current platform
	// Check each surface_<platform>.odin file to learn more
	state.surface = os_get_surface(state.instance)

	// Additional information required when requesting an adapter
	adapter_options := wgpu.RequestAdapterOptions {
		// Ensure our surface can be presentable with the requested adapter
		compatibleSurface = state.surface,
		// Power preference for the adapter
		powerPreference   = .HighPerformance,
	}

	// Retrieves an Adapter which matches the given options
	wgpu.InstanceRequestAdapter(state.instance, adapter_options, {callback = on_adapter})

	on_adapter :: proc "c" (
		status: wgpu.RequestAdapterStatus,
		adapter: wgpu.Adapter,
		message: string,
		userdata1: rawptr,
		userdata2: rawptr,
	) {
		context = state.ctx
		if status != .Success || adapter == nil {
			fmt.panicf("request adapter failure: [%v] %s", status, message)
		}
		state.adapter = adapter

		// Describes a Device.
		device_descriptor: wgpu.DeviceDescriptor

		when ODIN_OS != .JS {
			// Get information about the selected adapter
			// The information includes strings such as vendor, architecture, device,
			// and description, which are owned by the user and must be properly managed
			adapter_info, info_status := wgpu.AdapterGetInfo(adapter)
			if info_status != .Success {
				fmt.panicf("Failed to get adapter info: [%v", info_status)
			}
			// Ensure the allocated strings are properly freed after use
			defer wgpu.AdapterInfoFreeMembers(adapter_info)

			fmt.println("Selected adapter:")
			wgpu.AdapterInfoPrint(adapter_info)

			// Labels can be used to identify objects in debug mode
			device_descriptor.label = adapter_info.device
		}

		// This is a set of limits that is guaranteed to work on all primary backends
		device_descriptor.requiredLimits = wgpu.LIMITS_DOWNLEVEL

		wgpu.AdapterRequestDevice(adapter, device_descriptor, {callback = on_device})
	}

	on_device :: proc "c" (
		status: wgpu.RequestDeviceStatus,
		device: wgpu.Device,
		message: string,
		userdata1: rawptr,
		userdata2: rawptr,
	) {
		context = state.ctx
		if status != .Success || device == nil {
			fmt.panicf("request device failure: [%v] %s", status, message)
		}
		state.device = device

		// Get a handle to a command queue on the device
		state.queue = wgpu.DeviceGetQueue(state.device)

		// Returns the capabilities of the surface when used with the given adapter
		caps := wgpu.SurfaceGetCapabilities(state.surface, state.adapter)

		// We can assume that the first texture format is the "preferred" one
		preferred_format := caps.formats[0]

		wgpu.SurfaceCapabilitiesFreeMembers(caps)

		// Lets use a non srgb format to avoid "washed out texture colors" in srgb displays
		// More information here:
		// https://github.com/gfx-rs/wgpu-native/issues/386#issuecomment-2122157612
		if wgpu.TextureFormatIsSrgb(preferred_format) {
			preferred_format = wgpu.TextureFormatRemoveSrgbSuffix(preferred_format)
		}

		width, height := os_get_framebuffer_size()

		// Describes a Surface.
		state.config = wgpu.SurfaceConfiguration {
			device      = state.device,
			// Describes how the surface textures will be used. RenderAttachment specifies that the
			// textures will be used to write to the surface defined in the window.
			usage       = {.RenderAttachment},
			// Defines how the surface texture will be stored on the GPU
			format      = preferred_format,
			// Define the size of the surface texture,
			// which should usually be the width and height of the window
			width       = width,
			height      = height,
			// The Fifo present mode is the default option guaranteed to be available
			presentMode = .Fifo,
			// Let wgpu choose the best alpha mode for performance
			alphaMode   = .Auto,
		}

		// Initializes Surface for presentation.
		wgpu.SurfaceConfigure(state.surface, state.config)

		// Load and create a shader module
		TRIANGLE_WGSL :: #load("./triangle.wgsl")
		shader_module := wgpu.DeviceCreateShaderModule(
			state.device,
			{label = EXAMPLE_TITLE + " Module", source = string(TRIANGLE_WGSL)},
		)

		// Create the triangle pipeline
		state.render_pipeline = wgpu.DeviceCreateRenderPipeline(
			state.device,
			{
				label = EXAMPLE_TITLE + " Render Pipeline",
				vertex = {module = shader_module, entryPoint = "vs_main"},
				fragment = &{
					module = shader_module,
					entryPoint = "fs_main",
					targets = {
						{
							format = state.config.format,
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

		wgpu.Release(shader_module)

		os_run()
	}
}

resize :: proc "c" () {
	context = state.ctx

	state.config.width, state.config.height = os_get_framebuffer_size()
	wgpu.SurfaceConfigure(state.surface, state.config)
}

frame :: proc "c" (dt: f32) {
	context = state.ctx

	surface_texture := wgpu.SurfaceGetCurrentTexture(state.surface)
	switch surface_texture.status {
	case .SuccessOptimal, .SuccessSuboptimal:
		// All good, could handle suboptimal here.
	case .Timeout, .Outdated, .Lost:
		// Skip this frame, and re-configure surface.
		if surface_texture.texture != nil {
			wgpu.TextureRelease(surface_texture.texture)
		}
		resize()
		return
	case .OutOfMemory, .DeviceLost, .Error:
		// Fatal error
		fmt.panicf("[triangle] get_current_texture status=%v", surface_texture.status)
	}
	defer wgpu.TextureRelease(surface_texture.texture)

	// Creates a view for the frame texture
	frame := wgpu.TextureCreateView(surface_texture.texture)
	defer wgpu.Release(frame)

	// Creates an empty Command_Encoder
	encoder := wgpu.DeviceCreateCommandEncoder(state.device)
	defer wgpu.Release(encoder)

	// Describes the attachments of a render pass
	render_pass_descriptor := wgpu.RenderPassDescriptor {
		label             = "Render pass descriptor",
		colorAttachments = {
			{
				view = frame,
				ops = {.Clear, .Store, {0.0, 0.0, 0.0, 1.0}},
			},
		},
	}

	// Begins recording of a render pass
	render_pass := wgpu.CommandEncoderBeginRenderPass(encoder, render_pass_descriptor)
	defer wgpu.Release(render_pass)

	// Sets the active render pipeline
	wgpu.RenderPassSetPipeline(render_pass, state.render_pipeline)
	// Draws primitives in the range of vertices
	wgpu.RenderPassDraw(render_pass, {start = 0, end = 3})
	// Record the end of the render pass
	wgpu.RenderPassEnd(render_pass)

	// Finishes recording and returns a Command_Buffer that can be submitted for execution
	cmdbuf := wgpu.CommandEncoderFinish(encoder)
	defer wgpu.Release(cmdbuf)

	// Submits a series of finished command buffers for execution
	wgpu.QueueSubmit(state.queue, {cmdbuf})
	// Schedule the frame texture to be presented on the owning surface
	wgpu.SurfacePresent(state.surface)
}

finish :: proc() {
	wgpu.RenderPipelineRelease(state.render_pipeline)
	wgpu.QueueRelease(state.queue)
	wgpu.DeviceRelease(state.device)
	wgpu.AdapterRelease(state.adapter)
	wgpu.SurfaceRelease(state.surface)

	when ODIN_OS != .JS {
		wgpu.CheckForMemoryLeaks(state.instance)
	}

	wgpu.InstanceRelease(state.instance)
}
