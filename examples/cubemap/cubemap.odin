package cube_map_example

// STD Library
import "base:runtime"
import "base:builtin"
import "core:math"
import la "core:math/linalg"
import "core:time"
@(require) import "core:log"

// Local packages
import "../../utils/shaders"
import wgpu "../../wrapper"
import rl "./../../utils/renderlink"

State :: struct {
	// Buffers
	vertex_buffer      : wgpu.Buffer,
	index_buffer       : wgpu.Buffer,

	// Pipeline setup
	bind_group_layout  : wgpu.Bind_Group_Layout,
	render_pipeline    : wgpu.Render_Pipeline,

	// Texture and related resources
	cubemap_texture    : wgpu.Texture_Resource,

	// Uniform buffer and bind group
	uniform_buffer     : wgpu.Buffer,
	uniform_bind_group : wgpu.Bind_Group,

	// Other state variables
	aspect             : f32,
	projection_matrix  : la.Matrix4f32,
	model_matrix       : la.Matrix4f32,
	start_time         : time.Time,
}

State_Context :: rl.Context(State)

EXAMPLE_TITLE :: "Cubemap"
DEPTH_FORMAT :: wgpu.Texture_Format.Depth24_Plus

init :: proc(ctx: ^State_Context) -> (ok: bool) {
	ctx.vertex_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{
			label = EXAMPLE_TITLE + " Vertex Data",
			contents = wgpu.to_bytes(CUBE_VERTEX_DATA),
			usage = {.Vertex},
		},
	) or_return
	defer if !ok do wgpu.buffer_release(ctx.vertex_buffer)

	ctx.index_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		{
			label = EXAMPLE_TITLE + " Index Buffer",
			contents = wgpu.to_bytes(CUBE_INDICES_DATA),
			usage = {.Index},
		},
	) or_return
	defer if !ok do wgpu.buffer_release(ctx.index_buffer)

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	CUBEMAP_WGSL: string : #load("cubemap.wgsl", string)
	shader_source := shaders.apply_color_conversion(
		CUBEMAP_WGSL,
		ctx.gpu.is_srgb,
		context.temp_allocator,
	) or_return
	shader_module := wgpu.device_create_shader_module(
		ctx.gpu.device,
		{source = shader_source},
	) or_return
	defer wgpu.shader_module_release(shader_module)

	ctx.bind_group_layout = wgpu.device_create_bind_group_layout(
		ctx.gpu.device,
		wgpu.Bind_Group_Layout_Descriptor {
			label   = EXAMPLE_TITLE + " Bind group layout",
			entries = {
				{
					binding = 0,
					visibility = {.Vertex},
					type = wgpu.Buffer_Binding_Layout {
						type             = .Uniform,
						min_binding_size = size_of(la.Matrix4f32), // 4x4 matrix,
					},
				},
				{
					binding = 1,
					visibility = {.Fragment},
					type = wgpu.Sampler_Binding_Layout{type = .Filtering},
				},
				{
					binding = 2,
					visibility = {.Fragment},
					type = wgpu.Texture_Binding_Layout{sample_type = .Float, view_dimension = .Cube},
				},
			},
		},
	) or_return
	defer if !ok do wgpu.bind_group_layout_release(ctx.bind_group_layout)

	pipeline_layout := wgpu.device_create_pipeline_layout(
		ctx.gpu.device,
		{
			label = EXAMPLE_TITLE + " Pipeline bind group layout",
			bind_group_layouts = {ctx.bind_group_layout},
		},
	) or_return
	defer wgpu.pipeline_layout_release(pipeline_layout)

	attributes := wgpu.vertex_attr_array(2, {0, .Float32x4}, {1, .Float32x2})
	vertex_buffer_layout := wgpu.Vertex_Buffer_Layout {
		array_stride = size_of(Vertex),
		step_mode    = .Vertex,
		attributes   = attributes[:],
	}

	ctx.render_pipeline = wgpu.device_create_render_pipeline(
		ctx.gpu.device,
		descriptor = wgpu.Render_Pipeline_Descriptor {
			layout = pipeline_layout,
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
						blend = &wgpu.Blend_State_Normal,
						write_mask = wgpu.Color_Write_Mask_All,
					},
				},
			},
			primitive = {
				topology   = .Triangle_List,
				front_face = .CCW,
				// Since we are seeing from inside of the cube
				// and we are using the regular cube geomtry data with outward-facing normals,
				// the cullMode should be 'front' or 'none'.
				cull_mode  = .Front,
			},
			// Enable depth testing so that the fragment closest to the camera
			// is rendered in front.
			depth_stencil = &{
				depth_write_enabled = true,
				depth_compare = .Less,
				format = DEPTH_FORMAT,
				stencil_front = {compare = .Always},
				stencil_back = {compare = .Always},
				stencil_read_mask = 0xFFFFFFFF,
				stencil_write_mask = 0xFFFFFFFF,
			},
			multisample = wgpu.DEFAULT_MULTISAMPLE_STATE,
		},
	) or_return
	defer if !ok do wgpu.render_pipeline_release(ctx.render_pipeline)

	ctx.cubemap_texture = wgpu.queue_create_cubemap_texture(
		ctx.gpu.device,
		ctx.gpu.queue,
		{
			"./assets/cubemap/posx.jpg",
			"./assets/cubemap/negx.jpg",
			"./assets/cubemap/posy.jpg",
			"./assets/cubemap/negy.jpg",
			"./assets/cubemap/posz.jpg",
			"./assets/cubemap/negz.jpg",
		},
	) or_return
	defer if !ok do wgpu.texture_resource_release(ctx.cubemap_texture)

	ctx.uniform_buffer = wgpu.device_create_buffer(
		ctx.gpu.device,
		descriptor = wgpu.Buffer_Descriptor {
			label = EXAMPLE_TITLE + " Uniform Buffer",
			size  = size_of(la.Matrix4f32), // 4x4 matrix
			usage = {.Uniform, .Copy_Dst},
		},
	) or_return
	defer if !ok do wgpu.buffer_release(ctx.uniform_buffer)

	ctx.uniform_bind_group = wgpu.device_create_bind_group(
		ctx.gpu.device,
		{
			layout = ctx.bind_group_layout,
			entries = {
				{
					binding = 0,
					resource = wgpu.Buffer_Binding {
						buffer = ctx.uniform_buffer,
						size = wgpu.buffer_get_size(ctx.uniform_buffer),
					},
				},
				{binding = 1, resource = ctx.cubemap_texture.sampler},
				{binding = 2, resource = ctx.cubemap_texture.view},
			},
		},
	) or_return
	defer if !ok do wgpu.bind_group_release(ctx.uniform_bind_group)

	ctx.model_matrix = la.matrix4_scale_f32({1000.0, 1000.0, 1000.0})
	set_projection_matrix({ctx.gpu.config.width, ctx.gpu.config.height}, ctx)

	ctx.start_time = time.now()

	return true
}

quit :: proc(ctx: ^State_Context) {
	// Release bind group and related resources
	wgpu.bind_group_release(ctx.uniform_bind_group)
	wgpu.buffer_destroy(ctx.uniform_buffer)
	wgpu.buffer_release(ctx.uniform_buffer)

	// Release texture resources
	wgpu.texture_resource_release(ctx.cubemap_texture)

	// Release pipeline and related resources
	wgpu.render_pipeline_release(ctx.render_pipeline)
	wgpu.bind_group_layout_release(ctx.bind_group_layout)

	// Release buffer resources
	wgpu.buffer_destroy(ctx.index_buffer)
	wgpu.buffer_release(ctx.index_buffer)
	wgpu.buffer_destroy(ctx.vertex_buffer)
	wgpu.buffer_release(ctx.vertex_buffer)
}

set_projection_matrix :: proc(size: rl.Physical_Size, ctx: ^State_Context) {
	ctx.aspect = f32(ctx.gpu.config.width) / f32(ctx.gpu.config.height)
	ctx.projection_matrix = la.matrix4_perspective((2 * math.PI) / 5, ctx.aspect, 1, 3000.0)
}

get_transformation_matrix :: proc(ctx: ^State_Context) -> (mvp_mat: la.Matrix4f32) {
	now := f32(time.duration_seconds(time.since(ctx.start_time))) / 0.8

	rotation_x := la.quaternion_from_euler_angle_x_f32((math.PI / 10) * math.sin(now))
	rotation_y := la.quaternion_from_euler_angle_y_f32(now * 0.2)

	combined_rotation := la.quaternion_mul_quaternion(rotation_x, rotation_y)
	view_matrix := la.matrix4_from_quaternion_f32(combined_rotation)

	mvp_mat = la.matrix_mul(view_matrix, ctx.model_matrix)
	mvp_mat = la.matrix_mul(ctx.projection_matrix, mvp_mat)

	return
}

update :: proc(dt: f64, ctx: ^State_Context) -> bool {
	transformation_matrix := get_transformation_matrix(ctx)
	wgpu.queue_write_buffer(
		ctx.gpu.queue,
		ctx.uniform_buffer,
		0,
		wgpu.to_bytes(transformation_matrix),
	) or_return

	return true
}

draw :: proc(ctx: ^State_Context) -> bool {
	wgpu.render_pass_set_pipeline(ctx.gpu.render_pass, ctx.render_pipeline)
	wgpu.render_pass_set_vertex_buffer(ctx.gpu.render_pass, 0, ctx.vertex_buffer)
	wgpu.render_pass_set_index_buffer(ctx.gpu.render_pass, ctx.index_buffer, .Uint16)
	wgpu.render_pass_set_bind_group(ctx.gpu.render_pass, 0, ctx.uniform_bind_group)
	wgpu.render_pass_draw_indexed(ctx.gpu.render_pass, {0, u32(len(CUBE_INDICES_DATA))})
	return true
}

resize :: proc(event: rl.Resize_Event, ctx: ^State_Context) -> bool {
	set_projection_matrix({event.width, event.height}, ctx)
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
		update = update,
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
