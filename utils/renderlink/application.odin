package renderlink

// STD Library
import intr "base:intrinsics"
import "core:log"
import "core:time"

Application_Context :: struct {
	gpu               : ^Graphics_Context,
	settings          : Settings,
	initialized       : bool,
	target_frame_time : time.Duration,
	timer             : Timer,
	running           : bool,
}

Context :: struct($T: typeid) where intr.type_is_struct(T) {
	using app   : ^Application_Context,
	using state : T,
	callbacks   : Callback_List(T),
}

Settings :: struct {
	using window   : Window_Settings,
	using renderer : Renderer_Settings,
}

DEFAULT_SETTINGS :: Settings {
	window   = DEFAULT_WINDOW_SETTINGS,
	renderer = DEFAULT_RENDERER_SETTINGS,
}

@(private)
g_logger: log.Logger // For "contextless" and "c" procedures

@(require_results)
init :: proc(
	state: ^$T,
	settings := DEFAULT_SETTINGS,
	loc := #caller_location,
) -> (
	ok: bool,
) where intr.type_is_specialization_of(T, Context) {
	when ODIN_DEBUG {
		g_logger = context.logger
	}
	return _init(state, settings, loc)
}

destroy :: proc() {
	_destroy()
}

Callback_List :: struct($T: typeid) where intr.type_is_struct(T) {
	// This procedure is called exactly once at the beginning of the game.
	init:                    proc(ctx: ^Context(T)) -> bool,
	// Callback procedure triggered when the game is closed.
	quit:                    proc(ctx: ^Context(T)),
	// Callback procedure used to update the state of the game every frame.
	update:                  proc(dt: f64, ctx: ^Context(T)) -> bool,
	// Callback procedure used for compute operations every frame.
	compute:                    proc(ctx: ^Context(T)) -> bool,
	// Callback procedure used to draw on the screen every frame.
	draw:                    proc(ctx: ^Context(T)) -> bool,

	// Callback procedure triggered when a directory is dragged and dropped onto the window.
	display_rotated:         proc(event: Display_Rotated_Event, ctx: ^Context(T)),
	// Callback procedure triggered when window receives or loses focus.
	focus:                   proc(event: Focus_Event, ctx: ^Context(T)),
	// Callback procedure triggered when window receives or loses mouse focus.
	mouse_focus:             proc(event: Mouse_Focus_Event, ctx: ^Context(T)),
	// Called when the window is resized.
	resize:                  proc(event: Resize_Event, ctx: ^Context(T)) -> bool,
	// Callback procedure triggered when window is shown or hidden.
	visible:                 proc(event: Visible_Event, ctx: ^Context(T)),
	// Callback procedure triggered when window is moved (dragged).
	moved:                   proc(event: Moved_Event, ctx: ^Context(T)),
	// Callback procedure triggered when window is minimized.
	minimized:               proc(event: Minimized_Event, ctx: ^Context(T)),
	// Callback procedure triggered when window is restored.
	restored:                proc(event: Restored_Event, ctx: ^Context(T)),

	// Callback procedure triggered when a key is pressed.
	key_pressed:             proc(event: Key_Event, ctx: ^Context(T)),
	// Callback procedure triggered when a keyboard key is released.
	key_released:            proc(event: Key_Event, ctx: ^Context(T)),
	// Called when text has been entered by the user.
	text_input:              proc(event: Text_Input_Event, ctx: ^Context(T)),
	// Called when the candidate text for an IME has changed.
	text_edited:             proc(event: Text_Edited_Event, ctx: ^Context(T)),

	// Callback procedure triggered when the mouse is moved.
	mouse_moved:             proc(event: Mouse_Moved_Event, ctx: ^Context(T)),
	// Callback procedure triggered when a mouse button is pressed.
	mouse_pressed:           proc(event: Mouse_Button_Event, ctx: ^Context(T)),
	// Callback procedure triggered when a mouse button is released.
	mouse_released:          proc(event: Mouse_Button_Event, ctx: ^Context(T)),
	// Callback procedure triggered when the mouse wheel is moved.
	wheel_moved:             proc(event: Mouse_Wheel_Event, ctx: ^Context(T)),

	// Called when a joystick button is pressed.
	joystick_pressed:        proc(event: Joystick_Pressed_Event, ctx: ^Context(T)),
	// Called when a joystick button is released.
	joystick_released:       proc(event: Joystick_Pressed_Event, ctx: ^Context(T)),
	// Called when a joystick axis moves.
	joystick_axis:           proc(event: Joystick_Axis_Motion_Event, ctx: ^Context(T)),
	// Called when a joystick hat direction changes.
	joystick_hat:            proc(event: Joystick_Hat_Motion_Event, ctx: ^Context(T)),
	// Called when a Joystick's virtual gamepad axis is moved.
	gamepad_axis:            proc(event: Gamepad_Axis_Motion_Event, ctx: ^Context(T)),
	// Called when a Joystick's virtual gamepad button is pressed.
	gamepad_pressed:         proc(event: Gamepad_Pressed_Event, ctx: ^Context(T)),
	// Called when a Joystick's virtual gamepad button is released.
	gamepad_released:        proc(event: Gamepad_Pressed_Event, ctx: ^Context(T)),
	// Called when a Joystick is connected.
	joystick_added:          proc(event: Joystick_Status_Event, ctx: ^Context(T)),
	// Called when a Joystick is disconnected.
	joystick_removed:        proc(event: Joystick_Status_Event, ctx: ^Context(T)),
	// Called when a Joystick sensor is updated.
	joystick_sensor_updated: proc(event: Gamepad_Sensor_Update_Event, ctx: ^Context(T)),

	// Handle all pending events.
	handle_events:           proc(event: Event, ctx: ^Context(T)),
}
