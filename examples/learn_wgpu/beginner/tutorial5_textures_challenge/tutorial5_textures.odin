package tutorial5_textures

// Core
import "core:fmt"

// Package
import wgpu "../../../../wrapper"
import "../tutorial5_textures/texture"

// Framework
import app "../../../framework/application"
import "../../../framework/application/events"
import "../../../framework/renderer"

Vertex :: struct {
    position:   [3]f32,
    tex_coords: [2]f32,
}

main :: proc() {
    app_properties := app.Default_Properties
    app_properties.title = "Tutorial 5 - Textures Challenge"
    if app.init(app_properties) != .No_Error do return
    defer app.deinit()

    gpu, gpu_err := renderer.init()
    if gpu_err != .No_Error do return
    defer renderer.deinit(gpu)

    // Load our tree image to texture
    diffuse_texture, diffuse_texture_err := texture.texture_from_image(
        &gpu.device,
        "assets/learn_wgpu/tutorial5/happy-tree.png",
    )
    if diffuse_texture_err != .No_Error do return
    defer texture.texture_destroy(&diffuse_texture)

    texture_bind_group_layout, texture_bind_group_layout_err := gpu.device->create_bind_group_layout(
        & {
            label = "TextureBindGroupLayout",
            entries =  {
                 {
                    binding = 0,
                    visibility = {.Fragment},
                    texture = {multisampled = false, view_dimension = .D2, sample_type = .Float},
                },
                {binding = 1, visibility = {.Fragment}, sampler = {type = .Filtering}},
            },
        },
    )
    if texture_bind_group_layout_err != .No_Error do return
    defer texture_bind_group_layout->release()

    diffuse_bind_group, diffuse_bind_group_err := gpu.device->create_bind_group(
        &wgpu.Bind_Group_Descriptor {
            label = "diffuse_bind_group",
            layout = &texture_bind_group_layout,
            entries =  {
                {binding = 0, resource = &diffuse_texture.view},
                {binding = 1, resource = &diffuse_texture.sampler},
            },
        },
    )
    if diffuse_bind_group_err != .No_Error do return
    defer diffuse_bind_group->release()

    cartoon_texture, cartoon_texture_err := texture.texture_from_image(
        &gpu.device,
        "assets/learn_wgpu/tutorial5/happy-tree-cartoon.png",
    )
    if cartoon_texture_err != .No_Error do return
    defer texture.texture_destroy(&cartoon_texture)

    cartoon_bind_group, cartoon_bind_group_err := gpu.device->create_bind_group(
        &wgpu.Bind_Group_Descriptor {
            label = "cartoon_bind_group",
            layout = &texture_bind_group_layout,
            entries =  {
                {binding = 0, resource = &cartoon_texture.view},
                {binding = 1, resource = &cartoon_texture.sampler},
            },
        },
    )
    if cartoon_bind_group_err != .No_Error do return
    defer cartoon_bind_group->release()

    render_pipeline_layout, render_pipeline_layout_err := gpu.device->create_pipeline_layout(
        &{label = "Render Pipeline Layout", bind_group_layouts = {texture_bind_group_layout}},
    )
    if render_pipeline_layout_err != .No_Error do return
    defer render_pipeline_layout->release()

    vertex_buffer_layout := wgpu.Vertex_Buffer_Layout {
        array_stride = size_of(Vertex),
        step_mode = .Vertex,
        attributes =  {
            {offset = 0, shader_location = 0, format = .Float32x3},
             {
                offset = cast(u64)offset_of(Vertex, tex_coords),
                shader_location = 1,
                format = .Float32x2,
            },
        },
    }

    shader, shader_err := gpu.device->load_wgsl_shader_module(
        "assets/learn_wgpu/tutorial5/shader.wgsl",
        "shader.wgsl",
    )
    if shader_err != .No_Error do return
    defer shader->release()

    render_pipeline_descriptor := wgpu.Render_Pipeline_Descriptor {
        label = "Render Pipeline",
        layout = &render_pipeline_layout,
        vertex = {module = &shader, entry_point = "vs_main", buffers = {vertex_buffer_layout}},
        fragment = & {
            module = &shader,
            entry_point = "fs_main",
            targets =  {
                 {
                    format = gpu.config.format,
                    blend = &wgpu.Blend_State_Replace,
                    write_mask = wgpu.Color_Write_Mask_All,
                },
            },
        },
        primitive = {topology = .Triangle_List, front_face = .CCW, cull_mode = .None},
        depth_stencil = nil,
        multisample = {count = 1, mask = ~u32(0), alpha_to_coverage_enabled = false},
    }

    render_pipeline, render_pipeline_err := gpu.device->create_render_pipeline(
        &render_pipeline_descriptor,
    )
    if render_pipeline_err != .No_Error do return
    defer render_pipeline->release()

    vertices := []Vertex {
        {position = {-0.0868241, 0.49240386, 0.0}, tex_coords = {0.4131759, 0.00759614}}, // A
        {position = {-0.49513406, 0.06958647, 0.0}, tex_coords = {0.0048659444, 0.43041354}}, // B
        {position = {-0.21918549, -0.44939706, 0.0}, tex_coords = {0.28081453, 0.949397}}, // C
        {position = {0.35966998, -0.3473291, 0.0}, tex_coords = {0.85967, 0.84732914}}, // D
        {position = {0.44147372, 0.2347359, 0.0}, tex_coords = {0.9414737, 0.2652641}}, // E
    }

    indices: []u16 = {0, 1, 4, 1, 2, 4, 2, 3, 4}

    num_indices := cast(u32)len(indices)

    vertex_buffer, vertex_buffer_err := gpu.device->create_buffer_with_data(
        &wgpu.Buffer_Data_Descriptor {
            label = "Vertex Buffer",
            contents = wgpu.to_bytes(vertices),
            usage = {.Vertex},
        },
    )
    if vertex_buffer_err != .No_Error do return
    defer vertex_buffer->release()

    index_buffer, index_buffer_err := gpu.device->create_buffer_with_data(
        &wgpu.Buffer_Data_Descriptor {
            label = "Index Buffer",
            contents = wgpu.to_bytes(indices),
            usage = {.Index},
        },
    )
    if index_buffer_err != .No_Error do return
    defer index_buffer->release()

    is_space_pressed := false

    fmt.printf("Entering main loop...\n\n")

    main_loop: for {
        iter := app.process_events()

        for iter->has_next() {
            #partial switch event in iter->next() {
            case events.Quit_Event:
                break main_loop
            case events.Key_Press_Event:
                if event.key == .Space do is_space_pressed = true
            case events.Key_Release_Event:
                if event.key == .Space do is_space_pressed = false
            case events.Mouse_Press_Event:
            case events.Mouse_Motion_Event:
            case events.Mouse_Scroll_Event:
            case events.Framebuffer_Resize_Event:
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
            & {
                label = "Render Pass",
                color_attachments = []wgpu.Render_Pass_Color_Attachment {
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

        render_pass->set_pipeline(&render_pipeline)

        if is_space_pressed {
            render_pass->set_bind_group(0, &cartoon_bind_group)
        } else {
            render_pass->set_bind_group(0, &diffuse_bind_group)
        }

        render_pass->set_vertex_buffer(0, vertex_buffer)
        render_pass->set_index_buffer(index_buffer, .Uint16, 0, wgpu.Whole_Size)
        render_pass->draw_indexed(num_indices)
        if render_pass->end() != .No_Error do break main_loop

        command_buffer, command_buffer_err := encoder->finish()
        if command_buffer_err != .No_Error do break main_loop
        defer command_buffer->release()

        gpu.device.queue->submit(command_buffer)
        gpu.surface->present()
    }

    fmt.println("Exiting...")
}
