package instanced_cube

// Packages
import "core:log"
import "core:math"
import la "core:math/linalg"

// Local packages
import cube "root:examples/rotating_cube"
import app "root:utils/application"
import "root:wgpu"

CUBE_VERTEX_DATA := cube.CUBE_VERTEX_DATA
CUBE_INDICES_DATA :: cube.CUBE_INDICES_DATA
Vertex :: cube.Vertex

X_COUNT :: 4
Y_COUNT :: 4
MAX_INSTANCES :: X_COUNT * Y_COUNT
MATRIX_FLOAT_COUNT :: 16
MATRIX_SIZE :: 4 * MATRIX_FLOAT_COUNT
UNIFORM_BUFFER_SIZE :: MAX_INSTANCES * MATRIX_SIZE

Example :: struct {
	vertex_buffer:     wgpu.Buffer,
	index_buffer:      wgpu.Buffer,
	render_pipeline:   wgpu.Render_Pipeline,
	instance_buffer:   wgpu.Buffer,
	projection_matrix: la.Matrix4f32,
	model_matrices:    [MAX_INSTANCES]la.Matrix4f32, // Store original model matrices
	instances:         [MAX_INSTANCES]la.Matrix4f32, // Store MVP matrices
	render_pass:       struct {
		color_attachments: [1]wgpu.Render_Pass_Color_Attachment,
		descriptor:        wgpu.Render_Pass_Descriptor,
	},
}

Context :: app.Context(Example)

EXAMPLE_TITLE :: "Instanced Cube"

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

	instance_buffer_layout := wgpu.Vertex_Buffer_Layout {
		array_stride = size_of(la.Matrix4f32),
		step_mode    = .Instance,
		attributes   = {
			// mat4x4 takes up 4 vertex shader input locations
			{format = .Float32x4, offset = 0, shader_location = 5}, // 1st column
			{format = .Float32x4, offset = 16, shader_location = 6}, // 2nd column
			{format = .Float32x4, offset = 32, shader_location = 7}, // 3rd column
			{format = .Float32x4, offset = 48, shader_location = 8}, // 4th column
		},
	}

	INSTANCED_WGSL :: #load("instanced.wgsl", string)
	shader_module := wgpu.device_create_shader_module(
		ctx.gpu.device,
		{source = INSTANCED_WGSL},
	) or_return
	defer wgpu.release(shader_module)

	ctx.render_pipeline = wgpu.device_create_render_pipeline(
	ctx.gpu.device,
	{
		vertex = {
			module = shader_module,
			entry_point = "vs_main",
			buffers = {vertex_buffer_layout, instance_buffer_layout},
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

	// Allocate a buffer large enough to hold transforms for every instance.
	ctx.instance_buffer = wgpu.device_create_buffer(
		ctx.gpu.device,
		{
			label = EXAMPLE_TITLE + " Instance Buffer",
			size = UNIFORM_BUFFER_SIZE,
			usage = {.Vertex, .Copy_Dst},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.instance_buffer)
	}

	STEP :: 4.0
	for x in 0 ..< X_COUNT {
		for y in 0 ..< Y_COUNT {
			i := x * Y_COUNT + y
			position := la.Vector3f32 {
				STEP * (f32(x) - f32(X_COUNT) / 2 + 0.5),
				STEP * (f32(y) - f32(Y_COUNT) / 2 + 0.5),
				0,
			}
			ctx.model_matrices[i] = la.matrix4_translate(position)
		}
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
	wgpu.release(ctx.instance_buffer)
	wgpu.release(ctx.render_pipeline)
	wgpu.release(ctx.index_buffer)
	wgpu.release(ctx.vertex_buffer)
}

set_projection_matrix :: proc(ctx: ^Context, size: app.Resize_Event) {
	ctx.aspect = f32(size.w) / f32(size.h)
	ctx.projection_matrix = la.matrix4_perspective(2 * math.PI / 5, ctx.aspect, 1, 100.0)
}

update_transformation_matrices :: proc(ctx: ^Context) {
	view_matrix := la.matrix4_translate(la.Vector3f32{0, 0, -12})
	now := f32(app.get_time(ctx))

	for x in 0 ..< X_COUNT {
		for y in 0 ..< Y_COUNT {
			i := x * Y_COUNT + y

			// Create rotation axis for this instance
			rotation_axis := la.Vector3f32 {
				math.sin((f32(x) + 0.5) * now),
				math.cos((f32(y) + 0.5) * now),
				0,
			}

			// Start with original model matrix
			rotation_matrix := la.matrix4_rotate(1, rotation_axis)
			tmp_mat := la.matrix_mul(ctx.model_matrices[i], rotation_matrix)

			// Apply view and projection transformations
			tmp_mat = la.matrix_mul(view_matrix, tmp_mat)
			tmp_mat = la.matrix_mul(ctx.projection_matrix, tmp_mat)

			// Store MVP matrix
			ctx.instances[i] = tmp_mat
		}
	}
}

resize :: proc(ctx: ^Context, event: app.Resize_Event) -> bool {
	set_projection_matrix(ctx, {event.w, event.h})
	return true
}

update :: proc(ctx: ^Context, dt: f64) -> bool {
	update_transformation_matrices(ctx)
	wgpu.queue_write_buffer(
		ctx.gpu.queue,
		ctx.instance_buffer,
		0,
		wgpu.to_bytes(ctx.instances),
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
	wgpu.render_pass_set_vertex_buffer(render_pass, 1, {buffer = ctx.instance_buffer})
	wgpu.render_pass_set_index_buffer(render_pass, {buffer = ctx.index_buffer}, .Uint16)
	wgpu.render_pass_draw_indexed(
		render_pass,
		indices = {start = 0, end = u32(len(CUBE_INDICES_DATA))},
		instances = {start = 0, end = u32(len(ctx.instances))},
	)

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
