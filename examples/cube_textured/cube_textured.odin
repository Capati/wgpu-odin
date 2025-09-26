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
DEPTH_FORMAT       :: wgpu.TextureFormat.Depth24Plus

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

init :: proc(self: ^Application) -> (ok: bool) {
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
	defer wgpu.TextureRelease(texture)

	texture_view := wgpu.TextureCreateView(texture)
	defer wgpu.TextureViewRelease(texture_view)

	texels := create_texels()

	wgpu.QueueWriteTexture(
		self.gpu.queue,
		{texture = texture, mipLevel = 0, origin = {}, aspect = .All},
		wgpu.ToBytes(texels),
		{offset = 0, bytesPerRow = TEXEL_SIZE, rowsPerImage = TEXEL_SIZE},
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
	defer wgpu.ShaderModuleRelease(shader_module)

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
	defer wgpu.BindGroupLayoutRelease(bind_group_layout)

	self.bind_group = wgpu.DeviceCreateBindGroup(
		self.gpu.device,
		{
			layout = bind_group_layout,
			entries = {
				{
					binding = 0,
					resource = wgpu.BufferBinding {
						buffer = self.uniform_buffer,
						size = wgpu.BufferGetSize(self.uniform_buffer),
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

	return true
}

step :: proc(self: ^Application, dt: f32) -> (ok: bool) {
	frame := app.gpu_get_current_frame(self.gpu)
	if frame.skip { return }
	defer app.gpu_release_current_frame(&frame)

	encoder := wgpu.DeviceCreateCommandEncoder(self.gpu.device)
	defer wgpu.CommandEncoderRelease(encoder)

	self.rpass.colors[0].view = frame.view
	rpass := wgpu.CommandEncoderBeginRenderPass(encoder, self.rpass.descriptor)
	defer wgpu.RenderPassRelease(rpass)

	wgpu.RenderPassSetPipeline(rpass, self.render_pipeline)
	wgpu.RenderPassSetBindGroup(rpass, 0, self.bind_group)
	wgpu.RenderPassSetVertexBuffer(rpass, 0, {buffer = self.vertex_buffer})
	wgpu.RenderPassSetIndexBuffer(rpass, {buffer = self.index_buffer}, .Uint16)
	wgpu.RenderPassDrawIndexed(rpass, {0, u32(len(index_data))}, 0)

	wgpu.RenderPassEnd(rpass)

	cmdbuf := wgpu.CommandEncoderFinish(encoder)
	defer wgpu.CommandBufferRelease(cmdbuf)

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

	wgpu.BindGroupRelease(self.bind_group)
	wgpu.RenderPipelineRelease(self.render_pipeline)
	wgpu.BufferRelease(self.uniform_buffer)
	wgpu.BufferRelease(self.index_buffer)
	wgpu.BufferRelease(self.vertex_buffer)
}

resize :: proc(self: ^Application, size: app.Vec2u) {
	recreate_depth_stencil_texture(self)

	data := create_view_projection_matrix(f32(size.x) / f32(size.y))
	wgpu.QueueWriteBuffer(
		self.gpu.queue,
		self.uniform_buffer,
		0,
		wgpu.ToBytes(data),
	)
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

    callbacks := app.Application_Callbacks{
        init  = app.App_Init_Callback(init),
        step  = app.App_Step_Callback(step),
        event = app.App_Event_Callback(event),
        quit  = app.App_Quit_Callback(quit),
    }

    app.init(Application, VIDEO_MODE_DEFAULT, EXAMPLE_TITLE, callbacks)
}
