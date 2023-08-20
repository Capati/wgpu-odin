package tutorial5_textures

// Core
import "core:fmt"

// Package
import "../../../framework"
import wgpu "../../../../wrapper"

State :: framework.State
Physical_Size :: framework.Physical_Size

Vertex :: struct {
    position:   [3]f32,
    tex_coords: [2]f32,
}

Example :: struct {
    render_pipeline:    wgpu.Render_Pipeline,
    vertex_buffer:      wgpu.Buffer,
    index_buffer:       wgpu.Buffer,
    num_indices:        u32,
    diffuse_texture:    Texture,
    diffuse_bind_group: wgpu.Bind_Group,
}

ctx := Example{}

init_example :: proc(using state: ^State) -> (err: wgpu.Error_Type) {
    // Load our tree image to texture
    ctx.diffuse_texture = texture_from_image(
        &state.device,
        "assets/learn_wgpu/tutorial5/happy-tree.png",
    ) or_return
    defer if err != .No_Error do texture_destroy(&ctx.diffuse_texture)

    texture_bind_group_layout := state.device->create_bind_group_layout(
        &{
            label = "TextureBindGroupLayout",
            entries = {
                {
                    binding = 0,
                    visibility = {.Fragment},
                    texture = {
                        multisampled = false,
                        view_dimension = ._2D,
                        sample_type = .Float,
                    },
                },
                {binding = 1, visibility = {.Fragment}, sampler = {type = .Filtering}},
            },
        },
    ) or_return
    defer texture_bind_group_layout->release()

    ctx.diffuse_bind_group = state.device->create_bind_group(
        &wgpu.Bind_Group_Descriptor{
            label = "diffuse_bind_group",
            layout = &texture_bind_group_layout,
            entries = {
                {binding = 0, texture_view = &ctx.diffuse_texture.view},
                {binding = 1, sampler = &ctx.diffuse_texture.sampler},
            },
        },
    ) or_return
    defer if err != .No_Error do ctx.diffuse_bind_group->release()

    render_pipeline_layout := state.device->create_pipeline_layout(
        &{
            label = "Render Pipeline Layout",
            bind_group_layouts = {texture_bind_group_layout},
        },
    ) or_return
    defer render_pipeline_layout->release()

    vertex_buffer_layout := wgpu.Vertex_Buffer_Layout {
        array_stride = size_of(Vertex),
        step_mode = .Vertex,
        attributes = {
            {offset = 0, shader_location = 0, format = .Float32x3},
            {
                offset = cast(u64)offset_of(Vertex, tex_coords),
                shader_location = 1,
                format = .Float32x2,
            },
        },
    }

    shader := state.device->load_wgsl_shader_module(
        "assets/learn_wgpu/tutorial5/shader.wgsl",
        "shader.wgsl",
    ) or_return
    defer shader->release()

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

    vertices := []Vertex {
        {
            position = {-0.0868241, 0.49240386, 0.0},
            tex_coords = {0.4131759, 0.00759614},
        }, // A
        {
            position = {-0.49513406, 0.06958647, 0.0},
            tex_coords = {0.0048659444, 0.43041354},
        }, // B
        {
            position = {-0.21918549, -0.44939706, 0.0},
            tex_coords = {0.28081453, 0.949397},
        }, // C
        {position = {0.35966998, -0.3473291, 0.0}, tex_coords = {0.85967, 0.84732914}}, // D
        {position = {0.44147372, 0.2347359, 0.0}, tex_coords = {0.9414737, 0.2652641}}, // E
    }

    indices: []u16 = {0, 1, 4, 1, 2, 4, 2, 3, 4}

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

    return .No_Error
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
    render_pass->set_bind_group(0, &ctx.diffuse_bind_group)
    render_pass->set_vertex_buffer(0, ctx.vertex_buffer)
    render_pass->set_index_buffer(ctx.index_buffer, .Uint16, 0, wgpu.Whole_Size)
    render_pass->draw_indexed(ctx.num_indices)
    render_pass->end() or_return

    command_buffer := encoder->finish() or_return
    defer command_buffer->release()

    state.device.queue->submit(command_buffer)
    state.swap_chain->present()

    return .No_Error
}

main :: proc() {
    properties := framework.default_properties
    properties.title = "Tutorial 5 - Textures"

    state, state_err := framework.init(properties)
    if state_err != .No_Error {
        fmt.eprintf("Failed to initialize framework")
        return
    }
    defer framework.deinit()

    if init_example(state) != .No_Error do return
    defer {
        ctx.render_pipeline->release()
        ctx.index_buffer->release()
        ctx.vertex_buffer->release()
        ctx.diffuse_bind_group->release()
        texture_destroy(&ctx.diffuse_texture)
    }

    state.render_proc = render

    framework.begin_run()
}
