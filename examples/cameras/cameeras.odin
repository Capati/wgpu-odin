package cameras_example

// Packages
// import "core:fmt"
import "core:log"
import "core:math"
import la "core:math/linalg"
import mu "vendor:microui"

// Local packages
import cube "root:examples/textured_cube"
import app "root:utils/application"
import "root:wgpu"

Vertex :: cube.Vertex

Camera_Type :: enum {
	Arcball,
	WASD,
}

Example :: struct {
	vertex_buffer:      wgpu.Buffer,
	index_buffer:       wgpu.Buffer,
	render_pipeline:    wgpu.Render_Pipeline,
	uniform_buffer:     wgpu.Buffer,
	cube_texture:       app.Texture,
	uniform_bind_group: wgpu.Bind_Group,

	// Render pass
	render_pass:        struct {
		color_attachments: [1]wgpu.Render_Pass_Color_Attachment,
		descriptor:        wgpu.Render_Pass_Descriptor,
	},

	// Cameras
	last_mouse_pos:     app.Mouse_Position,
	projection_matrix:  la.Matrix4f32,
	cameras:            struct {
		input:   Input,
		arcball: Arcball_Camera,
		wasd:    WASD_Camera,
	},

	// UI settings
	current_type:       Camera_Type,
	camera_types:       [2]app.Combobox_Item(Camera_Type),
}

Context :: app.Context(Example)

EXAMPLE_TITLE :: "Cameras"

init :: proc(ctx: ^Context) -> (ok: bool) {
	microui_init_info := app.DEFAULT_MICROUI_INIT_INFO
	// This example uses depth stencil created by the application framework
	// The microui renderer will use the same default depth format
	microui_init_info.depth_stencil_format = app.DEFAULT_DEPTH_FORMAT
	// Initialize MicroUI context with the given info
	app.microui_init(ctx, microui_init_info) or_return

	// Create cameras
	INITIAL_CAMERA_POSITION :: la.Vector3f32{3, 2, 5}
	ctx.cameras.arcball = arcball_camera_create(INITIAL_CAMERA_POSITION)
	ctx.cameras.wasd = wasd_camera_create(INITIAL_CAMERA_POSITION)

	ctx.current_type = .Arcball
	ctx.camera_types = {{.Arcball, "Arcball"}, {.WASD, "WASD"}}

	set_projection_matrix(ctx, ctx.gpu.config.width, ctx.gpu.config.height)

	ctx.vertex_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{
			label = EXAMPLE_TITLE + " Vertex Data",
			contents = wgpu.to_bytes(cube.CUBE_VERTEX_DATA),
			usage = {.Vertex},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.vertex_buffer)
	}

	ctx.index_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{
			label = EXAMPLE_TITLE + " Index Buffer",
			contents = wgpu.to_bytes(cube.CUBE_INDICES_DATA),
			usage = {.Index},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.index_buffer)
	}

	attributes := wgpu.vertex_attr_array(2, {0, .Float32x4}, {1, .Float32x2})
	vertex_buffer_layout := wgpu.Vertex_Buffer_Layout {
		array_stride = size_of(Vertex),
		step_mode    = .Vertex,
		attributes   = attributes[:],
	}

	TEXTURED_CUBE_WGSL: string : #load("./cube.wgsl", string)
	shader_module := wgpu.device_create_shader_module(
		ctx.gpu.device,
		{label = EXAMPLE_TITLE + " Module", source = string(TEXTURED_CUBE_WGSL)},
	) or_return
	defer wgpu.shader_module_release(shader_module)

	ctx.render_pipeline = wgpu.device_create_render_pipeline(
		ctx.gpu.device,
		descriptor = wgpu.Render_Pipeline_Descriptor {
			vertex = {
				module = shader_module,
				entry_point = "vs_main",
				buffers = {vertex_buffer_layout},
			},
			fragment = &{
				module = shader_module,
				entry_point = "fs_main",
				targets = {
					{
						format = ctx.gpu.config.format,
						blend = &wgpu.BLEND_STATE_NORMAL,
						write_mask = wgpu.COLOR_WRITES_ALL,
					},
				},
			},
			primitive = {topology = .Triangle_List, front_face = .CCW, cull_mode = .Back},
			depth_stencil = app.create_depth_stencil_state(ctx),
			multisample = wgpu.DEFAULT_MULTISAMPLE_STATE,
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.render_pipeline)
	}

	ctx.uniform_buffer = wgpu.device_create_buffer(
		ctx.gpu.device,
		descriptor = wgpu.Buffer_Descriptor {
			label = EXAMPLE_TITLE + " Uniform Buffer",
			size  = size_of(la.Matrix4f32), // 4x4 matrix
			usage = {.Uniform, .Copy_Dst},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.uniform_buffer)
	}

	ctx.cube_texture = app.create_texture_from_file(ctx, "./assets/textures/Di-3d.png") or_return
	defer if !ok {
		app.release(ctx.cube_texture)
	}

	bind_group_layout := wgpu.render_pipeline_get_bind_group_layout(
		ctx.render_pipeline,
		0,
	) or_return
	defer wgpu.release(bind_group_layout)

	ctx.uniform_bind_group = wgpu.device_create_bind_group(
		ctx.gpu.device,
		{
			layout = bind_group_layout,
			entries = {
				{
					binding = 0,
					resource = wgpu.Buffer_Binding {
						buffer = ctx.uniform_buffer,
						size = wgpu.WHOLE_SIZE,
					},
				},
				{binding = 1, resource = ctx.cube_texture.sampler},
				{binding = 2, resource = ctx.cube_texture.view},
			},
		},
	) or_return
	defer if !ok {
		wgpu.release(ctx.uniform_bind_group)
	}

	ctx.render_pass.color_attachments[0] = {
		view = nil, /* Assigned later */
		ops = {load = .Clear, store = .Store, clear_value = app.Color_Dim_Gray},
	}

	app.setup_depth_stencil(ctx) or_return

	ctx.render_pass.descriptor = {
		label                    = "Render pass descriptor",
		color_attachments        = ctx.render_pass.color_attachments[:],
		depth_stencil_attachment = &ctx.depth_stencil.descriptor,
	}

	return true
}

quit :: proc(ctx: ^Context) {
	wgpu.release(ctx.uniform_bind_group)
	app.texture_release(ctx.cube_texture)
	wgpu.release(ctx.uniform_buffer)
	wgpu.release(ctx.render_pipeline)
	wgpu.release(ctx.index_buffer)
	wgpu.release(ctx.vertex_buffer)
}

resize :: proc(ctx: ^Context, size: app.Resize_Event) -> (ok: bool) {
	set_projection_matrix(ctx, ctx.gpu.config.width, ctx.gpu.config.height)
	return true
}

microui_update :: proc(ctx: ^Context, mu_ctx: ^mu.Context) -> (ok: bool) {
	if mu.begin_window(mu_ctx, "Settings", {10, 10, 200, 54}, {.NO_CLOSE, .NO_RESIZE}) {
		defer mu.end_window(mu_ctx)
		mu.layout_row(mu_ctx, {80, -1})
		mu.label(mu_ctx, "Type:")
		if .CHANGE in
		   app.microui_combobox(mu_ctx, "##camera_type", &ctx.current_type, ctx.camera_types[:]) {
			log.info(ctx.current_type)
		}
	}

	return true
}

set_projection_matrix :: proc(ctx: ^Context, w, h: u32) {
	ctx.projection_matrix = la.matrix4_perspective((2 * math.PI) / 5, ctx.aspect, 1, 100.0)
}

get_model_view_projection_matrix :: proc(ctx: ^Context, dt: f64) -> (mvp: la.Matrix4f32) {
	view_matrix := la.MATRIX4F32_IDENTITY
	switch ctx.current_type {
	case .Arcball:
		view_matrix = arcball_camera_update(&ctx.cameras.arcball, f32(dt), ctx.cameras.input)
	case .WASD:
		view_matrix = wasd_camera_update(&ctx.cameras.wasd, f32(dt), ctx.cameras.input)
	}
	return app.OPEN_GL_TO_WGPU_MATRIX * ctx.projection_matrix * view_matrix
}

update :: proc(ctx: ^Context, dt: f64) -> bool {
	analog := &ctx.cameras.input.analog
	mouse_is_down := app.mouse_button_is_down(ctx, .Left)
	analog.touching = mouse_is_down
	analog.zoom = f32(app.mouse_get_scroll(ctx).y)
	if mouse_is_down {
		movement := app.mouse_get_movement(ctx)
		analog.x = f32(movement.x)
		analog.y = f32(movement.y)
	} else {
		analog.x = 0
		analog.y = 0
	}

	if ctx.current_type == .WASD {
		digital := &ctx.cameras.input.digital
		digital.left = app.key_is_down(ctx, .A)
		digital.right = app.key_is_down(ctx, .D)
		digital.forward = app.key_is_down(ctx, .W)
		digital.backward = app.key_is_down(ctx, .S)
		digital.up = app.key_is_down(ctx, .Up)
		digital.down = app.key_is_down(ctx, .Down)
	}

	transformation_matrix := get_model_view_projection_matrix(ctx, dt)
	wgpu.queue_write_buffer(
		ctx.gpu.queue,
		ctx.uniform_buffer,
		0,
		wgpu.to_bytes(transformation_matrix),
	) or_return

	return true
}

draw :: proc(ctx: ^Context) -> bool {
	ctx.cmd = wgpu.device_create_command_encoder(ctx.gpu.device) or_return
	defer wgpu.release(ctx.cmd)

	ctx.render_pass.color_attachments[0].view = ctx.frame.view
	render_pass := wgpu.command_encoder_begin_render_pass(ctx.cmd, ctx.render_pass.descriptor)
	defer wgpu.release(render_pass)

	wgpu.render_pass_set_pipeline(render_pass, ctx.render_pipeline)
	wgpu.render_pass_set_bind_group(render_pass, 0, ctx.uniform_bind_group)
	wgpu.render_pass_set_vertex_buffer(render_pass, 0, {buffer = ctx.vertex_buffer})
	wgpu.render_pass_set_index_buffer(render_pass, {buffer = ctx.index_buffer}, .Uint16)
	wgpu.render_pass_draw_indexed(render_pass, {0, u32(len(cube.CUBE_INDICES_DATA))})

	// Render MicroUI elements
	app.microui_draw(ctx, render_pass) or_return

	wgpu.render_pass_end(render_pass) or_return

	cmdbuf := wgpu.command_encoder_finish(ctx.cmd) or_return
	defer wgpu.release(cmdbuf)

	wgpu.queue_submit(ctx.gpu.queue, cmdbuf)
	wgpu.surface_present(ctx.gpu.surface) or_return

	return true
}

main :: proc() {
	when ODIN_DEBUG {
		context.logger = log.create_console_logger(opt = {.Level, .Terminal_Color})
		defer log.destroy_console_logger(context.logger)
	}

	settings := app.DEFAULT_SETTINGS
	settings.title = EXAMPLE_TITLE

	example, ok := app.create(Context, settings)
	if !ok {
		log.fatalf("Failed to create example [%s]", EXAMPLE_TITLE)
		return
	}
	defer app.destroy(example)

	example.callbacks = {
		init           = init,
		quit           = quit,
		microui_update = microui_update,
		resize         = resize,
		update         = update,
		draw           = draw,
	}

	app.run(example) // Start the main loop
}
