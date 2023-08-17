package cube

// Core
import "core:fmt"
import "core:math"
import la "core:math/linalg"
// import "core:math/linalg/glsl"
import "core:runtime"

// Vendor
import sdl "vendor:sdl2"

// Package
import wgpu "../../wrapper"
import wgpu_sdl "../../utils/sdl"

State :: struct {
    minimized:      bool,
    surface:        wgpu.Surface,
    swap_chain:     wgpu.Swap_Chain,
    device:         wgpu.Device,
    config:         wgpu.Surface_Configuration,
    vertex_buffer:  wgpu.Buffer,
    index_buffer:   wgpu.Buffer,
    uniform_buffer: wgpu.Buffer,
    pipeline:       wgpu.Render_Pipeline,
    bind_group:     wgpu.Bind_Group,
}

Physical_Size :: struct {
    width:  u32,
    height: u32,
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

Texel_Size :: 256

create_texels :: proc() -> (texels: [Texel_Size * Texel_Size]u8) {
    for id := 0; id < (Texel_Size * Texel_Size); id += 1 {
        cx := 3.0 * f32(id % Texel_Size) / f32(Texel_Size - 1) - 2.0
        cy := 2.0 * f32(id / Texel_Size) / f32(Texel_Size - 1) - 1.0
        x, y, count := f32(cx), f32(cy), u8(0)
        for count < 0xFF && x * x + y * y < 4.0 {
            old_x := x
            x = x * x - y * y + cx
            y = 2.0 * old_x * y + cy
            count += 1
        }
        texels[id] = count
    }

    return
}

generate_matrix :: proc(aspect_ratio: f32) -> la.Matrix4f32 {
    projection := la.matrix4_perspective_f32(math.PI / 4, aspect_ratio, 1.0, 10.0)
    view := la.matrix4_look_at_f32(
        eye = {1.5, -5.0, 3.0},
        centre = {0.0, 0.0, 0.0},
        up = {0.0, 0.0, 1.0},
    )
    return la.mul(projection, view)
}

// generate_matrix :: proc(aspect_ratio: f32) -> glsl.mat4 {
//     projection := glsl.mat4Perspective(math.PI / 4, aspect_ratio, 1.0, 10.0)
//     view := glsl.mat4LookAt({1.5, -5.0, 3.0}, {0.0, 0.0, 0.0}, {0.0, 0.0, 1.0})
//     return projection * view
// }

init_state := proc(window: ^sdl.Window) -> (s: State, err: wgpu.Error_Type) {
    state := State{}

    instance_descriptor := wgpu.Instance_Descriptor {
        backends             = wgpu.Instance_Backend_Primary,
        dx12_shader_compiler = wgpu.Dx12_Compiler_Default,
    }

    instance := wgpu.create_instance(&instance_descriptor) or_return
    defer instance->release()

    surface_descriptor := wgpu_sdl.get_surface_descriptor(window) or_return
    state.surface = instance->create_surface(&surface_descriptor) or_return
    defer if err != .No_Error do state.surface->release()

    adapter_options := wgpu.Request_Adapter_Options {
        power_preference       = .High_Performance,
        compatible_surface     = &state.surface,
        force_fallback_adapter = false,
    }

    adapter := instance->request_adapter(&adapter_options) or_return
    defer adapter->release()

    device_descriptor := wgpu.Device_Descriptor {
        label  = adapter.info.name,
        limits = wgpu.Default_Limits,
    }

    state.device = adapter->request_device(&device_descriptor) or_return
    defer if err != .No_Error do state.device->release()

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
        format = state.surface->get_preferred_format(&adapter),
        width = cast(u32)width,
        height = cast(u32)height,
        present_mode = .Fifo,
        alpha_mode = caps.alpha_modes[0],
    }

    state.swap_chain = state.device->create_swap_chain(
        &state.surface,
        &state.config,
    ) or_return
    defer if err != .No_Error do state.swap_chain->release()

    state.vertex_buffer = state.device->create_buffer_with_data(
        &{
            label = "Vertex Buffer",
            contents = wgpu.to_bytes(vertex_data),
            usage = {.Vertex},
        },
    ) or_return
    defer if err != .No_Error do state.vertex_buffer->release()

    state.index_buffer = state.device->create_buffer_with_data(
        &{
            label = "Index Buffer",
            contents = wgpu.to_bytes(index_data),
            usage = {.Index},
        },
    ) or_return
    defer if err != .No_Error do state.index_buffer->release()

    texels := create_texels()
    texture_extent := wgpu.Extent_3D {
        width                 = Texel_Size,
        height                = Texel_Size,
        depth_or_array_layers = 1,
    }
    texture := state.device->create_texture(
        &{
            size = texture_extent,
            mip_level_count = 1,
            sample_count = 1,
            dimension = ._2D,
            format = .R8_Uint,
            usage = {.Texture_Binding, .Copy_Dst},
        },
    ) or_return
    defer texture->release()

    texture_view := texture->create_view(nil) or_return
    defer texture_view->release()

    state.device.queue->write_texture(
        &{texture = &texture, mip_level = 0, origin = {}, aspect = .All},
        wgpu.to_bytes(texels),
        &{
            offset = 0,
            bytes_per_row = Texel_Size,
            rows_per_image = cast(u32)wgpu.Copy_Stride_Undefined,
        },
        &texture_extent,
    ) or_return

    mx_total := generate_matrix(
        cast(f32)state.config.width / cast(f32)state.config.height,
    )

    fmt.printf("%#v\n", mx_total)

    state.uniform_buffer = state.device->create_buffer_with_data(
        &{
            label = "Uniform Buffer",
            contents = wgpu.to_bytes(mx_total),
            usage = {.Uniform, .Copy_Dst},
        },
    ) or_return
    defer if err != .No_Error do state.uniform_buffer->release()

    shader := state.device->load_wgsl_shader_module(
        "assets/cube.wgsl",
        "shader.wgsl",
    ) or_return
    defer shader->release()

    vertex_buffer_layout := wgpu.Vertex_Buffer_Layout {
        array_stride = size_of(Vertex),
        step_mode = .Vertex,
        attributes = {
            {format = .Float32x4, offset = 0, shader_location = 0},
            {
                format = .Float32x2,
                offset = cast(u64)offset_of(Vertex, tex_coords),
                shader_location = 1,
            },
        },
    }

    state.pipeline = state.device->create_render_pipeline(
        &{
            vertex = {
                module = &shader,
                entry_point = "vs_main",
                buffers = {vertex_buffer_layout},
            },
            fragment = &{
                module = &shader,
                entry_point = "fs_main",
                targets = {
                    {
                        format = state.config.format,
                        blend = nil,
                        write_mask = wgpu.Color_Write_Mask_All,
                    },
                },
            },
            primitive = {
                topology = .Triangle_List,
                front_face = .CCW,
                cull_mode = .Back,
            },
            depth_stencil = nil,
            multisample = wgpu.Multisample_State_Default,
        },
    ) or_return
    defer if err != .No_Error do state.pipeline->release()

    bind_group_layout := state.pipeline->get_bind_group_layout(0) or_return
    defer bind_group_layout->release()

    state.bind_group = state.device->create_bind_group(
        &{
            layout = &bind_group_layout,
            entries = {
                {binding = 0, buffer = &state.uniform_buffer, size = wgpu.Whole_Size},
                {binding = 1, texture_view = &texture_view, size = wgpu.Whole_Size},
            },
        },
    ) or_return

    return state, .No_Error
}

resize_window :: proc(state: ^State, size: Physical_Size) -> wgpu.Error_Type {
    if size.width == 0 && size.height == 0 {
        return .No_Error
    }

    state.config.width = size.width
    state.config.height = size.height

    mx_total := generate_matrix(
        cast(f32)state.config.width / cast(f32)state.config.height,
    )
    state.device.queue->write_buffer(
        &state.uniform_buffer,
        0,
        wgpu.to_bytes(mx_total),
    ) or_return

    if state.swap_chain.ptr != nil {
        state.swap_chain->release()
    }

    state.swap_chain = state.device->create_swap_chain(
        &state.surface,
        &state.config,
    ) or_return

    return .No_Error
}

render :: proc(state: ^State) -> wgpu.Error_Type {
    next_texture := state.swap_chain->get_current_texture_view() or_return
    defer next_texture->release()

    encoder := state.device->create_command_encoder(
        &wgpu.Command_Encoder_Descriptor{label = "Command Encoder"},
    ) or_return
    defer encoder->release()

    render_pass := encoder->begin_render_pass(
        &{
            label = "Render Pass",
            color_attachments = []wgpu.Render_Pass_Color_Attachment{
                {
                    view = &next_texture,
                    resolve_target = nil,
                    load_op = .Clear,
                    store_op = .Store,
                    clear_value = {0.1, 0.2, 0.3, 1.0},
                },
            },
            depth_stencil_attachment = nil,
        },
    )
    defer render_pass->release()

    render_pass->set_pipeline(&state.pipeline)
    render_pass->set_bind_group(0, &state.bind_group, nil)
    render_pass->set_index_buffer(state.index_buffer, .Uint16, 0, wgpu.Whole_Size)
    render_pass->set_vertex_buffer(0, state.vertex_buffer, 0, wgpu.Whole_Size)
    render_pass->draw_indexed(cast(u32)len(index_data), 1, 0, 0, 0)
    render_pass->end() or_return

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
        "Cube",
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
            fmt.eprintln("ERROR: Failed to initialize program:", message)
        } else {
            fmt.eprintln("ERROR: Failed to initialize program")
        }
        return
    }
    defer {
        state.bind_group->release()
        state.pipeline->release()
        state.uniform_buffer->release()
        state.index_buffer->release()
        state.vertex_buffer->release()
        state.device->release()
        state.swap_chain->release()
        state.surface->release()
    }

    err := wgpu.Error_Type{}

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
                        {cast(u32)e.window.data1, cast(u32)e.window.data2},
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
