package tutorial2_surface_challenge

// STD Library
import "base:builtin"
@(require) import "core:log"

// Local packages
import rl "./../../../../utils/renderlink"

State :: struct {
	clear_color: rl.Color,
}

State_Context :: rl.Context(State)

EXAMPLE_TITLE :: "Tutorial 2 - Surface Challenge"

init :: proc(ctx: ^State_Context) -> (ok: bool) {
	rl.graphics_clear(rl.Color_Royal_Blue)
	return true
}

calculate_color_from_position :: proc(x, y: f32, w, h: u32) -> (color: rl.Color) {
	color.r = cast(f64)x / cast(f64)w
	color.g = cast(f64)y / cast(f64)h
	color.b = 1.0
	color.a = 1.0
	return
}

mouse_moved :: proc(event: rl.Mouse_Moved_Event, ctx: ^State_Context) {
	ctx.clear_color = calculate_color_from_position(
		event.x,
		event.y,
		ctx.gpu.config.width,
		ctx.gpu.config.height,
	)

	rl.graphics_clear(ctx.clear_color)
}

draw :: proc(ctx: ^State_Context) -> bool {
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
		init        = init,
		mouse_moved = mouse_moved,
		draw        = draw,
	}

	settings := rl.DEFAULT_SETTINGS
	settings.window.title = EXAMPLE_TITLE

	if ok := rl.init(state, settings); !ok do return

	rl.begin_run(state) // Start the main loop
}
