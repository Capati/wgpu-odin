package triangle_msaa

// Core
import "core:fmt"

// Package
import wgpu "../../wrapper"

// Framework
import app "../framework/application"
import "../framework/application/events"
import "../framework/renderer"

MSAA_Count :: 4

State :: struct {
	gpu:                      ^renderer.Renderer,
	render_pipeline:          wgpu.Render_Pipeline,
	multisampled_framebuffer: wgpu.Texture_View,
}

Error :: union #shared_nil {
	app.Application_Error,
	renderer.Renderer_Error,
	wgpu.Error_Type,
}

init_example :: proc() -> (state: State, err: Error) {
	state.gpu = renderer.init() or_return
	defer if err != nil do renderer.deinit(state.gpu)

	// Use the same shader from the triangle example
	shader_source := #load("./../triangle/triangle.wgsl")
	shader_module := wgpu.device_create_shader_module(
		&state.gpu.device,
		&{label = "Red triangle module", source = cstring(raw_data(shader_source))},
	) or_return
	defer wgpu.shader_module_release(&shader_module)

	state.render_pipeline = wgpu.device_create_render_pipeline(
		&state.gpu.device,
		& {
			label = "Render Pipeline",
			vertex = {module = &shader_module, entry_point = "vs"},
			fragment = & {
				module = &shader_module,
				entry_point = "fs",
				targets =  {
					 {
						format = state.gpu.config.format,
						blend = &wgpu.Blend_State_Replace,
						write_mask = wgpu.Color_Write_Mask_All,
					},
				},
			},
			multisample = {count = MSAA_Count, mask = ~u32(0), alpha_to_coverage_enabled = false},
		},
	) or_return
	defer if err != nil do wgpu.render_pipeline_release(&state.render_pipeline)

	state.multisampled_framebuffer = get_multisampled_framebuffer(
		state.gpu,
		{state.gpu.config.width, state.gpu.config.height},
	) or_return

	return
}

render :: proc(using state: ^State) -> (err: Error) {
	frame := renderer.get_current_texture_frame(gpu) or_return
	defer wgpu.texture_release(&frame.texture)
	if gpu.skip_frame do return

	view := wgpu.texture_create_view(&frame.texture, nil) or_return
	defer wgpu.texture_view_release(&view)

	encoder := wgpu.device_create_command_encoder(&gpu.device) or_return
	defer wgpu.command_encoder_release(&encoder)

	render_pass := wgpu.command_encoder_begin_render_pass(
		&encoder,
		& {
			label = "Render Pass",
			color_attachments = []wgpu.Render_Pass_Color_Attachment {
				 {
					view = &multisampled_framebuffer,
					resolve_target = &view,
					load_op = .Clear,
					store_op = .Store,
					clear_value = wgpu.Color_Green,
				},
			},
			depth_stencil_attachment = nil,
		},
	)
	defer wgpu.render_pass_release(&render_pass)

	wgpu.render_pass_set_pipeline(&render_pass, &render_pipeline)
	wgpu.render_pass_draw(&render_pass, 3)
	wgpu.render_pass_end(&render_pass) or_return

	command_buffer := wgpu.command_encoder_finish(&encoder) or_return
	defer wgpu.command_buffer_release(&command_buffer)

	wgpu.queue_submit(&gpu.queue, &command_buffer)
	wgpu.surface_present(&gpu.surface)

	return
}

resize_surface :: proc(using state: ^State, size: app.Physical_Size) -> (err: Error) {
	wgpu.texture_view_release(&multisampled_framebuffer)
	multisampled_framebuffer = get_multisampled_framebuffer(
		gpu,
		{size.width, size.height},
	) or_return

	renderer.resize_surface(gpu, {size.width, size.height}) or_return

	return
}

main :: proc() {
	app_properties := app.Default_Properties
	app_properties.title = "Triangle 4x MSAA"
	if app.init(app_properties) != .No_Error do return
	defer app.deinit()

	state, state_err := init_example()
	if state_err != nil do return
	defer renderer.deinit(state.gpu)

	fmt.printf("Entering main loop...\n\n")

	main_loop: for {
		iter := app.process_events()

		for iter->has_next() {
			#partial switch event in iter->next() {
			case events.Quit_Event:
				break main_loop
			case events.Framebuffer_Resize_Event:
				if err := resize_surface(&state, {event.width, event.height}); err != nil {
					fmt.eprintf(
						"Error occurred while resizing [%v]: %v\n",
						err,
						wgpu.get_error_message(),
					)
					break main_loop
				}
			}
		}

		if err := render(&state); err != nil {
			fmt.eprintf("Error occurred while rendering [%v]: %v\n", err, wgpu.get_error_message())
			break main_loop
		}
	}

	// deinit state
	wgpu.texture_view_release(&state.multisampled_framebuffer)
	wgpu.render_pipeline_release(&state.render_pipeline)

	fmt.println("Exiting...")
}

get_multisampled_framebuffer :: proc(
	gpu: ^renderer.Renderer,
	size: app.Physical_Size,
) -> (
	view: wgpu.Texture_View,
	err: wgpu.Error_Type,
) {
	texture := wgpu.device_create_texture(
		&gpu.device,
		& {
			usage = {.Render_Attachment},
			dimension = .D2,
			size = {width = size.width, height = size.height, depth_or_array_layers = 1},
			format = gpu.config.format,
			mip_level_count = 1,
			sample_count = MSAA_Count,
		},
	) or_return
	defer wgpu.texture_release(&texture)

	return wgpu.texture_create_view(&texture, nil)
}
