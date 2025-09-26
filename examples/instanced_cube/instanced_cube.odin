package instanced_cube

// Core
import "core:log"
import "core:math"
import la "core:math/linalg"

// Local packages
import wgpu "../.."
import app "../../utils/application"
import cube "../../examples/rotating_cube"

CLIENT_WIDTH       :: 640
CLIENT_HEIGHT      :: 480
EXAMPLE_TITLE       :: "Instanced Cube"
VIDEO_MODE_DEFAULT :: app.Video_Mode {
	width  = CLIENT_WIDTH,
	height = CLIENT_HEIGHT,
}

CUBE_VERTEX_DATA  :: cube.CUBE_VERTEX_DATA
CUBE_INDICES_DATA :: cube.CUBE_INDICES_DATA
Vertex            :: cube.Vertex

X_COUNT             :: 4
Y_COUNT             :: 4
MAX_INSTANCES       :: X_COUNT * Y_COUNT
MATRIX_FLOAT_COUNT  :: 16
MATRIX_SIZE         :: 4 * MATRIX_FLOAT_COUNT
UNIFORM_BUFFER_SIZE :: MAX_INSTANCES * MATRIX_SIZE

Application :: struct {
	using _app:        app.Application, /* #subtype */
	vertex_buffer:     wgpu.Buffer,
	index_buffer:      wgpu.Buffer,
	render_pipeline:   wgpu.RenderPipeline,
	instance_buffer:   wgpu.Buffer,
	projection_matrix: la.Matrix4f32,
	model_matrices:    [MAX_INSTANCES]la.Matrix4f32, // Store original model matrices
	instances:         [MAX_INSTANCES]la.Matrix4f32, // Store MVP matrices
	depth_texture:     app.Depth_Stencil_Texture,
	rpass:       struct {
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

	instance_buffer_layout := wgpu.VertexBufferLayout {
		arrayStride = size_of(la.Matrix4f32),
		stepMode    = .Instance,
		attributes   = {
			// mat4x4 takes up 4 vertex shader input locations
			{format = .Float32x4, offset = 0, shaderLocation = 5}, // 1st column
			{format = .Float32x4, offset = 16, shaderLocation = 6}, // 2nd column
			{format = .Float32x4, offset = 32, shaderLocation = 7}, // 3rd column
			{format = .Float32x4, offset = 48, shaderLocation = 8}, // 4th column
		},
	}

	INSTANCED_WGSL :: #load("instanced.wgsl", string)
	shader_module := wgpu.DeviceCreateShaderModule(
		self.gpu.device,
		{source = INSTANCED_WGSL},
	)
	defer wgpu.Release(shader_module)

	self.render_pipeline = wgpu.DeviceCreateRenderPipeline(
		self.gpu.device,
		{
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

	// Allocate a buffer large enough to hold transforms for every instance.
	self.instance_buffer = wgpu.DeviceCreateBuffer(
		self.gpu.device,
		{
			label = EXAMPLE_TITLE + " Instance Buffer",
			size = UNIFORM_BUFFER_SIZE,
			usage = {.Vertex, .CopyDst},
		},
	)

	STEP :: 4.0
	for x in 0 ..< X_COUNT {
		for y in 0 ..< Y_COUNT {
			i := x * Y_COUNT + y
			position := la.Vector3f32 {
				STEP * (f32(x) - f32(X_COUNT) / 2 + 0.5),
				STEP * (f32(y) - f32(Y_COUNT) / 2 + 0.5),
				0,
			}
			self.model_matrices[i] = la.matrix4_translate(position)
		}
	}

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

	return true
}

update :: proc(self: ^Application) {
	update_transformation_matrices(self)
	wgpu.QueueWriteBuffer(
		self.gpu.queue,
		self.instance_buffer,
		0,
		wgpu.ToBytes(self.instances),
	)
}

step :: proc(self: ^Application, dt: f32) -> (ok: bool) {
	update(self)

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
	wgpu.RenderPassSetVertexBuffer(rpass, 1, {buffer = self.instance_buffer})
	wgpu.RenderPassSetIndexBuffer(rpass, {buffer = self.index_buffer}, .Uint16)
	wgpu.RenderPassDrawIndexed(
		rpass,
		indices = {start = 0, end = u32(len(CUBE_INDICES_DATA))},
		instances = {start = 0, end = u32(len(self.instances))},
	)

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

	wgpu.Release(self.instance_buffer)
	wgpu.Release(self.render_pipeline)
	wgpu.Release(self.index_buffer)
	wgpu.Release(self.vertex_buffer)
}

resize :: proc(self: ^Application, size: app.Vec2u) {
	recreate_depth_stencil_texture(self)
	set_projection_matrix(self, size)
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

update_transformation_matrices :: proc(self: ^Application) {
	view_matrix := la.matrix4_translate(la.Vector3f32{0, 0, -12})
	now := app.get_time(self)

	for x in 0 ..< X_COUNT {
		for y in 0 ..< Y_COUNT {
			i := x * Y_COUNT + y

			// Create rotation axis for this instance
			rotation_axis := la.Vector3f32 {
				math.sin((f32(x) + 0.5) * now),
				math.cos((f32(y) + 0.5) * now),
				0,
			}

			// Start with original model matrix
			rotation_matrix := la.matrix4_rotate(1, rotation_axis)
			tmp_mat := la.matrix_mul(self.model_matrices[i], rotation_matrix)

			// Apply view and projection transformations
			tmp_mat = la.matrix_mul(view_matrix, tmp_mat)
			tmp_mat = la.matrix_mul(self.projection_matrix, tmp_mat)

			// Store MVP matrix
			self.instances[i] = tmp_mat
		}
	}
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
