#+build !js
package application

// Vendor
import "vendor:glfw"

keyboard_update :: proc "contextless" (app := app_context) #no_bounds_check {
	copy(app.keyboard.previous[:], app.keyboard.current[:])
	app.keyboard.last_key_pressed = .Unknown
	for key in Key {
		if key == .Unknown do continue
		state := glfw.GetKey(window_get_handle(app.window), _FROM_KEY_LUT[key])
		app.keyboard.current[key] = state == glfw.PRESS || state == glfw.REPEAT
		if app.keyboard.current[key] && !app.keyboard.previous[key] {
			app.keyboard.last_key_pressed = key
		}
	}
}

_to_key :: proc "contextless" (key: i32) -> Key {
	switch key {
	case glfw.KEY_SPACE:         return .Space
	case glfw.KEY_APOSTROPHE:    return .Apostrophe
	case glfw.KEY_COMMA:         return .Comma
	case glfw.KEY_MINUS:         return .Minus
	case glfw.KEY_PERIOD:        return .Period
	case glfw.KEY_SLASH:         return .Slash
	case glfw.KEY_SEMICOLON:     return .Semicolon
	case glfw.KEY_EQUAL:         return .Equal
	case glfw.KEY_LEFT_BRACKET:  return .Left_Bracket
	case glfw.KEY_BACKSLASH:     return .Backslash
	case glfw.KEY_RIGHT_BRACKET: return .Right_Bracket
	case glfw.KEY_GRAVE_ACCENT:  return .Grave_Accent
	case glfw.KEY_WORLD_1:       return .World1
	case glfw.KEY_WORLD_2:       return .World2
	case glfw.KEY_0:             return .N0
	case glfw.KEY_1:             return .N1
	case glfw.KEY_2:             return .N2
	case glfw.KEY_3:             return .N3
	case glfw.KEY_4:             return .N4
	case glfw.KEY_5:             return .N5
	case glfw.KEY_6:             return .N6
	case glfw.KEY_7:             return .N7
	case glfw.KEY_8:             return .N8
	case glfw.KEY_9:             return .N9
	case glfw.KEY_A:             return .A
	case glfw.KEY_B:             return .B
	case glfw.KEY_C:             return .C
	case glfw.KEY_D:             return .D
	case glfw.KEY_E:             return .E
	case glfw.KEY_F:             return .F
	case glfw.KEY_G:             return .G
	case glfw.KEY_H:             return .H
	case glfw.KEY_I:             return .I
	case glfw.KEY_J:             return .J
	case glfw.KEY_K:             return .K
	case glfw.KEY_L:             return .L
	case glfw.KEY_M:             return .M
	case glfw.KEY_N:             return .N
	case glfw.KEY_O:             return .O
	case glfw.KEY_P:             return .P
	case glfw.KEY_Q:             return .Q
	case glfw.KEY_R:             return .R
	case glfw.KEY_S:             return .S
	case glfw.KEY_T:             return .T
	case glfw.KEY_U:             return .U
	case glfw.KEY_V:             return .V
	case glfw.KEY_W:             return .W
	case glfw.KEY_X:             return .X
	case glfw.KEY_Y:             return .Y
	case glfw.KEY_Z:             return .Z
	case glfw.KEY_ESCAPE:        return .Escape
	case glfw.KEY_ENTER:         return .Enter
	case glfw.KEY_TAB:           return .Tab
	case glfw.KEY_BACKSPACE:     return .Backspace
	case glfw.KEY_INSERT:        return .Insert
	case glfw.KEY_DELETE:        return .Delete
	case glfw.KEY_RIGHT:         return .Right
	case glfw.KEY_LEFT:          return .Left
	case glfw.KEY_DOWN:          return .Down
	case glfw.KEY_UP:            return .Up
	case glfw.KEY_PAGE_UP:       return .Page_Up
	case glfw.KEY_PAGE_DOWN:     return .Page_Down
	case glfw.KEY_HOME:          return .Home
	case glfw.KEY_END:           return .End
	case glfw.KEY_CAPS_LOCK:     return .Caps_Lock
	case glfw.KEY_SCROLL_LOCK:   return .Scroll_Lock
	case glfw.KEY_NUM_LOCK:      return .Num_Lock
	case glfw.KEY_PRINT_SCREEN:  return .Print_Screen
	case glfw.KEY_PAUSE:         return .Pause
	case glfw.KEY_F1:            return .F1
	case glfw.KEY_F2:            return .F2
	case glfw.KEY_F3:            return .F3
	case glfw.KEY_F4:            return .F4
	case glfw.KEY_F5:            return .F5
	case glfw.KEY_F6:            return .F6
	case glfw.KEY_F7:            return .F7
	case glfw.KEY_F8:            return .F8
	case glfw.KEY_F9:            return .F9
	case glfw.KEY_F10:           return .F10
	case glfw.KEY_F11:           return .F11
	case glfw.KEY_F12:           return .F12
	case glfw.KEY_F13:           return .F13
	case glfw.KEY_F14:           return .F14
	case glfw.KEY_F15:           return .F15
	case glfw.KEY_F16:           return .F16
	case glfw.KEY_F17:           return .F17
	case glfw.KEY_F18:           return .F18
	case glfw.KEY_F19:           return .F19
	case glfw.KEY_F20:           return .F20
	case glfw.KEY_F21:           return .F21
	case glfw.KEY_F22:           return .F22
	case glfw.KEY_F23:           return .F23
	case glfw.KEY_F24:           return .F24
	case glfw.KEY_F25:           return .F25
	case glfw.KEY_KP_0:          return .Kp0
	case glfw.KEY_KP_1:          return .Kp1
	case glfw.KEY_KP_2:          return .Kp2
	case glfw.KEY_KP_3:          return .Kp3
	case glfw.KEY_KP_4:          return .Kp4
	case glfw.KEY_KP_5:          return .Kp5
	case glfw.KEY_KP_6:          return .Kp6
	case glfw.KEY_KP_7:          return .Kp7
	case glfw.KEY_KP_8:          return .Kp8
	case glfw.KEY_KP_9:          return .Kp9
	case glfw.KEY_KP_DECIMAL:    return .Kp_Decimal
	case glfw.KEY_KP_DIVIDE:     return .Kp_Divide
	case glfw.KEY_KP_MULTIPLY:   return .Kp_Multiply
	case glfw.KEY_KP_SUBTRACT:   return .Kp_Subtract
	case glfw.KEY_KP_ADD:        return .Kp_Add
	case glfw.KEY_KP_ENTER:      return .Kp_Enter
	case glfw.KEY_KP_EQUAL:      return .Kp_Equal
	case glfw.KEY_LEFT_SHIFT:    return .Left_Shift
	case glfw.KEY_LEFT_CONTROL:  return .Left_Control
	case glfw.KEY_LEFT_ALT:      return .Left_Alt
	case glfw.KEY_LEFT_SUPER:    return .Left_Super
	case glfw.KEY_RIGHT_SHIFT:   return .Right_Shift
	case glfw.KEY_RIGHT_CONTROL: return .Right_Control
	case glfw.KEY_RIGHT_ALT:     return .Right_Alt
	case glfw.KEY_RIGHT_SUPER:   return .Right_Super
	case glfw.KEY_MENU:          return .Menu
	}
	return .Unknown
}

@(rodata, private)
_FROM_KEY_LUT := [Key]i32 {
	.Unknown       = glfw.KEY_UNKNOWN,
	.Space         = glfw.KEY_SPACE,
	.Apostrophe    = glfw.KEY_APOSTROPHE,
	.Comma         = glfw.KEY_COMMA,
	.Minus         = glfw.KEY_MINUS,
	.Period        = glfw.KEY_PERIOD,
	.Slash         = glfw.KEY_SLASH,
	.Semicolon     = glfw.KEY_SEMICOLON,
	.Equal         = glfw.KEY_EQUAL,
	.Left_Bracket  = glfw.KEY_LEFT_BRACKET,
	.Backslash     = glfw.KEY_BACKSLASH,
	.Right_Bracket = glfw.KEY_RIGHT_BRACKET,
	.Grave_Accent  = glfw.KEY_GRAVE_ACCENT,
	.World1        = glfw.KEY_WORLD_1,
	.World2        = glfw.KEY_WORLD_2,
	.N0            = glfw.KEY_0,
	.N1            = glfw.KEY_1,
	.N2            = glfw.KEY_2,
	.N3            = glfw.KEY_3,
	.N4            = glfw.KEY_4,
	.N5            = glfw.KEY_5,
	.N6            = glfw.KEY_6,
	.N7            = glfw.KEY_7,
	.N8            = glfw.KEY_8,
	.N9            = glfw.KEY_9,
	.A             = glfw.KEY_A,
	.B             = glfw.KEY_B,
	.C             = glfw.KEY_C,
	.D             = glfw.KEY_D,
	.E             = glfw.KEY_E,
	.F             = glfw.KEY_F,
	.G             = glfw.KEY_G,
	.H             = glfw.KEY_H,
	.I             = glfw.KEY_I,
	.J             = glfw.KEY_J,
	.K             = glfw.KEY_K,
	.L             = glfw.KEY_L,
	.M             = glfw.KEY_M,
	.N             = glfw.KEY_N,
	.O             = glfw.KEY_O,
	.P             = glfw.KEY_P,
	.Q             = glfw.KEY_Q,
	.R             = glfw.KEY_R,
	.S             = glfw.KEY_S,
	.T             = glfw.KEY_T,
	.U             = glfw.KEY_U,
	.V             = glfw.KEY_V,
	.W             = glfw.KEY_W,
	.X             = glfw.KEY_X,
	.Y             = glfw.KEY_Y,
	.Z             = glfw.KEY_Z,
	.Escape        = glfw.KEY_ESCAPE,
	.Enter         = glfw.KEY_ENTER,
	.Tab           = glfw.KEY_TAB,
	.Backspace     = glfw.KEY_BACKSPACE,
	.Insert        = glfw.KEY_INSERT,
	.Delete        = glfw.KEY_DELETE,
	.Right         = glfw.KEY_RIGHT,
	.Left          = glfw.KEY_LEFT,
	.Down          = glfw.KEY_DOWN,
	.Up            = glfw.KEY_UP,
	.Page_Up       = glfw.KEY_PAGE_UP,
	.Page_Down     = glfw.KEY_PAGE_DOWN,
	.Home          = glfw.KEY_HOME,
	.End           = glfw.KEY_END,
	.Caps_Lock     = glfw.KEY_CAPS_LOCK,
	.Scroll_Lock   = glfw.KEY_SCROLL_LOCK,
	.Num_Lock      = glfw.KEY_NUM_LOCK,
	.Print_Screen  = glfw.KEY_PRINT_SCREEN,
	.Pause         = glfw.KEY_PAUSE,
	.F1            = glfw.KEY_F1,
	.F2            = glfw.KEY_F2,
	.F3            = glfw.KEY_F3,
	.F4            = glfw.KEY_F4,
	.F5            = glfw.KEY_F5,
	.F6            = glfw.KEY_F6,
	.F7            = glfw.KEY_F7,
	.F8            = glfw.KEY_F8,
	.F9            = glfw.KEY_F9,
	.F10           = glfw.KEY_F10,
	.F11           = glfw.KEY_F11,
	.F12           = glfw.KEY_F12,
	.F13           = glfw.KEY_F13,
	.F14           = glfw.KEY_F14,
	.F15           = glfw.KEY_F15,
	.F16           = glfw.KEY_F16,
	.F17           = glfw.KEY_F17,
	.F18           = glfw.KEY_F18,
	.F19           = glfw.KEY_F19,
	.F20           = glfw.KEY_F20,
	.F21           = glfw.KEY_F21,
	.F22           = glfw.KEY_F22,
	.F23           = glfw.KEY_F23,
	.F24           = glfw.KEY_F24,
	.F25           = glfw.KEY_F25,
	.Kp0           = glfw.KEY_KP_0,
	.Kp1           = glfw.KEY_KP_1,
	.Kp2           = glfw.KEY_KP_2,
	.Kp3           = glfw.KEY_KP_3,
	.Kp4           = glfw.KEY_KP_4,
	.Kp5           = glfw.KEY_KP_5,
	.Kp6           = glfw.KEY_KP_6,
	.Kp7           = glfw.KEY_KP_7,
	.Kp8           = glfw.KEY_KP_8,
	.Kp9           = glfw.KEY_KP_9,
	.Kp_Decimal    = glfw.KEY_KP_DECIMAL,
	.Kp_Divide     = glfw.KEY_KP_DIVIDE,
	.Kp_Multiply   = glfw.KEY_KP_MULTIPLY,
	.Kp_Subtract   = glfw.KEY_KP_SUBTRACT,
	.Kp_Add        = glfw.KEY_KP_ADD,
	.Kp_Enter      = glfw.KEY_KP_ENTER,
	.Kp_Equal      = glfw.KEY_KP_EQUAL,
	.Left_Shift    = glfw.KEY_LEFT_SHIFT,
	.Left_Control  = glfw.KEY_LEFT_CONTROL,
	.Left_Alt      = glfw.KEY_LEFT_ALT,
	.Left_Super    = glfw.KEY_LEFT_SUPER,
	.Right_Shift   = glfw.KEY_RIGHT_SHIFT,
	.Right_Control = glfw.KEY_RIGHT_CONTROL,
	.Right_Alt     = glfw.KEY_RIGHT_ALT,
	.Right_Super   = glfw.KEY_RIGHT_SUPER,
	.Menu          = glfw.KEY_MENU,
	.Last          = glfw.KEY_MENU,
}
