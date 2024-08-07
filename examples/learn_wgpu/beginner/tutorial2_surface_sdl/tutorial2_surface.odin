package tutorial2_surface

// Base
import "base:runtime"

// Core
import "core:fmt"
import "core:mem"

// Vendor
import sdl "vendor:sdl2"

// Package
import wgpu_sdl "../../../../utils/sdl"
import wgpu "../../../../wrapper"

State :: struct {
	window:    ^sdl.Window,
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

	sdl_flags := sdl.InitFlags{.VIDEO, .JOYSTICK, .GAMECONTROLLER, .EVENTS}

	if res := sdl.Init(sdl_flags); res != 0 {
		fmt.eprintf("ERROR: Failed to initialize SDL: [%s]\n", sdl.GetError())
		return
	}
	defer if err != nil do sdl.Quit()

	window_flags: sdl.WindowFlags = {.SHOWN, .ALLOW_HIGHDPI, .RESIZABLE}

	state.window = sdl.CreateWindow(
		"Tutorial 2 - Surface",
		sdl.WINDOWPOS_CENTERED,
		sdl.WINDOWPOS_CENTERED,
		800,
		600,
		window_flags,
	)
	if state.window == nil {
		fmt.eprintf("ERROR: Failed to create the SDL Window: [%s]\n", sdl.GetError())
		return
	}
	defer if err != nil do sdl.DestroyWindow(state.window)

	wgpu.set_log_callback(_log_callback, nil)
	wgpu.set_log_level(.Warn)

	instance_descriptor := wgpu.Instance_Descriptor {
		backends             = wgpu.Instance_Backend_Primary,
		dx12_shader_compiler = wgpu.DEFAULT_DX12_COMPILER,
	}

	instance := wgpu.create_instance(instance_descriptor) or_return
	defer wgpu.instance_release(instance)

	surface_descriptor := wgpu_sdl.get_surface_descriptor(state.window) or_return
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

	width, height: i32
	sdl.GetWindowSize(state.window, &width, &height)

	state.config = {
		usage        = {.Render_Attachment},
		format       = wgpu.surface_get_preferred_format(state.surface, adapter.ptr) or_return,
		width        = cast(u32)width,
		height       = cast(u32)height,
		present_mode = .Fifo,
		alpha_mode   = caps.alpha_modes[0],
	}

	wgpu.surface_configure(&state.surface, state.device, state.config) or_return

	return
}

deinit :: proc(using state: ^State) {
	wgpu.queue_release(queue)
	wgpu.device_release(device)
	wgpu.surface_release(surface)
	sdl.DestroyWindow(window)
	sdl.Quit()
	free(state)
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

render :: proc(using state: ^State) -> (err: Error) {
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

main :: proc() {
	state, state_err := init()
	if state_err != nil do return
	defer deinit(state)

	main_loop: for {
		e: sdl.Event

		for sdl.PollEvent(&e) {
			#partial switch (e.type) {
			case .QUIT:
				break main_loop

			case .WINDOWEVENT:
				#partial switch (e.window.event) {
				case .SIZE_CHANGED:
				case .RESIZED:
					err := resize_surface(
						state,
						{cast(u32)e.window.data1, cast(u32)e.window.data2},
					)
					if err != nil do break main_loop

				case .MINIMIZED:
					state.minimized = true

				case .RESTORED:
					state.minimized = false
				}
			}
		}

		if !state.minimized {
			if err := render(state); err != nil do break main_loop
		}
	}

	fmt.println("Exiting...")
}
