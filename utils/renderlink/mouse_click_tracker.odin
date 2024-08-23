package renderlink

// STD Library
import "core:time"

Click_Tracker :: struct {
	last_click_time: time.Time,
	last_click_pos:  Mouse_Position,
	click_count:     u32,
	last_button:     Mouse_Button,
}

// Time window for multi-clicks
MULTI_CLICK_TIME_MS: f64 : #config(RL_MULTI_CLICK_TIME, 350)

// Maximum distance between clicks to be considered multi-click
MULTI_CLICK_DISTANCE_PX: f32 : #config(RL_MULTI_CLICK_DISTANCE_PX, 5)

_mouse_click_tracker_tick :: proc "contextless" (event: Mouse_Button_Event) -> (presses: u32) {
	tracker := &g_app.mouse.tracker

	current_time := time.now()

	// Reset tracker if it's a different mouse button
	if event.button != tracker.last_button {
		_mouse_click_tracker_reset(tracker)
	}

	if time.duration_milliseconds(time.diff(tracker.last_click_time, current_time)) <=
		   MULTI_CLICK_TIME_MS &&
	   abs(event.pos.x - tracker.last_click_pos.x) <= MULTI_CLICK_DISTANCE_PX &&
	   abs(event.pos.y - tracker.last_click_pos.y) <= MULTI_CLICK_DISTANCE_PX {
		tracker.click_count += 1
	} else {
		tracker.click_count = 1
	}

	tracker.last_click_time = current_time
	tracker.last_click_pos = event.pos
	tracker.last_button = event.button

	presses = tracker.click_count

	return
}

_mouse_click_tracker_reset :: proc "contextless" (tracker: ^Click_Tracker) {
	tracker.last_click_time = time.Time{}
	tracker.last_click_pos = Mouse_Position{}
	tracker.click_count = 0
}
