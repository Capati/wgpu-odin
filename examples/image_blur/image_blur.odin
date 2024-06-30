package image_blur_example

// Core
import "core:fmt"
import "core:math"

// Vendor
import mu "vendor:microui"

// Package
import wgpu "../../wrapper"
import wmu "./../../utils/microui"

// Framework
import app "../framework/application"
import "../framework/application/events"
import "../framework/renderer"

Settings :: struct {
	filter_size: i32,
	iterations:  i32,
}

State :: struct {
	using gpu:                ^renderer.Renderer,
	mu_ctx:                   ^mu.Context,
	blur_pipeline:            wgpu.Compute_Pipeline,
	fullscreen_quad_pipeline: wgpu.Render_Pipeline,
	image_texture:            wgpu.Texture,
	textures:                 [2]struct {
		texture: wgpu.Texture,
		view:    wgpu.Texture_View,
	},
	image_texture_view:       wgpu.Texture_View,
	buffer_0:                 wgpu.Buffer,
	buffer_1:                 wgpu.Buffer,
	sampler:                  wgpu.Sampler,
	blur_params_buffer:       wgpu.Buffer,
	compute_constants:        wgpu.Bind_Group,
	compute_bind_group_0:     wgpu.Bind_Group,
	compute_bind_group_1:     wgpu.Bind_Group,
	compute_bind_group_2:     wgpu.Bind_Group,
	show_result_bind_group:   wgpu.Bind_Group,
	block_dim:                i32,
	settings:                 Settings,
}

Error :: union #shared_nil {
	app.Application_Error,
	wgpu.Error,
}

// Constants from the shader
TILE_DIM: i32 : 128
BATCH :: 4

SLIDER_FMT :: "%.0f"

init_example :: proc() -> (state: State, err: Error) {
	r_properties := renderer.Default_Render_Properties
	r_properties.remove_srgb_from_surface = true // TODO(Capati): Fix srgb color
	r_properties.desired_maximum_frame_latency = 1
	r_properties.present_mode = .Fifo
	state.gpu = renderer.init(r_properties) or_return
	defer if err != nil do renderer.deinit(state)

	state.mu_ctx = wmu.init(&state.device, &state.queue, &state.surface.config) or_return
	defer if err != nil {
		wmu.destroy()
		free(state.mu_ctx)
	}

	blur_source := #load("./blur.wgsl", cstring)
	blur_shader := wgpu.device_create_shader_module(
		&state.device,
		&{source = blur_source},
	) or_return
	defer wgpu.shader_module_release(&blur_shader)
	state.blur_pipeline = wgpu.device_create_compute_pipeline(
		&state.device,
		&{compute = {module = blur_shader.ptr, entry_point = "main"}},
	) or_return
	defer if err != nil do wgpu.compute_pipeline_release(&state.blur_pipeline)

	fullscreen_texture_quad_source := #load("./fullscreen_textured_quad.wgsl", cstring)
	fullscreen_texture_quad_shader := wgpu.device_create_shader_module(
		&state.device,
		&{source = fullscreen_texture_quad_source},
	) or_return
	defer wgpu.shader_module_release(&fullscreen_texture_quad_shader)

	state.fullscreen_quad_pipeline = wgpu.device_create_render_pipeline(
		&state.device,
		&{
			vertex = {module = fullscreen_texture_quad_shader.ptr, entry_point = "vert_main"},
			fragment = &{
				module = fullscreen_texture_quad_shader.ptr,
				entry_point = "frag_main",
				targets = {
					{
						format = state.config.format,
						blend = nil,
						write_mask = wgpu.Color_Write_Mask_All,
					},
				},
			},
			primitive = {topology = .Triangle_List, front_face = .CCW, cull_mode = .None},
			depth_stencil = nil,
			multisample = wgpu.Default_Multisample_State,
		},
	) or_return
	defer if err != nil do wgpu.render_pipeline_release(&state.fullscreen_quad_pipeline)

	state.image_texture = wgpu.queue_copy_image_to_texture(
		&state.device,
		&state.queue,
		"./assets/image_blur/nature.jpg",
	) or_return
	defer if err != nil do wgpu.texture_release(&state.image_texture)

	for &t in state.textures {
		t.texture = wgpu.device_create_texture(
			&state.device,
			&{
				usage = {.Copy_Dst, .Storage_Binding, .Texture_Binding},
				dimension = state.image_texture.dimension,
				size = state.image_texture.size,
				format = state.image_texture.format,
				mip_level_count = state.image_texture.mip_level_count,
				sample_count = state.image_texture.sample_count,
			},
		) or_return
		t.view = wgpu.texture_create_view(&t.texture) or_return
	}
	defer if err != nil {
		for &t in state.textures {
			wgpu.texture_release(&t.texture)
			wgpu.texture_view_release(&t.view)
		}
	}

	state.buffer_0 = wgpu.device_create_buffer_with_data(
		&state.device,
		&{contents = wgpu.to_bytes([1]u32{0}), usage = {.Uniform}},
	) or_return
	defer if err != nil do wgpu.buffer_release(&state.buffer_0)

	state.buffer_1 = wgpu.device_create_buffer_with_data(
		&state.device,
		&{contents = wgpu.to_bytes([1]u32{1}), usage = {.Uniform}},
	) or_return
	defer if err != nil do wgpu.buffer_release(&state.buffer_1)

	state.blur_params_buffer = wgpu.device_create_buffer(
		&state.device,
		&{size = size_of(Settings), usage = {.Copy_Dst, .Uniform}},
	) or_return
	defer if err != nil do wgpu.buffer_release(&state.blur_params_buffer)

	blur_pipeline_layout_0 := wgpu.compute_pipeline_get_bind_group_layout(
		&state.blur_pipeline,
		0,
	) or_return
	defer wgpu.bind_group_layout_release(&blur_pipeline_layout_0)

	sampler_descriptor := wgpu.Default_Sampler_Descriptor
	sampler_descriptor.mag_filter = .Linear
	sampler_descriptor.min_filter = .Linear
	state.sampler = wgpu.device_create_sampler(&state.device, &sampler_descriptor) or_return
	defer if err != nil do wgpu.sampler_release(&state.sampler)

	state.compute_constants = wgpu.device_create_bind_group(
		&state.device,
		&{
			layout = blur_pipeline_layout_0.ptr,
			entries = {
				{binding = 0, resource = state.sampler.ptr},
				{
					binding = 1,
					resource = wgpu.Buffer_Binding {
						buffer = state.blur_params_buffer.ptr,
						size = state.blur_params_buffer.size,
					},
				},
			},
		},
	) or_return

	blur_pipeline_layout_1 := wgpu.compute_pipeline_get_bind_group_layout(
		&state.blur_pipeline,
		1,
	) or_return
	defer wgpu.bind_group_layout_release(&blur_pipeline_layout_1)

	state.image_texture_view = wgpu.texture_create_view(&state.image_texture) or_return
	defer if err != nil do wgpu.texture_view_release(&state.image_texture_view)

	state.compute_bind_group_0 = wgpu.device_create_bind_group(
		&state.device,
		&{
			layout = blur_pipeline_layout_1.ptr,
			entries = {
				{binding = 1, resource = state.image_texture_view.ptr},
				{binding = 2, resource = state.textures[0].view.ptr},
				{
					binding = 3,
					resource = wgpu.Buffer_Binding {
						buffer = state.buffer_0.ptr,
						size = state.buffer_0.size,
					},
				},
			},
		},
	) or_return
	defer if err != nil do wgpu.bind_group_release(&state.compute_bind_group_0)

	state.compute_bind_group_1 = wgpu.device_create_bind_group(
		&state.device,
		&{
			layout = blur_pipeline_layout_1.ptr,
			entries = {
				{binding = 1, resource = state.textures[0].view.ptr},
				{binding = 2, resource = state.textures[1].view.ptr},
				{
					binding = 3,
					resource = wgpu.Buffer_Binding {
						buffer = state.buffer_1.ptr,
						size = state.buffer_1.size,
					},
				},
			},
		},
	) or_return
	defer if err != nil do wgpu.bind_group_release(&state.compute_bind_group_1)

	state.compute_bind_group_2 = wgpu.device_create_bind_group(
		&state.device,
		&{
			layout = blur_pipeline_layout_1.ptr,
			entries = {
				{binding = 1, resource = state.textures[1].view.ptr},
				{binding = 2, resource = state.textures[0].view.ptr},
				{
					binding = 3,
					resource = wgpu.Buffer_Binding {
						buffer = state.buffer_0.ptr,
						size = state.buffer_0.size,
					},
				},
			},
		},
	) or_return
	defer if err != nil do wgpu.bind_group_release(&state.compute_bind_group_2)

	fullscreen_quad_pipeline_layout := wgpu.render_pipeline_get_bind_group_layout(
		&state.fullscreen_quad_pipeline,
		0,
	) or_return
	defer wgpu.bind_group_layout_release(&fullscreen_quad_pipeline_layout)

	state.show_result_bind_group = wgpu.device_create_bind_group(
		&state.device,
		&{
			layout = fullscreen_quad_pipeline_layout.ptr,
			entries = {
				{binding = 0, resource = state.sampler.ptr},
				{binding = 1, resource = state.textures[1].view.ptr},
			},
		},
	) or_return
	defer if err != nil do wgpu.bind_group_release(&state.show_result_bind_group)

	state.settings = {
		filter_size = 15,
		iterations  = 2,
	}

	update_settings(&state) or_return

	return
}

deinit_example :: proc(using s: ^State) {
	wgpu.bind_group_release(&show_result_bind_group)
	wgpu.bind_group_release(&compute_bind_group_2)
	wgpu.bind_group_release(&compute_bind_group_1)
	wgpu.bind_group_release(&compute_bind_group_0)
	for &t in textures {
		wgpu.texture_release(&t.texture)
		wgpu.texture_view_release(&t.view)
	}
	wgpu.texture_view_release(&image_texture_view)
	wgpu.buffer_release(&buffer_0)
	wgpu.buffer_release(&buffer_1)
	wgpu.sampler_release(&sampler)
	wgpu.buffer_release(&blur_params_buffer)
	wgpu.bind_group_release(&compute_constants)
	wgpu.texture_release(&image_texture)
	wgpu.render_pipeline_release(&fullscreen_quad_pipeline)
	wgpu.compute_pipeline_release(&blur_pipeline)

	wmu.destroy()
	renderer.deinit(gpu)
	free(mu_ctx)
}

update_settings :: proc(using state: ^State) -> (err: Error) {
	block_dim = TILE_DIM - (settings.filter_size - 1)
	wgpu.queue_write_buffer(
		&queue,
		blur_params_buffer.ptr,
		0,
		wgpu.to_bytes([2]i32{settings.filter_size, block_dim}),
	) or_return

	return
}

render_example :: proc(using state: ^State) -> (err: Error) {
	// UI definition
	mu.begin(mu_ctx)
	if mu.begin_window(mu_ctx, "Settings", {10, 10, 245, 78}, {.NO_RESIZE}) {
		mu.layout_row(mu_ctx, {-1}, 40)
		mu.layout_begin_column(mu_ctx)
		{
			mu.layout_row(mu_ctx, {60, -1}, 0)
			mu.label(mu_ctx, "Filter size:")
			if .CHANGE in wmu.slider(mu_ctx, &settings.filter_size, 2, 34, 2, SLIDER_FMT) {
				update_settings(state) or_return
			}
			mu.label(mu_ctx, "Iterations:")
			if .CHANGE in wmu.slider(mu_ctx, &settings.iterations, 1, 20, 1, SLIDER_FMT) {
				update_settings(state) or_return
			}
		}
		mu.layout_end_column(mu_ctx)

		mu.end_window(mu_ctx)
	}
	mu.end(mu_ctx)

	frame := renderer.get_current_texture_frame(gpu) or_return
	defer wgpu.texture_release(&frame.texture)
	if skip_frame do return

	view := wgpu.texture_create_view(&frame.texture, nil) or_return
	defer wgpu.texture_view_release(&view)

	encoder := wgpu.device_create_command_encoder(&device) or_return
	defer wgpu.command_encoder_release(&encoder)

	compute_pass := wgpu.command_encoder_begin_compute_pass(&encoder) or_return
	wgpu.compute_pass_encoder_set_pipeline(&compute_pass, blur_pipeline.ptr)
	wgpu.compute_pass_encoder_set_bind_group(&compute_pass, 0, compute_constants.ptr)

	wgpu.compute_pass_encoder_set_bind_group(&compute_pass, 1, compute_bind_group_0.ptr)
	wgpu.compute_pass_encoder_dispatch_workgroups(
		&compute_pass,
		u32(math.ceil(f32(image_texture.size.width) / f32(block_dim))),
		u32(math.ceil(f32(image_texture.size.height) / BATCH)),
	)

	wgpu.compute_pass_encoder_set_bind_group(&compute_pass, 1, compute_bind_group_1.ptr)
	wgpu.compute_pass_encoder_dispatch_workgroups(
		&compute_pass,
		u32(math.ceil(f32(image_texture.size.height) / f32(block_dim))),
		u32(math.ceil(f32(image_texture.size.width) / BATCH)),
	)

	for _ in 0 ..< settings.iterations - 1 {
		wgpu.compute_pass_encoder_set_bind_group(&compute_pass, 1, compute_bind_group_2.ptr)
		wgpu.compute_pass_encoder_dispatch_workgroups(
			&compute_pass,
			u32(math.ceil(f32(image_texture.size.width) / f32(block_dim))),
			u32(math.ceil(f32(image_texture.size.height) / BATCH)),
		)

		wgpu.compute_pass_encoder_set_bind_group(&compute_pass, 1, compute_bind_group_1.ptr)
		wgpu.compute_pass_encoder_dispatch_workgroups(
			&compute_pass,
			u32(math.ceil(f32(image_texture.size.height) / f32(block_dim))),
			u32(math.ceil(f32(image_texture.size.width) / BATCH)),
		)
	}

	wgpu.compute_pass_encoder_end(&compute_pass) or_return

	render_pass := wgpu.command_encoder_begin_render_pass(
		&encoder,
		&{
			label = "Render Pass",
			color_attachments = []wgpu.Render_Pass_Color_Attachment {
				{
					view = view.ptr,
					load_op = .Clear,
					store_op = .Store,
					clear_value = wgpu.Color_Black,
				},
			},
		},
	)

	wgpu.render_pass_encoder_set_pipeline(&render_pass, fullscreen_quad_pipeline.ptr)
	wgpu.render_pass_encoder_set_bind_group(&render_pass, 0, show_result_bind_group.ptr)
	wgpu.render_pass_encoder_draw(&render_pass, 6)

	// micro-ui rendering
	wmu.render(mu_ctx, &render_pass) or_return

	wgpu.render_pass_encoder_end(&render_pass) or_return
	wgpu.render_pass_encoder_release(&render_pass)

	command_buffer := wgpu.command_encoder_finish(&encoder) or_return
	defer wgpu.command_buffer_release(&command_buffer)

	wgpu.queue_submit(&queue, command_buffer.ptr)
	wgpu.surface_present(&surface)

	return
}

resize_surface :: proc(using state: ^State, size: app.Physical_Size) -> (err: Error) {
	renderer.resize_surface(gpu, {size.width, size.height}) or_return
	wmu.resize(i32(size.width), i32(size.height))
	return
}

main :: proc() {
	app_properties := app.Default_Properties
	app_properties.title = "Image Blur"
	app_properties.size = {639, 443}
	if app.init(app_properties) != nil do return
	defer app.deinit()

	state, state_err := init_example()
	if state_err != nil do return
	defer deinit_example(&state)

	fmt.printf("Entering main loop...\n\n")

	main_loop: for {
		event: events.Event
		for app.poll_event(&event) {
			#partial switch &ev in event {
			case events.Quit_Event:
				break main_loop
			case events.Framebuffer_Resize_Event:
				if err := resize_surface(&state, {ev.width, ev.height}); err != nil {
					break main_loop
				}
			case events.Text_Input_Event:
				mu.input_text(state.mu_ctx, string(cstring(&ev.buf[0])))
			case events.Mouse_Press_Event:
				mu.input_mouse_down(
					state.mu_ctx,
					ev.pos.x,
					ev.pos.y,
					events.mu_input_mouse(ev.button),
				)
			case events.Mouse_Release_Event:
				mu.input_mouse_up(
					state.mu_ctx,
					ev.pos.x,
					ev.pos.y,
					events.mu_input_mouse(ev.button),
				)
			case events.Mouse_Scroll_Event:
				mu.input_scroll(state.mu_ctx, ev.x * -25, ev.y * -25)
			case events.Mouse_Motion_Event:
				mu.input_mouse_move(state.mu_ctx, ev.x, ev.y)
			case events.Key_Press_Event:
				mu.input_key_down(state.mu_ctx, events.mu_input_key(ev.key))
			case events.Key_Release_Event:
				mu.input_key_up(state.mu_ctx, events.mu_input_key(ev.key))
			}
		}

		if err := render_example(&state); err != nil {
			break main_loop
		}
	}

	fmt.println("Exiting...")
}
