package triangle

// Core
import "core:fmt"
import "core:runtime"

// Vendor
import sdl "vendor:sdl2"

// Package
import wgpu "../../wrapper"
import wgpu_sdl "../../utils/sdl"

TRIANGLE_MSAA_EXAMPLE :: #config(TRIANGLE_MSAA_EXAMPLE, false)

State :: struct {
    minimized:                bool,
    surface:                  wgpu.Surface,
    swap_chain:               wgpu.Swap_Chain,
    device:                   wgpu.Device,
    config:                   wgpu.Surface_Configuration,
    pipeline:                 wgpu.Render_Pipeline,
    multisampled_framebuffer: wgpu.Texture_View,
}

_log_callback :: proc "c" (level: wgpu.Log_Level, message: cstring, user_data: rawptr) {
    context = runtime.default_context()
    fmt.eprintf("[wgpu] [%v] %s\n\n", level, message)
}

@(init)
init :: proc() {
    wgpu.set_log_callback(_log_callback, nil)
    wgpu.set_log_level(.Warn)
}

init_state := proc(window: ^sdl.Window) -> (s: State, err: wgpu.Error_Type) {
    state := State{}

    // Instance
    instance_descriptor := wgpu.Instance_Descriptor {
        backends = wgpu.Instance_Backend_Primary,
    }

    instance := wgpu.create_instance(&instance_descriptor) or_return
    defer if err != .No_Error do instance->release()

    // Surface
    surface_descriptor := wgpu_sdl.get_surface_descriptor(window) or_return

    state.surface = instance->create_surface(&surface_descriptor) or_return
    defer if err != .No_Error do state.surface->release()

    // Adapter
    adapter := instance->request_adapter(
        &{compatible_surface = &state.surface, power_preference = .High_Performance},
    ) or_return
    defer adapter->release()

    // Device
    device_descriptor := wgpu.Device_Descriptor {
        label = adapter.info.name,
    }

    state.device = adapter->request_device(&device_descriptor) or_return
    defer if err != .No_Error do state.device->release()

    // Configure presentation
    caps := state.surface->get_capabilities(adapter) or_return
    defer {
        delete(caps.formats)
        delete(caps.present_modes)
        delete(caps.alpha_modes)
    }

    width, height: i32
    sdl.GetWindowSize(window, &width, &height)

    state.config = {
        usage = {.Render_Attachment},
        format = caps.formats[0],
        width = cast(u32)width,
        height = cast(u32)height,
        present_mode = .Fifo,
        alpha_mode = caps.alpha_modes[0],
    }

    state.swap_chain = state.device->create_swap_chain(
        &state.surface,
        &state.config,
    ) or_return

    // Shader module
    shader := state.device->load_wgsl_shader_module(
        "assets/triangle.wgsl",
        "Red triangle module",
    ) or_return
    defer shader->release()

    // Render pipeline
    pipeline_descriptor := wgpu.Render_Pipeline_Descriptor {
        label = "Render Pipeline",
        vertex = {module = &shader, entry_point = "vs"},
        fragment = &{
            module = &shader,
            entry_point = "fs",
            targets = {
                {
                    format = state.config.format,
                    blend = &wgpu.Blend_State_Replace,
                    write_mask = wgpu.Color_Write_Mask_All,
                },
            },
        },
    }

    if TRIANGLE_MSAA_EXAMPLE {
        fmt.println("Enabling 4x MSAA...")
        pipeline_descriptor.multisample = {
            count                     = 4,
            mask                      = ~u32(0), // 0xFFFFFFFF
            alpha_to_coverage_enabled = false,
        }
    } else {
        pipeline_descriptor.multisample = wgpu.Multisample_State_Default
    }

    state.pipeline = state.device->create_render_pipeline(&pipeline_descriptor) or_return
    defer if err != .No_Error do state.pipeline->release()

    when TRIANGLE_MSAA_EXAMPLE {
        state.multisampled_framebuffer = get_multisampled_framebuffer(
            &state.device,
            state.config.width,
            state.config.height,
            state.config.format,
        ) or_return
    }

    return state, .No_Error
}

when TRIANGLE_MSAA_EXAMPLE {
    get_multisampled_framebuffer :: proc(
        device: ^wgpu.Device,
        width, height: u32,
        format: wgpu.Texture_Format,
    ) -> (
        view: wgpu.Texture_View,
        err: wgpu.Error_Type,
    ) {
        texture := device->create_texture(
            &wgpu.Texture_Descriptor{
                usage = {.Render_Attachment},
                dimension = ._2D,
                size = {width = width, height = height, depth_or_array_layers = 1},
                format = format,
                mip_level_count = 1,
                sample_count = 4,
            },
        ) or_return

        defer texture->release()

        return texture->create_view(nil)
    }
}

resize_window :: proc(state: ^State, width, height: u32) -> wgpu.Error_Type {
    if width == 0 && height == 0 {
        return .No_Error
    }

    state.config.width = width
    state.config.height = height

    if state.swap_chain.ptr != nil {
        state.swap_chain->release()
    }

    state.swap_chain = state.device->create_swap_chain(
        &state.surface,
        &state.config,
    ) or_return

    when TRIANGLE_MSAA_EXAMPLE {
        state.multisampled_framebuffer->release()

        state.multisampled_framebuffer = get_multisampled_framebuffer(
            &state.device,
            state.config.width,
            state.config.height,
            state.config.format,
        ) or_return
    }

    return .No_Error
}

render :: proc(state: ^State) -> wgpu.Error_Type {
    next_texture := state.swap_chain->get_current_texture_view() or_return
    defer next_texture->release()

    encoder := state.device->create_command_encoder(
        &wgpu.Command_Encoder_Descriptor{label = "Command Encoder"},
    ) or_return
    defer encoder->release()

    when TRIANGLE_MSAA_EXAMPLE {
        colors: []wgpu.Render_Pass_Color_Attachment = {
            {view = &state.multisampled_framebuffer, resolve_target = &frame.view},
        }
    } else {
        colors: []wgpu.Render_Pass_Color_Attachment = {
            {view = &next_texture, resolve_target = nil},
        }
    }

    colors[0].load_op = .Clear
    colors[0].store_op = .Store
    colors[0].clear_value = wgpu.Color_Green

    render_pass := encoder->begin_render_pass(
        &{label = "Default render pass encoder", color_attachments = colors},
    )
    defer render_pass->release()

    render_pass->set_pipeline(&state.pipeline)
    render_pass->draw(3)
    render_pass->end()

    command_buffer := encoder->finish() or_return
    defer command_buffer->release()

    state.device.queue->submit(command_buffer)
    state.swap_chain->present()

    return .No_Error
}

main :: proc() {
    sdl_flags := sdl.InitFlags{.VIDEO, .JOYSTICK, .GAMECONTROLLER, .EVENTS}

    if res := sdl.Init(sdl_flags); res != 0 {
        fmt.eprintf("ERROR: Failed to initialize SDL: [%s]\n", sdl.GetError())
        return
    }
    defer sdl.Quit()

    window_flags: sdl.WindowFlags = {.SHOWN, .ALLOW_HIGHDPI, .RESIZABLE}

    sdl_window := sdl.CreateWindow(
        "WGPU Red Triangle",
        sdl.WINDOWPOS_CENTERED,
        sdl.WINDOWPOS_CENTERED,
        800,
        600,
        window_flags,
    )
    defer sdl.DestroyWindow(sdl_window)

    if sdl_window == nil {
        fmt.eprintf("ERROR: Failed to create the SDL Window: [%s]\n", sdl.GetError())
        return
    }

    state, state_err := init_state(sdl_window)
    if state_err != .No_Error {
        message := wgpu.get_error_message()
        if message != "" {
            fmt.eprintln("ERROR: Failed to initilize program:", message)
        } else {
            fmt.eprintln("ERROR: Failed to initilize program")
        }
        return
    }
    defer {
        when TRIANGLE_MSAA_EXAMPLE {
            state.multisampled_framebuffer->release()
        }

        state.pipeline->release()
        state.device->release()
        state.surface->release()
    }

    err: wgpu.Error_Type

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
                    err = resize_window(
                        &state,
                        cast(u32)e.window.data1,
                        cast(u32)e.window.data2,
                    )
                    if err != .No_Error do break main_loop

                case .MINIMIZED:
                    state.minimized = true

                case .RESTORED:
                    state.minimized = false
                }
            }
        }

        if !state.minimized {
            err = render(&state)
            if err != .No_Error do break main_loop
        }
    }

    if err != .No_Error {
        fmt.eprintf("Error occurred while rendering: %v\n", wgpu.get_error_message())
    }

    fmt.println("Exiting...")
}
