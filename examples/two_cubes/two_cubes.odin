package two_cubes

// Packages
import "core:log"
import "core:math"
import la "core:math/linalg"

// Local packages
import wgpu "../.."
import app "../../utils/application"
import cube "../rotating_cube"

CLIENT_WIDTH       :: 640
CLIENT_HEIGHT      :: 480
EXAMPLE_TITLE      :: "Two Cubes"
VIDEO_MODE_DEFAULT :: app.Video_Mode {
	width  = CLIENT_WIDTH,
	height = CLIENT_HEIGHT,
}
CUBE_VERTEX_DATA   :: cube.CUBE_VERTEX_DATA
CUBE_INDICES_DATA  :: cube.CUBE_INDICES_DATA
Vertex             :: cube.Vertex

Application :: struct {
	using _app:          app.Application, /* #subtype */
	vertex_buffer:       wgpu.Buffer,
	index_buffer:        wgpu.Buffer,
	render_pipeline:     wgpu.RenderPipeline,
	uniform_buffer:      wgpu.Buffer,
	uniform_bind_group1: wgpu.BindGroup,
	uniform_bind_group2: wgpu.BindGroup,
	offset:              u64,
	projection_matrix:   la.Matrix4f32,
	depth_texture:       app.Depth_Stencil_Texture,
	rpass:         struct {
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

	vertex_buffer_layout := wgpu.VertexBufferLayout {
		arrayStride = size_of(Vertex),
		stepMode    = .Vertex,
		attributes   = {
			{format = .Float32x4, offset = 0, shaderLocation = 0},
			{format = .Float32x4, offset = u64(offset_of(Vertex, color)), shaderLocation = 1},
			{
				format = .Float32x2,
				offset = u64(offset_of(Vertex, tex_coords)),
				shaderLocation = 2,
			},
		},
	}

	ROTATING_CUBE_WGSL :: #load("./../rotating_cube/rotating_cube.wgsl", string)
	shader_module := wgpu.DeviceCreateShaderModule(
		self.gpu.device,
		{source = ROTATING_CUBE_WGSL},
	)
	defer wgpu.Release(shader_module)

	self.render_pipeline = wgpu.DeviceCreateRenderPipeline(
		self.gpu.device,
		{
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
				// Backface culling since the cube is solid piece of geometry.
				// Faces pointing away from the camera will be occluded by faces
				// pointing toward the camera.
				cullMode  = .Back,
			},
			// Enable depth testing so that the fragment closest to the camera
			// is rendered in front.
			depthStencil = app.gpu_create_depth_stencil_state(self),
			multisample = wgpu.MULTISAMPLE_STATE_DEFAULT,
		},
	)

	matrix_size: u64 = 4 * 16 // 4x4 matrix
	self.offset = 256
	uniform_buffer_size := self.offset + matrix_size

	self.uniform_buffer = wgpu.DeviceCreateBuffer(
		self.gpu.device,
		{
			label = EXAMPLE_TITLE + " Uniform Buffer",
			size = uniform_buffer_size,
			usage = {.Uniform, .CopyDst},
		},
	)

	bind_group_layout := wgpu.RenderPipelineGetBindGroupLayout(
		self.render_pipeline,
		0,
	)
	defer wgpu.Release(bind_group_layout)

	self.uniform_bind_group1 = wgpu.DeviceCreateBindGroup(
		self.gpu.device,
		{
			layout = bind_group_layout,
			entries = {
				{
					binding = 0,
					resource = wgpu.BufferBinding {
						buffer = self.uniform_buffer,
						size = wgpu.WHOLE_SIZE,
					},
				},
			},
		},
	)

	self.uniform_bind_group2 = wgpu.DeviceCreateBindGroup(
		self.gpu.device,
		{
			layout = bind_group_layout,
			entries = {
				{
					binding = 0,
					resource = wgpu.BufferBinding {
						buffer = self.uniform_buffer,
						offset = self.offset,
						size = wgpu.WHOLE_SIZE,
					},
				},
			},
		},
	)

	self.rpass.colors[0] = {
		view = nil, /* Assigned later */
		ops  = {.Clear, .Store, app.Color_Dark_Gray},
	}

	self.rpass.descriptor = {
		label                  = "Render pass descriptor",
		colorAttachments       = self.rpass.colors[:],
		depthStencilAttachment = nil, /* Assigned later */
	}

	create_depth_stencil_texture(self)

	set_projection_matrix(self, {self.gpu.config.width, self.gpu.config.height})

	app.add_resize_callback(self, { resize, self })

	return
}

release :: proc(self: ^Application) {
	app.gpu_release_depth_stencil_texture(self.depth_texture)

	wgpu.Release(self.uniform_bind_group2)
	wgpu.Release(self.uniform_bind_group1)
	wgpu.Release(self.uniform_buffer)
	wgpu.Release(self.render_pipeline)
	wgpu.Release(self.index_buffer)
	wgpu.Release(self.vertex_buffer)

	app.release(self)
	free(self)
}

update :: proc(self: ^Application) {
	now := f32(app.get_time(self))

	translation1 := la.Vector3f32{2, 0, -5}
	rotation_axis1 := la.Vector3f32{math.sin(now), math.cos(now), 0}
	transformation_matrix1 := get_transformation_matrix(self, translation1, rotation_axis1)
	wgpu.QueueWriteBuffer(
		self.gpu.queue,
		self.uniform_buffer,
		0,
		wgpu.ToBytes(transformation_matrix1),
	)

	translation2 := la.Vector3f32{-2, 0, -5}
	rotation_axis2 := la.Vector3f32{math.cos(now), math.sin(now), 0}
	transformation_matrix2 := get_transformation_matrix(self, translation2, rotation_axis2)
	wgpu.QueueWriteBuffer(
		self.gpu.queue,
		self.uniform_buffer,
		self.offset,
		wgpu.ToBytes(transformation_matrix2),
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
	wgpu.RenderPassSetVertexBuffer(rpass, 0, {buffer = self.vertex_buffer})
	wgpu.RenderPassSetIndexBuffer(rpass, {buffer = self.index_buffer}, .Uint16)

	// Bind the bind group (with the transformation matrix) for each cube, and draw.
	wgpu.RenderPassSetBindGroup(rpass, 0, self.uniform_bind_group1)
	wgpu.RenderPassDrawIndexed(rpass, {0, u32(len(CUBE_INDICES_DATA))})

	wgpu.RenderPassSetBindGroup(rpass, 0, self.uniform_bind_group2)
	wgpu.RenderPassDrawIndexed(rpass, {0, u32(len(CUBE_INDICES_DATA))})

	wgpu.RenderPassEnd(rpass)

	cmdbuf := wgpu.CommandEncoderFinish(encoder)
	defer wgpu.Release(cmdbuf)

	wgpu.QueueSubmit(self.gpu.queue, { cmdbuf })
	wgpu.SurfacePresent(self.gpu.surface)
}

resize :: proc(window: ^app.Window, size: app.Vec2u, userdata: rawptr) {
	self := cast(^Application)userdata
	recreate_depth_stencil_texture(self)
	set_projection_matrix(self, {size.x, size.y})
}


create_depth_stencil_texture :: proc(self: ^Application) {
	self.depth_texture = app.gpu_create_depth_stencil_texture(self.gpu)
	self.rpass.descriptor.depthStencilAttachment = self.depth_texture.descriptor
}

recreate_depth_stencil_texture :: proc(self: ^Application) {
	app.gpu_release_depth_stencil_texture(self.depth_texture)
	create_depth_stencil_texture(self)
}

set_projection_matrix :: proc(self: ^Application, size: app.Vec2u) {
	aspect := f32(size.x) / f32(size.y)
	self.projection_matrix = la.matrix4_perspective(2 * math.PI / 5, aspect, 1, 100.0)
}

get_transformation_matrix :: proc(
	self: ^Application,
	translation, rotation_axis: la.Vector3f32,
) -> (
	mvp_mat: la.Matrix4f32,
) {
	view_matrix := la.MATRIX4F32_IDENTITY

	// Translate
	view_matrix = la.matrix_mul(view_matrix, la.matrix4_translate(translation))

	// Rotate
	rotation_matrix := la.matrix4_rotate(1, rotation_axis)
	view_matrix = la.matrix_mul(view_matrix, rotation_matrix)

	// Multiply projection and view matrices
	mvp_mat = la.matrix_mul(self.projection_matrix, view_matrix)

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
