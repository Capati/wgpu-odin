package tutorial7_instancing_challenge

// Core
import "core:log"
import "core:math"
import la "core:math/linalg"

// Local Packages
import wgpu "../../../../" /* root folder */
import app "../../../../utils/application"

NUM_INSTANCES_PER_ROW :: 10
INSTANCE_DISPLACEMENT :: la.Vector3f32 {
	NUM_INSTANCES_PER_ROW * 0.5,
	0.0,
	NUM_INSTANCES_PER_ROW * 0.5,
}

Vertex :: struct {
	position:   [3]f32,
	tex_coords: [2]f32,
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

CLIENT_WIDTH       :: 640
CLIENT_HEIGHT      :: 480
EXAMPLE_TITLE      :: "Tutorial 7 - Instancing (Challenge)"
VIDEO_MODE_DEFAULT :: app.Video_Mode {
	width  = CLIENT_WIDTH,
	height = CLIENT_HEIGHT,
}

Application :: struct {
	using _app:         app.Application, /* #subtype */
	diffuse_bind_group: wgpu.BindGroup,
	camera:             Camera,
	camera_controller:  Camera_Controller,
	camera_uniform:     Camera_Uniform,
	camera_buffer:      wgpu.Buffer,
	camera_bind_group:  wgpu.BindGroup,
	render_pipeline:    wgpu.RenderPipeline,
	num_indices:        u32,
	vertex_buffer:      wgpu.Buffer,
	index_buffer:       wgpu.Buffer,
	instance_buffer:    wgpu.Buffer,
	instances:          [NUM_INSTANCES_PER_ROW * NUM_INSTANCES_PER_ROW]Instance,
	rpass: struct {
		colors:     [1]wgpu.RenderPassColorAttachment,
		descriptor: wgpu.RenderPassDescriptor,
	},
}

create :: proc() -> (self: ^Application) {
	self = new(Application)
	assert(self != nil, "Failed to allocate Application")

	app.init(self, VIDEO_MODE_DEFAULT, EXAMPLE_TITLE)

	// Load our tree image to texture
	diffuse_texture := app.create_texture_from_file(
		self,
		"assets/textures/happy-tree.png",
	)
	defer app.texture_release(diffuse_texture)

	texture_bind_group_layout := wgpu.DeviceCreateBindGroupLayout(
		self.gpu.device,
		wgpu.BindGroupLayoutDescriptor {
			label = "TextureBindGroupLayout",
			entries = {
				{
					binding = 0,
					visibility = {.Fragment},
					type = wgpu.TextureBindingLayout {
						multisampled = false,
						viewDimension = ._2D,
						sampleType = .Float,
					},
				},
				{
					binding = 1,
					visibility = {.Fragment},
					type = wgpu.SamplerBindingLayout{type = .Filtering},
				},
			},
		},
	)
	defer wgpu.Release(texture_bind_group_layout)

	self.diffuse_bind_group = wgpu.DeviceCreateBindGroup(
		self.gpu.device,
		wgpu.BindGroupDescriptor {
			label = "diffuse_bind_group",
			layout = texture_bind_group_layout,
			entries = {
				{binding = 0, resource = diffuse_texture.view},
				{binding = 1, resource = diffuse_texture.sampler},
			},
		},
	)

	self.camera = {
		{0.0, 1.0, 2.0},
		{0.0, 0.0, 0.0},
		{0.0, 1.0, 0.0},
		cast(f32)self.gpu.config.width / cast(f32)self.gpu.config.height,
		// math.PI / 4,
		cast(f32)la.to_radians(45.0),
		0.1,
		100.0,
	}

	self.camera_controller = new_camera_controller(10)

	self.camera_uniform = new_camera_uniform()
	update_view_proj(&self.camera_uniform, &self.camera)

	self.camera_buffer = wgpu.DeviceCreateBufferWithData(
		self.gpu.device,
		wgpu.BufferDataDescriptor {
			label = "Camera Buffer",
			contents = wgpu.ToBytes(self.camera_uniform.view_proj),
			usage = {.Uniform, .CopyDst},
		},
	)

	index := 0
	for z in 0 ..< NUM_INSTANCES_PER_ROW {
		for x in 0 ..< NUM_INSTANCES_PER_ROW {
			position := la.Vector3f32{f32(x), 0, f32(z)} - INSTANCE_DISPLACEMENT
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
			self.instances[index] = Instance {
				position = position,
				rotation = rotation,
			}
			index += 1
		}
	}

	instance_data: [NUM_INSTANCES_PER_ROW * NUM_INSTANCES_PER_ROW]Instance_Raw
	for v, i in self.instances {
		instance_data[i] = instance_to_raw(v)
	}

	self.instance_buffer = wgpu.DeviceCreateBufferWithData(
		self.gpu.device,
		wgpu.BufferDataDescriptor {
			label = "Instance Buffer",
			contents = wgpu.ToBytes(instance_data[:]),
			usage = {.Vertex, .CopyDst},
		},
	)

	camera_bind_group_layout := wgpu.DeviceCreateBindGroupLayout(
		self.gpu.device,
		wgpu.BindGroupLayoutDescriptor {
			label = "camera_bind_group_layout",
			entries = {
				{
					binding = 0,
					visibility = {.Vertex},
					type = wgpu.BufferBindingLayout{type = .Uniform, hasDynamicOffset = false},
				},
			},
		},
	)
	defer wgpu.Release(camera_bind_group_layout)

	self.camera_bind_group = wgpu.DeviceCreateBindGroup(
		self.gpu.device,
		wgpu.BindGroupDescriptor {
			label = "camera_bind_group",
			layout = camera_bind_group_layout,
			entries = {
				{
					binding = 0,
					resource = wgpu.BufferBinding {
						buffer = self.camera_buffer,
						size = wgpu.WHOLE_SIZE,
					},
				},
			},
		},
	)

	render_pipeline_layout := wgpu.DeviceCreatePipelineLayout(
		self.gpu.device,
		{
			label = "Render Pipeline Layout",
			bindGroupLayouts = {texture_bind_group_layout, camera_bind_group_layout},
		},
	)
	defer wgpu.Release(render_pipeline_layout)

	vertex_buffer_layout := wgpu.VertexBufferLayout {
		arrayStride = size_of(Vertex),
		stepMode    = .Vertex,
		attributes   = {
			{offset = 0, shaderLocation = 0, format = .Float32x3},
			{
				offset = cast(u64)offset_of(Vertex, tex_coords),
				shaderLocation = 1,
				format = .Float32x2,
			},
		},
	}

	instance_buffer_layout := wgpu.VertexBufferLayout {
		arrayStride = size_of(Instance_Raw),
		// We need to switch from using a step mode of Vertex to Instance
		// This means that our shaders will only change to use the next
		// instance when the shader starts processing a new instance
		stepMode    = .Instance,
		// A Matrix4 takes up 4 vertex slots as it is technically 4 vec4s. We need to define a
		// slot for each vec4. We'll have to reassemble the Matrix4 in the shader.
		attributes   = {
			// While our vertex shader only uses locations 0, and 1 now, in later tutorials, we'll
			// be using 2, 3, and 4, for Vertex. We'll start at slot 5, not conflict with them later
			{offset = 0, shaderLocation = 5, format = .Float32x4},
			{offset = size_of([4]f32), shaderLocation = 6, format = .Float32x4},
			{offset = size_of([8]f32), shaderLocation = 7, format = .Float32x4},
			{offset = size_of([12]f32), shaderLocation = 8, format = .Float32x4},
		},
	}

	CUBE_WGSL :: #load("./../tutorial7_instancing/shader.wgsl")
	shader_module := wgpu.DeviceCreateShaderModule(
		self.gpu.device,
		{source = string(CUBE_WGSL)},
	)
	defer wgpu.Release(shader_module)

	render_pipeline_descriptor := wgpu.RenderPipelineDescriptor {
		label = "Render Pipeline",
		layout = render_pipeline_layout,
		vertex = {
			module = shader_module,
			entryPoint = "vs_main",
			buffers = {vertex_buffer_layout, instance_buffer_layout},
		},
		fragment = &{
			module = shader_module,
			entryPoint = "fs_main",
			targets = {
				{
					format = self.gpu.config.format,
					blend = &wgpu.BLEND_STATE_REPLACE,
					writeMask = wgpu.COLOR_WRITES_ALL,
				},
			},
		},
		primitive = {topology = .TriangleList, frontFace = .CCW, cullMode = .Back},
		multisample = {count = 1, mask = ~u32(0), alphaToCoverageEnabled = false},
	}

	self.render_pipeline = wgpu.DeviceCreateRenderPipeline(
		self.gpu.device,
		render_pipeline_descriptor,
	)

	vertices := []Vertex {
		{position = {-0.0868241, 0.49240386, 0.0}, tex_coords = {0.4131759, 0.00759614}}, // A
		{position = {-0.49513406, 0.06958647, 0.0}, tex_coords = {0.0048659444, 0.43041354}}, // B
		{position = {-0.21918549, -0.44939706, 0.0}, tex_coords = {0.28081453, 0.949397}}, // C
		{position = {0.35966998, -0.3473291, 0.0}, tex_coords = {0.85967, 0.84732914}}, // D
		{position = {0.44147372, 0.2347359, 0.0}, tex_coords = {0.9414737, 0.2652641}}, // E
	}

	indices: []u16 = {0, 1, 4, 1, 2, 4, 2, 3, 4}

	self.num_indices = cast(u32)len(indices)

	self.vertex_buffer = wgpu.DeviceCreateBufferWithData(
		self.gpu.device,
		wgpu.BufferDataDescriptor {
			label = "Vertex Buffer",
			contents = wgpu.ToBytes(vertices),
			usage = {.Vertex},
		},
	)

	self.index_buffer = wgpu.DeviceCreateBufferWithData(
		self.gpu.device,
		wgpu.BufferDataDescriptor {
			label = "Index Buffer",
			contents = wgpu.ToBytes(indices),
			usage = {.Index},
		},
	)

	self.rpass.colors[0] = {
		view = nil, /* Assigned later */
		ops  = {.Clear, .Store, {0.1, 0.2, 0.3, 1.0}},
	}

	self.rpass.descriptor = {
		label            = "Render pass descriptor",
		colorAttachments = self.rpass.colors[:],
	}

	app.add_resize_callback(self, { resize, self })

	return
}

release :: proc(self: ^Application) {
	wgpu.Release(self.index_buffer)
	wgpu.Release(self.vertex_buffer)
	wgpu.Release(self.render_pipeline)
	wgpu.Release(self.camera_bind_group)
	wgpu.Release(self.diffuse_bind_group)
	wgpu.Release(self.camera_buffer)
	wgpu.Release(self.instance_buffer)

	app.release(self)
	free(self)
}

handle_input :: proc(self: ^Application) {
	controller := &self.camera_controller
	controller.is_forward_pressed = app.key_is_down(self, .W)
	controller.is_left_pressed = app.key_is_down(self, .A)
	controller.is_backward_pressed = app.key_is_down(self, .S)
	controller.is_right_pressed = app.key_is_down(self, .D)
}

ROTATION_SPEED_RAD: f32 = 1.0 * math.PI // radians per second

update :: proc(self: ^Application) {
	dt := app.get_delta_time(self)

	update_camera_controller(&self.camera_controller, &self.camera, dt)
	update_view_proj(&self.camera_uniform, &self.camera)

	wgpu.QueueWriteBuffer(
		self.gpu.queue,
		self.camera_buffer,
		0,
		wgpu.ToBytes(self.camera_uniform.view_proj),
	)

	// Create rotation quaternion using dt
	rotation_amount := la.quaternion_angle_axis_f32(ROTATION_SPEED_RAD * dt, {0, 0, 1})

	instance_data: [NUM_INSTANCES_PER_ROW * NUM_INSTANCES_PER_ROW]Instance_Raw
	for &v, i in self.instances {
		v.rotation = la.mul(rotation_amount, v.rotation)
		self.instances[i] = v
		instance_data[i] = instance_to_raw(v)
	}

	wgpu.QueueWriteBuffer(
		self.gpu.queue,
		self.instance_buffer,
		0,
		wgpu.ToBytes(instance_data[:]),
	)
}

draw :: proc(self: ^Application) {
	frame := app.gpu_get_current_frame(self.gpu)
	if frame.skip { return }
	defer app.gpu_release_current_frame(&frame)

	encoder := wgpu.DeviceCreateCommandEncoder(self.gpu.device)
	defer wgpu.Release(encoder)

	self.rpass.colors[0].view = frame.view
	rpass := wgpu.CommandEncoderBeginRenderPass(encoder, self.rpass.descriptor)
	defer wgpu.Release(rpass)

	wgpu.RenderPassSetPipeline(rpass, self.render_pipeline)

	wgpu.RenderPassSetBindGroup(rpass, 0, self.diffuse_bind_group)
	wgpu.RenderPassSetBindGroup(rpass, 1, self.camera_bind_group)
	wgpu.RenderPassSetVertexBuffer(rpass, 0, {buffer = self.vertex_buffer})

	wgpu.RenderPassSetVertexBuffer(rpass, 1, {buffer = self.instance_buffer})
	wgpu.RenderPassSetIndexBuffer(rpass, {buffer = self.index_buffer}, .Uint16)

	wgpu.RenderPassDrawIndexed(
		rpass,
		indices = {0, self.num_indices},
		baseVertex = 0,
		instances = {0, u32(len(self.instances))},
	)

	wgpu.RenderPassEnd(rpass)

	cmdbuf := wgpu.CommandEncoderFinish(encoder)
	defer wgpu.Release(cmdbuf)

	wgpu.QueueSubmit(self.gpu.queue, { cmdbuf })
	wgpu.SurfacePresent(self.gpu.surface)
}

resize :: proc(window: ^app.Window, size: app.Vec2u, userdata: rawptr) {
	self := cast(^Application)userdata

	self.camera.aspect = cast(f32)size.x / cast(f32)size.y
	update_view_proj(&self.camera_uniform, &self.camera)
	wgpu.QueueWriteBuffer(
		self.gpu.queue,
		self.camera_buffer,
		0,
		wgpu.ToBytes(self.camera_uniform.view_proj),
	)

	update(self)
	draw(self)
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

update_camera_controller :: proc(self: ^Camera_Controller, camera: ^Camera, dt: f32) {
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

main :: proc() {
	when ODIN_DEBUG {
		context.logger = log.create_console_logger(opt = {.Level, .Terminal_Color})
		defer log.destroy_console_logger(context.logger)
	}

	example := create()
	defer release(example)

	running := true
	MAIN_LOOP: for running {
		event: app.Event
		for app.poll_event(example, &event) {
			#partial switch &ev in event {
			case app.QuitEvent:
				log.info("Exiting...")
				running = false
			}
		}

		app.begin_frame(example)
		handle_input(example)
		update(example)
		draw(example)
		app.end_frame(example)
	}
}
