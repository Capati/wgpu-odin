package rotating_cube_textured

// STD Library
import "base:builtin"
import "base:runtime"
import "core:math"
import la "core:math/linalg"
import "core:time"
@(require) import "core:log"

// Local packages
import rl "./../../utils/renderlink"
import "./../../utils/shaders"
import wgpu "./../../wrapper"

State :: struct {
	vertex_buffer      : wgpu.Buffer,
	index_buffer       : wgpu.Buffer,
	render_pipeline    : wgpu.Render_Pipeline,
	depth_stencil_view : wgpu.Texture_View,
	uniform_buffer     : wgpu.Buffer,
	cube_texture       : wgpu.Texture,
	cube_texture_view  : wgpu.Texture_View,
	sampler            : wgpu.Sampler,
	uniform_bind_group : wgpu.Bind_Group,
	aspect             : f32,
	projection_matrix  : la.Matrix4f32,
	start_time         : time.Time,
}

State_Context :: rl.Context(State)

EXAMPLE_TITLE :: "Rotating Cube Textured"
DEFAULT_DEPTH_FORMAT :: rl.DEFAULT_DEPTH_FORMAT

init :: proc(ctx: ^State_Context) -> (ok: bool) {
	ctx.vertex_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{
			label = EXAMPLE_TITLE + " Vertex Data",
			contents = wgpu.to_bytes(CUBE_VERTEX_DATA),
			usage = {.Vertex},
		},
	) or_return
	defer if !ok do wgpu.buffer_release(ctx.vertex_buffer)

	ctx.index_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{
			label = EXAMPLE_TITLE + " Index Buffer",
			contents = wgpu.to_bytes(CUBE_INDICES_DATA),
			usage = {.Index},
		},
	) or_return
	defer if !ok do wgpu.buffer_release(ctx.index_buffer)

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
		ctx.gpu.is_srgb,
		context.temp_allocator,
	) or_return
	shader_module := wgpu.device_create_shader_module(
		ctx.gpu.device,
		{source = shader_source},
	) or_return
	defer wgpu.shader_module_release(shader_module)

	ctx.render_pipeline = wgpu.device_create_render_pipeline(
		ctx.gpu.device,
		descriptor = wgpu.Render_Pipeline_Descriptor {
			vertex = {
				module = shader_module,
				entry_point = "vs_main",
				buffers = {vertex_buffer_layout},
			},
			fragment = &{
				module = shader_module,
				entry_point = "fs_main",
				targets = {
					{
						format = ctx.gpu.config.format,
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
	defer if !ok do wgpu.render_pipeline_release(ctx.render_pipeline)

	ctx.uniform_buffer = wgpu.device_create_buffer(
		ctx.gpu.device,
		descriptor = wgpu.Buffer_Descriptor {
			label = EXAMPLE_TITLE + " Uniform Buffer",
			size  = size_of(la.Matrix4f32), // 4x4 matrix
			usage = {.Uniform, .Copy_Dst},
		},
	) or_return
	defer if !ok do wgpu.buffer_release(ctx.uniform_buffer)

	// Load the image and upload it into a Texture.
	ctx.cube_texture = wgpu.queue_copy_image_to_texture(
		ctx.gpu.device,
		ctx.gpu.queue,
		"./assets/rotating_cube_textured/odin_logo.png",
	) or_return
	defer if !ok do wgpu.texture_release(ctx.cube_texture)

	ctx.cube_texture_view = wgpu.texture_create_view(ctx.cube_texture) or_return
	defer if !ok do wgpu.texture_view_release(ctx.cube_texture_view)

	sampler_descriptor := wgpu.DEFAULT_SAMPLER_DESCRIPTOR
	// Create a sampler with linear filtering for smooth interpolation.
	sampler_descriptor.mag_filter = .Linear
	sampler_descriptor.min_filter = .Linear

	ctx.sampler = wgpu.device_create_sampler(ctx.gpu.device, sampler_descriptor) or_return
	defer if !ok do wgpu.sampler_release(ctx.sampler)

	bind_group_layout := wgpu.render_pipeline_get_bind_group_layout(
		ctx.render_pipeline,
		0,
	) or_return
	defer wgpu.bind_group_layout_release(bind_group_layout)

	ctx.uniform_bind_group = wgpu.device_create_bind_group(
		ctx.gpu.device,
		{
			layout = bind_group_layout,
			entries = {
				{
					binding = 0,
					resource = wgpu.Buffer_Binding {
						buffer = ctx.uniform_buffer,
						size = wgpu.WHOLE_SIZE,
					},
				},
				{binding = 1, resource = ctx.sampler},
				{binding = 2, resource = ctx.cube_texture_view},
			},
		},
	) or_return
	defer if !ok do wgpu.bind_group_release(ctx.uniform_bind_group)

	rl.graphics_clear(rl.Color_Dark_Gray)

	set_projection_matrix(&ctx.state, ctx.gpu.config.width, ctx.gpu.config.height)

	ctx.start_time = time.now()

	return true
}

quit :: proc(ctx: ^State_Context) {
	wgpu.bind_group_release(ctx.uniform_bind_group)
	wgpu.texture_view_release(ctx.cube_texture_view)
	wgpu.sampler_release(ctx.sampler)
	wgpu.texture_release(ctx.cube_texture)
	wgpu.buffer_destroy(ctx.uniform_buffer)
	wgpu.buffer_release(ctx.uniform_buffer)
	wgpu.render_pipeline_release(ctx.render_pipeline)
	wgpu.buffer_destroy(ctx.index_buffer)
	wgpu.buffer_release(ctx.index_buffer)
	wgpu.buffer_destroy(ctx.vertex_buffer)
	wgpu.buffer_release(ctx.vertex_buffer)
}

set_projection_matrix :: proc(state: ^State, w, h: u32) {
	state.aspect = f32(w) / f32(h)
	state.projection_matrix = la.matrix4_perspective(2 * math.PI / 5, state.aspect, 1, 100.0)
}

get_transformation_matrix :: proc(state: ^State) -> (mvp_mat: la.Matrix4f32) {
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
	mvp_mat = la.matrix_mul(state.projection_matrix, view_matrix)

	return
}

resize :: proc(event: rl.Resize_Event, ctx: ^State_Context) -> bool {
	set_projection_matrix(&ctx.state, event.width, event.height)
	return true
}

update :: proc(dt: f64, ctx: ^State_Context) -> bool {
	transformation_matrix := get_transformation_matrix(&ctx.state)
	wgpu.queue_write_buffer(
		ctx.gpu.queue,
		ctx.uniform_buffer,
		0,
		wgpu.to_bytes(transformation_matrix),
	) or_return

	return true
}

draw :: proc(ctx: ^State_Context) -> bool {
	wgpu.render_pass_set_pipeline(ctx.gpu.render_pass, ctx.render_pipeline)
	wgpu.render_pass_set_bind_group(ctx.gpu.render_pass, 0, ctx.uniform_bind_group)
	wgpu.render_pass_set_vertex_buffer(ctx.gpu.render_pass, 0, ctx.vertex_buffer)
	wgpu.render_pass_set_index_buffer(ctx.gpu.render_pass, ctx.index_buffer, .Uint16)
	wgpu.render_pass_draw_indexed(ctx.gpu.render_pass, {0, u32(len(CUBE_INDICES_DATA))})

	return true
}


main :: proc() {
	when ODIN_DEBUG {
		context.logger = log.create_console_logger(opt = {.Level, .Terminal_Color})
		defer log.destroy_console_logger(context.logger)
	}

	state := builtin.new(State_Context)
	assert(state != nil, "Failed to allocate application state")
	defer builtin.free(state)

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

	if ok := rl.init(state, settings); !ok do return

	rl.begin_run(state) // Start the main loop
}
