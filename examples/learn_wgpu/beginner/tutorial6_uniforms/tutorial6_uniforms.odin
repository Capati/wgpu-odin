package tutorial6_uniforms

// Packages
import "core:log"
import la "core:math/linalg"

// Local Packages
import wgpu "./../../../../"
import app "./../../../../utils/application"

Vertex :: struct {
	position:   [3]f32,
	tex_coords: [2]f32,
}

Camera :: struct {
	eye:     la.Vector3f32,
	target:  la.Vector3f32,
	up:      la.Vector3f32,
	aspect:  f32,
	fovYRad: f32,
	znear:   f32,
	zfar:    f32,
}

CameraUniform :: struct {
	view_proj: la.Matrix4f32,
}

CameraController :: struct {
	speed:               f32,
	is_up_pressed:       bool,
	is_down_pressed:     bool,
	is_forward_pressed:  bool,
	is_backward_pressed: bool,
	is_left_pressed:     bool,
	is_right_pressed:    bool,
}

Example :: struct {
	diffuse_bind_group: wgpu.BindGroup,
	camera:             Camera,
	camera_controller:  CameraController,
	camera_uniform:     CameraUniform,
	camera_buffer:      wgpu.Buffer,
	camera_bind_group:  wgpu.BindGroup,
	render_pipeline:    wgpu.RenderPipeline,
	num_indices:        u32,
	vertex_buffer:      wgpu.Buffer,
	index_buffer:       wgpu.Buffer,
	render_pass:        struct {
		color_attachments: [1]wgpu.RenderPassColorAttachment,
		descriptor:        wgpu.RenderPassDescriptor,
	},
}

Context :: app.Context(Example)

EXAMPLE_TITLE :: "Tutorial 6 - Uniforms"

init :: proc(ctx: ^Context) -> (ok: bool) {
	// Load our tree image to texture
	diffuse_texture := app.create_texture_from_file(
		ctx.gpu.device,
		ctx.gpu.queue,
		"assets/textures/happy-tree.png",
	) or_return
	defer app.release(diffuse_texture)

	texture_bind_group_layout := wgpu.device_create_bind_group_layout(
		ctx.gpu.device,
		wgpu.BindGroupLayoutDescriptor {
			label = "TextureBindGroupLayout",
			entries = {
				{
					binding = 0,
					visibility = {.Fragment},
					type = wgpu.TextureBindingLayout {
						multisampled = false,
						view_dimension = .D2,
						sample_type = .Float,
					},
				},
				{
					binding = 1,
					visibility = {.Fragment},
					type = wgpu.SamplerBindingLayout{type = .Filtering},
				},
			},
		},
	) or_return
	defer wgpu.release(texture_bind_group_layout)

	ctx.diffuse_bind_group = wgpu.device_create_bind_group(
		ctx.gpu.device,
		wgpu.BindGroupDescriptor {
			label = "diffuse_bind_group",
			layout = texture_bind_group_layout,
			entries = {
				{binding = 0, resource = diffuse_texture.view},
				{binding = 1, resource = diffuse_texture.sampler},
			},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.diffuse_bind_group)
	}

	ctx.camera = {
		{0.0, 1.0, 2.0},
		{0.0, 0.0, 0.0},
		{0.0, 1.0, 0.0},
		cast(f32)ctx.gpu.config.width / cast(f32)ctx.gpu.config.height,
		// math.PI / 4,
		cast(f32)la.to_radians(45.0),
		0.1,
		100.0,
	}

	ctx.camera_controller = new_camera_controller(10)

	ctx.camera_uniform = new_camera_uniform()
	update_view_proj(&ctx.camera_uniform, &ctx.camera)

	ctx.camera_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		wgpu.BufferDataDescriptor {
			label = "Camera Buffer",
			contents = wgpu.to_bytes(ctx.camera_uniform.view_proj),
			usage = {.Uniform, .CopyDst},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.camera_buffer)
	}

	camera_bind_group_layout := wgpu.device_create_bind_group_layout(
		ctx.gpu.device,
		wgpu.BindGroupLayoutDescriptor {
			label = "camera_bind_group_layout",
			entries = {
				{
					binding = 0,
					visibility = {.Vertex},
					type = wgpu.BufferBindingLayout{type = .Uniform, has_dynamic_offset = false},
				},
			},
		},
	) or_return
	defer wgpu.release(camera_bind_group_layout)

	ctx.camera_bind_group = wgpu.device_create_bind_group(
		ctx.gpu.device,
		wgpu.BindGroupDescriptor {
			label = "camera_bind_group",
			layout = camera_bind_group_layout,
			entries = {
				{
					binding = 0,
					resource = wgpu.BufferBinding {
						buffer = ctx.camera_buffer,
						size = wgpu.WHOLE_SIZE,
					},
				},
			},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.camera_bind_group)
	}

	render_pipeline_layout := wgpu.device_create_pipeline_layout(
		ctx.gpu.device,
		{
			label = "Render Pipeline Layout",
			bind_group_layouts = {texture_bind_group_layout, camera_bind_group_layout},
		},
	) or_return
	defer wgpu.release(render_pipeline_layout)

	vertex_buffer_layout := wgpu.VertexBufferLayout {
		array_stride = size_of(Vertex),
		step_mode    = .Vertex,
		attributes   = {
			{offset = 0, shader_location = 0, format = .Float32x3},
			{
				offset = cast(u64)offset_of(Vertex, tex_coords),
				shader_location = 1,
				format = .Float32x2,
			},
		},
	}

	CUBE_WGSL :: #load("./shader.wgsl")
	shader_module := wgpu.device_create_shader_module(
		ctx.gpu.device,
		{source = string(CUBE_WGSL)},
	) or_return
	defer wgpu.release(shader_module)

	render_pipeline_descriptor := wgpu.RenderPipelineDescriptor {
		label = "Render Pipeline",
		layout = render_pipeline_layout,
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
					write_mask = wgpu.COLOR_WRITE_MASK_ALL,
				},
			},
		},
		primitive = {topology = .TriangleList, front_face = .CCW, cull_mode = .Back},
		depth_stencil = nil,
		multisample = {count = 1, mask = ~u32(0), alpha_to_coverage_enabled = false},
	}

	ctx.render_pipeline = wgpu.device_create_render_pipeline(
		ctx.gpu.device,
		render_pipeline_descriptor,
	) or_return
	defer if !ok {
		wgpu.release(ctx.render_pipeline)
	}

	vertices := []Vertex {
		{position = {-0.0868241, 0.49240386, 0.0}, tex_coords = {0.4131759, 0.00759614}}, // A
		{position = {-0.49513406, 0.06958647, 0.0}, tex_coords = {0.0048659444, 0.43041354}}, // B
		{position = {-0.21918549, -0.44939706, 0.0}, tex_coords = {0.28081453, 0.949397}}, // C
		{position = {0.35966998, -0.3473291, 0.0}, tex_coords = {0.85967, 0.84732914}}, // D
		{position = {0.44147372, 0.2347359, 0.0}, tex_coords = {0.9414737, 0.2652641}}, // E
	}

	indices: []u16 = {0, 1, 4, 1, 2, 4, 2, 3, 4}

	ctx.num_indices = cast(u32)len(indices)

	ctx.vertex_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		wgpu.BufferDataDescriptor {
			label = "Vertex Buffer",
			contents = wgpu.to_bytes(vertices),
			usage = {.Vertex},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.vertex_buffer)
	}

	ctx.index_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		wgpu.BufferDataDescriptor {
			label = "Index Buffer",
			contents = wgpu.to_bytes(indices),
			usage = {.Index},
		},
	) or_return

	ctx.render_pass.color_attachments[0] = {
		view        = nil, /* Assigned later */
		depth_slice = wgpu.DEPTH_SLICE_UNDEFINED,
		load_op     = .Clear,
		store_op    = .Store,
		clear_value = {0.1, 0.2, 0.3, 1.0},
	}

	ctx.render_pass.descriptor = {
		label             = "Render pass descriptor",
		color_attachments = ctx.render_pass.color_attachments[:],
	}

	return true
}

quit :: proc(ctx: ^Context) {
	wgpu.release(ctx.index_buffer)
	wgpu.release(ctx.vertex_buffer)
	wgpu.release(ctx.render_pipeline)
	wgpu.release(ctx.camera_bind_group)
	wgpu.release(ctx.diffuse_bind_group)
	wgpu.release(ctx.camera_buffer)
}

resize :: proc(ctx: ^Context, size: app.ResizeEvent) -> bool {
	ctx.camera.aspect = cast(f32)size.w / cast(f32)size.h
	update_view_proj(&ctx.camera_uniform, &ctx.camera)
	wgpu.queue_write_buffer(
		ctx.gpu.queue,
		ctx.camera_buffer,
		0,
		wgpu.to_bytes(ctx.camera_uniform.view_proj),
	) or_return

	return true
}

update :: proc(ctx: ^Context, dt: f64) -> bool {
	update_camera_controller(&ctx.camera_controller, &ctx.camera, dt)
	update_view_proj(&ctx.camera_uniform, &ctx.camera)

	wgpu.queue_write_buffer(
		ctx.gpu.queue,
		ctx.camera_buffer,
		0,
		wgpu.to_bytes(ctx.camera_uniform.view_proj),
	)

	return true
}

draw :: proc(ctx: ^Context) -> bool {
	ctx.cmd = wgpu.device_create_command_encoder(ctx.gpu.device) or_return
	defer wgpu.release(ctx.cmd)

	ctx.render_pass.color_attachments[0].view = ctx.frame.view
	render_pass := wgpu.command_encoder_begin_render_pass(ctx.cmd, ctx.render_pass.descriptor)
	defer wgpu.release(render_pass)

	wgpu.render_pass_set_pipeline(render_pass, ctx.render_pipeline)
	wgpu.render_pass_set_bind_group(render_pass, 0, ctx.diffuse_bind_group)
	wgpu.render_pass_set_bind_group(render_pass, 1, ctx.camera_bind_group)
	wgpu.render_pass_set_vertex_buffer(render_pass, 0, {buffer = ctx.vertex_buffer})
	wgpu.render_pass_set_index_buffer(render_pass, {buffer = ctx.index_buffer}, .Uint16)
	wgpu.render_pass_draw_indexed(render_pass, {0, ctx.num_indices})

	wgpu.render_pass_end(render_pass) or_return

	cmdbuf := wgpu.command_encoder_finish(ctx.cmd) or_return
	defer wgpu.release(cmdbuf)

	wgpu.queue_submit(ctx.gpu.queue, cmdbuf)
	wgpu.surface_present(ctx.gpu.surface) or_return

	return true
}

handle_event :: proc(ctx: ^Context, event: app.Event) {
	#partial switch ev in event {
	case app.KeyEvent:
		controller := &ctx.camera_controller
		pressed := ev.action == .Pressed
		#partial switch ev.key {
		case .Space:
			controller.is_up_pressed = true if pressed else false
		case .LeftShift:
			controller.is_down_pressed = true if pressed else false
		case .W:
			controller.is_forward_pressed = true if pressed else false
		case .A:
			controller.is_left_pressed = true if pressed else false
		case .S:
			controller.is_backward_pressed = true if pressed else false
		case .D:
			controller.is_right_pressed = true if pressed else false
		}
	}

	return
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
		init         = init,
		quit         = quit,
		resize       = resize,
		handle_event = handle_event,
		update       = update,
		draw         = draw,
	}

	app.run(example) // Start the main loop
}

build_view_projection_matrix :: proc(camera: ^Camera) -> la.Matrix4f32 {
	projection := la.matrix4_perspective_f32(
		camera.fovYRad,
		camera.aspect,
		camera.znear,
		camera.zfar,
	)
	view := la.matrix4_look_at_f32(eye = camera.eye, centre = camera.target, up = camera.up)
	// return la.mul(projection, view)
	return app.OPEN_GL_TO_WGPU_MATRIX * projection * view
}

new_camera_uniform :: proc() -> CameraUniform {
	return {la.MATRIX4F32_IDENTITY}
}

update_view_proj :: proc(self: ^CameraUniform, camera: ^Camera) {
	self.view_proj = build_view_projection_matrix(camera)
}

new_camera_controller :: proc(speed: f32) -> CameraController {
	return {speed = speed}
}

update_camera_controller :: proc(self: ^CameraController, camera: ^Camera, dt: f64) {
	// Calculate frame-independent movement speed
	frame_speed := self.speed * f32(dt)

	forward := camera.target - camera.eye
	forward_norm := la.normalize(forward)
	forward_mag := la.length(forward)

	// Prevents glitching when the camera gets too close to the center of the scene.
	if self.is_forward_pressed && forward_mag > frame_speed {
		camera.eye += forward_norm * frame_speed
	}

	if self.is_backward_pressed {
		camera.eye -= forward_norm * frame_speed
	}

	right := la.cross(forward_norm, camera.up)

	// Redo radius calc in case the forward/backward is pressed.
	forward = camera.target - camera.eye
	forward_mag = la.length(forward)

	if self.is_right_pressed {
		camera.eye = camera.target - la.normalize(forward + right * frame_speed) * forward_mag
	}

	if self.is_left_pressed {
		camera.eye = camera.target - la.normalize(forward - right * frame_speed) * forward_mag
	}
}
