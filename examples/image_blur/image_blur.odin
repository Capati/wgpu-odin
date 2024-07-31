package image_blur_example

// STD Library
import "core:math"

// Vendor
import mu "vendor:microui"

// Local Packages
import wgpu "../../wrapper"
import wmu "./../../utils/microui"
import rl "./../../utils/renderlink"
import "./../../utils/shaders"

Settings :: struct {
	filter_size: i32,
	iterations:  i32,
}

State :: struct {
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
	blur_settings:            Settings,
}

App_Context :: rl.Context(State)

// Constants from the shader
TILE_DIM: i32 : 128
BATCH :: 4

SLIDER_FMT :: "%.0f"

EXAMPLE_TITLE :: "Image Blur"

init :: proc(using ctx: ^App_Context) -> (err: rl.Error) {
	// Initialize MicroUI renderer
	state.mu_ctx = wmu.init(gpu.device, gpu.queue, gpu.surface.config) or_return
	defer if err != nil {
		wmu.destroy()
		free(state.mu_ctx)
	}

	// Initialize example objects
	BLUR_SOURCE :: #load("./blur.wgsl", cstring)
	blur_shader := wgpu.device_create_shader_module(gpu.device, {source = BLUR_SOURCE}) or_return
	defer wgpu.shader_module_release(blur_shader)
	state.blur_pipeline = wgpu.device_create_compute_pipeline(
		gpu.device,
		{compute = {module = blur_shader.ptr, entry_point = "main"}},
	) or_return
	defer if err != nil do wgpu.compute_pipeline_release(state.blur_pipeline)

	QUAD_SHADER_SRC: string : #load("./fullscreen_textured_quad.wgsl", string)
	QUAD_COMBINED_SHADER_SRC :: shaders.SRGB_TO_LINEAR_WGSL + QUAD_SHADER_SRC
	quad_shader_module := wgpu.device_create_shader_module(
		gpu.device,
		{source = cstring(raw_data(QUAD_COMBINED_SHADER_SRC))},
	) or_return
	defer wgpu.shader_module_release(quad_shader_module)

	state.fullscreen_quad_pipeline = wgpu.device_create_render_pipeline(
		gpu.device,
		{
			vertex = {module = quad_shader_module.ptr, entry_point = "vert_main"},
			fragment = &{
				module = quad_shader_module.ptr,
				entry_point = "frag_main",
				targets = {
					{
						format = gpu.config.format,
						blend = nil,
						write_mask = wgpu.Color_Write_Mask_All,
					},
				},
			},
			primitive = {topology = .Triangle_List, front_face = .CCW, cull_mode = .None},
			depth_stencil = nil,
			multisample = wgpu.DEFAULT_MULTISAMPLE_STATE,
		},
	) or_return
	defer if err != nil do wgpu.render_pipeline_release(state.fullscreen_quad_pipeline)

	state.image_texture = wgpu.queue_copy_image_to_texture(
		gpu.device,
		gpu.queue,
		"./assets/image_blur/nature.jpg",
	) or_return
	defer if err != nil do wgpu.texture_release(state.image_texture)

	for &t in state.textures {
		t.texture = wgpu.device_create_texture(
			gpu.device,
			{
				usage = {.Copy_Dst, .Storage_Binding, .Texture_Binding},
				dimension = state.image_texture.dimension,
				size = state.image_texture.size,
				format = state.image_texture.format,
				mip_level_count = state.image_texture.mip_level_count,
				sample_count = state.image_texture.sample_count,
			},
		) or_return
		t.view = wgpu.texture_create_view(t.texture) or_return
	}
	defer if err != nil {
		for t in state.textures {
			wgpu.texture_release(t.texture)
			wgpu.texture_view_release(t.view)
		}
	}

	state.buffer_0 = wgpu.device_create_buffer_with_data(
		gpu.device,
		{contents = wgpu.to_bytes([1]u32{0}), usage = {.Uniform}},
	) or_return
	defer if err != nil do wgpu.buffer_release(state.buffer_0)

	state.buffer_1 = wgpu.device_create_buffer_with_data(
		gpu.device,
		{contents = wgpu.to_bytes([1]u32{1}), usage = {.Uniform}},
	) or_return
	defer if err != nil do wgpu.buffer_release(state.buffer_1)

	state.blur_params_buffer = wgpu.device_create_buffer(
		gpu.device,
		{size = size_of(Settings), usage = {.Copy_Dst, .Uniform}},
	) or_return
	defer if err != nil do wgpu.buffer_release(state.blur_params_buffer)

	blur_pipeline_layout_0 := wgpu.compute_pipeline_get_bind_group_layout(
		state.blur_pipeline,
		0,
	) or_return
	defer wgpu.bind_group_layout_release(blur_pipeline_layout_0)

	sampler_descriptor := wgpu.DEFAULT_SAMPLER_DESCRIPTOR
	sampler_descriptor.mag_filter = .Linear
	sampler_descriptor.min_filter = .Linear
	state.sampler = wgpu.device_create_sampler(gpu.device, sampler_descriptor) or_return
	defer if err != nil do wgpu.sampler_release(state.sampler)

	state.compute_constants = wgpu.device_create_bind_group(
		gpu.device,
		{
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
		state.blur_pipeline,
		1,
	) or_return
	defer wgpu.bind_group_layout_release(blur_pipeline_layout_1)

	state.image_texture_view = wgpu.texture_create_view(state.image_texture) or_return
	defer if err != nil do wgpu.texture_view_release(state.image_texture_view)

	state.compute_bind_group_0 = wgpu.device_create_bind_group(
		gpu.device,
		{
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
	defer if err != nil do wgpu.bind_group_release(state.compute_bind_group_0)

	state.compute_bind_group_1 = wgpu.device_create_bind_group(
		gpu.device,
		{
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
	defer if err != nil do wgpu.bind_group_release(state.compute_bind_group_1)

	state.compute_bind_group_2 = wgpu.device_create_bind_group(
		gpu.device,
		{
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
	defer if err != nil do wgpu.bind_group_release(state.compute_bind_group_2)

	fullscreen_quad_pipeline_layout := wgpu.render_pipeline_get_bind_group_layout(
		state.fullscreen_quad_pipeline,
		0,
	) or_return
	defer wgpu.bind_group_layout_release(fullscreen_quad_pipeline_layout)

	state.show_result_bind_group = wgpu.device_create_bind_group(
		gpu.device,
		{
			layout = fullscreen_quad_pipeline_layout.ptr,
			entries = {
				{binding = 0, resource = state.sampler.ptr},
				{binding = 1, resource = state.textures[1].view.ptr},
			},
		},
	) or_return
	defer if err != nil do wgpu.bind_group_release(state.show_result_bind_group)

	state.blur_settings = {
		filter_size = 15,
		iterations  = 2,
	}

	update_settings(ctx) or_return

	return
}

quit :: proc(using ctx: ^App_Context) {
	wgpu.bind_group_release(show_result_bind_group)
	wgpu.bind_group_release(compute_bind_group_2)
	wgpu.bind_group_release(compute_bind_group_1)
	wgpu.bind_group_release(compute_bind_group_0)
	for &t in textures {
		wgpu.texture_release(t.texture)
		wgpu.texture_view_release(t.view)
	}
	wgpu.texture_view_release(image_texture_view)
	wgpu.buffer_release(buffer_0)
	wgpu.buffer_release(buffer_1)
	wgpu.sampler_release(sampler)
	wgpu.buffer_release(blur_params_buffer)
	wgpu.bind_group_release(compute_constants)
	wgpu.texture_release(image_texture)
	wgpu.render_pipeline_release(fullscreen_quad_pipeline)
	wgpu.compute_pipeline_release(blur_pipeline)

	wmu.destroy()
}

update_settings :: proc(using ctx: ^App_Context) -> (err: rl.Error) {
	block_dim = TILE_DIM - (state.blur_settings.filter_size - 1)
	wgpu.queue_write_buffer(
		gpu.queue,
		blur_params_buffer.ptr,
		0,
		wgpu.to_bytes([2]i32{state.blur_settings.filter_size, block_dim}),
	) or_return

	return
}

handle_events :: proc(event: rl.Event, using ctx: ^App_Context) {
	rl.event_mu_set_event(mu_ctx, event)
}

update :: proc(dt: f64, using ctx: ^App_Context) -> (err: rl.Error) {
	// UI definition
	mu.begin(mu_ctx)
	if mu.begin_window(mu_ctx, "Settings", {10, 10, 245, 78}, {.NO_RESIZE}) {
		mu.layout_row(mu_ctx, {-1}, 40)
		mu.layout_begin_column(mu_ctx)
		{
			mu.layout_row(mu_ctx, {60, -1}, 0)
			mu.label(mu_ctx, "Filter size:")
			if .CHANGE in
			   wmu.slider(mu_ctx, &state.blur_settings.filter_size, 2, 34, 2, SLIDER_FMT) {
				update_settings(ctx) or_return
			}
			mu.label(mu_ctx, "Iterations:")
			if .CHANGE in
			   wmu.slider(mu_ctx, &state.blur_settings.iterations, 1, 20, 1, SLIDER_FMT) {
				update_settings(ctx) or_return
			}
		}
		mu.layout_end_column(mu_ctx)

		mu.end_window(mu_ctx)
	}
	mu.end(mu_ctx)

	return
}

draw :: proc(using ctx: ^App_Context) -> (err: rl.Error) {
	compute_pass := wgpu.command_encoder_begin_compute_pass(gpu.encoder) or_return

	wgpu.compute_pass_encoder_set_pipeline(compute_pass, blur_pipeline.ptr)
	wgpu.compute_pass_encoder_set_bind_group(compute_pass, 0, compute_constants.ptr)

	wgpu.compute_pass_encoder_set_bind_group(compute_pass, 1, compute_bind_group_0.ptr)
	wgpu.compute_pass_encoder_dispatch_workgroups(
		compute_pass,
		u32(math.ceil(f32(image_texture.size.width) / f32(block_dim))),
		u32(math.ceil(f32(image_texture.size.height) / BATCH)),
	)

	wgpu.compute_pass_encoder_set_bind_group(compute_pass, 1, compute_bind_group_1.ptr)
	wgpu.compute_pass_encoder_dispatch_workgroups(
		compute_pass,
		u32(math.ceil(f32(image_texture.size.height) / f32(block_dim))),
		u32(math.ceil(f32(image_texture.size.width) / BATCH)),
	)

	for _ in 0 ..< state.blur_settings.iterations - 1 {
		wgpu.compute_pass_encoder_set_bind_group(compute_pass, 1, compute_bind_group_2.ptr)
		wgpu.compute_pass_encoder_dispatch_workgroups(
			compute_pass,
			u32(math.ceil(f32(image_texture.size.width) / f32(block_dim))),
			u32(math.ceil(f32(image_texture.size.height) / BATCH)),
		)

		wgpu.compute_pass_encoder_set_bind_group(compute_pass, 1, compute_bind_group_1.ptr)
		wgpu.compute_pass_encoder_dispatch_workgroups(
			compute_pass,
			u32(math.ceil(f32(image_texture.size.height) / f32(block_dim))),
			u32(math.ceil(f32(image_texture.size.width) / BATCH)),
		)
	}

	wgpu.compute_pass_encoder_end(compute_pass) or_return

	wgpu.render_pass_set_pipeline(gpu.render_pass, fullscreen_quad_pipeline.ptr)
	wgpu.render_pass_set_bind_group(gpu.render_pass, 0, show_result_bind_group.ptr)
	wgpu.render_pass_draw(gpu.render_pass, {0, 6})

	// micro-ui rendering
	wmu.render(mu_ctx, gpu.render_pass) or_return

	return
}

main :: proc() {
	state, state_err := new(App_Context)
	if state_err != nil do return
	defer free(state)

	state.callbacks = {
		init          = init,
		quit          = quit,
		handle_events = handle_events,
		update        = update,
		draw          = draw,
	}

	settings := rl.DEFAULT_SETTINGS
	settings.title = EXAMPLE_TITLE

	if err := rl.init(state, settings); err != nil do return

	rl.begin_run(state) // Start the main loop
}
