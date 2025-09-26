package rotating_cube_textured

// Core
import "core:log"
import "core:math"
import la "core:math/linalg"

// Local packages
import wgpu "../.."
import app "../../utils/application"

CLIENT_WIDTH         :: 800
CLIENT_HEIGHT        :: 600
EXAMPLE_TITLE        :: "Rotating Cube Textured"
VIDEO_MODE_DEFAULT   :: app.Video_Mode {
	width  = CLIENT_WIDTH,
	height = CLIENT_HEIGHT,
}
DEFAULT_DEPTH_FORMAT :: app.DEFAULT_DEPTH_FORMAT

Texture :: app.Texture
Depth_Stencil_Texture :: app.Depth_Stencil_Texture

Application :: struct {
	using _app:         app.Application,
	vertex_buffer:      wgpu.Buffer,
	index_buffer:       wgpu.Buffer,
	render_pipeline:    wgpu.RenderPipeline,
	depth_stencil_view: wgpu.TextureView,
	uniform_buffer:     wgpu.Buffer,
	cube_texture:       Texture,
	uniform_bind_group: wgpu.BindGroup,
	depth_texture:      Depth_Stencil_Texture,
	projection_matrix:  la.Matrix4f32,
	rpass: struct {
		colors:     [1]wgpu.RenderPassColorAttachment,
		descriptor: wgpu.RenderPassDescriptor,
	},
}

init :: proc(self: ^Application) -> (ok: bool) {
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

	attributes := wgpu.VertexAttrArray(2, {0, .Float32x4}, {1, .Float32x2})

	vertex_buffer_layout := wgpu.VertexBufferLayout {
		arrayStride = size_of(Vertex),
		stepMode    = .Vertex,
		attributes  = attributes[:],
		// attributes   = {
		// 	{format = .Float32x4, offset = 0, shader_location = 0},
		// 	{
		// 		format = .Float32x2,
		// 		offset = u64(offset_of(Vertex, tex_coords)),
		// 		shader_location = 1,
		// 	},
		// },
	}

	ROTATING_CUBE_TEXTURED_WGSL :: #load("textured_cube.wgsl", string)
	shader_module := wgpu.DeviceCreateShaderModule(
		self.gpu.device,
		{source = ROTATING_CUBE_TEXTURED_WGSL},
	)
	defer wgpu.Release(shader_module)

	self.render_pipeline = wgpu.DeviceCreateRenderPipeline(
		self.gpu.device,
		descriptor = wgpu.RenderPipelineDescriptor {
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
			depthStencil = {
				depthWriteEnabled = true,
				depthCompare = .Less,
				format = DEFAULT_DEPTH_FORMAT,
				stencil = {
					front = {compare = .Always},
					back = {compare = .Always},
					readMask = 0xFFFFFFFF,
					writeMask = 0xFFFFFFFF,
				},
			},
			multisample = wgpu.MULTISAMPLE_STATE_DEFAULT,
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

	self.cube_texture = app.create_texture_from_file(self, "./assets/textures/Di-3d.png")

	bind_group_layout := wgpu.RenderPipelineGetBindGroupLayout(
		self.render_pipeline,
		groupIndex = 0,
	)
	defer wgpu.Release(bind_group_layout)

	self.uniform_bind_group = wgpu.DeviceCreateBindGroup(
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
				{binding = 1, resource = self.cube_texture.sampler},
				{binding = 2, resource = self.cube_texture.view},
			},
		},
	)

	self.rpass.colors[0] = {
		view = nil, /* Assigned later */
		ops  = {.Clear, .Store, app.Color_Dark_Gray},
	}

	self.depth_texture = app.gpu_create_depth_stencil_texture(self.gpu)

	self.rpass.descriptor  = {
		label                  = "Render pass descriptor",
		colorAttachments       = self.rpass.colors[:],
		depthStencilAttachment = self.depth_texture.descriptor,
	}

	set_projection_matrix(self, self.gpu.config.width, self.gpu.config.height)

	return true
}

update :: proc(self: ^Application) {
	transformation_matrix := get_transformation_matrix(self)
	wgpu.QueueWriteBuffer(
		self.gpu.queue,
		self.uniform_buffer,
		0,
		wgpu.ToBytes(transformation_matrix),
	)
}

step :: proc(self: ^Application, dt: f32) -> (ok: bool) {
	frame := app.gpu_get_current_frame(self.gpu)
	if frame.skip { return }
	defer app.gpu_release_current_frame(&frame)

	encoder := wgpu.DeviceCreateCommandEncoder(self.gpu.device)
	defer wgpu.Release(encoder)

	self.rpass.colors[0].view = frame.view
	rpass := wgpu.CommandEncoderBeginRenderPass(encoder, self.rpass.descriptor)
	defer wgpu.Release(rpass)
	wgpu.RenderPassSetPipeline(rpass, self.render_pipeline)
	wgpu.RenderPassSetBindGroup(rpass, 0, self.uniform_bind_group)
	wgpu.RenderPassSetVertexBuffer(rpass, 0, {buffer = self.vertex_buffer})
	wgpu.RenderPassSetIndexBuffer(rpass, {buffer = self.index_buffer}, .Uint16)
	wgpu.RenderPassDrawIndexed(rpass, {0, u32(len(CUBE_INDICES_DATA))})

	wgpu.RenderPassEnd(rpass)

	cmdbuf := wgpu.CommandEncoderFinish(encoder)
	defer wgpu.Release(cmdbuf)

	wgpu.QueueSubmit(self.gpu.queue, { cmdbuf })
	wgpu.SurfacePresent(self.gpu.surface)

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
	app.gpu_release_depth_stencil_texture(self.depth_texture)
	app.texture_release(self.cube_texture)

	wgpu.Release(self.uniform_bind_group)
	wgpu.Release(self.uniform_buffer)
	wgpu.Release(self.render_pipeline)
	wgpu.Release(self.index_buffer)
	wgpu.Release(self.vertex_buffer)
}

resize :: proc(self: ^Application, size: app.Vec2u) {
	app.gpu_release_depth_stencil_texture(self.depth_texture)
	self.depth_texture = app.gpu_create_depth_stencil_texture(self.gpu)
	self.rpass.descriptor.depthStencilAttachment = self.depth_texture.descriptor

	set_projection_matrix(self, size.x, size.y)
}

set_projection_matrix :: proc(self: ^Application, w, h: u32) {
	aspect := f32(w) / f32(h)
	self.projection_matrix = la.matrix4_perspective(2 * math.PI / 5, aspect, 1, 100.0)
}

get_transformation_matrix :: proc(self: ^Application) -> (mvp_mat: la.Matrix4f32) {
	view_matrix := la.MATRIX4F32_IDENTITY

	// Translate
	translation := la.Vector3f32{0, 0, -4}
	view_matrix = la.matrix_mul(view_matrix, la.matrix4_translate(translation))

	// Rotate
	now := f32(app.timer_get_time(&self.timer))
	rotation_axis := la.Vector3f32{math.sin(now), math.cos(now), 0}
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

    callbacks := app.Application_Callbacks{
        init  = app.App_Init_Callback(init),
        step  = app.App_Step_Callback(step),
        event = app.App_Event_Callback(event),
        quit  = app.App_Quit_Callback(quit),
    }

    app.init(Application, VIDEO_MODE_DEFAULT, EXAMPLE_TITLE, callbacks)
}
