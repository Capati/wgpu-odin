package triangle

// Core
import "core:fmt"

// Package
import "../framework"
import wgpu "../../wrapper"

State :: framework.State
Physical_Size :: framework.Physical_Size

Example :: struct {
    pipeline: wgpu.Render_Pipeline,
}

ctx := Example{}

init_example := proc(using state: ^State) -> (err: wgpu.Error_Type) {
    shader := device->load_wgsl_shader_module(
        "assets/triangle.wgsl",
        "Red triangle module",
    ) or_return
    defer shader->release()

    ctx.pipeline = device->create_render_pipeline(
        &{
            label = "Render Pipeline",
            vertex = {module = &shader, entry_point = "vs"},
            fragment = &{
                module = &shader,
                entry_point = "fs",
                targets = {
                    {
                        format = config.format,
                        blend = &wgpu.Blend_State_Replace,
                        write_mask = wgpu.Color_Write_Mask_All,
                    },
                },
            },
            multisample = wgpu.Multisample_State_Default,
        },
    ) or_return

    return .No_Error
}

render :: proc(using state: ^State) -> wgpu.Error_Type {
    encoder := device->create_command_encoder(
        &wgpu.Command_Encoder_Descriptor{label = "Command Encoder"},
    ) or_return
    defer encoder->release()

    render_pass := encoder->begin_render_pass(
        &{
            label = "Render Pass",
            color_attachments = []wgpu.Render_Pass_Color_Attachment{
                {
                    view = &frame,
                    resolve_target = nil,
                    load_op = .Clear,
                    store_op = .Store,
                    clear_value = wgpu.Color_Green,
                },
            },
            depth_stencil_attachment = nil,
        },
    )
    defer render_pass->release()

    render_pass->set_pipeline(&ctx.pipeline)
    render_pass->draw(3)
    render_pass->end() or_return

    command_buffer := encoder->finish() or_return
    defer command_buffer->release()

    device.queue->submit(command_buffer)
    swap_chain->present()

    return .No_Error
}

main :: proc() {
    title: cstring = "Triangle"
    properties := framework.default_properties
    properties.title = title

    state, state_err := framework.init(properties)
    if state_err != .No_Error {
        message := wgpu.get_error_message()
        if message != "" {
            fmt.eprintf("Failed to initialize [%s]: %s", title, message)
        } else {
            fmt.eprintf("Failed to initialize [%s]", title)
        }
        return
    }
    defer framework.deinit()

    if init_example(state) != .No_Error do return
    defer {
        ctx.pipeline->release()
    }

    state.render_proc = render

    framework.begin_run()
}
