//+build linux, darwin, windows
package application

// STD Library
import "core:container/queue"
import "core:log"
import "core:mem"
import "core:unicode/utf8"

// Vendor
import sdl "vendor:sdl2"

_event_init :: proc(
	allocator: mem.Allocator,
	capacity := DEFAULT_EVENTS_CAPACITY,
) -> (
	ok: bool,
) {
	if sdl.InitSubSystem({.EVENTS}) < 0 {
		log.errorf("Could not initialize SDL events subsystem: [%s]", sdl.GetError())
		return
	}

	if err := queue.init(&g_app.events.data, capacity, allocator); err != nil {
		log.errorf("Failed to initialize events queue: [%v]", err)
		return
	}

	when ODIN_OS == .Windows {
		sdl.AddEventWatch(_win_event_watch, nil)
		sdl.EventState(.SYSWMEVENT, sdl.ENABLE)
	}

	return true
}

_event_destroy :: proc() {
	sdl.QuitSubSystem({.EVENTS})
}

@(private)
_platform_populate_event_queue :: proc() {
	e: sdl.Event
	for sdl.PollEvent(&e) {
		event: Event = nil

		#partial switch (e.type) {
		case .KEYDOWN, .KEYUP:
			event = Key_Event {
				key       = _sdl_to_key(e.key.keysym.sym),
				scancode  = _sdl_to_keyboard_scancode(e.key.keysym.scancode),
				is_repeat = e.key.repeat != 0,
				action    = .Pressed if e.key.state == sdl.PRESSED else .Released,
			}

		case .TEXTINPUT:
			event = _process_text_input_event(e.text.text[:])

		case .TEXTEDITING:
			event = Text_Edited_Event {
				_base  = _process_text_input_event(e.text.text[:]),
				start  = e.edit.start,
				length = e.edit.length,
			}

		case .MOUSEMOTION:
			x := f32(e.motion.x)
			y := f32(e.motion.y)
			xrel := f32(e.motion.xrel)
			yrel := f32(e.motion.yrel)

			when WINDOW_PACKAGE {
				_window_clamp_position(&x, &y)
				_window_to_dpi_coords(&x, &y)
				_window_to_dpi_coords(&xrel, &yrel)
			}

			event = Mouse_Moved_Event {
				x    = x,
				y    = y,
				xrel = xrel,
				yrel = yrel,
			}

		case .MOUSEBUTTONDOWN, .MOUSEBUTTONUP:
			button: Mouse_Button

			switch e.button.button {
			case sdl.BUTTON_LEFT:
				button = .Left
			case sdl.BUTTON_MIDDLE:
				button = .Middle
			case sdl.BUTTON_RIGHT:
				button = .Right
			case sdl.BUTTON_X1:
				button = .Four
			case sdl.BUTTON_X2:
				button = .Five
			}

			pos := Mouse_Position{f32(e.button.x), f32(e.button.y)}

			when WINDOW_PACKAGE {
				_window_clamp_position(&pos.x, &pos.y)
				_window_to_dpi_coords(&pos.x, &pos.y)
			}

			mouse_button_event := Mouse_Button_Event {
				button = button,
				pos    = pos,
				action = e.button.type == .MOUSEBUTTONDOWN ? .Pressed : .Released,
			}

			event = mouse_button_event

			_mouse_click_tracker_tick(mouse_button_event)

		case .MOUSEWHEEL:
			event = Mouse_Wheel_Event{f32(e.wheel.x), f32(e.wheel.y)}

		case .JOYBUTTONDOWN, .JOYBUTTONUP:
			if joy, ok := _joystick_get_from_instance_id(e.jbutton.which); ok {
				event = Joystick_Pressed_Event {
					joystick = joy._base,
					index    = e.jbutton.button,
					action   = .Pressed if e.jbutton.state == sdl.PRESSED else .Released,
				}
			}

		case .JOYAXISMOTION:
			if joy, ok := _joystick_get_from_instance_id(e.jaxis.which); ok {
				event = Joystick_Axis_Motion_Event {
					joystick = joy._base,
					axis     = e.jaxis.axis,
					value    = _joystick_clamp_value(
						f32(e.jaxis.value) / MAX_JOYSTICK_GET_AXIS_VALUE,
					),
				}
			}

		case .JOYHATMOTION:
			if joy, ok := _joystick_get_from_instance_id(e.jhat.which); ok {
				event = Joystick_Hat_Motion_Event {
					joystick  = joy._base,
					hat       = e.jhat.hat,
					direction = JOYSTICK_NATIVE_HAT[e.jhat.hat],
				}
			}

		case .CONTROLLERBUTTONDOWN, .CONTROLLERBUTTONUP:
			if button, ok := _joystick_sdl_button_to_gamepad_button(e.cbutton.button); ok {
				joy := _joystick_get_from_instance_id(e.cbutton.which)
				if joy == nil do break
				event = Gamepad_Pressed_Event {
					joystick = joy._base,
					button   = button,
					action   = .Pressed if e.cbutton.state == sdl.PRESSED else .Released,
				}
			}

		case .CONTROLLERAXISMOTION:
			if joy, ok := _joystick_get_from_instance_id(e.caxis.which); ok {
				event = Gamepad_Axis_Motion_Event {
					joystick = joy._base,
					axis     = _joystick_sdl_gamepad_axis_to_gamepad_axis(e.caxis.axis),
					value    = _joystick_clamp_value(
						f32(e.caxis.value) / MAX_JOYSTICK_GET_AXIS_VALUE,
					),
				}
			}

		case .JOYDEVICEADDED:
			if joy, ok := _joystick_add(e.jdevice.which); !ok {
				event = Joystick_Status_Event {
					joystick = joy._base,
					status   = .Connected,
				}
			}

		case .JOYDEVICEREMOVED:
			if joy, ok := _joystick_get_from_id(e.jdevice.which); ok {
				_joystick_remove_connected(joy)
				event = Joystick_Status_Event {
					joystick = joy._base,
					status   = .Disconnected,
				}
			}

		case .CONTROLLERSENSORUPDATE:
			if joy, ok := _joystick_get_from_instance_id(e.csensor.which); ok {
				data: [3]f32
				s_len := min(len(e.csensor.data), len(data))
				for i in 0 ..< s_len {
					data[i] = e.csensor.data[i]
				}
				event = Gamepad_Sensor_Update_Event {
					joystick = joy._base,
					type     = _sensor_native_convert_sdl_to_sensor(
						sdl.SensorType(e.csensor.sensor),
					),
					data     = data,
				}
			}

		case .WINDOWEVENT:
			#partial switch e.window.event {
			case .FOCUS_GAINED, .FOCUS_LOST:
				event = Focus_Event {
					value = e.window.event == .FOCUS_GAINED,
				}

			case .ENTER, .LEAVE:
				event = Mouse_Focus_Event {
					value = e.window.event == .ENTER,
				}

			case .SHOWN, .HIDDEN:
				event = Visible_Event {
					value = e.window.event == .SHOWN,
				}

			case .RESIZED, .SIZE_CHANGED:
				new_size := Window_Size{u32(e.window.data1), u32(e.window.data2)}
				// Avoid multiple .SIZE_CHANGED and .RESIZED events at the same time.
				if g_app.window.size != new_size {
					g_app.window.size = new_size
					event = cast(Resize_Event)new_size
				}

			case .MINIMIZED, .RESTORED:
				if e.window.event == .MINIMIZED {
					event = Minimized_Event{true}
				} else {
					event = Restored_Event{true}
				}
			}

		case .DISPLAYEVENT:
			orientation: Display_Orientation
			switch sdl.DisplayOrientation(e.display.data1) {
			case .UNKNOWN:
				orientation = .Unknown
			case .LANDSCAPE:
				orientation = .Landscape
			case .LANDSCAPE_FLIPPED:
				orientation = .Landscape_Flipped
			case .PORTRAIT:
				orientation = .Portrait
			case .PORTRAIT_FLIPPED:
				orientation = .Portrait_Flipped
			}

			event = Display_Rotated_Event {
				index       = e.display.display,
				orientation = orientation,
			}

		case .QUIT, .APP_TERMINATING:
			event = Quit_Event{}
		}

		if event != nil {
			event_push(event)
		}
	}
}

@(private)
_process_text_input_event :: proc "contextless" (buf: []u8) -> (ev: Text_Input_Event) {
	copy(ev.buf[:], buf[:])

	nul := nul_search_bytes(ev.buf[:])

	// Add null terminator
	ev.buf[nul] = 0

	r, w := utf8.decode_rune_in_bytes(ev.buf[:nul + 1])
	ev.size = w
	ev.ch = r

	return ev
}
