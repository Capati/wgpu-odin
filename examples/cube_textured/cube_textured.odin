package cube_textured

// STD Library
import "base:builtin"
import "base:runtime"
import "core:math"
import la "core:math/linalg"
@(require) import "core:log"

// Local packages
import rl "./../../utils/renderlink"
import "./../../utils/shaders"
import wgpu "./../../wrapper"

State :: struct {
	vertex_buffer   : wgpu.Buffer,
	index_buffer    : wgpu.Buffer,
	uniform_buffer  : wgpu.Buffer,
	render_pipeline : wgpu.Render_Pipeline,
	bind_group      : wgpu.Bind_Group,
}

State_Context :: rl.Context(State)

EXAMPLE_TITLE :: "Textured Cube"
TEXEL_SIZE    :: 256

init :: proc(ctx: ^State_Context) -> (ok: bool) {
	ctx.vertex_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{
			label    = EXAMPLE_TITLE + " Vertex Buffer",
			contents = wgpu.to_bytes(vertex_data),
			usage    = {.Vertex},
		},
	) or_return
	defer if !ok do wgpu.buffer_release(ctx.vertex_buffer)

	ctx.index_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{
			label    = EXAMPLE_TITLE + " Index Buffer",
			contents = wgpu.to_bytes(index_data),
			usage    = {.Index},
		},
	) or_return
	defer if !ok do wgpu.buffer_release(ctx.index_buffer)

	texture_extent := wgpu.Extent_3D {
		width                 = TEXEL_SIZE,
		height                = TEXEL_SIZE,
		depth_or_array_layers = 1,
	}

	texture := wgpu.device_create_texture(
		ctx.gpu.device,
		{
			size            = texture_extent,
			mip_level_count = 1,
			sample_count    = 1,
			dimension       = .D2,
			format          = .R8_Uint,
			usage           = {.Texture_Binding, .Copy_Dst},
		},
	) or_return
	defer wgpu.texture_release(texture)

	texture_view := wgpu.texture_create_view(texture) or_return
	defer wgpu.texture_view_release(texture_view)

	texels := create_texels()

	wgpu.queue_write_texture(
		ctx.gpu.queue,
		{texture = texture, mip_level = 0, origin = {}, aspect = .All},
		wgpu.to_bytes(texels),
		{offset = 0, bytes_per_row = TEXEL_SIZE, rows_per_image = wgpu.COPY_STRIDE_UNDEFINED},
		texture_extent,
	) or_return

	mx_total := create_view_projection_matrix(
		cast(f32)ctx.gpu.config.width / cast(f32)ctx.gpu.config.height,
	)

	ctx.uniform_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{
			label    = EXAMPLE_TITLE + " Uniform Buffer",
			contents = wgpu.to_bytes(mx_total),
			usage    = {.Uniform, .Copy_Dst},
		},
	) or_return
	defer if !ok do wgpu.buffer_release(ctx.uniform_buffer)

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	CUBE_TEXTURED_WGSL: string : #load("./cube_textured.wgsl", string)
	shader_source := shaders.apply_color_conversion(
		CUBE_TEXTURED_WGSL,
		ctx.gpu.is_srgb,
		context.temp_allocator,
	) or_return
	shader_module := wgpu.device_create_shader_module(
		ctx.gpu.device,
		{label = EXAMPLE_TITLE + " Module", source = shader_source},
	) or_return
	defer wgpu.shader_module_release(shader_module)

	vertex_buffer_layout := wgpu.Vertex_Buffer_Layout {
		array_stride = size_of(Vertex),
		step_mode    = .Vertex,
		attributes   = {
			{format = .Float32x4, offset = 0, shader_location = 0},
			{
				format = .Float32x2,
				offset = cast(u64)offset_of(Vertex, tex_coords),
				shader_location = 1,
			},
		},
	}

	ctx.render_pipeline = wgpu.device_create_render_pipeline(
		ctx.gpu.device,
		{
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
						blend = nil,
						write_mask = wgpu.Color_Write_Mask_All,
					},
				},
			},
			primitive = {topology = .Triangle_List, front_face = .CCW, cull_mode = .Back},
			multisample = wgpu.DEFAULT_MULTISAMPLE_STATE,
		},
	) or_return
	defer if !ok do wgpu.render_pipeline_release(ctx.render_pipeline)

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
				{binding = 1, resource = texture_view},
			},
		},
	) or_return
	defer if !ok do wgpu.bind_group_release(ctx.bind_group)

	rl.graphics_clear(rl.Color{0.1, 0.2, 0.3, 1.0})

	return true
}

quit :: proc(ctx: ^State_Context) {
	wgpu.bind_group_release(ctx.bind_group)
	wgpu.render_pipeline_release(ctx.render_pipeline)
	wgpu.buffer_release(ctx.uniform_buffer)
	wgpu.buffer_release(ctx.index_buffer)
	wgpu.buffer_release(ctx.vertex_buffer)
}

create_texels :: proc() -> (texels: [TEXEL_SIZE * TEXEL_SIZE]u8) {
	for id := 0; id < (TEXEL_SIZE * TEXEL_SIZE); id += 1 {
		cx := 3.0 * f32(id % TEXEL_SIZE) / f32(TEXEL_SIZE - 1) - 2.0
		cy := 2.0 * f32(id / TEXEL_SIZE) / f32(TEXEL_SIZE - 1) - 1.0
		x, y, count := f32(cx), f32(cy), u8(0)
		for count < 0xFF && x * x + y * y < 4.0 {
			old_x := x
			x = x * x - y * y + cx
			y = 2.0 * old_x * y + cy
			count += 1
		}
		texels[id] = count
	}

	return
}

create_view_projection_matrix :: proc(aspect: f32) -> la.Matrix4f32 {
	projection := la.matrix4_perspective_f32(math.PI / 4, aspect, 1.0, 10.0)
	view := la.matrix4_look_at_f32(
		eye = {1.5, -5.0, 3.0},
		centre = {0.0, 0.0, 0.0},
		up = {0.0, 0.0, 1.0},
	)
	return la.mul(projection, view)
}

resize :: proc(event: rl.Resize_Event, ctx: ^State_Context) -> bool {
	wgpu.queue_write_buffer(
		ctx.gpu.queue,
		ctx.uniform_buffer,
		0,
		wgpu.to_bytes(create_view_projection_matrix(f32(event.width) / f32(event.height))),
	) or_return

	return true
}

draw :: proc(ctx: ^State_Context) -> bool {
	wgpu.render_pass_set_pipeline(ctx.gpu.render_pass, ctx.render_pipeline)
	wgpu.render_pass_set_bind_group(ctx.gpu.render_pass, 0, ctx.bind_group)
	wgpu.render_pass_set_vertex_buffer(ctx.gpu.render_pass, 0, ctx.vertex_buffer)
	wgpu.render_pass_set_index_buffer(ctx.gpu.render_pass, ctx.index_buffer, .Uint16)
	wgpu.render_pass_draw_indexed(ctx.gpu.render_pass, {0, u32(len(index_data))}, 0)

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

	if ok := rl.init(state, settings); !ok do return

	rl.begin_run(state) // Start the main loop
}
