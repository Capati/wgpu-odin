package microui_example

// Vendor
import mu "vendor:microui"

// Package
import wgpu "../../wrapper"
import wmu "./../../utils/microui"
import rl "./../../utils/renderlink"

State :: struct {
	mu_ctx:          ^mu.Context,
	log_buf:         [64000]u8,
	log_buf_len:     int,
	log_buf_updated: bool,
	bg:              mu.Color,
}

App_Context :: rl.Context(State)

EXAMPLE_TITLE :: "MicroUI Example"

init :: proc(using ctx: ^App_Context) -> (err: rl.Error) {
	// Initialize the MicroUI renderer and context
	mu_ctx = wmu.init(gpu.device, gpu.queue, gpu.surface.config) or_return

	// Set initial state
	bg = {56, 130, 210, 255}

	return
}

quit :: proc(using ctx: ^App_Context) {
	wmu.destroy()
	free(mu_ctx)
}

get_color_from_mu_color :: proc(color: mu.Color) -> wgpu.Color {
	return {f64(color.r) / 255.0, f64(color.g) / 255.0, f64(color.b) / 255.0, 1.0}
}

handle_events :: proc(event: rl.Event, using ctx: ^App_Context) {
	rl.event_mu_set_event(mu_ctx, event)
}

resize :: proc(event: rl.Resize_Event, using ctx: ^App_Context) -> (err: rl.Error) {
	wmu.resize(i32(event.width), i32(event.height))
	return
}

update :: proc(dt: f64, using ctx: ^App_Context) -> (err: rl.Error) {
	// UI definition and update
	mu.begin(mu_ctx)
	test_window(&ctx.state)
	log_window(&ctx.state)
	style_window(&ctx.state)
	mu.end(mu_ctx)

	rl.graphics_clear(get_color_from_mu_color(bg))

	return
}

draw :: proc(using ctx: ^App_Context) -> (err: rl.Error) {
	// micro-ui rendering
	wmu.render(mu_ctx, gpu.render_pass) or_return
	return
}

main :: proc() {
	state, state_err := new(App_Context)
	if state_err != nil do return
	defer free(state)

	state.callbacks = {
		init          = init,
		quit          = quit,
		resize        = resize,
		handle_events = handle_events,
		update        = update,
		draw          = draw,
	}

	settings := rl.DEFAULT_SETTINGS
	settings.title = EXAMPLE_TITLE
	settings.gpu.desired_maximum_frame_latency = 1 // XXX

	if err := rl.init(state, settings); err != nil do return

	rl.begin_run(state) // Start the main loop
}
