package tutorial2_surface_glfw

// Core
import "base:runtime"
import "core:fmt"
import "vendor:glfw"

// Local packages
import wgpu_glfw "root:utils/glfw"
import "root:wgpu"

State :: struct {
	window:    glfw.WindowHandle,
	minimized: bool,
	surface:   wgpu.Surface,
	device:    wgpu.Device,
	queue:     wgpu.Queue,
	config:    wgpu.Surface_Configuration,
}

Physical_Size :: struct {
	width:  u32,
	height: u32,
}

_log_callback :: proc "c" (level: wgpu.Log_Level, message: wgpu.String_View, userdata: rawptr) {
	context = runtime.default_context()
	fmt.eprintf("[wgpu] [%v] %s\n\n", level, wgpu.string_view_get_string(message))
}

init :: proc() -> (state: ^State, ok: bool) {
	state = new(State)
	defer if !ok {
		free(state)
	}

	if !glfw.Init() {
		panic("[glfw] init failure")
	}
	defer if !ok {
		glfw.Terminate()
	}

	glfw.WindowHint(glfw.CLIENT_API, glfw.NO_API)
	state.window = glfw.CreateWindow(800, 600, "Tutorial 1 - Window", nil, nil)
	defer if !ok {
		glfw.DestroyWindow(state.window)
	}

	glfw.SetWindowUserPointer(state.window, state)
	glfw.SetFramebufferSizeCallback(state.window, size_callback)
	glfw.SetWindowIconifyCallback(state.window, iconify_callback)

	wgpu.set_log_callback(_log_callback, nil)
	wgpu.set_log_level(.Warn)

	instance_descriptor := wgpu.Instance_Descriptor {
		backends = wgpu.BACKENDS_PRIMARY,
	}

	instance := wgpu.create_instance(instance_descriptor) or_return
	defer wgpu.release(instance)

	surface_descriptor := wgpu_glfw.get_surface_descriptor(state.window) or_return
	state.surface = wgpu.instance_create_surface(instance, surface_descriptor) or_return
	defer if !ok {
		wgpu.release(state.surface)
	}

	adapter_options := wgpu.Request_Adapter_Options {
		power_preference       = .High_Performance,
		compatible_surface     = state.surface,
		force_fallback_adapter = false,
	}

	adapter := wgpu.instance_request_adapter(instance, adapter_options) or_return
	defer wgpu.release(adapter)

	adapter_info := wgpu.adapter_get_info(adapter) or_return
	defer wgpu.adapter_info_free_members(adapter_info)

	device_descriptor := wgpu.Device_Descriptor {
		label           = adapter_info.description,
		required_limits = wgpu.DEFAULT_LIMITS,
	}

	state.device = wgpu.adapter_request_device(adapter, device_descriptor) or_return
	defer if !ok {
		wgpu.release(state.device)
	}

	state.queue = wgpu.device_get_queue(state.device)
	defer if !ok {
		wgpu.release(state.queue)
	}

	caps := wgpu.surface_get_capabilities(state.surface, adapter) or_return
	defer wgpu.surface_capabilities_free_members(caps)

	width, height := glfw.GetWindowSize(state.window)

	state.config = {
		device       = state.device,
		usage        = {.Render_Attachment},
		format       = caps.formats[0],
		width        = cast(u32)width,
		height       = cast(u32)height,
		present_mode = .Fifo,
		alpha_mode   = caps.alpha_modes[0],
	}

	wgpu.surface_configure(state.surface, state.config) or_return

	return state, true
}

deinit :: proc(state: ^State) {
	wgpu.release(state.queue)
	wgpu.release(state.device)
	wgpu.release(state.surface)
	glfw.DestroyWindow(state.window)
	glfw.Terminate()
	free(state)
}

render :: proc(state: ^State) -> bool {
	frame := wgpu.surface_get_current_texture(state.surface) or_return
	defer wgpu.release(frame.texture)

	view := wgpu.texture_create_view(frame.texture) or_return
	defer wgpu.release(view)

	encoder := wgpu.device_create_command_encoder(
		state.device,
		wgpu.Command_Encoder_Descriptor{label = "Command Encoder"},
	) or_return
	defer wgpu.release(encoder)

	render_pass := wgpu.command_encoder_begin_render_pass(
		encoder,
		{
			label = "Render Pass",
			color_attachments = []wgpu.Render_Pass_Color_Attachment {
				{view = view, resolve_target = nil, ops = {.Clear, .Store, {0.1, 0.2, 0.3, 1.0}}},
			},
			depth_stencil_attachment = nil,
		},
	)
	defer wgpu.release(render_pass)
	wgpu.render_pass_end(render_pass) or_return

	command_buffer := wgpu.command_encoder_finish(encoder) or_return
	defer wgpu.release(command_buffer)

	wgpu.queue_submit(state.queue, command_buffer)
	wgpu.surface_present(state.surface)

	return true
}

resize_surface :: proc(state: ^State, size: Physical_Size) -> bool {
	if size.width == 0 && size.height == 0 {
		return true
	}

	state.config.width = size.width
	state.config.height = size.height

	wgpu.surface_unconfigure(state.surface)
	wgpu.surface_configure(state.surface, state.config) or_return

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
