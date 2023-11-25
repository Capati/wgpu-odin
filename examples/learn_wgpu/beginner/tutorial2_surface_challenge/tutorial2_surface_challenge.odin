package tutorial2_surface_challenge

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
    app_properties.title = "Tutorial 2 - Surface Challenge"
    if app.init(app_properties) != .No_Error do return
    defer app.deinit()

    gpu, gpu_err := renderer.init()
    if gpu_err != .No_Error do return
    defer renderer.deinit(gpu)

    clear_color := wgpu.Color_Black

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
                clear_color = {
                    r = cast(f64)event.x / cast(f64)gpu.config.width,
                    g = cast(f64)event.y / cast(f64)gpu.config.height,
                    b = 1.0,
                    a = 1.0,
                }
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
                        clear_value = clear_color,
                    },
                },
                depth_stencil_attachment = nil,
            },
        )
        if render_pass->end() != .No_Error do break main_loop
        render_pass->release()

        command_buffer, command_buffer_err := encoder->finish("Default command buffer")
        if command_buffer_err != .No_Error do break main_loop
        defer command_buffer->release()

        gpu.device.queue->submit(command_buffer)
        gpu.surface->present()
    }

    fmt.println("Exiting...")
}
