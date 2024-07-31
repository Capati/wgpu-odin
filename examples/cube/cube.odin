package cube_example

// STD Library
import "base:runtime"

// Package
import "../common"
import rl "./../../utils/renderlink"
import "./../../utils/shaders"
import wgpu "./../../wrapper"

State :: struct {
	vertex_buffer:   wgpu.Buffer,
	render_pipeline: wgpu.Render_Pipeline,
	uniform_buffer:  wgpu.Buffer,
	bind_group:      wgpu.Bind_Group,
}

App_Context :: rl.Context(State)

EXAMPLE_TITLE :: "Colored Cube"
DEPTH_FORMAT :: wgpu.Texture_Format.Depth24_Plus

init :: proc(using ctx: ^App_Context) -> (err: rl.Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	CUBE_WGSL: string : #load("./cube.wgsl", string)
	shader_source := shaders.apply_color_conversion(
		CUBE_WGSL,
		gpu.is_srgb,
		context.temp_allocator,
	) or_return
	shader_module := wgpu.device_create_shader_module(
		gpu.device,
		{label = EXAMPLE_TITLE + " Module", source = shader_source},
	) or_return
	defer wgpu.shader_module_release(shader_module)

	vertex_buffer = wgpu.device_create_buffer_with_data(
		gpu.device,
		{
			label = EXAMPLE_TITLE + " Buffer",
			contents = wgpu.to_bytes(vertex_data),
			usage = {.Vertex},
		},
	) or_return
	defer if err != nil do wgpu.buffer_release(vertex_buffer)

	vertex_attributes := wgpu.vertex_attr_array(2, {0, .Float32x3}, {1, .Float32x3})

	vertex_buffer_layout := wgpu.Vertex_Buffer_Layout {
		array_stride = size_of(Vertex),
		step_mode    = .Vertex,
		attributes   = vertex_attributes[:],
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
					format = gpu.config.format,
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
		multisample = wgpu.DEFAULT_MULTISAMPLE_STATE,
	}

	render_pipeline = wgpu.device_create_render_pipeline(gpu.device, pipeline_descriptor) or_return
	defer if err != nil do wgpu.render_pipeline_release(render_pipeline)

	aspect := f32(gpu.config.width) / f32(gpu.config.height)
	mvp_mat := common.create_view_projection_matrix(aspect)

	uniform_buffer = wgpu.device_create_buffer_with_data(
		gpu.device,
		{
			label = EXAMPLE_TITLE + " Uniform Buffer",
			contents = wgpu.to_bytes(mvp_mat),
			usage = {.Uniform, .Copy_Dst},
		},
	) or_return
	defer if err != nil do wgpu.buffer_release(uniform_buffer)

	bind_group_layout := wgpu.render_pipeline_get_bind_group_layout(render_pipeline, 0) or_return
	defer wgpu.bind_group_layout_release(bind_group_layout)

	bind_group = wgpu.device_create_bind_group(
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
	defer if err != nil do wgpu.bind_group_release(bind_group)

	rl.graphics_clear(rl.Color_Dark_Gray)

	return
}

quit :: proc(using ctx: ^App_Context) {
	wgpu.bind_group_release(bind_group)
	wgpu.buffer_release(uniform_buffer)
	wgpu.render_pipeline_release(render_pipeline)
	wgpu.buffer_release(vertex_buffer)
}

resize :: proc(event: rl.Resize_Event, using ctx: ^App_Context) -> (err: rl.Error) {
	// Update uniform buffer with new aspect ratio
	aspect := f32(event.width) / f32(event.height)
	new_matrix := common.create_view_projection_matrix(aspect)
	wgpu.queue_write_buffer(gpu.queue, uniform_buffer.ptr, 0, wgpu.to_bytes(new_matrix)) or_return

	return
}

draw :: proc(using ctx: ^App_Context) -> (err: rl.Error) {
	wgpu.render_pass_set_pipeline(gpu.render_pass, render_pipeline.ptr)
	wgpu.render_pass_set_bind_group(gpu.render_pass, 0, bind_group.ptr)
	wgpu.render_pass_set_vertex_buffer(gpu.render_pass, 0, vertex_buffer.ptr)
	wgpu.render_pass_draw(gpu.render_pass, {0, u32(len(vertex_data))})
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
