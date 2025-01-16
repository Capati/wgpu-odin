package tutorial9_model_loading

// Packages
import "core:log"
import "core:math"
import la "core:math/linalg"

// Local Packages
import "root:examples/common"
import app "root:utils/application"
import "root:wgpu"

NUM_INSTANCES_PER_ROW :: 10
INSTANCE_DISPLACEMENT :: la.Vector3f32 {
	NUM_INSTANCES_PER_ROW * 0.5,
	0.0,
	NUM_INSTANCES_PER_ROW * 0.5,
}

Instance :: struct {
	position: [3]f32,
	rotation: la.Quaternionf32,
}

Instance_Raw :: struct {
	model: la.Matrix4f32,
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

Camera_Uniform :: struct {
	view_proj: la.Matrix4f32,
}

Camera_Controller :: struct {
	speed:               f32,
	is_up_pressed:       bool,
	is_down_pressed:     bool,
	is_forward_pressed:  bool,
	is_backward_pressed: bool,
	is_left_pressed:     bool,
	is_right_pressed:    bool,
}

Depth_Texture :: struct {
	created: bool,
	texture: wgpu.Texture,
	view:    wgpu.Texture_View,
	sampler: wgpu.Sampler,
}

Example :: struct {
	camera:            Camera,
	camera_controller: Camera_Controller,
	camera_uniform:    Camera_Uniform,
	camera_buffer:     wgpu.Buffer,
	camera_bind_group: wgpu.Bind_Group,
	model:             ^common.Model,
	render_pipeline:   wgpu.Render_Pipeline,
	instance_buffer:   wgpu.Buffer,
	instances:         [NUM_INSTANCES_PER_ROW * NUM_INSTANCES_PER_ROW]Instance,
	depth_texture:     Depth_Texture,
	render_pass:       struct {
		color_attachments:        [1]wgpu.Render_Pass_Color_Attachment,
		depth_stencil_attachment: wgpu.Render_Pass_Depth_Stencil_Attachment,
		descriptor:               wgpu.Render_Pass_Descriptor,
	},
}

Context :: app.Context(Example)

EXAMPLE_TITLE :: "Tutorial 9 - Model Loading"

DEPTH_FORMAT :: wgpu.Texture_Format.Depth32Float

init :: proc(ctx: ^Context) -> (ok: bool) {
	texture_bind_group_layout := wgpu.device_create_bind_group_layout(
		ctx.gpu.device,
		wgpu.Bind_Group_Layout_Descriptor {
			label = "TextureBindGroupLayout",
			entries = {
				{
					binding = 0,
					visibility = {.Fragment},
					type = wgpu.Texture_Binding_Layout {
						multisampled = false,
						view_dimension = .D2,
						sample_type = .Float,
					},
				},
				{
					binding = 1,
					visibility = {.Fragment},
					type = wgpu.Sampler_Binding_Layout{type = .Filtering},
				},
			},
		},
	) or_return
	defer wgpu.release(texture_bind_group_layout)

	ctx.camera = {
		{0.0, 5.0, -10.0},
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
		wgpu.Buffer_Data_Descriptor {
			label = "Camera Buffer",
			contents = wgpu.to_bytes(ctx.camera_uniform.view_proj),
			usage = {.Uniform, .Copy_Dst},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.camera_buffer)
	}

	index := 0
	SPACE_BETWEEN :: 3.0
	for z in 0 ..< NUM_INSTANCES_PER_ROW {
		for x in 0 ..< NUM_INSTANCES_PER_ROW {
			x := SPACE_BETWEEN * (f32(x) - NUM_INSTANCES_PER_ROW / 2.0)
			z := SPACE_BETWEEN * (f32(z) - NUM_INSTANCES_PER_ROW / 2.0)
			position := la.Vector3f32{x, 0, z}
			rotation: la.Quaternionf32
			// this is needed so an object at (0, 0, 0) won't get scaled to zero
			// as Quaternions can affect scale if they're not created correctly
			if position == {} {
				rotation = la.quaternion_angle_axis_f32(0, {0, 0, 1})
			} else {
				rotation = la.quaternion_angle_axis_f32(
					f32(la.to_radians(45.0)),
					la.normalize(position),
				)
			}
			ctx.instances[index] = Instance {
				position = position,
				rotation = rotation,
			}
			index += 1
		}
	}

	instance_data: [NUM_INSTANCES_PER_ROW * NUM_INSTANCES_PER_ROW]Instance_Raw
	for v, i in ctx.instances {
		instance_data[i] = instance_to_raw(v)
	}

	ctx.instance_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		wgpu.Buffer_Data_Descriptor {
			label = "Instance Buffer",
			contents = wgpu.to_bytes(instance_data[:]),
			usage = {.Vertex, .Copy_Dst},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.instance_buffer)
	}

	camera_bind_group_layout := wgpu.device_create_bind_group_layout(
		ctx.gpu.device,
		wgpu.Bind_Group_Layout_Descriptor {
			label = "camera_bind_group_layout",
			entries = {
				{
					binding = 0,
					visibility = {.Vertex},
					type = wgpu.Buffer_Binding_Layout{type = .Uniform, has_dynamic_offset = false},
				},
			},
		},
	) or_return
	defer wgpu.release(camera_bind_group_layout)

	ctx.camera_bind_group = wgpu.device_create_bind_group(
		ctx.gpu.device,
		wgpu.Bind_Group_Descriptor {
			label = "camera_bind_group",
			layout = camera_bind_group_layout,
			entries = {
				{
					binding = 0,
					resource = wgpu.Buffer_Binding {
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

	ctx.model = common.load_model(
		ctx,
		"assets/models/cube/cube.obj",
		texture_bind_group_layout,
	) or_return
	defer if !ok {
		common.destroy_model(ctx.model)
	}

	render_pipeline_layout := wgpu.device_create_pipeline_layout(
		ctx.gpu.device,
		{
			label = "Render Pipeline Layout",
			bind_group_layouts = {texture_bind_group_layout, camera_bind_group_layout},
		},
	) or_return
	defer wgpu.release(render_pipeline_layout)

	instance_buffer_layout := wgpu.Vertex_Buffer_Layout {
		array_stride = size_of(Instance_Raw),
		// We need to switch from using a step mode of Vertex to Instance
		// This means that our shaders will only change to use the next
		// instance when the shader starts processing a new instance
		step_mode    = .Instance,
		// A Matrix4 takes up 4 vertex slots as it is technically 4 vec4s. We need to define a
		// slot for each vec4. We'll have to reassemble the Matrix4 in the shader.
		attributes   = {
			// While our vertex shader only uses locations 0, and 1 now, in later tutorials, we'll
			// be using 2, 3, and 4, for Vertex. We'll start at slot 5, not conflict with them later
			{offset = 0, shader_location = 5, format = .Float32x4},
			{offset = size_of([4]f32), shader_location = 6, format = .Float32x4},
			{offset = size_of([8]f32), shader_location = 7, format = .Float32x4},
			{offset = size_of([12]f32), shader_location = 8, format = .Float32x4},
		},
	}

	CUBE_WGSL :: #load("./../tutorial7_instancing/shader.wgsl")
	shader_module := wgpu.device_create_shader_module(
		ctx.gpu.device,
		{source = string(CUBE_WGSL)},
	) or_return
	defer wgpu.release(shader_module)

	render_pipeline_descriptor := wgpu.Render_Pipeline_Descriptor {
		label = "Render Pipeline",
		layout = render_pipeline_layout,
		vertex = {
			module = shader_module,
			entry_point = "vs_main",
			buffers = {common.MODEL_VERTEX_LAYOUT, instance_buffer_layout},
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
		primitive = {topology = .Triangle_List, front_face = .CCW, cull_mode = .Back},
		depth_stencil = {
			format = DEPTH_FORMAT,
			depth_write_enabled = true,
			depth_compare = .Less,
			stencil = {
				front = {compare = .Always},
				back = {compare = .Always},
				read_mask = max(u32),
				write_mask = max(u32),
			},
		},
		multisample = {count = 1, mask = ~u32(0), alpha_to_coverage_enabled = false},
	}

	ctx.render_pipeline = wgpu.device_create_render_pipeline(
		ctx.gpu.device,
		render_pipeline_descriptor,
	) or_return
	defer if !ok {
		wgpu.release(ctx.render_pipeline)
	}

	create_depth_texture(ctx) or_return

	ctx.render_pass.color_attachments[0] = {
		view = nil, /* Assigned later */
		ops  = {.Clear, .Store, {0.1, 0.2, 0.3, 1.0}},
	}

	ctx.render_pass.descriptor = {
		label                    = "Render pass descriptor",
		color_attachments        = ctx.render_pass.color_attachments[:],
		depth_stencil_attachment = &ctx.render_pass.depth_stencil_attachment,
	}

	return true
}

create_depth_texture :: proc(ctx: ^Context) -> (ok: bool) {
	if ctx.depth_texture.created {
		wgpu.release(ctx.depth_texture.sampler)
		wgpu.release(ctx.depth_texture.view)
		wgpu.release(ctx.depth_texture.texture)
	}

	texture_descriptor := wgpu.Texture_Descriptor {
		usage = {.Render_Attachment, .Copy_Dst},
		format = DEPTH_FORMAT,
		dimension = .D2,
		mip_level_count = 1,
		sample_count = 1,
		size = {
			width = ctx.gpu.config.width,
			height = ctx.gpu.config.height,
			depth_or_array_layers = 1,
		},
	}

	ctx.depth_texture.texture = wgpu.device_create_texture(
		ctx.gpu.device,
		texture_descriptor,
	) or_return
	defer if !ok {
		wgpu.release(ctx.depth_texture.texture)
	}

	texture_view_descriptor := wgpu.Texture_View_Descriptor {
		format            = texture_descriptor.format,
		dimension         = .D2,
		base_mip_level    = 0,
		mip_level_count   = 1,
		base_array_layer  = 0,
		array_layer_count = 1,
		aspect            = .All,
	}

	ctx.depth_texture.view = wgpu.texture_create_view(
		ctx.depth_texture.texture,
		texture_view_descriptor,
	) or_return
	defer if !ok {
		wgpu.release(ctx.depth_texture.view)
	}

	sampler_descriptor := wgpu.Sampler_Descriptor {
		address_mode_u = .Clamp_To_Edge,
		address_mode_v = .Clamp_To_Edge,
		address_mode_w = .Clamp_To_Edge,
		mag_filter     = .Linear,
		min_filter     = .Linear,
		mipmap_filter  = .Nearest,
		lod_min_clamp  = 0.0,
		lod_max_clamp  = 100.0,
		compare        = .Less_Equal,
		max_anisotropy = 1,
	}

	ctx.depth_texture.sampler = wgpu.device_create_sampler(
		ctx.gpu.device,
		sampler_descriptor,
	) or_return

	ctx.render_pass.depth_stencil_attachment = {
		view                = ctx.depth_texture.view,
		depth_load_op       = .Clear,
		depth_store_op      = .Store,
		depth_clear_value   = 1.0,
		stencil_clear_value = 0.0,
	}

	ctx.depth_texture.created = true

	return true
}

quit :: proc(ctx: ^Context) {
	wgpu.release(ctx.depth_texture.sampler)
	wgpu.release(ctx.depth_texture.view)
	wgpu.release(ctx.depth_texture.texture)
	wgpu.release(ctx.render_pipeline)
	common.destroy_model(ctx.model)
	wgpu.release(ctx.camera_bind_group)
	wgpu.release(ctx.camera_buffer)
	wgpu.release(ctx.instance_buffer)
}

resize :: proc(ctx: ^Context, size: app.Resize_Event) -> bool {
	create_depth_texture(ctx) or_return

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

ROTATION_SPEED_RAD: f32 = 0.5 * math.PI // radians per second

update :: proc(ctx: ^Context, dt: f64) -> bool {
	update_camera_controller(&ctx.camera_controller, &ctx.camera, dt)
	update_view_proj(&ctx.camera_uniform, &ctx.camera)

	wgpu.queue_write_buffer(
		ctx.gpu.queue,
		ctx.camera_buffer,
		0,
		wgpu.to_bytes(ctx.camera_uniform.view_proj),
	)

	// Create rotation quaternion using dt
	rotation_amount := la.quaternion_angle_axis_f32(ROTATION_SPEED_RAD * f32(dt), {0, 0, 1})

	instance_data: [NUM_INSTANCES_PER_ROW * NUM_INSTANCES_PER_ROW]Instance_Raw
	for &v, i in ctx.instances {
		v.rotation = la.mul(rotation_amount, v.rotation)
		ctx.instances[i] = v
		instance_data[i] = instance_to_raw(v)
	}

	wgpu.queue_write_buffer(
		ctx.gpu.queue,
		ctx.instance_buffer,
		0,
		wgpu.to_bytes(instance_data[:]),
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
	wgpu.render_pass_set_vertex_buffer(render_pass, 1, {buffer = ctx.instance_buffer})
	common.model_draw_instanced(
		render_pass,
		ctx.model,
		{0, u32(len(ctx.instances))},
		ctx.camera_bind_group,
	)

	wgpu.render_pass_end(render_pass) or_return

	cmdbuf := wgpu.command_encoder_finish(ctx.cmd) or_return
	defer wgpu.release(cmdbuf)

	wgpu.queue_submit(ctx.gpu.queue, cmdbuf)
	wgpu.surface_present(ctx.gpu.surface) or_return

	return true
}

handle_event :: proc(ctx: ^Context, event: app.Event) {
	#partial switch ev in event {
	case app.Key_Event:
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

new_camera_uniform :: proc() -> Camera_Uniform {
	return {la.MATRIX4F32_IDENTITY}
}

update_view_proj :: proc(self: ^Camera_Uniform, camera: ^Camera) {
	self.view_proj = build_view_projection_matrix(camera)
}

new_camera_controller :: proc(speed: f32) -> Camera_Controller {
	return {speed = speed}
}

update_camera_controller :: proc(self: ^Camera_Controller, camera: ^Camera, dt: f64) {
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

instance_to_raw :: proc(i: Instance) -> Instance_Raw {
	return {model = la.matrix4_from_trs_f32(i.position, i.rotation, {1, 1, 1})}
}
