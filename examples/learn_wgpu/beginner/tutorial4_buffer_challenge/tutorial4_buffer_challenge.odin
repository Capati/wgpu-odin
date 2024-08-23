package tutorial4_buffer_challenge

// STD Library
import "base:builtin"
import "base:runtime"
import "core:math"
@(require) import "core:log"

// Local Packages
import "../../../../utils/shaders"
import wgpu "../../../../wrapper"
import rl "./../../../../utils/renderlink"

Vertex :: struct {
	position : [3]f32,
	color    : [3]f32,
}

State :: struct {
	render_pipeline         : wgpu.Render_Pipeline,
	vertex_buffer           : wgpu.Buffer,
	index_buffer            : wgpu.Buffer,
	num_indices             : u32,
	num_challenge_indices   : u32,
	challenge_vertex_buffer : wgpu.Buffer,
	challenge_index_buffer  : wgpu.Buffer,
	use_complex             : bool,
}

State_Context :: rl.Context(State)

EXAMPLE_TITLE :: "Tutorial 4 - Buffers"

init :: proc(ctx: ^State_Context) -> (ok: bool) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	// Use the same shader from the Tutorial 4 - Buffers
	SHADER_WGSL: string : #load("./../tutorial4_buffer/shader.wgsl", string)
	shader_source := shaders.apply_color_conversion(
		SHADER_WGSL,
		ctx.gpu.is_srgb,
		context.temp_allocator,
	) or_return
	shader_module := wgpu.device_create_shader_module(
		ctx.gpu.device,
		{source = shader_source},
	) or_return
	defer wgpu.shader_module_release(shader_module)

	render_pipeline_layout := wgpu.device_create_pipeline_layout(
		ctx.gpu.device,
		{label = EXAMPLE_TITLE + " Render Pipeline Layout"},
	) or_return
	defer wgpu.pipeline_layout_release(render_pipeline_layout)

	vertex_buffer_layout := wgpu.Vertex_Buffer_Layout {
		array_stride = size_of(Vertex),
		step_mode    = .Vertex,
		attributes   = {
			{offset = 0, shader_location = 0, format = .Float32x3},
			{offset = cast(u64)offset_of(Vertex, color), shader_location = 1, format = .Float32x3},
		},
	}

	render_pipeline_descriptor := wgpu.Render_Pipeline_Descriptor {
		label = EXAMPLE_TITLE + " Render Pipeline",
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

	// vertices := []Vertex{
	//     {position = {0.0, 0.5, 0.0}, color = {1.0, 0.0, 0.0}},
	//     {position = {-0.5, -0.5, 0.0}, color = {0.0, 1.0, 0.0}},
	//     {position = {0.5, -0.5, 0.0}, color = {0.0, 0.0, 1.0}},
	// }

	vertices := []Vertex {
		{position = {-0.0868241, 0.49240386, 0.0}, color = {0.5, 0.0, 0.5}}, // A
		{position = {-0.49513406, 0.06958647, 0.0}, color = {0.5, 0.0, 0.5}}, // B
		{position = {-0.21918549, -0.44939706, 0.0}, color = {0.5, 0.0, 0.5}}, // C
		{position = {0.35966998, -0.3473291, 0.0}, color = {0.5, 0.0, 0.5}}, // D
		{position = {0.44147372, 0.2347359, 0.0}, color = {0.5, 0.0, 0.5}}, // E
	}

	indices: []u16 = {0, 1, 4, 1, 2, 4, 2, 3, 4}

	// num_vertices = cast(u32)len(vertices)
	ctx.num_indices = cast(u32)len(indices)

	ctx.vertex_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		wgpu.Buffer_Data_Descriptor {
			label = EXAMPLE_TITLE + " Vertex Buffer",
			contents = wgpu.to_bytes(vertices),
			usage = {.Vertex},
		},
	) or_return
	defer if !ok do wgpu.buffer_release(ctx.vertex_buffer)

	ctx.index_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		wgpu.Buffer_Data_Descriptor {
			label = EXAMPLE_TITLE + " Index Buffer",
			contents = wgpu.to_bytes(indices),
			usage = {.Index},
		},
	) or_return
	defer if !ok do wgpu.buffer_release(ctx.index_buffer)

	num_vertices :: 100
	angle := math.PI * 2.0 / f32(num_vertices)
	challenge_verts: [num_vertices]Vertex

	for i := 0; i < num_vertices; i += 1 {
		theta := angle * f32(i)
		theta_sin, theta_cos := math.sincos_f64(f64(theta))

		challenge_verts[i] = Vertex {
			position = {0.5 * f32(theta_cos), -0.5 * f32(theta_sin), 0.0},
			color    = {(1.0 + f32(theta_cos)) / 2.0, (1.0 + f32(theta_sin)) / 2.0, 1.0},
		}
	}

	num_triangles :: num_vertices - 2
	challenge_indices: [num_triangles * 3]u16
	{
		index := 0
		for i := u16(1); i < num_triangles + 1; i += 1 {
			challenge_indices[index] = i + 1
			challenge_indices[index + 1] = i
			challenge_indices[index + 2] = 0
			index += 3
		}
	}

	ctx.num_challenge_indices = cast(u32)len(challenge_indices)

	ctx.challenge_vertex_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		wgpu.Buffer_Data_Descriptor {
			label = EXAMPLE_TITLE + " Vertex Buffer",
			contents = wgpu.to_bytes(challenge_verts[:]),
			usage = {.Vertex},
		},
	) or_return
	defer if !ok do wgpu.buffer_release(ctx.challenge_vertex_buffer)

	ctx.challenge_index_buffer = wgpu.device_create_buffer_with_data(
		ctx.gpu.device,
		wgpu.Buffer_Data_Descriptor {
			label = EXAMPLE_TITLE + " Index Buffer",
			contents = wgpu.to_bytes(challenge_indices[:]),
			usage = {.Index},
		},
	) or_return

	rl.graphics_clear(rl.Color{0.1, 0.2, 0.3, 1.0})

	return true
}

quit :: proc(ctx: ^State_Context) {
	wgpu.buffer_release(ctx.challenge_index_buffer)
	wgpu.buffer_release(ctx.challenge_vertex_buffer)
	wgpu.buffer_release(ctx.index_buffer)
	wgpu.buffer_release(ctx.vertex_buffer)
	wgpu.render_pipeline_release(ctx.render_pipeline)
}

draw :: proc(ctx: ^State_Context) -> bool {
	wgpu.render_pass_set_pipeline(ctx.gpu.render_pass, ctx.render_pipeline)

	if rl.keyboard_is_down(.Space) {
		wgpu.render_pass_set_vertex_buffer(ctx.gpu.render_pass, 0, ctx.challenge_vertex_buffer)
		wgpu.render_pass_set_index_buffer(ctx.gpu.render_pass, ctx.challenge_index_buffer, .Uint16)
		wgpu.render_pass_draw_indexed(ctx.gpu.render_pass, {0, ctx.num_challenge_indices})
	} else {
		wgpu.render_pass_set_vertex_buffer(ctx.gpu.render_pass, 0, ctx.vertex_buffer)
		wgpu.render_pass_set_index_buffer(ctx.gpu.render_pass, ctx.index_buffer, .Uint16)
		wgpu.render_pass_draw_indexed(ctx.gpu.render_pass, {0, ctx.num_indices})
	}

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
		init = init,
		quit = quit,
		draw = draw,
	}

	settings := rl.DEFAULT_SETTINGS
	settings.window.title = EXAMPLE_TITLE

	if ok := rl.init(state, settings); !ok do return

	rl.begin_run(state) // Start the main loop
}
