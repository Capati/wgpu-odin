package tutorial4_buffer_challenge

// Core
import "core:fmt"
import "core:math"

// Package
import "../../../framework"
import wgpu "../../../../wrapper"

State :: framework.State
Physical_Size :: framework.Physical_Size
Keyboard_Event :: framework.Keyboard_Event

Vertex :: struct {
    position: [3]f32,
    color:    [3]f32,
}

Example :: struct {
    render_pipeline:         wgpu.Render_Pipeline,
    vertex_buffer:           wgpu.Buffer,
    index_buffer:            wgpu.Buffer,
    challenge_vertex_buffer: wgpu.Buffer,
    challenge_index_buffer:  wgpu.Buffer,
    num_indices:             u32,
    num_challenge_indices:   u32,
    use_complex:             bool,
}

ctx := Example{}

init_example :: proc(using state: ^State) -> (err: wgpu.Error_Type) {
    shader := state.device->load_wgsl_shader_module(
        "assets/learn_wgpu/tutorial4/shader.wgsl",
        "shader.wgsl",
    ) or_return
    defer shader->release()

    render_pipeline_layout := state.device->create_pipeline_layout(
        &{label = "Render Pipeline Layout"},
    ) or_return
    defer render_pipeline_layout->release()

    vertex_buffer_layout := wgpu.Vertex_Buffer_Layout {
        array_stride = size_of(Vertex),
        step_mode = .Vertex,
        attributes = {
            {offset = 0, shader_location = 0, format = .Float32x3},
            {
                offset = cast(u64)offset_of(Vertex, color),
                shader_location = 1,
                format = .Float32x3,
            },
        },
    }

    render_pipeline_descriptor := wgpu.Render_Pipeline_Descriptor {
        label = "Render Pipeline",
        layout = &render_pipeline_layout,
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
                    format = state.config.format,
                    blend = &wgpu.Blend_State_Replace,
                    write_mask = wgpu.Color_Write_Mask_All,
                },
            },
        },
        primitive = {topology = .Triangle_List, front_face = .CCW, cull_mode = .None},
        depth_stencil = nil,
        multisample = {count = 1, mask = ~u32(0), alpha_to_coverage_enabled = false},
    }

    ctx.render_pipeline = state.device->create_render_pipeline(
        &render_pipeline_descriptor,
    ) or_return

    // vertices := []Vertex{
    //     {position = {0.0, 0.5, 0.0}, color = {1.0, 0.0, 0.0}},
    //     {position = {-0.5, -0.5, 0.0}, color = {0.0, 1.0, 0.0}},
    //     {position = {0.5, -0.5, 0.0}, color = {0.0, 0.0, 1.0}},
    // }

    vertices := []Vertex {
        {position = {-0.0868241, 0.49240386, 0.0}, color = {0.5, 0.0, 0.5}}, // A
        {position = {-0.49513406, 0.06958647, 0.0}, color = {0.5, 0.0, 0.5}}, // B
        {position = {-0.21918549, -0.44939706, 0.0}, color = {0.5, 0.0, 0.5}}, // C
        {position = {0.35966998, -0.3473291, 0.0}, color = {0.5, 0.0, 0.5}}, // D
        {position = {0.44147372, 0.2347359, 0.0}, color = {0.5, 0.0, 0.5}}, // E
    }

    indices: []u16 = {0, 1, 4, 1, 2, 4, 2, 3, 4}

    // state.num_vertices = cast(u32)len(vertices)
    ctx.num_indices = cast(u32)len(indices)

    ctx.vertex_buffer = state.device->create_buffer_with_data(
        &wgpu.Buffer_Data_Descriptor{
            label = "Vertex Buffer",
            contents = wgpu.to_bytes(vertices),
            usage = {.Vertex},
        },
    ) or_return

    ctx.index_buffer = state.device->create_buffer_with_data(
        &wgpu.Buffer_Data_Descriptor{
            label = "Index Buffer",
            contents = wgpu.to_bytes(indices),
            usage = {.Index},
        },
    ) or_return

    num_vertices :: 100
    angle := math.PI * 2.0 / f32(num_vertices)
    challenge_verts: [num_vertices]Vertex

    for i := 0; i < num_vertices; i += 1 {
        theta := angle * f32(i)
        theta_sin, theta_cos := math.sincos_f64(f64(theta))

        challenge_verts[i] = Vertex {
            position = {0.5 * f32(theta_cos), -0.5 * f32(theta_sin), 0.0},
            color = {(1.0 + f32(theta_cos)) / 2.0, (1.0 + f32(theta_sin)) / 2.0, 1.0},
        }
    }

    num_triangles :: num_vertices - 2
    challenge_indices: [num_triangles * 3]u16
    {
        index := 0
        for i := u16(1); i < num_triangles + 1; i += 1 {
            challenge_indices[index] = i + 1
            challenge_indices[index + 1] = i
            challenge_indices[index + 2] = 0
            index += 3
        }
    }

    ctx.num_challenge_indices = len(challenge_indices)

    ctx.challenge_vertex_buffer = state.device->create_buffer_with_data(
        &wgpu.Buffer_Data_Descriptor{
            label = "Vertex Buffer",
            contents = wgpu.to_bytes(challenge_verts[:]),
            usage = {.Vertex},
        },
    ) or_return

    ctx.challenge_index_buffer = state.device->create_buffer_with_data(
        &wgpu.Buffer_Data_Descriptor{
            label = "Index Buffer",
            contents = wgpu.to_bytes(challenge_indices[:]),
            usage = {.Index},
        },
    ) or_return

    return .No_Error
}

on_key_down :: proc(state: ^State, event: Keyboard_Event) {
    if event.keysym.sym == .SPACE {
        ctx.use_complex = true
    }
}

on_key_up :: proc(state: ^State, event: Keyboard_Event) {
    if event.keysym.sym == .SPACE {
        ctx.use_complex = false
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

    render_pass->set_pipeline(&ctx.render_pipeline)

    if ctx.use_complex {
        render_pass->set_vertex_buffer(0, ctx.challenge_vertex_buffer)
        render_pass->set_index_buffer(
            ctx.challenge_index_buffer,
            .Uint16,
            0,
            wgpu.Whole_Size,
        )
        render_pass->draw_indexed(ctx.num_challenge_indices)
    } else {
        render_pass->set_vertex_buffer(0, ctx.vertex_buffer)
        render_pass->set_index_buffer(ctx.index_buffer, .Uint16, 0, wgpu.Whole_Size)
        render_pass->draw_indexed(ctx.num_indices)
    }

    // render_pass->draw(state.num_vertices)
    render_pass->end()

    command_buffer := encoder->finish() or_return
    defer command_buffer->release()

    state.device.queue->submit(command_buffer)
    state.swap_chain->present()

    return .No_Error
}

main :: proc() {
    properties := framework.default_properties
    properties.title = "Tutorial 4 - Buffer Challenge"

    state, state_err := framework.init(properties)
    if state_err != .No_Error {
        fmt.eprintf("Failed to initialize framework")
        return
    }
    defer framework.deinit()

    if init_example(state) != .No_Error do return
    defer {
        ctx.challenge_vertex_buffer->release()
        ctx.challenge_index_buffer->release()
        ctx.index_buffer->release()
        ctx.vertex_buffer->release()
        ctx.render_pipeline->release()
    }

    state.render_proc = render
    state.on_key_down_proc = on_key_down
    state.on_key_up_proc = on_key_up

    framework.begin_run()
}
