#+vet !unused-imports
package application

// Core
import intr "base:intrinsics"
import "core:fmt"
import "core:log"
import "core:time"

// Vendor
import "vendor:glfw"

run :: proc(app: ^$T/Context) -> (ok: bool) {
	// Initialize application specific (the `init` callback)
	if app.callbacks.init != nil {
		log.debugf("Initializing \x1b[32m%s\x1b[0m", app.settings.title)
		if !app.callbacks.init(app) {
			log.fatal(
				"Failed to initialize application:\n" +
				"   Make sure your 'init' procedure is returning 'true'",
			)
			return
		}
		log.info("Initialized successfully!")
	}

	defer if app.callbacks.quit != nil {
		app.callbacks.quit(app)
	}

	when ODIN_DEBUG {
		check_callbacks(app) or_return
	}

	monitor_info := get_primary_monitor_info()
	timer_init(&app.timer, monitor_info.refresh_rate)

	log.info("Entering main loop...")

	loop: for !glfw.WindowShouldClose(app.window) {
		timer_tick(&app.timer)

		// Poll events first to minimize input latency
		glfw.PollEvents()

		if !process_events(app) {
			log.fatal("Error while processing events!")
			return
		}

		// Handle update (which processes inputs) right after events
		if app.callbacks.update != nil &&
		   !app.callbacks.update(app, timer_get_delta_time(app.timer)) {
			log.fatal("Error in \x1b[31mupdate\x1b[0m procedure!")
			return
		}

		// Early out for rendering skips
		if app.stop_rendering || app.skip_frame {
			if app.skip_frame {
				app.skip_frame = false
			}
			glfw.WaitEvents()
			timer_init(&app.timer, monitor_info.refresh_rate)
			continue
		}

		// UI updates after input processing but before acquire
		update_ui(app) or_return

		// Move the potentially blocking get_current_frame to after all input processing
		get_current_frame(app) or_return

		// Draw callback after frame acquisition
		if app.callbacks.draw != nil && !app.callbacks.draw(app) {
			log.fatal("Error in \x1b[31mdraw\x1b[0m procedure!")
			return
		}

		when ODIN_DEBUG {
			update_window_title_with_fps(app)
		}
	}

	log.info("Exiting...")

	return true
}

stop_rendering :: #force_inline proc "contextless" (app: ^$T/Context) -> bool {
	return app.stop_rendering
}

check_callbacks :: proc(app: ^$T/Context) -> (ok: bool) {
	// Check MicroUI initialization and callback
	if microui_is_initialized(app) && app.callbacks.microui_update == nil {
		log.warn(
			"MicroUI initialization incomplete:\n" +
			"   \x1b[33mmicroui_update\x1b[0m callback procedure is required for frame updates",
		)
	} else if app.callbacks.microui_update != nil && !microui_is_initialized(app) {
		log.warn(
			"\x1b[33mmicroui_update\x1b[0m callback procedure is set but MicroUI is not " +
			"initialized:\n   Call \x1b[33mapp.microui_init(ctx)\x1b[0m before run",
		)
	}

	return true
}

update_ui :: proc(app: ^$T/Context) -> (ok: bool) {
	if microui_is_initialized(app) {
		microui_new_frame(app)
		if app.callbacks.microui_update != nil && !app.callbacks.microui_update(app, app._mu_ctx) {
			log.error("Error in \x1b[31mmicroui_update\x1b[0m procedure!")
			return
		}
		microui_end_frame(app)
	}

	return true
}

enforce_frame_timing :: #force_inline proc(app: ^Application) {
	time.sleep(app.target_frame_time)
}

when ODIN_DEBUG {
	update_window_title_with_fps :: proc(app: ^Application) {
		if !timer_check_fps_updated(app.timer) {
			return
		}

		fmt.bprintf(
			app.title_buffer[:],
			"%s - FPS = %.2f",
			app.settings.title,
			timer_get_fps(app.timer),
		)

		nul := nul_search_bytes(app.title_buffer[:])
		// Add null terminator
		app.title_buffer[nul] = 0
		// Set the window title, including the null terminator
		glfw.SetWindowTitle(app.window, cstring(raw_data(app.title_buffer[:nul + 1])))
	}
}
