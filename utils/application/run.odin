#+vet !unused-imports
package application

// Core
import intr "base:intrinsics"
import "core:fmt"
import "core:log"
import "core:time"

// Vendor
import "vendor:glfw"
import mu "vendor:microui"

// Local packages
import wmu "./../microui"

run :: proc(app: ^$T) -> (ok: bool) where intr.type_is_specialization_of(T, Context) {
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

	timer_init(&app.timer)

	dt: f64

	log.info("Entering main loop...")

	loop: for !glfw.WindowShouldClose(app.window) {
		// Reset state each frame
		defer {
			app.mouse.scroll = {}
		}

		dt = timer_step(&app.timer)

		if !process_events(app) {
			log.fatal("Error while processing events!")
			return
		}

		update_ui(app) or_return

		if app.callbacks.update != nil && !app.callbacks.update(app, dt) {
			log.fatal("Error in \x1b[31mupdate\x1b[0m procedure!")
			return
		}

		if app.minimized {
			enforce_frame_timing(app)
			continue
		}

		get_current_frame(app) or_return
		defer if !ok || app.frame.skip {
			release_current_frame(app)
		}

		if app.frame.skip {
			enforce_frame_timing(app)
			continue
		}

		if app.callbacks.draw != nil && !app.callbacks.draw(app) {
			log.fatal("Error in \x1b[31mdraw\x1b[0m procedure!")
			return
		}

		when ODIN_DEBUG {
			update_window_title_with_fps(app)
		}

		enforce_frame_timing(app)
	}

	log.info("Exiting...")

	return true
}

check_callbacks :: proc(app: ^$T) -> (ok: bool) where intr.type_is_specialization_of(T, Context) {
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

update_ui :: proc(app: ^$T) -> (ok: bool) where intr.type_is_specialization_of(T, Context) {
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
	should_update_window_title_with_fps :: proc "contextless" (app: ^Application) -> bool {
		if app.timer.prev_fps_update == app.timer.curr_time {
			if app.timer.prev_fps != app.timer.fps {
				return true
			}
		}
		return false
	}

	WINDOW_TITLE_FPS_STR :: #config(WINDOW_TITLE_FPS_STR, " FPS")

	update_window_title_with_fps :: proc(app: ^Application) {
		if !should_update_window_title_with_fps(app) {
			return
		}

		fmt.bprintf(
			app.title_buffer[:],
			"%s [%d%s]",
			app.settings.title,
			app.timer.fps,
			WINDOW_TITLE_FPS_STR,
		)

		nul := nul_search_bytes(app.title_buffer[:])
		// Add null terminator
		app.title_buffer[nul] = 0
		// Set the window title, including the null terminator
		glfw.SetWindowTitle(app.window, cstring(raw_data(app.title_buffer[:nul + 1])))
	}
}
