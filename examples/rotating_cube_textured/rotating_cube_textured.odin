package rotating_cube_textured

// Base
import "base:runtime"

// Core
import "core:log"
import "core:math"
import la "core:math/linalg"
import "core:time"

// Package
import rl "./../../utils/renderlink"
import "./../../utils/shaders"
import wgpu "./../../wrapper"

_ :: log

State :: struct {
	vertex_buffer:      wgpu.Buffer,
	index_buffer:       wgpu.Buffer,
	render_pipeline:    wgpu.Render_Pipeline,
	depth_stencil_view: wgpu.Texture_View,
	uniform_buffer:     wgpu.Buffer,
	cube_texture:       wgpu.Texture,
	cube_texture_view:  wgpu.Texture_View,
	sampler:            wgpu.Sampler,
	uniform_bind_group: wgpu.Bind_Group,
	aspect:             f32,
	projection_matrix:  la.Matrix4f32,
	start_time:         time.Time,
}

App_Context :: rl.Context(State)

EXAMPLE_TITLE :: "Rotating Cube Textured"
DEFAULT_DEPTH_FORMAT :: rl.DEFAULT_DEPTH_FORMAT

init :: proc(using ctx: ^App_Context) -> (err: rl.Error) {
	state.vertex_buffer = wgpu.device_create_buffer_with_data(
		gpu.device,
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
		gpu.device,
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

	attributes := wgpu.vertex_attr_array(2, {0, .Float32x4}, {1, .Float32x2})

	vertex_buffer_layout := wgpu.Vertex_Buffer_Layout {
		array_stride = size_of(Vertex),
		step_mode    = .Vertex,
		attributes   = attributes[:],
		// attributes   = {
		// 	{format = .Float32x4, offset = 0, shader_location = 0},
		// 	{
		// 		format = .Float32x2,
		// 		offset = u64(offset_of(Vertex, tex_coords)),
		// 		shader_location = 1,
		// 	},
		// },
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	ROTATING_CUBE_TEXTURED_WGSL: string : #load("rotating_cube_textured.wgsl", string)
	shader_source := shaders.apply_color_conversion(
		ROTATING_CUBE_TEXTURED_WGSL,
		gpu.is_srgb,
		context.temp_allocator,
	) or_return
	shader_module := wgpu.device_create_shader_module(
		gpu.device,
		{source = shader_source},
	) or_return
	defer wgpu.shader_module_release(shader_module)

	state.render_pipeline = wgpu.device_create_render_pipeline(
		gpu.device,
		descriptor = wgpu.Render_Pipeline_Descriptor {
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
				format = DEFAULT_DEPTH_FORMAT,
				stencil_front = {compare = .Always},
				stencil_back = {compare = .Always},
				stencil_read_mask = 0xFFFFFFFF,
				stencil_write_mask = 0xFFFFFFFF,
			},
			multisample = wgpu.DEFAULT_MULTISAMPLE_STATE,
		},
	) or_return
	defer if err != nil do wgpu.render_pipeline_release(state.render_pipeline)

	state.uniform_buffer = wgpu.device_create_buffer(
		gpu.device,
		descriptor = wgpu.Buffer_Descriptor {
			label = EXAMPLE_TITLE + " Uniform Buffer",
			size  = size_of(la.Matrix4f32), // 4x4 matrix
			usage = {.Uniform, .Copy_Dst},
		},
	) or_return
	defer if err != nil do wgpu.buffer_release(state.uniform_buffer)

	// Load the image and upload it into a Texture.
	state.cube_texture = wgpu.queue_copy_image_to_texture(
		gpu.device,
		gpu.queue,
		"./assets/rotating_cube_textured/odin_logo.png",
	) or_return
	defer if err != nil do wgpu.texture_release(state.cube_texture)

	state.cube_texture_view = wgpu.texture_create_view(state.cube_texture) or_return
	defer if err != nil do wgpu.texture_view_release(state.cube_texture_view)

	sampler_descriptor := wgpu.DEFAULT_SAMPLER_DESCRIPTOR
	// Create a sampler with linear filtering for smooth interpolation.
	sampler_descriptor.mag_filter = .Linear
	sampler_descriptor.min_filter = .Linear

	state.sampler = wgpu.device_create_sampler(gpu.device, sampler_descriptor) or_return
	defer if err != nil do wgpu.sampler_release(state.sampler)

	bind_group_layout := wgpu.render_pipeline_get_bind_group_layout(
		state.render_pipeline,
		0,
	) or_return
	defer wgpu.bind_group_layout_release(bind_group_layout)

	state.uniform_bind_group = wgpu.device_create_bind_group(
		gpu.device,
		{
			layout = bind_group_layout.ptr,
			entries = {
				{
					binding = 0,
					resource = wgpu.Buffer_Binding {
						buffer = state.uniform_buffer.ptr,
						size = state.uniform_buffer.size,
					},
				},
				{binding = 1, resource = state.sampler.ptr},
				{binding = 2, resource = state.cube_texture_view.ptr},
			},
		},
	) or_return
	defer if err != nil do wgpu.bind_group_release(state.uniform_bind_group)

	rl.graphics_clear(rl.Color_Dark_Gray)

	set_projection_matrix(&state, gpu.config.width, gpu.config.height)

	state.start_time = time.now()

	return
}

quit :: proc(using ctx: ^App_Context) {
	wgpu.bind_group_release(state.uniform_bind_group)
	wgpu.texture_view_release(state.cube_texture_view)
	wgpu.sampler_release(state.sampler)
	wgpu.texture_release(state.cube_texture)
	wgpu.buffer_destroy(state.uniform_buffer)
	wgpu.buffer_release(state.uniform_buffer)
	wgpu.render_pipeline_release(state.render_pipeline)
	wgpu.buffer_destroy(state.index_buffer)
	wgpu.buffer_release(state.index_buffer)
	wgpu.buffer_destroy(state.vertex_buffer)
	wgpu.buffer_release(state.vertex_buffer)
}

set_projection_matrix :: proc(using state: ^State, w, h: u32) {
	state.aspect = f32(w) / f32(h)
	state.projection_matrix = la.matrix4_perspective(2 * math.PI / 5, state.aspect, 1, 100.0)
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
	set_projection_matrix(&state, event.width, event.height)
	return
}

update :: proc(dt: f64, using ctx: ^App_Context) -> (err: rl.Error) {
	transformation_matrix := get_transformation_matrix(&state)
	wgpu.queue_write_buffer(
		gpu.queue,
		state.uniform_buffer.ptr,
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
	settings.renderer.depth_format = DEFAULT_DEPTH_FORMAT

	if err := rl.init(state, settings); err != nil do return

	rl.begin_run(state) // Start the main loop
}
