package cube

// Core
import "core:fmt"
import "core:math"
import la "core:math/linalg"

// Package
import wgpu "../../wrapper"
import "../common"

// Framework
import app "../framework/application"
import "../framework/application/events"
import "../framework/renderer"

Depth_Format: wgpu.Texture_Format = .Depth24_Plus

main :: proc() {
    app_properties := app.Default_Properties
    app_properties.title = "Cube"
    if app.init(app_properties) != .No_Error do return
    defer app.deinit()

    gpu, gpu_err := renderer.init()
    if gpu_err != .No_Error do return
    defer renderer.deinit(gpu)

    shader, shader_err := gpu.device->load_wgsl_shader_module(
        "assets/cube.wgsl",
        "Cube shader",
    )
    if shader_err != .No_Error do return
    defer shader->release()

    vertex_buffer, vertex_buffer_err := gpu.device->create_buffer_with_data(
        &{
            label = "Cube Vertex Buffer",
            contents = wgpu.to_bytes(vertex_data),
            usage = {.Vertex},
        },
    )
    if vertex_buffer_err != .No_Error do return
    defer vertex_buffer->release()

    vertex_buffer_layout := wgpu.Vertex_Buffer_Layout {
        array_stride = size_of(Vertex),
        step_mode = .Vertex,
        attributes = {
            {format = .Float32x3, offset = 0, shader_location = 0},
            {
                format = .Float32x3,
                offset = cast(u64)offset_of(Vertex, color),
                shader_location = 1,
            },
        },
    }

    pipeline_descriptor := wgpu.Render_Pipeline_Descriptor {
        label = "Render Pipeline",
        vertex = {
            module = &shader,
            entry_point = "vertex_main",
            buffers = {vertex_buffer_layout},
        },
        fragment = &{
            module = &shader,
            entry_point = "fragment_main",
            targets = {
                {
                    format = gpu.config.format,
                    blend = &wgpu.Blend_State_Replace,
                    write_mask = wgpu.Color_Write_Mask_All,
                },
            },
        },
        primitive = {topology = .Triangle_List, front_face = .CCW, cull_mode = .None},
        // Enable depth testing so that the fragment closest to the camera
        // is rendered in front.
        depth_stencil = &{
            depth_write_enabled = true,
            depth_compare = .Less,
            format = Depth_Format,
            stencil_front = {compare = .Always},
            stencil_back = {compare = .Always},
            stencil_read_mask = 0xFFFFFFFF,
            stencil_write_mask = 0xFFFFFFFF,
        },
        multisample = wgpu.Default_Multisample_State,
    }

    pipeline, pipeline_err := gpu.device->create_render_pipeline(&pipeline_descriptor)
    if pipeline_err != .No_Error do return
    defer pipeline->release()

    depth_stencil_view, depth_stencil_view_err := get_depth_framebuffer(
        gpu,
        {gpu.config.width, gpu.config.height},
    )
    if depth_stencil_view_err != .No_Error do return
    defer depth_stencil_view->release()

    aspect := cast(f32)gpu.config.width / cast(f32)gpu.config.height
    mvp_mat := generate_matrix(aspect)

    uniform_buffer, uniform_buffer_err := gpu.device->create_buffer_with_data(
        &{
            label = "Uniform Buffer",
            contents = wgpu.to_bytes(mvp_mat),
            usage = {.Uniform, .Copy_Dst},
        },
    )
    if uniform_buffer_err != .No_Error do return
    defer uniform_buffer->release()

    bind_group_layout, bind_group_layout_err := pipeline->get_bind_group_layout(0)
    if bind_group_layout_err != .No_Error do return
    defer bind_group_layout->release()

    bind_group, bind_group_err := gpu.device->create_bind_group(
        &{
            layout = &bind_group_layout,
            entries = {{binding = 0, buffer = &uniform_buffer, size = wgpu.Whole_Size}},
        },
    )
    if bind_group_err != .No_Error do return
    defer bind_group->release()

    fmt.printf("Entering main loop...\n\n")

    main_loop: for {
        iter := app.process_events()

        for iter->has_next() {
            #partial switch event in iter->next() {
            case events.Quit_Event:
                break main_loop
            case events.Key_Press_Event:
            case events.Mouse_Press_Event:
            case events.Mouse_Motion_Event:
            case events.Mouse_Scroll_Event:
            case events.Framebuffer_Resize_Event:
                size: app.Physical_Size = {event.width, event.height}

                depth_stencil_view->release()
                depth_stencil_view, depth_stencil_view_err = get_depth_framebuffer(
                    gpu,
                    size,
                )
                if depth_stencil_view_err != .No_Error do return

                write_buffer_err := gpu.device.queue->write_buffer(
                    &uniform_buffer,
                    0,
                    wgpu.to_bytes(
                        generate_matrix(cast(f32)size.width / cast(f32)size.height),
                    ),
                )
                if write_buffer_err != .No_Error do break main_loop

                resize_err := renderer.resize_surface(gpu, size)
                if resize_err != .No_Error do break main_loop
            }
        }

        frame, frame_err := renderer.get_current_texture_frame(gpu)
        if frame_err != .No_Error do break main_loop
        defer frame->release()
        if gpu.skip_frame do continue main_loop

        view, view_err := frame.texture->create_view(nil)
        if view_err != .No_Error do break main_loop
        defer view->release()

        encoder, encoder_err := gpu.device->create_command_encoder(
            &wgpu.Command_Encoder_Descriptor{label = "Cube Encoder"},
        )
        if encoder_err != .No_Error do break main_loop
        defer encoder->release()

        render_pass := encoder->begin_render_pass(
            &{
                label = "Render Pass",
                color_attachments = []wgpu.Render_Pass_Color_Attachment{
                    {
                        view = &view,
                        resolve_target = nil,
                        load_op = .Clear,
                        store_op = .Store,
                        clear_value = {0.2, 0.2, 0.2, 1.0},
                    },
                },
                depth_stencil_attachment = &{
                    view = &depth_stencil_view,
                    depth_clear_value = 1.0,
                    depth_load_op = .Clear,
                    depth_store_op = .Store,
                },
            },
        )
        defer render_pass->release()

        render_pass->set_pipeline(&pipeline)
        render_pass->set_bind_group(0, &bind_group, nil)
        render_pass->set_vertex_buffer(0, vertex_buffer, 0, wgpu.Whole_Size)
        render_pass->draw(cast(u32)len(vertex_data))
        if render_pass->end() != .No_Error do break main_loop

        command_buffer, command_buffer_err := encoder->finish()
        if command_buffer_err != .No_Error do break main_loop
        defer command_buffer->release()

        gpu.device.queue->submit(command_buffer)
        gpu.surface->present()
    }

    fmt.println("Exiting...")
}

get_depth_framebuffer :: proc(
    gpu: ^renderer.Renderer,
    size: app.Physical_Size,
) -> (
    view: wgpu.Texture_View,
    err: wgpu.Error_Type,
) {
    texture := gpu.device->create_texture(
        &{
            size = {width = size.width, height = size.height, depth_or_array_layers = 1},
            mip_level_count = 1,
            sample_count = 1,
            dimension = .D2,
            format = Depth_Format,
            usage = {.Render_Attachment},
        },
    ) or_return
    defer texture->release()

    return texture->create_view(nil)
}

generate_matrix :: proc(aspect: f32) -> la.Matrix4f32 {
    // 72 deg FOV
    projection := la.matrix4_perspective_f32((2 * math.PI) / 5, aspect, 1.0, 10.0)
    view := la.matrix4_look_at_f32(
        eye = {1.1, 1.1, 1.1},
        centre = {0.0, 0.0, 0.0},
        up = {0.0, 1.0, 0.0},
    )
    return common.Open_Gl_To_Wgpu_Matrix * projection * view
}
