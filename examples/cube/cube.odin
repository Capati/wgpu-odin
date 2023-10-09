package cube

// Core
import "core:fmt"
import "core:math"
import la "core:math/linalg"
// import "core:math/linalg/glsl"

// Package
import "../framework"
import wgpu "../../wrapper"

State :: framework.State
Physical_Size :: framework.Physical_Size

Example :: struct {
    vertex_buffer:  wgpu.Buffer,
    index_buffer:   wgpu.Buffer,
    uniform_buffer: wgpu.Buffer,
    pipeline:       wgpu.Render_Pipeline,
    bind_group:     wgpu.Bind_Group,
}

ctx := Example{}

Texel_Size :: 256

create_texels :: proc() -> (texels: [Texel_Size * Texel_Size]u8) {
    for id := 0; id < (Texel_Size * Texel_Size); id += 1 {
        cx := 3.0 * f32(id % Texel_Size) / f32(Texel_Size - 1) - 2.0
        cy := 2.0 * f32(id / Texel_Size) / f32(Texel_Size - 1) - 1.0
        x, y, count := f32(cx), f32(cy), u8(0)
        for count < 0xFF && x * x + y * y < 4.0 {
            old_x := x
            x = x * x - y * y + cx
            y = 2.0 * old_x * y + cy
            count += 1
        }
        texels[id] = count
    }

    return
}

generate_matrix :: proc(aspect_ratio: f32) -> la.Matrix4f32 {
    projection := la.matrix4_perspective_f32(math.PI / 4, aspect_ratio, 1.0, 10.0)
    view := la.matrix4_look_at_f32(
        eye = {1.5, -5.0, 3.0},
        centre = {0.0, 0.0, 0.0},
        up = {0.0, 0.0, 1.0},
    )
    return la.mul(projection, view)
}

// generate_matrix :: proc(aspect_ratio: f32) -> glsl.mat4 {
//     projection := glsl.mat4Perspective(math.PI / 4, aspect_ratio, 1.0, 10.0)
//     view := glsl.mat4LookAt({1.5, -5.0, 3.0}, {0.0, 0.0, 0.0}, {0.0, 0.0, 1.0})
//     return projection * view
// }

init_example := proc(using state: ^State) -> (err: wgpu.Error_Type) {
    ctx.vertex_buffer = state.device->create_buffer_with_data(
        &{
            label = "Vertex Buffer",
            contents = wgpu.to_bytes(vertex_data),
            usage = {.Vertex},
        },
    ) or_return
    defer if err != .No_Error do ctx.vertex_buffer->release()

    ctx.index_buffer = state.device->create_buffer_with_data(
        &{
            label = "Index Buffer",
            contents = wgpu.to_bytes(index_data),
            usage = {.Index},
        },
    ) or_return
    defer if err != .No_Error do ctx.index_buffer->release()

    texels := create_texels()
    texture_extent := wgpu.Extent_3D {
        width                 = Texel_Size,
        height                = Texel_Size,
        depth_or_array_layers = 1,
    }
    texture := state.device->create_texture(
        &{
            size = texture_extent,
            mip_level_count = 1,
            sample_count = 1,
            dimension = .D2,
            format = .R8_Uint,
            usage = {.Texture_Binding, .Copy_Dst},
        },
    ) or_return
    defer texture->release()

    texture_view := texture->create_view(nil) or_return
    defer texture_view->release()

    state.device.queue->write_texture(
        &{texture = &texture, mip_level = 0, origin = {}, aspect = .All},
        wgpu.to_bytes(texels),
        &{
            offset = 0,
            bytes_per_row = Texel_Size,
            rows_per_image = cast(u32)wgpu.Copy_Stride_Undefined,
        },
        &texture_extent,
    ) or_return

    mx_total := generate_matrix(
        cast(f32)state.config.width / cast(f32)state.config.height,
    )

    fmt.printf("%#v\n", mx_total)

    ctx.uniform_buffer = state.device->create_buffer_with_data(
        &{
            label = "Uniform Buffer",
            contents = wgpu.to_bytes(mx_total),
            usage = {.Uniform, .Copy_Dst},
        },
    ) or_return
    defer if err != .No_Error do ctx.uniform_buffer->release()

    shader := state.device->load_wgsl_shader_module(
        "assets/cube.wgsl",
        "shader.wgsl",
    ) or_return
    defer shader->release()

    vertex_buffer_layout := wgpu.Vertex_Buffer_Layout {
        array_stride = size_of(Vertex),
        step_mode = .Vertex,
        attributes = {
            {format = .Float32x4, offset = 0, shader_location = 0},
            {
                format = .Float32x2,
                offset = cast(u64)offset_of(Vertex, tex_coords),
                shader_location = 1,
            },
        },
    }

    ctx.pipeline = state.device->create_render_pipeline(
        &{
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
                        blend = nil,
                        write_mask = wgpu.Color_Write_Mask_All,
                    },
                },
            },
            primitive = {
                topology = .Triangle_List,
                front_face = .CCW,
                cull_mode = .Back,
            },
            depth_stencil = nil,
            multisample = wgpu.Multisample_State_Default,
        },
    ) or_return
    defer if err != .No_Error do ctx.pipeline->release()

    bind_group_layout := ctx.pipeline->get_bind_group_layout(0) or_return
    defer bind_group_layout->release()

    ctx.bind_group = state.device->create_bind_group(
        &{
            layout = &bind_group_layout,
            entries = {
                {binding = 0, buffer = &ctx.uniform_buffer, size = wgpu.Whole_Size},
                {binding = 1, texture_view = &texture_view, size = wgpu.Whole_Size},
            },
        },
    ) or_return

    return .No_Error
}

resized :: proc(using state: ^State, size: Physical_Size) -> wgpu.Error_Type {
    mx_total := generate_matrix(cast(f32)size.width / cast(f32)size.height)
    state.device.queue->write_buffer(
        &ctx.uniform_buffer,
        0,
        wgpu.to_bytes(mx_total),
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

    render_pass->set_pipeline(&ctx.pipeline)
    render_pass->set_bind_group(0, &ctx.bind_group, nil)
    render_pass->set_index_buffer(ctx.index_buffer, .Uint16, 0, wgpu.Whole_Size)
    render_pass->set_vertex_buffer(0, ctx.vertex_buffer, 0, wgpu.Whole_Size)
    render_pass->draw_indexed(cast(u32)len(index_data), 1, 0, 0, 0)
    render_pass->end() or_return

    command_buffer := encoder->finish() or_return
    defer command_buffer->release()

    state.device.queue->submit(command_buffer)
    state.swap_chain->present()

    return .No_Error
}

main :: proc() {
    title: cstring = "Textured Cube"
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
        ctx.bind_group->release()
        ctx.pipeline->release()
        ctx.uniform_buffer->release()
        ctx.index_buffer->release()
        ctx.vertex_buffer->release()
    }

    state.render_proc = render
    state.resized_proc = resized

    framework.begin_run()
}
