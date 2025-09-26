package cameras_example

// Core
import "core:log"
import "core:math"
import la "core:math/linalg"

// Vendor
import mu "vendor:microui"

// Local packages
import wgpu "../.."
import wgpu_mu "../../utils/microui"
import app "../../utils/application"
import cube "../../examples/textured_cube"

CLIENT_WIDTH       :: 800
CLIENT_HEIGHT      :: 600
EXAMPLE_TITLE      :: "Cameras"
VIDEO_MODE_DEFAULT :: app.Video_Mode {
	width  = CLIENT_WIDTH,
	height = CLIENT_HEIGHT,
}

Vertex :: cube.Vertex

Camera_Type :: enum {
	Arcball,
	WASD,
}

Texture :: app.Texture
Vec2f :: app.Vec2f
Combobox_Item :: app.Combobox_Item
Depth_Stencil_Texture :: app.Depth_Stencil_Texture

Application :: struct {
	using _app:         app.Application, /* #subtype */
	vertex_buffer:      wgpu.Buffer,
	index_buffer:       wgpu.Buffer,
	render_pipeline:    wgpu.RenderPipeline,
	uniform_buffer:     wgpu.Buffer,
	cube_texture:       Texture,
	uniform_bind_group: wgpu.BindGroup,
	depth_texture:      Depth_Stencil_Texture,
	mu_ctx:             ^mu.Context,

	// Render pass
	rpass:        struct {
		colors:     [1]wgpu.RenderPassColorAttachment,
		descriptor: wgpu.RenderPassDescriptor,
	},

	// Cameras
	last_mouse_pos:    Vec2f,
	projection_matrix: la.Matrix4f32,
	cameras:            struct {
		input:   Input,
		arcball: Arcball_Camera,
		wasd:    WASD_Camera,
	},

	// UI settings
	current_type: Camera_Type,
	camera_types: [2]Combobox_Item(Camera_Type),
}

init :: proc(self: ^Application) -> (ok: bool) {
	mu_init_info := wgpu_mu.MICROUI_INIT_INFO_DEFAULT
	mu_init_info.surface_config = self.gpu.config
	// This example uses depth stencil, the microui renderer will use the same
	// default depth format
	mu_init_info.depth_stencil_format = app.DEFAULT_DEPTH_FORMAT

	self.mu_ctx = new(mu.Context)

	mu.init(self.mu_ctx)
	self.mu_ctx.text_width = mu.default_atlas_text_width
	self.mu_ctx.text_height = mu.default_atlas_text_height

	// Initialize MicroUI context with default settings
	wgpu_mu.init(mu_init_info)

	// Create cameras
	INITIAL_CAMERA_POSITION :: la.Vector3f32{3, 2, 5}
	self.cameras.arcball = arcball_camera_create(INITIAL_CAMERA_POSITION)
	self.cameras.wasd = wasd_camera_create(INITIAL_CAMERA_POSITION)

	self.current_type = .Arcball
	self.camera_types = {{.Arcball, "Arcball"}, {.WASD, "WASD"}}

	set_projection_matrix(self, self.gpu.config.width, self.gpu.config.height)

	self.vertex_buffer = wgpu.DeviceCreateBufferWithData(
		self.gpu.device,
		{
			label = EXAMPLE_TITLE + " Vertex Data",
			contents = wgpu.ToBytes(cube.CUBE_VERTEX_DATA),
			usage = {.Vertex},
		},
	)

	self.index_buffer = wgpu.DeviceCreateBufferWithData(
		self.gpu.device,
		{
			label = EXAMPLE_TITLE + " Index Buffer",
			contents = wgpu.ToBytes(cube.CUBE_INDICES_DATA),
			usage = {.Index},
		},
	)

	attributes := wgpu.VertexAttrArray(2, {0, .Float32x4}, {1, .Float32x2})
	vertex_buffer_layout := wgpu.VertexBufferLayout {
		arrayStride = size_of(Vertex),
		stepMode    = .Vertex,
		attributes  = attributes[:],
	}

	TEXTURED_CUBE_WGSL: string : #load("./cube.wgsl", string)
	shader_module := wgpu.DeviceCreateShaderModule(
		self.gpu.device,
		{label = EXAMPLE_TITLE + " Module", source = string(TEXTURED_CUBE_WGSL)},
	)
	defer wgpu.ShaderModuleRelease(shader_module)

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
			primitive = {topology = .TriangleList, frontFace = .CCW, cullMode = .Back},
			depthStencil = app.gpu_create_depth_stencil_state(self),
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
		ops = {load = .Clear, store = .Store, clearValue = app.Color_Dim_Gray},
	}

	self.depth_texture = app.gpu_create_depth_stencil_texture(self.gpu)

	self.rpass.descriptor = {
		label                  = "Render pass descriptor",
		colorAttachments       = self.rpass.colors[:],
		depthStencilAttachment = self.depth_texture.descriptor,
	}

	return true
}

update :: proc(self: ^Application) {
	analog := &self.cameras.input.analog
	mouse_is_down := app.mouse_button_is_down(.Left)
	analog.touching = mouse_is_down
	analog.zoom = f32(app.mouse_get_scroll().y)
	if mouse_is_down {
		movement := app.mouse_get_movement()
		analog.x = f32(movement.x)
		analog.y = f32(movement.y)
	} else {
		analog.x = 0
		analog.y = 0
	}

	if self.current_type == .WASD {
		digital := &self.cameras.input.digital

		digital.left     = app.key_is_down(.A)
		digital.right    = app.key_is_down(.D)
		digital.forward  = app.key_is_down(.W)
		digital.backward = app.key_is_down(.S)
		digital.up       = app.key_is_down(.Up)
		digital.down     = app.key_is_down(.Down)
	}

	transformation_matrix := get_model_view_projection_matrix(self, app.get_delta_time(self))
	wgpu.QueueWriteBuffer(
		self.gpu.queue,
		self.uniform_buffer,
		0,
		wgpu.ToBytes(transformation_matrix),
	)
}

step :: proc(self: ^Application, dt: f32) -> (ok: bool) {
	microui_update(self)
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
	wgpu.RenderPassSetBindGroup(rpass, 0, self.uniform_bind_group)
	wgpu.RenderPassSetVertexBuffer(rpass, 0, {buffer = self.vertex_buffer})
	wgpu.RenderPassSetIndexBuffer(rpass, {buffer = self.index_buffer}, .Uint16)
	wgpu.RenderPassDrawIndexed(rpass, {0, u32(len(cube.CUBE_INDICES_DATA))})

	// Render MicroUI elements
	wgpu_mu.render(self.mu_ctx, rpass)

	wgpu.RenderPassEnd(rpass)

	cmdbuf := wgpu.CommandEncoderFinish(encoder)
	defer wgpu.Release(cmdbuf)

	wgpu.QueueSubmit(self.gpu.queue, { cmdbuf })
	wgpu.SurfacePresent(self.gpu.surface)

	return true
}

event :: proc(self: ^Application, event: app.Event) -> (ok: bool) {
	app.mu_handle_events(self.mu_ctx, event)
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

	wgpu.Release(self.uniform_bind_group)
	app.texture_release(self.cube_texture)
	wgpu.Release(self.uniform_buffer)
	wgpu.Release(self.render_pipeline)
	wgpu.Release(self.index_buffer)
	wgpu.Release(self.vertex_buffer)

	wgpu_mu.destroy()
	free(self.mu_ctx)
}

resize :: proc(self: ^Application, size: app.Vec2u) {
	app.gpu_release_depth_stencil_texture(self.depth_texture)
	self.depth_texture = app.gpu_create_depth_stencil_texture(self.gpu)
	self.rpass.descriptor.depthStencilAttachment = self.depth_texture.descriptor

	set_projection_matrix(self, size.x, size.y)

	wgpu_mu.resize(size.x, size.y)
}

microui_update :: proc(self: ^Application) {
	mu.begin(self.mu_ctx)
	if mu.begin_window(self.mu_ctx, "Settings", {10, 10, 200, 54}, {.NO_CLOSE, .NO_RESIZE}) {
		defer mu.end_window(self.mu_ctx)
		mu.layout_row(self.mu_ctx, {80, -1})
		mu.label(self.mu_ctx, "Type:")
		if .CHANGE in app.mu_combobox(
				self.mu_ctx, "##camera_type", &self.current_type, self.camera_types[:]) {
			log.info(self.current_type)
		}
	}
	mu.end(self.mu_ctx)
}

set_projection_matrix :: proc(self: ^Application, w, h: u32) {
	aspect := f32(w) / f32(h)
	self.projection_matrix = la.matrix4_perspective((2 * math.PI) / 5, aspect, 1, 100.0)
}

get_model_view_projection_matrix :: proc(
	self: ^Application,
	dt: f32,
) -> (
	mvp: la.Matrix4f32,
) {
	view_matrix := la.MATRIX4F32_IDENTITY
	switch self.current_type {
	case .Arcball:
		view_matrix = arcball_camera_update(&self.cameras.arcball, dt, self.cameras.input)
	case .WASD:
		view_matrix = wasd_camera_update(&self.cameras.wasd, dt, self.cameras.input)
	}
	return app.OPEN_GL_TO_WGPU_MATRIX * self.projection_matrix * view_matrix
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
