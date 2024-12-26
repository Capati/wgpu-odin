#+vet !unused-imports
package cube_example

// Packages
import "core:log"

// Local packages
import "../common"
import app "./../../utils/application"
import "./../../wgpu"

Example :: struct {
	render_pass:     struct {
		color_attachments:        [1]wgpu.RenderPassColorAttachment,
		depth_stencil_attachment: wgpu.RenderPassDepthStencilAttachment,
		descriptor:               wgpu.RenderPassDescriptor,
	},
	vertex_buffer:   wgpu.Buffer,
	render_pipeline: wgpu.RenderPipeline,
	uniform_buffer:  wgpu.Buffer,
	bind_group:      wgpu.BindGroup,
	depth_view:      wgpu.TextureView,
}

Context :: app.Context(Example)

EXAMPLE_TITLE :: "Colored Cube"
DEPTH_FORMAT :: wgpu.TextureFormat.Depth24Plus

init :: proc(ctx: ^Context) -> (ok: bool) {
	CUBE_WGSL :: #load("./cube.wgsl")
	shader_module := wgpu.device_create_shader_module(
		ctx.gpu.device,
		{label = EXAMPLE_TITLE + " Module", source = string(CUBE_WGSL)},
	) or_return
	defer wgpu.release(shader_module)

	ctx.vertex_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{
			label = EXAMPLE_TITLE + " Buffer",
			contents = wgpu.to_bytes(vertex_data),
			usage = {.Vertex},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.vertex_buffer)
	}

	vertex_attributes := wgpu.vertex_attr_array(2, {0, .Float32x3}, {1, .Float32x3})

	// Above line expands to:
	// vertex_attributes := [?]wgpu.VertexAttribute {
	// 	{format = .Float32x3, offset = 0, shader_location = 0},
	// 	{
	// 		format = .Float32x3,
	// 		offset = 12,
	// 		shader_location = 1,
	// 	},
	// }

	vertex_buffer_layout := wgpu.VertexBufferLayout {
		array_stride = size_of(Vertex),
		step_mode    = .Vertex,
		attributes   = vertex_attributes[:],
	}

	pipeline_descriptor := wgpu.RenderPipelineDescriptor {
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
					blend = &wgpu.BLEND_STATE_REPLACE,
					write_mask = wgpu.COLOR_WRITES_ALL,
				},
			},
		},
		primitive = {topology = .TriangleList, front_face = .CCW, cull_mode = .Back},
		// Enable depth testing so that the fragment closest to the camera
		// is rendered in front.
		depth_stencil = {
			depth_write_enabled = true,
			depth_compare = .Less,
			format = DEPTH_FORMAT,
			stencil = {
				front = {compare = .Always},
				back = {compare = .Always},
				read_mask = 0xFFFFFFFF,
				write_mask = 0xFFFFFFFF,
			},
		},
		multisample = wgpu.DEFAULT_MULTISAMPLE_STATE,
	}

	ctx.render_pipeline = wgpu.device_create_render_pipeline(
		ctx.gpu.device,
		pipeline_descriptor,
	) or_return
	defer if !ok {
		wgpu.release(ctx.render_pipeline)
	}

	aspect := f32(ctx.gpu.config.width) / f32(ctx.gpu.config.height)
	mvp_mat := common.create_view_projection_matrix(aspect)

	ctx.uniform_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{
			label = EXAMPLE_TITLE + " Uniform Buffer",
			contents = wgpu.to_bytes(mvp_mat),
			usage = {.Uniform, .CopyDst},
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

	ctx.bind_group = wgpu.device_create_bind_group(
		ctx.gpu.device,
		{
			layout = bind_group_layout,
			entries = {
				{
					binding = 0,
					resource = wgpu.BufferBinding {
						buffer = ctx.uniform_buffer,
						size = wgpu.WHOLE_SIZE,
					},
				},
			},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.bind_group)
	}

	create_depth_framebuffer(ctx) or_return

	ctx.render_pass.color_attachments[0] = {
		view = nil, /* Assigned later */
		ops = {load = .Clear, store = .Store, clear_value = app.ColorDarkGray},
	}

	ctx.render_pass.descriptor = {
		label                    = "Render pass descriptor",
		color_attachments        = ctx.render_pass.color_attachments[:],
		depth_stencil_attachment = &ctx.render_pass.depth_stencil_attachment,
	}

	return true
}

create_depth_framebuffer :: proc(ctx: ^Context) -> (ok: bool) {
	format_features := wgpu.texture_format_guaranteed_format_features(
		DEPTH_FORMAT,
		ctx.gpu.features,
	)

	size := ctx.framebuffer_size

	texture_descriptor := wgpu.TextureDescriptor {
		size            = {size.w, size.h, 1},
		mip_level_count = 1,
		sample_count    = 1,
		dimension       = .D2,
		format          = DEPTH_FORMAT,
		usage           = format_features.allowed_usages,
	}

	texture := wgpu.device_create_texture(ctx.gpu.device, texture_descriptor) or_return
	defer wgpu.release(texture)

	ctx.depth_view = wgpu.texture_create_view(texture) or_return

	// Setup depth stencil attachment
	ctx.render_pass.depth_stencil_attachment = {
		view              = ctx.depth_view,
		depth_load_op     = .Clear,
		depth_store_op    = .Store,
		depth_clear_value = 1.0,
	}

	return true
}

quit :: proc(ctx: ^Context) {
	wgpu.release(ctx.depth_view)
	wgpu.release(ctx.bind_group)
	wgpu.release(ctx.uniform_buffer)
	wgpu.release(ctx.render_pipeline)
	wgpu.release(ctx.vertex_buffer)
}

resize :: proc(ctx: ^Context, size: app.ResizeEvent) -> bool {
	wgpu.release(ctx.depth_view)
	create_depth_framebuffer(ctx) or_return

	// Update uniform buffer with new aspect ratio
	aspect := f32(size.w) / f32(size.h)
	new_matrix := common.create_view_projection_matrix(aspect)
	wgpu.queue_write_buffer(
		ctx.gpu.queue,
		ctx.uniform_buffer,
		0,
		wgpu.to_bytes(new_matrix),
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
	wgpu.render_pass_draw(render_pass, {0, u32(len(vertex_data))})

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
