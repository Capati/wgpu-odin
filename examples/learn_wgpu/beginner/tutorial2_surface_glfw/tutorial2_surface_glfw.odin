package tutorial2_surface_glfw

// Base
import "base:runtime"

import "core:fmt"
import "core:mem"

// Vendor
import "vendor:glfw"

// Package
import wgpu_glfw "../../../../utils/glfw"
import wgpu "../../../../wrapper"

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

Error :: union #shared_nil {
	wgpu.Error,
	mem.Allocator_Error,
}

_log_callback :: proc "c" (level: wgpu.Log_Level, message: cstring, user_data: rawptr) {
	context = runtime.default_context()
	fmt.eprintf("[wgpu] [%v] %s\n\n", level, message)
}

init :: proc() -> (state: ^State, err: Error) {
	state = new(State) or_return
	defer if err != nil do free(state)

	if !glfw.Init() {
		panic("[glfw] init failure")
	}
	defer if err != nil do glfw.Terminate()

	glfw.WindowHint(glfw.CLIENT_API, glfw.NO_API)
	state.window = glfw.CreateWindow(800, 600, "Tutorial 1 - Window", nil, nil)
	defer if err != nil do glfw.DestroyWindow(state.window)

	glfw.SetWindowUserPointer(state.window, state)
	glfw.SetFramebufferSizeCallback(state.window, size_callback)
	glfw.SetWindowIconifyCallback(state.window, iconify_callback)

	wgpu.set_log_callback(_log_callback, nil)
	wgpu.set_log_level(.Warn)

	instance_descriptor := wgpu.Instance_Descriptor {
		backends             = wgpu.Instance_Backend_Primary,
		dx12_shader_compiler = wgpu.DEFAULT_DX12_COMPILER,
	}

	instance := wgpu.create_instance(instance_descriptor) or_return
	defer wgpu.instance_release(instance)

	surface_descriptor := wgpu_glfw.get_surface_descriptor(state.window) or_return
	state.surface = wgpu.instance_create_surface(instance, surface_descriptor) or_return
	defer if err != nil do wgpu.surface_release(state.surface)

	adapter_options := wgpu.Request_Adapter_Options {
		power_preference       = .High_Performance,
		compatible_surface     = state.surface.ptr,
		force_fallback_adapter = false,
	}

	adapter := wgpu.instance_request_adapter(instance, adapter_options) or_return
	defer wgpu.adapter_release(adapter)

	device_descriptor := wgpu.Device_Descriptor {
		label           = adapter.info.name,
		required_limits = wgpu.DEFAULT_LIMITS,
	}

	state.device, state.queue = wgpu.adapter_request_device(adapter, device_descriptor) or_return
	defer if err != nil {
		wgpu.queue_release(state.queue)
		wgpu.device_release(state.device)
	}

	caps := wgpu.surface_get_capabilities(state.surface, adapter.ptr) or_return
	defer wgpu.surface_capabilities_free_members(caps)

	width, height := glfw.GetWindowSize(state.window)

	state.config = {
		usage        = {.Render_Attachment},
		format       = wgpu.surface_get_preferred_format(state.surface, adapter.ptr) or_return,
		width        = cast(u32)width,
		height       = cast(u32)height,
		present_mode = .Fifo,
		alpha_mode   = caps.alpha_modes[0],
	}

	wgpu.surface_configure(&state.surface, state.device, state.config) or_return

	return state, nil
}

deinit :: proc(using state: ^State) {
	wgpu.queue_release(queue)
	wgpu.device_release(device)
	wgpu.surface_release(surface)
	glfw.DestroyWindow(window)
	glfw.Terminate()
	free(state)
}

render :: proc(using state: ^State) -> wgpu.Error {
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
					view = view.ptr,
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

	wgpu.queue_submit(queue, command_buffer.ptr)
	wgpu.surface_present(surface)

	return nil
}

resize_surface :: proc(state: ^State, size: Physical_Size) -> wgpu.Error {
	if size.width == 0 && size.height == 0 {
		return nil
	}

	state.config.width = size.width
	state.config.height = size.height

	wgpu.surface_unconfigure(state.surface)
	wgpu.surface_configure(&state.surface, state.device, state.config) or_return

	return nil
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
	state, state_err := init()
	if state_err != nil do return
	defer deinit(state)

	for !glfw.WindowShouldClose(state.window) {
		glfw.PollEvents()

		if !state.minimized {
			if err := render(state); err != nil {
				glfw.SetWindowShouldClose(state.window, true)
			}
		}
	}

	fmt.println("Exiting...")
}
