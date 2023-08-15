package tutorial5_textures

// Core
import "core:bytes"
import "core:fmt"
import "core:runtime"

// Vendor
import sdl "vendor:sdl2"

// Package
import wgpu "../../../../wrapper"
import wgpu_sdl "../../../../utils/sdl"

Vertex :: struct {
    position:   [3]f32,
    tex_coords: [2]f32,
}

State :: struct {
    minimized:          bool,
    surface:            wgpu.Surface,
    swap_chain:         wgpu.Swap_Chain,
    device:             wgpu.Device,
    config:             wgpu.Surface_Configuration,
    render_pipeline:    wgpu.Render_Pipeline,
    vertex_buffer:      wgpu.Buffer,
    index_buffer:       wgpu.Buffer,
    num_indices:        u32,
    diffuse_texture:    Texture,
    diffuse_bind_group: wgpu.Bind_Group,
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

    surface_format := state.surface->get_preferred_format(&adapter)

    state.config = {
        usage = {.Render_Attachment},
        format = surface_format,
        width = cast(u32)width,
        height = cast(u32)height,
        present_mode = .Fifo,
        alpha_mode = caps.alpha_modes[0],
    }

    state.swap_chain = state.device->create_swap_chain(
        &state.surface,
        &state.config,
    ) or_return

    // Load our tree image to texture
    state.diffuse_texture = texture_from_image(
        &state.device,
        "assets/learn_wgpu/tutorial5/happy-tree.png",
    ) or_return
    defer if err != .No_Error do texture_destroy(&state.diffuse_texture)

    texture_bind_group_layout := state.device->create_bind_group_layout(
        &{
            label = "TextureBindGroupLayout",
            entries = {
                {
                    binding = 0,
                    visibility = {.Fragment},
                    texture = {
                        multisampled = false,
                        view_dimension = ._2D,
                        sample_type = .Float,
                    },
                },
                {binding = 1, visibility = {.Fragment}, sampler = {type = .Filtering}},
            },
        },
    ) or_return
    defer texture_bind_group_layout->release()

    state.diffuse_bind_group = state.device->create_bind_group(
        &wgpu.Bind_Group_Descriptor{
            label = "diffuse_bind_group",
            layout = &texture_bind_group_layout,
            entries = {
                {binding = 0, texture_view = &state.diffuse_texture.view},
                {binding = 1, sampler = &state.diffuse_texture.sampler},
            },
        },
    ) or_return
    defer if err != .No_Error do state.diffuse_bind_group->release()

    render_pipeline_layout := state.device->create_pipeline_layout(
        &{
            label = "Render Pipeline Layout",
            bind_group_layouts = {texture_bind_group_layout},
        },
    ) or_return
    defer render_pipeline_layout->release()

    vertex_buffer_layout := wgpu.Vertex_Buffer_Layout {
        array_stride = size_of(Vertex),
        step_mode = .Vertex,
        attributes = {
            {offset = 0, shader_location = 0, format = .Float32x3},
            {
                offset = cast(u64)offset_of(Vertex, tex_coords),
                shader_location = 1,
                format = .Float32x2,
            },
        },
    }

    shader := state.device->load_wgsl_shader_module(
        "assets/learn_wgpu/tutorial5/shader.wgsl",
        "shader.wgsl",
    ) or_return
    defer shader->release()

    render_pipeline_descriptor := wgpu.Render_Pipeline_Descriptor {
        label = "Render Pipeline",
        layout = &render_pipeline_layout,
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
                    blend = &wgpu.Blend_State_Replace,
                    write_mask = wgpu.Color_Write_Mask_All,
                },
            },
        },
        primitive = {topology = .Triangle_List, front_face = .CCW, cull_mode = .None},
        depth_stencil = nil,
        multisample = {count = 1, mask = ~u32(0), alpha_to_coverage_enabled = false},
    }

    state.render_pipeline = state.device->create_render_pipeline(
        &render_pipeline_descriptor,
    ) or_return

    vertices := []Vertex {
        {
            position = {-0.0868241, 0.49240386, 0.0},
            tex_coords = {0.4131759, 0.00759614},
        }, // A
        {
            position = {-0.49513406, 0.06958647, 0.0},
            tex_coords = {0.0048659444, 0.43041354},
        }, // B
        {
            position = {-0.21918549, -0.44939706, 0.0},
            tex_coords = {0.28081453, 0.949397},
        }, // C
        {position = {0.35966998, -0.3473291, 0.0}, tex_coords = {0.85967, 0.84732914}}, // D
        {position = {0.44147372, 0.2347359, 0.0}, tex_coords = {0.9414737, 0.2652641}}, // E
    }

    indices: []u16 = {0, 1, 4, 1, 2, 4, 2, 3, 4}

    state.num_indices = cast(u32)len(indices)

    state.vertex_buffer = state.device->create_buffer_with_data(
        &wgpu.Buffer_Data_Descriptor{
            label = "Vertex Buffer",
            contents = wgpu.to_bytes(vertices),
            usage = {.Vertex},
        },
    ) or_return

    state.index_buffer = state.device->create_buffer_with_data(
        &wgpu.Buffer_Data_Descriptor{
            label = "Index Buffer",
            contents = wgpu.to_bytes(indices),
            usage = {.Index},
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

    render_pass->set_pipeline(&state.render_pipeline)
    render_pass->set_bind_group(0, &state.diffuse_bind_group)
    render_pass->set_vertex_buffer(0, state.vertex_buffer)
    render_pass->set_index_buffer(state.index_buffer, .Uint16, 0, wgpu.Whole_Size)
    render_pass->draw_indexed(state.num_indices)
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
        "Tutorial 5 - Textures",
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
        state.render_pipeline->release()
        state.index_buffer->release()
        state.vertex_buffer->release()
        state.diffuse_bind_group->release()
        texture_destroy(&state.diffuse_texture)
        state.swap_chain->release()
        state.device->release()
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
