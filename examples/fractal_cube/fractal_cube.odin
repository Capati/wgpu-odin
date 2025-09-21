package fractal_cube

// Core
import "core:log"
import "core:math"
import la "core:math/linalg"

// Local packages
import wgpu "../.."
import app "../../utils/application"

CLIENT_WIDTH       :: 640
CLIENT_HEIGHT      :: 480
EXAMPLE_TITLE      :: "Fractal Cube"
VIDEO_MODE_DEFAULT :: app.Video_Mode {
	width  = CLIENT_WIDTH,
	height = CLIENT_HEIGHT,
}

Application :: struct {
	using _app:         app.Application, /* #subtype */
	vertex_buffer:      wgpu.Buffer,
	index_buffer:       wgpu.Buffer,
	render_pipeline:    wgpu.RenderPipeline,
	uniform_buffer:     wgpu.Buffer,
	uniform_bind_group: wgpu.BindGroup,
	projection_matrix:  la.Matrix4f32,
	// We will copy the frame's rendering results into this texture and
	// sample it on the next frame.
	cube_texture:       wgpu.Texture,
	cube_view:          wgpu.TextureView,
	sampler:            wgpu.Sampler,
	depth_texture:      app.Depth_Stencil_Texture,
	need_bind_group_update: bool,
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

	vertex_buffer_layout := wgpu.VertexBufferLayout {
		arrayStride = size_of(Vertex),
		stepMode    = .Vertex,
		attributes   = {
			{format = .Float32x4, offset = 0, shaderLocation = 0},
			{
				format = .Float32x2,
				offset = u64(offset_of(Vertex, tex_coords)),
				shaderLocation = 1,
			},
		},
	}

	ROTATING_CUBE_WGSL :: #load("./fractal_cube.wgsl", string)
	shader_module := wgpu.DeviceCreateShaderModule(
		self.gpu.device,
		{source = ROTATING_CUBE_WGSL},
	)
	defer wgpu.Release(shader_module)

	depth_stencil_state := app.gpu_create_depth_stencil_state(self)

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
		depthStencil = depth_stencil_state,
		multisample = wgpu.MULTISAMPLE_STATE_DEFAULT,
	},
	)

	self.uniform_buffer = wgpu.DeviceCreateBuffer(
		self.gpu.device,
		{
			label = EXAMPLE_TITLE + " Uniform Buffer",
			size  = 4 * 16, // 4x4 matrix
			usage = {.Uniform, .CopyDst},
		},
	)

	create_cube_texture(self)

	sampler_descriptor := wgpu.SAMPLER_DESCRIPTOR_DEFAULT
	sampler_descriptor.magFilter = .Linear
	sampler_descriptor.minFilter = .Linear
	self.sampler = wgpu.DeviceCreateSampler(self.gpu.device, sampler_descriptor)

	create_fractal_bind_group(self)

	self.rpass.colors[0] = {
		view = nil, /* Assigned later */
		ops = {
			load        = .Clear,
			store       = .Store,
			// The clear color serves as the initial background and seed for the
			// fractal generation. The mid-gray value (0.5, 0.5, 0.5) provides a
			// neutral starting point for the fractal algorithm. In the fractal
			// shader, values near 0.5 can significantly influence the initial
			// pattern generation. The specific threshold of 0.01 used in the
			// shader depends on this base gray color. Changing this value can
			// dramatically alter the initial fractal distribution and appearance.
			clearValue = {0.5, 0.5, 0.5, 1},
		},
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

	wgpu.Release(self.uniform_bind_group)
	wgpu.Release(self.sampler)

	destroy_cube_texture(self)

	wgpu.Release(self.uniform_buffer)
	wgpu.Release(self.render_pipeline)
	wgpu.Release(self.index_buffer)
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
	frame := app.gpu_get_current_frame(self.gpu)
	if frame.skip { return }
	defer app.gpu_release_current_frame(&frame)

	encoder := wgpu.DeviceCreateCommandEncoder(self.gpu.device)
	defer wgpu.Release(encoder)

	self.rpass.colors[0].view = frame.view
	rpass := wgpu.CommandEncoderBeginRenderPass(encoder, self.rpass.descriptor)
	defer wgpu.Release(rpass)

	if self.need_bind_group_update {
        recreate_fractal_bind_group(self)
        self.need_bind_group_update = false
    }

	wgpu.RenderPassSetPipeline(rpass, self.render_pipeline)
	wgpu.RenderPassSetBindGroup(rpass, 0, self.uniform_bind_group)
	wgpu.RenderPassSetVertexBuffer(rpass, 0, {buffer = self.vertex_buffer})
	wgpu.RenderPassSetIndexBuffer(rpass, {buffer = self.index_buffer}, .Uint16)
	wgpu.RenderPassDrawIndexed(rpass, {0, u32(len(CUBE_INDICES_DATA))})

	wgpu.RenderPassEnd(rpass)

	// Copy the rendering results from the swapchain into `cube_texture`.
	wgpu.CommandEncoderCopyTextureToTexture(
		encoder,
		{texture = frame.texture, mipLevel = 0, origin = {}, aspect = .All},
		{texture = self.cube_texture, mipLevel = 0, origin = {}, aspect = .All},
		{self.gpu.config.width, self.gpu.config.height, 1},
	)

	cmdbuf := wgpu.CommandEncoderFinish(encoder)
	defer wgpu.Release(cmdbuf)

	wgpu.QueueSubmit(self.gpu.queue, { cmdbuf })
	wgpu.SurfacePresent(self.gpu.surface)
}

resize :: proc(window: ^app.Window, size: app.Vec2u, userdata: rawptr) {
	self := cast(^Application)userdata

	recreate_cube_texture(self)
	recreate_depth_stencil_texture(self)

	set_projection_matrix(self, size)

    self.need_bind_group_update = true

	update(self)
	draw(self)
}

create_cube_texture :: proc(self: ^Application) {
	self.cube_texture = wgpu.DeviceCreateTexture(
		self.gpu.device,
		{
			usage = {.TextureBinding, .CopyDst, .RenderAttachment},
			format = self.gpu.config.format,
			dimension = ._2D,
			mipLevelCount = 1,
			sampleCount = 1,
			size = {
				width = self.gpu.config.width,
				height = self.gpu.config.height,
				depthOrArrayLayers = 1,
			},
		},
	)

	texture_view_descriptor := wgpu.TextureViewDescriptor {
		format            = self.gpu.config.format,
		dimension         = ._2D,
		baseMipLevel    = 0,
		mipLevelCount   = 1,
		baseArrayLayer  = 0,
		arrayLayerCount = 1,
		aspect            = .All,
	}

	self.cube_view = wgpu.TextureCreateView(self.cube_texture, texture_view_descriptor)
}

destroy_cube_texture :: proc(self: ^Application) {
	if self.cube_texture != nil {
		wgpu.Release(self.cube_texture)
	}
	if self.cube_view != nil {
		wgpu.Release(self.cube_view)
	}
}

recreate_cube_texture :: proc(self: ^Application) {
	destroy_cube_texture(self)
	create_cube_texture(self)
}

create_fractal_bind_group :: proc(self: ^Application) {
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
                {binding = 1, resource = self.sampler},
                {binding = 2, resource = self.cube_view},
            },
        },
    )
}

recreate_fractal_bind_group :: proc(self: ^Application) {
    if self.uniform_bind_group != nil {
        wgpu.Release(self.uniform_bind_group)
    }
    create_fractal_bind_group(self)
}

set_projection_matrix :: proc(self: ^Application, size: app.Vec2u) {
	aspect := f32(size.x) / f32(size.y)
	self.projection_matrix = la.matrix4_perspective(2 * math.PI / 5, aspect, 1, 100.0)
}

get_transformation_matrix :: proc(self: ^Application) -> (mvp_mat: la.Matrix4f32) {
	view_matrix := la.MATRIX4F32_IDENTITY

	// Translate
	translation := la.Vector3f32{0, 0, -4}
	view_matrix = la.matrix_mul(view_matrix, la.matrix4_translate(translation))

	// Rotate
	now := app.get_time(self)
	rotation_axis := la.Vector3f32{math.sin(now), math.cos(now), 0}
	rotation_matrix := la.matrix4_rotate(1, rotation_axis)
	view_matrix = la.matrix_mul(view_matrix, rotation_matrix)

	// Multiply projection and view matrices
	mvp_mat = la.matrix_mul(self.projection_matrix, view_matrix)

	return
}

create_depth_stencil_texture :: proc(self: ^Application) {
	self.depth_texture = app.gpu_create_depth_stencil_texture(self.gpu)
	self.rpass.descriptor.depthStencilAttachment = self.depth_texture.descriptor
}

recreate_depth_stencil_texture :: proc(self: ^Application) {
	app.gpu_release_depth_stencil_texture(self.depth_texture)
	create_depth_stencil_texture(self)
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
