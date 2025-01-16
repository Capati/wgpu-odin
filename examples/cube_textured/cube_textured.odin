package cube_textured

// Packages
import "core:log"
import "core:math"
import la "core:math/linalg"

// Local packages
import app "root:utils/application"
import "root:wgpu"

Example :: struct {
	vertex_buffer:   wgpu.Buffer,
	index_buffer:    wgpu.Buffer,
	uniform_buffer:  wgpu.Buffer,
	render_pipeline: wgpu.Render_Pipeline,
	bind_group:      wgpu.Bind_Group,
	render_pass:     struct {
		color_attachments: [1]wgpu.Render_Pass_Color_Attachment,
		descriptor:        wgpu.Render_Pass_Descriptor,
	},
}

Context :: app.Context(Example)

EXAMPLE_TITLE :: "Textured Cube"
TEXEL_SIZE :: 256

init :: proc(ctx: ^Context) -> (ok: bool) {
	ctx.vertex_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{
			label = EXAMPLE_TITLE + " Vertex Buffer",
			contents = wgpu.to_bytes(vertex_data),
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
			contents = wgpu.to_bytes(index_data),
			usage = {.Index},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.index_buffer)
	}

	texture_extent := wgpu.Extent_3D {
		width                 = TEXEL_SIZE,
		height                = TEXEL_SIZE,
		depth_or_array_layers = 1,
	}

	texture := wgpu.device_create_texture(
		ctx.gpu.device,
		{
			size = texture_extent,
			mip_level_count = 1,
			sample_count = 1,
			dimension = .D2,
			format = .R8Uint,
			usage = {.Texture_Binding, .Copy_Dst},
		},
	) or_return
	defer wgpu.release(texture)

	texture_view := wgpu.texture_create_view(texture) or_return
	defer wgpu.release(texture_view)

	texels := create_texels()

	wgpu.queue_write_texture(
		ctx.gpu.queue,
		{texture = texture, mip_level = 0, origin = {}, aspect = .All},
		wgpu.to_bytes(texels),
		{offset = 0, bytes_per_row = TEXEL_SIZE, rows_per_image = wgpu.COPY_STRIDE_UNDEFINED},
		texture_extent,
	) or_return

	mx_total := create_view_projection_matrix(
		cast(f32)ctx.gpu.config.width / cast(f32)ctx.gpu.config.height,
	)

	ctx.uniform_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{
			label = EXAMPLE_TITLE + " Uniform Buffer",
			contents = wgpu.to_bytes(mx_total),
			usage = {.Uniform, .Copy_Dst},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.uniform_buffer)
	}

	CUBE_TEXTURED_WGSL :: #load("./cube_textured.wgsl")
	shader_module := wgpu.device_create_shader_module(
		ctx.gpu.device,
		{label = EXAMPLE_TITLE + " Module", source = string(CUBE_TEXTURED_WGSL)},
	) or_return
	defer wgpu.release(shader_module)

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
						blend = &wgpu.BLEND_STATE_REPLACE,
						write_mask = wgpu.COLOR_WRITES_ALL,
					},
				},
			},
			depth_stencil = app.create_depth_stencil_state(ctx),
			primitive = {topology = .Triangle_List, front_face = .CCW, cull_mode = .Back},
			multisample = wgpu.DEFAULT_MULTISAMPLE_STATE,
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.render_pipeline)
	}

	bind_group_layout := wgpu.render_pipeline_get_bind_group_layout(
		ctx.render_pipeline,
		0,
	) or_return
	defer wgpu.release(bind_group_layout)

	ctx.bind_group = wgpu.device_create_bind_group(
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
				{binding = 1, resource = texture_view},
			},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.bind_group)
	}

	ctx.render_pass.color_attachments[0] = {
		view = nil, /* Assigned later */
		ops  = {.Clear, .Store, {0.1, 0.2, 0.3, 1.0}},
	}

	app.setup_depth_stencil(ctx) or_return

	ctx.render_pass.descriptor = {
		label                    = "Render pass descriptor",
		color_attachments        = ctx.render_pass.color_attachments[:],
		depth_stencil_attachment = &ctx.depth_stencil.descriptor,
	}

	return true
}

quit :: proc(ctx: ^Context) {
	wgpu.release(ctx.bind_group)
	wgpu.release(ctx.render_pipeline)
	wgpu.release(ctx.uniform_buffer)
	wgpu.release(ctx.index_buffer)
	wgpu.release(ctx.vertex_buffer)
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

resize :: proc(ctx: ^Context, size: app.Resize_Event) -> bool {
	app.setup_depth_stencil(ctx) or_return
	wgpu.queue_write_buffer(
		ctx.gpu.queue,
		ctx.uniform_buffer,
		0,
		wgpu.to_bytes(create_view_projection_matrix(f32(size.w) / f32(size.h))),
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
	wgpu.render_pass_set_bind_group(render_pass, 0, ctx.bind_group)
	wgpu.render_pass_set_vertex_buffer(render_pass, 0, {buffer = ctx.vertex_buffer})
	wgpu.render_pass_set_index_buffer(render_pass, {buffer = ctx.index_buffer}, .Uint16)
	wgpu.render_pass_draw_indexed(render_pass, {0, u32(len(index_data))}, 0)

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
		draw   = draw,
	}

	app.run(example) // Start the main loop
}
