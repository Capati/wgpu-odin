package triangle_example

// STD Library
import "base:builtin"
import "base:runtime"
@(require) import "core:log"

// Local packages
import "./../../utils/shaders"
import rl "./../../utils/renderlink"
import wgpu "./../../wrapper"

State :: struct {
	render_pipeline: wgpu.Render_Pipeline,
}

State_Context :: rl.Context(State)

EXAMPLE_TITLE :: "Red Triangle"

init :: proc(ctx: ^State_Context) -> (ok: bool) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	TRIANGLE_WGSL: string : #load("./triangle.wgsl", string)
	shader_source := shaders.apply_color_conversion(
		TRIANGLE_WGSL,
		ctx.gpu.is_srgb,
		context.temp_allocator,
	) or_return
	shader_module := wgpu.device_create_shader_module(
		ctx.gpu.device,
		{label = EXAMPLE_TITLE + " Module", source = shader_source},
	) or_return
	defer wgpu.shader_module_release(shader_module)

	ctx.render_pipeline = wgpu.device_create_render_pipeline(
		ctx.gpu.device,
		{
			label = EXAMPLE_TITLE + " Render Pipeline",
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
			multisample = wgpu.DEFAULT_MULTISAMPLE_STATE,
		},
	) or_return

	rl.graphics_clear(rl.Color_Green)

	return true
}

quit :: proc(ctx: ^State_Context) {
	wgpu.render_pipeline_release(ctx.render_pipeline)
}

draw :: proc(ctx: ^State_Context) -> bool {
	wgpu.render_pass_set_pipeline(ctx.gpu.render_pass, ctx.render_pipeline)
	wgpu.render_pass_draw(ctx.gpu.render_pass, {0, 3})
	return true // keep ticking...
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
	settings.title = EXAMPLE_TITLE

	settings.gpu.required_features = {.Pipeline_Statistics_Query}

	if ok := rl.init(state, settings); !ok do return

	rl.begin_run(state) // Start the main loop
}
