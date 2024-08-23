package tutorial6_uniforms

// STD Library
import "base:builtin"
import "base:runtime"
import la "core:math/linalg"
@(require) import "core:log"

// Local Packages
import "../../../../utils/shaders"
import wgpu "../../../../wrapper"
import "../tutorial5_textures/texture"
import rl "./../../../../utils/renderlink"

Vertex :: struct {
	position   : [3]f32,
	tex_coords : [2]f32,
}

Camera :: struct {
	eye     : la.Vector3f32,
	target  : la.Vector3f32,
	up      : la.Vector3f32,
	aspect  : f32,
	fovYRad : f32,
	znear   : f32,
	zfar    : f32,
}

Camera_Uniform :: struct {
	view_proj: la.Matrix4f32,
}

Camera_Controller :: struct {
	speed               : f32,
	is_up_pressed       : bool,
	is_down_pressed     : bool,
	is_forward_pressed  : bool,
	is_backward_pressed : bool,
	is_left_pressed     : bool,
	is_right_pressed    : bool,
}

State :: struct {
	diffuse_bind_group : wgpu.Bind_Group,
	camera             : Camera,
	camera_controller  : Camera_Controller,
	camera_uniform     : Camera_Uniform,
	camera_buffer      : wgpu.Buffer,
	camera_bind_group  : wgpu.Bind_Group,
	render_pipeline    : wgpu.Render_Pipeline,
	num_indices        : u32,
	vertex_buffer      : wgpu.Buffer,
	index_buffer       : wgpu.Buffer,
}

State_Context :: rl.Context(State)

EXAMPLE_TITLE :: "Tutorial 6 - Uniforms"

init :: proc(ctx: ^State_Context) -> (ok: bool) {
	// Load our tree image to texture
	diffuse_texture := texture.texture_from_image(
		ctx.gpu.device,
		ctx.gpu.queue,
		"assets/learn_wgpu/tutorial5/happy-tree.png",
	) or_return
	defer texture.texture_destroy(diffuse_texture)

	texture_bind_group_layout := wgpu.device_create_bind_group_layout(
		ctx.gpu.device,
		wgpu.Bind_Group_Layout_Descriptor{
			label = "TextureBindGroupLayout",
			entries = {
				{
					binding = 0,
					visibility = {.Fragment},
					type = wgpu.Texture_Binding_Layout {
						multisampled = false,
						view_dimension = .D2,
						sample_type = .Float,
					},
				},
				{
					binding = 1,
					visibility = {.Fragment},
					type = wgpu.Sampler_Binding_Layout{type = .Filtering},
				},
			},
		},
	) or_return
	defer wgpu.bind_group_layout_release(texture_bind_group_layout)

	ctx.diffuse_bind_group = wgpu.device_create_bind_group(
		ctx.gpu.device,
		wgpu.Bind_Group_Descriptor {
			label = "diffuse_bind_group",
			layout = texture_bind_group_layout,
			entries = {
				{binding = 0, resource = diffuse_texture.view},
				{binding = 1, resource = diffuse_texture.sampler},
			},
		},
	) or_return
	defer if !ok do wgpu.bind_group_release(ctx.diffuse_bind_group)

	ctx.camera = {
		{0.0, 1.0, 2.0},
		{0.0, 0.0, 0.0},
		{0.0, 1.0, 0.0},
		cast(f32)ctx.gpu.config.width / cast(f32)ctx.gpu.config.height,
		// math.PI / 4,
		cast(f32)la.to_radians(45.0),
		0.1,
		100.0,
	}

	ctx.camera_controller = new_camera_controller(0.2)

	ctx.camera_uniform = new_camera_uniform()
	update_view_proj(&ctx.camera_uniform, &ctx.camera)

	ctx.camera_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		wgpu.Buffer_Data_Descriptor {
			label = "Camera Buffer",
			contents = wgpu.to_bytes(ctx.camera_uniform.view_proj),
			usage = {.Uniform, .Copy_Dst},
		},
	) or_return
	defer if !ok do wgpu.buffer_release(ctx.camera_buffer)

	camera_bind_group_layout := wgpu.device_create_bind_group_layout(
		ctx.gpu.device,
		wgpu.Bind_Group_Layout_Descriptor{
			label = "camera_bind_group_layout",
			entries = {
				{
					binding = 0,
					visibility = {.Vertex},
					type = wgpu.Buffer_Binding_Layout{type = .Uniform, has_dynamic_offset = false},
				},
			},
		},
	) or_return
	defer wgpu.bind_group_layout_release(camera_bind_group_layout)

	ctx.camera_bind_group = wgpu.device_create_bind_group(
		ctx.gpu.device,
		wgpu.Bind_Group_Descriptor {
			label = "camera_bind_group",
			layout = camera_bind_group_layout,
			entries = {
				{
					binding = 0,
					resource = wgpu.Buffer_Binding {
						buffer = ctx.camera_buffer,
						size = wgpu.WHOLE_SIZE,
					},
				},
			},
		},
	) or_return
	defer if !ok do wgpu.bind_group_release(ctx.camera_bind_group)

	render_pipeline_layout := wgpu.device_create_pipeline_layout(
		ctx.gpu.device,
		{
			label = "Render Pipeline Layout",
			bind_group_layouts = {texture_bind_group_layout, camera_bind_group_layout},
		},
	) or_return
	defer wgpu.pipeline_layout_release(render_pipeline_layout)

	vertex_buffer_layout := wgpu.Vertex_Buffer_Layout {
		array_stride = size_of(Vertex),
		step_mode    = .Vertex,
		attributes   = {
			{offset = 0, shader_location = 0, format = .Float32x3},
			{
				offset = cast(u64)offset_of(Vertex, tex_coords),
				shader_location = 1,
				format = .Float32x2,
			},
		},
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	CUBE_WGSL: string : #load("./shader.wgsl", string)
	shader_source := shaders.apply_color_conversion(
		CUBE_WGSL,
		ctx.gpu.is_srgb,
		context.temp_allocator,
	) or_return
	shader_module := wgpu.device_create_shader_module(
		ctx.gpu.device,
		{source = shader_source},
	) or_return
	defer wgpu.shader_module_release(shader_module)

	render_pipeline_descriptor := wgpu.Render_Pipeline_Descriptor {
		label = "Render Pipeline",
		layout = render_pipeline_layout,
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
					blend = &wgpu.Blend_State_Replace,
					write_mask = wgpu.Color_Write_Mask_All,
				},
			},
		},
		primitive = {topology = .Triangle_List, front_face = .CCW, cull_mode = .Back},
		depth_stencil = nil,
		multisample = {count = 1, mask = ~u32(0), alpha_to_coverage_enabled = false},
	}

	ctx.render_pipeline = wgpu.device_create_render_pipeline(
		ctx.gpu.device,
		render_pipeline_descriptor,
	) or_return
	defer if !ok do wgpu.render_pipeline_release(ctx.render_pipeline)

	vertices := []Vertex {
		{position = {-0.0868241, 0.49240386, 0.0}, tex_coords = {0.4131759, 0.00759614}}, // A
		{position = {-0.49513406, 0.06958647, 0.0}, tex_coords = {0.0048659444, 0.43041354}}, // B
		{position = {-0.21918549, -0.44939706, 0.0}, tex_coords = {0.28081453, 0.949397}}, // C
		{position = {0.35966998, -0.3473291, 0.0}, tex_coords = {0.85967, 0.84732914}}, // D
		{position = {0.44147372, 0.2347359, 0.0}, tex_coords = {0.9414737, 0.2652641}}, // E
	}

	indices: []u16 = {0, 1, 4, 1, 2, 4, 2, 3, 4}

	ctx.num_indices = cast(u32)len(indices)

	ctx.vertex_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		wgpu.Buffer_Data_Descriptor {
			label = "Vertex Buffer",
			contents = wgpu.to_bytes(vertices),
			usage = {.Vertex},
		},
	) or_return
	defer if !ok do wgpu.buffer_release(ctx.vertex_buffer)

	ctx.index_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		wgpu.Buffer_Data_Descriptor {
			label = "Index Buffer",
			contents = wgpu.to_bytes(indices),
			usage = {.Index},
		},
	) or_return

	rl.graphics_clear(rl.Color{0.1, 0.2, 0.3, 1.0})

	return true
}

quit :: proc(ctx: ^State_Context) {
	wgpu.buffer_release(ctx.index_buffer)
	wgpu.buffer_release(ctx.vertex_buffer)
	wgpu.render_pipeline_release(ctx.render_pipeline)
	wgpu.bind_group_release(ctx.camera_bind_group)
	wgpu.bind_group_release(ctx.diffuse_bind_group)
	wgpu.buffer_release(ctx.camera_buffer)
}

resize :: proc(event: rl.Resize_Event, ctx: ^State_Context) -> bool{
	ctx.camera.aspect = cast(f32)event.width / cast(f32)event.height
	update_view_proj(&ctx.camera_uniform, &ctx.camera)
	wgpu.queue_write_buffer(
		ctx.gpu.queue,
		ctx.camera_buffer,
		0,
		wgpu.to_bytes(ctx.camera_uniform.view_proj),
	) or_return

	return true
}

update :: proc(dt: f64, ctx: ^State_Context) -> bool{
	update_camera_controller(&ctx.camera_controller, &ctx.camera)
	update_view_proj(&ctx.camera_uniform, &ctx.camera)

	wgpu.queue_write_buffer(
		ctx.gpu.queue,
		ctx.camera_buffer,
		0,
		wgpu.to_bytes(ctx.camera_uniform.view_proj),
	)

	return true
}

draw :: proc(ctx: ^State_Context) -> bool{
	wgpu.render_pass_set_pipeline(ctx.gpu.render_pass, ctx.render_pipeline)
	wgpu.render_pass_set_bind_group(ctx.gpu.render_pass, 0, ctx.diffuse_bind_group)
	wgpu.render_pass_set_bind_group(ctx.gpu.render_pass, 1, ctx.camera_bind_group)
	wgpu.render_pass_set_vertex_buffer(ctx.gpu.render_pass, 0, ctx.vertex_buffer)
	wgpu.render_pass_set_index_buffer(ctx.gpu.render_pass, ctx.index_buffer, .Uint16)
	wgpu.render_pass_draw_indexed(ctx.gpu.render_pass, {0, ctx.num_indices})

	return true
}

handle_events :: proc(event: rl.Event, ctx: ^State_Context) {
	#partial switch ev in event {
	case rl.Key_Event:
		controller := &ctx.camera_controller
		pressed := ev.action == .Pressed
		#partial switch ev.key {
		case .Space:
			controller.is_up_pressed = true if pressed else false
		case .Left_Shift:
			controller.is_down_pressed = true if pressed else false
		case .W:
			controller.is_forward_pressed = true if pressed else false
		case .A:
			controller.is_left_pressed = true if pressed else false
		case .S:
			controller.is_backward_pressed = true if pressed else false
		case .D:
			controller.is_right_pressed = true if pressed else false
		}
	}

	return
}

main :: proc() {
	when ODIN_DEBUG {
		context.logger = log.create_console_logger(opt = {.Level, .Terminal_Color})
		defer log.destroy_console_logger(context.logger)
	}

	state := builtin.new(State_Context)
	assert(state != nil, "Failed to allocate application state")
	defer builtin.free(state)

	state.callbacks = {
		init          = init,
		quit          = quit,
		handle_events = handle_events,
		update        = update,
		draw          = draw,
	}

	settings := rl.DEFAULT_SETTINGS
	settings.window.title = EXAMPLE_TITLE

	if ok := rl.init(state, settings); !ok do return

	rl.begin_run(state) // Start the main loop
}

build_view_projection_matrix :: proc(camera: ^Camera) -> la.Matrix4f32 {
	projection := la.matrix4_perspective_f32(
		camera.fovYRad,
		camera.aspect,
		camera.znear,
		camera.zfar,
	)
	view := la.matrix4_look_at_f32(eye = camera.eye, centre = camera.target, up = camera.up)
	// return la.mul(projection, view)
	return rl.OPEN_GL_TO_WGPU_MATRIX * projection * view
}

new_camera_uniform :: proc() -> Camera_Uniform {
	return {la.MATRIX4F32_IDENTITY}
}

update_view_proj :: proc(self: ^Camera_Uniform, camera: ^Camera) {
	self.view_proj = build_view_projection_matrix(camera)
}

new_camera_controller :: proc(speed: f32) -> Camera_Controller {
	return {speed = speed}
}

update_camera_controller :: proc(using self: ^Camera_Controller, camera: ^Camera) {
	forward := camera.target - camera.eye
	forward_norm := la.normalize(forward)
	forward_mag := la.length(forward)

	// Prevents glitching when the camera gets too close to the center of the scene.
	if is_forward_pressed && forward_mag > speed {
		camera.eye += forward_norm * speed
	}

	if is_backward_pressed {
		camera.eye -= forward_norm * speed
	}

	right := la.cross(forward_norm, camera.up)

	// Redo radius calc in case the forward/backward is pressed.
	forward = camera.target - camera.eye
	forward_mag = la.length(forward)

	if is_right_pressed {
		camera.eye = camera.target - la.normalize(forward + right * speed) * forward_mag
	}

	if is_left_pressed {
		camera.eye = camera.target - la.normalize(forward - right * speed) * forward_mag
	}
}
