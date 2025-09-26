package tutorial9_model_loading

// Core
import "core:log"
import "core:math"
import la "core:math/linalg"

// Local Packages
import wgpu "../../../../" /* root folder */
import app "../../../../utils/application"
import "../../../common"

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
	view:    wgpu.TextureView,
	sampler: wgpu.Sampler,
}

CLIENT_WIDTH       :: 800
CLIENT_HEIGHT      :: 600
EXAMPLE_TITLE      :: "Tutorial 9 - Model Loading"
VIDEO_MODE_DEFAULT :: app.Video_Mode {
	width  = CLIENT_WIDTH,
	height = CLIENT_HEIGHT,
}

Application :: struct {
	using _app:        app.Application, /* #subtype */
	camera:            Camera,
	camera_controller: Camera_Controller,
	camera_uniform:    Camera_Uniform,
	camera_buffer:     wgpu.Buffer,
	camera_bind_group: wgpu.BindGroup,
	model:             ^common.Model,
	render_pipeline:   wgpu.RenderPipeline,
	instance_buffer:   wgpu.Buffer,
	instances:         [NUM_INSTANCES_PER_ROW * NUM_INSTANCES_PER_ROW]Instance,
	depth_texture:     Depth_Texture,
	rpass:       struct {
		colors:     [1]wgpu.RenderPassColorAttachment,
		descriptor: wgpu.RenderPassDescriptor,
	},
}

DEPTH_FORMAT :: wgpu.TextureFormat.Depth32Float

init :: proc(self: ^Application) -> (ok: bool) {
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

	self.camera = {
		{0.0, 5.0, -10.0},
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

	self.model = common.load_model(
		self,
		"assets/models/cube/cube.obj",
		texture_bind_group_layout,
	)

	render_pipeline_layout := wgpu.DeviceCreatePipelineLayout(
		self.gpu.device,
		{
			label = "Render Pipeline Layout",
			bindGroupLayouts = {texture_bind_group_layout, camera_bind_group_layout},
		},
	)
	defer wgpu.Release(render_pipeline_layout)

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
			buffers = {common.MODEL_VERTEX_LAYOUT, instance_buffer_layout},
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
		depthStencil = {
			format = DEPTH_FORMAT,
			depthWriteEnabled = true,
			depthCompare = .Less,
			stencil = {
				front = {compare = .Always},
				back = {compare = .Always},
				readMask = max(u32),
				writeMask = max(u32),
			},
		},
		multisample = {count = 1, mask = ~u32(0), alphaToCoverageEnabled = false},
	}

	self.render_pipeline = wgpu.DeviceCreateRenderPipeline(
		self.gpu.device,
		render_pipeline_descriptor,
	)

	self.rpass.colors[0] = {
		view = nil, /* Assigned later */
		ops  = {.Clear, .Store, {0.1, 0.2, 0.3, 1.0}},
	}

	self.rpass.descriptor = {
		label                   = "Render pass descriptor",
		colorAttachments        = self.rpass.colors[:],
		depthStencilAttachment = nil, /* assigned later */
	}

	create_depth_texture(self)

	return true
}

handle_input :: proc(self: ^Application, dt: f32) -> (ok: bool) {
	controller := &self.camera_controller
	controller.is_forward_pressed = app.key_is_down(.W)
	controller.is_left_pressed = app.key_is_down(.A)
	controller.is_backward_pressed = app.key_is_down(.S)
	controller.is_right_pressed = app.key_is_down(.D)
	return true
}

ROTATION_SPEED_RAD: f32 = 0.5 * math.PI // radians per second

update :: proc(self: ^Application, dt: f32) -> (ok: bool) {
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

	return true
}

draw :: proc(self: ^Application, dt: f32) -> (ok: bool) {
	frame := app.gpu_get_current_frame(self.gpu)
	if frame.skip { return }
	defer app.gpu_release_current_frame(&frame)

	encoder := wgpu.DeviceCreateCommandEncoder(self.gpu.device)
	defer wgpu.Release(encoder)

	self.rpass.colors[0].view = frame.view
	rpass := wgpu.CommandEncoderBeginRenderPass(encoder, self.rpass.descriptor)
	defer wgpu.Release(rpass)

	wgpu.RenderPassSetPipeline(rpass, self.render_pipeline)
	wgpu.RenderPassSetVertexBuffer(rpass, 1, {buffer = self.instance_buffer})
	common.model_draw_instanced(
		rpass,
		self.model,
		{0, u32(len(self.instances))},
		self.camera_bind_group,
	)

	wgpu.RenderPassEnd(rpass)

	cmdbuf := wgpu.CommandEncoderFinish(encoder)
	defer wgpu.Release(cmdbuf)

	wgpu.QueueSubmit(self.gpu.queue, { cmdbuf })
	wgpu.SurfacePresent(self.gpu.surface)

	return true
}

step :: proc(self: ^Application, dt: f32) -> (ok: bool) {
	handle_input(self, dt) or_return
	update(self, dt) or_return
	draw(self, dt) or_return
	return true
}

event :: proc(self: ^Application, event: app.Event) -> (ok: bool) {
    #partial switch &ev in event {
        case app.Quit_Event:
            log.info("Exiting...")
            return
		case app.Resize_Event:
			resize(self, ev.size)
    }
    return true
}

quit :: proc(self: ^Application) {
	wgpu.Release(self.depth_texture.sampler)
	wgpu.Release(self.depth_texture.view)
	wgpu.Release(self.depth_texture.texture)
	wgpu.Release(self.render_pipeline)

	common.destroy_model(self.model)

	wgpu.Release(self.camera_bind_group)
	wgpu.Release(self.camera_buffer)
	wgpu.Release(self.instance_buffer)
}

resize :: proc(self: ^Application, size: app.Vec2u) {
	create_depth_texture(self)

	self.camera.aspect = cast(f32)size.x / cast(f32)size.y
	update_view_proj(&self.camera_uniform, &self.camera)
	wgpu.QueueWriteBuffer(
		self.gpu.queue,
		self.camera_buffer,
		0,
		wgpu.ToBytes(self.camera_uniform.view_proj),
	)
}

create_depth_texture :: proc(self: ^Application) {
	if self.depth_texture.created {
		wgpu.Release(self.depth_texture.sampler)
		wgpu.Release(self.depth_texture.view)
		wgpu.Release(self.depth_texture.texture)
	}

	texture_descriptor := wgpu.TextureDescriptor {
		usage = {.RenderAttachment, .CopyDst},
		format = DEPTH_FORMAT,
		dimension = ._2D,
		mipLevelCount = 1,
		sampleCount = 1,
		size = {
			width = self.gpu.config.width,
			height = self.gpu.config.height,
			depthOrArrayLayers = 1,
		},
	}

	self.depth_texture.texture = wgpu.DeviceCreateTexture(
		self.gpu.device,
		texture_descriptor,
	)

	texture_view_descriptor := wgpu.TextureViewDescriptor {
		format          = texture_descriptor.format,
		dimension       = ._2D,
		baseMipLevel    = 0,
		mipLevelCount   = 1,
		baseArrayLayer  = 0,
		arrayLayerCount = 1,
		aspect          = .All,
	}

	self.depth_texture.view = wgpu.TextureCreateView(
		self.depth_texture.texture,
		texture_view_descriptor,
	)

	sampler_descriptor := wgpu.SamplerDescriptor {
		addressModeU  = .ClampToEdge,
		addressModeV  = .ClampToEdge,
		addressModeW  = .ClampToEdge,
		magFilter     = .Linear,
		minFilter     = .Linear,
		mipmapFilter  = .Nearest,
		lodMinClamp   = 0.0,
		lodMaxClamp   = 100.0,
		compare       = .LessEqual,
		maxAnisotropy = 1,
	}

	self.depth_texture.sampler = wgpu.DeviceCreateSampler(
		self.gpu.device,
		sampler_descriptor,
	)

	self.rpass.descriptor.depthStencilAttachment = wgpu.RenderPassDepthStencilAttachment{
		view = self.depth_texture.view,
		depthOps = wgpu.RenderPassDepthOperations{
			load       = .Clear,
			store      = .Store,
			clearValue = 1.0,
		},
	}

	self.depth_texture.created = true
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
	frame_speed := self.speed * dt

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

    callbacks := app.Application_Callbacks{
        init  = app.App_Init_Callback(init),
        step  = app.App_Step_Callback(step),
        event = app.App_Event_Callback(event),
        quit  = app.App_Quit_Callback(quit),
    }

    app.init(Application, VIDEO_MODE_DEFAULT, EXAMPLE_TITLE, callbacks)
}
