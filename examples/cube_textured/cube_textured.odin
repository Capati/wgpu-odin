package cube_textured

// Core
import "core:fmt"
import "core:math"
import la "core:math/linalg"
// import "core:math/linalg/glsl"

// Package
import wgpu "../../wrapper"

// Framework
import app "../framework/application"
import "../framework/application/events"
import "../framework/renderer"

Texel_Size :: 256

State :: struct {
	gpu:             ^renderer.Renderer,
	vertex_buffer:   wgpu.Buffer,
	index_buffer:    wgpu.Buffer,
	uniform_buffer:  wgpu.Buffer,
	render_pipeline: wgpu.Render_Pipeline,
	bind_group:      wgpu.Bind_Group,
}

Error :: union #shared_nil {
	app.Application_Error,
	renderer.Renderer_Error,
	wgpu.Error_Type,
}

init_example :: proc() -> (state: State, err: Error) {
	state.gpu = renderer.init() or_return
	defer if err != nil do renderer.deinit(state.gpu)

	state.vertex_buffer = wgpu.device_create_buffer_with_data(
		&state.gpu.device,
		&{label = "Vertex Buffer", contents = wgpu.to_bytes(vertex_data), usage = {.Vertex}},
	) or_return
	defer if err != nil do wgpu.buffer_release(&state.vertex_buffer)

	state.index_buffer = wgpu.device_create_buffer_with_data(
		&state.gpu.device,
		&{label = "Index Buffer", contents = wgpu.to_bytes(index_data), usage = {.Index}},
	) or_return
	defer if err != nil do wgpu.buffer_release(&state.index_buffer)

	texture_extent := wgpu.Extent_3D {
		width                 = Texel_Size,
		height                = Texel_Size,
		depth_or_array_layers = 1,
	}

	texture := wgpu.device_create_texture(
		&state.gpu.device,
		& {
			size = texture_extent,
			mip_level_count = 1,
			sample_count = 1,
			dimension = .D2,
			format = .R8_Uint,
			usage = {.Texture_Binding, .Copy_Dst},
		},
	) or_return
	defer wgpu.texture_release(&texture)

	texture_view := wgpu.texture_create_view(&texture, nil) or_return
	defer wgpu.texture_view_release(&texture_view)

	texels := create_texels()

	wgpu.queue_write_texture(
		&state.gpu.queue,
		&{texture = &texture, mip_level = 0, origin = {}, aspect = .All},
		wgpu.to_bytes(texels),
		& {
			offset = 0,
			bytes_per_row = Texel_Size,
			rows_per_image = cast(u32)wgpu.COPY_STRIDE_UNDEFINED,
		},
		&texture_extent,
	) or_return

	mx_total := generate_matrix(cast(f32)state.gpu.config.width / cast(f32)state.gpu.config.height)

	state.uniform_buffer = wgpu.device_create_buffer_with_data(
		&state.gpu.device,
		& {
			label = "Uniform Buffer",
			contents = wgpu.to_bytes(mx_total),
			usage = {.Uniform, .Copy_Dst},
		},
	) or_return
	defer if err != nil do wgpu.buffer_release(&state.uniform_buffer)

	shader_source := #load("./cube_textured.wgsl")

	shader_module := wgpu.device_create_shader_module(
		&state.gpu.device,
		&{label = "Texture cube shader", source = cstring(raw_data(shader_source))},
	) or_return
	defer wgpu.shader_module_release(&shader_module)

	vertex_buffer_layout := wgpu.Vertex_Buffer_Layout {
		array_stride = size_of(Vertex),
		step_mode = .Vertex,
		attributes =  {
			{format = .Float32x4, offset = 0, shader_location = 0},
			 {
				format = .Float32x2,
				offset = cast(u64)offset_of(Vertex, tex_coords),
				shader_location = 1,
			},
		},
	}

	state.render_pipeline = wgpu.device_create_render_pipeline(
		&state.gpu.device,
		& {
			vertex =  {
				module = &shader_module,
				entry_point = "vs_main",
				buffers = {vertex_buffer_layout},
			},
			fragment = & {
				module = &shader_module,
				entry_point = "fs_main",
				targets =  {
					 {
						format = state.gpu.config.format,
						blend = nil,
						write_mask = wgpu.Color_Write_Mask_All,
					},
				},
			},
			primitive = {topology = .Triangle_List, front_face = .CCW, cull_mode = .Back},
			depth_stencil = nil,
			multisample = wgpu.Default_Multisample_State,
		},
	) or_return
	defer if err != nil do wgpu.render_pipeline_release(&state.render_pipeline)

	bind_group_layout := wgpu.render_pipeline_get_bind_group_layout(
		&state.render_pipeline,
		0,
	) or_return
	defer wgpu.bind_group_layout_release(&bind_group_layout)

	state.bind_group = wgpu.device_create_bind_group(
		&state.gpu.device,
		& {
			layout = &bind_group_layout,
			entries =  {
				 {
					binding = 0,
					resource = wgpu.Buffer_Binding {
						buffer = &state.uniform_buffer,
						size = wgpu.WHOLE_SIZE,
					},
				},
				{binding = 1, resource = &texture_view},
			},
		},
	) or_return

	return
}

render :: proc(using state: ^State) -> (err: Error) {
	frame := renderer.get_current_texture_frame(gpu) or_return
	defer wgpu.texture_release(&frame.texture)
	if gpu.skip_frame do return

	view := wgpu.texture_create_view(&frame.texture, nil) or_return
	defer wgpu.texture_view_release(&view)

	encoder := wgpu.device_create_command_encoder(&gpu.device) or_return
	defer wgpu.command_encoder_release(&encoder)

	render_pass := wgpu.command_encoder_begin_render_pass(
		&encoder,
		& {
			label = "Render Pass",
			color_attachments = []wgpu.Render_Pass_Color_Attachment {
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
	defer wgpu.render_pass_release(&render_pass)

	wgpu.render_pass_set_pipeline(&render_pass, &render_pipeline)
	wgpu.render_pass_set_bind_group(&render_pass, 0, &bind_group, nil)
	wgpu.render_pass_set_index_buffer(&render_pass, index_buffer, .Uint16, 0, wgpu.WHOLE_SIZE)
	wgpu.render_pass_set_vertex_buffer(&render_pass, 0, vertex_buffer, 0, wgpu.WHOLE_SIZE)
	wgpu.render_pass_draw_indexed(&render_pass, cast(u32)len(index_data), 1, 0, 0, 0)
	wgpu.render_pass_end(&render_pass) or_return

	command_buffer := wgpu.command_encoder_finish(&encoder, "Default command buffer") or_return
	defer wgpu.command_buffer_release(&command_buffer)

	wgpu.queue_submit(&gpu.queue, &command_buffer)
	wgpu.surface_present(&gpu.surface)

	return
}

resize_surface :: proc(using state: ^State, size: app.Physical_Size) -> (err: Error) {
	wgpu.queue_write_buffer(
		&gpu.queue,
		&uniform_buffer,
		0,
		wgpu.to_bytes(generate_matrix(cast(f32)size.width / cast(f32)size.height)),
	) or_return

	renderer.resize_surface(gpu, {size.width, size.height}) or_return

	return
}

main :: proc() {
	app_properties := app.Default_Properties
	app_properties.title = "Textured Cube"
	if app.init(app_properties) != .No_Error do return
	defer app.deinit()

	state, state_err := init_example()
	if state_err != nil do return
	defer renderer.deinit(state.gpu)

	fmt.printf("Entering main loop...\n\n")

	main_loop: for {
		iter := app.process_events()

		for iter->has_next() {
			#partial switch event in iter->next() {
			case events.Quit_Event:
				break main_loop
			case events.Framebuffer_Resize_Event:
				if err := resize_surface(&state, {event.width, event.height}); err != nil {
					fmt.eprintf(
						"Error occurred while resizing [%v]: %v\n",
						err,
						wgpu.get_error_message(),
					)
					break main_loop
				}
			}
		}

		if err := render(&state); err != nil {
			fmt.eprintf("Error occurred while rendering [%v]: %v\n", err, wgpu.get_error_message())
			break main_loop
		}
	}

	// deinit state
	wgpu.bind_group_release(&state.bind_group)
	wgpu.render_pipeline_release(&state.render_pipeline)
	wgpu.buffer_release(&state.uniform_buffer)
	wgpu.buffer_release(&state.index_buffer)
	wgpu.buffer_release(&state.vertex_buffer)

	fmt.println("Exiting...")
}

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
