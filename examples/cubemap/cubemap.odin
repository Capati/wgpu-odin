package cube_map

// Core
import "core:log"
import "core:math"
import la "core:math/linalg"

// Local packages
import wgpu "../.."
import app "../../utils/application"

CLIENT_WIDTH       :: 650
CLIENT_HEIGHT      :: 650
EXAMPLE_TITLE      :: "Cubemap"
VIDEO_MODE_DEFAULT :: app.Video_Mode {
	width  = CLIENT_WIDTH,
	height = CLIENT_HEIGHT,
}

Texture               :: app.Texture
Depth_Stencil_Texture :: app.Depth_Stencil_Texture

Application :: struct {
	using _app:         app.Application,

	// Buffers
	vertex_buffer:      wgpu.Buffer,
	index_buffer:       wgpu.Buffer,

	// Pipeline setup
	bind_group_layout:  wgpu.BindGroupLayout,
	render_pipeline:    wgpu.RenderPipeline,

	// Texture and related resources
	cubemap_texture:    Texture,
	depth_texture:      Depth_Stencil_Texture,

	// Uniform buffer and bind group
	uniform_buffer:     wgpu.Buffer,
	uniform_bind_group: wgpu.BindGroup,

	// Other state variables
	projection_matrix:  la.Matrix4f32,
	model_matrix:       la.Matrix4f32,
	rpass: struct {
		colors:     [1]wgpu.RenderPassColorAttachment,
		descriptor: wgpu.RenderPassDescriptor,
	},
}

create :: proc() -> (self: ^Application) {
	self = new(Application)
	assert(self != nil, "Failed to allocate Application")

	app.init(self, VIDEO_MODE_DEFAULT, EXAMPLE_TITLE)

	self.vertex_buffer = wgpu.DeviceCreateBufferWithData(
		self.gpu.device,
		{
			label = EXAMPLE_TITLE + " Vertex Data",
			contents = wgpu.ToBytes(CUBE_VERTEX_DATA),
			usage = {.Vertex},
		},
	)

	self.index_buffer = wgpu.DeviceCreateBufferWithData(
		self.gpu.device,
		{
			label = EXAMPLE_TITLE + " Index Buffer",
			contents = wgpu.ToBytes(CUBE_INDICES_DATA),
			usage = {.Index},
		},
	)

	CUBEMAP_WGSL :: #load("cubemap.wgsl")
	shader_module := wgpu.DeviceCreateShaderModule(
		self.gpu.device,
		{source = string(CUBEMAP_WGSL)},
	)
	defer wgpu.Release(shader_module)

	self.bind_group_layout = wgpu.DeviceCreateBindGroupLayout(
	self.gpu.device,
	wgpu.BindGroupLayoutDescriptor {
		label   = EXAMPLE_TITLE + " Bind group layout",
		entries = {
			{
				binding = 0,
				visibility = {.Vertex},
				type = wgpu.BufferBindingLayout {
					type             = .Uniform,
					minBindingSize = size_of(la.Matrix4f32), // 4x4 matrix,
				},
			},
			{
				binding = 1,
				visibility = {.Fragment},
				type = wgpu.SamplerBindingLayout{type = .Filtering},
			},
			{
				binding = 2,
				visibility = {.Fragment},
				type = wgpu.TextureBindingLayout{sampleType = .Float, viewDimension = .Cube},
			},
		},
	},
	)

	pipeline_layout := wgpu.DeviceCreatePipelineLayout(
		self.gpu.device,
		{
			label = EXAMPLE_TITLE + " Pipeline bind group layout",
			bindGroupLayouts = {self.bind_group_layout},
		},
	)
	defer wgpu.Release(pipeline_layout)

	attributes := wgpu.VertexAttrArray(2, {0, .Float32x4}, {1, .Float32x2})
	vertex_buffer_layout := wgpu.VertexBufferLayout {
		arrayStride = size_of(Vertex),
		stepMode    = .Vertex,
		attributes  = attributes[:],
	}

	self.render_pipeline = wgpu.DeviceCreateRenderPipeline(
		self.gpu.device,
		descriptor = wgpu.RenderPipelineDescriptor {
			layout = pipeline_layout,
			vertex = {
				module = shader_module,
				entryPoint = "vs_main",
				buffers = {vertex_buffer_layout},
			},
			fragment = &{
				module = shader_module,
				entryPoint = "fs_main",
				targets = {
					{
						format = self.gpu.config.format,
						blend = &wgpu.BLEND_STATE_NORMAL,
						writeMask = wgpu.COLOR_WRITES_ALL,
					},
				},
			},
			primitive = {
				topology   = .TriangleList,
				frontFace = .CCW,
				// Since we are seeing from inside of the cube
				// and we are using the regular cube geometry data with outward-facing normals,
				// the cullMode should be 'front' or 'none'.
				cullMode  = .Front,
			},
			// Enable depth testing so that the fragment closest to the camera
			// is rendered in front.
			depthStencil = app.gpu_create_depth_stencil_state(self),
			multisample = wgpu.MULTISAMPLE_STATE_DEFAULT,
		},
	)

	self.cubemap_texture = app.create_cubemap_texture_from_files(
		self,
		{
			"./assets/textures/cubemaps/bridge2_px.jpg",
			"./assets/textures/cubemaps/bridge2_nx.jpg",
			"./assets/textures/cubemaps/bridge2_py.jpg",
			"./assets/textures/cubemaps/bridge2_ny.jpg",
			"./assets/textures/cubemaps/bridge2_pz.jpg",
			"./assets/textures/cubemaps/bridge2_nz.jpg",
		},
	)

	self.uniform_buffer = wgpu.DeviceCreateBuffer(
		self.gpu.device,
		descriptor = wgpu.BufferDescriptor {
			label = EXAMPLE_TITLE + " Uniform Buffer",
			size  = size_of(la.Matrix4f32), // 4x4 matrix
			usage = {.Uniform, .CopyDst},
		},
	)

	self.uniform_bind_group = wgpu.DeviceCreateBindGroup(
		self.gpu.device,
		{
			layout = self.bind_group_layout,
			entries = {
				{
					binding = 0,
					resource = wgpu.BufferBinding {
						buffer = self.uniform_buffer,
						size = wgpu.BufferGetSize(self.uniform_buffer),
					},
				},
				{binding = 1, resource = self.cubemap_texture.sampler},
				{binding = 2, resource = self.cubemap_texture.view},
			},
		},
	)

	self.rpass.colors[0] = {
		view = nil, /* Assigned later */
		ops  = {.Clear, .Store, {0.0, 0.0, 0.0, 1.0}},
	}

	self.depth_texture = app.gpu_create_depth_stencil_texture(self.gpu)

	self.rpass.descriptor = {
		label                  = "Render pass descriptor",
		colorAttachments       = self.rpass.colors[:],
		depthStencilAttachment = self.depth_texture.descriptor,
	}

	self.model_matrix = la.matrix4_scale_f32({1000.0, 1000.0, 1000.0})
	set_projection_matrix(self, {self.gpu.config.width, self.gpu.config.height})

	app.add_resize_callback(self, { resize, self })

	return
}

release :: proc(self: ^Application) {
	app.gpu_release_depth_stencil_texture(self.depth_texture)

	// Release bind group and related resources
	wgpu.Release(self.uniform_bind_group)
	wgpu.BufferDestroy(self.uniform_buffer)
	wgpu.Release(self.uniform_buffer)

	// Release texture resources
	app.texture_release(self.cubemap_texture)

	// Release pipeline and related resources
	wgpu.Release(self.render_pipeline)
	wgpu.Release(self.bind_group_layout)

	// Release buffer resources
	wgpu.BufferDestroy(self.index_buffer)
	wgpu.Release(self.index_buffer)
	wgpu.BufferDestroy(self.vertex_buffer)
	wgpu.Release(self.vertex_buffer)

	app.release(self)
	free(self)
}

update :: proc(self: ^Application) {
	transformation_matrix := get_transformation_matrix(self)
	wgpu.QueueWriteBuffer(
		self.gpu.queue,
		self.uniform_buffer,
		0,
		wgpu.ToBytesContextless(transformation_matrix),
	)
}

draw :: proc(self: ^Application) {
	gpu := self.gpu

	frame := app.gpu_get_current_frame(gpu)
	if frame.skip { return }
	defer app.gpu_release_current_frame(&frame)

	encoder := wgpu.DeviceCreateCommandEncoder(self.gpu.device)
	defer wgpu.Release(encoder)

	self.rpass.colors[0].view = frame.view
	rpass := wgpu.CommandEncoderBeginRenderPass(encoder, self.rpass.descriptor)
	defer wgpu.Release(rpass)

	wgpu.RenderPassSetPipeline(rpass, self.render_pipeline)
	wgpu.RenderPassSetVertexBuffer(rpass, 0, {buffer = self.vertex_buffer})
	wgpu.RenderPassSetIndexBuffer(rpass, {buffer = self.index_buffer}, .Uint16)
	wgpu.RenderPassSetBindGroup(rpass, 0, self.uniform_bind_group)
	wgpu.RenderPassDrawIndexed(rpass, {0, u32(len(CUBE_INDICES_DATA))})

	wgpu.RenderPassEnd(rpass)

	cmdbuf := wgpu.CommandEncoderFinish(encoder)
	defer wgpu.Release(cmdbuf)

	wgpu.QueueSubmit(self.gpu.queue, { cmdbuf })
	wgpu.SurfacePresent(self.gpu.surface)
}

resize :: proc(window: ^app.Window, size: app.Vec2u, userdata: rawptr) {
	self := cast(^Application)userdata

	app.gpu_release_depth_stencil_texture(self.depth_texture)
	self.depth_texture = app.gpu_create_depth_stencil_texture(self.gpu)
	self.rpass.descriptor.depthStencilAttachment = self.depth_texture.descriptor

	set_projection_matrix(self, size)

	update(self)
	draw(self)
}

set_projection_matrix :: proc(self: ^Application, size: app.Vec2u) {
	aspect := f32(size.x) / f32(size.y)
	self.projection_matrix = la.matrix4_perspective((2 * math.PI) / 5, aspect, 1, 3000.0)
}

get_transformation_matrix :: proc(self: ^Application) -> (mvp_mat: la.Matrix4f32) {
	now := app.get_time(self) / 0.8

	rotation_x := la.quaternion_from_euler_angle_x_f32((math.PI / 10) * math.sin(now))
	rotation_y := la.quaternion_from_euler_angle_y_f32(now * 0.2)

	combined_rotation := la.quaternion_mul_quaternion(rotation_x, rotation_y)
	view_matrix := la.matrix4_from_quaternion_f32(combined_rotation)

	mvp_mat = la.matrix_mul(view_matrix, self.model_matrix)
	mvp_mat = la.matrix_mul(self.projection_matrix, mvp_mat)

	return
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

		update(example)
		draw(example)

		app.end_frame(example)
	}
}
