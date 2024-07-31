package triangle_example

// STD Library
import "base:runtime"

// Local Packages
import rl "./../../utils/renderlink"
import "./../../utils/shaders"
import wgpu "./../../wrapper"

State :: struct {
	render_pipeline: wgpu.Render_Pipeline,
}

State_Context :: rl.Context(State)

EXAMPLE_TITLE :: "Red Triangle"

init :: proc(using ctx: ^State_Context) -> (err: rl.Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	TRIANGLE_WGSL: string : #load("./triangle.wgsl", string)
	shader_source := shaders.apply_color_conversion(
		TRIANGLE_WGSL,
		rl.graphics_is_srgb(),
		context.temp_allocator,
	) or_return
	shader_module := wgpu.device_create_shader_module(
		gpu.device,
		{label = EXAMPLE_TITLE + " Module", source = shader_source},
	) or_return
	defer wgpu.shader_module_release(shader_module)

	render_pipeline = wgpu.device_create_render_pipeline(
		gpu.device,
		{
			label = EXAMPLE_TITLE + " Render Pipeline",
			vertex = {module = shader_module.ptr, entry_point = "vs_main"},
			fragment = &{
				module = shader_module.ptr,
				entry_point = "fs_main",
				targets = {
					{
						format = gpu.config.format,
						blend = &wgpu.Blend_State_Replace,
						write_mask = wgpu.Color_Write_Mask_All,
					},
				},
			},
			multisample = wgpu.DEFAULT_MULTISAMPLE_STATE,
		},
	) or_return
	defer if err != nil do wgpu.render_pipeline_release(render_pipeline)

	rl.graphics_clear(rl.Color_Green)

	return
}

quit :: proc(using ctx: ^State_Context) {
	wgpu.render_pipeline_release(render_pipeline)
}

draw :: proc(using ctx: ^State_Context) -> (err: rl.Error) {
	wgpu.render_pass_set_pipeline(gpu.render_pass, render_pipeline.ptr)
	wgpu.render_pass_draw(gpu.render_pass, {0, 3})
	return
}

main :: proc() {
	state, state_err := new(State_Context)
	if state_err != nil do return
	defer free(state)

	state.callbacks = {
		init = init,
		quit = quit,
		draw = draw,
	}

	settings := rl.DEFAULT_SETTINGS
	settings.title = EXAMPLE_TITLE

	if err := rl.init(state, settings); err != nil do return

	rl.begin_run(state) // Start the main loop
}
