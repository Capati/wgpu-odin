package framework

// Core
import "core:fmt"
import "core:mem"
import "core:runtime"
import "core:strings"

// Vendor
import sdl "vendor:sdl2"

// Package
import wgpu "../../wrapper"
import wgpu_sdl "../../utils/sdl"

Mouse_Motion :: sdl.MouseMotionEvent
Keyboard_Event :: sdl.KeyboardEvent

Physical_Size :: struct {
    width:  u32,
    height: u32,
}

Window_Mode :: enum {
    Default,
    Fullscreen,
    Fullscreen_Borderless,
    Fullscreen_Stretch,
}

Properties :: struct {
    title:     cstring,
    mode:      Window_Mode,
    centered:  bool,
    resizable: bool,
    decorated: bool,
    vsync:     bool,
    size:      Physical_Size,
}

default_properties := Properties {
    title = "Example",
    mode = .Default,
    centered = true,
    resizable = true,
    decorated = true,
    vsync = true,
    size = {width = 800, height = 600},
}

Init_Error :: enum {
    No_Error,
    Allocator_Error,
    Gpu_Failed,
    Window_Failed,
}

State :: struct {
    window:               ^sdl.Window,
    instance:             wgpu.Instance,
    surface:              wgpu.Surface,
    adapter:              wgpu.Adapter,
    device:               wgpu.Device,
    config:               wgpu.Surface_Configuration,
    swap_chain:           wgpu.Swap_Chain,
    frame:                wgpu.Texture_View,
    minimized:            bool,
    delta:                f64,
    render_proc:          proc(state: ^State) -> wgpu.Error_Type,
    resized_proc:         proc(state: ^State, size: Physical_Size) -> wgpu.Error_Type,
    on_mouse_motion_proc: proc(state: ^State, motion: Mouse_Motion),
    on_key_down_proc:     proc(state: ^State, event: Keyboard_Event),
    on_key_up_proc:       proc(state: ^State, event: Keyboard_Event),
}

state_ctx: State
state_context := &state_ctx

init :: proc(properties: Properties) -> (state: ^State, err: Init_Error) {
    state_err: mem.Allocator_Error = .None
    if state_context, state_err = new(State); state_err != .None {
        fmt.eprintf("Failed to initialize state: [%s]\n", state_err)
        return nil, .Allocator_Error
    }
    defer if err != .No_Error do free(state_context)

    fmt.println("window init...")

    sdl_flags := sdl.InitFlags{.VIDEO, .JOYSTICK, .GAMECONTROLLER, .EVENTS}

    if res := sdl.Init(sdl_flags); res != 0 {
        fmt.eprintf("Failed to initialize SDL: [%s]\n", sdl.GetError())
        return nil, .Window_Failed
    }

    current_mode: sdl.DisplayMode
    if res := sdl.GetCurrentDisplayMode(0, &current_mode); res != 0 {
        fmt.eprintf("Failed to get current display mode: [%s]\n", sdl.GetError())
        return nil, .Window_Failed
    }

    physical_size: Physical_Size = {
        width  = properties.size.width,
        height = properties.size.height,
    }

    // Window is hidden by default, defer shown afer initialize everything,
    // this can avoid blank screen at start
    window_flags: sdl.WindowFlags = {.ALLOW_HIGHDPI, .HIDDEN}

    if properties.mode == .Default {
        if properties.resizable {
            window_flags += {.RESIZABLE}
        }

        if !properties.decorated {
            window_flags += {.BORDERLESS}
        }
    } else {
        window_flags += {.BORDERLESS}
    }

    #partial switch properties.mode {
    case .Fullscreen:
        fallthrough
    case .Fullscreen_Borderless:
        physical_size.width = cast(u32)current_mode.w
        physical_size.height = cast(u32)current_mode.h
    case:
    }

    #partial switch properties.mode {
    case .Fullscreen:
        fallthrough
    case .Fullscreen_Stretch:
        window_flags += {.FULLSCREEN}
    case:
    }

    window_pos := sdl.WINDOWPOS_UNDEFINED
    if properties.centered {
        window_pos = sdl.WINDOWPOS_CENTERED
    }

    state_context.window = sdl.CreateWindow(
        properties.title,
        cast(i32)window_pos,
        cast(i32)window_pos,
        cast(i32)physical_size.width,
        cast(i32)physical_size.height,
        window_flags,
    )
    if state_context.window == nil {
        fmt.eprintf("Failed to create a SDL window: [%s]\n", sdl.GetError())
        return nil, .Window_Failed
    }
    defer if err == .No_Error {
        sdl.ShowWindow(state_context.window)
        // Ensure "centered" on fullscreen borderless
        if properties.mode == .Fullscreen_Borderless {
            sdl.SetWindowPosition(state_context.window, 0, 0)
        }
    }

    fmt.printf("Window created successfully.\n\n")
    fmt.printf("GPU init...\n")

    wgpu.set_log_callback(_log_callback, nil)
    wgpu.set_log_level(.Warn)

    instance_descriptor := wgpu.Instance_Descriptor {
        backends             = wgpu.Instance_Backend_Primary,
        dx12_shader_compiler = wgpu.Dx12_Compiler_Default,
    }

    gpu_err: wgpu.Error_Type

    state_context.instance, gpu_err = wgpu.create_instance(&instance_descriptor)
    if gpu_err != .No_Error {
        fmt.eprintf(
            "Failed to create GPU Instance [%v]: %s\n",
            gpu_err,
            wgpu.get_error_message(),
        )
        return nil, .Gpu_Failed
    }

    surface_descriptor, surface_descriptor_err := wgpu_sdl.get_surface_descriptor(
        state_context.window,
    )
    if surface_descriptor_err != .No_Error {
        fmt.eprintf("Failed to create a surface descriptor\n")
        return nil, .Gpu_Failed
    }
    state_context.surface, gpu_err =
    state_context.instance->create_surface(&surface_descriptor)
    defer if err != .No_Error do state_context.surface->release()

    state_context.adapter, gpu_err =
    state_context.instance->request_adapter(
        &{
            power_preference = .High_Performance,
            compatible_surface = &state_context.surface,
            force_fallback_adapter = false,
        },
    )
    if gpu_err != .No_Error {
        fmt.eprintf(
            "Failed to create GPU Adapter [%v]: %s\n",
            gpu_err,
            wgpu.get_error_message(),
        )
        return nil, .Gpu_Failed
    }

    limits := wgpu.Default_Limits

    device_descriptor := wgpu.Device_Descriptor {
        label  = state_context.adapter.info.name,
        limits = limits,
    }

    state_context.device, gpu_err =
    state_context.adapter->request_device(&device_descriptor)
    if gpu_err != .No_Error {
        fmt.eprintf(
            "Failed to create GPU Device [%v]: %s\n",
            gpu_err,
            wgpu.get_error_message(),
        )
        return nil, .Gpu_Failed
    }
    defer if err != .No_Error do state_context.device->release()

    defer if err == .No_Error {
        state_context.device->set_uncaptured_error_callback(
            proc "c" (type: wgpu.Error_Type, message: cstring, user_data: rawptr) {
                context = runtime.default_context()
                fmt.eprintln("ERROR: ", message)
            },
            nil,
        )
    }

    caps, caps_err := state_context.surface->get_capabilities(state_context.adapter)
    if caps_err != .No_Error {
        fmt.eprintf(
            "Failed to get surface capabilities [%v]: %s\n",
            caps_err,
            wgpu.get_error_message(),
        )
        return nil, .Gpu_Failed
    }
    defer {
        delete(caps.formats)
        delete(caps.present_modes)
        delete(caps.alpha_modes)
    }

    width, height: i32
    sdl.GetWindowSize(state_context.window, &width, &height)

    surface_format := state_context.surface->get_preferred_format(&state_context.adapter)

    state_context.config = {
        usage = {.Render_Attachment},
        format = surface_format,
        width = cast(u32)width,
        height = cast(u32)height,
        present_mode = .Fifo,
        alpha_mode = caps.alpha_modes[0],
    }

    state_context.swap_chain, gpu_err =
    state_context.device->create_swap_chain(
        &state_context.surface,
        &state_context.config,
    )
    if gpu_err != .No_Error {
        fmt.eprintf(
            "Failed to create Swap Chain [%v]: %s\n",
            gpu_err,
            wgpu.get_error_message(),
        )
        return nil, .Gpu_Failed
    }

    fmt.printf("GPU init successfully.\n\n")

    return state_context, .No_Error
}

resize_surface :: proc(
    size: Physical_Size,
    using state := state_context,
) -> wgpu.Error_Type {
    if size.width == 0 && size.height == 0 {
        return .No_Error
    }

    if state.resized_proc != nil {
        state.resized_proc(state, size) or_return
    }

    state.config.width = size.width
    state.config.height = size.height

    if state.swap_chain.ptr != nil {
        state.swap_chain->release()
    }

    state.swap_chain = state.device->create_swap_chain(
        &state.surface,
        &state.config,
    ) or_return

    return .No_Error
}

Max_Texture_Attempts :: 5

begin_run :: proc(using state := state_context) {
    fmt.println("Entering render loop..")

    err: wgpu.Error_Type = .No_Error

    current_texture_attempts := 0
    // last_ticks := sdl.GetTicks()
    last_time := cast(f64)sdl.GetPerformanceCounter()

    main_loop: for {
        // now_ticks := sdl.GetTicks()
        // delta = f64(now_ticks - last_ticks) * 0.001
        // last_ticks = now_ticks

        delta =
            (cast(f64)sdl.GetPerformanceCounter() - last_time) /
            cast(f64)sdl.GetPerformanceFrequency()
        last_time = cast(f64)sdl.GetPerformanceCounter()

        e: sdl.Event

        for sdl.PollEvent(&e) {
            #partial switch (e.type) {
            case .QUIT:
                break main_loop

            case .WINDOWEVENT:
                #partial switch (e.window.event) {
                case .SIZE_CHANGED:
                case .RESIZED:
                    err = resize_surface(
                        {cast(u32)e.window.data1, cast(u32)e.window.data2},
                        state,
                    )
                    if err != .No_Error do break main_loop

                case .MINIMIZED:
                    state.minimized = true

                case .RESTORED:
                    state.minimized = false
                }

            case .KEYDOWN:
                if state.on_key_down_proc != nil {
                    state.on_key_down_proc(state, e.key)
                }

            case .KEYUP:
                if state.on_key_up_proc != nil {
                    state.on_key_up_proc(state, e.key)
                }

            case .MOUSEMOTION:
                if state.on_mouse_motion_proc != nil {
                    state.on_mouse_motion_proc(state, e.motion)
                }
            }
        }

        if state.minimized || state.render_proc == nil {
            continue main_loop
        }

        state.frame, err = state.swap_chain->get_current_texture_view()

        // Handle suboptimal surface
        if err != .No_Error {
            message := wgpu.get_error_message()

            if strings.contains(message, "Surface timed out") ||
               strings.contains(message, "Surface is outdated") ||
               strings.contains(message, "Surface was lost") {
                // Release suboptimal frame before skip/break loop
                if state.frame.ptr != nil {
                    state.frame->release()
                }

                width, height: i32
                sdl.GetWindowSize(state.window, &width, &height)

                if (width == 0 && height == 0) ||
                   state.config.width == u32(width) &&
                       state.config.height == u32(height) {
                    // skip current frame
                    continue main_loop
                }

                current_texture_attempts += 1

                if current_texture_attempts > Max_Texture_Attempts {
                    break main_loop
                }

                fmt.printf(
                    "Suboptimal surface, attempting %d/%d to acquire new texture...\n",
                    current_texture_attempts,
                    Max_Texture_Attempts,
                )

                fmt.println(message)

                resize_surface({cast(u32)width, cast(u32)height}, state)

                // skip current frame
                continue main_loop
            } else {
                break main_loop
            }
        } else {
            current_texture_attempts = 0
        }
        defer state.frame->release()

        err = state.render_proc(state)
        if err != .No_Error do break main_loop
    }

    if err != .No_Error {
        fmt.eprintf("Error occurred while rendering!\n")
    }

    fmt.println("Exiting...")
}

deinit :: proc(using state := state_context) {
    swap_chain->release()
    device->release()
    surface->release()
    adapter->release()
    instance->release()

    sdl.DestroyWindow(window)
    sdl.Quit()

    free(state)
}

@(private)
_log_callback :: proc "c" (level: wgpu.Log_Level, message: cstring, user_data: rawptr) {
    context = runtime.default_context()
    fmt.eprintf("[wgpu] [%v] %s\n\n", level, message)
}
