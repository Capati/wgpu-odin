package renderlink

Joystick_Hat :: enum u8 {
	Invalid,
	Centered,
	Up,
	Right,
	Down,
	Left,
	Right_Up,
	Right_Down,
	Left_Up,
	Left_Down,
}

Joystick_Type :: enum u8 {
	Unknown,
	Joystick,
	Wheel,
	Arcade_Stick,
	Flight_Stick,
	Dance_Pad,
	Guitar,
	Drum_Kit,
	Arcade_Pad,
	Throttle,
}

Gamepad_Type :: enum u8 {
	Unknown,
	Xbox_360,
	Xbox_One,
	Ps3,
	Ps4,
	Ps5,
	Nintendo_Switch_Pro,
	Amazon_Luna,
	Stadia,
	Virtual,
	Nvidia_Shield,
	Joycon_Left,
	Joycon_Right,
	Joycon_Pair,
}

Gamepad_Axis :: enum u8 {
	Invalid,
	Left_X,
	Left_Y,
	Right_X,
	Right_Y,
	Trigger_Left,
	Trigger_Right,
}

Gamepad_Button :: enum u8 {
	Invalid,
	A,
	B,
	X,
	Y,
	Back,
	Guide,
	Start,
	Left_Stick,
	Right_Stick,
	Left_Shoulder,
	Right_Shoulder,
	Dpad_Up,
	Dpad_Down,
	Dpad_Left,
	Dpad_Right,
	Misc1,
	Paddle1,
	Paddle2,
	Paddle3,
	Paddle4,
	Touchpad,
}

Joystick_Input_Type :: enum u8 {
	Axis,
	Button,
	Hat,
}

Gamepad_Input :: struct {
	type:  Joystick_Input_Type,
	value: union {
		Gamepad_Axis,
		Gamepad_Button,
	},
}

Joystick_Input_Axis :: struct {
	index: int,
}

Joystick_Input_Button :: struct {
	index: int,
}

Joystick_Input_Hat_Direction :: struct {
	index: int,
	value: Joystick_Hat,
}

Joystick_Input_Data :: union {
	Joystick_Input_Axis,
	Joystick_Input_Button,
	Joystick_Input_Hat_Direction,
}

Joystick_Input :: struct {
	type:  Joystick_Input_Type,
	value: Joystick_Input_Data,
}

Joystick_Vibration :: struct {
	left, right: f32,
	id:          int,
	end_time:    u32,
}

Joystick_Device_Info :: struct {
	vendor_id, product_id, product_version: u16,
}

Joystick_Input_Action :: enum u8 {
	Pressed,
	Released,
}

Joystick_Pressed_Event :: struct {
	joystick: Joystick,
	index:    u8,
	action:   Joystick_Input_Action,
}

Joystick_Axis_Motion_Event :: struct {
	joystick: Joystick,
	axis:     u8,
	value:    f32,
}

Joystick_Hat_Motion_Event :: struct {
	joystick:  Joystick,
	hat:       u8,
	direction: Joystick_Hat,
}

Gamepad_Pressed_Event :: struct {
	joystick: Joystick,
	button:   Gamepad_Button,
	action:   Joystick_Input_Action,
}

Gamepad_Axis_Motion_Event :: struct {
	joystick: Joystick,
	axis:     Gamepad_Axis,
	value:    f32,
}

Joystick_Status :: enum {
	Connected,
	Disconnected,
}

Joystick_Status_Event :: struct {
	joystick: Joystick,
	status:   Joystick_Status,
}

Gamepad_Sensor_Update_Event :: struct {
	joystick: Joystick,
	type:     Sensor_Type,
	data:     [3]f32,
}

Joystick_Event :: union {
	Joystick_Pressed_Event,
	Joystick_Axis_Motion_Event,
	Joystick_Hat_Motion_Event,
	Gamepad_Pressed_Event,
	Gamepad_Axis_Motion_Event,
	Joystick_Status_Event,
	Gamepad_Sensor_Update_Event,
}

Joystick :: struct {
	id:               i32,
	guid:             string,
	type:             Joystick_Type,
	name:             string,
	is_gamepad:       bool,
	rumble_supported: bool,
}

Joystick_List_Type :: map[i32]Joystick

Joystick_Error :: enum {
	None,
	Init_Failed,
	Invalid_Joystick_Device,
	Failed_To_Open_Joystick,
}

// Gets the number of connected joysticks.
joystick_get_connected_count :: _joystick_get_connected_count

// Gets a list of connected joysticks.
joystick_get_connected :: _joystick_get_connected

// Gets the direction of each axis.
joystick_get_axes :: _joystick_get_axes

// Gets the direction of an axis.
joystick_get_axis :: _joystick_get_axis

// Gets the number of axes on the _joystick_
joystick_get_axis_count :: _joystick_get_axis_count

// Gets the number of buttons on the _joystick_
joystick_get_button_count :: _joystick_get_button_count

// Gets the OS-independent device info of the _joystick_
joystick_get_device_info :: _joystick_get_device_info

// Gets a stable GUID unique to the type of the physical _joystick_
joystick_get_guid :: _joystick_get_guid

// Gets the direction of a virtual gamepad axis.
joystick_get_gamepad_axis :: _joystick_get_gamepad_axis

// Gets the axis or hat that a virtual gamepad input is bound to.
joystick_get_gamepad_mapping_axis :: _joystick_get_gamepad_mapping_axis

// Gets the button that a virtual gamepad input is bound to.
joystick_get_gamepad_mapping_button :: _joystick_get_gamepad_mapping_button

// Gets the button, axis or hat that a virtual gamepad input is bound to.
joystick_get_gamepad_mapping :: proc {
	joystick_get_gamepad_mapping_axis,
	joystick_get_gamepad_mapping_button,
}

// Gets the full gamepad mapping string of this Joystick, or `""` if it's not recognized
// as a gamepad.
joystick_get_gamepad_mapping_string :: _joystick_get_gamepad_mapping_string

// Gets the direction of a hat.
joystick_get_hat :: _joystick_get_hat

// Gets the number of hats on the _joystick_
joystick_get_hat_count :: _joystick_get_hat_count

// Gets the joystick's unique identifier.
joystick_get_id :: _joystick_get_id

// Gets the name of the _joystick_
joystick_get_name :: _joystick_get_name

// Gets whether the Joystick is connected.
joystick_is_connected :: _joystick_is_connected

// Gets whether the Joystick is recognized as a gamepad.
joystick_is_gamepad :: _joystick_is_gamepad

// Checks if a virtual gamepad button on the Joystick is pressed.
joystick_is_gamepad_down :: _joystick_is_gamepad_down

// Gets whether the Joystick supports vibration.
joystick_is_vibration_supported :: _joystick_is_vibration_supported

// Start the vibration on a Joystick.
joystick_start_vibration :: _joystick_start_vibration

// stops the vibration on a Joystick.
joystick_stop_vibration :: _joystick_stop_vibration

// Sets the vibration motor speeds on a Joystick with rumble support.
joystick_set_vibration :: proc {
	joystick_start_vibration,
	joystick_stop_vibration,
}
