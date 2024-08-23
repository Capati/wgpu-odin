//+build linux, darwin, windows
package application

// STD Library
import "base:runtime"
import "core:slice"
import "core:strings"

// Vendor
import sdl "vendor:sdl2"

when JOYSTICK_PACKAGE {
@(require_results)
_joystick_get_connected_count :: proc "contextless" () -> int {
	return len(g_app.joystick.connected)
}

@(require_results)
_joystick_get_connected :: proc(
	allocator := context.allocator,
) -> (
	joystick_slice: []Joystick,
	err: runtime.Allocator_Error,
) {
	joystick_slice = make([]Joystick, len(g_app.joystick.connected), allocator) or_return
	i := 0
	for _, joystick in g_app.joystick.connected {
		joystick_slice[i] = joystick
		i += 1
	}

	sort_joysticks_by_id :: proc(joysticks: []Joystick) {
		slice.stable_sort_by(joysticks, proc(a, b: Joystick) -> bool {
			return a.id < b.id
		})
	}

	if len(joystick_slice) > 1 {
		sort_joysticks_by_id(joystick_slice)
	}

	return
}

@(require_results)
_joystick_get_axes :: proc "contextless" (joystick: Joystick) -> (axes: []f32) {
	if joy, ok := _joystick_get_valid_connected(joystick.id); ok {
		if len(joy.axes) == 0 do return
		for &v, i in joy.axes {
			v = _joystick_clamp_value(
				f32(sdl.JoystickGetAxis(joy.handle, i32(i))) / MAX_JOYSTICK_GET_AXIS_VALUE,
			)
		}
		return joy.axes[:]
	}
	return
}

@(require_results)
_joystick_get_axis :: proc "contextless" (joystick: Joystick, axis_index: int) -> f32 {
	if joy, ok := _joystick_get_valid_connected(joystick.id); ok {
		if axis_index < 0 || axis_index >= _joystick_get_axis_count(joy) do return 0.0
		return _joystick_clamp_value(
			f32(sdl.JoystickGetAxis(joy.handle, i32(axis_index))) /
			MAX_JOYSTICK_GET_AXIS_VALUE,
		)
	}
	return 0.0
}

@(require_results)
_joystick_get_axis_count :: proc "contextless" (joystick: Joystick) -> int {
	if joy, ok := _joystick_get_valid_connected(joystick.id); ok {
		return _joystick_native_get_axis_count(joy)
	}
	return 0.0
}

@(require_results)
_joystick_get_button_count :: proc "contextless" (joystick: Joystick) -> int {
	if joy, ok := _joystick_get_valid_connected(joystick.id); ok {
		return _joystick_native_get_button_count(joy)
	}
	return 0
}

@(require_results)
_joystick_get_device_info :: proc "contextless" (
	joystick: Joystick,
) -> (
	info: Joystick_Device_Info,
) {
	joy := _joystick_get_from_id(joystick.id)
	if joy == nil || joy.handle == nil do return

	info.vendor_id = sdl.JoystickGetVendor(joy.handle)
	info.product_id = sdl.JoystickGetProduct(joy.handle)
	info.product_version = sdl.JoystickGetProductVersion(joy.handle)

	return
}

@(require_results)
_joystick_get_guid :: proc "contextless" (joystick: Joystick) -> string {
	return joystick.guid
}

@(require_results)
_joystick_get_gamepad_axis :: proc "contextless" (
	joystick: Joystick,
	axis: Gamepad_Axis,
) -> (
	out: f32,
) {
	if !joystick.is_gamepad do return
	if joy, ok := _joystick_get_valid_connected(joystick.id); ok {
		value := sdl.GameControllerGetAxis(joy.controller, JOYSTICK_NATIVE_AXIS[axis])
		out = _joystick_clamp_value(f32(value) / MAX_JOYSTICK_GET_AXIS_VALUE)
		return
	}
	return
}

@(require_results)
_joystick_get_gamepad_mapping_axis :: proc "contextless" (
	joystick: Joystick,
	axis: Gamepad_Axis,
) -> Joystick_Input {
	return _joystick_native_get_gamepad_mapping(
		joystick,
		Gamepad_Input{type = .Axis, value = axis},
	)
}

@(require_results)
_joystick_get_gamepad_mapping_button :: proc "contextless" (
	joystick: Joystick,
	button: Gamepad_Button,
) -> Joystick_Input {
	return _joystick_native_get_gamepad_mapping(
		joystick,
		Gamepad_Input{type = .Button, value = button},
	)
}
@(require_results)
_joystick_get_gamepad_mapping_string :: proc(
	joystick: Joystick,
	allocator := context.allocator,
) -> (
	str: string,
	err: runtime.Allocator_Error,
) {
	sdl_mapping: cstring
	defer if sdl_mapping != nil {
		sdl.free(rawptr(sdl_mapping))
	}

	joy := _joystick_get_from_id(joystick.id)
	if joy == nil do return

	if joy.is_gamepad && joy.controller != nil {
		sdl_mapping = sdl.GameControllerMapping(joy.controller)
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	if sdl_mapping == nil {
		pch_guid := strings.clone_to_cstring(joy.guid, context.temp_allocator) or_return
		sdl_guid := sdl.JoystickGetGUIDFromString(pch_guid)
		sdl_mapping = sdl.GameControllerMappingForGUID(sdl_guid)
	}

	if sdl_mapping == nil {
		return
	}

	builder := strings.builder_make(context.temp_allocator) or_return
	defer strings.builder_destroy(&builder)

	strings.write_string(&builder, string(sdl_mapping))

	str = strings.to_string(builder)

	// Matches SDL_GameControllerAddMappingsFromRW
	if str[len(str) - 1] != ',' {
		strings.write_byte(&builder, ',')
	}

	if !strings.contains(strings.to_string(builder), "platform:") {
		strings.write_string(&builder, "platform:")
		strings.write_string(&builder, string(sdl.GetPlatform()))
	}

	str = strings.clone(strings.to_string(builder), allocator) or_return

	return
}

@(require_results)
_joystick_get_hat :: proc "contextless" (
	joystick: Joystick,
	hat_index: int,
) -> (
	hat: Joystick_Hat,
) {
	if joy := _joystick_get_from_id(joystick.id); joy != nil {
		if !_joystick_is_connected(joy) do return
		if hat_index < 0 || hat_index >= _get_hat_count(joy) do return
		hat = _joystick_sdl_hat_to_joystick_hat(sdl.JoystickGetHat(joy.handle, i32(hat_index)))
	}

	return
}

@(require_results)
_joystick_get_hat_count :: proc "contextless" (joystick: Joystick) -> int {
	if joy := _joystick_get_from_id(joystick.id); joy != nil {
		return _get_hat_count(joy)
	}
	return 0
}

@(require_results)
_joystick_get_id :: proc "contextless" (joystick: Joystick) -> i32 {
	return joystick.id
}

@(require_results)
_joystick_get_name :: proc "contextless" (joystick: Joystick) -> string {
	return joystick.name
}

@(require_results)
_joystick_is_connected :: proc "contextless" (joystick: Joystick) -> bool {
	return _joystick_native_is_connected(_joystick_get_from_id(joystick.id))
}

@(require_results)
_joystick_is_gamepad :: proc "contextless" (joystick: Joystick) -> bool {
	return joystick.is_gamepad
}

@(require_results)
_joystick_is_gamepad_down :: proc "contextless" (
	joystick: Joystick,
	buttons: ..Gamepad_Button,
) -> bool {
	if !joystick.is_gamepad do return false

	if joy, ok := _joystick_get_valid_connected(joystick.id); ok {
		for b in buttons {
			sdl_button := JOYSTICK_NATIVE_BUTTONS[b]
			if sdl.GameControllerGetButton(joy.controller, sdl_button) == 1 {
				return true
			}
		}
	}

	return false
}

@(require_results)
_joystick_is_vibration_supported :: proc(joystick: Joystick) -> bool {
	if joystick.rumble_supported do return true

	if joy, ok := _joystick_get_valid_connected(joystick.id); ok {
		if !_check_create_haptic(joy) do return false

		features := sdl.HapticQuery(joy.haptic)

		// features & sdl.HAPTIC_LEFTRIGHT
		if features & 1 << 2 != 0 {
			return true
		}

		// features & sdl.HAPTIC_CUSTOM
		if joy.is_gamepad && features & 1 << 11 != 0 {
			return true
		}

		if (features & 1 << 1) != 0 {
			return true
		}
	}

	return false
}

@(require_results)
_joystick_start_vibration :: proc(
	joystick: Joystick,
	left, right: f32,
	duration: f32 = -1,
) -> (
	success: bool,
) {
	_left := clamp(left, 0, 1)
	_right := clamp(right, 0, 1)

	if _left == 0.0 && _right == 0.0 {
		return _joystick_stop_vibration(joystick)
	}

	joy, joy_connected := _joystick_get_valid_connected(joystick.id)
	if joy == nil do return
	if !joy_connected {
		joy.vibration.left = 0.0
		joy.vibration.right = 0.0
		joy.vibration.end_time = sdl.HAPTIC_INFINITY
		return
	}

	length: u32 = sdl.HAPTIC_INFINITY
	if duration >= 0 {
		max_duration := f32(max(u32) / 1000.0)
		length = u32(min(duration, max_duration) * 1000)
	}

	if sdl.JoystickRumble(joy.handle, u16(_left * 0xFFFF), u16(_right * 0xFFFF), length) == 0 {
		success = true
	}

	if !success && !_check_create_haptic(joy) {
		return false
	}

	features := sdl.HapticQuery(joy.haptic)

	if !success && (features & 1 << 2) != 0 {
		joy.vibration.effect = {} // Zero-initialize the effect
		joy.vibration.effect.type = .LEFTRIGHT

		joy.vibration.effect.leftright.length = length
		joy.vibration.effect.leftright.large_magnitude = u16(_left) * max(u16)
		joy.vibration.effect.leftright.small_magnitude = u16(_right) * max(u16)

		success = _joystick_native_run_vibration_effect(joy)
	}

	axes := sdl.HapticNumAxes(joy.haptic)

	if !success && joy.is_gamepad && (features & 1 << 11) != 0 && axes == 2 {
		joy.vibration.data[0] = u16(_left * 0x7FFF)
		joy.vibration.data[2] = u16(_left * 0x7FFF)
		joy.vibration.data[1] = u16(_right * 0x7FFF)
		joy.vibration.data[3] = u16(_right * 0x7FFF)
		joy.vibration.effect = {} // Zero-initialize the effect
		joy.vibration.effect.type = .CUSTOM
		joy.vibration.effect.custom.length = length
		joy.vibration.effect.custom.channels = 2
		joy.vibration.effect.custom.period = 10
		joy.vibration.effect.custom.samples = 2
		joy.vibration.effect.custom.data = raw_data(joy.vibration.data[:])

		success = _joystick_native_run_vibration_effect(joy)
	}

	if !success && (features & 1 << 1) != 0 {
		joy.vibration.effect = {} // Zero-initialize the effect
		joy.vibration.effect.type = .SINE
		joy.vibration.effect.periodic.length = length
		joy.vibration.effect.periodic.period = 10
		strength := max(_left, _right)
		joy.vibration.effect.periodic.magnitude = i16(strength * 0x7FFF)

		success = _joystick_native_run_vibration_effect(joy)
	}

	if success {
		joy.vibration.left = _left
		joy.vibration.right = _right
		if length == sdl.HAPTIC_INFINITY {
			joy.vibration.end_time = sdl.HAPTIC_INFINITY
		} else {
			joy.vibration.end_time = sdl.GetTicks() + length
		}
	} else {
		joy.vibration.left = 0
		joy.vibration.right = 0
		joy.vibration.end_time = sdl.HAPTIC_INFINITY
	}

	return
}

@(require_results)
_joystick_stop_vibration :: proc "contextless" (joystick: Joystick) -> (success: bool) {
	if joy, ok := _joystick_get_valid_connected(joystick.id); ok {
		return _joystick_native_reset_vibration(joy)
	}

	return
}

_joystick_set_vibration :: proc {
	_joystick_start_vibration,
	_joystick_stop_vibration,
}

} else {

_ :: log
_ :: slice
_ :: strings
_ :: sdl

_joystick_get_connected_count :: proc "contextless" () -> int {return 0}
_joystick_get_connected :: proc(
	_ := context.allocator,
) -> (
	[]Joystick,
	runtime.Allocator_Error,
) {
	return {}, nil
}
_joystick_get_axes :: proc "contextless" (_: Joystick) -> (axes: []f32) {return {}}
_joystick_get_axis :: proc "contextless" (_: Joystick, _: int) -> f32 {return 0}
_joystick_get_axis_count :: proc "contextless" (_: Joystick) -> int {return 0}
_joystick_get_button_count :: proc "contextless" (_: Joystick) -> int {return 0}
_joystick_get_device_info :: proc "contextless" (_: Joystick) -> (info: Joystick_Device_Info) {
	return
}
_joystick_get_guid :: proc "contextless" (_: Joystick) -> string {return ""}
_joystick_get_gamepad_axis :: proc "contextless" (_: Joystick, _: Gamepad_Axis) -> (out: f32) {
	return
}
_joystick_get_gamepad_mapping_axis :: proc "contextless" (
	_: Joystick,
	_: Gamepad_Axis,
) -> Joystick_Input {
	return {}
}
_joystick_get_gamepad_mapping_button :: proc "contextless" (
	_: Joystick,
	_: Gamepad_Button,
) -> Joystick_Input {
	return {}
}
_joystick_get_gamepad_mapping :: proc {
	get_gamepad_mapping_axis,
	get_gamepad_mapping_button,
}
_joystick_get_gamepad_mapping_string :: proc(
	_: Joystick,
	_ := context.allocator,
) -> (
	str: string,
	err: runtime.Allocator_Error,
) {
	return
}
_joystick_get_hat :: proc "contextless" (_: Joystick, _: int) -> (hat: Joystick_Hat) {return}
_joystick_get_hat_count :: proc "contextless" (_: Joystick) -> int {return 0}
_joystick_get_id :: proc "contextless" (_: Joystick) -> i32 {return 0}
_joystick_get_name :: proc "contextless" (_: Joystick) -> string {return ""}
_joystick_is_connected :: proc "contextless" (_: Joystick) -> bool {return false}
_joystick_is_gamepad :: proc "contextless" (_: Joystick) -> bool {return false}
_joystick_is_gamepad_down :: proc "contextless" (_: Joystick, _: ..Gamepad_Button) -> bool {
	return false
}
_joystick_is_vibration_supported :: proc(_: Joystick) -> bool {return false}
_joystick_start_vibration :: proc(_: Joystick, _, _: f32, _: f32 = 1) -> bool {return false}
_joystick_stop_vibration :: proc "contextless" (joystick: Joystick) {}
_joystick_set_vibration :: proc {
	_joystick_start_vibration,
	_joystick_stop_vibration,
}
}
