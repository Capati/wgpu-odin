package image_blur

// Core
import "core:log"
import "core:math"

// Vendor
import mu "vendor:microui"

// Local Packages
import wgpu "../.."
import wgpu_mu "../../utils/microui"
import app "../../utils/application"

CLIENT_WIDTH       :: 640
CLIENT_HEIGHT      :: 480
EXAMPLE_TITLE      :: "Image Blur"
VIDEO_MODE_DEFAULT :: app.Video_Mode {
	width  = CLIENT_WIDTH,
	height = CLIENT_HEIGHT,
}
SLIDER_FMT         :: "%.0f"

// Constants from the shader
TILE_DIM: i32 : 128
BATCH      :: 4

Settings :: struct {
	filter_size: i32,
	iterations:  i32,
}

Application :: struct {
	using _app:               app.Application, /* #subtype */
	mu_ctx:                   ^mu.Context,
	blur_pipeline:            wgpu.ComputePipeline,
	fullscreen_quad_pipeline: wgpu.RenderPipeline,
	image_texture:            app.Texture,
	textures: [2]struct {
		texture: wgpu.Texture,
		view:    wgpu.TextureView,
	},
	buffer_0:                 wgpu.Buffer,
	buffer_1:                 wgpu.Buffer,
	sampler:                  wgpu.Sampler,
	blur_params_buffer:       wgpu.Buffer,
	compute_constants:        wgpu.BindGroup,
	compute_bind_group_0:     wgpu.BindGroup,
	compute_bind_group_1:     wgpu.BindGroup,
	compute_bind_group_2:     wgpu.BindGroup,
	show_result_bind_group:   wgpu.BindGroup,
	block_dim:                i32,
	blur_settings:            Settings,
	rpass: struct {
		colors:     [1]wgpu.RenderPassColorAttachment,
		descriptor: wgpu.RenderPassDescriptor,
	},
}

create :: proc() -> (self: ^Application) {
	self = new(Application)
	assert(self != nil, "Failed to allocate Application")

	app.init(self, VIDEO_MODE_DEFAULT, EXAMPLE_TITLE)

	mu_init_info := wgpu_mu.MICROUI_INIT_INFO_DEFAULT
	mu_init_info.surface_config = self.gpu.config

	self.mu_ctx = new(mu.Context)

	mu.init(self.mu_ctx)
	self.mu_ctx.text_width = mu.default_atlas_text_width
	self.mu_ctx.text_height = mu.default_atlas_text_height

	// Initialize MicroUI context with default settings
	wgpu_mu.init(mu_init_info)

	// Initialize example objects
	BLUR_SOURCE :: #load("./blur.wgsl", string)
	blur_shader := wgpu.DeviceCreateShaderModule(
		self.gpu.device,
		{source = BLUR_SOURCE},
	)
	defer wgpu.Release(blur_shader)
	self.blur_pipeline = wgpu.DeviceCreateComputePipeline(
		self.gpu.device,
		{module = blur_shader, entryPoint = "main"},
	)

	FULLSCREEN_TEXTURED_QUAD_WGSL :: #load("./fullscreen_textured_quad.wgsl", string)
	quad_shader_module := wgpu.DeviceCreateShaderModule(
		self.gpu.device,
		{source = FULLSCREEN_TEXTURED_QUAD_WGSL},
	)
	defer wgpu.Release(quad_shader_module)

	self.fullscreen_quad_pipeline = wgpu.DeviceCreateRenderPipeline(
		self.gpu.device,
		{
			vertex = {module = quad_shader_module, entryPoint = "vert_main"},
			fragment = &{
				module = quad_shader_module,
				entryPoint = "frag_main",
				targets = {
					{
						format = self.gpu.config.format,
						blend = nil,
						writeMask = wgpu.COLOR_WRITES_ALL,
					},
				},
			},
			primitive = {topology = .TriangleList, frontFace = .CCW, cullMode = .None},
			multisample = wgpu.MULTISAMPLE_STATE_DEFAULT,
		},
	)

	self.image_texture = app.create_texture_from_file(self, "./assets/textures/nature.jpg")

	image_texture_descriptor := wgpu.TextureGetDescriptor(self.image_texture.texture)
	for &t in self.textures {
		t.texture = wgpu.DeviceCreateTexture(
			self.gpu.device,
			{
				usage         = {.CopyDst, .StorageBinding, .TextureBinding},
				dimension     = image_texture_descriptor.dimension,
				size          = image_texture_descriptor.size,
				format        = image_texture_descriptor.format,
				mipLevelCount = image_texture_descriptor.mipLevelCount,
				sampleCount   = image_texture_descriptor.sampleCount,
			},
		)
		t.view = wgpu.TextureCreateView(t.texture)
	}

	self.buffer_0 = wgpu.DeviceCreateBufferWithData(
		self.gpu.device,
		{contents = wgpu.ToBytes([1]u32{0}), usage = {.Uniform}},
	)

	self.buffer_1 = wgpu.DeviceCreateBufferWithData(
		self.gpu.device,
		{contents = wgpu.ToBytes([1]u32{1}), usage = {.Uniform}},
	)

	self.blur_params_buffer = wgpu.DeviceCreateBuffer(
		self.gpu.device,
		{size = size_of(Settings), usage = {.CopyDst, .Uniform}},
	)

	blur_pipeline_layout_0 := wgpu.ComputePipelineGetBindGroupLayout(
		self.blur_pipeline,
		0,
	)
	defer wgpu.Release(blur_pipeline_layout_0)

	sampler_descriptor := wgpu.SAMPLER_DESCRIPTOR_DEFAULT
	sampler_descriptor.magFilter = .Linear
	sampler_descriptor.minFilter = .Linear
	self.sampler = wgpu.DeviceCreateSampler(self.gpu.device, sampler_descriptor)

	self.compute_constants = wgpu.DeviceCreateBindGroup(
		self.gpu.device,
		{
			layout = blur_pipeline_layout_0,
			entries = {
				{binding = 0, resource = self.sampler},
				{
					binding = 1,
					resource = wgpu.BufferBinding {
						buffer = self.blur_params_buffer,
						size = wgpu.BufferGetSize(self.blur_params_buffer),
					},
				},
			},
		},
	)

	blur_pipeline_layout_1 := wgpu.ComputePipelineGetBindGroupLayout(
		self.blur_pipeline,
		1,
	)
	defer wgpu.Release(blur_pipeline_layout_1)

	self.compute_bind_group_0 = wgpu.DeviceCreateBindGroup(
		self.gpu.device,
		{
			layout = blur_pipeline_layout_1,
			entries = {
				{binding = 1, resource = self.image_texture.view},
				{binding = 2, resource = self.textures[0].view},
				{
					binding = 3,
					resource = wgpu.BufferBinding {
						buffer = self.buffer_0,
						size = wgpu.BufferGetSize(self.buffer_0),
					},
				},
			},
		},
	)

	self.compute_bind_group_1 = wgpu.DeviceCreateBindGroup(
		self.gpu.device,
		{
			layout = blur_pipeline_layout_1,
			entries = {
				{binding = 1, resource = self.textures[0].view},
				{binding = 2, resource = self.textures[1].view},
				{
					binding = 3,
					resource = wgpu.BufferBinding {
						buffer = self.buffer_1,
						size = wgpu.BufferGetSize(self.buffer_1),
					},
				},
			},
		},
	)

	self.compute_bind_group_2 = wgpu.DeviceCreateBindGroup(
		self.gpu.device,
		{
			layout = blur_pipeline_layout_1,
			entries = {
				{binding = 1, resource = self.textures[1].view},
				{binding = 2, resource = self.textures[0].view},
				{
					binding = 3,
					resource = wgpu.BufferBinding {
						buffer = self.buffer_0,
						size = wgpu.BufferGetSize(self.buffer_0),
					},
				},
			},
		},
	)

	fullscreen_quad_pipeline_layout := wgpu.RenderPipelineGetBindGroupLayout(
		self.fullscreen_quad_pipeline,
		0,
	)
	defer wgpu.Release(fullscreen_quad_pipeline_layout)

	self.show_result_bind_group = wgpu.DeviceCreateBindGroup(
		self.gpu.device,
		{
			layout = fullscreen_quad_pipeline_layout,
			entries = {
				{binding = 0, resource = self.sampler},
				{binding = 1, resource = self.textures[1].view},
			},
		},
	)

	self.rpass.colors[0] = {
		view = nil, /* Assigned later */
		ops  = {.Clear, .Store, app.Color_Black},
	}

	self.rpass.descriptor = {
		label            = "Render pass descriptor",
		colorAttachments = self.rpass.colors[:],
	}

	self.blur_settings = {
		filter_size = 15,
		iterations  = 2,
	}

	update_settings(self)

	app.add_resize_callback(self, { resize, self })

	return
}

release :: proc(self: ^Application) {
	wgpu.Release(self.show_result_bind_group)
	wgpu.Release(self.compute_bind_group_2)
	wgpu.Release(self.compute_bind_group_1)
	wgpu.Release(self.compute_bind_group_0)

	for &t in self.textures {
		wgpu.Release(t.texture)
		wgpu.Release(t.view)
	}

	wgpu.Release(self.buffer_0)
	wgpu.Release(self.buffer_1)
	wgpu.Release(self.sampler)
	wgpu.Release(self.blur_params_buffer)
	wgpu.Release(self.compute_constants)

	app.texture_release(self.image_texture)

	wgpu.Release(self.fullscreen_quad_pipeline)
	wgpu.Release(self.blur_pipeline)

	wgpu_mu.destroy()
	free(self.mu_ctx)

	app.release(self)
	free(self)
}

compute :: proc(self: ^Application, encoder: wgpu.CommandEncoder) {
	compute_pass := wgpu.CommandEncoderBeginComputePass(encoder)
	defer wgpu.Release(compute_pass)

	wgpu.ComputePassSetPipeline(compute_pass, self.blur_pipeline)
	wgpu.ComputePassSetBindGroup(compute_pass, 0, self.compute_constants)

	image_size := wgpu.TextureGetSize(self.image_texture.texture)

	wgpu.ComputePassSetBindGroup(compute_pass, 1, self.compute_bind_group_0)
	wgpu.ComputePassDispatchWorkgroups(
		compute_pass,
		u32(math.ceil(f32(image_size.width) / f32(self.block_dim))),
		u32(math.ceil(f32(image_size.height) / BATCH)),
		1,
	)

	wgpu.ComputePassSetBindGroup(compute_pass, 1, self.compute_bind_group_1)
	wgpu.ComputePassDispatchWorkgroups(
		compute_pass,
		u32(math.ceil(f32(image_size.height) / f32(self.block_dim))),
		u32(math.ceil(f32(image_size.width) / BATCH)),
		1,
	)

	for _ in 0 ..< self.blur_settings.iterations - 1 {
		wgpu.ComputePassSetBindGroup(compute_pass, 1, self.compute_bind_group_2)
		wgpu.ComputePassDispatchWorkgroups(
			compute_pass,
			u32(math.ceil(f32(image_size.width) / f32(self.block_dim))),
			u32(math.ceil(f32(image_size.height) / BATCH)),
			1,
		)

		wgpu.ComputePassSetBindGroup(compute_pass, 1, self.compute_bind_group_1)
		wgpu.ComputePassDispatchWorkgroups(
			compute_pass,
			u32(math.ceil(f32(image_size.height) / f32(self.block_dim))),
			u32(math.ceil(f32(image_size.width) / BATCH)),
			1,
		)
	}

	wgpu.ComputePassEnd(compute_pass)
}

draw :: proc(self: ^Application) {
	frame := app.gpu_get_current_frame(self.gpu)
	if frame.skip { return }
	defer app.gpu_release_current_frame(&frame)

	encoder := wgpu.DeviceCreateCommandEncoder(self.gpu.device)
	defer wgpu.Release(encoder)

	compute(self, encoder)

	self.rpass.colors[0].view = frame.view
	rpass := wgpu.CommandEncoderBeginRenderPass(encoder, self.rpass.descriptor)
	defer wgpu.Release(rpass)

	wgpu.RenderPassSetPipeline(rpass, self.fullscreen_quad_pipeline)
	wgpu.RenderPassSetBindGroup(rpass, 0, self.show_result_bind_group)
	wgpu.RenderPassDraw(rpass, {0, 6})

	wgpu_mu.render(self.mu_ctx, rpass)  // MicroUI rendering

	wgpu.RenderPassEnd(rpass)

	cmdbuf := wgpu.CommandEncoderFinish(encoder)
	defer wgpu.Release(cmdbuf)

	wgpu.QueueSubmit(self.gpu.queue, { cmdbuf })
	wgpu.SurfacePresent(self.gpu.surface)
}

resize :: proc(window: ^app.Window, size: app.Vec2u, userdata: rawptr) {
	self := cast(^Application)userdata
	wgpu_mu.resize(size.x, size.y)
	draw(self)
}

update_settings :: proc(self: ^Application) -> bool {
	self.block_dim = TILE_DIM - (self.blur_settings.filter_size - 1)
	wgpu.QueueWriteBuffer(
		self.gpu.queue,
		self.blur_params_buffer,
		0,
		wgpu.ToBytes([2]i32{self.blur_settings.filter_size, self.block_dim}),
	)

	return true
}

microui_update :: proc(self: ^Application) {
	mu.begin(self.mu_ctx)
	if mu.begin_window(self.mu_ctx, "Settings", {10, 10, 245, 78}, {.NO_RESIZE, .NO_CLOSE}) {
		mu.layout_row(self.mu_ctx, {-1}, 40)
		mu.layout_begin_column(self.mu_ctx)
		{
			mu.layout_row(self.mu_ctx, {60, -1}, 0)
			mu.label(self.mu_ctx, "Filter size:")
			if .CHANGE in
			   app.mu_slider(self.mu_ctx, &self.blur_settings.filter_size, 2, 34, 2, SLIDER_FMT) {
				update_settings(self)
			}
			mu.label(self.mu_ctx, "Iterations:")
			if .CHANGE in
			   app.mu_slider(self.mu_ctx, &self.blur_settings.iterations, 1, 20, 1, SLIDER_FMT) {
				update_settings(self)
			}
		}
		mu.layout_end_column(self.mu_ctx)

		mu.end_window(self.mu_ctx)
	}
	mu.end(self.mu_ctx)
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
			app.mu_handle_events(example.mu_ctx, event)
			#partial switch &ev in event {
			case app.QuitEvent:
				log.info("Exiting...")
				running = false
			}
		}

		app.begin_frame(example)
		microui_update(example)
		draw(example)
		app.end_frame(example)
	}
}
