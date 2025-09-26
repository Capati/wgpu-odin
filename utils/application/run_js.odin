#+build js
package application

// Core
import "core:sys/wasm/js"

@(private="file", export)
step :: proc(dt: f32) -> bool {
	app := app_context
	if app == nil do return true
	context = app.custom_context
	if !app.prepared {
		return true
	}

	if !app.running {
		if app.callbacks.quit != nil {
			app.callbacks.quit(app)
		}
		return false
	}

	timer_begin_frame(&app.timer)

	// Application iteration
	if app.callbacks.step != nil {
		if !app.callbacks.step(app, f32(timer_get_delta(&app.timer))) {
			app.running = false
		}
	}

	// TODO: fix order
	keyboard_update()
	mouse_update()

	timer_end_frame(&app.timer)

	return app.running
}

run :: proc(app := app_context) -> (ok: bool) {
	assert(app != nil, "Invalid application")
	assert(!app.prepared, "Application already initialized")

	// Set up window callbacks
	_window_setup_callbacks(app.window)

	// Initialize the user application
	if app.callbacks.init != nil {
		if res := app.callbacks.init(app); !res {
			return
		}
	}

	timer_init(&app.timer, 0, 0)

	app.prepared = true
	app.running = true

	return true
}

@(private="file", fini)
_js_fini :: proc "contextless" () {
	app := app_context
	context = app.custom_context
	destroy(app)
}
