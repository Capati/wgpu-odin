package stencil_triangles

// Packages
import "core:log"
import la "core:math/linalg"

// Local packages
import app "root:utils/application"
import "root:wgpu"

Example :: struct {
	outer_vertex_buffer: wgpu.Buffer,
	mask_vertex_buffer:  wgpu.Buffer,
	outer_pipeline:      wgpu.RenderPipeline,
	mask_pipeline:       wgpu.RenderPipeline,
	stencil_buffer:      wgpu.Texture,
	depth_view:          wgpu.TextureView,
	render_pass:         struct {
		color_attachments: [1]wgpu.RenderPassColorAttachment,
		depth_stencil:     wgpu.RenderPassDepthStencilAttachment,
		descriptor:        wgpu.RenderPassDescriptor,
	},
}

Context :: app.Context(Example)

Vertex :: struct {
	pos: la.Vector4f32,
}

EXAMPLE_TITLE :: "Stencil Triangles"
STENCIL_FORMAT :: wgpu.TextureFormat.Stencil8

vertex :: proc(x, y: f32) -> Vertex {
	return {pos = {x, y, 0.0, 1.0}}
}

init :: proc(ctx: ^Context) -> (ok: bool) {
	outer_vertices := []Vertex{vertex(-1.0, -1.0), vertex(1.0, -1.0), vertex(0.0, 1.0)}
	ctx.outer_vertex_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{
			label = "Outer Vertex Buffer",
			contents = wgpu.to_bytes(outer_vertices),
			usage = {.Vertex},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.outer_vertex_buffer)
	}

	mask_vertices := []Vertex{vertex(-0.5, 0.0), vertex(0.0, -1.0), vertex(0.5, 0.0)}
	ctx.mask_vertex_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{label = "Mask Vertex Buffer", contents = wgpu.to_bytes(mask_vertices), usage = {.Vertex}},
	) or_return
	defer if !ok {
		wgpu.release(ctx.mask_vertex_buffer)
	}

	pipeline_layout := wgpu.device_create_pipeline_layout(ctx.gpu.device, {}) or_return
	defer wgpu.release(pipeline_layout)

	shader := wgpu.device_create_shader_module(
		ctx.gpu.device,
		{source = #load("./stencil_triangles.wgsl", string)},
	) or_return
	defer wgpu.release(shader)

	vertex_buffers := [1]wgpu.VertexBufferLayout {
		{
			array_stride = size_of(Vertex),
			step_mode = .Vertex,
			attributes = {{format = .Float32x4, offset = 0, shader_location = 0}},
		},
	}

	descriptor := wgpu.RenderPipelineDescriptor {
		layout = pipeline_layout,
		vertex = {module = shader, entry_point = "vs_main", buffers = vertex_buffers[:]},
		fragment = &{
			module = shader,
			entry_point = "fs_main",
			targets = {{format = ctx.gpu.config.format, write_mask = wgpu.COLOR_WRITES_NONE}},
		},
		primitive = wgpu.DEFAULT_PRIMITIVE_STATE,
		depth_stencil = {
			format = STENCIL_FORMAT,
			depth_write_enabled = false,
			depth_compare = .Always,
			stencil = {
				front = {
					compare = .Always,
					fail_op = .Keep,
					depth_fail_op = .Keep,
					pass_op = .Replace,
				},
				back = wgpu.STENCIL_FACE_STATE_IGNORE,
				read_mask = max(u32),
				write_mask = max(u32),
			},
		},
		multisample = wgpu.DEFAULT_MULTISAMPLE_STATE,
	}

	descriptor.label = "Mask Pipeline"

	ctx.mask_pipeline = wgpu.device_create_render_pipeline(ctx.gpu.device, descriptor) or_return
	defer if !ok {
		wgpu.release(ctx.mask_pipeline)
	}

	descriptor.label = "Outer Pipeline"
	descriptor.depth_stencil.stencil.front = {
		compare = .Greater,
		pass_op = .Keep,
	}
	descriptor.fragment.targets[0].write_mask = wgpu.COLOR_WRITES_ALL

	ctx.outer_pipeline = wgpu.device_create_render_pipeline(ctx.gpu.device, descriptor) or_return
	defer if !ok {
		wgpu.release(ctx.outer_pipeline)
	}

	create_stencil_buffer(ctx) or_return
	defer if !ok {
		destroy_stencil_buffer(ctx)
	}

	ctx.render_pass.color_attachments[0] = {
		view = nil, /* Assigned later */
		ops = {load = .Clear, store = .Store, clear_value = {0.1, 0.2, 0.3, 1.0}},
	}

	ctx.render_pass.descriptor = {
		label                    = "Render pass descriptor",
		color_attachments        = ctx.render_pass.color_attachments[:],
		depth_stencil_attachment = &ctx.render_pass.depth_stencil,
	}

	return true
}

create_stencil_buffer :: proc(ctx: ^Context) -> (ok: bool) {
	destroy_stencil_buffer(ctx)

	ctx.stencil_buffer = wgpu.device_create_texture(
		ctx.gpu.device,
		{
			label = "Stencil buffer",
			size = {
				width = ctx.gpu.config.width,
				height = ctx.gpu.config.height,
				depth_or_array_layers = 1,
			},
			mip_level_count = 1,
			sample_count = 1,
			dimension = .D2,
			format = STENCIL_FORMAT,
			usage = {.RenderAttachment},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.stencil_buffer)
	}

	texture_view_descriptor := wgpu.TextureViewDescriptor {
		format            = STENCIL_FORMAT,
		dimension         = .D2,
		base_mip_level    = 0,
		mip_level_count   = 1,
		base_array_layer  = 0,
		array_layer_count = 1,
		aspect            = .All,
	}

	ctx.depth_view = wgpu.texture_create_view(
		ctx.stencil_buffer,
		texture_view_descriptor,
	) or_return
	defer if !ok {
		wgpu.release(ctx.depth_view)
	}

	ctx.render_pass.depth_stencil = {
		view                = ctx.depth_view,
		stencil_load_op     = .Clear,
		stencil_store_op    = .Store,
		depth_clear_value   = 1.0,
		stencil_clear_value = 0.0,
	}

	return true
}

destroy_stencil_buffer :: proc(ctx: ^Context) {
	if ctx.stencil_buffer != nil {
		wgpu.release(ctx.stencil_buffer)
	}

	if ctx.depth_view != nil {
		wgpu.release(ctx.depth_view)
	}
}

quit :: proc(ctx: ^Context) {
	destroy_stencil_buffer(ctx)
	wgpu.release(ctx.outer_pipeline)
	wgpu.release(ctx.mask_pipeline)
	wgpu.release(ctx.mask_vertex_buffer)
	wgpu.release(ctx.outer_vertex_buffer)
}

resize :: proc(ctx: ^Context, size: app.WindowSize) -> (ok: bool) {
	create_stencil_buffer(ctx) or_return
	return true
}

draw :: proc(ctx: ^Context) -> (ok: bool) {
	ctx.cmd = wgpu.device_create_command_encoder(ctx.gpu.device) or_return
	defer wgpu.release(ctx.cmd)

	ctx.render_pass.color_attachments[0].view = ctx.frame.view
	render_pass := wgpu.command_encoder_begin_render_pass(ctx.cmd, ctx.render_pass.descriptor)
	defer wgpu.release(render_pass)

	wgpu.render_pass_set_stencil_reference(render_pass, 1)

	wgpu.render_pass_set_pipeline(render_pass, ctx.mask_pipeline)
	wgpu.render_pass_set_vertex_buffer(render_pass, 0, {buffer = ctx.mask_vertex_buffer})
	wgpu.render_pass_draw(render_pass, {0, 3})

	wgpu.render_pass_set_pipeline(render_pass, ctx.outer_pipeline)
	wgpu.render_pass_set_vertex_buffer(render_pass, 0, {buffer = ctx.outer_vertex_buffer})
	wgpu.render_pass_draw(render_pass, {0, 3})

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

	example.callbacks = {
		init   = init,
		quit   = quit,
		resize = resize,
		draw   = draw,
	}

	app.run(example)
}
