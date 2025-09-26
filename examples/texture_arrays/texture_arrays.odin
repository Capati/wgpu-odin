#+build !js
package texture_arrays

// Core
import "core:log"

// Local packages
import wgpu "../.."
import app "../../utils/application"

CLIENT_WIDTH       :: 640
CLIENT_HEIGHT      :: 480
EXAMPLE_TITLE      :: "Texture Arrays"
VIDEO_MODE_DEFAULT :: app.Video_Mode {
	width  = CLIENT_WIDTH,
	height = CLIENT_HEIGHT,
}

Texture_Data :: struct {
	label: string,
	tex:   wgpu.Texture,
	view:  wgpu.TextureView,
	data:  [4]u8,
}

Texture_Name :: enum {
	RED,
	GREEN,
	BLUE,
	WHITE,
}

Vertex :: struct {
	pos:       [2]f32,
	tex_coord: [2]f32,
	index:     u32,
}

VERTICES: []Vertex : {
	// left rectangle
	{ {-1, -1}, {0, 1}, 0 },
	{ {-1,  1}, {0, 0}, 0 },
	{ {0 ,  1}, {1, 0}, 0 },
	{ {0 , -1}, {1, 1}, 0 },

	// right rectangle
	{ {0, -1}, {0, 1}, 1 },
	{ {0,  1}, {0, 0}, 1 },
	{ {1,  1}, {1, 0}, 1 },
	{ {1, -1}, {1, 1}, 1 },
}

INDICES: []u16 = {
	// Left rectangle
	0, 1, 2, // First triangle
	2, 0, 3, // Second triangle

	// Right rectangle
	4, 5, 6, // First triangle
	6, 4, 7, // Second triangle
}

OPTIONAL_FEATURES :: wgpu.Features{ .SampledTextureAndStorageBufferArrayNonUniformIndexing }
REQUIRED_FEATURES :: wgpu.Features{ .TextureBindingArray }

Application :: struct {
	using _app:                   app.Application,
	device_has_optional_features: bool,
	use_uniform_workaround:       bool,
	fragment_entry_point:         string,
	vertex_buffer:                wgpu.Buffer,
	index_buffer:                 wgpu.Buffer,
	texture_index_buffer:         wgpu.Buffer,
	textures:                     [Texture_Name]Texture_Data,
	sampler:                      wgpu.Sampler,
	bind_group:                   wgpu.BindGroup,
	render_pipeline:              wgpu.RenderPipeline,
	rpass: struct {
		colors:     [1]wgpu.RenderPassColorAttachment,
		descriptor: wgpu.RenderPassDescriptor,
	},
}

init :: proc(self: ^Application) -> (ok: bool) {
	self.device_has_optional_features = wgpu.DeviceHasFeature(self.gpu.device, OPTIONAL_FEATURES)

	if self.device_has_optional_features {
		self.fragment_entry_point = "non_uniform_main"
	} else {
		self.use_uniform_workaround = true
		self.fragment_entry_point = "uniform_main"
	}

	INDEXING_WGSL :: #load("./indexing.wgsl", string)
	base_shader_module := wgpu.DeviceCreateShaderModule(
		self.gpu.device,
		{source = INDEXING_WGSL},
	)
	defer wgpu.Release(base_shader_module)

	fragment_shader_module: wgpu.ShaderModule
	if !self.use_uniform_workaround {
		NON_UNIFORM_INDEXING_WGSL: string : #load("./non_uniform_indexing.wgsl", string)
		fragment_shader_module = wgpu.DeviceCreateShaderModule(
			self.gpu.device,
			{source = string(NON_UNIFORM_INDEXING_WGSL)},
		)
	} else {
		fragment_shader_module = base_shader_module
	}
	defer if !self.use_uniform_workaround {
		wgpu.Release(fragment_shader_module)
	}

	log.infof("Using fragment entry point: %s", self.fragment_entry_point)

	self.vertex_buffer = wgpu.DeviceCreateBufferWithData(
		self.gpu.device,
		{
			label = EXAMPLE_TITLE + " Vertex buffer",
			contents = wgpu.ToBytes(VERTICES),
			usage = {.Vertex},
		},
	)

	self.index_buffer = wgpu.DeviceCreateBufferWithData(
		self.gpu.device,
		{
			label = EXAMPLE_TITLE + " Index buffer",
			contents = wgpu.ToBytes(INDICES),
			usage = {.Index},
		},
	)

	texture_index_buffer_contents: [128]u32 = {}
	texture_index_buffer_contents[64] = 1

	self.texture_index_buffer = wgpu.DeviceCreateBufferWithData(
		self.gpu.device,
		{
			label = EXAMPLE_TITLE + "Texture index buffer",
			contents = wgpu.ToBytes(texture_index_buffer_contents),
			usage = {.Uniform},
		},
	)

	extent_3d_default: wgpu.Extent3D = {1, 1, 1}

	texture_descriptor_common: wgpu.TextureDescriptor = {
		usage         = {.TextureBinding, .CopyDst},
		dimension     = ._2D,
		size          = extent_3d_default,
		format        = self.gpu.config.format,
		mipLevelCount = 1,
		sampleCount   = 1,
	}

	texture_data_layout_common: wgpu.TexelCopyBufferLayout = {
		offset       = 0,
		bytesPerRow  = 4,
		rowsPerImage = wgpu.COPY_STRIDE_UNDEFINED,
	}

	self.textures[.RED].label = "red"
	self.textures[.GREEN].label = "green"
	self.textures[.BLUE].label = "blue"
	self.textures[.WHITE].label = "white"

	self.textures[.RED].data = {255, 0, 0, 255}
	self.textures[.GREEN].data = {0, 255, 0, 255}
	self.textures[.BLUE].data = {0, 0, 255, 255}
	self.textures[.WHITE].data = {255, 255, 255, 255}

	for i in 0 ..< len(self.textures) {
		ref := &self.textures[cast(Texture_Name)i]

		texture_descriptor_common.label = ref.label

		ref.tex = wgpu.DeviceCreateTexture(self.gpu.device, texture_descriptor_common)

		ref.view = wgpu.TextureCreateView(ref.tex)

		wgpu.QueueWriteTexture(
			self.gpu.queue,
			wgpu.TextureAsImageCopy(ref.tex),
			wgpu.ToBytes(wgpu.ToBytes(ref.data)),
			texture_data_layout_common,
			extent_3d_default,
		)
	}

	bind_group_layout := wgpu.DeviceCreateBindGroupLayout(
		self.gpu.device,
		wgpu.BindGroupLayoutDescriptor {
			label = EXAMPLE_TITLE + " Bind group layout",
			entries = {
				{
					binding = 0,
					visibility = {.Fragment},
					type = wgpu.TextureBindingLayout {
						multisampled = false,
						viewDimension = ._2D,
						sampleType = .Float,
					},
					count = 2,
				},
				{
					binding = 1,
					visibility = {.Fragment},
					type = wgpu.TextureBindingLayout {
						multisampled = false,
						viewDimension = ._2D,
						sampleType = .Float,
					},
					count = 2,
				},
				{
					binding = 2,
					visibility = {.Fragment},
					type = wgpu.SamplerBindingLayout{type = .Filtering},
					count = 2,
				},
				{
					binding = 3,
					visibility = {.Fragment},
					type = wgpu.BufferBindingLayout {
						type = .Uniform,
						hasDynamicOffset = true,
						minBindingSize = 4,
					},
				},
			},
		},
	)
	defer wgpu.Release(bind_group_layout)

	self.sampler = wgpu.DeviceCreateSampler(self.gpu.device)

	self.bind_group = wgpu.DeviceCreateBindGroup(
		self.gpu.device,
		{
			label = EXAMPLE_TITLE + " Bind Group",
			layout = bind_group_layout,
			entries = {
				{
					binding = 0,
					resource = []wgpu.TextureView {
						self.textures[.RED].view,
						self.textures[.GREEN].view,
					},
				},
				{
					binding = 1,
					resource = []wgpu.TextureView {
						self.textures[.BLUE].view,
						self.textures[.WHITE].view,
					},
				},
				{binding = 2, resource = []wgpu.Sampler{self.sampler, self.sampler}},
				{
					binding = 3,
					resource = wgpu.BufferBinding {
						buffer = self.texture_index_buffer,
						offset = 0,
						size = 4,
					},
				},
			},
		},
	)

	pipeline_layout := wgpu.DeviceCreatePipelineLayout(
		self.gpu.device,
		{label = EXAMPLE_TITLE + " main", bindGroupLayouts = {bind_group_layout}},
	)
	defer wgpu.Release(pipeline_layout)

	self.render_pipeline = wgpu.DeviceCreateRenderPipeline(
		self.gpu.device,
		{
			layout = pipeline_layout,
			vertex = {
				module = base_shader_module,
				entryPoint = "vert_main",
				buffers = {
					{
						arrayStride = size_of(Vertex),
						stepMode = .Vertex,
						attributes = {
							{format = .Float32x2, offset = 0, shaderLocation = 0},
							{
								format = .Float32x2,
								offset = u64(offset_of(Vertex, tex_coord)),
								shaderLocation = 1,
							},
							{
								format = .Sint32,
								offset = u64(offset_of(Vertex, index)),
								shaderLocation = 2,
							},
						},
					},
				},
			},
			fragment = &{
				module = fragment_shader_module,
				entryPoint = self.fragment_entry_point,
				targets = {
					{
						format = self.gpu.config.format,
						writeMask = wgpu.COLOR_WRITES_ALL,
					},
				},
			},
			primitive = wgpu.PRIMITIVE_STATE_DEFAULT,
			multisample = wgpu.MULTISAMPLE_STATE_DEFAULT,
		},
	)

	self.rpass.colors[0] = {
		view = nil, /* Assigned later */
		ops  = {.Clear, .Store, app.Color_Black},
	}

	self.rpass.descriptor = {
		label             = "Render pass descriptor",
		colorAttachments = self.rpass.colors[:],
	}

	return true
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
	wgpu.RenderPassSetVertexBuffer(rpass, 0, {buffer = self.vertex_buffer})
	wgpu.RenderPassSetIndexBuffer(rpass, {buffer = self.index_buffer}, .Uint16)

	if self.use_uniform_workaround {
		// Draw left rectangle
		wgpu.RenderPassSetBindGroup(rpass, 0, self.bind_group, {0})
		wgpu.RenderPassDrawIndexed(rpass, {0, 6})
		// Draw right rectangle
		wgpu.RenderPassSetBindGroup(rpass, 0, self.bind_group, {256})
		wgpu.RenderPassDrawIndexed(rpass, {6, 12})
	} else {
		wgpu.RenderPassSetBindGroup(rpass, 0, self.bind_group, {0})
		wgpu.RenderPassDrawIndexed(rpass, {0, 12})
	}

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
    }
    return true
}

quit :: proc(self: ^Application) {
	wgpu.Release(self.render_pipeline)
	wgpu.Release(self.bind_group)
	wgpu.Release(self.sampler)

	for i in 0 ..< len(self.textures) {
		ref := &self.textures[cast(Texture_Name)i]
		wgpu.Release(ref.view)
		wgpu.TextureDestroy(ref.tex)
		wgpu.Release(ref.tex)
	}

	wgpu.Release(self.texture_index_buffer)
	wgpu.Release(self.index_buffer)
	wgpu.Release(self.vertex_buffer)
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

    settings := app.SETTINGS_DEFAULT

    // Set optional features to decide for a workaround or feature based
	settings.optional_features = OPTIONAL_FEATURES
	// Set required features to use texture arrays
	settings.required_features = REQUIRED_FEATURES

    app.init(Application, VIDEO_MODE_DEFAULT, EXAMPLE_TITLE, callbacks, settings)
}
