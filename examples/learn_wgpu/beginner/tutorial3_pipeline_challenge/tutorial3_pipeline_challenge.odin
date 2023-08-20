package tutorial3_pipeline_challenge

// Core
import "core:fmt"

// Package
import "../../../framework"
import wgpu "../../../../wrapper"

State :: framework.State
Keyboard_Event :: framework.Keyboard_Event
Physical_Size :: framework.Physical_Size

Example :: struct {
    render_pipeline:           wgpu.Render_Pipeline,
    // The new colored pipeline
    challenge_render_pipeline: wgpu.Render_Pipeline,
    // Flag to use the colored pipeline
    use_color:                 bool,
}

ctx := Example{}

init_example :: proc(using state: ^State) -> (err: wgpu.Error_Type) {
    shader := state.device->load_wgsl_shader_module(
        "assets/learn_wgpu/tutorial3/shader.wgsl",
        "shader.wgsl",
    ) or_return
    defer shader->release()

    render_pipeline_layout := state.device->create_pipeline_layout(
        &{label = "Render Pipeline Layout"},
    ) or_return

    render_pipeline_descriptor := wgpu.Render_Pipeline_Descriptor {
        label = "Render Pipeline",
        layout = &render_pipeline_layout,
        vertex = {module = &shader, entry_point = "vs_main"},
        fragment = &{
            module = &shader,
            entry_point = "fs_main",
            targets = {
                {
                    format = state.config.format,
                    blend = &wgpu.Blend_State_Replace,
                    write_mask = wgpu.Color_Write_Mask_All,
                },
            },
        },
        primitive = {topology = .Triangle_List, front_face = .CCW, cull_mode = .Back},
        depth_stencil = nil,
        multisample = {count = 1, mask = ~u32(0), alpha_to_coverage_enabled = false},
    }

    ctx.render_pipeline = state.device->create_render_pipeline(
        &render_pipeline_descriptor,
    ) or_return

    challenge_shader := state.device->load_wgsl_shader_module(
        "assets/learn_wgpu/tutorial3/challenge.wgsl",
        "challenge.wgsl",
    ) or_return
    defer challenge_shader->release()

    challenge_render_pipeline_descriptor := wgpu.Render_Pipeline_Descriptor {
        label = "Challenge Render Pipeline",
        layout = &render_pipeline_layout,
        vertex = {module = &challenge_shader, entry_point = "vs_main"},
        fragment = &{
            module = &challenge_shader,
            entry_point = "fs_main",
            targets = {
                {
                    format = state.config.format,
                    blend = &wgpu.Blend_State_Replace,
                    write_mask = wgpu.Color_Write_Mask_All,
                },
            },
        },
        primitive = {topology = .Triangle_List, front_face = .CCW, cull_mode = .Back},
        depth_stencil = nil,
        multisample = {count = 1, mask = ~u32(0), alpha_to_coverage_enabled = false},
    }

    ctx.challenge_render_pipeline = state.device->create_render_pipeline(
        &challenge_render_pipeline_descriptor,
    ) or_return

    return .No_Error
}

on_key_down :: proc(state: ^State, event: Keyboard_Event) {
    if event.keysym.sym == .SPACE {
        ctx.use_color = true
    }
}

on_key_up :: proc(state: ^State, event: Keyboard_Event) {
    if event.keysym.sym == .SPACE {
        ctx.use_color = false
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
                    clear_value = {0.1, 0.2, 0.3, 1.0},
                },
            },
            depth_stencil_attachment = nil,
        },
    )
    defer render_pass->release()

    // Use the colored pipeline if `use_color` is `true`
    if ctx.use_color {
        render_pass->set_pipeline(&ctx.challenge_render_pipeline)
    } else {
        render_pass->set_pipeline(&ctx.render_pipeline)
    }
    render_pass->draw(3)
    render_pass->end() or_return

    command_buffer := encoder->finish() or_return
    defer command_buffer->release()

    state.device.queue->submit(command_buffer)
    state.swap_chain->present()

    return .No_Error
}

main :: proc() {
    properties := framework.default_properties
    properties.title = "Tutorial 3 - Pipeline Challenge"

    state, state_err := framework.init(properties)
    if state_err != .No_Error {
        fmt.eprintf("Failed to initialize framework")
        return
    }
    defer framework.deinit()

    if init_example(state) != .No_Error do return
    defer {
        ctx.challenge_render_pipeline->release()
        ctx.render_pipeline->release()

    }

    state.render_proc = render
    state.on_key_down_proc = on_key_down
    state.on_key_up_proc = on_key_up

    framework.begin_run()
}
