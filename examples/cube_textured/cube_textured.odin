package cube_textured

// Core
import "core:fmt"
import "core:math"
import la "core:math/linalg"
// import "core:math/linalg/glsl"

// Package
import wgpu "../../wrapper"

// Framework
import app "../framework/application"
import "../framework/application/events"
import "../framework/renderer"

Texel_Size :: 256

main :: proc() {
    app_properties := app.Default_Properties
    app_properties.title = "Textured Cube"
    if app.init(app_properties) != .No_Error do return
    defer app.deinit()

    gpu, gpu_err := renderer.init()
    if gpu_err != .No_Error do return
    defer renderer.deinit(gpu)

    vertex_buffer, vertex_buffer_err := gpu.device->create_buffer_with_data(
        &{
            label = "Vertex Buffer",
            contents = wgpu.to_bytes(vertex_data),
            usage = {.Vertex},
        },
    )
    if vertex_buffer_err != .No_Error do return
    defer vertex_buffer->release()

    index_buffer, index_buffer_err := gpu.device->create_buffer_with_data(
        &{
            label = "Index Buffer",
            contents = wgpu.to_bytes(index_data),
            usage = {.Index},
        },
    )
    if index_buffer_err != .No_Error do return
    defer index_buffer->release()

    texels := create_texels()
    texture_extent := wgpu.Extent_3D {
        width                 = Texel_Size,
        height                = Texel_Size,
        depth_or_array_layers = 1,
    }
    texture, texture_err := gpu.device->create_texture(
        &{
            size = texture_extent,
            mip_level_count = 1,
            sample_count = 1,
            dimension = .D2,
            format = .R8_Uint,
            usage = {.Texture_Binding, .Copy_Dst},
        },
    )
    if texture_err != .No_Error do return
    defer texture->release()

    texture_view, texture_view_err := texture->create_view(nil)
    if texture_view_err != .No_Error do return
    defer texture_view->release()

    write_texture_err := gpu.device.queue->write_texture(
        &{texture = &texture, mip_level = 0, origin = {}, aspect = .All},
        wgpu.to_bytes(texels),
        &{
            offset = 0,
            bytes_per_row = Texel_Size,
            rows_per_image = cast(u32)wgpu.Copy_Stride_Undefined,
        },
        &texture_extent,
    )
    if write_texture_err != .No_Error do return

    mx_total := generate_matrix(cast(f32)gpu.config.width / cast(f32)gpu.config.height)

    fmt.printf("%#v\n\n", mx_total)

    uniform_buffer, uniform_buffer_err := gpu.device->create_buffer_with_data(
        &{
            label = "Uniform Buffer",
            contents = wgpu.to_bytes(mx_total),
            usage = {.Uniform, .Copy_Dst},
        },
    )
    if uniform_buffer_err != .No_Error do return
    defer uniform_buffer->release()

    shader, shader_err := gpu.device->load_wgsl_shader_module(
        "assets/cube_textured.wgsl",
        "shader.wgsl",
    )
    if shader_err != .No_Error do return
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

    pipeline, pipeline_err := gpu.device->create_render_pipeline(
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
                        format = gpu.config.format,
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
            multisample = wgpu.Default_Multisample_State,
        },
    )

    if pipeline_err != .No_Error do return
    defer pipeline->release()

    bind_group_layout, bind_group_layout_err := pipeline->get_bind_group_layout(0)
    if bind_group_layout_err != .No_Error do return
    defer bind_group_layout->release()

    bind_group, bind_group_err := gpu.device->create_bind_group(
        &{
            layout = &bind_group_layout,
            entries = {
                {binding = 0, buffer = &uniform_buffer, size = wgpu.Whole_Size},
                {binding = 1, texture_view = &texture_view, size = wgpu.Whole_Size},
            },
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
                write_buffer_err := gpu.device.queue->write_buffer(
                    &uniform_buffer,
                    0,
                    wgpu.to_bytes(
                        generate_matrix(cast(f32)event.width / cast(f32)event.height),
                    ),
                )
                if write_buffer_err != .No_Error do break main_loop

                resize_err := renderer.resize_surface(gpu, {event.width, event.height})
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
            &wgpu.Command_Encoder_Descriptor{label = "Command Encoder"},
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
                        clear_value = {0.1, 0.2, 0.3, 1.0},
                    },
                },
                depth_stencil_attachment = nil,
            },
        )
        defer render_pass->release()

        render_pass->set_pipeline(&pipeline)
        render_pass->set_bind_group(0, &bind_group, nil)
        render_pass->set_index_buffer(index_buffer, .Uint16, 0, wgpu.Whole_Size)
        render_pass->set_vertex_buffer(0, vertex_buffer, 0, wgpu.Whole_Size)
        render_pass->draw_indexed(cast(u32)len(index_data), 1, 0, 0, 0)
        if render_pass->end() != .No_Error do break main_loop

        command_buffer, command_buffer_err := encoder->finish("Default command buffer")
        if command_buffer_err != .No_Error do break main_loop
        defer command_buffer->release()

        gpu.device.queue->submit(command_buffer)
        gpu.surface->present()
    }

    fmt.println("Exiting...")
}

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
