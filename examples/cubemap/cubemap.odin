package cube_map

// Packages
import "core:log"
import "core:math"
import la "core:math/linalg"
import "core:time"

// Local packages
import app "root:utils/application"
import "root:wgpu"

Example :: struct {
	// Buffers
	vertex_buffer:      wgpu.Buffer,
	index_buffer:       wgpu.Buffer,

	// Pipeline setup
	bind_group_layout:  wgpu.Bind_Group_Layout,
	render_pipeline:    wgpu.Render_Pipeline,

	// Texture and related resources
	cubemap_texture:    app.Texture,

	// Uniform buffer and bind group
	uniform_buffer:     wgpu.Buffer,
	uniform_bind_group: wgpu.Bind_Group,

	// Other state variables
	projection_matrix:  la.Matrix4f32,
	model_matrix:       la.Matrix4f32,
	start_time:         time.Time,
	render_pass:        struct {
		color_attachments: [1]wgpu.Render_Pass_Color_Attachment,
		descriptor:        wgpu.Render_Pass_Descriptor,
	},
}

Context :: app.Context(Example)

EXAMPLE_TITLE :: "Cubemap"

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

	CUBEMAP_WGSL :: #load("cubemap.wgsl")
	shader_module := wgpu.device_create_shader_module(
		ctx.gpu.device,
		{source = string(CUBEMAP_WGSL)},
	) or_return
	defer wgpu.release(shader_module)

	ctx.bind_group_layout = wgpu.device_create_bind_group_layout(
	ctx.gpu.device,
	wgpu.Bind_Group_Layout_Descriptor {
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
	defer if !ok {
		wgpu.release(ctx.bind_group_layout)
	}

	pipeline_layout := wgpu.device_create_pipeline_layout(
		ctx.gpu.device,
		{
			label = EXAMPLE_TITLE + " Pipeline bind group layout",
			bind_group_layouts = {ctx.bind_group_layout},
		},
	) or_return
	defer wgpu.release(pipeline_layout)

	attributes := wgpu.vertex_attr_array(2, {0, .Float32x4}, {1, .Float32x2})
	vertex_buffer_layout := wgpu.Vertex_Buffer_Layout {
		array_stride = size_of(Vertex),
		step_mode    = .Vertex,
		attributes   = attributes[:],
	}

	ctx.render_pipeline = wgpu.device_create_render_pipeline(
		ctx.gpu.device,
		descriptor = wgpu.Render_Pipeline_Descriptor {
			layout = pipeline_layout,
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
				// Since we are seeing from inside of the cube
				// and we are using the regular cube geometry data with outward-facing normals,
				// the cullMode should be 'front' or 'none'.
				cull_mode  = .Front,
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

	ctx.cubemap_texture = app.create_cubemap_texture_from_files(
		ctx,
		{
			"./assets/textures/cubemaps/bridge2_px.jpg",
			"./assets/textures/cubemaps/bridge2_nx.jpg",
			"./assets/textures/cubemaps/bridge2_py.jpg",
			"./assets/textures/cubemaps/bridge2_ny.jpg",
			"./assets/textures/cubemaps/bridge2_pz.jpg",
			"./assets/textures/cubemaps/bridge2_nz.jpg",
		},
	) or_return
	defer if !ok {
		app.release(ctx.cubemap_texture)
	}

	ctx.uniform_buffer = wgpu.device_create_buffer(
		ctx.gpu.device,
		descriptor = wgpu.Buffer_Descriptor {
			label = EXAMPLE_TITLE + " Uniform Buffer",
			size  = size_of(la.Matrix4f32), // 4x4 matrix
			usage = {.Uniform, .Copy_Dst},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.uniform_buffer)
	}

	ctx.uniform_bind_group = wgpu.device_create_bind_group(
		ctx.gpu.device,
		{
			layout = ctx.bind_group_layout,
			entries = {
				{
					binding = 0,
					resource = wgpu.Buffer_Binding {
						buffer = ctx.uniform_buffer,
						size = wgpu.buffer_size(ctx.uniform_buffer),
					},
				},
				{binding = 1, resource = ctx.cubemap_texture.sampler},
				{binding = 2, resource = ctx.cubemap_texture.view},
			},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.uniform_bind_group)
	}

	ctx.render_pass.color_attachments[0] = {
		view = nil, /* Assigned later */
		ops  = {.Clear, .Store, {0.0, 0.0, 0.0, 1.0}},
	}

	app.setup_depth_stencil(ctx) or_return

	ctx.render_pass.descriptor = {
		label                    = "Render pass descriptor",
		color_attachments        = ctx.render_pass.color_attachments[:],
		depth_stencil_attachment = &ctx.depth_stencil.descriptor,
	}

	ctx.model_matrix = la.matrix4_scale_f32({1000.0, 1000.0, 1000.0})
	set_projection_matrix({ctx.gpu.config.width, ctx.gpu.config.height}, ctx)

	ctx.start_time = time.now()

	return true
}

quit :: proc(ctx: ^Context) {
	// Release bind group and related resources
	wgpu.release(ctx.uniform_bind_group)
	wgpu.buffer_destroy(ctx.uniform_buffer)
	wgpu.release(ctx.uniform_buffer)

	// Release texture resources
	app.release(ctx.cubemap_texture)

	// Release pipeline and related resources
	wgpu.release(ctx.render_pipeline)
	wgpu.release(ctx.bind_group_layout)

	// Release buffer resources
	wgpu.buffer_destroy(ctx.index_buffer)
	wgpu.release(ctx.index_buffer)
	wgpu.buffer_destroy(ctx.vertex_buffer)
	wgpu.release(ctx.vertex_buffer)
}

set_projection_matrix :: proc(size: app.Window_Size, ctx: ^Context) {
	ctx.aspect = f32(ctx.gpu.config.width) / f32(ctx.gpu.config.height)
	ctx.projection_matrix = la.matrix4_perspective((2 * math.PI) / 5, ctx.aspect, 1, 3000.0)
}

get_transformation_matrix :: proc(ctx: ^Context) -> (mvp_mat: la.Matrix4f32) {
	now := f32(time.duration_seconds(time.since(ctx.start_time))) / 0.8

	rotation_x := la.quaternion_from_euler_angle_x_f32((math.PI / 10) * math.sin(now))
	rotation_y := la.quaternion_from_euler_angle_y_f32(now * 0.2)

	combined_rotation := la.quaternion_mul_quaternion(rotation_x, rotation_y)
	view_matrix := la.matrix4_from_quaternion_f32(combined_rotation)

	mvp_mat = la.matrix_mul(view_matrix, ctx.model_matrix)
	mvp_mat = la.matrix_mul(ctx.projection_matrix, mvp_mat)

	return
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
	wgpu.render_pass_set_vertex_buffer(render_pass, 0, {buffer = ctx.vertex_buffer})
	wgpu.render_pass_set_index_buffer(render_pass, {buffer = ctx.index_buffer}, .Uint16)
	wgpu.render_pass_set_bind_group(render_pass, 0, ctx.uniform_bind_group)
	wgpu.render_pass_draw_indexed(render_pass, {0, u32(len(CUBE_INDICES_DATA))})

	wgpu.render_pass_end(render_pass) or_return

	cmdbuf := wgpu.command_encoder_finish(ctx.cmd) or_return
	defer wgpu.release(cmdbuf)

	wgpu.queue_submit(ctx.gpu.queue, cmdbuf)
	wgpu.surface_present(ctx.gpu.surface) or_return

	return true
}

resize :: proc(ctx: ^Context, size: app.Resize_Event) -> bool {
	set_projection_matrix({size.w, size.h}, ctx)
	return true
}

main :: proc() {
	when ODIN_DEBUG {
		context.logger = log.create_console_logger(opt = {.Level, .Terminal_Color})
		defer log.destroy_console_logger(context.logger)
	}

	settings := app.DEFAULT_SETTINGS
	settings.title = EXAMPLE_TITLE
	settings.size = {650, 650}

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

	app.run(example)
}
