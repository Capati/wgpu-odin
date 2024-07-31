package tutorial3_pipeline

// STD Library
import "base:runtime"

// Local Packages
import "../../../../utils/shaders"
import wgpu "../../../../wrapper"
import rl "./../../../../utils/renderlink"

State :: struct {
	render_pipeline: wgpu.Render_Pipeline,
}

App_Context :: rl.Context(State)

EXAMPLE_TITLE :: "Tutorial 3 - Pipeline"

init :: proc(using ctx: ^App_Context) -> (err: rl.Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	SHADER_WGSL: string : #load("./shader.wgsl", string)
	shader_source := shaders.apply_color_conversion(
		SHADER_WGSL,
		gpu.is_srgb,
		context.temp_allocator,
	) or_return
	shader_module := wgpu.device_create_shader_module(
		gpu.device,
		{source = shader_source},
	) or_return
	defer wgpu.shader_module_release(shader_module)

	render_pipeline_layout := wgpu.device_create_pipeline_layout(
		gpu.device,
		{label = EXAMPLE_TITLE + " Layout"},
	) or_return
	defer wgpu.pipeline_layout_release(render_pipeline_layout)

	render_pipeline_descriptor := wgpu.Render_Pipeline_Descriptor {
		label = EXAMPLE_TITLE + " Render Pipeline",
		layout = render_pipeline_layout.ptr,
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
		primitive = {topology = .Triangle_List, front_face = .CCW, cull_mode = .Back},
		depth_stencil = nil,
		multisample = {count = 1, mask = ~u32(0), alpha_to_coverage_enabled = false},
	}

	state.render_pipeline = wgpu.device_create_render_pipeline(
		gpu.device,
		render_pipeline_descriptor,
	) or_return

	rl.graphics_clear(rl.Color{0.1, 0.2, 0.3, 1.0})

	return
}

quit :: proc(using ctx: ^App_Context) {
	wgpu.render_pipeline_release(state.render_pipeline)
}

draw :: proc(using ctx: ^App_Context) -> (err: rl.Error) {
	wgpu.render_pass_set_pipeline(gpu.render_pass, state.render_pipeline.ptr)
	wgpu.render_pass_draw(gpu.render_pass, {0, 3})
	return
}

main :: proc() {
	state, state_err := new(App_Context)
	if state_err != nil do return
	defer free(state)

	state.callbacks = {
		init = init,
		quit = quit,
		draw = draw,
	}

	settings := rl.DEFAULT_SETTINGS
	settings.window.title = EXAMPLE_TITLE

	if err := rl.init(state, settings); err != nil do return

	rl.begin_run(state) // Start the main loop
}
