package fractal_cube

// Packages
import "core:log"
import "core:math"
import la "core:math/linalg"

// Local packages
import app "root:utils/application"
import "root:wgpu"

Example :: struct {
	vertex_buffer:      wgpu.Buffer,
	index_buffer:       wgpu.Buffer,
	render_pipeline:    wgpu.Render_Pipeline,
	uniform_buffer:     wgpu.Buffer,
	uniform_bind_group: wgpu.Bind_Group,
	projection_matrix:  la.Matrix4f32,
	// We will copy the frame's rendering results into this texture and
	// sample it on the next frame.
	cube_texture:       wgpu.Texture,
	cube_view:          wgpu.Texture_View,
	sampler:            wgpu.Sampler,
	render_pass:        struct {
		color_attachments: [1]wgpu.Render_Pass_Color_Attachment,
		descriptor:        wgpu.Render_Pass_Descriptor,
	},
}

Context :: app.Context(Example)

EXAMPLE_TITLE :: "Fractal Cube"
DEPTH_FORMAT :: wgpu.Texture_Format.Depth24_Plus

init :: proc(ctx: ^Context) -> (ok: bool) {
	ctx.vertex_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{
			label = EXAMPLE_TITLE + " Vertex Data",
			contents = wgpu.to_bytes(CUBE_VERTEX_DATA),
			usage = {.Vertex},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.vertex_buffer)
	}

	ctx.index_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{
			label = EXAMPLE_TITLE + " Index Buffer",
			contents = wgpu.to_bytes(CUBE_INDICES_DATA),
			usage = {.Index},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.index_buffer)
	}

	vertex_buffer_layout := wgpu.Vertex_Buffer_Layout {
		array_stride = size_of(Vertex),
		step_mode    = .Vertex,
		attributes   = {
			{format = .Float32x4, offset = 0, shader_location = 0},
			{
				format = .Float32x2,
				offset = u64(offset_of(Vertex, tex_coords)),
				shader_location = 1,
			},
		},
	}

	ROTATING_CUBE_WGSL :: #load("./fractal_cube.wgsl", string)
	shader_module := wgpu.device_create_shader_module(
		ctx.gpu.device,
		{source = ROTATING_CUBE_WGSL},
	) or_return
	defer wgpu.release(shader_module)

	depth_stencil_state := app.create_depth_stencil_state(ctx)

	ctx.render_pipeline = wgpu.device_create_render_pipeline(
	ctx.gpu.device,
	{
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
					blend = &wgpu.BLEND_STATE_NORMAL,
					write_mask = wgpu.COLOR_WRITES_ALL,
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
		depth_stencil = depth_stencil_state,
		multisample = wgpu.DEFAULT_MULTISAMPLE_STATE,
	},
	) or_return
	defer if !ok {
		wgpu.release(ctx.render_pipeline)
	}

	ctx.uniform_buffer = wgpu.device_create_buffer(
	ctx.gpu.device,
	{
		label = EXAMPLE_TITLE + " Uniform Buffer",
		size  = 4 * 16, // 4x4 matrix
		usage = {.Uniform, .Copy_Dst},
	},
	) or_return
	defer if !ok {
		wgpu.release(ctx.uniform_buffer)
	}

	create_cube_texture(ctx) or_return

	sampler_descriptor := wgpu.DEFAULT_SAMPLER_DESCRIPTOR
	sampler_descriptor.mag_filter = .Linear
	sampler_descriptor.min_filter = .Linear
	ctx.sampler = wgpu.device_create_sampler(ctx.gpu.device, sampler_descriptor) or_return
	defer if !ok {
		wgpu.release(ctx.sampler)
	}

	bind_group_layout := wgpu.render_pipeline_get_bind_group_layout(
		ctx.render_pipeline,
		0,
	) or_return
	defer wgpu.release(bind_group_layout)

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
				{binding = 2, resource = ctx.cube_view},
			},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.uniform_bind_group)
	}

	ctx.render_pass.color_attachments[0] = {
		view = nil, /* Assigned later */
		ops = {
			load        = .Clear,
			store       = .Store,
			// The clear color serves as the initial background and seed for the fractal
			// generation. The mid-gray value (0.5, 0.5, 0.5) provides a neutral starting point
			// for the fractal algorithm. In the fractal shader, values near 0.5 can
			// significantly influence the initial pattern generation. The specific threshold of
			// 0.01 used in the shader depends on this base gray color. Changing this value can
			// dramatically alter the initial fractal distribution and appearance
			clear_value = {0.5, 0.5, 0.5, 1},
		},
	}

	app.setup_depth_stencil(ctx) or_return

	ctx.render_pass.descriptor = {
		label                    = "Render pass descriptor",
		color_attachments        = ctx.render_pass.color_attachments[:],
		depth_stencil_attachment = &ctx.depth_stencil.descriptor,
	}

	set_projection_matrix(ctx, {ctx.gpu.config.width, ctx.gpu.config.height})

	return true
}

quit :: proc(ctx: ^Context) {
	wgpu.release(ctx.uniform_bind_group)
	wgpu.release(ctx.sampler)
	wgpu.release(ctx.cube_view)
	wgpu.release(ctx.cube_texture)
	wgpu.release(ctx.uniform_buffer)
	wgpu.release(ctx.render_pipeline)
	wgpu.release(ctx.index_buffer)
	wgpu.release(ctx.vertex_buffer)
}

create_cube_texture :: proc(ctx: ^Context) -> (ok: bool) {
	if ctx.cube_texture != nil {
		wgpu.release(ctx.cube_texture)
	}
	ctx.cube_texture = wgpu.device_create_texture(
		ctx.gpu.device,
		{
			usage = {.Texture_Binding, .Copy_Dst, .Render_Attachment},
			format = ctx.gpu.config.format,
			dimension = .D2,
			mip_level_count = 1,
			sample_count = 1,
			size = {
				width = ctx.gpu.config.width,
				height = ctx.gpu.config.height,
				depth_or_array_layers = 1,
			},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.cube_texture)
	}

	texture_view_descriptor := wgpu.Texture_View_Descriptor {
		format            = ctx.gpu.config.format,
		dimension         = .D2,
		base_mip_level    = 0,
		mip_level_count   = 1,
		base_array_layer  = 0,
		array_layer_count = 1,
		aspect            = .All,
	}

	if ctx.cube_view != nil {
		wgpu.release(ctx.cube_view)
	}
	ctx.cube_view = wgpu.texture_create_view(ctx.cube_texture, texture_view_descriptor) or_return
	defer if !ok {
		wgpu.release(ctx.cube_view)
	}

	return true
}

set_projection_matrix :: proc(ctx: ^Context, size: app.Resize_Event) {
	ctx.projection_matrix = la.matrix4_perspective(2 * math.PI / 5, ctx.aspect, 1, 100.0)
}

get_transformation_matrix :: proc(ctx: ^Context) -> (mvp_mat: la.Matrix4f32) {
	view_matrix := la.MATRIX4F32_IDENTITY

	// Translate
	translation := la.Vector3f32{0, 0, -4}
	view_matrix = la.matrix_mul(view_matrix, la.matrix4_translate(translation))

	// Rotate
	now := f32(app.get_time(ctx))
	rotation_axis := la.Vector3f32{math.sin(now), math.cos(now), 0}
	rotation_matrix := la.matrix4_rotate(1, rotation_axis)
	view_matrix = la.matrix_mul(view_matrix, rotation_matrix)

	// Multiply projection and view matrices
	mvp_mat = la.matrix_mul(ctx.projection_matrix, view_matrix)

	return
}

resize :: proc(ctx: ^Context, size: app.Resize_Event) -> bool {
	create_cube_texture(ctx) or_return
	set_projection_matrix(ctx, size)
	return true
}

update :: proc(ctx: ^Context, dt: f64) -> bool {
	transformation_matrix := get_transformation_matrix(ctx)
	wgpu.queue_write_buffer(
		ctx.gpu.queue,
		ctx.uniform_buffer,
		0,
		wgpu.to_bytes(transformation_matrix),
	) or_return

	return true
}

draw :: proc(ctx: ^Context) -> bool {
	ctx.cmd = wgpu.device_create_command_encoder(ctx.gpu.device) or_return
	defer wgpu.release(ctx.cmd)

	ctx.render_pass.color_attachments[0].view = ctx.frame.view
	render_pass := wgpu.command_encoder_begin_render_pass(ctx.cmd, ctx.render_pass.descriptor)
	defer wgpu.release(render_pass)

	wgpu.render_pass_set_pipeline(render_pass, ctx.render_pipeline)
	wgpu.render_pass_set_bind_group(render_pass, 0, ctx.uniform_bind_group)
	wgpu.render_pass_set_vertex_buffer(render_pass, 0, {buffer = ctx.vertex_buffer})
	wgpu.render_pass_set_index_buffer(render_pass, {buffer = ctx.index_buffer}, .Uint16)
	wgpu.render_pass_draw_indexed(render_pass, {0, u32(len(CUBE_INDICES_DATA))})

	wgpu.render_pass_end(render_pass) or_return

	// Copy the rendering results from the swapchain into `cube_texture`.
	wgpu.command_encoder_copy_texture_to_texture(
		ctx.cmd,
		{texture = ctx.frame.texture, mip_level = 0, origin = {}, aspect = .All},
		{texture = ctx.cube_texture, mip_level = 0, origin = {}, aspect = .All},
		{ctx.gpu.config.width, ctx.gpu.config.height, 1},
	) or_return

	cmdbuf := wgpu.command_encoder_finish(ctx.cmd) or_return
	defer wgpu.release(cmdbuf)

	wgpu.queue_submit(ctx.gpu.queue, cmdbuf)
	wgpu.surface_present(ctx.gpu.surface) or_return

	return true
}

main :: proc() {
	when ODIN_DEBUG {
		context.logger = log.create_console_logger(opt = {.Level, .Terminal_Color})
		defer log.destroy_console_logger(context.logger)
	}

	settings := app.DEFAULT_SETTINGS
	settings.title = EXAMPLE_TITLE

	example, ok := app.create(Context, settings)
	if !ok {
		log.fatalf("Failed to create example [%s]", EXAMPLE_TITLE)
		return
	}
	defer app.destroy(example)

	example.callbacks = {
		init   = init,
		quit   = quit,
		resize = resize,
		update = update,
		draw   = draw,
	}

	app.run(example) // Start the main loop
}
