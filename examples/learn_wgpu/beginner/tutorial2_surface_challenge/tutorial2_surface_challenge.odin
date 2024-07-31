package tutorial2_surface_challenge

// Core
import "core:log"

// Package
import rl "./../../../../utils/renderlink"

_ :: log

State :: struct {
	clear_color: rl.Color,
}

App_Context :: rl.Context(State)

EXAMPLE_TITLE :: "Tutorial 2 - Surface Challenge"

init :: proc(using ctx: ^App_Context) -> (err: rl.Error) {
	rl.graphics_clear(rl.Color_Royal_Blue)
	return
}

calculate_color_from_position :: proc(x, y: f32, w, h: u32) -> (color: rl.Color) {
	color.r = cast(f64)x / cast(f64)w
	color.g = cast(f64)y / cast(f64)h
	color.b = 1.0
	color.a = 1.0
	return
}

mouse_moved :: proc(event: rl.Mouse_Moved_Event, using ctx: ^App_Context) {
	state.clear_color = calculate_color_from_position(
		event.x,
		event.y,
		gpu.config.width,
		gpu.config.height,
	)

	rl.graphics_clear(state.clear_color)
}

draw :: proc(using ctx: ^App_Context) -> (err: rl.Error) {
	return
}

main :: proc() {
	state, state_err := new(App_Context)
	if state_err != nil do return
	defer free(state)

	state.callbacks = {
		init        = init,
		mouse_moved = mouse_moved,
		draw        = draw,
	}

	settings := rl.DEFAULT_SETTINGS
	settings.window.title = EXAMPLE_TITLE

	if err := rl.init(state, settings); err != nil do return

	rl.begin_run(state) // Start the main loop
}
