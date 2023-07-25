package triangle

// Core
import "core:os"
import "core:fmt"
import "core:runtime"

// Vendor
import sdl "vendor:sdl2"

// Package
import wgpu "../../"

Adapter_Response :: struct {
    status:  wgpu.Request_Adapter_Status,
    adapter: wgpu.Adapter,
}

Device_Response :: struct {
    status:  wgpu.Request_Device_Status,
    message: cstring,
    device:  wgpu.Device,
}

Next_Texture_Response :: struct {
    type:    wgpu.Error_Type,
    message: cstring,
}

Vertex :: struct {
    position: [2]f32,
    color:    [3]f32,
}

start :: proc() {
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
        fmt.eprintf("ERROR: Failed to create the SDL Platform: [%s]\n", sdl.GetError())
        return
    }

    sys_info: sdl.SysWMinfo
    sdl.GetVersion(&sys_info.version)

    if !sdl.GetWindowWMInfo(sdl_window, &sys_info) {
        fmt.eprintf(
            "ERROR: Could not obtain SDL WM info from window: [%s]\n",
            sdl.GetError(),
        )
    }

    // Create a instance descriptor.
    instance_descriptor := wgpu.Instance_Descriptor {
        next_in_chain = cast(^wgpu.Chained_Struct)&wgpu.Instance_Extras{backends = {.Primary}},
    }

    instance := wgpu.create_instance(&instance_descriptor)

    // Setup surface information
    surface_descriptor := wgpu.Surface_Descriptor {
        label         = nil,
        next_in_chain = nil,
    }

    when ODIN_OS == .Darwin {
        native_window := (^NS.Window)(sys_info.info.cocoa.window)

        metal_layer := CA.MetalLayer.layer()
        defer metal_layer->release()

        native_window->contentView()->setLayer(metal_layer)

        surface_descriptor.label = "Metal Layer"

        // Set surface descriptor
        surface_descriptor.next_in_chain =
        cast(^wgpu.Chained_Struct)&wgpu.Surface_Descriptor_From_Metal_Layer{
            chain = wgpu.Chained_Struct{
                next = nil,
                stype = .Surface_Descriptor_From_Metal_Layer,
            },
            layer = metal_layer,
        }
    } else when ODIN_OS == .Linux {
        wayland_value, found_wayland := os.lookup_env("WAYLAND_DISPLAY", allocator)
        defer delete(wayland_value)

        x11_value, found_x11 := os.lookup_env("DISPLAY", allocator)
        defer delete(x11_value)

        if (!found_wayland || wayland_value == "") && (!found_x11 || x11_value == "") {
            log.eprintf("ERROR: Unable to recognize the current desktop session.\n")
            return
        }

        // Set surface descriptor for Wayland or X11
        if found_wayland {
            surface_descriptor.label = "Wayland surface"

            surface_descriptor.next_in_chain =
            cast(^wgpu.Chained_Struct)&wgpu.Surface_Descriptor_From_Wayland_Surface{
                chain = wgpu.Chained_Struct{
                    next = nil,
                    stype = .Surface_Descriptor_From_Wayland_Surface,
                },
                display = sys_info.info.wl.display,
                surface = sys_info.info.wl.surface,
            }
        } else if found_x11 {
            surface_descriptor.label = "X11 Window"

            surface_descriptor.next_in_chain =
            cast(^wgpu.Chained_Struct)&wgpu.Surface_Descriptor_From_Xlib_Window{
                chain = wgpu.Chained_Struct{
                    next = nil,
                    stype = .Surface_Descriptor_From_Xlib_Window,
                },
                display = sys_info.info.x11.display,
                window = cast(c.uint32_t)sys_info.info.x11.window,
            }
        }
    } else when ODIN_OS == .Windows {
        surface_descriptor.label = "Windows HWND"

        // Set surface descriptor
        surface_descriptor.next_in_chain =
        cast(^wgpu.Chained_Struct)&wgpu.Surface_Descriptor_From_Windows_HWND{
            chain = wgpu.Chained_Struct{
                next = nil,
                stype = .Surface_Descriptor_From_Windows_HWND,
            },
            hinstance = sys_info.info.win.hinstance,
            hwnd = sys_info.info.win.window,
        }
    } else {
        fmt.eprintln("Current platform is not supported.")
        return
    }

    // Create a surface from raw window information
    surface := wgpu.instance_create_surface(instance, &surface_descriptor)
    defer wgpu.surface_release(surface)

    adapter_descriptor: wgpu.Request_Adapter_Options = {
        next_in_chain          = nil,
        compatible_surface     = surface,
        power_preference       = .High_Performance,
        force_fallback_adapter = false,
    }

    adapter_response := Adapter_Response{}
    wgpu.instance_request_adapter(
        instance,
        &adapter_descriptor,
        _on_request_adapter_callback,
        &adapter_response,
    )

    if adapter_response.status != .Success {
        fmt.eprintf("Failed to request adapter: [%v]\n", adapter_response.status)
    }

    adapter := adapter_response.adapter
    defer wgpu.adapter_release(adapter)

    adapter_info: wgpu.Adapter_Properties
    wgpu.adapter_get_properties(adapter, &adapter_info)

    // Print adapter information
    print_adapter_information(adapter_info)

    device_descriptor := wgpu.Device_Descriptor {
        next_in_chain = nil,
        label = adapter_info.name,
        required_features_count = 0,
        required_features = nil,
        default_queue = wgpu.Queue_Descriptor{
            next_in_chain = nil,
            label = "Default Queue",
        },
        device_lost_callback = _on_device_lost,
        device_lost_userdata = nil,
    }

    device_response := Device_Response{}
    wgpu.adapter_request_device(
        adapter,
        &device_descriptor,
        _on_adapter_request_device,
        &device_response,
    )

    if device_response.status != .Success {
        fmt.eprintf(
            "Failed to request a device: [%v] - %s\n",
            device_response.status,
            device_response.message,
        )
        return
    }

    device := device_response.device
    defer wgpu.device_release(device)

    queue := wgpu.device_get_queue(device)
    defer wgpu.queue_release(queue)

    surface_format := wgpu.surface_get_preferred_format(surface, adapter)

    surface_config := wgpu.Swap_Chain_Descriptor {
        label = "Main window swap chain",
        usage = {.Render_Attachment},
        format = surface_format,
        width = 800,
        height = 600,
        present_mode = .Fifo,
    }

    swapchain := wgpu.device_create_swap_chain(device, surface, &surface_config)

    loaded_shader, loaded_shader_ok := os.read_entire_file("triangle.wgsl")
    defer delete(loaded_shader)

    if !loaded_shader_ok {
        fmt.eprintf("Failed to load WGSL shader file: [%s]\n")
        return
    }

    wgsl_descriptor := wgpu.Shader_Module_WGSL_Descriptor {
        chain = {next = nil, stype = .Shader_Module_WGSL_Descriptor},
        code = cstring(raw_data(loaded_shader)),
    }

    shader_descriptor := wgpu.Shader_Module_Descriptor {
        next_in_chain = cast(^wgpu.Chained_Struct)&wgsl_descriptor,
        label         = "Triangle shader module",
    }

    shader_module := wgpu.device_create_shader_module(device, &shader_descriptor)
    defer wgpu.shader_module_release(shader_module)

    vertex_attributes: []wgpu.Vertex_Attribute = {
        {
            shader_location = 0,
            format = .Float32x2,
            offset = cast(u64)offset_of(Vertex, position),
        },
        {
            shader_location = 1,
            format = .Float32x3,
            offset = cast(u64)offset_of(Vertex, color),
        },
    }

    render_pipeline_desc := wgpu.Render_Pipeline_Descriptor {
        label = "Render Pipeline",
        layout = nil,
        vertex = {
            module = shader_module,
            entry_point = "vs_main",
            buffer_count = 1,
            buffers = &{
                array_stride = size_of(Vertex),
                attribute_count = cast(uint)len(vertex_attributes),
                step_mode = .Vertex,
                attributes = raw_data(vertex_attributes),
            },
        },
        primitive = {
            topology = .Triangle_List,
            strip_index_format = .Undefined,
            front_face = .CCW,
            cull_mode = .None,
        },
        multisample = {
            next_in_chain = nil,
            count = 1,
            mask = ~u32(0),
            alpha_to_coverage_enabled = false,
        },
        depth_stencil = nil,
        fragment = &{
            module = shader_module,
            entry_point = "fs_main",
            target_count = 1,
            targets = &{
                format = surface_format,
                blend = &{
                    color = {
                        src_factor = .Src_Alpha,
                        dst_factor = .One_Minus_Src_Alpha,
                        operation = .Add,
                    },
                    alpha = {src_factor = .Zero, dst_factor = .One, operation = .Add},
                },
                write_mask = wgpu.Color_Write_Mask_Flags_All,
            },
        },
    }

    render_pipeline := wgpu.device_create_render_pipeline(device, &render_pipeline_desc)
    defer wgpu.render_pipeline_release(render_pipeline)

    data := []Vertex{
        {{0.0, 1.0}, {1.0, 0.0, 0.0}},
        {{-1.0, -1.0}, {0.0, 1.0, 0.0}},
        {{1.0, -1.0}, {0.0, 0.0, 1.0}},
    }

    buffer_descriptor := wgpu.Buffer_Descriptor {
        label = "Triangle buffer",
        size = cast(u64)len(data) * size_of(Vertex),
        usage = {.Copy_Dst, .Vertex},
    }

    buffer := wgpu.device_create_buffer(device, &buffer_descriptor)
    defer wgpu.buffer_release(buffer)

    wgpu.queue_write_buffer(
        queue,
        buffer,
        0,
        raw_data(data),
        cast(uint)buffer_descriptor.size,
    )

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
                    new_width := cast(u32)e.window.data1
                    new_height := cast(u32)e.window.data2

                    if new_width != 0 && new_height != 0 {
                        surface_config.width = new_width
                        surface_config.height = new_height

                        wgpu.swap_chain_release(swapchain)

                        fmt.printf(
                            "Resizing to %d x %d\n",
                            surface_config.width,
                            surface_config.height,
                        )

                        swapchain = wgpu.device_create_swap_chain(
                            device,
                            surface,
                            &surface_config,
                        )
                    }
                }
            }
        }

        next_texture_response: Next_Texture_Response = {}

        wgpu.device_push_error_scope(device, .Validation)
        next_texture := wgpu.swap_chain_get_current_texture_view(swapchain)
        wgpu.device_pop_error_scope(
            device,
            _handle_current_texture_error,
            &next_texture_response,
        )

        if next_texture_response.type != .No_Error {
            fmt.eprintf(
                "Failed to get current texture [%v]: %s\n",
                next_texture_response.type,
                next_texture_response.message,
            )
            break main_loop
        }
        defer wgpu.texture_view_release(next_texture)

        encoder := wgpu.device_create_command_encoder(
            device,
            &wgpu.Command_Encoder_Descriptor{label = "Command Encoder"},
        )

        color_attachments: []wgpu.Render_Pass_Color_Attachment = {
            {
                view = next_texture,
                resolve_target = nil,
                load_op = .Clear,
                store_op = .Store,
                clear_value = {0.2, 0.2, 0.2, 1.0},
            },
        }

        render_pass := wgpu.command_encoder_begin_render_pass(
            encoder,
            &wgpu.Render_Pass_Descriptor{
                next_in_chain = nil,
                label = "Default render pass",
                color_attachment_count = cast(uint)len(color_attachments),
                color_attachments = raw_data(color_attachments),
                depth_stencil_attachment = nil,
            },
        )

        wgpu.render_pass_encoder_set_pipeline(render_pass, render_pipeline)
        wgpu.render_pass_encoder_set_vertex_buffer(
            render_pass,
            0,
            buffer,
            0,
            buffer_descriptor.size,
        )
        wgpu.render_pass_encoder_draw(render_pass, cast(u32)len(data), 1, 0, 0)
        wgpu.render_pass_encoder_end(render_pass)
        wgpu.render_pass_encoder_release(render_pass)

        commands: []wgpu.Command_Buffer = {
            wgpu.command_encoder_finish(
                encoder,
                &wgpu.Command_Buffer_Descriptor{label = "Default command buffer"},
            ),
        }
        wgpu.command_encoder_release(encoder)

        wgpu.queue_submit(queue, len(commands), raw_data(commands))
        wgpu.swap_chain_present(swapchain)
    }

    fmt.println("Exiting...")
}

_on_request_adapter_callback :: proc "c" (
    status: wgpu.Request_Adapter_Status,
    adapter: wgpu.Adapter,
    message: cstring,
    user_data: rawptr,
) {
    response := cast(^Adapter_Response)user_data
    response.status = status

    if status == .Success {
        response.adapter = adapter
    }
}

_on_adapter_request_device :: proc "c" (
    status: wgpu.Request_Device_Status,
    device: wgpu.Device,
    message: cstring,
    user_data: rawptr,
) {
    response := cast(^Device_Response)user_data
    response.status = status
    response.message = message

    if status == .Success {
        response.device = device
    }
}

_handle_current_texture_error :: proc "c" (
    type: wgpu.Error_Type,
    message: cstring,
    user_data: rawptr,
) {
    if type == .No_Error {
        return
    }

    response := cast(^Next_Texture_Response)user_data
    response.type = type
    response.message = message
}

_on_device_lost :: proc "c" (
    reason: wgpu.Device_Lost_Reason,
    message: cstring,
    user_data: rawptr,
) {
    context = runtime.default_context()
    fmt.eprintf("The WGPU device was lost [%d]: %s\n", reason, message)
}

print_adapter_information :: proc(info: wgpu.Adapter_Properties) {
    fmt.printf("Selected device:\n\n")
    fmt.printf("%s\n", info.name)

    driver_description: cstring = info.driver_description

    if driver_description == nil || driver_description == "" {
        driver_description = "Unknown"
    }

    fmt.printf("\tDriver: %s\n", driver_description)

    adapter_type: cstring = ""

    switch info.adapter_type {
    case wgpu.Adapter_Type.Discrete_GPU:
        adapter_type = "Discrete GPU with separate CPU/GPU memory"
    case wgpu.Adapter_Type.Integrated_GPU:
        adapter_type = "Integrated GPU with shared CPU/GPU memory"
    case wgpu.Adapter_Type.CPU:
        adapter_type = "Cpu / Software Rendering"
    case wgpu.Adapter_Type.Unknown:
        adapter_type = "Unknown"
    }

    fmt.printf("\tType: %s\n", adapter_type)

    backend_type: cstring

    #partial switch info.backend_type {
    case wgpu.Backend_Type.Null:
        backend_type = "Empty"
    case wgpu.Backend_Type.WebGPU:
        backend_type = "WebGPU in the browser"
    case wgpu.Backend_Type.D3D11:
        backend_type = "Direct3D-11"
    case wgpu.Backend_Type.D3D12:
        backend_type = "Direct3D-12"
    case wgpu.Backend_Type.Metal:
        backend_type = "Metal API"
    case wgpu.Backend_Type.Vulkan:
        backend_type = "Vulkan API"
    case wgpu.Backend_Type.OpenGL:
        backend_type = "OpenGL"
    case wgpu.Backend_Type.OpenGLES:
        backend_type = "OpenGLES"
    }

    fmt.printf("\tBackend: %s\n\n", backend_type)
}
