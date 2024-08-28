package tutorial2_surface_glfw

// STD Library
import "base:runtime"
import "core:fmt"

// Vendor
import "vendor:glfw"

// Local packages
import wgpu_glfw "../../../../utils/glfw"
import wgpu "../../../../wrapper"

State :: struct {
	window    : glfw.WindowHandle,
	minimized : bool,
	surface   : wgpu.Surface,
	device    : wgpu.Device,
	queue     : wgpu.Queue,
	config    : wgpu.Surface_Configuration,
}

Physical_Size :: struct {
	width  : u32,
	height : u32,
}

_log_callback :: proc "c" (level: wgpu.Log_Level, message: cstring, user_data: rawptr) {
	context = runtime.default_context()
	fmt.eprintf("[wgpu] [%v] %s\n\n", level, message)
}

init :: proc() -> (state: ^State, ok: bool) {
	state = new(State)
	defer if !ok do free(state)

	if !glfw.Init() {
		panic("[glfw] init failure")
	}
	defer if !ok do glfw.Terminate()

	glfw.WindowHint(glfw.CLIENT_API, glfw.NO_API)
	state.window = glfw.CreateWindow(800, 600, "Tutorial 1 - Window", nil, nil)
	defer if !ok do glfw.DestroyWindow(state.window)

	glfw.SetWindowUserPointer(state.window, state)
	glfw.SetFramebufferSizeCallback(state.window, size_callback)
	glfw.SetWindowIconifyCallback(state.window, iconify_callback)

	wgpu.set_log_callback(_log_callback, nil)
	wgpu.set_log_level(.Warn)

	instance_descriptor := wgpu.Instance_Descriptor {
		backends             = wgpu.Instance_Backend_Primary,
	}

	instance := wgpu.create_instance(instance_descriptor) or_return
	defer wgpu.instance_release(instance)

	surface_descriptor := wgpu_glfw.get_surface_descriptor(state.window) or_return
	state.surface = wgpu.instance_create_surface(instance, surface_descriptor) or_return
	defer if !ok do wgpu.surface_release(state.surface)

	adapter_options := wgpu.Request_Adapter_Options {
		power_preference       = .High_Performance,
		compatible_surface     = state.surface,
		force_fallback_adapter = false,
	}

	adapter := wgpu.instance_request_adapter(instance, adapter_options) or_return
	defer wgpu.adapter_release(adapter)

	adapter_info := wgpu.adapter_get_info(adapter) or_return
	defer wgpu.adapter_info_free_members(adapter_info)

	device_descriptor := wgpu.Device_Descriptor {
		label           = adapter_info.description,
		required_limits = wgpu.DEFAULT_LIMITS,
	}

	state.device = wgpu.adapter_request_device(adapter, device_descriptor) or_return
	defer if !ok do wgpu.device_release(state.device)

	state.queue = wgpu.device_get_queue(state.device)
	defer if !ok do wgpu.queue_release(state.queue)

	caps := wgpu.surface_get_capabilities(state.surface, adapter) or_return
	defer wgpu.surface_capabilities_free_members(caps)

	width, height := glfw.GetWindowSize(state.window)

	state.config = {
		usage        = {.Render_Attachment},
		format       = caps.formats[0],
		width        = cast(u32)width,
		height       = cast(u32)height,
		present_mode = .Fifo,
		alpha_mode   = caps.alpha_modes[0],
	}

	wgpu.surface_configure(state.surface, state.device, state.config) or_return

	return state, true
}

deinit :: proc(using state: ^State) {
	wgpu.queue_release(queue)
	wgpu.device_release(device)
	wgpu.surface_release(surface)
	glfw.DestroyWindow(window)
	glfw.Terminate()
	free(state)
}

render :: proc(using state: ^State) -> bool {
	frame := wgpu.surface_get_current_texture(state.surface) or_return
	defer wgpu.texture_release(frame.texture)

	view := wgpu.texture_create_view(frame.texture) or_return
	defer wgpu.texture_view_release(view)

	encoder := wgpu.device_create_command_encoder(
		state.device,
		wgpu.Command_Encoder_Descriptor{label = "Command Encoder"},
	) or_return
	defer wgpu.command_encoder_release(encoder)

	render_pass := wgpu.command_encoder_begin_render_pass(
		encoder,
		{
			label = "Render Pass",
			color_attachments = []wgpu.Render_Pass_Color_Attachment {
				{
					view = view,
					resolve_target = nil,
					load_op = .Clear,
					store_op = .Store,
					clear_value = {0.1, 0.2, 0.3, 1.0},
				},
			},
			depth_stencil_attachment = nil,
		},
	)
	defer wgpu.render_pass_release(render_pass)
	wgpu.render_pass_end(render_pass) or_return

	command_buffer := wgpu.command_encoder_finish(encoder) or_return
	defer wgpu.command_buffer_release(command_buffer)

	wgpu.queue_submit(queue, command_buffer)
	wgpu.surface_present(surface)

	return true
}

resize_surface :: proc(state: ^State, size: Physical_Size) -> bool {
	if size.width == 0 && size.height == 0 {
		return true
	}

	state.config.width = size.width
	state.config.height = size.height

	wgpu.surface_unconfigure(state.surface)
	wgpu.surface_configure(state.surface, state.device, state.config) or_return

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
	if !state_ok do return
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
