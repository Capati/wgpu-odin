//+private
//+build linux, darwin, windows
package application

// STD Library
import "base:runtime"
import "core:log"
import "core:strings"

// Vendor
import sdl "vendor:sdl2"

Joystick_Vibration_Impl :: struct {
	using _base: Joystick_Vibration,
	data:        [4]u16,
	effect:      sdl.HapticEffect,
}

Joystick_Impl :: struct {
	using _base: Joystick,
	handle:      ^sdl.Joystick,
	controller:  ^sdl.GameController,
	haptic:      ^sdl.Haptic,
	instance_id: sdl.JoystickID,
	axes:        []f32,
	vibration:   Joystick_Vibration_Impl,
}

Joystick_List_Type_Impl :: map[sdl.JoystickID]^Joystick_Impl

Joystick_State :: struct {
	allocator:           runtime.Allocator,
	found:               Joystick_List_Type_Impl,
	connected:           Joystick_List_Type,
	recent_gamepad_guid: map[string]bool,
}

g_joystick: Joystick_State

@(require_results)
_joystick_init :: proc(allocator := context.allocator) -> (err: Error) {
	if sdl.InitSubSystem({.JOYSTICK, .GAMECONTROLLER}) < 0 {
		log.errorf("Could not initialize SDL joystick/gamepad subsystem: [%s]", sdl.GetError())
		return Joystick_Error.Init_Failed
	}

	g_joystick.allocator = allocator
	defer if err != nil do destroy()

	g_joystick.found.allocator = allocator
	g_joystick.connected.allocator = allocator
	g_joystick.recent_gamepad_guid.allocator = allocator

	num_joysticks := sdl.NumJoysticks()
	for i in 0 ..< num_joysticks {
		_joystick_add(i) or_return
	}

	sdl.JoystickEventState(sdl.ENABLE)
	sdl.GameControllerEventState(sdl.ENABLE)

	num_keys: i32
	sdl.GetKeyboardState(&num_keys)

	return
}

_joystick_destroy :: proc() {
	for _, joystick in g_joystick.found {
		_joystick_destroy_joystick(joystick, g_joystick.allocator)
	}

	delete(g_joystick.found)
	delete(g_joystick.connected)
	delete(g_joystick.recent_gamepad_guid)
}

_joystick_destroy_joystick :: proc(joystick: ^Joystick_Impl, allocator: runtime.Allocator) {
	_joystick_close(joystick)
	delete(joystick.guid)
	delete(joystick.name)
	delete(joystick.axes)
	free(joystick, allocator)
}

// Attempts to add a new joystick or reuse an existing disconnected one.
_joystick_add :: proc(device_id: i32) -> (joystick: ^Joystick_Impl, err: Error) {
	if device_id < 0 || device_id > sdl.NumJoysticks() {
		err = .Invalid_Joystick_Device
		log.errorf("Invalid joystick device id: [%d]", device_id)
		return
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	temp_guid := _joystick_get_device_guid(device_id, context.temp_allocator) or_return

	// Try to re-use a disconnected Joystick with the same GUID.
	for _, joy in g_joystick.found {
		if joy.guid == temp_guid {
			joystick = joy
			if !_joystick_native_is_connected(joy) {
				_joystick_add_to_connected(joystick)
			}
			return
		}
	}

	joystick = _joystick_create(device_id, g_joystick.allocator) or_return
	defer if err != nil do free(joystick)
	g_joystick.found[joystick.instance_id] = joystick

	if joystick.is_gamepad {
		g_joystick.recent_gamepad_guid[joystick.guid] = true
	}

	_joystick_add_to_connected(joystick)

	return
}

_joystick_add_to_connected :: proc(joystick: ^Joystick_Impl) {
	connected_id := i32(joystick.instance_id)
	if connected_id not_in g_joystick.connected {
		g_joystick.connected[connected_id] = joystick._base
		log.infof("Connected joystick %d: [%s]", joystick.id, joystick.name)
	}
}

_joystick_create :: proc(
	device_id: i32,
	allocator := context.allocator,
) -> (
	joystick: ^Joystick_Impl,
	err: Error,
) {
	joystick = new(Joystick_Impl, allocator) or_return
	defer if err != nil do free(joystick)

	joystick.handle = sdl.JoystickOpen(device_id)
	if joystick.handle == nil {
		err = .Failed_To_Open_Joystick
		log.errorf("Failed to open joystick [%d]", device_id)
		return
	}
	defer if err != nil do sdl.JoystickClose(joystick.handle)

	when SDL_MAJOR_VERSION_ATLEAST_2_0_18 {
		joystick.rumble_supported = bool(sdl.JoystickHasRumble(joystick.handle))
	} else {
		joystick.rumble_supported = sdl.JoystickRumble(joystick.handle, 0, 0, 0) != -1
	}

	joystick.instance_id = sdl.JoystickInstanceID(joystick.handle)
	joystick.id = i32(joystick.instance_id)

	// Get GUID
	sdl_guid := sdl.JoystickGetGUID(joystick.handle)
	guid_buffer: [GUID_BUFFER_SIZE]byte
	sdl.JoystickGetGUIDString(sdl_guid, &guid_buffer[0], len(guid_buffer))
	nul := nul_search_bytes(guid_buffer[:])
	guid_buffer[nul] = 0
	joystick.guid = strings.clone_from_bytes(guid_buffer[:nul], allocator) or_return
	defer if err != nil do delete(joystick.guid)

	// Open as Game Controller if possible
	joystick.controller = sdl.GameControllerOpen(device_id)
	joystick.is_gamepad = joystick.controller != nil
	defer if err != nil && joystick.is_gamepad do sdl.GameControllerClose(joystick.controller)

	// Get name
	joy_name := sdl.JoystickName(joystick.handle)
	if joy_name == nil && joystick.controller != nil {
		joy_name = sdl.GameControllerName(joystick.controller)
	}
	if joy_name != nil {
		joystick.name = strings.clone_from_cstring(joy_name, allocator) or_return
	}
	defer if err != nil && joy_name != nil do delete(joystick.name)

	sdl_type := sdl.JoystickGetType(joystick.handle)

	#partial switch sdl_type {
	case .GAMECONTROLLER:
		joystick.type = .Joystick
	case .WHEEL:
		joystick.type = .Wheel
	case .ARCADE_STICK:
		joystick.type = .Arcade_Stick
	case .FLIGHT_STICK:
		joystick.type = .Flight_Stick
	case .DANCE_PAD:
		joystick.type = .Dance_Pad
	case .GUITAR:
		joystick.type = .Guitar
	case .DRUM_KIT:
		joystick.type = .Drum_Kit
	case .ARCADE_PAD:
		joystick.type = .Arcade_Pad
	case .THROTTLE:
		joystick.type = .Throttle
	case:
		joystick.type = .Unknown
	}

	num_axes := max(0, sdl.JoystickNumAxes(joystick.handle))
	joystick.axes = make([]f32, num_axes, allocator) or_return
	defer if err != nil do delete(joystick.axes)

	joystick.vibration.end_time = sdl.HAPTIC_INFINITY
	joystick.vibration.id = -1

	return
}

_joystick_remove_connected_guid :: proc(guid: string) {
	id: i32 = -1
	for key, joy in g_joystick.connected {
		if guid == joy.guid {
			id = key
			break
		}
	}

	if id != -1 {
		delete_key(&g_joystick.connected, id)
	}
}

_joystick_remove_connected_joystick :: proc(joystick: ^Joystick_Impl) {
	if joy, ok := g_joystick.connected[i32(joystick.instance_id)]; ok {
		delete_key(&g_joystick.connected, joy.id)
	}
}

_joystick_remove_connected :: proc {
	_joystick_remove_connected_guid,
	_joystick_remove_connected_joystick,
}

GUID_BUFFER_SIZE :: 33

_joystick_get_device_guid :: proc(
	id: i32,
	allocator := context.allocator,
) -> (
	str: string,
	err: Error,
) {
	buffer: [GUID_BUFFER_SIZE]byte

	if id < 0 || id >= sdl.NumJoysticks() {
		return
	}

	guid := sdl.JoystickGetDeviceGUID(id)
	sdl.JoystickGetGUIDString(guid, &buffer[0], len(buffer))

	nul := nul_search_bytes(buffer[:])
	str = strings.clone_from_bytes(buffer[:nul], allocator) or_return

	return
}

_joystick_close :: proc "contextless" (joystick: ^Joystick_Impl) {
	if joystick.haptic != nil {
		sdl.HapticClose(joystick.haptic)
	}

	if joystick.controller != nil {
		sdl.GameControllerClose(joystick.controller)
	}

	if joystick.handle != nil {
		sdl.JoystickClose(joystick.handle)
	}
}

SDL_BUTTON_TO_GAMEPAD_BUTTON_MAP := [21]Gamepad_Button {
	.A,
	.B,
	.X,
	.Y,
	.Back,
	.Guide,
	.Start,
	.Left_Stick,
	.Right_Stick,
	.Left_Shoulder,
	.Right_Shoulder,
	.Dpad_Up,
	.Dpad_Down,
	.Dpad_Left,
	.Dpad_Right,
	.Misc1,
	.Paddle1,
	.Paddle2,
	.Paddle3,
	.Paddle4,
	.Touchpad,
}

_joystick_sdl_button_to_gamepad_button :: proc(
	index: u8,
) -> (
	button: Gamepad_Button,
	ok: bool,
) #optional_ok {
	button = .Invalid
	if int(index) < len(SDL_BUTTON_TO_GAMEPAD_BUTTON_MAP) {
		button = SDL_BUTTON_TO_GAMEPAD_BUTTON_MAP[index]
		ok = button != .Invalid
	}
	return
}

_joystick_get_from_id :: #force_inline proc "contextless" (
	id: i32,
) -> (
	^Joystick_Impl,
	bool,
) #no_bounds_check #optional_ok {
	return _joystick_get_from_instance_id(cast(sdl.JoystickID)id)
}

_joystick_get_from_instance_id :: #force_inline proc "contextless" (
	instance_id: sdl.JoystickID,
) -> (
	^Joystick_Impl,
	bool,
) #no_bounds_check #optional_ok {
	if joy, ok := g_joystick.found[instance_id]; ok {
		if joy != nil do return joy, true
	}
	return nil, false
}

_joystick_get_valid_connected :: proc "contextless" (
	id: i32,
) -> (
	joy: ^Joystick_Impl,
	ok: bool,
) #optional_ok {
	joy = _joystick_get_from_id(id)
	if joy == nil {
		return nil, false
	}
	ok = _joystick_native_is_connected(joy)
	return
}

_joystick_native_get_axis_count :: proc "contextless" (joystick: ^Joystick_Impl) -> int {
	return int(sdl.JoystickNumAxes(joystick.handle))
}

_joystick_native_get_button_count :: proc "contextless" (joystick: ^Joystick_Impl) -> int {
	return int(sdl.JoystickNumButtons(joystick.handle))
}

JOYSTICK_NATIVE_AXIS: [Gamepad_Axis]sdl.GameControllerAxis = {
	Gamepad_Axis.Invalid       = sdl.GameControllerAxis.INVALID,
	Gamepad_Axis.Left_X        = sdl.GameControllerAxis.LEFTX,
	Gamepad_Axis.Left_Y        = sdl.GameControllerAxis.LEFTY,
	Gamepad_Axis.Right_X       = sdl.GameControllerAxis.RIGHTX,
	Gamepad_Axis.Right_Y       = sdl.GameControllerAxis.RIGHTY,
	Gamepad_Axis.Trigger_Left  = sdl.GameControllerAxis.TRIGGERLEFT,
	Gamepad_Axis.Trigger_Right = sdl.GameControllerAxis.TRIGGERRIGHT,
}

JOYSTICK_NATIVE_SDL_AXIS_TO_GAMEPAD_AXIS: [6]Gamepad_Axis = {
	sdl.GameControllerAxis.LEFTX        = .Left_X,
	sdl.GameControllerAxis.LEFTY        = .Left_Y,
	sdl.GameControllerAxis.RIGHTX       = .Right_X,
	sdl.GameControllerAxis.RIGHTY       = .Right_Y,
	sdl.GameControllerAxis.TRIGGERLEFT  = .Trigger_Left,
	sdl.GameControllerAxis.TRIGGERRIGHT = .Trigger_Right,
}

_joystick_sdl_gamepad_axis_to_gamepad_axis :: proc "contextless" (
	axis: u8,
) -> (
	Gamepad_Axis,
	bool,
) #no_bounds_check #optional_ok {
	if axis >= len(JOYSTICK_NATIVE_SDL_AXIS_TO_GAMEPAD_AXIS) {
		return .Invalid, false
	}
	return JOYSTICK_NATIVE_SDL_AXIS_TO_GAMEPAD_AXIS[axis], true
}

JOYSTICK_NATIVE_BUTTONS: [Gamepad_Button]sdl.GameControllerButton = {
	Gamepad_Button.Invalid        = sdl.GameControllerButton.INVALID,
	Gamepad_Button.A              = sdl.GameControllerButton.A,
	Gamepad_Button.B              = sdl.GameControllerButton.B,
	Gamepad_Button.X              = sdl.GameControllerButton.X,
	Gamepad_Button.Y              = sdl.GameControllerButton.Y,
	Gamepad_Button.Back           = sdl.GameControllerButton.BACK,
	Gamepad_Button.Guide          = sdl.GameControllerButton.GUIDE,
	Gamepad_Button.Start          = sdl.GameControllerButton.START,
	Gamepad_Button.Left_Stick     = sdl.GameControllerButton.LEFTSTICK,
	Gamepad_Button.Right_Stick    = sdl.GameControllerButton.RIGHTSTICK,
	Gamepad_Button.Left_Shoulder  = sdl.GameControllerButton.LEFTSHOULDER,
	Gamepad_Button.Right_Shoulder = sdl.GameControllerButton.RIGHTSHOULDER,
	Gamepad_Button.Dpad_Up        = sdl.GameControllerButton.DPAD_UP,
	Gamepad_Button.Dpad_Down      = sdl.GameControllerButton.DPAD_DOWN,
	Gamepad_Button.Dpad_Left      = sdl.GameControllerButton.DPAD_LEFT,
	Gamepad_Button.Dpad_Right     = sdl.GameControllerButton.DPAD_RIGHT,
	Gamepad_Button.Misc1          = sdl.GameControllerButton.MISC1,
	Gamepad_Button.Paddle1        = sdl.GameControllerButton.PADDLE1,
	Gamepad_Button.Paddle2        = sdl.GameControllerButton.PADDLE2,
	Gamepad_Button.Paddle3        = sdl.GameControllerButton.PADDLE3,
	Gamepad_Button.Paddle4        = sdl.GameControllerButton.PADDLE4,
	Gamepad_Button.Touchpad       = sdl.GameControllerButton.TOUCHPAD,
}

JOYSTICK_NATIVE_HAT: [14]Joystick_Hat = {
	sdl.HAT_CENTERED  = .Centered,
	sdl.HAT_UP        = .Up,
	sdl.HAT_RIGHT     = .Right,
	sdl.HAT_DOWN      = .Down,
	sdl.HAT_LEFT      = .Left,
	sdl.HAT_RIGHTUP   = .Right_Up,
	sdl.HAT_RIGHTDOWN = .Right_Down,
	sdl.HAT_LEFTUP    = .Left_Up,
	sdl.HAT_LEFTDOWN  = .Left_Down,
}

_joystick_native_get_gamepad_mapping :: proc "contextless" (
	joystick: Joystick,
	input: Gamepad_Input,
) -> (
	joystick_input: Joystick_Input,
) {
	if !joystick.is_gamepad do return

	sdl_bind: sdl.GameControllerButtonBind

	joy := _joystick_get_from_id(joystick.id)

	switch v in input.value {
	case Gamepad_Button:
		sdl_bind = sdl.GameControllerGetBindForButton(joy.controller, JOYSTICK_NATIVE_BUTTONS[v])
	case Gamepad_Axis:
		sdl_bind = sdl.GameControllerGetBindForAxis(joy.controller, JOYSTICK_NATIVE_AXIS[v])
	}

	#partial switch sdl_bind.bindType {
	case .BUTTON:
		joystick_input.type = .Button
		joystick_input.value = Joystick_Input_Button {
			index = int(sdl_bind.value.button),
		}
	case .AXIS:
		joystick_input.type = .Axis
		joystick_input.value = Joystick_Input_Axis {
			index = int(sdl_bind.value.axis),
		}
	case .HAT:
		joystick_input.type = .Hat
		index := int(sdl_bind.value.hat.hat)
		joystick_input.value = Joystick_Input_Hat_Direction {
			index = index,
			value = JOYSTICK_NATIVE_HAT[index],
		}
	}

	return
}

_joystick_sdl_hat_to_joystick_hat :: proc "contextless" (index: u8) -> (hat: Joystick_Hat) {
	// odinfmt: disable
	switch index {
	case sdl.HAT_CENTERED:  hat = .Centered
	case sdl.HAT_UP:  hat = .Up
	case sdl.HAT_RIGHT:  hat = .Right
	case sdl.HAT_DOWN:  hat = .Down
	case sdl.HAT_LEFT:  hat = .Left
	case sdl.HAT_RIGHTUP:  hat = .Right_Up
	case sdl.HAT_RIGHTDOWN:  hat = .Right_Down
	case sdl.HAT_LEFTUP:  hat = .Left_Up
	case sdl.HAT_LEFTDOWN:  hat = .Left_Down
	}
	// odinfmt: enable

	return
}

_get_hat_count :: proc "contextless" (joystick: ^Joystick_Impl) -> int {
	return int(sdl.JoystickNumHats(joystick.handle))
}

_joystick_get_vibration :: proc "contextless" (joystick: Joystick) -> (left, right: f32) {
	if joy, ok := _joystick_get_valid_connected(joystick.id); ok {
		if joy.vibration.end_time != sdl.HAPTIC_INFINITY {
			if sdl.TICKS_PASSED(sdl.GetTicks(), joy.vibration.end_time) {
				_joystick_native_reset_vibration(joy)
				joy.vibration.end_time = sdl.HAPTIC_INFINITY
			}
		}

		id := joy.vibration.id

		if joy.haptic == nil || id == -1 || sdl.HapticGetEffectStatus(joy.haptic, i32(id)) != 1 {
			joy.vibration.left = 0.0
			joy.vibration.right = 0.0
		}

		left = joy.vibration.left
		right = joy.vibration.right
	}

	return
}

_joystick_native_is_connected :: proc "contextless" (joystick: ^Joystick_Impl) -> bool {
	return bool(sdl.JoystickGetAttached(joystick.handle))
}

// _joystick_is_gamepad :: proc "contextless" (joystick: Joystick) -> bool {
// 	return _joystick_native_is_gamepad(_joystick_get_from_id(joystick.id))
// }

_joystick_native_is_gamepad :: proc "contextless" (joystick: ^Joystick_Impl) -> bool {
	return joystick.controller != nil
}

_check_create_haptic :: proc(joystick: ^Joystick_Impl) -> bool {
	if sdl.WasInit({.HAPTIC}) == {} && sdl.InitSubSystem({.HAPTIC}) < 0 {
		return false
	}

	if joystick.haptic != nil && sdl.HapticIndex(joystick.haptic) != -1 {
		return true
	}

	if joystick.haptic != nil {
		sdl.HapticClose(joystick.haptic)
	}

	joystick.haptic = sdl.HapticOpenFromJoystick(joystick.handle)

	if joystick.haptic == nil {
		log.warn(string(sdl.GetError()))
		return false
	}

	return true
}

_joystick_native_run_vibration_effect :: proc(joystick: ^Joystick_Impl) -> bool {
	if joystick.vibration.id != -1 {
		if sdl.HapticUpdateEffect(
			   joystick.haptic,
			   i32(joystick.vibration.id),
			   &joystick.vibration.effect,
		   ) ==
		   0 {
			if sdl.HapticRunEffect(joystick.haptic, i32(joystick.vibration.id), 1) == 0 {
				return true
			}
		}

		sdl.HapticDestroyEffect(joystick.haptic, i32(joystick.vibration.id))
		joystick.vibration.id = -1
	}

	joystick.vibration.id = int(sdl.HapticNewEffect(joystick.haptic, &joystick.vibration.effect))

	if joystick.vibration.id != -1 {
		if sdl.HapticRunEffect(joystick.haptic, i32(joystick.vibration.id), 1) == 0 {
			return true
		}
	}

	return false
}

_joystick_native_reset_vibration :: proc "contextless" (
	joystick: ^Joystick_Impl,
) -> (
	success: bool,
) {
	success = sdl.JoystickRumble(joystick.handle, 0, 0, 0) == 0

	if !success {
		if sdl.WasInit({.HAPTIC}) == {} &&
		   joystick.haptic != nil &&
		   sdl.HapticIndex(joystick.haptic) != -1 {
			success = (sdl.HapticStopEffect(joystick.haptic, i32(joystick.vibration.id)) == 0)
		}
	}

	if success {
		joystick.vibration.left = 0.0
		joystick.vibration.right = 0.0
	}

	return
}

// <https://wiki.libsdl.org/SDL2/SDL_JoystickGetAxis>
MAX_JOYSTICK_GET_AXIS_VALUE: f32 : 32768.0

_joystick_clamp_value :: #force_inline proc "contextless" (x: f32) -> f32 {
	if abs(x) < 0.01 {
		return 0.0
	}
	if x < -0.99 {
		return -1.0
	}
	if x > 0.99 {
		return 1.0
	}
	return x
}

// odinfmt: disable
SDL_MAJOR_VERSION_ATLEAST_2_0_18 :: sdl.MAJOR_VERSION == 2 && sdl.MINOR_VERSION > 0 ||
                                	(sdl.MINOR_VERSION == 0 && sdl.PATCHLEVEL >= 18)
// odinfmt: enable
