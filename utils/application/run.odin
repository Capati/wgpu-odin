#+vet !unused-imports
package application

// Packages
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
	if app.callbacks.init != nil {
		log.infof("Initializing '%s'", app.settings.title)
		if !app.callbacks.init(app) {
			log.fatal(
				"Failed to initialize application specific. " +
				"Make sure your 'init' procedure is returning 'true'.",
			)
			return
		}
		log.info("Initialized successfully!")
	}

	defer if app.callbacks.quit != nil {
		app.callbacks.quit(app)
	}

	// Create a MicroUI context to use in `ui_update` callback
	if app.callbacks.ui_update != nil {
		if !setup_ui(app) {
			log.fatal("Failed to setup MicroUI renderer")
			return
		}
	}

	timer_init(&app.timer)

	dt: f64

	log.info("Entering main loop...")

	loop: for !glfw.WindowShouldClose(app.window) {
		dt = timer_step(&app.timer)

		if !process_events(app) {
			log.fatal("Error while processing events!")
			return
		}

		if app.callbacks.ui_update != nil {
			mu.begin(app.mu_ctx)
			if !app.callbacks.ui_update(app, app.mu_ctx) {
				log.fatal("Error in 'ui_update' procedure!")
				return
			}
			mu.end(app.mu_ctx)
		}

		if app.callbacks.update != nil {
			if !app.callbacks.update(app, dt) {
				log.fatal("Error in 'update' procedure!")
				return
			}
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

		if app.callbacks.draw != nil {
			if !app.callbacks.draw(app) {
				log.fatal("Error in 'draw' procedure!")
				return
			}
		}

		when ODIN_DEBUG {
			update_window_title_with_fps(app)
		}

		enforce_frame_timing(app)
	}

	log.info("Exiting...")

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
