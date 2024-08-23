package microui_example

// STD Library
import "base:builtin"
@(require) import "core:log"

// Vendor
import mu "vendor:microui"

// Local packages
import wgpu "../../wrapper"
import wmu "./../../utils/microui"
import rl "./../../utils/renderlink"

State :: struct {
	mu_ctx          : ^mu.Context,
	log_buf         : [64000]u8,
	log_buf_len     : int,
	log_buf_updated : bool,
	bg              : mu.Color,
}

State_Context :: rl.Context(State)

EXAMPLE_TITLE :: "MicroUI Example"

init :: proc(ctx: ^State_Context) -> (ok: bool) {
	// Initialize the MicroUI renderer and context
	ctx.mu_ctx = wmu.init(ctx.gpu.device, ctx.gpu.queue, ctx.gpu.config) or_return

	// Set initial state
	ctx.bg = {56, 130, 210, 255}

	return true
}

quit :: proc(ctx: ^State_Context) {
	wmu.destroy()
	free(ctx.mu_ctx)
}

get_color_from_mu_color :: proc(color: mu.Color) -> wgpu.Color {
	return {f64(color.r) / 255.0, f64(color.g) / 255.0, f64(color.b) / 255.0, 1.0}
}

handle_events :: proc(event: rl.Event, ctx: ^State_Context) {
	rl.event_mu_set_event(ctx.mu_ctx, event)
}

resize :: proc(event: rl.Resize_Event, ctx: ^State_Context) -> bool {
	wmu.resize(i32(event.width), i32(event.height))
	return true
}

update :: proc(dt: f64, ctx: ^State_Context) -> bool {
	// UI definition and update
	mu.begin(ctx.mu_ctx)
	test_window(&ctx.state)
	log_window(&ctx.state)
	style_window(&ctx.state)
	mu.end(ctx.mu_ctx)

	rl.graphics_clear(get_color_from_mu_color(ctx.bg))

	return true
}

draw :: proc(ctx: ^State_Context) -> bool {
	// micro-ui rendering
	wmu.render(ctx.mu_ctx, ctx.gpu.render_pass) or_return
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

	if ok := rl.init(state, settings); !ok do return

	rl.begin_run(state) // Start the main loop
}
