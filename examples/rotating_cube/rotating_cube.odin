package rotating_cube

// Core
import "core:fmt"
import "core:math"
import la "core:math/linalg"
import "core:mem"
import "core:slice"
import "core:time"

// Package
import wgpu "../../wrapper"
import "./../../utils/shaders"

// Framework
import app "../framework/application"
import "../framework/application/events"
import "../framework/renderer"

DEPTH_FORMAT :: wgpu.Texture_Format.Depth24_Plus

State :: struct {
	using gpu:                ^renderer.Renderer,
	vertex_buffer:            wgpu.Buffer,
	index_buffer:             wgpu.Buffer,
	render_pipeline:          wgpu.Render_Pipeline,
	depth_stencil_view:       wgpu.Texture_View,
	uniform_buffer:           wgpu.Buffer,
	uniform_bind_group:       wgpu.Bind_Group,
	aspect:                   f32,
	projection_matrix:        la.Matrix4f32,
	start_time:               time.Time,
	render_pass_descriptor:   wgpu.Render_Pass_Descriptor,
	depth_stencil_attachment: wgpu.Render_Pass_Depth_Stencil_Attachment,
}

Error :: union #shared_nil {
	app.Application_Error,
	wgpu.Error,
	mem.Allocator_Error,
}

init_example :: proc() -> (state: ^State, err: Error) {
	state = new(State) or_return
	defer if err != nil do free(state)

	// Initialize the application
	app_properties := app.Default_Properties
	app_properties.title = "Rotating Cube"
	app.init(app_properties) or_return
	defer if err != nil do app.deinit()

	// Initialize the wgpu renderer
	r_properties := renderer.Default_Render_Properties
	state.gpu = renderer.init(r_properties) or_return
	defer if err != nil do renderer.deinit(state)

	state.vertex_buffer = wgpu.device_create_buffer_with_data(
		&state.device,
		&{
			label = "Cube Vertex Data",
			contents = wgpu.to_bytes(CUBE_VERTEX_DATA),
			usage = {.Vertex},
		},
	) or_return
	defer if err != nil {
		wgpu.buffer_destroy(&state.vertex_buffer)
		wgpu.buffer_release(&state.vertex_buffer)
	}

	state.index_buffer = wgpu.device_create_buffer_with_data(
		&state.device,
		&{
			label = "Cube Index Buffer",
			contents = wgpu.to_bytes(CUBE_INDICES_DATA),
			usage = {.Index},
		},
	) or_return
	defer if err != nil {
		wgpu.buffer_destroy(&state.index_buffer)
		wgpu.buffer_release(&state.index_buffer)
	}

	vertex_buffer_layout := wgpu.Vertex_Buffer_Layout {
		array_stride = size_of(Vertex),
		step_mode    = .Vertex,
		attributes   = {
			{format = .Float32x4, offset = 0, shader_location = 0},
			{format = .Float32x4, offset = u64(offset_of(Vertex, color)), shader_location = 1},
			{
				format = .Float32x2,
				offset = u64(offset_of(Vertex, tex_coords)),
				shader_location = 2,
			},
		},
	}

	shader_src: string : #load("rotating_cube.wgsl", string)
	combined_shader_src := shaders.SRGB_TO_LINEAR_WGSL + shader_src
	shader_module := wgpu.device_create_shader_module(
		&state.device,
		&{source = cstring(raw_data(combined_shader_src))},
	) or_return
	defer wgpu.shader_module_release(&shader_module)

	state.render_pipeline = wgpu.device_create_render_pipeline(
		&state.device,
		&{
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
			primitive = {
				topology   = .Triangle_List,
				front_face = .CCW,
				// Backface culling since the cube is solid piece of geometry.
				// Faces pointing away from the camera will be occluded by faces
				// pointing toward the camera.
				cull_mode  = .Back,
			},
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
		},
	) or_return
	defer if err != nil do wgpu.render_pipeline_release(&state.render_pipeline)

	state.uniform_buffer = wgpu.device_create_buffer(
		&state.device,
		&{
			label = "Uniform Buffer",
			size  = 4 * 16, // 4x4 matrix
			usage = {.Uniform, .Copy_Dst},
		},
	) or_return
	defer if err != nil do wgpu.buffer_release(&state.uniform_buffer)

	bind_group_layout := wgpu.render_pipeline_get_bind_group_layout(
		&state.render_pipeline,
		0,
	) or_return
	defer wgpu.bind_group_layout_release(&bind_group_layout)

	state.uniform_bind_group = wgpu.device_create_bind_group(
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
	defer if err != nil do wgpu.bind_group_release(&state.uniform_bind_group)

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

	state.render_pass_descriptor = wgpu.Render_Pass_Descriptor {
		label                    = "Rotating Cube Render Pass",
		color_attachments        = slice.clone(
			[]wgpu.Render_Pass_Color_Attachment {
				{
					view        = nil, // Assigned later
					load_op     = .Clear,
					store_op    = .Store,
					clear_value = wgpu.color_srgb_to_linear(wgpu.Color_Dark_Gray),
				},
			},
		) or_return,
		depth_stencil_attachment = &state.depth_stencil_attachment,
	}

	set_projection_matrix(state)

	state.start_time = time.now()

	return
}

deinit_example :: proc(using state: ^State) {
	delete(state.render_pass_descriptor.color_attachments)
	wgpu.texture_view_release(&depth_stencil_view)
	wgpu.bind_group_release(&uniform_bind_group)
	wgpu.buffer_destroy(&uniform_buffer)
	wgpu.buffer_release(&uniform_buffer)
	wgpu.render_pipeline_release(&render_pipeline)
	wgpu.buffer_destroy(&index_buffer)
	wgpu.buffer_release(&index_buffer)
	wgpu.buffer_destroy(&vertex_buffer)
	wgpu.buffer_release(&vertex_buffer)
	renderer.deinit(gpu)
	app.deinit()
	free(state)
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

set_projection_matrix :: proc(using state: ^State) {
	state.aspect = f32(state.config.width) / f32(state.config.height)
	state.projection_matrix = la.matrix4_perspective(2 * math.PI / 5, state.aspect, 1, 100.0)
}

get_transformation_matrix :: proc(using state: ^State) -> (mvp_mat: la.Matrix4f32) {
	view_matrix := la.MATRIX4F32_IDENTITY

	// Translate
	translation := la.Vector3f32{0, 0, -4}
	view_matrix = la.matrix_mul(view_matrix, la.matrix4_translate(translation))

	// Rotate
	now := f32(time.duration_seconds(time.since(start_time)))
	rotation_axis := la.Vector3f32{math.sin(now), math.cos(now), 0}
	rotation_matrix := la.matrix4_rotate(1, rotation_axis)
	view_matrix = la.matrix_mul(view_matrix, rotation_matrix)

	// Multiply projection and view matrices
	mvp_mat = la.matrix_mul(projection_matrix, view_matrix)

	return
}

render_example :: proc(using state: ^State) -> (err: Error) {
	frame := renderer.get_current_texture_frame(gpu) or_return
	if skip_frame do return
	defer wgpu.texture_release(&frame.texture)

	transformation_matrix := get_transformation_matrix(state)
	wgpu.queue_write_buffer(
		&queue,
		uniform_buffer.ptr,
		0,
		wgpu.to_bytes(transformation_matrix),
	) or_return

	view := wgpu.texture_create_view(&frame.texture, nil) or_return
	defer wgpu.texture_view_release(&view)

	encoder := wgpu.device_create_command_encoder(&device) or_return
	defer wgpu.command_encoder_release(&encoder)

	render_pass_descriptor.color_attachments[0].view = view.ptr
	render_pass := wgpu.command_encoder_begin_render_pass(&encoder, &render_pass_descriptor)

	wgpu.render_pass_encoder_set_pipeline(&render_pass, render_pipeline.ptr)
	wgpu.render_pass_encoder_set_bind_group(&render_pass, 0, uniform_bind_group.ptr)
	wgpu.render_pass_encoder_set_vertex_buffer(&render_pass, 0, vertex_buffer.ptr)
	wgpu.render_pass_encoder_set_index_buffer(&render_pass, index_buffer.ptr, .Uint16)
	wgpu.render_pass_encoder_draw_indexed(&render_pass, u32(len(CUBE_INDICES_DATA)))

	wgpu.render_pass_encoder_end(&render_pass) or_return
	wgpu.render_pass_encoder_release(&render_pass)

	command_buffer := wgpu.command_encoder_finish(&encoder) or_return
	defer wgpu.command_buffer_release(&command_buffer)

	wgpu.queue_submit(&queue, command_buffer.ptr)
	wgpu.surface_present(&surface)

	return
}

resize_surface :: proc(using state: ^State, size: app.Physical_Size) -> (err: Error) {
	wgpu.texture_view_release(&depth_stencil_view)
	depth_stencil_view = get_depth_framebuffer(state, size) or_return
	render_pass_descriptor.depth_stencil_attachment.view = depth_stencil_view.ptr

	renderer.resize_surface(gpu, {size.width, size.height}) or_return

	set_projection_matrix(state)

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
	state, state_err := init_example()
	if state_err != nil do return
	defer deinit_example(state)

	fmt.printf("Entering main loop...\n\n")

	main_loop: for {
		should_quit, err := handle_events(state)
		if should_quit || err != nil do break main_loop
		if err = render_example(state); err != nil do break main_loop
	}

	fmt.println("Exiting...")
}
