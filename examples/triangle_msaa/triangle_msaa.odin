package triangle_msaa

// Core
import "core:fmt"

// Package
import wgpu "../../wrapper"
import "./../../utils/shaders"
import "./../common"

// Framework
import app "../framework/application"
import "../framework/application/events"
import "../framework/renderer"

MSAA_COUNT :: 4

State :: struct {
	using _:                  common.State_Base,
	render_pipeline:          wgpu.Render_Pipeline,
	multisampled_framebuffer: wgpu.Texture_View,
}

Error :: common.Error

EXAMPLE_TITLE :: "Triangle 4x MSAA"

init :: proc() -> (state: ^State, err: Error) {
	state = new(State) or_return
	defer if err != nil do free(state)

	app_properties := app.Default_Properties
	app_properties.title = EXAMPLE_TITLE
	app.init(app_properties) or_return
	defer if err != nil do app.deinit()

	state.gpu = renderer.init() or_return
	defer if err != nil do renderer.deinit(state)

	// Use the same shader from the triangle example
	SHADER_SRC: string : #load("./../triangle/triangle.wgsl", string)
	COMBINED_SHADER_SRC := shaders.SRGB_TO_LINEAR_WGSL + SHADER_SRC
	shader_module := wgpu.device_create_shader_module(
		&state.device,
		&{label = EXAMPLE_TITLE + " Module", source = COMBINED_SHADER_SRC},
	) or_return
	defer wgpu.shader_module_release(&shader_module)

	state.render_pipeline = wgpu.device_create_render_pipeline(
		&state.device,
		&{
			label = EXAMPLE_TITLE + " Render Pipeline",
			vertex = {module = shader_module.ptr, entry_point = "vs_main"},
			fragment = &{
				module = shader_module.ptr,
				entry_point = "fs_main",
				targets = {
					{
						format = state.config.format,
						blend = &wgpu.Blend_State_Replace,
						write_mask = wgpu.Color_Write_Mask_All,
					},
				},
			},
			multisample = {count = MSAA_COUNT, mask = ~u32(0)},
		},
	) or_return
	defer if err != nil do wgpu.render_pipeline_release(&state.render_pipeline)

	state.multisampled_framebuffer = get_multisampled_framebuffer(
		state,
		{state.config.width, state.config.height},
	) or_return
	defer if err != nil do wgpu.texture_view_release(&state.multisampled_framebuffer)

	state.render_pass_desc = common.create_render_pass_descriptor(
		EXAMPLE_TITLE + " Render Pass",
		wgpu.color_srgb_to_linear(wgpu.Color_Green),
	) or_return

	// Get a reference to the first color attachment
	state.color_attachment = &state.render_pass_desc.color_attachments[0]
	state.color_attachment.view = state.multisampled_framebuffer.ptr

	return
}

deinit :: proc(using state: ^State) {
	delete(render_pass_desc.color_attachments)
	wgpu.texture_view_release(&state.multisampled_framebuffer)
	wgpu.render_pipeline_release(&state.render_pipeline)
	renderer.deinit(state)
	app.deinit()
	free(state)
}

get_multisampled_framebuffer :: proc(
	using gpu: ^renderer.Renderer,
	size: app.Physical_Size,
) -> (
	view: wgpu.Texture_View,
	err: wgpu.Error,
) {
	texture := wgpu.device_create_texture(
		&device,
		&{
			usage = {.Render_Attachment},
			dimension = .D2,
			size = {width = size.width, height = size.height, depth_or_array_layers = 1},
			format = config.format,
			mip_level_count = 1,
			sample_count = MSAA_COUNT,
		},
	) or_return
	defer wgpu.texture_release(&texture)

	return wgpu.texture_create_view(&texture)
}

render :: proc(using state: ^State) -> (err: Error) {
	frame := renderer.get_current_texture_frame(gpu) or_return
	if skip_frame do return
	defer wgpu.texture_release(&frame.texture)

	view := wgpu.texture_create_view(&frame.texture) or_return
	defer wgpu.texture_view_release(&view)

	encoder := wgpu.device_create_command_encoder(&device) or_return
	defer wgpu.command_encoder_release(&encoder)

	color_attachment.resolve_target = view.ptr
	render_pass := wgpu.command_encoder_begin_render_pass(&encoder, &render_pass_desc)
	defer wgpu.render_pass_encoder_release(&render_pass)

	wgpu.render_pass_encoder_set_pipeline(&render_pass, render_pipeline.ptr)
	wgpu.render_pass_encoder_draw(&render_pass, 3)
	wgpu.render_pass_encoder_end(&render_pass) or_return

	command_buffer := wgpu.command_encoder_finish(&encoder) or_return
	defer wgpu.command_buffer_release(&command_buffer)

	wgpu.queue_submit(&queue, command_buffer.ptr)
	wgpu.surface_present(&surface)

	return
}

resize_surface :: proc(using state: ^State, size: app.Physical_Size) -> (err: Error) {
	wgpu.texture_view_release(&multisampled_framebuffer)
	multisampled_framebuffer = get_multisampled_framebuffer(gpu, size) or_return
	color_attachment.view = multisampled_framebuffer.ptr

	renderer.resize_surface(gpu, size) or_return

	return
}

handle_events :: proc(state: ^State) -> (should_quit: bool, err: Error) {
	event: events.Event
	for app.poll_event(&event) {
		#partial switch &ev in event {
		case events.Quit_Event:
			return true, nil
		case events.Framebuffer_Resize_Event:
			if err = resize_surface(state, {ev.width, ev.height}); err != nil {
				return true, err
			}
		}
	}

	return
}

main :: proc() {
	state, state_err := init()
	if state_err != nil do return
	defer deinit(state)

	fmt.printf("Entering main loop...\n\n")

	main_loop: for {
		should_quit, err := handle_events(state)
		if should_quit || err != nil do break main_loop
		if err = render(state); err != nil do break main_loop
	}

	fmt.println("Exiting...")
}
