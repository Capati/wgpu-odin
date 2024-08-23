package triangle_msaa_example

// STD Library
import "base:builtin"
import "base:runtime"
@(require) import "core:log"

// Local packages
import rl "./../../utils/renderlink"
import "./../../utils/shaders"
import wgpu "./../../wrapper"

State :: struct {
	render_pipeline: wgpu.Render_Pipeline,
}

State_Context :: rl.Context(State)

EXAMPLE_TITLE :: "Red Triangle 4x MSAA"
MSAA_COUNT: u32 : 4

init :: proc(ctx: ^State_Context) -> bool {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	// Use the same shader from the triangle example
	TRIANGLE_WGSL: string : #load("./../triangle/triangle.wgsl", string)
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
						blend = &wgpu.Blend_State_Normal,
						write_mask = wgpu.Color_Write_Mask_All,
					},
				},
			},
			multisample = {count = MSAA_COUNT, mask = max(u32)},
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
	settings.title = EXAMPLE_TITLE
	settings.resizable = true

	// Allow to create a multisampled framebuffer to be used during draw
	// Will fail if sample count is invalid or unsupported
	settings.renderer.sample_count = MSAA_COUNT

	if ok := rl.init(state, settings); !ok do return

	rl.begin_run(state) // Start the main loop
}
