package tutorial2_surface_challenge

// Core
import "core:fmt"
import "core:runtime"

// Vendor
import sdl "vendor:sdl2"

// Package
import "../../../framework"
import wgpu "../../../../wrapper"

State :: framework.State
Physical_Size :: framework.Physical_Size
Mouse_Motion :: framework.Mouse_Motion

Example :: struct {
    clear_color: wgpu.Color,
}

ctx := Example{}

init_example := proc(using state: ^State) -> (err: wgpu.Error_Type) {
    ctx.clear_color = wgpu.Color_Black
    return .No_Error
}

on_mouse_motion :: proc(state: ^State, motion: Mouse_Motion) {
    ctx.clear_color = {
        r = cast(f64)motion.x / cast(f64)state.config.width,
        g = cast(f64)motion.y / cast(f64)state.config.height,
        b = 1.0,
        a = 1.0,
    }
}

render :: proc(state: ^State) -> wgpu.Error_Type {
    encoder := state.device->create_command_encoder(
        &wgpu.Command_Encoder_Descriptor{label = "Command Encoder"},
    ) or_return
    defer encoder->release()

    render_pass := encoder->begin_render_pass(
        &{
            label = "Render Pass",
            color_attachments = []wgpu.Render_Pass_Color_Attachment{
                {
                    view = &state.frame,
                    resolve_target = nil,
                    load_op = .Clear,
                    store_op = .Store,
                    clear_value = ctx.clear_color,
                },
            },
            depth_stencil_attachment = nil,
        },
    )
    render_pass->end() or_return
    render_pass->release()

    command_buffer := encoder->finish() or_return
    defer command_buffer->release()

    state.device.queue->submit(command_buffer)
    state.swap_chain->present()

    return .No_Error
}

main :: proc() {
    properties := framework.default_properties
    properties.title = "Tutorial 2 - Surface Challenge"

    state, state_err := framework.init(properties)
    if state_err != .No_Error {
        fmt.eprintf("Failed to initialize framework")
        return
    }
    defer framework.deinit()

    if init_example(state) != .No_Error do return

    state.render_proc = render
    state.on_mouse_motion_proc = on_mouse_motion

    framework.begin_run()
}
