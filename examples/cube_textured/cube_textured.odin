package cube_textured

// STD Library
import "base:runtime"
import "core:math"
import la "core:math/linalg"

// Package
import rl "./../../utils/renderlink"
import "./../../utils/shaders"
import wgpu "./../../wrapper"

State :: struct {
	vertex_buffer:   wgpu.Buffer,
	index_buffer:    wgpu.Buffer,
	uniform_buffer:  wgpu.Buffer,
	render_pipeline: wgpu.Render_Pipeline,
	bind_group:      wgpu.Bind_Group,
}

App_Context :: rl.Context(State)

EXAMPLE_TITLE :: "Textured Cube"
TEXEL_SIZE :: 256

init :: proc(using ctx: ^App_Context) -> (err: rl.Error) {
	vertex_buffer = wgpu.device_create_buffer_with_data(
		gpu.device,
		{
			label = EXAMPLE_TITLE + " Vertex Buffer",
			contents = wgpu.to_bytes(vertex_data),
			usage = {.Vertex},
		},
	) or_return
	defer if err != nil do wgpu.buffer_release(vertex_buffer)

	index_buffer = wgpu.device_create_buffer_with_data(
		gpu.device,
		{
			label = EXAMPLE_TITLE + " Index Buffer",
			contents = wgpu.to_bytes(index_data),
			usage = {.Index},
		},
	) or_return
	defer if err != nil do wgpu.buffer_release(index_buffer)

	texture_extent := wgpu.Extent_3D {
		width                 = TEXEL_SIZE,
		height                = TEXEL_SIZE,
		depth_or_array_layers = 1,
	}

	texture := wgpu.device_create_texture(
		gpu.device,
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
		gpu.queue,
		{texture = texture.ptr, mip_level = 0, origin = {}, aspect = .All},
		wgpu.to_bytes(texels),
		{offset = 0, bytes_per_row = TEXEL_SIZE, rows_per_image = wgpu.COPY_STRIDE_UNDEFINED},
		texture_extent,
	) or_return

	mx_total := create_view_projection_matrix(
		cast(f32)gpu.config.width / cast(f32)gpu.config.height,
	)

	uniform_buffer = wgpu.device_create_buffer_with_data(
		gpu.device,
		{
			label = EXAMPLE_TITLE + " Uniform Buffer",
			contents = wgpu.to_bytes(mx_total),
			usage = {.Uniform, .Copy_Dst},
		},
	) or_return
	defer if err != nil do wgpu.buffer_release(uniform_buffer)

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	CUBE_TEXTURED_WGSL: string : #load("./cube_textured.wgsl", string)
	shader_source := shaders.apply_color_conversion(
		CUBE_TEXTURED_WGSL,
		gpu.is_srgb,
		context.temp_allocator,
	) or_return
	shader_module := wgpu.device_create_shader_module(
		gpu.device,
		{label = EXAMPLE_TITLE + " Module", source = shader_source},
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
						blend = nil,
						write_mask = wgpu.Color_Write_Mask_All,
					},
				},
			},
			primitive = {topology = .Triangle_List, front_face = .CCW, cull_mode = .Back},
			multisample = wgpu.DEFAULT_MULTISAMPLE_STATE,
		},
	) or_return
	defer if err != nil do wgpu.render_pipeline_release(render_pipeline)

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
						size = wgpu.WHOLE_SIZE,
					},
				},
				{binding = 1, resource = texture_view.ptr},
			},
		},
	) or_return
	defer if err != nil do wgpu.bind_group_release(bind_group)

	rl.graphics_clear(rl.Color{0.1, 0.2, 0.3, 1.0})

	return
}

quit :: proc(using ctx: ^App_Context) {
	wgpu.bind_group_release(bind_group)
	wgpu.render_pipeline_release(render_pipeline)
	wgpu.buffer_release(uniform_buffer)
	wgpu.buffer_release(index_buffer)
	wgpu.buffer_release(vertex_buffer)
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

create_view_projection_matrix :: proc(aspect: f32) -> la.Matrix4f32 {
	projection := la.matrix4_perspective_f32(math.PI / 4, aspect, 1.0, 10.0)
	view := la.matrix4_look_at_f32(
		eye = {1.5, -5.0, 3.0},
		centre = {0.0, 0.0, 0.0},
		up = {0.0, 0.0, 1.0},
	)
	return la.mul(projection, view)
}

resize :: proc(event: rl.Resize_Event, using ctx: ^App_Context) -> (err: rl.Error) {
	wgpu.queue_write_buffer(
		gpu.queue,
		uniform_buffer.ptr,
		0,
		wgpu.to_bytes(create_view_projection_matrix(f32(event.width) / f32(event.height))),
	) or_return

	return
}

draw :: proc(using ctx: ^App_Context) -> (err: rl.Error) {
	wgpu.render_pass_set_pipeline(gpu.render_pass, render_pipeline.ptr)
	wgpu.render_pass_set_bind_group(gpu.render_pass, 0, bind_group.ptr)
	wgpu.render_pass_set_vertex_buffer(gpu.render_pass, 0, vertex_buffer.ptr)
	wgpu.render_pass_set_index_buffer(gpu.render_pass, index_buffer.ptr, .Uint16)
	wgpu.render_pass_draw_indexed(gpu.render_pass, {0, u32(len(index_data))}, 0)
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

	if err := rl.init(state, settings); err != nil do return

	rl.begin_run(state) // Start the main loop
}
