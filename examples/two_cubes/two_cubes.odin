package two_cubes

// Packages
import "core:log"
import "core:math"
import la "core:math/linalg"

// Local packages
import cube "root:examples/rotating_cube"
import app "root:utils/application"
import "root:wgpu"

Example :: struct {
	vertex_buffer:       wgpu.Buffer,
	index_buffer:        wgpu.Buffer,
	render_pipeline:     wgpu.Render_Pipeline,
	uniform_buffer:      wgpu.Buffer,
	uniform_bind_group1: wgpu.Bind_Group,
	uniform_bind_group2: wgpu.Bind_Group,
	offset:              u64,
	projection_matrix:   la.Matrix4f32,
	render_pass:         struct {
		color_attachments: [1]wgpu.Render_Pass_Color_Attachment,
		descriptor:        wgpu.Render_Pass_Descriptor,
	},
}

Context :: app.Context(Example)

EXAMPLE_TITLE :: "Two Cubes"

CUBE_VERTEX_DATA := cube.CUBE_VERTEX_DATA
CUBE_INDICES_DATA := cube.CUBE_INDICES_DATA
Vertex :: cube.Vertex

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
			{format = .Float32x4, offset = u64(offset_of(Vertex, color)), shader_location = 1},
			{
				format = .Float32x2,
				offset = u64(offset_of(Vertex, tex_coords)),
				shader_location = 2,
			},
		},
	}

	ROTATING_CUBE_WGSL :: #load("./../rotating_cube/rotating_cube.wgsl")
	shader_module := wgpu.device_create_shader_module(
		ctx.gpu.device,
		{source = string(ROTATING_CUBE_WGSL)},
	) or_return
	defer wgpu.release(shader_module)

	ctx.render_pipeline = wgpu.device_create_render_pipeline(
	ctx.gpu.device,
	{
		label = EXAMPLE_TITLE + " Render Pipeline",
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
		depth_stencil = app.create_depth_stencil_state(ctx),
		multisample = wgpu.DEFAULT_MULTISAMPLE_STATE,
	},
	) or_return
	defer if !ok {
		wgpu.release(ctx.render_pipeline)
	}

	matrix_size: u64 = 4 * 16 // 4x4 matrix
	ctx.offset = 256
	uniform_buffer_size := ctx.offset + matrix_size

	ctx.uniform_buffer = wgpu.device_create_buffer(
		ctx.gpu.device,
		{
			label = EXAMPLE_TITLE + " Uniform Buffer",
			size = uniform_buffer_size,
			usage = {.Uniform, .Copy_Dst},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.uniform_buffer)
	}

	bind_group_layout := wgpu.render_pipeline_get_bind_group_layout(
		ctx.render_pipeline,
		0,
	) or_return
	defer wgpu.release(bind_group_layout)

	ctx.uniform_bind_group1 = wgpu.device_create_bind_group(
		ctx.gpu.device,
		{
			layout = bind_group_layout,
			entries = {
				{
					binding = 0,
					resource = wgpu.Buffer_Binding {
						buffer = ctx.uniform_buffer,
						size = matrix_size,
					},
				},
			},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.uniform_bind_group1)
	}

	ctx.uniform_bind_group2 = wgpu.device_create_bind_group(
		ctx.gpu.device,
		{
			layout = bind_group_layout,
			entries = {
				{
					binding = 0,
					resource = wgpu.Buffer_Binding {
						buffer = ctx.uniform_buffer,
						offset = ctx.offset,
						size = matrix_size,
					},
				},
			},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.uniform_bind_group2)
	}

	ctx.render_pass.color_attachments[0] = {
		view = nil, /* Assigned later */
		ops  = {.Clear, .Store, app.Color_Dark_Gray},
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
	wgpu.release(ctx.uniform_bind_group1)
	wgpu.release(ctx.uniform_buffer)
	wgpu.release(ctx.render_pipeline)
	wgpu.release(ctx.index_buffer)
	wgpu.release(ctx.vertex_buffer)
}

set_projection_matrix :: proc(ctx: ^Context, size: app.Resize_Event) {
	ctx.projection_matrix = la.matrix4_perspective(2 * math.PI / 5, ctx.aspect, 1, 100.0)
}

get_transformation_matrix :: proc(
	ctx: ^Context,
	translation, rotation_axis: la.Vector3f32,
) -> (
	mvp_mat: la.Matrix4f32,
) {
	view_matrix := la.MATRIX4F32_IDENTITY

	// Translate
	view_matrix = la.matrix_mul(view_matrix, la.matrix4_translate(translation))

	// Rotate
	rotation_matrix := la.matrix4_rotate(1, rotation_axis)
	view_matrix = la.matrix_mul(view_matrix, rotation_matrix)

	// Multiply projection and view matrices
	mvp_mat = la.matrix_mul(ctx.projection_matrix, view_matrix)

	return
}

resize :: proc(ctx: ^Context, event: app.Resize_Event) -> bool {
	set_projection_matrix(ctx, {event.w, event.h})
	return true
}

update :: proc(ctx: ^Context, dt: f64) -> bool {
	now := f32(app.get_time(ctx))

	translation1 := la.Vector3f32{2, 0, -5}
	rotation_axis1 := la.Vector3f32{math.sin(now), math.cos(now), 0}
	transformation_matrix1 := get_transformation_matrix(ctx, translation1, rotation_axis1)
	wgpu.queue_write_buffer(
		ctx.gpu.queue,
		ctx.uniform_buffer,
		0,
		wgpu.to_bytes(transformation_matrix1),
	) or_return

	translation2 := la.Vector3f32{-2, 0, -5}
	rotation_axis2 := la.Vector3f32{math.cos(now), math.sin(now), 0}
	transformation_matrix2 := get_transformation_matrix(ctx, translation2, rotation_axis2)
	wgpu.queue_write_buffer(
		ctx.gpu.queue,
		ctx.uniform_buffer,
		ctx.offset,
		wgpu.to_bytes(transformation_matrix2),
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
	wgpu.render_pass_set_vertex_buffer(render_pass, 0, {buffer = ctx.vertex_buffer})
	wgpu.render_pass_set_index_buffer(render_pass, {buffer = ctx.index_buffer}, .Uint16)

	// Bind the bind group (with the transformation matrix) for each cube, and draw.
	wgpu.render_pass_set_bind_group(render_pass, 0, ctx.uniform_bind_group1)
	wgpu.render_pass_draw_indexed(render_pass, {0, u32(len(CUBE_INDICES_DATA))})

	wgpu.render_pass_set_bind_group(render_pass, 0, ctx.uniform_bind_group2)
	wgpu.render_pass_draw_indexed(render_pass, {0, u32(len(CUBE_INDICES_DATA))})

	wgpu.render_pass_end(render_pass) or_return

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
