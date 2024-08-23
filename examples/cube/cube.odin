package cube_example

// STD Library
import "base:builtin"
import "base:runtime"
@(require) import "core:log"

// Local packages
import "../common"
import rl "./../../utils/renderlink"
import "./../../utils/shaders"
import wgpu "./../../wrapper"

State :: struct {
	vertex_buffer   : wgpu.Buffer,
	render_pipeline : wgpu.Render_Pipeline,
	uniform_buffer  : wgpu.Buffer,
	bind_group      : wgpu.Bind_Group,
}

State_Context :: rl.Context(State)

EXAMPLE_TITLE :: "Colored Cube"
DEPTH_FORMAT :: wgpu.Texture_Format.Depth24_Plus

init :: proc(ctx: ^State_Context) -> (ok: bool) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	CUBE_WGSL: string : #load("./cube.wgsl", string)
	shader_source := shaders.apply_color_conversion(
		CUBE_WGSL,
		ctx.gpu.is_srgb,
		context.temp_allocator,
	) or_return
	shader_module := wgpu.device_create_shader_module(
		ctx.gpu.device,
		{label = EXAMPLE_TITLE + " Module", source = shader_source},
	) or_return
	defer wgpu.shader_module_release(shader_module)

	ctx.vertex_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{
			label    = EXAMPLE_TITLE + " Buffer",
			contents = wgpu.to_bytes(vertex_data),
			usage    = {.Vertex},
		},
	) or_return
	defer if !ok do wgpu.buffer_release(ctx.vertex_buffer)

	vertex_attributes := wgpu.vertex_attr_array(2, {0, .Float32x3}, {1, .Float32x3})

	vertex_buffer_layout := wgpu.Vertex_Buffer_Layout {
		array_stride = size_of(Vertex),
		step_mode    = .Vertex,
		attributes   = vertex_attributes[:],
	}

	pipeline_descriptor := wgpu.Render_Pipeline_Descriptor {
		label = EXAMPLE_TITLE + " Render Pipeline",
		vertex = {
			module      = shader_module,
			entry_point = "vs_main",
			buffers     = {vertex_buffer_layout},
		},
		fragment = &{
			module = shader_module,
			entry_point = "fs_main",
			targets = {
				{
					format     = ctx.gpu.config.format,
					blend      = &wgpu.Blend_State_Normal,
					write_mask = wgpu.Color_Write_Mask_All,
				},
			},
		},
		primitive = {topology = .Triangle_List, front_face = .CCW, cull_mode = .Back},
		// Enable depth testing so that the fragment closest to the camera
		// is rendered in front.
		depth_stencil = &{
			depth_write_enabled = true,
			depth_compare       = .Less,
			format              = DEPTH_FORMAT,
			stencil_front       = {compare = .Always},
			stencil_back        = {compare = .Always},
			stencil_read_mask   = 0xFFFFFFFF,
			stencil_write_mask  = 0xFFFFFFFF,
		},
		multisample = wgpu.DEFAULT_MULTISAMPLE_STATE,
	}

	ctx.render_pipeline = wgpu.device_create_render_pipeline(ctx.gpu.device, pipeline_descriptor) or_return
	defer if !ok do wgpu.render_pipeline_release(ctx.render_pipeline)

	aspect := f32(ctx.gpu.config.width) / f32(ctx.gpu.config.height)
	mvp_mat := common.create_view_projection_matrix(aspect)

	ctx.uniform_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{
			label = EXAMPLE_TITLE + " Uniform Buffer",
			contents = wgpu.to_bytes(mvp_mat),
			usage = {.Uniform, .Copy_Dst},
		},
	) or_return
	defer if !ok do wgpu.buffer_release(ctx.uniform_buffer)

	bind_group_layout := wgpu.render_pipeline_get_bind_group_layout(
		ctx.render_pipeline,
		0,
	) or_return
	defer wgpu.bind_group_layout_release(bind_group_layout)

	ctx.bind_group = wgpu.device_create_bind_group(
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
			},
		},
	) or_return
	defer if !ok do wgpu.bind_group_release(ctx.bind_group)

	rl.graphics_clear(rl.Color_Dark_Gray)

	return true
}

quit :: proc(ctx: ^State_Context) {
	wgpu.bind_group_release(ctx.bind_group)
	wgpu.buffer_release(ctx.uniform_buffer)
	wgpu.render_pipeline_release(ctx.render_pipeline)
	wgpu.buffer_release(ctx.vertex_buffer)
}

resize :: proc(event: rl.Resize_Event, ctx: ^State_Context) -> bool {
	// Update uniform buffer with new aspect ratio
	aspect := f32(event.width) / f32(event.height)
	new_matrix := common.create_view_projection_matrix(aspect)
	wgpu.queue_write_buffer(
		ctx.gpu.queue,
		ctx.uniform_buffer,
		0,
		wgpu.to_bytes(new_matrix),
	) or_return

	return true
}

draw :: proc(ctx: ^State_Context) -> bool {
	wgpu.render_pass_set_pipeline(ctx.gpu.render_pass, ctx.render_pipeline)
	wgpu.render_pass_set_bind_group(ctx.gpu.render_pass, 0, ctx.bind_group)
	wgpu.render_pass_set_vertex_buffer(ctx.gpu.render_pass, 0, ctx.vertex_buffer)
	wgpu.render_pass_draw(ctx.gpu.render_pass, {0, u32(len(vertex_data))})

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
		init   = init,
		quit   = quit,
		resize = resize,
		draw   = draw,
	}

	settings := rl.DEFAULT_SETTINGS
	settings.window.title = EXAMPLE_TITLE
	settings.window.resizable = true

	// Allow to create a depth framebuffer with the given format to be used during draw
	settings.renderer.use_depth_stencil = true
	settings.renderer.depth_format = DEPTH_FORMAT

	if ok := rl.init(state, settings); !ok do return

	rl.begin_run(state) // Start the main loop
}
