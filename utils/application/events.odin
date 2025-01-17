#+vet !unused-imports
package application

// Packages
import intr "base:intrinsics"
import "base:runtime"
import "core:container/queue"
import "core:log"
import "core:time"
import "vendor:glfw"
import mu "vendor:microui"

// Local packages
import im "./../imgui"
import wmu "./../microui"

Input_Action :: enum u8 {
	None,
	Pressed,
	Released,
}

Key_Event :: struct {
	key:       Key,
	scancode:  i32,
	is_repeat: bool,
	action:    Input_Action,
}

Mouse_Position :: struct {
	x, y: f32,
}

Mouse_Moved_Event :: distinct Mouse_Position

Mouse_Button :: enum i32 {
	Unknown = -1,
	Left    = glfw.MOUSE_BUTTON_LEFT,
	Middle  = glfw.MOUSE_BUTTON_MIDDLE,
	Right   = glfw.MOUSE_BUTTON_RIGHT,
	Four    = glfw.MOUSE_BUTTON_4,
	Five    = glfw.MOUSE_BUTTON_5,
}

Mouse_Button_Event :: struct {
	button:  Mouse_Button,
	action:  Input_Action,
	pos:     Mouse_Position,
	presses: u32,
}

Mouse_Wheel_Event :: distinct Mouse_Position

Resize_Event :: Window_Size

Minimized_Event :: struct {
	value: bool,
}

Restored_Event :: struct {
	value: bool,
}

Quit_Event :: struct {}

Event :: union {
	Key_Event,
	// TextInputEvent,
	// TextEditedEvent,
	Mouse_Moved_Event,
	Mouse_Button_Event,
	Mouse_Wheel_Event,
	// JoystickPressedEvent,
	// JoystickAxisMotionEvent,
	// JoystickHatMotionEvent,
	// GamepadPressedEvent,
	// GamepadAxisMotionEvent,
	// JoystickStatusEvent,
	// GamepadSensorUpdateEvent,
	// FocusEvent,
	// MouseFocusEvent,
	Resize_Event,
	// VisibleEvent,
	// MovedEvent,
	Minimized_Event,
	Restored_Event,
	// DisplayRotatedEvent,
	Quit_Event,
}

/* FIFO Queue */
Event_List :: distinct queue.Queue(Event)

/* Default events queue capacity */
DEFAULT_EVENTS_CAPACITY :: #config(DEFAULT_EVENTS_CAPACITY, 16)

Event_State :: struct {
	data:            Event_List,
	window_dragging: bool,
}

event_init :: proc(self: ^Event_State) -> (ok: bool) {
	if err := queue.init(&self.data, DEFAULT_EVENTS_CAPACITY); err != nil {
		log.fatalf("Failed to initialize events: [%v]", err)
		return
	}
	return true
}

/* Clears the event queue. */
event_clear :: proc(self: ^Event_State) {
	queue.clear(&self.data)
}

// Pop the next event from the front of the FIFO event queue, if any, and return it.
event_poll :: proc(self: ^Event_State, event: ^Event) -> (has_next: bool) {
	event^, has_next = event_pop(self)
	return
}

// Adds an event to the event queue.
event_push :: proc(self: ^Event_State, event: Event) {
	queue.push_front(&self.data, event)
}

// Wait for and return the next available window event
event_wait :: proc(self: ^Event_State, event: ^Event, timeout: f64 = 0) -> (has_next: bool) {
	glfw.WaitEventsTimeout(timeout)
	event^, has_next = event_pop(self)
	return
}

event_pop :: proc(self: ^Event_State) -> (Event, bool) {
	if !event_is_empty(self) {
		return queue.pop_back_safe(&self.data)
	}
	return nil, false
}

event_has_next :: proc(self: ^Event_State) -> bool {
	return self.data.len > 0
}

event_is_empty :: proc(self: ^Event_State) -> bool {
	return self.data.len == 0
}

size_callback :: proc "c" (window: Window, width, height: i32) {
	context = runtime.default_context()
	app := cast(^Application)glfw.GetWindowUserPointer(window)
	size := Window_Size{u32(width), u32(height)}
	app.framebuffer_size = size
	// Avoid stack multiple events while user is resizing
	if app.should_resize {
		return
	}
	event_push(&app.events, size)
	app.should_resize = true
}

minimize_callback :: proc "c" (window: Window, iconified: i32) {
	context = runtime.default_context()
	app := cast(^Application)glfw.GetWindowUserPointer(window)
	app.minimized = bool(iconified)
	event_push(&app.events, Minimized_Event{bool(iconified)})
}

focus_callback :: proc "c" (window: Window, focused: i32) {
	context = runtime.default_context()
	app := cast(^Application)glfw.GetWindowUserPointer(window)
	event_push(&app.events, Restored_Event{bool(focused)})
}

key_callback :: proc "c" (window: Window, key, scancode, action, mods: i32) {
	context = runtime.default_context()
	app := cast(^Application)glfw.GetWindowUserPointer(window)
	event_push(
		&app.events,
		Key_Event {
			key = Key(key),
			scancode = scancode,
			action = .Pressed if action == glfw.PRESS || action == glfw.REPEAT else .Released,
		},
	)
}

cursor_position_callback :: proc "c" (window: Window, xpos, ypos: f64) {
	context = runtime.default_context()
	app := cast(^Application)glfw.GetWindowUserPointer(window)
	event_push(&app.events, Mouse_Moved_Event{x = f32(xpos), y = f32(ypos)})
}

mouse_button_callback :: proc "c" (window: Window, button, action, mods: i32) {
	context = runtime.default_context()
	app := cast(^Application)glfw.GetWindowUserPointer(window)
	xpos, ypos := glfw.GetCursorPos(window)
	event_push(
		&app.events,
		Mouse_Button_Event {
			button = Mouse_Button(button),
			action = .Pressed if action == glfw.PRESS else .Released,
			pos = {x = f32(xpos), y = f32(ypos)},
		},
	)
}

scroll_callback :: proc "c" (window: Window, xoffset, yoffset: f64) {
	context = runtime.default_context()
	app := cast(^Application)glfw.GetWindowUserPointer(window)
	event_push(&app.events, Mouse_Wheel_Event{f32(xoffset), f32(yoffset)})
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
		case Key_Event:
			if app.exit_key != .Unknown && ev.key == app.exit_key {
				quit(app)
			}
			if app.callbacks.key != nil {
				app.callbacks.key(app, ev)
			}

		case Mouse_Button_Event:
			if app.callbacks.mouse_button != nil {
				app.callbacks.mouse_button(app, ev)
			}

		case Mouse_Moved_Event:
			if app.callbacks.mouse_position != nil {
				app.callbacks.mouse_position(app, ev)
			}

		case Mouse_Wheel_Event:
			if app.callbacks.wheel_moved != nil {
				app.callbacks.wheel_moved(app, ev)
			}

		case Minimized_Event:
			if app.callbacks.minimized != nil {
				app.callbacks.minimized(app, ev.value)
			}

		case Restored_Event:
			if app.callbacks.restored != nil {
				app.callbacks.restored(app, ev.value)
			}

		case Window_Size:
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
				when ENABLE_IMGUI {
					if imgui_is_initialized(app) {
						im.wgpu_recreate_device_objects() or_return
					}
				}
				if microui_is_initialized(app) {
					wmu.resize(i32(app.framebuffer_size.w), i32(app.framebuffer_size.h))
				}
				if app.callbacks.resize != nil {
					app.callbacks.resize(app, app.framebuffer_size)
				}
			}

		case Quit_Event:
			quit(app)
		}

		if app.callbacks.handle_event != nil {
			app.callbacks.handle_event(app, event)
		}
	}

	return true
}

Callback_List :: struct($T: typeid) where intr.type_is_struct(T) {
	// This procedure is called exactly once at the beginning of the application.
	init:           proc(ctx: ^Context(T)) -> bool,
	// Callback procedure triggered when the application is closed.
	quit:           proc(ctx: ^Context(T)),
	// Callback procedure used to update the state of the ImGui every frame.
	imgui_update:   proc(ctx: ^Context(T), im_ctx: ^im.Context) -> (ok: bool),
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
	resize:         proc(ctx: ^Context(T), size: Window_Size) -> bool,
	// // Callback procedure triggered when window is shown or hidden.
	// visible:                 proc(event: Visible_Event, ctx: ^Context(T)),
	// // Callback procedure triggered when window is moved (dragged).
	// moved:                   proc(event: Moved_Event, ctx: ^Context(T)),
	// Callback procedure triggered when window is minimized.
	minimized:      proc(ctx: ^Context(T), minimized: bool),
	// Callback procedure triggered when window is restored.
	restored:       proc(ctx: ^Context(T), focused: bool),

	// Callback procedure triggered when a key is pressed.
	key:            proc(ctx: ^Context(T), key: Key_Event),
	// // Callback procedure triggered when a keyboard key is released.
	// key_released:            proc(event: Key_Event, ctx: ^Context(T)),
	// // Called when text has been entered by the user.
	// text_input:              proc(event: Text_Input_Event, ctx: ^Context(T)),
	// // Called when the candidate text for an IME has changed.
	// text_edited:             proc(event: Text_Edited_Event, ctx: ^Context(T)),

	// Callback procedure triggered when the mouse is moved.
	mouse_position: proc(ctx: ^Context(T), position: Mouse_Moved_Event),
	// Callback procedure triggered when a mouse button is pressed.
	mouse_button:   proc(ctx: ^Context(T), button: Mouse_Button_Event),
	// // Callback procedure triggered when a mouse button is released.
	// mouse_released:          proc(event: Mouse_Button_Event, ctx: ^Context(T)),
	// Callback procedure triggered when the mouse wheel is moved.
	wheel_moved:    proc(ctx: ^Context(T), event: Mouse_Wheel_Event),

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
