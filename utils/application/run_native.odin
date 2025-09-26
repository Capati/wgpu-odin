#+build !js
package application

run :: proc(app := app_context) {
	assert(!app.prepared, "Application already initialized")

	// Set up window callbacks
	_window_setup_callbacks(app.window)

	// Initialize the user application
	if app.callbacks.init != nil {
		if res := app.callbacks.init(app); !res {
			return
		}
	}

	defer {
		if app.callbacks.quit != nil {
			app.callbacks.quit(app)
		}
		destroy(app)
	}

	margin_ms := 0.5 // Wake up early for busy wait accuracy
	target_frame_time_ms := 1000.0 / f64(window_get_refresh_rate(app.window))
	timer_init(&app.timer, margin_ms, target_frame_time_ms)

	app.prepared = true
	app.running = true

	MAIN_LOOP: for app.running {
		// Process events
		// Events are handled directly via callbacks - no need to poll queue
		window_process_events(app.window)

		timer_begin_frame(&app.timer)
		when ODIN_DEBUG {
			_update_window_title_with_fps(app)
		}

		keyboard_update()
		mouse_update()

		// Application iteration
		if app.callbacks.step != nil {
			if !app.callbacks.step(app, f32(timer_get_delta(&app.timer))) {
				app.running = false
				break MAIN_LOOP
			}
		}

		timer_end_frame(&app.timer)
		gpu_pace_frame(app.gpu, &app.timer)
	}
}

// -----------------------------------------------------------------------------
// @(private)
// -----------------------------------------------------------------------------

@(private, disabled = !ODIN_DEBUG)
_update_window_title_with_fps :: proc(app := app_context) {
    if !timer_get_fps_update(&app.timer) {
        return
    }

    window_impl := _window_get_impl(app.window)
    title := string_buffer_get_string(&window_impl.title_buf)

    title_buf: String_Buffer
    string_buffer_init(&title_buf, title)
    string_buffer_append(&title_buf, " - FPS = ")

    fps_buf: [4]u8
    fps := timer_get_fps(&app.timer)
    string_buffer_append_f64(&title_buf, fps_buf[:], fps, decimals = 1)

    // This call does not change window.title_buf
    window_set_title_cstring(app.window, string_buffer_get_cstring(&title_buf))
}
