package triangle_msaa

// Core
import "core:fmt"

// Package
import "../framework"
import wgpu "../../wrapper"

State :: framework.State
Physical_Size :: framework.Physical_Size

Example :: struct {
    pipeline:                 wgpu.Render_Pipeline,
    multisampled_framebuffer: wgpu.Texture_View,
}

ctx := Example{}

Msaa_Count :: 4

init_example := proc(using state: ^State) -> (err: wgpu.Error_Type) {
    shader := device->load_wgsl_shader_module(
        "assets/triangle.wgsl",
        "Red triangle module",
    ) or_return
    defer shader->release()

    pipeline_descriptor := wgpu.Render_Pipeline_Descriptor {
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
        multisample = {
            count = Msaa_Count,
            mask = ~u32(0),
            alpha_to_coverage_enabled = false,
        },
    }

    ctx.pipeline = device->create_render_pipeline(&pipeline_descriptor) or_return
    defer if err != .No_Error do ctx.pipeline->release()

    ctx.multisampled_framebuffer = get_multisampled_framebuffer(
        state,
        {config.width, config.height},
    ) or_return

    return .No_Error
}

get_multisampled_framebuffer :: proc(
    using state: ^State,
    size: Physical_Size,
) -> (
    view: wgpu.Texture_View,
    err: wgpu.Error_Type,
) {
    texture := device->create_texture(
        &{
            usage = {.Render_Attachment},
            dimension = ._2D,
            size = {width = size.width, height = size.height, depth_or_array_layers = 1},
            format = config.format,
            mip_level_count = 1,
            sample_count = Msaa_Count,
        },
    ) or_return
    defer texture->release()

    return texture->create_view(nil)
}

resized :: proc(using state: ^State, size: Physical_Size) -> wgpu.Error_Type {
    ctx.multisampled_framebuffer->release()
    ctx.multisampled_framebuffer = get_multisampled_framebuffer(state, size) or_return
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
                    view = &ctx.multisampled_framebuffer,
                    resolve_target = &frame,
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
    title: cstring = "Triangle 4x MSAA"
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
        ctx.multisampled_framebuffer->release()
        ctx.pipeline->release()
    }

    state.render_proc = render
    state.resized_proc = resized

    framework.begin_run()
}
