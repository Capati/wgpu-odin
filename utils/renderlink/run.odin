package application

// STD Library
import intr "base:intrinsics"
import "core:fmt"
import "core:log"
import "core:math"
import "core:time"

_ :: fmt
_ :: log
_ :: math

SHOW_FPS: bool : (ODIN_DEBUG && TIMER_PACKAGE)

begin_run :: proc(state: ^$T) -> (err: Error) where intr.type_is_specialization_of(T, Context) {
	assert(g_app.initialized, "Application not initialized!")

	when TIMER_PACKAGE {
		g_app.timer = timer_init()
	}

	g_app.running = true

	dt: f64

	log.info("Entering main loop...")

	main_loop: for true {
		when EVENT_PACKAGE {
			event_process(state)
			if !g_app.running do break main_loop // Quit requested from some callback?
		}

		when TIMER_PACKAGE {
			// Update dt, as we'll be passing it to update
			dt = timer_step()
		}

		if state.callbacks.update != nil {
			if err = state.callbacks.update(dt, state); err != nil {
				log.error("Error occurred during 'update' procedure")
				break main_loop
			}
		}

		// Skip frame when window is minimized
		if window_is_minimized() {
			_throttle_main_loop()
			continue
		}

		when GRAPHICS_PACKAGE {
			if err = _graphics_start(); err != nil {
				log.error("Error occurred during frame start")
				break main_loop
			}

			// Skip frame when surface texture is outdated or lost
			if g_app.renderer.skip_frame do continue

			if state.callbacks.draw != nil {
				if err = state.callbacks.draw(state); err != nil {
					log.error("Error occurred during 'draw' procedure")
					break main_loop
				}
			}

			if err = _graphics_end(); err != nil {
				log.error("Error occurred during frame end")
				break main_loop
			}
		}

		when SHOW_FPS {
			if _should_update_window_title_with_fps() {
				_update_window_title_with_fps(g_app.timer.fps)
			}
		}

		time.sleep(g_app.target_frame_time)
	}

	log.info("Exiting...")

	if state.callbacks.quit != nil {
		state.callbacks.quit(state)
	}

	destroy()

	return
}

// Close the application in the next frame.
quit :: proc() {
	g_app.running = false
}

when SHOW_FPS {
	@(private)
	_should_update_window_title_with_fps :: proc "contextless" () -> bool {
		if g_app.timer.prev_fps_update == g_app.timer.curr_time {
			if g_app.timer.prev_fps != g_app.timer.fps {
				return true
			}
		}
		return false
	}

	WINDOW_TITLE_BUFFER_LEN: int : #config(WINDOW_TITLE_BUFFER_LEN, 256)
	WINDOW_TITLE_FPS_STR: string : #config(WINDOW_TITLE_FPS_STR, " FPS")

	@(private)
	_update_window_title_with_fps :: proc(fps: int) {
		buffer: [WINDOW_TITLE_BUFFER_LEN]byte
		fmt.bprintf(buffer[:], "%s [%d%s]", window_get_title(), fps, WINDOW_TITLE_FPS_STR)

		nul := nul_search_bytes(buffer[:])

		// Add null terminator
		buffer[nul] = 0

		// Set the window title, including the null terminator
		window_set_title_c_string(cstring(raw_data(buffer[:nul + 1])))
	}
}

MAIN_LOOP_THROTTLE_DURATION :: THROTTLE_DURATION

@(private)
_throttle_main_loop :: proc "contextless" () {
	time.sleep(MAIN_LOOP_THROTTLE_DURATION)
}
