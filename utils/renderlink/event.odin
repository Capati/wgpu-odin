package renderlink

// STD Library
import intr "base:intrinsics"
import "core:container/queue"
import "core:log"
import "core:time"

_ :: log

Quit_Event :: struct{}

Event :: union {
	Key_Event,
	Text_Input_Event,
	Text_Edited_Event,
	Mouse_Moved_Event,
	Mouse_Button_Event,
	Mouse_Wheel_Event,
	Joystick_Pressed_Event,
	Joystick_Axis_Motion_Event,
	Joystick_Hat_Motion_Event,
	Gamepad_Pressed_Event,
	Gamepad_Axis_Motion_Event,
	Joystick_Status_Event,
	Gamepad_Sensor_Update_Event,
	Focus_Event,
	Mouse_Focus_Event,
	Resize_Event,
	Visible_Event,
	Moved_Event,
	Minimized_Event,
	Restored_Event,
	Display_Rotated_Event,
	Quit_Event,
}

Event_Error :: enum {
	None,
	Init_Failed,
}

/* FIFO Queue */
Event_List :: distinct queue.Queue(Event)

/* Default events queue capacity */
DEFAULT_EVENTS_CAPACITY :: #config(DEFAULT_EVENTS_CAPACITY, 16)

DRAG_TIMEOUT :: time.Millisecond * 100 // 100ms timeout

Event_State :: struct {
	data            : Event_List,
	window_dragging : bool,
}

when EVENT_PACKAGE {
/* Clears the event queue. */
event_clear :: proc() {
	queue.clear(&g_app.events.data)
}

// Pop the next event from the front of the FIFO event queue, if any, and return it.
event_poll :: proc(event: ^Event) -> (has_next: bool) {
	if event_is_empty() {
		_platform_populate_event_queue()
	}
	event^, has_next = event_pop()
	return
}

// Pump events into the event queue.
event_pump :: proc() {
}

// Adds an event to the event queue.
event_push :: proc(event: Event) {
	queue.push_front(&g_app.events.data, event)
}

// Wait for and return the next available window event
event_wait :: proc(event: ^Event, timeout: time.Duration = 0) -> (has_next: bool) {
	start_time := time.now()

	timed_out :: proc(start: time.Time, timeout: time.Duration) -> bool {
		if timeout == 0 {
			return false // Infinite timeout
		}
		return time.since(start) >= timeout
	}

	// If the event queue is empty, first check if new events are available
	if event_is_empty() {
		_platform_populate_event_queue()
	}

	// Manual wait loop to avoid skipping joystick events
	for event_is_empty() && !timed_out(start_time, timeout) {
		time.sleep(time.Millisecond * 10)
		_platform_populate_event_queue()
	}

	event^, has_next = event_pop()
	return
}

event_pop :: proc() -> (Event, bool) {
	if !event_is_empty() {
		return queue.pop_back_safe(&g_app.events.data)
	}
	return nil, false
}

event_has_next :: proc() -> bool {
	return g_app.events.data.len > 0
}

event_is_empty :: proc() -> bool {
	return g_app.events.data.len == 0
}

} else {

event_clear :: proc() {}
event_poll :: proc(_: ^Event) -> (has_next: bool) {return}
event_pump :: proc() {}
event_push :: proc(_: Event) {}
event_wait :: proc(_: ^Event, _: time.Duration = 0) -> (has_next: bool) {return}
event_pop :: proc() -> (Event, bool) {return nil, false}
event_has_next :: proc() -> bool {return false}
event_is_empty :: proc() -> bool {return false}
}

when EVENT_PACKAGE {
	update_input_state :: proc "contextless" () {
		_keyboard_update_state()
		_mouse_update_state()
	}

	reset_input_state :: proc "contextless" () {
		_keyboard_reset_state()
		_mouse_reset_state()
	}

	event_process :: proc(state: ^$T) where intr.type_is_specialization_of(T, Context) {
		update_input_state()

		curr_event: Event
		for event_poll(&curr_event) {
			#partial switch &ev in curr_event {
			case Key_Event:
				switch ev.action {
				case .Pressed:
					if state.callbacks.key_pressed != nil {
						if _keyboard_is_pressed(ev.key) {
							state.callbacks.key_pressed(ev, state)
						}
					} else {
						if ev.key == .Escape {
							quit();return
						}
					}
				case .Released:
					if state.callbacks.key_released != nil {
						if _keyboard_is_released(ev.key) {
							state.callbacks.key_released(ev, state)
						}
					}
				}

			case Text_Input_Event:
				if state.callbacks.text_input != nil {
					state.callbacks.text_input(ev, state)
				}

			case Text_Edited_Event:
				if state.callbacks.text_edited != nil {
					state.callbacks.text_edited(ev, state)
				}

			case Mouse_Moved_Event:
				if state.callbacks.mouse_moved != nil {
					state.callbacks.mouse_moved(ev, state)
				}

			case Mouse_Button_Event:
				switch ev.action {
				case .Pressed:
					if state.callbacks.mouse_pressed != nil {
						if _mouse_is_pressed(ev.button) {
							state.callbacks.mouse_pressed(ev, state)
						}
					}
				case .Released:
					if state.callbacks.mouse_released != nil {
						if _mouse_is_released(ev.button) {
							state.callbacks.mouse_released(ev, state)
						}
					}
				}

			case Mouse_Wheel_Event:
				if state.callbacks.wheel_moved != nil {
					state.callbacks.wheel_moved(ev, state)
				}

			case Joystick_Pressed_Event:
				switch ev.action {
				case .Pressed:
					if state.callbacks.joystick_pressed != nil {
						state.callbacks.joystick_pressed(ev, state)
					}
				case .Released:
					if state.callbacks.joystick_released != nil {
						state.callbacks.joystick_released(ev, state)
					}
				}

			case Joystick_Axis_Motion_Event:
				if state.callbacks.joystick_axis != nil {
					state.callbacks.joystick_axis(ev, state)
				}

			case Joystick_Hat_Motion_Event:
				if state.callbacks.joystick_hat != nil {
					state.callbacks.joystick_hat(ev, state)
				}

			case Gamepad_Pressed_Event:
				switch ev.action {
				case .Pressed:
					if state.callbacks.gamepad_pressed != nil {
						state.callbacks.gamepad_pressed(ev, state)
					}
				case .Released:
					if state.callbacks.gamepad_released != nil {
						state.callbacks.gamepad_released(ev, state)
					}
				}

			case Gamepad_Axis_Motion_Event:
				if state.callbacks.gamepad_axis != nil {
					state.callbacks.gamepad_axis(ev, state)
				}

			case Joystick_Status_Event:
				switch ev.status {
				case .Connected:
					if state.callbacks.joystick_added != nil {
						state.callbacks.joystick_added(ev, state)
					}
				case .Disconnected:
					if state.callbacks.joystick_removed != nil {
						state.callbacks.joystick_removed(ev, state)
					}
				}

			case Gamepad_Sensor_Update_Event:
				if state.callbacks.joystick_sensor_updated != nil {
					state.callbacks.joystick_sensor_updated(ev, state)
				}

			case Focus_Event:
				if state.callbacks.focus != nil {
					state.callbacks.focus(ev, state)
				}

			case Mouse_Focus_Event:
				if state.callbacks.mouse_focus != nil {
					state.callbacks.mouse_focus(ev, state)
				}

			case Visible_Event:
				if state.callbacks.visible != nil {
					state.callbacks.visible(ev, state)
				}

			case Moved_Event:
				reset_input_state()
				if state.callbacks.moved != nil {
					state.callbacks.moved(ev, state)
				}

			case Minimized_Event:
				if state.callbacks.minimized != nil {
					state.callbacks.minimized(ev, state)
				}

			case Restored_Event:
				if state.callbacks.restored != nil {
					state.callbacks.restored(ev, state)
				}

			case Resize_Event:
				log.infof("Window resized: %d x %d", ev.width, ev.height)

				if state.callbacks.resize != nil {
					if ok := state.callbacks.resize(ev, state); !ok {
						log.error("Error occurred during 'resized' callback")
						quit();return
					}
				}

				when GRAPHICS_PACKAGE {
					if ok := _graphics_resize_surface({ev.width, ev.height}); !ok {
						log.error("Error occurred during renderer resizing surface")
						quit();return
					}
				}

			case Display_Rotated_Event:
				if state.callbacks.display_rotated != nil {
					state.callbacks.display_rotated(ev, state)
				}

			case Quit_Event:
				log.info("Requested exit!")
				quit();return // Request a break from the game loop
			}

			if curr_event != nil && state.callbacks.handle_events != nil {
				state.callbacks.handle_events(curr_event, state)
			}
		}
	}
} else {
	update_input_state :: proc "contextless" () {}
	reset_input_state :: proc "contextless" () {}
	event_process :: proc(
		state: ^$T,
	) -> (
		exit: bool,
	) where intr.type_is_specialization_of(T, Context) {
		return
	}
}
