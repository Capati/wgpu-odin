package cube_map_example

// STD Library
import "core:math"
import la "core:math/linalg"
import "core:time"

// Package
import "../../utils/shaders"
import wgpu "../../wrapper"
import rl "./../../utils/renderlink"

State :: struct {
	// Buffers
	vertex_buffer:      wgpu.Buffer,
	index_buffer:       wgpu.Buffer,

	// Pipeline setup
	bind_group_layout:  wgpu.Bind_Group_Layout,
	render_pipeline:    wgpu.Render_Pipeline,

	// Texture and related resources
	cubemap_texture:    wgpu.Texture_Resource,

	// Uniform buffer and bind group
	uniform_buffer:     wgpu.Buffer,
	uniform_bind_group: wgpu.Bind_Group,

	// Other state variables
	aspect:             f32,
	projection_matrix:  la.Matrix4f32,
	model_matrix:       la.Matrix4f32,
	start_time:         time.Time,
}

App_Context :: rl.Context(State)

EXAMPLE_TITLE :: "Cubemap"
DEPTH_FORMAT :: wgpu.Texture_Format.Depth24_Plus

init :: proc(using ctx: ^App_Context) -> (err: rl.Error) {
	vertex_buffer = wgpu.device_create_buffer_with_data(
		gpu.device,
		{
			label = EXAMPLE_TITLE + " Vertex Data",
			contents = wgpu.to_bytes(CUBE_VERTEX_DATA),
			usage = {.Vertex},
		},
	) or_return
	defer if err != nil {
		wgpu.buffer_destroy(vertex_buffer)
		wgpu.buffer_release(vertex_buffer)
	}

	index_buffer = wgpu.device_create_buffer_with_data(
		gpu.device,
		{
			label = EXAMPLE_TITLE + " Index Buffer",
			contents = wgpu.to_bytes(CUBE_INDICES_DATA),
			usage = {.Index},
		},
	) or_return
	defer if err != nil {
		wgpu.buffer_destroy(index_buffer)
		wgpu.buffer_release(index_buffer)
	}

	SHADER_SRC: string : #load("cubemap.wgsl", string)
	COMBINED_SHADER_SRC :: shaders.SRGB_TO_LINEAR_WGSL + SHADER_SRC
	shader_module := wgpu.device_create_shader_module(
		gpu.device,
		{source = COMBINED_SHADER_SRC},
	) or_return
	defer wgpu.shader_module_release(shader_module)

	bind_group_layout = wgpu.device_create_bind_group_layout(
	gpu.device,
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
	defer if err != nil do wgpu.bind_group_layout_release(bind_group_layout)

	pipeline_layout := wgpu.device_create_pipeline_layout(
		gpu.device,
		{
			label = EXAMPLE_TITLE + " Pipeline bind group layout",
			bind_group_layouts = {bind_group_layout.ptr},
		},
	) or_return
	defer wgpu.pipeline_layout_release(pipeline_layout)

	attributes := wgpu.vertex_attr_array(2, {0, .Float32x4}, {1, .Float32x2})
	vertex_buffer_layout := wgpu.Vertex_Buffer_Layout {
		array_stride = size_of(Vertex),
		step_mode    = .Vertex,
		attributes   = attributes[:],
	}

	render_pipeline = wgpu.device_create_render_pipeline(
		gpu.device,
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
						format = gpu.config.format,
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
	defer if err != nil do wgpu.render_pipeline_release(render_pipeline)

	cubemap_texture = wgpu.queue_create_cubemap_texture(
		gpu.device,
		gpu.queue,
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
		wgpu.texture_resource_release(cubemap_texture)
	}

	uniform_buffer = wgpu.device_create_buffer(
		gpu.device,
		descriptor = wgpu.Buffer_Descriptor {
			label = EXAMPLE_TITLE + " Uniform Buffer",
			size  = size_of(la.Matrix4f32), // 4x4 matrix
			usage = {.Uniform, .Copy_Dst},
		},
	) or_return
	defer if err != nil do wgpu.buffer_release(uniform_buffer)

	uniform_bind_group = wgpu.device_create_bind_group(
		gpu.device,
		{
			layout = bind_group_layout.ptr,
			entries = {
				{
					binding = 0,
					resource = wgpu.Buffer_Binding {
						buffer = uniform_buffer.ptr,
						size = uniform_buffer.size,
					},
				},
				{binding = 1, resource = cubemap_texture.sampler.ptr},
				{binding = 2, resource = cubemap_texture.view.ptr},
			},
		},
	) or_return
	defer if err != nil do wgpu.bind_group_release(uniform_bind_group)

	model_matrix = la.matrix4_scale_f32({1000.0, 1000.0, 1000.0})
	set_projection_matrix({gpu.config.width, gpu.config.height}, ctx)

	start_time = time.now()

	return
}

quit :: proc(using ctx: ^App_Context) {
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
}

set_projection_matrix :: proc(size: rl.Physical_Size, using ctx: ^App_Context) {
	aspect = f32(gpu.config.width) / f32(gpu.config.height)
	projection_matrix = la.matrix4_perspective((2 * math.PI) / 5, aspect, 1, 3000.0)
}

get_transformation_matrix :: proc(using ctx: ^App_Context) -> (mvp_mat: la.Matrix4f32) {
	now := f32(time.duration_seconds(time.since(start_time))) / 0.8

	rotation_x := la.quaternion_from_euler_angle_x_f32((math.PI / 10) * math.sin(now))
	rotation_y := la.quaternion_from_euler_angle_y_f32(now * 0.2)

	combined_rotation := la.quaternion_mul_quaternion(rotation_x, rotation_y)
	view_matrix := la.matrix4_from_quaternion_f32(combined_rotation)

	mvp_mat = la.matrix_mul(view_matrix, model_matrix)
	mvp_mat = la.matrix_mul(projection_matrix, mvp_mat)

	return
}

update :: proc(dt: f64, using ctx: ^App_Context) -> (err: rl.Error) {
	transformation_matrix := get_transformation_matrix(ctx)
	wgpu.queue_write_buffer(
		gpu.queue,
		uniform_buffer.ptr,
		0,
		wgpu.to_bytes(transformation_matrix),
	) or_return
	return
}

draw :: proc(using ctx: ^App_Context) -> (err: rl.Error) {
	wgpu.render_pass_set_pipeline(gpu.render_pass, render_pipeline.ptr)
	wgpu.render_pass_set_vertex_buffer(gpu.render_pass, 0, vertex_buffer.ptr)
	wgpu.render_pass_set_index_buffer(gpu.render_pass, index_buffer.ptr, .Uint16)
	wgpu.render_pass_set_bind_group(gpu.render_pass, 0, uniform_bind_group.ptr)
	wgpu.render_pass_draw_indexed(gpu.render_pass, {0, u32(len(CUBE_INDICES_DATA))})
	return
}

resize :: proc(event: rl.Resize_Event, using ctx: ^App_Context) -> (err: rl.Error) {
	set_projection_matrix({event.width, event.height}, ctx)
	return
}

main :: proc() {
	state, state_err := new(App_Context)
	if state_err != nil do return
	defer free(state)

	state.callbacks = {
		init   = init,
		quit   = quit,
		resize = resize,
		update = update,
		draw   = draw,
	}

	settings := rl.DEFAULT_SETTINGS
	settings.window.title = EXAMPLE_TITLE
	settings.window.resizable = true

	// Allow to create a depth framebuffer with the given format to be used during draw
	settings.renderer.use_depth_stencil = true
	settings.renderer.depth_format = DEPTH_FORMAT

	if err := rl.init(state, settings); err != nil do return

	rl.begin_run(state) // Start the main loop
}
