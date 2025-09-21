package application

// Core
import "core:time"
import win32 "core:sys/windows"

TIMER_NUM_SAMPLES :: 60

Timer :: struct {
	start_time:           time.Time,
	prev_frame_start:     time.Tick,
	frame_start:          time.Tick,
	frame_end:            time.Tick,
	delta_time_ms:        f64,
	fps:                  f64,
	sample_index:         int,
	work_times:           [TIMER_NUM_SAMPLES]f64,
	average_work_time:    f64,
	margin_ms:            f64,
	target_frame_time_ms: f64,
	fps_update:           bool,
	frame_count:          uint,
	last_fps_update_time: f64,
}

timer_init :: proc "contextless" (t: ^Timer, margin_ms: f64, target_frame: f64) {
	assert_contextless(t != nil)

	when ODIN_OS == .Windows {
		win32.timeBeginPeriod(1)
	}

	t.start_time           = time.now()
	t.prev_frame_start     = {}
	t.frame_start          = {}
	t.frame_end            = {}
	t.delta_time_ms        = 0.0
	t.fps                  = 0.0
	t.sample_index         = 0
	t.average_work_time    = 2.0  // Initial guess (ms)
	t.margin_ms            = margin_ms
	t.target_frame_time_ms = target_frame
	t.work_times           = {}
	t.fps_update           = false
	t.frame_count          = 0
	t.last_fps_update_time = 0.0
}

/*
Marks the beginning of a new frame.

This procedure should be called at the start of each frame update cycle. It
records the current timestamp and calculates delta time for the frame.
*/
timer_begin_frame :: proc "contextless" (t: ^Timer) {
	now := time.tick_now()
	current_time := timer_get_time(t)

	if t.prev_frame_start._nsec != 0 {  // Check if prev_frame_start is set
		delta_duration := time.tick_diff(t.prev_frame_start, now)
		t.delta_time_ms = time.duration_milliseconds(delta_duration)

		// Only calculate FPS if we have a reasonable frame time
		if t.delta_time_ms > 0.0 && t.delta_time_ms < 100.0 {
			t.frame_count += 1

			// Update FPS every second using timer_get_time
			if current_time - t.last_fps_update_time >= 1.0 {
				t.fps = f64(t.frame_count) / (current_time - t.last_fps_update_time)
				t.fps_update = true

				// Reset for next measurement period
				t.frame_count = 0
				t.last_fps_update_time = current_time
			} else {
				t.fps_update = false
			}
		}
	} else {
		t.delta_time_ms = 0.0
		t.fps = 0.0
		t.fps_update = false
		t.frame_count = 0
		t.last_fps_update_time = current_time
	}

	t.prev_frame_start = now
	t.frame_start = now
}

/**
Marks the end of a frame and performs timing calculations.

This function should be called at the end of each frame update cycle. It
computes the frame duration, calculates FPS, and updates performance metrics.
*/
timer_end_frame :: proc "contextless" (t: ^Timer) #no_bounds_check {
	t.frame_end = time.tick_now()

	work_duration := time.tick_diff(t.frame_start, t.frame_end)
	work_time_ms := time.duration_milliseconds(work_duration)

	t.work_times[t.sample_index] = work_time_ms
	t.sample_index = (t.sample_index + 1) % TIMER_NUM_SAMPLES

	t.average_work_time = 0.0
	for i in 0 ..< TIMER_NUM_SAMPLES {
		t.average_work_time += t.work_times[i]
	}
	t.average_work_time /= f64(TIMER_NUM_SAMPLES)

	t.fps_update = false
}

/* Gets the delta time since the last frame in seconds. */
@(require_results)
timer_get_delta :: proc "contextless" (t: ^Timer) -> f64 {
	return t.delta_time_ms / 1000.0
}

/* Gets the delta time since the last frame in milliseconds. */
@(require_results)
timer_get_delta_ms :: proc "contextless" (t: ^Timer) -> f64 {
	return t.delta_time_ms
}

/* Gets the current frames per second (FPS). */
@(require_results)
timer_get_fps :: proc "contextless" (t: ^Timer) -> f64 {
	return t.fps
}

/*
Gets the average time spent on frame work in milliseconds.

This excludes any sleep time and represents only the actual processing time.
*/
@(require_results)
timer_get_average_work_ms :: proc "contextless" (t: ^Timer) -> f64 {
	return t.average_work_time
}

/* Returns the precise amount of time since some time in the past. */
@(require_results)
timer_get_time :: proc "contextless" (t: ^Timer) -> f64 {
	return time.duration_seconds(time.since(t.start_time))
}

@(require_results)
timer_get_fps_update :: proc "contextless" (t: ^Timer) -> bool {
	return t.fps_update
}
