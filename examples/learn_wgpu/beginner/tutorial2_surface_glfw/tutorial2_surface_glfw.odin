package tutorial2_surface_glfw

// Core
import "base:runtime"
import "core:fmt"

// Vendor
import "vendor:glfw"

// Local Packages
import wgpu "../../../../" /* root folder */
import wgpu_glfw "../../../../utils/glfw"

State :: struct {
	window:    glfw.WindowHandle,
	minimized: bool,
	surface:   wgpu.Surface,
	device:    wgpu.Device,
	queue:     wgpu.Queue,
	config:    wgpu.SurfaceConfiguration,
}

Physical_Size :: struct {
	width:  u32,
	height: u32,
}

_log_callback :: proc "c" (level: wgpu.LogLevel, message: string, userdata: rawptr) {
	context = runtime.default_context()
	fmt.eprintf("[wgpu] [%v] %s\n\n", level, message)
}

init :: proc() -> (state: ^State, ok: bool) {
	state = new(State)
	defer if !ok do free(state)

	ensure(bool(glfw.Init()))
	defer if !ok do  glfw.Terminate()

	glfw.WindowHint(glfw.CLIENT_API, glfw.NO_API)
	state.window = glfw.CreateWindow(800, 600, "Tutorial 1 - Window", nil, nil)
	defer if !ok {
		glfw.DestroyWindow(state.window)
	}

	glfw.SetWindowUserPointer(state.window, state)
	glfw.SetFramebufferSizeCallback(state.window, size_callback)
	glfw.SetWindowIconifyCallback(state.window, iconify_callback)

	wgpu.SetLogCallback(_log_callback, nil)
	wgpu.SetLogLevel(.Warn)

	instance_descriptor := wgpu.InstanceDescriptor {
		backends = wgpu.BACKENDS_PRIMARY,
	}

	instance := wgpu.CreateInstance(instance_descriptor)
	defer wgpu.Release(instance)

	state.surface = wgpu_glfw.create_surface(state.window, instance)
	defer if !ok do wgpu.Release(state.surface)

	adapter_options := wgpu.RequestAdapterOptions {
		powerPreference      = .HighPerformance,
		compatibleSurface    = state.surface,
		forceFallbackAdapter = false,
	}

	adapter_res := wgpu.InstanceRequestAdapterSync(instance, adapter_options)
	if (adapter_res.status != .Success) {
		fmt.eprintfln(
			"Failed to request the selected adapter [%v]: %s",
			adapter_res.status,
			adapter_res.message,
		)
		return
	}
	adapter := adapter_res.adapter
	defer wgpu.AdapterRelease(adapter)

	adapter_info, info_status := wgpu.AdapterGetInfo(adapter)
	if info_status != .Success {
		fmt.eprintln("Failed to get adapter info for the selected adapter")
		return
	}
	defer wgpu.AdapterInfoFreeMembers(adapter_info)

	device_descriptor := wgpu.DeviceDescriptor {
		label          = adapter_info.device,
		requiredLimits = wgpu.LIMITS_DEFAULT,
	}

	device_res := wgpu.AdapterRequestDeviceSync(adapter, device_descriptor)
	if (device_res.status != .Success) {
		fmt.eprintfln(
			"Failed to request the selected device [%v]: %s",
			device_res.status,
			device_res.message,
		)
		return
	}
	state.device = device_res.device
	defer if !ok do wgpu.Release(state.device)

	state.queue = wgpu.DeviceGetQueue(state.device)
	defer if !ok do wgpu.Release(state.queue)

	caps := wgpu.SurfaceGetCapabilities(state.surface, adapter)
	defer wgpu.SurfaceCapabilitiesFreeMembers(caps)

	width, height := glfw.GetWindowSize(state.window)

	state.config = {
		device      = state.device,
		usage       = {.RenderAttachment},
		format      = caps.formats[0],
		width       = cast(u32)width,
		height      = cast(u32)height,
		presentMode = .Fifo,
		alphaMode   = caps.alphaModes[0],
	}

	wgpu.SurfaceConfigure(state.surface, state.config)

	return state, true
}

deinit :: proc(state: ^State) {
	wgpu.Release(state.queue)
	wgpu.Release(state.device)
	wgpu.Release(state.surface)
	glfw.DestroyWindow(state.window)
	glfw.Terminate()
	free(state)
}

render :: proc(state: ^State) -> bool {
	frame := wgpu.SurfaceGetCurrentTexture(state.surface)
	defer wgpu.Release(frame.texture)

	view := wgpu.TextureCreateView(frame.texture)
	defer wgpu.Release(view)

	encoder := wgpu.DeviceCreateCommandEncoder(
		state.device,
		wgpu.CommandEncoderDescriptor{label = "Command Encoder"},
	)
	defer wgpu.Release(encoder)

	render_pass := wgpu.CommandEncoderBeginRenderPass(
		encoder,
		{
			label = "Render Pass",
			colorAttachments = []wgpu.RenderPassColorAttachment {
				{view = view, resolveTarget = nil, ops = {.Clear, .Store, {0.1, 0.2, 0.3, 1.0}}},
			},
			depthStencilAttachment = nil,
		},
	)
	defer wgpu.Release(render_pass)
	wgpu.RenderPassEnd(render_pass)

	command_buffer := wgpu.CommandEncoderFinish(encoder)
	defer wgpu.Release(command_buffer)

	wgpu.QueueSubmit(state.queue, { command_buffer })
	wgpu.SurfacePresent(state.surface)

	return true
}

resize_surface :: proc(state: ^State, size: Physical_Size) -> bool {
	if size.width == 0 && size.height == 0 {
		return true
	}

	state.config.width = size.width
	state.config.height = size.height

	wgpu.SurfaceUnconfigure(state.surface)
	wgpu.SurfaceConfigure(state.surface, state.config)

	return true
}

iconify_callback :: proc "c" (window: glfw.WindowHandle, iconified: i32) {
	state := cast(^State)(glfw.GetWindowUserPointer(window))
	state.minimized = bool(iconified)
}

size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	context = runtime.default_context()
	state := cast(^State)(glfw.GetWindowUserPointer(window))
	resize_surface(state, {u32(width), u32(height)})
}

main :: proc() {
	state, state_ok := init()
	if !state_ok {
		return
	}
	defer deinit(state)

	for !glfw.WindowShouldClose(state.window) {
		glfw.PollEvents()

		if !state.minimized {
			if ok := render(state); !ok {
				glfw.SetWindowShouldClose(state.window, true)
			}
		}
	}

	fmt.println("Exiting...")
}
