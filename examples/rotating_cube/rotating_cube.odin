package rotating_cube

// STD Library
import "base:runtime"
import "core:math"
import la "core:math/linalg"
import "core:time"

// Package
import rl "./../../utils/renderlink"
import "./../../utils/shaders"
import wgpu "./../../wrapper"

State :: struct {
	vertex_buffer:      wgpu.Buffer,
	index_buffer:       wgpu.Buffer,
	render_pipeline:    wgpu.Render_Pipeline,
	uniform_buffer:     wgpu.Buffer,
	uniform_bind_group: wgpu.Bind_Group,
	aspect:             f32,
	projection_matrix:  la.Matrix4f32,
	start_time:         time.Time,
}

App_Context :: rl.Context(State)

EXAMPLE_TITLE :: "Rotating Cube"
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

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	ROTATING_CUBE_WGSL: string : #load("rotating_cube.wgsl", string)
	shader_source := shaders.apply_color_conversion(
		ROTATING_CUBE_WGSL,
		gpu.is_srgb,
		context.temp_allocator,
	) or_return
	shader_module := wgpu.device_create_shader_module(
		gpu.device,
		{source = shader_source},
	) or_return
	defer wgpu.shader_module_release(shader_module)

	render_pipeline = wgpu.device_create_render_pipeline(
	gpu.device,
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
					format = gpu.config.format,
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
		multisample = wgpu.DEFAULT_MULTISAMPLE_STATE,
	},
	) or_return
	defer if err != nil do wgpu.render_pipeline_release(render_pipeline)

	uniform_buffer = wgpu.device_create_buffer(
	gpu.device,
	{
		label = EXAMPLE_TITLE + " Uniform Buffer",
		size  = 4 * 16, // 4x4 matrix
		usage = {.Uniform, .Copy_Dst},
	},
	) or_return
	defer if err != nil do wgpu.buffer_release(uniform_buffer)

	bind_group_layout := wgpu.render_pipeline_get_bind_group_layout(render_pipeline, 0) or_return
	defer wgpu.bind_group_layout_release(bind_group_layout)

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
			},
		},
	) or_return
	defer if err != nil do wgpu.bind_group_release(uniform_bind_group)

	rl.graphics_clear(rl.Color_Dark_Gray)

	set_projection_matrix({gpu.config.width, gpu.config.height}, ctx)

	start_time = time.now()

	return
}

quit :: proc(using ctx: ^App_Context) {
	wgpu.bind_group_release(uniform_bind_group)
	wgpu.buffer_destroy(uniform_buffer)
	wgpu.buffer_release(uniform_buffer)
	wgpu.render_pipeline_release(render_pipeline)
	wgpu.buffer_destroy(index_buffer)
	wgpu.buffer_release(index_buffer)
	wgpu.buffer_destroy(vertex_buffer)
	wgpu.buffer_release(vertex_buffer)
}

set_projection_matrix :: proc(size: rl.Physical_Size, using ctx: ^App_Context) {
	aspect = f32(size.width) / f32(size.height)
	projection_matrix = la.matrix4_perspective(2 * math.PI / 5, aspect, 1, 100.0)
}

get_transformation_matrix :: proc(using state: ^State) -> (mvp_mat: la.Matrix4f32) {
	view_matrix := la.MATRIX4F32_IDENTITY

	// Translate
	translation := la.Vector3f32{0, 0, -4}
	view_matrix = la.matrix_mul(view_matrix, la.matrix4_translate(translation))

	// Rotate
	now := f32(rl.timer_get_time())
	rotation_axis := la.Vector3f32{math.sin(now), math.cos(now), 0}
	rotation_matrix := la.matrix4_rotate(1, rotation_axis)
	view_matrix = la.matrix_mul(view_matrix, rotation_matrix)

	// Multiply projection and view matrices
	mvp_mat = la.matrix_mul(projection_matrix, view_matrix)

	return
}

resize :: proc(event: rl.Resize_Event, using ctx: ^App_Context) -> (err: rl.Error) {
	set_projection_matrix({event.width, event.height}, ctx)
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
	wgpu.render_pass_set_bind_group(gpu.render_pass, 0, uniform_bind_group.ptr)
	wgpu.render_pass_set_vertex_buffer(gpu.render_pass, 0, vertex_buffer.ptr)
	wgpu.render_pass_set_index_buffer(gpu.render_pass, index_buffer.ptr, .Uint16)
	wgpu.render_pass_draw_indexed(gpu.render_pass, {0, u32(len(CUBE_INDICES_DATA))})
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
