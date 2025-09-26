#+build js
package application

import "core:log"

keyboard_update :: proc (app := app_context) #no_bounds_check {
	copy(app.keyboard.previous[:], app.keyboard.current[:])
	app.keyboard.last_key_pressed = .Unknown
}

_to_key :: proc "contextless" (key: string) -> Key {
	switch key {
	case " ":              return .Space
	case "'":              return .Apostrophe
	case ",":              return .Comma
	case "-":              return .Minus
	case ".":              return .Period
	case "/":              return .Slash
	case ";":              return .Semicolon
	case "=":              return .Equal
	case "[":              return .Left_Bracket
	case "\\":             return .Backslash
	case "]":              return .Right_Bracket
	case "`":              return .Grave_Accent
	case "0":              return .N0
	case "1":              return .N1
	case "2":              return .N2
	case "3":              return .N3
	case "4":              return .N4
	case "5":              return .N5
	case "6":              return .N6
	case "7":              return .N7
	case "8":              return .N8
	case "9":              return .N9
	case "a", "A":         return .A
	case "b", "B":         return .B
	case "c", "C":         return .C
	case "d", "D":         return .D
	case "e", "E":         return .E
	case "f", "F":         return .F
	case "g", "G":         return .G
	case "h", "H":         return .H
	case "i", "I":         return .I
	case "j", "J":         return .J
	case "k", "K":         return .K
	case "l", "L":         return .L
	case "m", "M":         return .M
	case "n", "N":         return .N
	case "o", "O":         return .O
	case "p", "P":         return .P
	case "q", "Q":         return .Q
	case "r", "R":         return .R
	case "s", "S":         return .S
	case "t", "T":         return .T
	case "u", "U":         return .U
	case "v", "V":         return .V
	case "w", "W":         return .W
	case "x", "X":         return .X
	case "y", "Y":         return .Y
	case "z", "Z":         return .Z
	case "Escape":         return .Escape
	case "Enter":          return .Enter
	case "Tab":            return .Tab
	case "Backspace":      return .Backspace
	case "Insert":         return .Insert
	case "Delete":         return .Delete
	case "ArrowRight":     return .Right
	case "ArrowLeft":      return .Left
	case "ArrowDown":      return .Down
	case "ArrowUp":        return .Up
	case "PageUp":         return .Page_Up
	case "PageDown":       return .Page_Down
	case "Home":           return .Home
	case "End":            return .End
	case "CapsLock":       return .Caps_Lock
	case "ScrollLock":     return .Scroll_Lock
	case "NumLock":        return .Num_Lock
	case "PrintScreen":    return .Print_Screen
	case "Pause":          return .Pause
	case "F1":             return .F1
	case "F2":             return .F2
	case "F3":             return .F3
	case "F4":             return .F4
	case "F5":             return .F5
	case "F6":             return .F6
	case "F7":             return .F7
	case "F8":             return .F8
	case "F9":             return .F9
	case "F10":            return .F10
	case "F11":            return .F11
	case "F12":            return .F12
	case "F13":            return .F13
	case "F14":            return .F14
	case "F15":            return .F15
	case "F16":            return .F16
	case "F17":            return .F17
	case "F18":            return .F18
	case "F19":            return .F19
	case "F20":            return .F20
	case "F21":            return .F21
	case "F22":            return .F22
	case "F23":            return .F23
	case "F24":            return .F24
	case "F25":            return .F25
	case "Numpad0":        return .Kp0
	case "Numpad1":        return .Kp1
	case "Numpad2":        return .Kp2
	case "Numpad3":        return .Kp3
	case "Numpad4":        return .Kp4
	case "Numpad5":        return .Kp5
	case "Numpad6":        return .Kp6
	case "Numpad7":        return .Kp7
	case "Numpad8":        return .Kp8
	case "Numpad9":        return .Kp9
	case "NumpadDecimal":  return .Kp_Decimal
	case "NumpadDivide":   return .Kp_Divide
	case "NumpadMultiply": return .Kp_Multiply
	case "NumpadSubtract": return .Kp_Subtract
	case "NumpadAdd":      return .Kp_Add
	case "NumpadEnter":    return .Kp_Enter
	case "NumpadEqual":    return .Kp_Equal
	case "ShiftLeft":      return .Left_Shift
	case "ControlLeft":    return .Left_Control
	case "AltLeft":        return .Left_Alt
	case "MetaLeft":       return .Left_Super
	case "ShiftRight":     return .Right_Shift
	case "ControlRight":   return .Right_Control
	case "AltRight":       return .Right_Alt
	case "MetaRight":      return .Right_Super
	case "ContextMenu":    return .Menu
	}
	return .Unknown
}

@(rodata, private)
_FROM_KEY_LUT := [Key]string {
	.Unknown       = "",
	.Space         = " ",
	.Apostrophe    = "'",
	.Comma         = ",",
	.Minus         = "-",
	.Period        = ".",
	.Slash         = "/",
	.Semicolon     = ";",
	.Equal         = "=",
	.Left_Bracket  = "[",
	.Backslash     = "\\",
	.Right_Bracket = "]",
	.Grave_Accent  = "`",
	.World1        = "", // Not standard in JavaScript key events
	.World2        = "", // Not standard in JavaScript key events
	.N0            = "0",
	.N1            = "1",
	.N2            = "2",
	.N3            = "3",
	.N4            = "4",
	.N5            = "5",
	.N6            = "6",
	.N7            = "7",
	.N8            = "8",
	.N9            = "9",
	.A             = "a",
	.B             = "b",
	.C             = "c",
	.D             = "d",
	.E             = "e",
	.F             = "f",
	.G             = "g",
	.H             = "h",
	.I             = "i",
	.J             = "j",
	.K             = "k",
	.L             = "l",
	.M             = "m",
	.N             = "n",
	.O             = "o",
	.P             = "p",
	.Q             = "q",
	.R             = "r",
	.S             = "s",
	.T             = "t",
	.U             = "u",
	.V             = "v",
	.W             = "w",
	.X             = "x",
	.Y             = "y",
	.Z             = "z",
	.Escape        = "Escape",
	.Enter         = "Enter",
	.Tab           = "Tab",
	.Backspace     = "Backspace",
	.Insert        = "Insert",
	.Delete        = "Delete",
	.Right         = "ArrowRight",
	.Left          = "ArrowLeft",
	.Down          = "ArrowDown",
	.Up            = "ArrowUp",
	.Page_Up       = "PageUp",
	.Page_Down     = "PageDown",
	.Home          = "Home",
	.End           = "End",
	.Caps_Lock     = "CapsLock",
	.Scroll_Lock   = "ScrollLock",
	.Num_Lock      = "NumLock",
	.Print_Screen  = "PrintScreen",
	.Pause         = "Pause",
	.F1            = "F1",
	.F2            = "F2",
	.F3            = "F3",
	.F4            = "F4",
	.F5            = "F5",
	.F6            = "F6",
	.F7            = "F7",
	.F8            = "F8",
	.F9            = "F9",
	.F10           = "F10",
	.F11           = "F11",
	.F12           = "F12",
	.F13           = "F13",
	.F14           = "F14",
	.F15           = "F15",
	.F16           = "F16",
	.F17           = "F17",
	.F18           = "F18",
	.F19           = "F19",
	.F20           = "F20",
	.F21           = "F21",
	.F22           = "F22",
	.F23           = "F23",
	.F24           = "F24",
	.F25           = "F25",
	.Kp0           = "Numpad0",
	.Kp1           = "Numpad1",
	.Kp2           = "Numpad2",
	.Kp3           = "Numpad3",
	.Kp4           = "Numpad4",
	.Kp5           = "Numpad5",
	.Kp6           = "Numpad6",
	.Kp7           = "Numpad7",
	.Kp8           = "Numpad8",
	.Kp9           = "Numpad9",
	.Kp_Decimal    = "NumpadDecimal",
	.Kp_Divide     = "NumpadDivide",
	.Kp_Multiply   = "NumpadMultiply",
	.Kp_Subtract   = "NumpadSubtract",
	.Kp_Add        = "NumpadAdd",
	.Kp_Enter      = "NumpadEnter",
	.Kp_Equal      = "NumpadEqual",
	.Left_Shift    = "ShiftLeft",
	.Left_Control  = "ControlLeft",
	.Left_Alt      = "AltLeft",
	.Left_Super    = "MetaLeft",
	.Right_Shift   = "ShiftRight",
	.Right_Control = "ControlRight",
	.Right_Alt     = "AltRight",
	.Right_Super   = "MetaRight",
	.Menu          = "ContextMenu",
	.Last          = "", // Not used in JavaScript key events
}

_to_scancode :: proc "contextless" (code: string) -> i32 {
	switch code {
	case "Space":          return 32
	case "Quote":          return 39
	case "Comma":          return 44
	case "Minus":          return 45
	case "Period":         return 46
	case "Slash":          return 47
	case "Semicolon":      return 59
	case "Equal":          return 61
	case "BracketLeft":    return 91
	case "Backslash":      return 92
	case "BracketRight":   return 93
	case "Backquote":      return 96
	case "Digit0":         return 48
	case "Digit1":         return 49
	case "Digit2":         return 50
	case "Digit3":         return 51
	case "Digit4":         return 52
	case "Digit5":         return 53
	case "Digit6":         return 54
	case "Digit7":         return 55
	case "Digit8":         return 56
	case "Digit9":         return 57
	case "KeyA":           return 65
	case "KeyB":           return 66
	case "KeyC":           return 67
	case "KeyD":           return 68
	case "KeyE":           return 69
	case "KeyF":           return 70
	case "KeyG":           return 71
	case "KeyH":           return 72
	case "KeyI":           return 73
	case "KeyJ":           return 74
	case "KeyK":           return 75
	case "KeyL":           return 76
	case "KeyM":           return 77
	case "KeyN":           return 78
	case "KeyO":           return 79
	case "KeyP":           return 80
	case "KeyQ":           return 81
	case "KeyR":           return 82
	case "KeyS":           return 83
	case "KeyT":           return 84
	case "KeyU":           return 85
	case "KeyV":           return 86
	case "KeyW":           return 87
	case "KeyX":           return 88
	case "KeyY":           return 89
	case "KeyZ":           return 90
	case "Escape":         return 256
	case "Enter":          return 257
	case "Tab":            return 258
	case "Backspace":      return 259
	case "Insert":         return 260
	case "Delete":         return 261
	case "ArrowRight":     return 262
	case "ArrowLeft":      return 263
	case "ArrowDown":      return 264
	case "ArrowUp":        return 265
	case "PageUp":         return 266
	case "PageDown":       return 267
	case "Home":           return 268
	case "End":            return 269
	case "CapsLock":       return 280
	case "ScrollLock":     return 281
	case "NumLock":        return 282
	case "PrintScreen":    return 283
	case "Pause":          return 284
	case "F1":             return 290
	case "F2":             return 291
	case "F3":             return 292
	case "F4":             return 293
	case "F5":             return 294
	case "F6":             return 295
	case "F7":             return 296
	case "F8":             return 297
	case "F9":             return 298
	case "F10":            return 299
	case "F11":            return 300
	case "F12":            return 301
	case "F13":            return 302
	case "F14":            return 303
	case "F15":            return 304
	case "F16":            return 305
	case "F17":            return 306
	case "F18":            return 307
	case "F19":            return 308
	case "F20":            return 309
	case "F21":            return 310
	case "F22":            return 311
	case "F23":            return 312
	case "F24":            return 313
	case "F25":            return 314
	case "Numpad0":        return 320
	case "Numpad1":        return 321
	case "Numpad2":        return 322
	case "Numpad3":        return 323
	case "Numpad4":        return 324
	case "Numpad5":        return 325
	case "Numpad6":        return 326
	case "Numpad7":        return 327
	case "Numpad8":        return 328
	case "Numpad9":        return 329
	case "NumpadDecimal":  return 330
	case "NumpadDivide":   return 331
	case "NumpadMultiply": return 332
	case "NumpadSubtract": return 333
	case "NumpadAdd":      return 334
	case "NumpadEnter":    return 335
	case "NumpadEqual":    return 336
	case "ShiftLeft":      return 340
	case "ControlLeft":    return 341
	case "AltLeft":        return 342
	case "MetaLeft":       return 343
	case "ShiftRight":     return 344
	case "ControlRight":   return 345
	case "AltRight":       return 346
	case "MetaRight":      return 347
	case "ContextMenu":    return 348
	}
	return 0 // Unknown scancode
}

// Lookup table to convert Key enum to i32 scancode
@(rodata, private)
_FROM_KEY_TO_SCANCODE_LUT := [Key]i32 {
	.Unknown       = 0,
	.Space         = 32,
	.Apostrophe    = 39,
	.Comma         = 44,
	.Minus         = 45,
	.Period        = 46,
	.Slash         = 47,
	.Semicolon     = 59,
	.Equal         = 61,
	.Left_Bracket  = 91,
	.Backslash     = 92,
	.Right_Bracket = 93,
	.Grave_Accent  = 96,
	.World1        = 0, // Not standard in JavaScript
	.World2        = 0, // Not standard in JavaScript
	.N0            = 48,
	.N1            = 49,
	.N2            = 50,
	.N3            = 51,
	.N4            = 52,
	.N5            = 53,
	.N6            = 54,
	.N7            = 55,
	.N8            = 56,
	.N9            = 57,
	.A             = 65,
	.B             = 66,
	.C             = 67,
	.D             = 68,
	.E             = 69,
	.F             = 70,
	.G             = 71,
	.H             = 72,
	.I             = 73,
	.J             = 74,
	.K             = 75,
	.L             = 76,
	.M             = 77,
	.N             = 78,
	.O             = 79,
	.P             = 80,
	.Q             = 81,
	.R             = 82,
	.S             = 83,
	.T             = 84,
	.U             = 85,
	.V             = 86,
	.W             = 87,
	.X             = 88,
	.Y             = 89,
	.Z             = 90,
	.Escape        = 256,
	.Enter         = 257,
	.Tab           = 258,
	.Backspace     = 259,
	.Insert        = 260,
	.Delete        = 261,
	.Right         = 262,
	.Left          = 263,
	.Down          = 264,
	.Up            = 265,
	.Page_Up       = 266,
	.Page_Down     = 267,
	.Home          = 268,
	.End           = 269,
	.Caps_Lock     = 280,
	.Scroll_Lock   = 281,
	.Num_Lock      = 282,
	.Print_Screen  = 283,
	.Pause         = 284,
	.F1            = 290,
	.F2            = 291,
	.F3            = 292,
	.F4            = 293,
	.F5            = 294,
	.F6            = 295,
	.F7            = 296,
	.F8            = 297,
	.F9            = 298,
	.F10           = 299,
	.F11           = 300,
	.F12           = 301,
	.F13           = 302,
	.F14           = 303,
	.F15           = 304,
	.F16           = 305,
	.F17           = 306,
	.F18           = 307,
	.F19           = 308,
	.F20           = 309,
	.F21           = 310,
	.F22           = 311,
	.F23           = 312,
	.F24           = 313,
	.F25           = 314,
	.Kp0           = 320,
	.Kp1           = 321,
	.Kp2           = 322,
	.Kp3           = 323,
	.Kp4           = 324,
	.Kp5           = 325,
	.Kp6           = 326,
	.Kp7           = 327,
	.Kp8           = 328,
	.Kp9           = 329,
	.Kp_Decimal    = 330,
	.Kp_Divide     = 331,
	.Kp_Multiply   = 332,
	.Kp_Subtract   = 333,
	.Kp_Add        = 334,
	.Kp_Enter      = 335,
	.Kp_Equal      = 336,
	.Left_Shift    = 340,
	.Left_Control  = 341,
	.Left_Alt      = 342,
	.Left_Super    = 343,
	.Right_Shift   = 344,
	.Right_Control = 345,
	.Right_Alt     = 346,
	.Right_Super   = 347,
	.Menu          = 348,
	.Last          = 0, // Not used
}
