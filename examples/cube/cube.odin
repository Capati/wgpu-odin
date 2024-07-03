package cube_example

// Core
import "core:fmt"
import "core:math"
import la "core:math/linalg"

// Package
import wgpu "../../wrapper"
import "../common"
import "./../../utils/shaders"

// Framework
import app "../framework/application"
import "../framework/application/events"
import "../framework/renderer"

DEPTH_FORMAT :: wgpu.Texture_Format.Depth24_Plus

State :: struct {
	using _:                  common.State_Base,
	vertex_buffer:            wgpu.Buffer,
	render_pipeline:          wgpu.Render_Pipeline,
	uniform_buffer:           wgpu.Buffer,
	bind_group:               wgpu.Bind_Group,
	depth_stencil_view:       wgpu.Texture_View,
	depth_stencil_attachment: wgpu.Render_Pass_Depth_Stencil_Attachment,
}

Error :: common.Error

EXAMPLE_TITLE :: "Colored Cube"

init :: proc() -> (state: ^State, err: Error) {
	state = new(State) or_return
	defer if err != nil do free(state)

	app_properties := app.Default_Properties
	app_properties.title = EXAMPLE_TITLE
	app.init(app_properties) or_return
	defer if err != nil do app.deinit()

	state.gpu = renderer.init() or_return
	defer if err != nil do renderer.deinit(state)

	SHADER_SRC: string : #load("./cube.wgsl", string)
	COMBINE_SHADER_SRC := shaders.SRGB_TO_LINEAR_WGSL + SHADER_SRC
	shader_module := wgpu.device_create_shader_module(
		&state.device,
		&{label = EXAMPLE_TITLE + " Module", source = COMBINE_SHADER_SRC},
	) or_return
	defer wgpu.shader_module_release(&shader_module)

	state.vertex_buffer = wgpu.device_create_buffer_with_data(
		&state.device,
		&{
			label = EXAMPLE_TITLE + " Buffer",
			contents = wgpu.to_bytes(vertex_data),
			usage = {.Vertex},
		},
	) or_return
	defer if err != nil do wgpu.buffer_release(&state.vertex_buffer)

	vertex_buffer_layout := wgpu.Vertex_Buffer_Layout {
		array_stride = size_of(Vertex),
		step_mode    = .Vertex,
		attributes   = {
			{format = .Float32x3, offset = 0, shader_location = 0},
			{format = .Float32x3, offset = cast(u64)offset_of(Vertex, color), shader_location = 1},
		},
	}

	pipeline_descriptor := wgpu.Render_Pipeline_Descriptor {
		label = EXAMPLE_TITLE + " Render Pipeline",
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
					blend = &wgpu.Blend_State_Normal,
					write_mask = wgpu.Color_Write_Mask_All,
				},
			},
		},
		primitive = {topology = .Triangle_List, front_face = .CCW, cull_mode = .Back},
		// Enable depth testing so that the fragment closest to the camera
		// is rendered in front.
		depth_stencil = &{
			depth_write_enabled = true,
			depth_compare = .Less,
			format = DEPTH_FORMAT,
			stencil_front = {compare = .Always},
			stencil_back = {compare = .Always},
			stencil_read_mask = 0xFFFFFFFF,
			stencil_write_mask = 0xFFFFFFFF,
		},
		multisample = wgpu.Default_Multisample_State,
	}

	state.render_pipeline = wgpu.device_create_render_pipeline(
		&state.device,
		&pipeline_descriptor,
	) or_return
	defer if err != nil do wgpu.render_pipeline_release(&state.render_pipeline)

	aspect := cast(f32)state.config.width / cast(f32)state.config.height
	mvp_mat := generate_matrix(aspect)

	state.uniform_buffer = wgpu.device_create_buffer_with_data(
		&state.device,
		&{
			label = EXAMPLE_TITLE + " Uniform Buffer",
			contents = wgpu.to_bytes(mvp_mat),
			usage = {.Uniform, .Copy_Dst},
		},
	) or_return
	defer if err != nil do wgpu.buffer_release(&state.uniform_buffer)

	bind_group_layout := wgpu.render_pipeline_get_bind_group_layout(
		&state.render_pipeline,
		0,
	) or_return
	defer wgpu.bind_group_layout_release(&bind_group_layout)

	state.bind_group = wgpu.device_create_bind_group(
		&state.device,
		&{
			layout = bind_group_layout.ptr,
			entries = {
				{
					binding = 0,
					resource = wgpu.Buffer_Binding {
						buffer = state.uniform_buffer.ptr,
						size = state.uniform_buffer.size,
					},
				},
			},
		},
	) or_return
	defer if err != nil do wgpu.bind_group_release(&state.bind_group)

	state.depth_stencil_view = get_depth_framebuffer(
		state,
		{state.config.width, state.config.height},
	) or_return
	defer if err != nil do wgpu.texture_view_release(&state.depth_stencil_view)

	state.depth_stencil_attachment = {
		view              = state.depth_stencil_view.ptr,
		depth_clear_value = 1.0,
		depth_load_op     = .Clear,
		depth_store_op    = .Store,
	}

	state.render_pass_desc = common.create_render_pass_descriptor(
		EXAMPLE_TITLE + " Render Pass",
		wgpu.color_srgb_to_linear(wgpu.Color_Dark_Gray),
	) or_return

	// Get a reference to the first color attachment
	state.color_attachment = &state.render_pass_desc.color_attachments[0]
	state.render_pass_desc.depth_stencil_attachment = &state.depth_stencil_attachment

	return
}

deinit :: proc(using state: ^State) {
	delete(state.render_pass_desc.color_attachments)
	wgpu.texture_view_release(&depth_stencil_view)
	wgpu.bind_group_release(&bind_group)
	wgpu.buffer_release(&uniform_buffer)
	wgpu.render_pipeline_release(&render_pipeline)
	wgpu.buffer_release(&vertex_buffer)
	renderer.deinit(gpu)
	app.deinit()
	free(state)
}

render :: proc(using state: ^State) -> (err: Error) {
	frame := renderer.get_current_texture_frame(gpu) or_return
	if skip_frame do return
	defer wgpu.texture_release_and_nil(&frame.texture)

	view := wgpu.texture_create_view(&frame.texture) or_return
	defer wgpu.texture_view_release(&view)

	encoder := wgpu.device_create_command_encoder(&device) or_return
	defer wgpu.command_encoder_release(&encoder)

	color_attachment.view = view.ptr
	render_pass := wgpu.command_encoder_begin_render_pass(&encoder, &render_pass_desc)
	defer wgpu.render_pass_encoder_release(&render_pass)

	wgpu.render_pass_encoder_set_pipeline(&render_pass, render_pipeline.ptr)
	wgpu.render_pass_encoder_set_bind_group(&render_pass, 0, bind_group.ptr)
	wgpu.render_pass_encoder_set_vertex_buffer(&render_pass, 0, vertex_buffer.ptr)
	wgpu.render_pass_encoder_draw(&render_pass, cast(u32)len(vertex_data))
	wgpu.render_pass_encoder_end(&render_pass) or_return

	command_buffer := wgpu.command_encoder_finish(&encoder) or_return
	defer wgpu.command_buffer_release(&command_buffer)

	wgpu.queue_submit(&queue, command_buffer.ptr)
	wgpu.surface_present(&surface)

	return
}

resize_surface :: proc(using state: ^State, size: app.Physical_Size) -> (err: Error) {
	// Release old depth stencil view and create new one
	wgpu.texture_view_release(&depth_stencil_view)
	depth_stencil_view = get_depth_framebuffer(state, size) or_return
	render_pass_desc.depth_stencil_attachment.view = depth_stencil_view.ptr

	// Update uniform buffer with new aspect ratio
	aspect_ratio := cast(f32)size.width / cast(f32)size.height
	new_matrix := generate_matrix(aspect_ratio)
	wgpu.queue_write_buffer(&queue, uniform_buffer.ptr, 0, wgpu.to_bytes(new_matrix)) or_return

	renderer.resize_surface(gpu, size) or_return

	return
}

handle_events :: proc(state: ^State) -> (should_quit: bool, err: Error) {
	event: events.Event
	for app.poll_event(&event) {
		#partial switch &ev in event {
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

get_depth_framebuffer :: proc(
	using state: ^State,
	size: app.Physical_Size,
) -> (
	view: wgpu.Texture_View,
	err: wgpu.Error,
) {
	texture := wgpu.device_create_texture(
		&device,
		&{
			size = {width = size.width, height = size.height, depth_or_array_layers = 1},
			mip_level_count = 1,
			sample_count = 1,
			dimension = .D2,
			format = DEPTH_FORMAT,
			usage = {.Render_Attachment},
		},
	) or_return
	defer wgpu.texture_release(&texture)

	return wgpu.texture_create_view(&texture)
}

generate_matrix :: proc(aspect: f32) -> la.Matrix4f32 {
	// 72 deg FOV
	projection := la.matrix4_perspective_f32(2 * math.PI / 5, aspect, 1.0, 100.0)
	view := la.matrix4_look_at_f32(
		eye = {1.1, 1.1, 1.1},
		centre = {0.0, 0.0, 0.0},
		up = {0.0, 1.0, 0.0},
	)
	return common.OPEN_GL_TO_WGPU_MATRIX * projection * view
}
