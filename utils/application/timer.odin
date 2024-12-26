package application

/* Packages */
import "core:time"

Timer :: struct {
	/* Frame delta vars. */
	start_time:           time.Time,
	curr_time:            time.Tick,
	prev_time:            time.Tick,
	prev_fps_update:      time.Tick,

	/* Updated with a certain frequency. */
	fps:                  int,
	prev_fps:             int,
	average_delta:        f64,

	/* The frequency by which to update the FPS. */
	fps_update_frequency: f64,

	/* Frames since last FPS update. */
	frames:               int,

	/* The current timestep. */
	dt:                   f64,
}

/*
Defines how often the FPS (Frames Per Second)counter should update, measured in seconds.
Default value is 0.5 seconds if not configured otherwise.
*/
FPS_UPDATE_FREQUENCY: f64 : #config(FPS_UPDATE_FREQUENCY, 0.5)

timer_init :: proc "contextless" (timer: ^Timer) {
	timer.start_time = time.now()
	timer.curr_time = time.tick_now()
	timer.prev_time = timer.curr_time
	timer.prev_fps_update = timer.curr_time
	timer.fps_update_frequency = FPS_UPDATE_FREQUENCY
}

/* Returns the average delta time over the last second. */
timer_get_average_delta :: proc "contextless" (timer: ^Timer) -> f64 {
	return timer.average_delta
}

/* Returns the time between the last two frames. */
timer_get_delta :: proc "contextless" (timer: ^Timer) -> f64 {
	return timer.dt
}

/* Returns the current frames per second. */
timer_get_fps :: proc "contextless" (timer: ^Timer) -> int {
	return timer.fps
}

/* Returns the precise amount of time since some time in the past. */
timer_get_time :: proc "contextless" (timer: ^Timer) -> f64 {
	return time.duration_seconds(time.since(timer.start_time))
}

/* Pauses the current thread for the specified amount of time in seconds. */
timer_sleep :: proc "contextless" (seconds: f64) {
	time.sleep(time.Duration(seconds * f64(time.Second)))
}

/* Measures the time between two frames. */
timer_step :: proc "contextless" (timer: ^Timer) -> f64 {
	// Frames rendered
	timer.frames += 1

	// "Current" time is previous time by now.
	timer.prev_time = timer.curr_time

	// Get time from system using tick_now for high precision
	timer.curr_time = time.tick_now()

	// Calculate delta time in seconds
	timer.dt = time.duration_seconds(time.tick_since(timer.prev_time))

	/* Calculates the elapsed time in seconds since the last FPS update */
	time_since_last := time.duration_seconds(time.tick_since(timer.prev_fps_update))

	// Update FPS?
	if time_since_last > timer.fps_update_frequency {
		timer.fps = int((f64(timer.frames) / time_since_last) + 0.5)
		timer.average_delta = time_since_last / f64(timer.frames)
		timer.prev_fps_update = timer.curr_time
		timer.frames = 0
	}

	return timer.dt
}

/* Returns the current time in seconds since the application started. */
get_time :: proc "contextless" (app: ^Application) -> f64 {
	return timer_get_time(&app.timer)
}
