package tutorial3_pipeline_challenge

// STD Library
import "base:runtime"
import "base:builtin"
@(require) import "core:log"

// Local Packages
import "../../../../utils/shaders"
import wgpu "../../../../wrapper"
import rl "./../../../../utils/renderlink"

State :: struct {
	render_pipeline           : wgpu.Render_Pipeline,
	challenge_render_pipeline : wgpu.Render_Pipeline,
}

State_Context :: rl.Context(State)

EXAMPLE_TITLE :: "Tutorial 3 - Pipeline Challenge"

init :: proc(ctx: ^State_Context) -> (ok: bool) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	// Use the same shader from the Tutorial 3 - Pipeline
	SHADER_WGSL: string : #load("./../tutorial3_pipeline/shader.wgsl", string)
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

	render_pipeline_descriptor := wgpu.Render_Pipeline_Descriptor {
		label = EXAMPLE_TITLE + " Render Pipeline",
		layout = render_pipeline_layout,
		vertex = {module = shader_module, entry_point = "vs_main"},
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

	CHALLENGE_SHADER_SRC: string : #load("./challenge.wgsl", string)
	COMBINED_CHALLENGE_SHADER_SRC :: shaders.SRGB_TO_LINEAR_WGSL + CHALLENGE_SHADER_SRC
	challenge_shader_module := wgpu.device_create_shader_module(
		ctx.gpu.device,
		{source = COMBINED_CHALLENGE_SHADER_SRC},
	) or_return
	defer wgpu.shader_module_release(challenge_shader_module)

	challenge_render_pipeline_descriptor := wgpu.Render_Pipeline_Descriptor {
		label = EXAMPLE_TITLE + " Challenge Render Pipeline",
		layout = render_pipeline_layout,
		vertex = {module = challenge_shader_module, entry_point = "vs_main"},
		fragment = &{
			module = challenge_shader_module,
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

	ctx.challenge_render_pipeline = wgpu.device_create_render_pipeline(
		ctx.gpu.device,
		challenge_render_pipeline_descriptor,
	) or_return

	rl.graphics_clear(rl.Color{0.1, 0.2, 0.3, 1.0})

	return true
}

quit :: proc(ctx: ^State_Context) {
	wgpu.render_pipeline_release(ctx.challenge_render_pipeline)
	wgpu.render_pipeline_release(ctx.render_pipeline)
}

draw :: proc(ctx: ^State_Context) -> bool {
	if rl.keyboard_is_down(.Space) {
		wgpu.render_pass_set_pipeline(ctx.gpu.render_pass, ctx.challenge_render_pipeline)
	} else {
		wgpu.render_pass_set_pipeline(ctx.gpu.render_pass, ctx.render_pipeline)
	}

	wgpu.render_pass_draw(ctx.gpu.render_pass, {0, 3})

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
