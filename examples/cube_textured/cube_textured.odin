package cube_textured

// Core
import "core:fmt"
import "core:math"
import la "core:math/linalg"
// import "core:math/linalg/glsl"

// Package
import wgpu "../../wrapper"
import "../common"
import "./../../utils/shaders"

// Framework
import app "../framework/application"
import "../framework/application/events"
import "../framework/renderer"

TEXEL_SIZE :: 256

State :: struct {
	using _:         common.State_Base,
	vertex_buffer:   wgpu.Buffer,
	index_buffer:    wgpu.Buffer,
	uniform_buffer:  wgpu.Buffer,
	render_pipeline: wgpu.Render_Pipeline,
	bind_group:      wgpu.Bind_Group,
}

Error :: common.Error

EXAMPLE_TITLE :: "Textured Cube"

init :: proc() -> (state: ^State, err: Error) {
	state = new(State) or_return
	defer if err != nil do free(state)

	app_properties := app.Default_Properties
	app_properties.title = EXAMPLE_TITLE
	app.init(app_properties) or_return
	defer if err != nil do app.deinit()

	state.gpu = renderer.init() or_return
	defer if err != nil do renderer.deinit(state)

	state.vertex_buffer = wgpu.device_create_buffer_with_data(
		state.device,
		{
			label = EXAMPLE_TITLE + " Vertex Buffer",
			contents = wgpu.to_bytes(vertex_data),
			usage = {.Vertex},
		},
	) or_return
	defer if err != nil do wgpu.buffer_release(state.vertex_buffer)

	state.index_buffer = wgpu.device_create_buffer_with_data(
		state.device,
		{
			label = EXAMPLE_TITLE + " Index Buffer",
			contents = wgpu.to_bytes(index_data),
			usage = {.Index},
		},
	) or_return
	defer if err != nil do wgpu.buffer_release(state.index_buffer)

	texture_extent := wgpu.Extent_3D {
		width                 = TEXEL_SIZE,
		height                = TEXEL_SIZE,
		depth_or_array_layers = 1,
	}

	texture := wgpu.device_create_texture(
		state.device,
		{
			size = texture_extent,
			mip_level_count = 1,
			sample_count = 1,
			dimension = .D2,
			format = .R8_Uint,
			usage = {.Texture_Binding, .Copy_Dst},
		},
	) or_return
	defer wgpu.texture_release(texture)

	texture_view := wgpu.texture_create_view(texture) or_return
	defer wgpu.texture_view_release(texture_view)

	texels := create_texels()

	wgpu.queue_write_texture(
		state.queue,
		{texture = texture.ptr, mip_level = 0, origin = {}, aspect = .All},
		wgpu.to_bytes(texels),
		{offset = 0, bytes_per_row = TEXEL_SIZE, rows_per_image = wgpu.COPY_STRIDE_UNDEFINED},
		texture_extent,
	) or_return

	mx_total := generate_matrix(cast(f32)state.config.width / cast(f32)state.config.height)

	state.uniform_buffer = wgpu.device_create_buffer_with_data(
		state.device,
		{
			label = EXAMPLE_TITLE + " Uniform Buffer",
			contents = wgpu.to_bytes(mx_total),
			usage = {.Uniform, .Copy_Dst},
		},
	) or_return
	defer if err != nil do wgpu.buffer_release(state.uniform_buffer)

	SHADER_SRC: string : #load("./cube_textured.wgsl", string)
	COMBINED_SHADER_SRC := shaders.SRGB_TO_LINEAR_WGSL + SHADER_SRC
	shader_module := wgpu.device_create_shader_module(
		state.device,
		{label = EXAMPLE_TITLE + " Module", source = COMBINED_SHADER_SRC},
	) or_return
	defer wgpu.shader_module_release(shader_module)

	vertex_buffer_layout := wgpu.Vertex_Buffer_Layout {
		array_stride = size_of(Vertex),
		step_mode    = .Vertex,
		attributes   = {
			{format = .Float32x4, offset = 0, shader_location = 0},
			{
				format = .Float32x2,
				offset = cast(u64)offset_of(Vertex, tex_coords),
				shader_location = 1,
			},
		},
	}

	state.render_pipeline = wgpu.device_create_render_pipeline(
		state.device,
		{
			vertex = {
				module = shader_module.ptr,
				entry_point = "vs_main",
				buffers = {vertex_buffer_layout},
			},
			fragment = &{
				module = shader_module.ptr,
				entry_point = "fs_main",
				targets = {
					{
						format = state.config.format,
						blend = nil,
						write_mask = wgpu.Color_Write_Mask_All,
					},
				},
			},
			primitive = {topology = .Triangle_List, front_face = .CCW, cull_mode = .Back},
			depth_stencil = nil,
			multisample = wgpu.DEFAULT_MULTISAMPLE_STATE,
		},
	) or_return
	defer if err != nil do wgpu.render_pipeline_release(state.render_pipeline)

	bind_group_layout := wgpu.render_pipeline_get_bind_group_layout(
		state.render_pipeline,
		0,
	) or_return
	defer wgpu.bind_group_layout_release(bind_group_layout)

	state.bind_group = wgpu.device_create_bind_group(
		state.device,
		{
			layout = bind_group_layout.ptr,
			entries = {
				{
					binding = 0,
					resource = wgpu.Buffer_Binding {
						buffer = state.uniform_buffer.ptr,
						size = wgpu.WHOLE_SIZE,
					},
				},
				{binding = 1, resource = texture_view.ptr},
			},
		},
	) or_return
	defer if err != nil do wgpu.bind_group_release(state.bind_group)

	state.render_pass_desc = common.create_render_pass_descriptor(
		EXAMPLE_TITLE + " Render Pass",
		wgpu.color_srgb_to_linear(wgpu.Color{0.1, 0.2, 0.3, 1.0}),
	) or_return

	// Get a reference to the first color attachment
	state.color_attachment = &state.render_pass_desc.color_attachments[0]

	return
}

deinit :: proc(using state: ^State) {
	delete(render_pass_desc.color_attachments)
	wgpu.bind_group_release(bind_group)
	wgpu.render_pipeline_release(render_pipeline)
	wgpu.buffer_release(uniform_buffer)
	wgpu.buffer_release(index_buffer)
	wgpu.buffer_release(vertex_buffer)
	renderer.deinit(gpu)
	app.deinit()
	free(state)
}

create_texels :: proc() -> (texels: [TEXEL_SIZE * TEXEL_SIZE]u8) {
	for id := 0; id < (TEXEL_SIZE * TEXEL_SIZE); id += 1 {
		cx := 3.0 * f32(id % TEXEL_SIZE) / f32(TEXEL_SIZE - 1) - 2.0
		cy := 2.0 * f32(id / TEXEL_SIZE) / f32(TEXEL_SIZE - 1) - 1.0
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

render :: proc(using state: ^State) -> (err: Error) {
	frame := renderer.get_current_texture_frame(gpu) or_return
	if skip_frame do return
	defer renderer.release_current_texture_frame(gpu)

	view := wgpu.texture_create_view(frame.texture) or_return
	defer wgpu.texture_view_release(view)

	encoder := wgpu.device_create_command_encoder(device) or_return
	defer wgpu.command_encoder_release(encoder)

	color_attachment.view = view.ptr
	render_pass := wgpu.command_encoder_begin_render_pass(encoder, render_pass_desc)
	defer wgpu.render_pass_release(render_pass)

	wgpu.render_pass_set_pipeline(render_pass, render_pipeline.ptr)
	wgpu.render_pass_set_bind_group(render_pass, 0, bind_group.ptr, nil)
	wgpu.render_pass_set_vertex_buffer(render_pass, 0, vertex_buffer.ptr)
	wgpu.render_pass_set_index_buffer(render_pass, index_buffer.ptr, .Uint16)
	wgpu.render_pass_draw_indexed(render_pass, {0, u32(len(index_data))}, 0)
	wgpu.render_pass_end(render_pass) or_return

	command_buffer := wgpu.command_encoder_finish(encoder) or_return
	defer wgpu.command_buffer_release(command_buffer)

	wgpu.queue_submit(queue, command_buffer.ptr)
	wgpu.surface_present(surface)

	return
}

resize_surface :: proc(using state: ^State, size: app.Physical_Size) -> (err: Error) {
	wgpu.queue_write_buffer(
		queue,
		uniform_buffer.ptr,
		0,
		wgpu.to_bytes(generate_matrix(cast(f32)size.width / cast(f32)size.height)),
	) or_return

	renderer.resize_surface(gpu, {size.width, size.height}) or_return

	return
}

handle_events :: proc(state: ^State) -> (should_quit: bool, err: Error) {
	event: events.Event
	for app.poll_event(&event) {
		#partial switch ev in event {
		case events.Quit_Event:
			return true, nil
		case events.Framebuffer_Resize_Event:
			if err = resize_surface(state, {ev.width, ev.height}); err != nil {
				return true, err
			}
		}
	}

	return
}

main :: proc() {
	state, state_err := init()
	if state_err != nil do return
	defer deinit(state)

	fmt.printf("Entering main loop...\n\n")

	main_loop: for {
		should_quit, err := handle_events(state)
		if should_quit || err != nil do break main_loop
		if err = render(state); err != nil do break main_loop
	}

	fmt.println("Exiting...")
}
