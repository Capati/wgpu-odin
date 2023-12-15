package tutorial6_uniforms

// Core
import "core:fmt"
import "core:math"
import la "core:math/linalg"

// Package
import wgpu "../../../../wrapper"
import "../../../common"
import "../tutorial5_textures/texture"

Open_Gl_To_Wgpu_Matrix :: common.Open_Gl_To_Wgpu_Matrix

// Framework
import app "../../../framework/application"
import "../../../framework/application/events"
import "../../../framework/renderer"

Vertex :: struct {
	position:   [3]f32,
	tex_coords: [2]f32,
}

Camera :: struct {
	eye:     la.Vector3f32,
	target:  la.Vector3f32,
	up:      la.Vector3f32,
	aspect:  f32,
	fovYRad: f32,
	znear:   f32,
	zfar:    f32,
}

Camera_Uniform :: struct {
	view_proj: la.Matrix4f32,
}

Camera_Controller :: struct {
	speed:               f32,
	is_up_pressed:       bool,
	is_down_pressed:     bool,
	is_forward_pressed:  bool,
	is_backward_pressed: bool,
	is_left_pressed:     bool,
	is_right_pressed:    bool,
}

State :: struct {
	gpu:                ^renderer.Renderer,
	diffuse_bind_group: wgpu.Bind_Group,
	camera:             Camera,
	camera_controller:  Camera_Controller,
	camera_uniform:     Camera_Uniform,
	camera_buffer:      wgpu.Buffer,
	camera_bind_group:  wgpu.Bind_Group,
	render_pipeline:    wgpu.Render_Pipeline,
	num_indices:        u32,
	vertex_buffer:      wgpu.Buffer,
	index_buffer:       wgpu.Buffer,
}

Error :: union #shared_nil {
	app.Application_Error,
	renderer.Renderer_Error,
	wgpu.Error_Type,
}

init_example :: proc() -> (state: State, err: Error) {
	state.gpu = renderer.init() or_return
	defer if err != nil do renderer.deinit(state.gpu)

	// Load our tree image to texture
	diffuse_texture := texture.texture_from_image(
		&state.gpu.device,
		&state.gpu.queue,
		"assets/learn_wgpu/tutorial5/happy-tree.png",
	) or_return
	defer texture.texture_destroy(&diffuse_texture)

	texture_bind_group_layout := wgpu.device_create_bind_group_layout(
		&state.gpu.device,
		& {
			label = "TextureBindGroupLayout",
			entries =  {
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
	defer wgpu.bind_group_layout_release(&texture_bind_group_layout)

	state.diffuse_bind_group = wgpu.device_create_bind_group(
		&state.gpu.device,
		&wgpu.Bind_Group_Descriptor {
			label = "diffuse_bind_group",
			layout = &texture_bind_group_layout,
			entries =  {
				{binding = 0, resource = &diffuse_texture.view},
				{binding = 1, resource = &diffuse_texture.sampler},
			},
		},
	) or_return
	defer if err != nil do wgpu.bind_group_release(&state.diffuse_bind_group)

	state.camera = {
		{0.0, 1.0, 2.0},
		{0.0, 0.0, 0.0},
		{0.0, 1.0, 0.0},
		cast(f32)state.gpu.config.width / cast(f32)state.gpu.config.height,
		// math.PI / 4,
		cast(f32)la.to_radians(45.0),
		0.1,
		100.0,
	}

	state.camera_controller = new_camera_controller(0.2)

	state.camera_uniform = new_camera_uniform()
	update_view_proj(&state.camera_uniform, &state.camera)

	state.camera_buffer = wgpu.device_create_buffer_with_data(
		&state.gpu.device,
		&wgpu.Buffer_Data_Descriptor {
			label = "Camera Buffer",
			contents = wgpu.to_bytes(state.camera_uniform.view_proj),
			usage = {.Uniform, .Copy_Dst},
		},
	) or_return
	defer if err != nil do wgpu.buffer_release(&state.camera_buffer)

	camera_bind_group_layout := wgpu.device_create_bind_group_layout(
		&state.gpu.device,
		& {
			label = "camera_bind_group_layout",
			entries =  {
				 {
					binding = 0,
					visibility = {.Vertex},
					type = wgpu.Buffer_Binding_Layout{type = .Uniform, has_dynamic_offset = false},
				},
			},
		},
	) or_return
	defer wgpu.bind_group_layout_release(&camera_bind_group_layout)

	state.camera_bind_group = wgpu.device_create_bind_group(
		&state.gpu.device,
		&wgpu.Bind_Group_Descriptor {
			label = "camera_bind_group",
			layout = &camera_bind_group_layout,
			entries =  {
				 {
					binding = 0,
					resource = wgpu.Buffer_Binding {
						buffer = &state.camera_buffer,
						size = wgpu.WHOLE_SIZE,
					},
				},
			},
		},
	) or_return
	defer if err != nil do wgpu.bind_group_release(&state.camera_bind_group)

	render_pipeline_layout := wgpu.device_create_pipeline_layout(
		&state.gpu.device,
		& {
			label = "Render Pipeline Layout",
			bind_group_layouts = {texture_bind_group_layout, camera_bind_group_layout},
		},
	) or_return
	defer wgpu.pipeline_layout_release(&render_pipeline_layout)

	vertex_buffer_layout := wgpu.Vertex_Buffer_Layout {
		array_stride = size_of(Vertex),
		step_mode = .Vertex,
		attributes =  {
			{offset = 0, shader_location = 0, format = .Float32x3},
			 {
				offset = cast(u64)offset_of(Vertex, tex_coords),
				shader_location = 1,
				format = .Float32x2,
			},
		},
	}

	shader_source := #load("./shader.wgsl")
	shader_module := wgpu.device_create_shader_module(
		&state.gpu.device,
		&{source = cstring(raw_data(shader_source))},
	) or_return
	defer wgpu.shader_module_release(&shader_module)

	render_pipeline_descriptor := wgpu.Render_Pipeline_Descriptor {
		label = "Render Pipeline",
		layout = &render_pipeline_layout,
		vertex =  {
			module = &shader_module,
			entry_point = "vs_main",
			buffers = {vertex_buffer_layout},
		},
		fragment = & {
			module = &shader_module,
			entry_point = "fs_main",
			targets =  {
				 {
					format = state.gpu.config.format,
					blend = &wgpu.Blend_State_Replace,
					write_mask = wgpu.Color_Write_Mask_All,
				},
			},
		},
		primitive = {topology = .Triangle_List, front_face = .CCW, cull_mode = .None},
		depth_stencil = nil,
		multisample = {count = 1, mask = ~u32(0), alpha_to_coverage_enabled = false},
	}

	state.render_pipeline = wgpu.device_create_render_pipeline(
		&state.gpu.device,
		&render_pipeline_descriptor,
	) or_return
	defer if err != nil do wgpu.render_pipeline_release(&state.render_pipeline)

	vertices := []Vertex {
		{position = {-0.0868241, 0.49240386, 0.0}, tex_coords = {0.4131759, 0.00759614}}, // A
		{position = {-0.49513406, 0.06958647, 0.0}, tex_coords = {0.0048659444, 0.43041354}}, // B
		{position = {-0.21918549, -0.44939706, 0.0}, tex_coords = {0.28081453, 0.949397}}, // C
		{position = {0.35966998, -0.3473291, 0.0}, tex_coords = {0.85967, 0.84732914}}, // D
		{position = {0.44147372, 0.2347359, 0.0}, tex_coords = {0.9414737, 0.2652641}}, // E
	}

	indices: []u16 = {0, 1, 4, 1, 2, 4, 2, 3, 4}

	state.num_indices = cast(u32)len(indices)

	state.vertex_buffer = wgpu.device_create_buffer_with_data(
		&state.gpu.device,
		&wgpu.Buffer_Data_Descriptor {
			label = "Vertex Buffer",
			contents = wgpu.to_bytes(vertices),
			usage = {.Vertex},
		},
	) or_return
	defer if err != nil do wgpu.buffer_release(&state.vertex_buffer)

	state.index_buffer = wgpu.device_create_buffer_with_data(
		&state.gpu.device,
		&wgpu.Buffer_Data_Descriptor {
			label = "Index Buffer",
			contents = wgpu.to_bytes(indices),
			usage = {.Index},
		},
	) or_return

	return
}

update :: proc(using state: ^State) -> (err: Error) {
	update_camera_controller(&camera_controller, &camera)
	update_view_proj(&camera_uniform, &camera)

	wgpu.queue_write_buffer(&gpu.queue, &camera_buffer, 0, wgpu.to_bytes(camera_uniform.view_proj))

	return
}

render :: proc(using state: ^State) -> (err: Error) {
	frame := renderer.get_current_texture_frame(gpu) or_return
	defer wgpu.texture_release(&frame.texture)
	if gpu.skip_frame do return

	view := wgpu.texture_create_view(&frame.texture, nil) or_return
	defer wgpu.texture_view_release(&view)

	encoder := wgpu.device_create_command_encoder(&gpu.device) or_return
	defer wgpu.command_encoder_release(&encoder)

	render_pass := wgpu.command_encoder_begin_render_pass(
		&encoder,
		& {
			label = "Render Pass",
			color_attachments = []wgpu.Render_Pass_Color_Attachment {
				 {
					view = &view,
					resolve_target = nil,
					load_op = .Clear,
					store_op = .Store,
					clear_value = {0.1, 0.2, 0.3, 1.0},
				},
			},
			depth_stencil_attachment = nil,
		},
	)
	defer wgpu.render_pass_release(&render_pass)

	wgpu.render_pass_set_pipeline(&render_pass, &render_pipeline)
	wgpu.render_pass_set_bind_group(&render_pass, 0, &diffuse_bind_group)
	wgpu.render_pass_set_bind_group(&render_pass, 1, &camera_bind_group)
	wgpu.render_pass_set_vertex_buffer(&render_pass, 0, vertex_buffer)
	wgpu.render_pass_set_index_buffer(&render_pass, index_buffer, .Uint16, 0, wgpu.WHOLE_SIZE)
	wgpu.render_pass_draw_indexed(&render_pass, num_indices)
	wgpu.render_pass_end(&render_pass) or_return

	command_buffer := wgpu.command_encoder_finish(&encoder) or_return
	defer wgpu.command_buffer_release(&command_buffer)

	wgpu.queue_submit(&gpu.queue, &command_buffer)
	wgpu.surface_present(&gpu.surface)

	return
}

resize_surface :: proc(using state: ^State, size: app.Physical_Size) -> (err: Error) {
	camera.aspect = cast(f32)size.width / cast(f32)size.height
	update_view_proj(&camera_uniform, &camera)
	wgpu.queue_write_buffer(
		&gpu.queue,
		&camera_buffer,
		0,
		wgpu.to_bytes(camera_uniform.view_proj),
	) or_return

	renderer.resize_surface(gpu, {size.width, size.height}) or_return

	return
}

main :: proc() {
	app_properties := app.Default_Properties
	app_properties.title = "Tutorial 6 - Uniforms"
	if app.init(app_properties) != .No_Error do return
	defer app.deinit()

	state, state_err := init_example()
	if state_err != nil do return
	defer renderer.deinit(state.gpu)

	fmt.printf("Entering main loop...\n\n")

	main_loop: for {
		iter := app.process_events()

		for iter->has_next() {
			#partial switch event in iter->next() {
			case events.Quit_Event:
				break main_loop
			case events.Key_Press_Event:
				#partial switch event.key {
				case .Space:
					state.camera_controller.is_up_pressed = true
				case .Lshift:
					state.camera_controller.is_down_pressed = true
				case .W:
					state.camera_controller.is_forward_pressed = true
				case .A:
					state.camera_controller.is_left_pressed = true
				case .S:
					state.camera_controller.is_backward_pressed = true
				case .D:
					state.camera_controller.is_right_pressed = true
				}
			case events.Key_Release_Event:
				#partial switch event.key {
				case .Space:
					state.camera_controller.is_up_pressed = false
				case .Lshift:
					state.camera_controller.is_down_pressed = false
				case .W:
					state.camera_controller.is_forward_pressed = false
				case .A:
					state.camera_controller.is_left_pressed = false
				case .S:
					state.camera_controller.is_backward_pressed = false
				case .D:
					state.camera_controller.is_right_pressed = false
				}
			case events.Framebuffer_Resize_Event:
				if err := resize_surface(&state, {event.width, event.height}); err != nil {
					fmt.eprintf("Error while resizing [%v]: %v\n", err, wgpu.get_error_message())
					break main_loop
				}
			}
		}

		if err := update(&state); err != nil {
			fmt.eprintf("Error while update [%v]: %v\n", err, wgpu.get_error_message())
			break main_loop
		}

		if err := render(&state); err != nil {
			fmt.eprintf("Error while rendering [%v]: %v\n", err, wgpu.get_error_message())
			break main_loop
		}
	}

	// deinit state
	wgpu.buffer_release(&state.index_buffer)
	wgpu.buffer_release(&state.vertex_buffer)
	wgpu.render_pipeline_release(&state.render_pipeline)
	wgpu.bind_group_release(&state.camera_bind_group)
	wgpu.bind_group_release(&state.diffuse_bind_group)
	wgpu.buffer_release(&state.camera_buffer)

	fmt.println("Exiting...")
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
	return Open_Gl_To_Wgpu_Matrix * projection * view
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
