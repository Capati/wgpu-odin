package triangle_msaa

// Core
import "core:fmt"

// Package
import wgpu "../../wrapper"

// Framework
import app "../framework/application"
import "../framework/application/events"
import "../framework/renderer"

Msaa_Count :: 4

main :: proc() {
    app_properties := app.Default_Properties
    app_properties.title = "Triangle 4x MSAA"
    if app.init(app_properties) != .No_Error do return
    defer app.deinit()

    gpu, gpu_err := renderer.init()
    if gpu_err != .No_Error do return
    defer renderer.deinit(gpu)

    shader, shader_err := gpu.device->load_wgsl_shader_module(
        "assets/triangle.wgsl",
        "Red triangle module",
    )
    if shader_err != .No_Error do return
    defer shader->release()

    pipeline, pipeline_err := gpu.device->create_render_pipeline(
        & {
            label = "Render Pipeline",
            vertex = {module = &shader, entry_point = "vs"},
            fragment = & {
                module = &shader,
                entry_point = "fs",
                targets =  {
                     {
                        format = gpu.config.format,
                        blend = &wgpu.Blend_State_Replace,
                        write_mask = wgpu.Color_Write_Mask_All,
                    },
                },
            },
            multisample = {count = Msaa_Count, mask = ~u32(0), alpha_to_coverage_enabled = false},
        },
    )
    if pipeline_err != .No_Error do return
    defer pipeline->release()

    multisampled_framebuffer, multisampled_framebuffer_err := get_multisampled_framebuffer(
        gpu,
        {gpu.config.width, gpu.config.height},
    )
    if multisampled_framebuffer_err != .No_Error do return

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
                multisampled_framebuffer->release()
                multisampled_framebuffer, multisampled_framebuffer_err =
                    get_multisampled_framebuffer(gpu, {event.width, event.height})
                if multisampled_framebuffer_err != .No_Error do break main_loop

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
                        view = &multisampled_framebuffer,
                        resolve_target = &view,
                        load_op = .Clear,
                        store_op = .Store,
                        clear_value = wgpu.Color_Green,
                    },
                },
                depth_stencil_attachment = nil,
            },
        )
        defer render_pass->release()

        render_pass->set_pipeline(&pipeline)
        render_pass->draw(3)
        if render_pass->end() != .No_Error do break main_loop

        command_buffer, command_buffer_err := encoder->finish("Default command buffer")
        if command_buffer_err != .No_Error do break main_loop
        defer command_buffer->release()

        gpu.device.queue->submit(command_buffer)
        gpu.surface->present()
    }

    fmt.println("Exiting...")
}

get_multisampled_framebuffer :: proc(
    gpu: ^renderer.Renderer,
    size: app.Physical_Size,
) -> (
    view: wgpu.Texture_View,
    err: wgpu.Error_Type,
) {
    texture := gpu.device->create_texture(
        & {
            usage = {.Render_Attachment},
            dimension = .D2,
            size = {width = size.width, height = size.height, depth_or_array_layers = 1},
            format = gpu.config.format,
            mip_level_count = 1,
            sample_count = Msaa_Count,
        },
    ) or_return
    defer texture->release()

    return texture->create_view(nil)
}
