package cube_textured

// Core
import "core:log"
import "core:math"
import la "core:math/linalg"

// Local packages
import wgpu "../../"
import app "../../utils/application"

CLIENT_WIDTH       :: 640
CLIENT_HEIGHT      :: 480
EXAMPLE_TITLE      :: "Textured Cube"
VIDEO_MODE_DEFAULT :: app.Video_Mode {
	width  = CLIENT_WIDTH,
	height = CLIENT_HEIGHT,
}
TEXEL_SIZE         :: 256

Application :: struct {
	using _app:      app.Application, /* #subtype */
	vertex_buffer:   wgpu.Buffer,
	index_buffer:    wgpu.Buffer,
	uniform_buffer:  wgpu.Buffer,
	render_pipeline: wgpu.RenderPipeline,
	bind_group:      wgpu.BindGroup,
	depth_texture:   app.Depth_Stencil_Texture,
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
			label    = EXAMPLE_TITLE + " Vertex Buffer",
			contents = wgpu.ToBytes(vertex_data),
			usage    = {.Vertex},
		},
	)

	self.index_buffer = wgpu.DeviceCreateBufferWithData(
		self.gpu.device,
		{
			label    = EXAMPLE_TITLE + " Index Buffer",
			contents = wgpu.ToBytes(index_data),
			usage    = {.Index},
		},
	)

	texture_extent := wgpu.Extent3D {
		width              = TEXEL_SIZE,
		height             = TEXEL_SIZE,
		depthOrArrayLayers = 1,
	}

	texture := wgpu.DeviceCreateTexture(
		self.gpu.device,
		{
			size          = texture_extent,
			mipLevelCount = 1,
			sampleCount   = 1,
			dimension     = ._2D,
			format        = .R8Uint,
			usage         = {.TextureBinding, .CopyDst},
		},
	)
	defer wgpu.Release(texture)

	texture_view := wgpu.TextureCreateView(texture)
	defer wgpu.Release(texture_view)

	texels := create_texels()

	wgpu.QueueWriteTexture(
		self.gpu.queue,
		{texture = texture, mipLevel = 0, origin = {}, aspect = .All},
		wgpu.ToBytes(texels),
		{offset = 0, bytesPerRow = TEXEL_SIZE, rowsPerImage = wgpu.COPY_STRIDE_UNDEFINED},
		texture_extent,
	)

	mx_total := create_view_projection_matrix(
		cast(f32)self.gpu.config.width / cast(f32)self.gpu.config.height,
	)

	self.uniform_buffer = wgpu.DeviceCreateBufferWithData(
		self.gpu.device,
		{
			label = EXAMPLE_TITLE + " Uniform Buffer",
			contents = wgpu.ToBytes(mx_total),
			usage = {.Uniform, .CopyDst},
		},
	)

	CUBE_TEXTURED_WGSL :: #load("./cube_textured.wgsl")
	shader_module := wgpu.DeviceCreateShaderModule(
		self.gpu.device,
		{label = EXAMPLE_TITLE + " Module", source = string(CUBE_TEXTURED_WGSL)},
	)
	defer wgpu.Release(shader_module)

	vertex_buffer_layout := wgpu.VertexBufferLayout {
		arrayStride = size_of(Vertex),
		stepMode    = .Vertex,
		attributes   = {
			{format = .Float32x4, offset = 0, shaderLocation = 0},
			{
				format = .Float32x2,
				offset = cast(u64)offset_of(Vertex, tex_coords),
				shaderLocation = 1,
			},
		},
	}

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
						blend = &wgpu.BLEND_STATE_REPLACE,
						writeMask = wgpu.COLOR_WRITES_ALL,
					},
				},
			},
			depthStencil = app.gpu_create_depth_stencil_state(self),
			primitive = {topology = .TriangleList, frontFace = .CCW, cullMode = .Back},
			multisample = wgpu.MULTISAMPLE_STATE_DEFAULT,
		},
	)

	bind_group_layout := wgpu.RenderPipelineGetBindGroupLayout(
		self.render_pipeline,
		groupIndex = 0,
	)
	defer wgpu.Release(bind_group_layout)

	self.bind_group = wgpu.DeviceCreateBindGroup(
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
				{binding = 1, resource = texture_view},
			},
		},
	)

	self.rpass.colors[0] = {
		view = nil, /* Assigned later */
		ops  = {.Clear, .Store, {0.1, 0.2, 0.3, 1.0}},
	}

	self.rpass.descriptor = {
		label                  = "Render pass descriptor",
		colorAttachments       = self.rpass.colors[:],
		depthStencilAttachment = nil, /* Assigned later */
	}

	create_depth_stencil_texture(self)

	app.add_resize_callback(self, { resize, self })

	return
}

release :: proc(self: ^Application) {
	app.gpu_release_depth_stencil_texture(self.depth_texture)

	wgpu.Release(self.bind_group)
	wgpu.Release(self.render_pipeline)
	wgpu.Release(self.uniform_buffer)
	wgpu.Release(self.index_buffer)
	wgpu.Release(self.vertex_buffer)

	app.release(self)
	free(self)
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
	wgpu.RenderPassSetBindGroup(rpass, 0, self.bind_group)
	wgpu.RenderPassSetVertexBuffer(rpass, 0, {buffer = self.vertex_buffer})
	wgpu.RenderPassSetIndexBuffer(rpass, {buffer = self.index_buffer}, .Uint16)
	wgpu.RenderPassDrawIndexed(rpass, {0, u32(len(index_data))}, 0)

	wgpu.RenderPassEnd(rpass)

	cmdbuf := wgpu.CommandEncoderFinish(encoder)
	defer wgpu.Release(cmdbuf)

	wgpu.QueueSubmit(self.gpu.queue, { cmdbuf })
	wgpu.SurfacePresent(self.gpu.surface)
}

resize :: proc(window: ^app.Window, size: app.Vec2u, userdata: rawptr) {
	self := cast(^Application)userdata

	recreate_depth_stencil_texture(self)

	data := create_view_projection_matrix(f32(size.x) / f32(size.y))
	wgpu.QueueWriteBuffer(
		self.gpu.queue,
		self.uniform_buffer,
		0,
		wgpu.ToBytes(data),
	)

	draw(self)
}

create_depth_stencil_texture :: proc(self: ^Application) {
	self.depth_texture = app.gpu_create_depth_stencil_texture(self.gpu)
	self.rpass.descriptor.depthStencilAttachment = self.depth_texture.descriptor
}

recreate_depth_stencil_texture :: proc(self: ^Application) {
	app.gpu_release_depth_stencil_texture(self.depth_texture)
	create_depth_stencil_texture(self)
}

create_texels :: proc() -> (texels: [TEXEL_SIZE * TEXEL_SIZE]u8) {
	for id := 0; id < (TEXEL_SIZE * TEXEL_SIZE); id += 1 {
		cx := 3.0 * f32(id % TEXEL_SIZE) / f32(TEXEL_SIZE - 1) - 2.0
		cy := 2.0 * f32(id / TEXEL_SIZE) / f32(TEXEL_SIZE - 1) - 1.0
		x, y, count := f32(cx), f32(cy), u8(0)
		for count < 0xFF && x * x + y * y < 4.0 {
			old_x := x
			x = x * x - y * y + cx
			y = 2.0 * old_x * y + cy
			count += 1
		}
		texels[id] = count
	}

	return
}

create_view_projection_matrix :: proc(aspect: f32) -> la.Matrix4f32 {
	projection := la.matrix4_perspective_f32(math.PI / 4, aspect, 1.0, 10.0)
	view := la.matrix4_look_at_f32(
		eye = {1.5, -5.0, 3.0},
		centre = {0.0, 0.0, 0.0},
		up = {0.0, 0.0, 1.0},
	)
	return la.mul(projection, view)
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
		draw(example)
		app.end_frame(example)
	}
}

