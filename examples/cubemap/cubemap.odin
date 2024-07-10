package cube_map_example

// Core
import "core:fmt"
import "core:math"
import la "core:math/linalg"
import "core:time"

// Package
import "../../utils/shaders"
import wgpu "../../wrapper"
import "./../common"

// Framework
import app "../framework/application"
import "../framework/application/events"
import "../framework/renderer"

DEPTH_FORMAT :: wgpu.Texture_Format.Depth24_Plus

State :: struct {
	using _:                  common.State_Base,

	// Buffers
	vertex_buffer:            wgpu.Buffer,
	index_buffer:             wgpu.Buffer,

	// Pipeline setup
	bind_group_layout:        wgpu.Bind_Group_Layout,
	render_pipeline:          wgpu.Render_Pipeline,

	// Texture and related resources
	cubemap_texture:          wgpu.Texture_Resource,

	// Uniform buffer and bind group
	uniform_buffer:           wgpu.Buffer,
	uniform_bind_group:       wgpu.Bind_Group,

	// Render pass related
	depth_stencil_view:       wgpu.Texture_View,
	depth_stencil_attachment: wgpu.Render_Pass_Depth_Stencil_Attachment,

	// Other state variables
	aspect:                   f32,
	projection_matrix:        la.Matrix4f32,
	model_matrix:             la.Matrix4f32,
	start_time:               time.Time,
}

Error :: common.Error

EXAMPLE_TITLE :: "Cubemap"

init :: proc() -> (state: ^State, err: Error) {
	state = new(State) or_return
	defer if err != nil do free(state)

	// Initialize the application
	app_properties := app.Default_Properties
	app_properties.title = EXAMPLE_TITLE
	app.init(app_properties) or_return
	defer if err != nil do app.deinit()

	// Initialize the wgpu renderer
	r_properties := renderer.Default_Render_Properties
	state.gpu = renderer.init(r_properties) or_return
	defer if err != nil do renderer.deinit(state)

	state.vertex_buffer = wgpu.device_create_buffer_with_data(
		state.device,
		{
			label = EXAMPLE_TITLE + " Vertex Data",
			contents = wgpu.to_bytes(CUBE_VERTEX_DATA),
			usage = {.Vertex},
		},
	) or_return
	defer if err != nil {
		wgpu.buffer_destroy(state.vertex_buffer)
		wgpu.buffer_release(state.vertex_buffer)
	}

	state.index_buffer = wgpu.device_create_buffer_with_data(
		state.device,
		{
			label = EXAMPLE_TITLE + " Index Buffer",
			contents = wgpu.to_bytes(CUBE_INDICES_DATA),
			usage = {.Index},
		},
	) or_return
	defer if err != nil {
		wgpu.buffer_destroy(state.index_buffer)
		wgpu.buffer_release(state.index_buffer)
	}

	SHADER_SRC: string : #load("cubemap.wgsl", string)
	COMBINED_SHADER_SRC :: shaders.SRGB_TO_LINEAR_WGSL + SHADER_SRC
	shader_module := wgpu.device_create_shader_module(
		state.device,
		{source = COMBINED_SHADER_SRC},
	) or_return
	defer wgpu.shader_module_release(shader_module)

	state.bind_group_layout = wgpu.device_create_bind_group_layout(
	state.device,
	{
		label   = EXAMPLE_TITLE + " Bind group layout",
		entries = {
			{
				binding = 0,
				visibility = {.Vertex},
				type = wgpu.Buffer_Binding_Layout {
					type             = .Uniform,
					min_binding_size = size_of(la.Matrix4f32), // 4x4 matrix,
				},
			},
			{
				binding = 1,
				visibility = {.Fragment},
				type = wgpu.Sampler_Binding_Layout{type = .Filtering},
			},
			{
				binding = 2,
				visibility = {.Fragment},
				type = wgpu.Texture_Binding_Layout{sample_type = .Float, view_dimension = .Cube},
			},
		},
	},
	) or_return
	defer if err != nil do wgpu.bind_group_layout_release(state.bind_group_layout)

	pipeline_layout := wgpu.device_create_pipeline_layout(
		state.device,
		{
			label = EXAMPLE_TITLE + " Pipeline bind group layout",
			bind_group_layouts = {state.bind_group_layout.ptr},
		},
	) or_return
	defer wgpu.pipeline_layout_release(pipeline_layout)

	attributes := wgpu.vertex_attr_array(2, {0, .Float32x4}, {1, .Float32x2})
	vertex_buffer_layout := wgpu.Vertex_Buffer_Layout {
		array_stride = size_of(Vertex),
		step_mode    = .Vertex,
		attributes   = attributes[:],
	}

	state.render_pipeline = wgpu.device_create_render_pipeline(
		state.device,
		descriptor = wgpu.Render_Pipeline_Descriptor {
			layout = pipeline_layout.ptr,
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
				// Since we are seeing from inside of the cube
				// and we are using the regular cube geomtry data with outward-facing normals,
				// the cullMode should be 'front' or 'none'.
				cull_mode  = .Front,
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
			multisample = wgpu.DEFAULT_MULTISAMPLE_STATE,
		},
	) or_return
	defer if err != nil do wgpu.render_pipeline_release(state.render_pipeline)

	state.cubemap_texture = wgpu.queue_create_cubemap_texture(
		state.device,
		state.queue,
		{
			"./assets/cubemap/posx.jpg",
			"./assets/cubemap/negx.jpg",
			"./assets/cubemap/posy.jpg",
			"./assets/cubemap/negy.jpg",
			"./assets/cubemap/posz.jpg",
			"./assets/cubemap/negz.jpg",
		},
	) or_return
	defer if err != nil {
		wgpu.texture_resource_release(state.cubemap_texture)
	}

	state.uniform_buffer = wgpu.device_create_buffer(
		state.device,
		descriptor = wgpu.Buffer_Descriptor {
			label = EXAMPLE_TITLE + " Uniform Buffer",
			size  = size_of(la.Matrix4f32), // 4x4 matrix
			usage = {.Uniform, .Copy_Dst},
		},
	) or_return
	defer if err != nil do wgpu.buffer_release(state.uniform_buffer)

	state.uniform_bind_group = wgpu.device_create_bind_group(
		state.device,
		{
			layout = state.bind_group_layout.ptr,
			entries = {
				{
					binding = 0,
					resource = wgpu.Buffer_Binding {
						buffer = state.uniform_buffer.ptr,
						size = state.uniform_buffer.size,
					},
				},
				{binding = 1, resource = state.cubemap_texture.sampler.ptr},
				{binding = 2, resource = state.cubemap_texture.view.ptr},
			},
		},
	) or_return
	defer if err != nil do wgpu.bind_group_release(state.uniform_bind_group)

	state.render_pass_desc = common.create_render_pass_descriptor(
		EXAMPLE_TITLE + " Render Pass",
		wgpu.color_srgb_to_linear(wgpu.Color_Dark_Gray),
	) or_return

	// Get a reference to the first color attachment
	state.color_attachment = &state.render_pass_desc.color_attachments[0]

	state.depth_stencil_view = common.get_depth_framebuffer(
		state.gpu,
		DEPTH_FORMAT,
		state.config.width,
		state.config.height,
	) or_return
	defer if err != nil do wgpu.texture_view_release(state.depth_stencil_view)

	state.depth_stencil_attachment = {
		view              = state.depth_stencil_view.ptr,
		depth_clear_value = 1.0,
		depth_load_op     = .Clear,
		depth_store_op    = .Store,
	}

	state.render_pass_desc.depth_stencil_attachment = &state.depth_stencil_attachment

	state.model_matrix = la.matrix4_scale_f32({1000.0, 1000.0, 1000.0})
	set_projection_matrix(state)

	state.start_time = time.now()

	return
}

deinit :: proc(using state: ^State) {
	// Release render pass related resources
	delete(render_pass_desc.color_attachments)
	wgpu.texture_view_release(depth_stencil_view)

	// Release bind group and related resources
	wgpu.bind_group_release(uniform_bind_group)
	wgpu.buffer_destroy(uniform_buffer)
	wgpu.buffer_release(uniform_buffer)

	// Release texture resources
	wgpu.texture_resource_release(cubemap_texture)

	// Release pipeline and related resources
	wgpu.render_pipeline_release(render_pipeline)
	wgpu.bind_group_layout_release(bind_group_layout)

	// Release buffer resources
	wgpu.buffer_destroy(index_buffer)
	wgpu.buffer_release(index_buffer)
	wgpu.buffer_destroy(vertex_buffer)
	wgpu.buffer_release(vertex_buffer)

	// Deinit renderer and app
	renderer.deinit(gpu)
	app.deinit()

	// Free the state
	free(state)
}

set_projection_matrix :: proc(using state: ^State) {
	state.aspect = f32(state.config.width) / f32(state.config.height)
	state.projection_matrix = la.matrix4_perspective((2 * math.PI) / 5, state.aspect, 1, 3000.0)
}

get_transformation_matrix :: proc(using state: ^State) -> (mvp_mat: la.Matrix4f32) {
	now := f32(time.duration_seconds(time.since(start_time))) / 0.8

	rotation_x := la.quaternion_from_euler_angle_x_f32((math.PI / 10) * math.sin(now))
	rotation_y := la.quaternion_from_euler_angle_y_f32(now * 0.2)

	combined_rotation := la.quaternion_mul_quaternion(rotation_x, rotation_y)
	view_matrix := la.matrix4_from_quaternion_f32(combined_rotation)

	mvp_mat = la.matrix_mul(view_matrix, model_matrix)
	mvp_mat = la.matrix_mul(projection_matrix, mvp_mat)

	return
}

render :: proc(using state: ^State) -> (err: Error) {
	frame := renderer.get_current_texture_frame(gpu) or_return
	if skip_frame do return
	defer renderer.release_current_texture_frame(gpu)

	transformation_matrix := get_transformation_matrix(state)
	wgpu.queue_write_buffer(
		queue,
		uniform_buffer.ptr,
		0,
		wgpu.to_bytes(transformation_matrix),
	) or_return

	view := wgpu.texture_create_view(frame.texture) or_return
	defer wgpu.texture_view_release(view)

	encoder := wgpu.device_create_command_encoder(device) or_return
	defer wgpu.command_encoder_release(encoder)

	color_attachment.view = view.ptr
	render_pass := wgpu.command_encoder_begin_render_pass(encoder, render_pass_desc)
	defer wgpu.render_pass_release(render_pass)

	wgpu.render_pass_set_pipeline(render_pass, render_pipeline.ptr)
	wgpu.render_pass_set_vertex_buffer(render_pass, 0, vertex_buffer.ptr)
	wgpu.render_pass_set_index_buffer(render_pass, index_buffer.ptr, .Uint16)
	wgpu.render_pass_set_bind_group(render_pass, 0, uniform_bind_group.ptr)
	wgpu.render_pass_draw_indexed(render_pass, {0, u32(len(CUBE_INDICES_DATA))})

	wgpu.render_pass_end(render_pass) or_return

	command_buffer := wgpu.command_encoder_finish(encoder) or_return
	defer wgpu.command_buffer_release(command_buffer)

	wgpu.queue_submit(queue, command_buffer.ptr)
	wgpu.surface_present(surface)

	return
}

resize_surface :: proc(using state: ^State, size: app.Physical_Size) -> (err: Error) {
	wgpu.texture_view_release(depth_stencil_view)
	depth_stencil_view = common.get_depth_framebuffer(
		gpu,
		DEPTH_FORMAT,
		size.width,
		size.height,
	) or_return
	render_pass_desc.depth_stencil_attachment.view = depth_stencil_view.ptr

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
