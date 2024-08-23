package image_blur_example

// STD Library
import "core:math"
import "base:runtime"
import "base:builtin"
@(require) import "core:log"

// Vendor
import mu "vendor:microui"

// Local Packages
import wgpu "../../wrapper"
import wmu "./../../utils/microui"
import rl "./../../utils/renderlink"
import "./../../utils/shaders"

Settings :: struct {
	filter_size : i32,
	iterations  : i32,
}

State :: struct {
	mu_ctx                   : ^mu.Context,
	blur_pipeline            : wgpu.Compute_Pipeline,
	fullscreen_quad_pipeline : wgpu.Render_Pipeline,
	image_texture            : wgpu.Texture,
	textures                 : [2]struct {
		texture : wgpu.Texture,
		view    : wgpu.Texture_View,
	},
	image_texture_view       : wgpu.Texture_View,
	buffer_0                 : wgpu.Buffer,
	buffer_1                 : wgpu.Buffer,
	sampler                  : wgpu.Sampler,
	blur_params_buffer       : wgpu.Buffer,
	compute_constants        : wgpu.Bind_Group,
	compute_bind_group_0     : wgpu.Bind_Group,
	compute_bind_group_1     : wgpu.Bind_Group,
	compute_bind_group_2     : wgpu.Bind_Group,
	show_result_bind_group   : wgpu.Bind_Group,
	block_dim                : i32,
	blur_settings            : Settings,
}

State_Context :: rl.Context(State)

// Constants from the shader
TILE_DIM: i32 : 128
BATCH :: 4

SLIDER_FMT :: "%.0f"

EXAMPLE_TITLE :: "Image Blur"

init :: proc(ctx: ^State_Context) -> (ok: bool) {
	// Initialize MicroUI renderer
	ctx.mu_ctx = wmu.init(ctx.gpu.device, ctx.gpu.queue, ctx.gpu.config) or_return
	defer if !ok {
		wmu.destroy()
		free(ctx.mu_ctx)
	}

	// Initialize example objects
	BLUR_SOURCE :: #load("./blur.wgsl", cstring)
	blur_shader := wgpu.device_create_shader_module(
		ctx.gpu.device,
		{source = BLUR_SOURCE},
	) or_return
	defer wgpu.shader_module_release(blur_shader)
	ctx.blur_pipeline = wgpu.device_create_compute_pipeline(
		ctx.gpu.device,
		{module = blur_shader, entry_point = "main"},
	) or_return
	defer if !ok do wgpu.compute_pipeline_release(ctx.blur_pipeline)

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	FULLSCREEN_TEXTURED_QUAD_WGSL: string : #load("./fullscreen_textured_quad.wgsl", string)
	shader_source := shaders.apply_color_conversion(
		FULLSCREEN_TEXTURED_QUAD_WGSL,
		ctx.gpu.is_srgb,
		context.temp_allocator,
	) or_return
	quad_shader_module := wgpu.device_create_shader_module(
		ctx.gpu.device,
		{source = shader_source},
	) or_return
	defer wgpu.shader_module_release(quad_shader_module)

	ctx.fullscreen_quad_pipeline = wgpu.device_create_render_pipeline(
		ctx.gpu.device,
		{
			vertex = {module = quad_shader_module, entry_point = "vert_main"},
			fragment = &{
				module = quad_shader_module,
				entry_point = "frag_main",
				targets = {
					{
						format = ctx.gpu.config.format,
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
	defer if !ok do wgpu.render_pipeline_release(ctx.fullscreen_quad_pipeline)

	ctx.image_texture = wgpu.queue_copy_image_to_texture(
		ctx.gpu.device,
		ctx.gpu.queue,
		"./assets/image_blur/nature.jpg",
	) or_return
	defer if !ok do wgpu.texture_release(ctx.image_texture)

	image_texture_descriptor := wgpu.texture_descriptor(ctx.image_texture)

	for &t in ctx.textures {
		t.texture = wgpu.device_create_texture(
			ctx.gpu.device,
			{
				usage           = {.Copy_Dst, .Storage_Binding, .Texture_Binding},
				dimension       = image_texture_descriptor.dimension,
				size            = image_texture_descriptor.size,
				format          = image_texture_descriptor.format,
				mip_level_count = image_texture_descriptor.mip_level_count,
				sample_count    = image_texture_descriptor.sample_count,
			},
		) or_return
		t.view = wgpu.texture_create_view(t.texture) or_return
	}
	defer if !ok {
		for t in ctx.textures {
			wgpu.texture_release(t.texture)
			wgpu.texture_view_release(t.view)
		}
	}

	ctx.buffer_0 = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{contents = wgpu.to_bytes([1]u32{0}), usage = {.Uniform}},
	) or_return
	defer if !ok do wgpu.buffer_release(ctx.buffer_0)

	ctx.buffer_1 = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{contents = wgpu.to_bytes([1]u32{1}), usage = {.Uniform}},
	) or_return
	defer if !ok do wgpu.buffer_release(ctx.buffer_1)

	ctx.blur_params_buffer = wgpu.device_create_buffer(
		ctx.gpu.device,
		{size = size_of(Settings), usage = {.Copy_Dst, .Uniform}},
	) or_return
	defer if !ok do wgpu.buffer_release(ctx.blur_params_buffer)

	blur_pipeline_layout_0 := wgpu.compute_pipeline_get_bind_group_layout(
		ctx.blur_pipeline,
		0,
	) or_return
	defer wgpu.bind_group_layout_release(blur_pipeline_layout_0)

	sampler_descriptor := wgpu.DEFAULT_SAMPLER_DESCRIPTOR
	sampler_descriptor.mag_filter = .Linear
	sampler_descriptor.min_filter = .Linear
	ctx.sampler = wgpu.device_create_sampler(ctx.gpu.device, sampler_descriptor) or_return
	defer if !ok do wgpu.sampler_release(ctx.sampler)

	ctx.compute_constants = wgpu.device_create_bind_group(
		ctx.gpu.device,
		{
			layout = blur_pipeline_layout_0,
			entries = {
				{binding = 0, resource = ctx.sampler},
				{
					binding = 1,
					resource = wgpu.Buffer_Binding {
						buffer = ctx.blur_params_buffer,
						size = wgpu.buffer_get_size(ctx.blur_params_buffer),
					},
				},
			},
		},
	) or_return

	blur_pipeline_layout_1 := wgpu.compute_pipeline_get_bind_group_layout(
		ctx.blur_pipeline,
		1,
	) or_return
	defer wgpu.bind_group_layout_release(blur_pipeline_layout_1)

	ctx.image_texture_view = wgpu.texture_create_view(ctx.image_texture) or_return
	defer if !ok do wgpu.texture_view_release(ctx.image_texture_view)

	ctx.compute_bind_group_0 = wgpu.device_create_bind_group(
		ctx.gpu.device,
		{
			layout = blur_pipeline_layout_1,
			entries = {
				{binding = 1, resource = ctx.image_texture_view},
				{binding = 2, resource = ctx.textures[0].view},
				{
					binding = 3,
					resource = wgpu.Buffer_Binding {
						buffer = ctx.buffer_0,
						size = wgpu.buffer_get_size(ctx.buffer_0),
					},
				},
			},
		},
	) or_return
	defer if !ok do wgpu.bind_group_release(ctx.compute_bind_group_0)

	ctx.compute_bind_group_1 = wgpu.device_create_bind_group(
		ctx.gpu.device,
		{
			layout = blur_pipeline_layout_1,
			entries = {
				{binding = 1, resource = ctx.textures[0].view},
				{binding = 2, resource = ctx.textures[1].view},
				{
					binding = 3,
					resource = wgpu.Buffer_Binding {
						buffer = ctx.buffer_1,
						size = wgpu.buffer_get_size(ctx.buffer_1),
					},
				},
			},
		},
	) or_return
	defer if !ok do wgpu.bind_group_release(ctx.compute_bind_group_1)

	ctx.compute_bind_group_2 = wgpu.device_create_bind_group(
		ctx.gpu.device,
		{
			layout = blur_pipeline_layout_1,
			entries = {
				{binding = 1, resource = ctx.textures[1].view},
				{binding = 2, resource = ctx.textures[0].view},
				{
					binding = 3,
					resource = wgpu.Buffer_Binding {
						buffer = ctx.buffer_0,
						size = wgpu.buffer_get_size(ctx.buffer_0),
					},
				},
			},
		},
	) or_return
	defer if !ok do wgpu.bind_group_release(ctx.compute_bind_group_2)

	fullscreen_quad_pipeline_layout := wgpu.render_pipeline_get_bind_group_layout(
		ctx.fullscreen_quad_pipeline,
		0,
	) or_return
	defer wgpu.bind_group_layout_release(fullscreen_quad_pipeline_layout)

	ctx.show_result_bind_group = wgpu.device_create_bind_group(
		ctx.gpu.device,
		{
			layout = fullscreen_quad_pipeline_layout,
			entries = {
				{binding = 0, resource = ctx.sampler},
				{binding = 1, resource = ctx.textures[1].view},
			},
		},
	) or_return
	defer if !ok do wgpu.bind_group_release(ctx.show_result_bind_group)

	ctx.blur_settings = {
		filter_size = 15,
		iterations  = 2,
	}

	update_settings(ctx) or_return

	return true
}

quit :: proc(ctx: ^State_Context) {
	wgpu.bind_group_release(ctx.show_result_bind_group)
	wgpu.bind_group_release(ctx.compute_bind_group_2)
	wgpu.bind_group_release(ctx.compute_bind_group_1)
	wgpu.bind_group_release(ctx.compute_bind_group_0)
	for &t in ctx.textures {
		wgpu.texture_release(t.texture)
		wgpu.texture_view_release(t.view)
	}
	wgpu.texture_view_release(ctx.image_texture_view)
	wgpu.buffer_release(ctx.buffer_0)
	wgpu.buffer_release(ctx.buffer_1)
	wgpu.sampler_release(ctx.sampler)
	wgpu.buffer_release(ctx.blur_params_buffer)
	wgpu.bind_group_release(ctx.compute_constants)
	wgpu.texture_release(ctx.image_texture)
	wgpu.render_pipeline_release(ctx.fullscreen_quad_pipeline)
	wgpu.compute_pipeline_release(ctx.blur_pipeline)

	wmu.destroy()
}

update_settings :: proc(ctx: ^State_Context) -> bool {
	ctx.block_dim = TILE_DIM - (ctx.blur_settings.filter_size - 1)
	wgpu.queue_write_buffer(
		ctx.gpu.queue,
		ctx.blur_params_buffer,
		0,
		wgpu.to_bytes([2]i32{ctx.blur_settings.filter_size, ctx.block_dim}),
	) or_return

	return true
}

handle_events :: proc(event: rl.Event, ctx: ^State_Context) {
	rl.event_mu_set_event(ctx.mu_ctx, event)
}

update :: proc(dt: f64, ctx: ^State_Context) -> bool {
	// UI definition
	mu.begin(ctx.mu_ctx)
	if mu.begin_window(ctx.mu_ctx, "Settings", {10, 10, 245, 78}, {.NO_RESIZE}) {
		mu.layout_row(ctx.mu_ctx, {-1}, 40)
		mu.layout_begin_column(ctx.mu_ctx)
		{
			mu.layout_row(ctx.mu_ctx, {60, -1}, 0)
			mu.label(ctx.mu_ctx, "Filter size:")
			if .CHANGE in
			   wmu.slider(ctx.mu_ctx, &ctx.blur_settings.filter_size, 2, 34, 2, SLIDER_FMT) {
				update_settings(ctx) or_return
			}
			mu.label(ctx.mu_ctx, "Iterations:")
			if .CHANGE in
			   wmu.slider(ctx.mu_ctx, &ctx.blur_settings.iterations, 1, 20, 1, SLIDER_FMT) {
				update_settings(ctx) or_return
			}
		}
		mu.layout_end_column(ctx.mu_ctx)

		mu.end_window(ctx.mu_ctx)
	}
	mu.end(ctx.mu_ctx)

	return true
}

draw :: proc(ctx: ^State_Context) -> bool {
	compute_pass := wgpu.command_encoder_begin_compute_pass(ctx.gpu.encoder) or_return

	wgpu.compute_pass_set_pipeline(compute_pass, ctx.blur_pipeline)
	wgpu.compute_pass_set_bind_group(compute_pass, 0, ctx.compute_constants)

	image_size := wgpu.texture_size(ctx.image_texture)

	wgpu.compute_pass_set_bind_group(compute_pass, 1, ctx.compute_bind_group_0)
	wgpu.compute_pass_dispatch_workgroups(
		compute_pass,
		u32(math.ceil(f32(image_size.width) / f32(ctx.block_dim))),
		u32(math.ceil(f32(image_size.height) / BATCH)),
	)

	wgpu.compute_pass_set_bind_group(compute_pass, 1, ctx.compute_bind_group_1)
	wgpu.compute_pass_dispatch_workgroups(
		compute_pass,
		u32(math.ceil(f32(image_size.height) / f32(ctx.block_dim))),
		u32(math.ceil(f32(image_size.width) / BATCH)),
	)

	for _ in 0 ..< ctx.blur_settings.iterations - 1 {
		wgpu.compute_pass_set_bind_group(compute_pass, 1, ctx.compute_bind_group_2)
		wgpu.compute_pass_dispatch_workgroups(
			compute_pass,
			u32(math.ceil(f32(image_size.width) / f32(ctx.block_dim))),
			u32(math.ceil(f32(image_size.height) / BATCH)),
		)

		wgpu.compute_pass_set_bind_group(compute_pass, 1, ctx.compute_bind_group_1)
		wgpu.compute_pass_dispatch_workgroups(
			compute_pass,
			u32(math.ceil(f32(image_size.height) / f32(ctx.block_dim))),
			u32(math.ceil(f32(image_size.width) / BATCH)),
		)
	}

	wgpu.compute_pass_end(compute_pass) or_return

	wgpu.render_pass_set_pipeline(ctx.gpu.render_pass, ctx.fullscreen_quad_pipeline)
	wgpu.render_pass_set_bind_group(ctx.gpu.render_pass, 0, ctx.show_result_bind_group)
	wgpu.render_pass_draw(ctx.gpu.render_pass, {0, 6})

	// micro-ui rendering
	wmu.render(ctx.mu_ctx, ctx.gpu.render_pass) or_return

	return true
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
	settings.title = EXAMPLE_TITLE

	if ok := rl.init(state, settings); !ok do return

	rl.begin_run(state) // Start the main loop
}
