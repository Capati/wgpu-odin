#+vet !unused-imports
package application

// Packages
import intr "base:intrinsics"
import "base:runtime"
import "core:container/queue"
import "core:log"
import "core:time"

// Vendor
import "vendor:glfw"
import mu "vendor:microui"

// Local packages
import wmu "./../microui"

InputAction :: enum u8 {
	None,
	Pressed,
	Released,
}

KeyEvent :: struct {
	key:       Key,
	scancode:  i32,
	is_repeat: bool,
	action:    InputAction,
}

MousePosition :: struct {
	x, y: f32,
}

MouseMovedEvent :: distinct MousePosition

MouseButton :: enum i32 {
	Unknown = -1,
	Left    = glfw.MOUSE_BUTTON_LEFT,
	Middle  = glfw.MOUSE_BUTTON_MIDDLE,
	Right   = glfw.MOUSE_BUTTON_RIGHT,
	Four    = glfw.MOUSE_BUTTON_4,
	Five    = glfw.MOUSE_BUTTON_5,
}

MouseButtonEvent :: struct {
	button:  MouseButton,
	action:  InputAction,
	pos:     MousePosition,
	presses: u32,
}

MouseWheelEvent :: distinct MousePosition

ResizeEvent :: WindowSize

MinimizedEvent :: struct {
	value: bool,
}

RestoredEvent :: struct {
	value: bool,
}

QuitEvent :: struct {}

Event :: union {
	KeyEvent,
	// TextInputEvent,
	// TextEditedEvent,
	MouseMovedEvent,
	MouseButtonEvent,
	MouseWheelEvent,
	// JoystickPressedEvent,
	// JoystickAxisMotionEvent,
	// JoystickHatMotionEvent,
	// GamepadPressedEvent,
	// GamepadAxisMotionEvent,
	// JoystickStatusEvent,
	// GamepadSensorUpdateEvent,
	// FocusEvent,
	// MouseFocusEvent,
	ResizeEvent,
	// VisibleEvent,
	// MovedEvent,
	MinimizedEvent,
	RestoredEvent,
	// DisplayRotatedEvent,
	QuitEvent,
}

/* FIFO Queue */
EventList :: distinct queue.Queue(Event)

/* Default events queue capacity */
DEFAULT_EVENTS_CAPACITY :: #config(DEFAULT_EVENTS_CAPACITY, 16)

EventState :: struct {
	data:            EventList,
	window_dragging: bool,
}

event_init :: proc(self: ^EventState) -> (ok: bool) {
	if err := queue.init(&self.data, DEFAULT_EVENTS_CAPACITY); err != nil {
		log.fatalf("Failed to initialize events: [%v]", err)
		return
	}
	return true
}

/* Clears the event queue. */
event_clear :: proc(self: ^EventState) {
	queue.clear(&self.data)
}

// Pop the next event from the front of the FIFO event queue, if any, and return it.
event_poll :: proc(self: ^EventState, event: ^Event) -> (has_next: bool) {
	event^, has_next = event_pop(self)
	return
}

// Adds an event to the event queue.
event_push :: proc(self: ^EventState, event: Event) {
	queue.push_front(&self.data, event)
}

// Wait for and return the next available window event
event_wait :: proc(self: ^EventState, event: ^Event, timeout: f64 = 0) -> (has_next: bool) {
	glfw.WaitEventsTimeout(timeout)
	event^, has_next = event_pop(self)
	return
}

event_pop :: proc(self: ^EventState) -> (Event, bool) {
	if !event_is_empty(self) {
		return queue.pop_back_safe(&self.data)
	}
	return nil, false
}

event_has_next :: proc(self: ^EventState) -> bool {
	return self.data.len > 0
}

event_is_empty :: proc(self: ^EventState) -> bool {
	return self.data.len == 0
}

size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	context = runtime.default_context()
	app := cast(^Application)glfw.GetWindowUserPointer(window)
	size := WindowSize{u32(width), u32(height)}
	app.framebuffer_size = size
	// Avoid stack multiple events while user is resizing
	if app.should_resize {
		return
	}
	event_push(&app.events, size)
	app.should_resize = true
}

minimize_callback :: proc "c" (window: glfw.WindowHandle, iconified: i32) {
	context = runtime.default_context()
	app := cast(^Application)glfw.GetWindowUserPointer(window)
	app.minimized = bool(iconified)
	event_push(&app.events, MinimizedEvent{bool(iconified)})
}

focus_callback :: proc "c" (window: glfw.WindowHandle, focused: i32) {
	context = runtime.default_context()
	app := cast(^Application)glfw.GetWindowUserPointer(window)
	event_push(&app.events, RestoredEvent{bool(focused)})
}

key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	context = runtime.default_context()
	app := cast(^Application)glfw.GetWindowUserPointer(window)
	event_push(
		&app.events,
		KeyEvent {
			key = Key(key),
			scancode = scancode,
			action = .Pressed if action == glfw.PRESS || action == glfw.REPEAT else .Released,
		},
	)
}

cursor_position_callback :: proc "c" (window: glfw.WindowHandle, xpos, ypos: f64) {
	context = runtime.default_context()
	app := cast(^Application)glfw.GetWindowUserPointer(window)
	event_push(&app.events, MouseMovedEvent{x = f32(xpos), y = f32(ypos)})
}

mouse_button_callback :: proc "c" (window: glfw.WindowHandle, button, action, mods: i32) {
	context = runtime.default_context()
	app := cast(^Application)glfw.GetWindowUserPointer(window)
	xpos, ypos := glfw.GetCursorPos(window)
	event_push(
		&app.events,
		MouseButtonEvent {
			button = MouseButton(button),
			action = .Pressed if action == glfw.PRESS else .Released,
			pos = {x = f32(xpos), y = f32(ypos)},
		},
	)
}

scroll_callback :: proc "c" (window: glfw.WindowHandle, xoffset, yoffset: f64) {
	context = runtime.default_context()
	app := cast(^Application)glfw.GetWindowUserPointer(window)
	event_push(&app.events, MouseWheelEvent{f32(xoffset), f32(yoffset)})
}

@(require_results)
process_events :: proc(app: ^$T) -> (ok: bool) where intr.type_is_specialization_of(T, Context) {
	glfw.PollEvents()
	keyboard_update(app)

	event: Event = ---
	for event_poll(&app.events, &event) {
		if microui_is_initialized(app) {
			microui_handle_events(app, event)
		}

		#partial switch &ev in event {
		case KeyEvent:
			if app.exit_key != .Unknown && ev.key == app.exit_key {
				quit(app)
			}
			if app.callbacks.key != nil {
				app.callbacks.key(app, ev)
			}

		case MouseButtonEvent:
			if app.callbacks.mouse_button != nil {
				app.callbacks.mouse_button(app, ev)
			}

		case MouseMovedEvent:
			if app.callbacks.mouse_position != nil {
				app.callbacks.mouse_position(app, ev)
			}

		case MouseWheelEvent:
			if app.callbacks.wheel_moved != nil {
				app.callbacks.wheel_moved(app, ev)
			}

		case MinimizedEvent:
			if app.callbacks.minimized != nil {
				app.callbacks.minimized(app, ev.value)
			}

		case RestoredEvent:
			if app.callbacks.restored != nil {
				app.callbacks.restored(app, ev.value)
			}

		case WindowSize:
			if app.should_resize && !app.minimized {
				log.infof(
					"Framebuffer resize: %d x %d",
					app.framebuffer_size.w,
					app.framebuffer_size.h,
				)
				app.should_resize = false
				resize_surface(app, app.framebuffer_size) or_return
				if app.depth_stencil.enabled {
					setup_depth_stencil(app, {format = app.depth_stencil.format}) or_return
				}
				if microui_is_initialized(app) {
					wmu.resize(i32(app.framebuffer_size.w), i32(app.framebuffer_size.h))
				}
				if app.callbacks.resize != nil {
					app.callbacks.resize(app, app.framebuffer_size)
				}
			}

		case QuitEvent:
			quit(app)
		}

		if app.callbacks.handle_event != nil {
			app.callbacks.handle_event(app, event)
		}
	}

	return true
}

CallbackList :: struct($T: typeid) where intr.type_is_struct(T) {
	// This procedure is called exactly once at the beginning of the application.
	init:           proc(ctx: ^Context(T)) -> bool,
	// Callback procedure triggered when the application is closed.
	quit:           proc(ctx: ^Context(T)),
	// Callback procedure used to update the state of the MicroUI every frame.
	microui_update: proc(ctx: ^Context(T), mu_ctx: ^mu.Context) -> (ok: bool),
	// Callback procedure used to update the state of the application every frame.
	update:         proc(ctx: ^Context(T), dt: f64) -> bool,
	// Callback procedure used to draw on the screen every frame.
	draw:           proc(ctx: ^Context(T)) -> bool,
	// Callback procedure used for compute operations every frame.
	compute:        proc(ctx: ^Context(T)) -> bool,

	// // Callback procedure triggered when a directory is dragged and dropped onto the window.
	// display_rotated:         proc(event: Display_Rotated_Event, ctx: ^Context(T)),
	// // Callback procedure triggered when window receives or loses focus.
	// focus:                   proc(event: Focus_Event, ctx: ^Context(T)),
	// // Callback procedure triggered when window receives or loses mouse focus.
	// mouse_focus:             proc(event: Mouse_Focus_Event, ctx: ^Context(T)),
	// Called when the window is resized.
	resize:         proc(ctx: ^Context(T), size: WindowSize) -> bool,
	// // Callback procedure triggered when window is shown or hidden.
	// visible:                 proc(event: Visible_Event, ctx: ^Context(T)),
	// // Callback procedure triggered when window is moved (dragged).
	// moved:                   proc(event: Moved_Event, ctx: ^Context(T)),
	// Callback procedure triggered when window is minimized.
	minimized:      proc(ctx: ^Context(T), minimized: bool),
	// Callback procedure triggered when window is restored.
	restored:       proc(ctx: ^Context(T), focused: bool),

	// Callback procedure triggered when a key is pressed.
	key:            proc(ctx: ^Context(T), key: KeyEvent),
	// // Callback procedure triggered when a keyboard key is released.
	// key_released:            proc(event: KeyEvent, ctx: ^Context(T)),
	// // Called when text has been entered by the user.
	// text_input:              proc(event: Text_Input_Event, ctx: ^Context(T)),
	// // Called when the candidate text for an IME has changed.
	// text_edited:             proc(event: Text_Edited_Event, ctx: ^Context(T)),

	// Callback procedure triggered when the mouse is moved.
	mouse_position: proc(ctx: ^Context(T), position: MouseMovedEvent),
	// Callback procedure triggered when a mouse button is pressed.
	mouse_button:   proc(ctx: ^Context(T), button: MouseButtonEvent),
	// // Callback procedure triggered when a mouse button is released.
	// mouse_released:          proc(event: MouseButtonEvent, ctx: ^Context(T)),
	// Callback procedure triggered when the mouse wheel is moved.
	wheel_moved:    proc(ctx: ^Context(T), event: MouseWheelEvent),

	// // Called when a joystick button is pressed.
	// joystick_pressed:        proc(event: Joystick_Pressed_Event, ctx: ^Context(T)),
	// // Called when a joystick button is released.
	// joystick_released:       proc(event: Joystick_Pressed_Event, ctx: ^Context(T)),
	// // Called when a joystick axis moves.
	// joystick_axis:           proc(event: Joystick_Axis_Motion_Event, ctx: ^Context(T)),
	// // Called when a joystick hat direction changes.
	// joystick_hat:            proc(event: Joystick_Hat_Motion_Event, ctx: ^Context(T)),
	// // Called when a Joystick's virtual gamepad axis is moved.
	// gamepad_axis:            proc(event: Gamepad_Axis_Motion_Event, ctx: ^Context(T)),
	// // Called when a Joystick's virtual gamepad button is pressed.
	// gamepad_pressed:         proc(event: Gamepad_Pressed_Event, ctx: ^Context(T)),
	// // Called when a Joystick's virtual gamepad button is released.
	// gamepad_released:        proc(event: Gamepad_Pressed_Event, ctx: ^Context(T)),
	// // Called when a Joystick is connected.
	// joystick_added:          proc(event: Joystick_Status_Event, ctx: ^Context(T)),
	// // Called when a Joystick is disconnected.
	// joystick_removed:        proc(event: Joystick_Status_Event, ctx: ^Context(T)),
	// // Called when a Joystick sensor is updated.
	// joystick_sensor_updated: proc(event: Gamepad_Sensor_Update_Event, ctx: ^Context(T)),

	// Handle all pending events.
	handle_event:   proc(ctx: ^Context(T), event: Event),
}
