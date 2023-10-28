package tutorial3_pipeline

// Core
import "core:fmt"

// Package
import wgpu "../../../../wrapper"

// Framework
import app "../../../framework/application"
import "../../../framework/application/events"
import "../../../framework/renderer"

main :: proc() {
    app_properties := app.Default_Properties
    app_properties.title = "Tutorial 3 - Pipeline"
    if app.init(app_properties) != .No_Error do return
    defer app.deinit()

    gpu, gpu_err := renderer.init()
    if gpu_err != .No_Error do return
    defer renderer.deinit(gpu)

    shader, shader_err := gpu.device->load_wgsl_shader_module(
        "assets/learn_wgpu/tutorial3/shader.wgsl",
        "shader.wgsl",
    )
    if shader_err != .No_Error do return
    defer shader->release()

    render_pipeline_layout, render_pipeline_layout_err := gpu.device->create_pipeline_layout(
        &{label = "Render Pipeline Layout"},
    )
    if render_pipeline_layout_err != .No_Error do return
    defer render_pipeline_layout->release()

    render_pipeline_descriptor := wgpu.Render_Pipeline_Descriptor {
        label = "Render Pipeline",
        layout = &render_pipeline_layout,
        vertex = {module = &shader, entry_point = "vs_main"},
        fragment = &{
            module = &shader,
            entry_point = "fs_main",
            targets = {
                {
                    format = gpu.config.format,
                    blend = &wgpu.Blend_State_Replace,
                    write_mask = wgpu.Color_Write_Mask_All,
                },
            },
        },
        primitive = {topology = .Triangle_List, front_face = .CCW, cull_mode = .Back},
        depth_stencil = nil,
        multisample = {count = 1, mask = ~u32(0), alpha_to_coverage_enabled = false},
    }

    render_pipeline, render_pipeline_err := gpu.device->create_render_pipeline(
        &render_pipeline_descriptor,
    )
    if render_pipeline_err != .No_Error do return
    defer render_pipeline->release()

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

        render_pass->set_pipeline(&render_pipeline)
        render_pass->draw(3)
        if render_pass->end() != .No_Error do break main_loop

        command_buffer, command_buffer_err := encoder->finish()
        if command_buffer_err != .No_Error do break main_loop
        defer command_buffer->release()

        gpu.device.queue->submit(command_buffer)
        gpu.surface->present()
    }

    fmt.println("Exiting...")
}
