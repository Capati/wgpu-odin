//+build linux, darwin, windows
package application

// Vendor
import sdl "vendor:sdl2"

_sdl_get_mod_state :: proc "contextless" (mod: sdl.Keymod) -> (key_mods: Keyboard_Modifier_Key) {
	// Check for no modifiers
	mod_keys := sdl.KMOD_CTRL | sdl.KMOD_SHIFT | sdl.KMOD_ALT | sdl.KMOD_GUI
	if (mod & mod_keys) != sdl.KMOD_NONE {
		key_mods = {
			left_shift  = (sdl.KeymodFlag.LSHIFT in mod),
			right_shift = (sdl.KeymodFlag.RSHIFT in mod),
			left_ctrl   = (sdl.KeymodFlag.LCTRL in mod),
			right_ctrl  = (sdl.KeymodFlag.RCTRL in mod),
			left_alt    = (sdl.KeymodFlag.LALT in mod),
			right_alt   = (sdl.KeymodFlag.RALT in mod),
			left_super  = (sdl.KeymodFlag.LGUI in mod),
			right_super = (sdl.KeymodFlag.RGUI in mod),
			num         = (sdl.KeymodFlag.NUM in mod),
			caps        = (sdl.KeymodFlag.CAPS in mod),
			mode        = (sdl.KeymodFlag.MODE in mod),
		}
	}

	return
}

_key_to_sdl_scancode :: proc "contextless" (key: Keyboard_Key) -> sdl.Scancode {
	return sdl.GetScancodeFromKey(_key_to_sdl(key))
}

// Lookup table for converting SDL scancodes to custom keyboard scancodes
KEYBOARD_SDL_TO_KEYBOARD_SCANCODE_LUT := [sdl.Scancode.NUM_SCANCODES]Keyboard_Scancode {
	sdl.Scancode.UNKNOWN            = .Unknown,
	sdl.Scancode.A                  = .A,
	sdl.Scancode.B                  = .B,
	sdl.Scancode.C                  = .C,
	sdl.Scancode.D                  = .D,
	sdl.Scancode.E                  = .E,
	sdl.Scancode.F                  = .F,
	sdl.Scancode.G                  = .G,
	sdl.Scancode.H                  = .H,
	sdl.Scancode.I                  = .I,
	sdl.Scancode.J                  = .J,
	sdl.Scancode.K                  = .K,
	sdl.Scancode.L                  = .L,
	sdl.Scancode.M                  = .M,
	sdl.Scancode.N                  = .N,
	sdl.Scancode.O                  = .O,
	sdl.Scancode.P                  = .P,
	sdl.Scancode.Q                  = .Q,
	sdl.Scancode.R                  = .R,
	sdl.Scancode.S                  = .S,
	sdl.Scancode.T                  = .T,
	sdl.Scancode.U                  = .U,
	sdl.Scancode.V                  = .V,
	sdl.Scancode.W                  = .W,
	sdl.Scancode.X                  = .X,
	sdl.Scancode.Y                  = .Y,
	sdl.Scancode.Z                  = .Z,
	sdl.Scancode.NUM1               = .Num_1,
	sdl.Scancode.NUM2               = .Num_2,
	sdl.Scancode.NUM3               = .Num_3,
	sdl.Scancode.NUM4               = .Num_4,
	sdl.Scancode.NUM5               = .Num_5,
	sdl.Scancode.NUM6               = .Num_6,
	sdl.Scancode.NUM7               = .Num_7,
	sdl.Scancode.NUM8               = .Num_8,
	sdl.Scancode.NUM9               = .Num_9,
	sdl.Scancode.NUM0               = .Num_0,
	sdl.Scancode.RETURN             = .Return,
	sdl.Scancode.ESCAPE             = .Escape,
	sdl.Scancode.BACKSPACE          = .Backspace,
	sdl.Scancode.TAB                = .Tab,
	sdl.Scancode.SPACE              = .Space,
	sdl.Scancode.MINUS              = .Minus,
	sdl.Scancode.EQUALS             = .Equals,
	sdl.Scancode.LEFTBRACKET        = .Left_Bracket,
	sdl.Scancode.RIGHTBRACKET       = .Right_Bracket,
	sdl.Scancode.BACKSLASH          = .Backslash,
	sdl.Scancode.NONUSHASH          = .Non_Us_Hash,
	sdl.Scancode.SEMICOLON          = .Semicolon,
	sdl.Scancode.APOSTROPHE         = .Apostrophe,
	sdl.Scancode.GRAVE              = .Grave,
	sdl.Scancode.COMMA              = .Comma,
	sdl.Scancode.PERIOD             = .Period,
	sdl.Scancode.SLASH              = .Slash,
	sdl.Scancode.CAPSLOCK           = .Caps_Lock,
	sdl.Scancode.F1                 = .F1,
	sdl.Scancode.F2                 = .F2,
	sdl.Scancode.F3                 = .F3,
	sdl.Scancode.F4                 = .F4,
	sdl.Scancode.F5                 = .F5,
	sdl.Scancode.F6                 = .F6,
	sdl.Scancode.F7                 = .F7,
	sdl.Scancode.F8                 = .F8,
	sdl.Scancode.F9                 = .F9,
	sdl.Scancode.F10                = .F10,
	sdl.Scancode.F11                = .F11,
	sdl.Scancode.F12                = .F12,
	sdl.Scancode.PRINTSCREEN        = .Print_Screen,
	sdl.Scancode.SCROLLLOCK         = .Scroll_Lock,
	sdl.Scancode.PAUSE              = .Pause,
	sdl.Scancode.INSERT             = .Insert,
	sdl.Scancode.HOME               = .Home,
	sdl.Scancode.PAGEUP             = .Page_Up,
	sdl.Scancode.DELETE             = .Delete,
	sdl.Scancode.END                = .End,
	sdl.Scancode.PAGEDOWN           = .Page_Down,
	sdl.Scancode.RIGHT              = .Right,
	sdl.Scancode.LEFT               = .Left,
	sdl.Scancode.DOWN               = .Down,
	sdl.Scancode.UP                 = .Up,
	sdl.Scancode.NUMLOCKCLEAR       = .Num_Lock_Clear,
	sdl.Scancode.KP_DIVIDE          = .Kp_Divide,
	sdl.Scancode.KP_MULTIPLY        = .Kp_Multiply,
	sdl.Scancode.KP_MINUS           = .Kp_Minus,
	sdl.Scancode.KP_PLUS            = .Kp_Plus,
	sdl.Scancode.KP_ENTER           = .Kp_Enter,
	sdl.Scancode.KP_1               = .Kp_1,
	sdl.Scancode.KP_2               = .Kp_2,
	sdl.Scancode.KP_3               = .Kp_3,
	sdl.Scancode.KP_4               = .Kp_4,
	sdl.Scancode.KP_5               = .Kp_5,
	sdl.Scancode.KP_6               = .Kp_6,
	sdl.Scancode.KP_7               = .Kp_7,
	sdl.Scancode.KP_8               = .Kp_8,
	sdl.Scancode.KP_9               = .Kp_9,
	sdl.Scancode.KP_0               = .Kp_0,
	sdl.Scancode.KP_PERIOD          = .Kp_Period,
	sdl.Scancode.NONUSBACKSLASH     = .Non_Us_Backslash,
	sdl.Scancode.APPLICATION        = .Application,
	sdl.Scancode.POWER              = .Power,
	sdl.Scancode.KP_EQUALS          = .Kp_Equals,
	sdl.Scancode.F13                = .F13,
	sdl.Scancode.F14                = .F14,
	sdl.Scancode.F15                = .F15,
	sdl.Scancode.F16                = .F16,
	sdl.Scancode.F17                = .F17,
	sdl.Scancode.F18                = .F18,
	sdl.Scancode.F19                = .F19,
	sdl.Scancode.F20                = .F20,
	sdl.Scancode.F21                = .F21,
	sdl.Scancode.F22                = .F22,
	sdl.Scancode.F23                = .F23,
	sdl.Scancode.F24                = .F24,
	sdl.Scancode.EXECUTE            = .Execute,
	sdl.Scancode.HELP               = .Help,
	sdl.Scancode.MENU               = .Menu,
	sdl.Scancode.SELECT             = .Select,
	sdl.Scancode.STOP               = .Stop,
	sdl.Scancode.AGAIN              = .Again,
	sdl.Scancode.UNDO               = .Undo,
	sdl.Scancode.CUT                = .Cut,
	sdl.Scancode.COPY               = .Copy,
	sdl.Scancode.PASTE              = .Paste,
	sdl.Scancode.FIND               = .Find,
	sdl.Scancode.MUTE               = .Mute,
	sdl.Scancode.VOLUMEUP           = .Volume_Up,
	sdl.Scancode.VOLUMEDOWN         = .Volume_Down,
	sdl.Scancode.KP_COMMA           = .Kp_Comma,
	sdl.Scancode.KP_EQUALSAS400     = .Kp_Equals_As_400,
	sdl.Scancode.INTERNATIONAL1     = .International_1,
	sdl.Scancode.INTERNATIONAL2     = .International_2,
	sdl.Scancode.INTERNATIONAL3     = .International_3,
	sdl.Scancode.INTERNATIONAL4     = .International_4,
	sdl.Scancode.INTERNATIONAL5     = .International_5,
	sdl.Scancode.INTERNATIONAL6     = .International_6,
	sdl.Scancode.INTERNATIONAL7     = .International_7,
	sdl.Scancode.INTERNATIONAL8     = .International_8,
	sdl.Scancode.INTERNATIONAL9     = .International_9,
	sdl.Scancode.LANG1              = .Lang_1,
	sdl.Scancode.LANG2              = .Lang_2,
	sdl.Scancode.LANG3              = .Lang_3,
	sdl.Scancode.LANG4              = .Lang_4,
	sdl.Scancode.LANG5              = .Lang_5,
	sdl.Scancode.LANG6              = .Lang_6,
	sdl.Scancode.LANG7              = .Lang_7,
	sdl.Scancode.LANG8              = .Lang_8,
	sdl.Scancode.LANG9              = .Lang_9,
	sdl.Scancode.ALTERASE           = .Alt_Erase,
	sdl.Scancode.SYSREQ             = .Sys_Req,
	sdl.Scancode.CANCEL             = .Cancel,
	sdl.Scancode.CLEAR              = .Clear,
	sdl.Scancode.PRIOR              = .Prior,
	sdl.Scancode.RETURN2            = .Return_2,
	sdl.Scancode.SEPARATOR          = .Separator,
	sdl.Scancode.OUT                = .Out,
	sdl.Scancode.OPER               = .Oper,
	sdl.Scancode.CLEARAGAIN         = .Clear_Again,
	sdl.Scancode.CRSEL              = .Cr_Sel,
	sdl.Scancode.EXSEL              = .Ex_Sel,
	sdl.Scancode.KP_00              = .Kp_00,
	sdl.Scancode.KP_000             = .Kp_000,
	sdl.Scancode.THOUSANDSSEPARATOR = .Thousands_Separator,
	sdl.Scancode.DECIMALSEPARATOR   = .Decimal_Separator,
	sdl.Scancode.CURRENCYUNIT       = .Currency_Unit,
	sdl.Scancode.CURRENCYSUBUNIT    = .Currency_Subunit,
	sdl.Scancode.KP_LEFTPAREN       = .Kp_Left_Paren,
	sdl.Scancode.KP_RIGHTPAREN      = .Kp_Right_Paren,
	sdl.Scancode.KP_LEFTBRACE       = .Kp_Left_Brace,
	sdl.Scancode.KP_RIGHTBRACE      = .Kp_Right_Brace,
	sdl.Scancode.KP_TAB             = .Kp_Tab,
	sdl.Scancode.KP_BACKSPACE       = .Kp_Backspace,
	sdl.Scancode.KP_A               = .Kp_A,
	sdl.Scancode.KP_B               = .Kp_B,
	sdl.Scancode.KP_C               = .Kp_C,
	sdl.Scancode.KP_D               = .Kp_D,
	sdl.Scancode.KP_E               = .Kp_E,
	sdl.Scancode.KP_F               = .Kp_F,
	sdl.Scancode.KP_XOR             = .Kp_Xor,
	sdl.Scancode.KP_POWER           = .Kp_Power,
	sdl.Scancode.KP_PERCENT         = .Kp_Percent,
	sdl.Scancode.KP_LESS            = .Kp_Less,
	sdl.Scancode.KP_GREATER         = .Kp_Greater,
	sdl.Scancode.KP_AMPERSAND       = .Kp_Ampersand,
	sdl.Scancode.KP_DBLAMPERSAND    = .Kp_Dbl_Ampersand,
	sdl.Scancode.KP_VERTICALBAR     = .Kp_Vertical_Bar,
	sdl.Scancode.KP_DBLVERTICALBAR  = .Kp_Dbl_Vertical_Bar,
	sdl.Scancode.KP_COLON           = .Kp_Colon,
	sdl.Scancode.KP_HASH            = .Kp_Hash,
	sdl.Scancode.KP_SPACE           = .Kp_Space,
	sdl.Scancode.KP_AT              = .Kp_At,
	sdl.Scancode.KP_EXCLAM          = .Kp_Exclam,
	sdl.Scancode.KP_MEMSTORE        = .Kp_Mem_Store,
	sdl.Scancode.KP_MEMRECALL       = .Kp_Mem_Recall,
	sdl.Scancode.KP_MEMCLEAR        = .Kp_Mem_Clear,
	sdl.Scancode.KP_MEMADD          = .Kp_Mem_Add,
	sdl.Scancode.KP_MEMSUBTRACT     = .Kp_Mem_Subtract,
	sdl.Scancode.KP_MEMMULTIPLY     = .Kp_Mem_Multiply,
	sdl.Scancode.KP_MEMDIVIDE       = .Kp_Mem_Divide,
	sdl.Scancode.KP_PLUSMINUS       = .Kp_Plus_Minus,
	sdl.Scancode.KP_CLEAR           = .Kp_Clear,
	sdl.Scancode.KP_CLEARENTRY      = .Kp_Clear_Entry,
	sdl.Scancode.KP_BINARY          = .Kp_Binary,
	sdl.Scancode.KP_OCTAL           = .Kp_Octal,
	sdl.Scancode.KP_DECIMAL         = .Kp_Decimal,
	sdl.Scancode.KP_HEXADECIMAL     = .Kp_Hexadecimal,
	sdl.Scancode.LCTRL              = .Left_Ctrl,
	sdl.Scancode.LSHIFT             = .Left_Shift,
	sdl.Scancode.LALT               = .Left_Alt,
	sdl.Scancode.LGUI               = .Left_Gui,
	sdl.Scancode.RCTRL              = .Right_Ctrl,
	sdl.Scancode.RSHIFT             = .Right_Shift,
	sdl.Scancode.RALT               = .Right_Alt,
	sdl.Scancode.RGUI               = .Right_Gui,
	sdl.Scancode.MODE               = .Mode,
	sdl.Scancode.AUDIONEXT          = .Audio_Next,
	sdl.Scancode.AUDIOPREV          = .Audio_Prev,
	sdl.Scancode.AUDIOSTOP          = .Audio_Stop,
	sdl.Scancode.AUDIOPLAY          = .Audio_Play,
	sdl.Scancode.AUDIOMUTE          = .Audio_Mute,
	sdl.Scancode.MEDIASELECT        = .Media_Select,
	sdl.Scancode.WWW                = .WWW,
	sdl.Scancode.MAIL               = .Mail,
	sdl.Scancode.CALCULATOR         = .Calculator,
	sdl.Scancode.COMPUTER           = .Computer,
	sdl.Scancode.AC_SEARCH          = .Ac_Search,
	sdl.Scancode.AC_HOME            = .Ac_Home,
	sdl.Scancode.AC_BACK            = .Ac_Back,
	sdl.Scancode.AC_FORWARD         = .Ac_Forward,
	sdl.Scancode.AC_STOP            = .Ac_Stop,
	sdl.Scancode.AC_REFRESH         = .Ac_Refresh,
	sdl.Scancode.AC_BOOKMARKS       = .Ac_Bookmarks,
	sdl.Scancode.BRIGHTNESSDOWN     = .Brightness_Down,
	sdl.Scancode.BRIGHTNESSUP       = .Brightness_Up,
	sdl.Scancode.DISPLAYSWITCH      = .Display_Switch,
	sdl.Scancode.KBDILLUMTOGGLE     = .Kbd_Illum_Toggle,
	sdl.Scancode.KBDILLUMDOWN       = .Kbd_Illum_Down,
	sdl.Scancode.KBDILLUMUP         = .Kbd_Illum_Up,
	sdl.Scancode.EJECT              = .Eject,
	sdl.Scancode.SLEEP              = .Sleep,
	sdl.Scancode.APP1               = .App_1,
	sdl.Scancode.APP2               = .App_2,
	sdl.Scancode.AUDIOREWIND        = .Audio_Rewind,
	sdl.Scancode.AUDIOFASTFORWARD   = .Audio_Fastforward,
}

_sdl_to_keyboard_scancode :: proc "contextless" (
	sdl_scancode: sdl.Scancode,
) -> (
	Keyboard_Scancode,
	bool,
) #no_bounds_check #optional_ok {
	if int(sdl_scancode) < 0 || int(sdl_scancode) >= len(KEYBOARD_SDL_TO_KEYBOARD_SCANCODE_LUT) {
		return .Unknown, false
	}
	return KEYBOARD_SDL_TO_KEYBOARD_SCANCODE_LUT[sdl_scancode], true
}

// Lookup table for converting custom keyboard scancodes to sdl scancodes
KEYBOARD_SCANCODE_TO_SDL_LUT := [Keyboard_Scancode]sdl.Scancode {
	.Unknown             = sdl.Scancode.UNKNOWN,
	.A                   = sdl.Scancode.A,
	.B                   = sdl.Scancode.B,
	.C                   = sdl.Scancode.C,
	.D                   = sdl.Scancode.D,
	.E                   = sdl.Scancode.E,
	.F                   = sdl.Scancode.F,
	.G                   = sdl.Scancode.G,
	.H                   = sdl.Scancode.H,
	.I                   = sdl.Scancode.I,
	.J                   = sdl.Scancode.J,
	.K                   = sdl.Scancode.K,
	.L                   = sdl.Scancode.L,
	.M                   = sdl.Scancode.M,
	.N                   = sdl.Scancode.N,
	.O                   = sdl.Scancode.O,
	.P                   = sdl.Scancode.P,
	.Q                   = sdl.Scancode.Q,
	.R                   = sdl.Scancode.R,
	.S                   = sdl.Scancode.S,
	.T                   = sdl.Scancode.T,
	.U                   = sdl.Scancode.U,
	.V                   = sdl.Scancode.V,
	.W                   = sdl.Scancode.W,
	.X                   = sdl.Scancode.X,
	.Y                   = sdl.Scancode.Y,
	.Z                   = sdl.Scancode.Z,
	.Num_1               = sdl.Scancode.NUM1,
	.Num_2               = sdl.Scancode.NUM2,
	.Num_3               = sdl.Scancode.NUM3,
	.Num_4               = sdl.Scancode.NUM4,
	.Num_5               = sdl.Scancode.NUM5,
	.Num_6               = sdl.Scancode.NUM6,
	.Num_7               = sdl.Scancode.NUM7,
	.Num_8               = sdl.Scancode.NUM8,
	.Num_9               = sdl.Scancode.NUM9,
	.Num_0               = sdl.Scancode.NUM0,
	.Return              = sdl.Scancode.RETURN,
	.Escape              = sdl.Scancode.ESCAPE,
	.Backspace           = sdl.Scancode.BACKSPACE,
	.Tab                 = sdl.Scancode.TAB,
	.Space               = sdl.Scancode.SPACE,
	.Minus               = sdl.Scancode.MINUS,
	.Equals              = sdl.Scancode.EQUALS,
	.Left_Bracket        = sdl.Scancode.LEFTBRACKET,
	.Right_Bracket       = sdl.Scancode.RIGHTBRACKET,
	.Backslash           = sdl.Scancode.BACKSLASH,
	.Non_Us_Hash         = sdl.Scancode.NONUSHASH,
	.Semicolon           = sdl.Scancode.SEMICOLON,
	.Apostrophe          = sdl.Scancode.APOSTROPHE,
	.Grave               = sdl.Scancode.GRAVE,
	.Comma               = sdl.Scancode.COMMA,
	.Period              = sdl.Scancode.PERIOD,
	.Slash               = sdl.Scancode.SLASH,
	.Caps_Lock           = sdl.Scancode.CAPSLOCK,
	.F1                  = sdl.Scancode.F1,
	.F2                  = sdl.Scancode.F2,
	.F3                  = sdl.Scancode.F3,
	.F4                  = sdl.Scancode.F4,
	.F5                  = sdl.Scancode.F5,
	.F6                  = sdl.Scancode.F6,
	.F7                  = sdl.Scancode.F7,
	.F8                  = sdl.Scancode.F8,
	.F9                  = sdl.Scancode.F9,
	.F10                 = sdl.Scancode.F10,
	.F11                 = sdl.Scancode.F11,
	.F12                 = sdl.Scancode.F12,
	.Print_Screen        = sdl.Scancode.PRINTSCREEN,
	.Scroll_Lock         = sdl.Scancode.SCROLLLOCK,
	.Pause               = sdl.Scancode.PAUSE,
	.Insert              = sdl.Scancode.INSERT,
	.Home                = sdl.Scancode.HOME,
	.Page_Up             = sdl.Scancode.PAGEUP,
	.Delete              = sdl.Scancode.DELETE,
	.End                 = sdl.Scancode.END,
	.Page_Down           = sdl.Scancode.PAGEDOWN,
	.Right               = sdl.Scancode.RIGHT,
	.Left                = sdl.Scancode.LEFT,
	.Down                = sdl.Scancode.DOWN,
	.Up                  = sdl.Scancode.UP,
	.Num_Lock_Clear      = sdl.Scancode.NUMLOCKCLEAR,
	.Kp_Divide           = sdl.Scancode.KP_DIVIDE,
	.Kp_Multiply         = sdl.Scancode.KP_MULTIPLY,
	.Kp_Minus            = sdl.Scancode.KP_MINUS,
	.Kp_Plus             = sdl.Scancode.KP_PLUS,
	.Kp_Enter            = sdl.Scancode.KP_ENTER,
	.Kp_1                = sdl.Scancode.KP_1,
	.Kp_2                = sdl.Scancode.KP_2,
	.Kp_3                = sdl.Scancode.KP_3,
	.Kp_4                = sdl.Scancode.KP_4,
	.Kp_5                = sdl.Scancode.KP_5,
	.Kp_6                = sdl.Scancode.KP_6,
	.Kp_7                = sdl.Scancode.KP_7,
	.Kp_8                = sdl.Scancode.KP_8,
	.Kp_9                = sdl.Scancode.KP_9,
	.Kp_0                = sdl.Scancode.KP_0,
	.Kp_Period           = sdl.Scancode.KP_PERIOD,
	.Non_Us_Backslash    = sdl.Scancode.NONUSBACKSLASH,
	.Application         = sdl.Scancode.APPLICATION,
	.Power               = sdl.Scancode.POWER,
	.Kp_Equals           = sdl.Scancode.KP_EQUALS,
	.F13                 = sdl.Scancode.F13,
	.F14                 = sdl.Scancode.F14,
	.F15                 = sdl.Scancode.F15,
	.F16                 = sdl.Scancode.F16,
	.F17                 = sdl.Scancode.F17,
	.F18                 = sdl.Scancode.F18,
	.F19                 = sdl.Scancode.F19,
	.F20                 = sdl.Scancode.F20,
	.F21                 = sdl.Scancode.F21,
	.F22                 = sdl.Scancode.F22,
	.F23                 = sdl.Scancode.F23,
	.F24                 = sdl.Scancode.F24,
	.Execute             = sdl.Scancode.EXECUTE,
	.Help                = sdl.Scancode.HELP,
	.Menu                = sdl.Scancode.MENU,
	.Select              = sdl.Scancode.SELECT,
	.Stop                = sdl.Scancode.STOP,
	.Again               = sdl.Scancode.AGAIN,
	.Undo                = sdl.Scancode.UNDO,
	.Cut                 = sdl.Scancode.CUT,
	.Copy                = sdl.Scancode.COPY,
	.Paste               = sdl.Scancode.PASTE,
	.Find                = sdl.Scancode.FIND,
	.Mute                = sdl.Scancode.MUTE,
	.Volume_Up           = sdl.Scancode.VOLUMEUP,
	.Volume_Down         = sdl.Scancode.VOLUMEDOWN,
	.Kp_Comma            = sdl.Scancode.KP_COMMA,
	.Kp_Equals_As_400    = sdl.Scancode.KP_EQUALSAS400,
	.International_1     = sdl.Scancode.INTERNATIONAL1,
	.International_2     = sdl.Scancode.INTERNATIONAL2,
	.International_3     = sdl.Scancode.INTERNATIONAL3,
	.International_4     = sdl.Scancode.INTERNATIONAL4,
	.International_5     = sdl.Scancode.INTERNATIONAL5,
	.International_6     = sdl.Scancode.INTERNATIONAL6,
	.International_7     = sdl.Scancode.INTERNATIONAL7,
	.International_8     = sdl.Scancode.INTERNATIONAL8,
	.International_9     = sdl.Scancode.INTERNATIONAL9,
	.Lang_1              = sdl.Scancode.LANG1,
	.Lang_2              = sdl.Scancode.LANG2,
	.Lang_3              = sdl.Scancode.LANG3,
	.Lang_4              = sdl.Scancode.LANG4,
	.Lang_5              = sdl.Scancode.LANG5,
	.Lang_6              = sdl.Scancode.LANG6,
	.Lang_7              = sdl.Scancode.LANG7,
	.Lang_8              = sdl.Scancode.LANG8,
	.Lang_9              = sdl.Scancode.LANG9,
	.Alt_Erase           = sdl.Scancode.ALTERASE,
	.Sys_Req             = sdl.Scancode.SYSREQ,
	.Cancel              = sdl.Scancode.CANCEL,
	.Clear               = sdl.Scancode.CLEAR,
	.Prior               = sdl.Scancode.PRIOR,
	.Return_2            = sdl.Scancode.RETURN2,
	.Separator           = sdl.Scancode.SEPARATOR,
	.Out                 = sdl.Scancode.OUT,
	.Oper                = sdl.Scancode.OPER,
	.Clear_Again         = sdl.Scancode.CLEARAGAIN,
	.Cr_Sel              = sdl.Scancode.CRSEL,
	.Ex_Sel              = sdl.Scancode.EXSEL,
	.Kp_00               = sdl.Scancode.KP_00,
	.Kp_000              = sdl.Scancode.KP_000,
	.Thousands_Separator = sdl.Scancode.THOUSANDSSEPARATOR,
	.Decimal_Separator   = sdl.Scancode.DECIMALSEPARATOR,
	.Currency_Unit       = sdl.Scancode.CURRENCYUNIT,
	.Currency_Subunit    = sdl.Scancode.CURRENCYSUBUNIT,
	.Kp_Left_Paren       = sdl.Scancode.KP_LEFTPAREN,
	.Kp_Right_Paren      = sdl.Scancode.KP_RIGHTPAREN,
	.Kp_Left_Brace       = sdl.Scancode.KP_LEFTBRACE,
	.Kp_Right_Brace      = sdl.Scancode.KP_RIGHTBRACE,
	.Kp_Tab              = sdl.Scancode.KP_TAB,
	.Kp_Backspace        = sdl.Scancode.KP_BACKSPACE,
	.Kp_A                = sdl.Scancode.KP_A,
	.Kp_B                = sdl.Scancode.KP_B,
	.Kp_C                = sdl.Scancode.KP_C,
	.Kp_D                = sdl.Scancode.KP_D,
	.Kp_E                = sdl.Scancode.KP_E,
	.Kp_F                = sdl.Scancode.KP_F,
	.Kp_Xor              = sdl.Scancode.KP_XOR,
	.Kp_Power            = sdl.Scancode.KP_POWER,
	.Kp_Percent          = sdl.Scancode.KP_PERCENT,
	.Kp_Less             = sdl.Scancode.KP_LESS,
	.Kp_Greater          = sdl.Scancode.KP_GREATER,
	.Kp_Ampersand        = sdl.Scancode.KP_AMPERSAND,
	.Kp_Dbl_Ampersand    = sdl.Scancode.KP_DBLAMPERSAND,
	.Kp_Vertical_Bar     = sdl.Scancode.KP_VERTICALBAR,
	.Kp_Dbl_Vertical_Bar = sdl.Scancode.KP_DBLVERTICALBAR,
	.Kp_Colon            = sdl.Scancode.KP_COLON,
	.Kp_Hash             = sdl.Scancode.KP_HASH,
	.Kp_Space            = sdl.Scancode.KP_SPACE,
	.Kp_At               = sdl.Scancode.KP_AT,
	.Kp_Exclam           = sdl.Scancode.KP_EXCLAM,
	.Kp_Mem_Store        = sdl.Scancode.KP_MEMSTORE,
	.Kp_Mem_Recall       = sdl.Scancode.KP_MEMRECALL,
	.Kp_Mem_Clear        = sdl.Scancode.KP_MEMCLEAR,
	.Kp_Mem_Add          = sdl.Scancode.KP_MEMADD,
	.Kp_Mem_Subtract     = sdl.Scancode.KP_MEMSUBTRACT,
	.Kp_Mem_Multiply     = sdl.Scancode.KP_MEMMULTIPLY,
	.Kp_Mem_Divide       = sdl.Scancode.KP_MEMDIVIDE,
	.Kp_Plus_Minus       = sdl.Scancode.KP_PLUSMINUS,
	.Kp_Clear            = sdl.Scancode.KP_CLEAR,
	.Kp_Clear_Entry      = sdl.Scancode.KP_CLEARENTRY,
	.Kp_Binary           = sdl.Scancode.KP_BINARY,
	.Kp_Octal            = sdl.Scancode.KP_OCTAL,
	.Kp_Decimal          = sdl.Scancode.KP_DECIMAL,
	.Kp_Hexadecimal      = sdl.Scancode.KP_HEXADECIMAL,
	.Left_Ctrl           = sdl.Scancode.LCTRL,
	.Left_Shift          = sdl.Scancode.LSHIFT,
	.Left_Alt            = sdl.Scancode.LALT,
	.Left_Gui            = sdl.Scancode.LGUI,
	.Right_Ctrl          = sdl.Scancode.RCTRL,
	.Right_Shift         = sdl.Scancode.RSHIFT,
	.Right_Alt           = sdl.Scancode.RALT,
	.Right_Gui           = sdl.Scancode.RGUI,
	.Mode                = sdl.Scancode.MODE,
	.Audio_Next          = sdl.Scancode.AUDIONEXT,
	.Audio_Prev          = sdl.Scancode.AUDIOPREV,
	.Audio_Stop          = sdl.Scancode.AUDIOSTOP,
	.Audio_Play          = sdl.Scancode.AUDIOPLAY,
	.Audio_Mute          = sdl.Scancode.AUDIOMUTE,
	.Media_Select        = sdl.Scancode.MEDIASELECT,
	.WWW                 = sdl.Scancode.WWW,
	.Mail                = sdl.Scancode.MAIL,
	.Calculator          = sdl.Scancode.CALCULATOR,
	.Computer            = sdl.Scancode.COMPUTER,
	.Ac_Search           = sdl.Scancode.AC_SEARCH,
	.Ac_Home             = sdl.Scancode.AC_HOME,
	.Ac_Back             = sdl.Scancode.AC_BACK,
	.Ac_Forward          = sdl.Scancode.AC_FORWARD,
	.Ac_Stop             = sdl.Scancode.AC_STOP,
	.Ac_Refresh          = sdl.Scancode.AC_REFRESH,
	.Ac_Bookmarks        = sdl.Scancode.AC_BOOKMARKS,
	.Brightness_Down     = sdl.Scancode.BRIGHTNESSDOWN,
	.Brightness_Up       = sdl.Scancode.BRIGHTNESSUP,
	.Display_Switch      = sdl.Scancode.DISPLAYSWITCH,
	.Kbd_Illum_Toggle    = sdl.Scancode.KBDILLUMTOGGLE,
	.Kbd_Illum_Down      = sdl.Scancode.KBDILLUMDOWN,
	.Kbd_Illum_Up        = sdl.Scancode.KBDILLUMUP,
	.Eject               = sdl.Scancode.EJECT,
	.Sleep               = sdl.Scancode.SLEEP,
	.App_1               = sdl.Scancode.APP1,
	.App_2               = sdl.Scancode.APP2,
	.Audio_Rewind        = sdl.Scancode.AUDIOREWIND,
	.Audio_Fastforward   = sdl.Scancode.AUDIOFASTFORWARD,
}

_scancode_to_sdl_scancode :: proc "contextless" (
	scancode: Keyboard_Scancode,
) -> (
	sdl.Scancode,
	bool,
) #no_bounds_check #optional_ok {
	if int(scancode) < 0 || int(scancode) >= len(KEYBOARD_SCANCODE_TO_SDL_LUT) {
		return .UNKNOWN, false
	}
	return KEYBOARD_SCANCODE_TO_SDL_LUT[scancode], true
}

_sdl_to_key :: proc "contextless" (sdl_key: sdl.Keycode) -> Keyboard_Key {
	// odinfmt: disable
	#partial switch sdl_key {
	case .UNKNOWN:            return .Unknown
	case .RETURN:             return .Return
	case .ESCAPE:             return .Escape
	case .BACKSPACE:          return .Backspace
	case .TAB:                return .Tab
	case .SPACE:              return .Space
	case .EXCLAIM:            return .Exclaim
	case .QUOTEDBL:           return .Quotedbl
	case .HASH:               return .Hash
	case .PERCENT:            return .Percent
	case .DOLLAR:             return .Dollar
	case .AMPERSAND:          return .Ampersand
	case .QUOTE:              return .Quote
	case .LEFTPAREN:          return .Left_Paren
	case .RIGHTPAREN:         return .Right_Paren
	case .ASTERISK:           return .Asterisk
	case .PLUS:               return .Plus
	case .COMMA:              return .Comma
	case .MINUS:              return .Minus
	case .PERIOD:             return .Period
	case .SLASH:              return .Slash
	case .NUM0:               return .Num_0
	case .NUM1:               return .Num_1
	case .NUM2:               return .Num_2
	case .NUM3:               return .Num_3
	case .NUM4:               return .Num_4
	case .NUM5:               return .Num_5
	case .NUM6:               return .Num_6
	case .NUM7:               return .Num_7
	case .NUM8:               return .Num_8
	case .NUM9:               return .Num_9
	case .COLON:              return .Colon
	case .SEMICOLON:          return .Semicolon
	case .LESS:               return .Less
	case .EQUALS:             return .Equals
	case .GREATER:            return .Greater
	case .QUESTION:           return .Question
	case .AT:                 return .At
	case .LEFTBRACKET:        return .Left_Bracket
	case .BACKSLASH:          return .Backslash
	case .RIGHTBRACKET:       return .Right_Bracket
	case .CARET:              return .Caret
	case .UNDERSCORE:         return .Underscore
	case .BACKQUOTE:          return .Backquote
	case .a:                  return .a
	case .b:                  return .b
	case .c:                  return .c
	case .d:                  return .d
	case .e:                  return .e
	case .f:                  return .f
	case .g:                  return .g
	case .h:                  return .h
	case .i:                  return .i
	case .j:                  return .j
	case .k:                  return .k
	case .l:                  return .l
	case .m:                  return .m
	case .n:                  return .n
	case .o:                  return .o
	case .p:                  return .p
	case .q:                  return .q
	case .r:                  return .r
	case .s:                  return .s
	case .t:                  return .t
	case .u:                  return .u
	case .v:                  return .v
	case .w:                  return .w
	case .x:                  return .x
	case .y:                  return .y
	case .z:                  return .z
	case .CAPSLOCK:           return .Caps_Lock
	case .F1:                 return .F1
	case .F2:                 return .F2
	case .F3:                 return .F3
	case .F4:                 return .F4
	case .F5:                 return .F5
	case .F6:                 return .F6
	case .F7:                 return .F7
	case .F8:                 return .F8
	case .F9:                 return .F9
	case .F10:                return .F10
	case .F11:                return .F11
	case .F12:                return .F12
	case .PRINTSCREEN:        return .Print_Screen
	case .SCROLLLOCK:         return .Scroll_Lock
	case .PAUSE:              return .Pause
	case .INSERT:             return .Insert
	case .HOME:               return .Home
	case .PAGEUP:             return .Page_Up
	case .DELETE:             return .Delete
	case .END:                return .End
	case .PAGEDOWN:           return .Page_Down
	case .RIGHT:              return .Right
	case .LEFT:               return .Left
	case .DOWN:               return .Down
	case .UP:                 return .Up
	case .NUMLOCKCLEAR:       return .Num_Lock_Clear
	case .KP_DIVIDE:          return .Kp_Divide
	case .KP_MULTIPLY:        return .Kp_Multiply
	case .KP_MINUS:           return .Kp_Minus
	case .KP_PLUS:            return .Kp_Plus
	case .KP_ENTER:           return .Kp_Enter
	case .KP_1:               return .Kp_1
	case .KP_2:               return .Kp_2
	case .KP_3:               return .Kp_3
	case .KP_4:               return .Kp_4
	case .KP_5:               return .Kp_5
	case .KP_6:               return .Kp_6
	case .KP_7:               return .Kp_7
	case .KP_8:               return .Kp_8
	case .KP_9:               return .Kp_9
	case .KP_0:               return .Kp_0
	case .KP_PERIOD:          return .Kp_Period
	case .APPLICATION:        return .Application
	case .POWER:              return .Power
	case .KP_EQUALS:          return .Kp_Equals
	case .F13:                return .F13
	case .F14:                return .F14
	case .F15:                return .F15
	case .F16:                return .F16
	case .F17:                return .F17
	case .F18:                return .F18
	case .F19:                return .F19
	case .F20:                return .F20
	case .F21:                return .F21
	case .F22:                return .F22
	case .F23:                return .F23
	case .F24:                return .F24
	case .EXECUTE:            return .Execute
	case .HELP:               return .Help
	case .MENU:               return .Menu
	case .SELECT:             return .Select
	case .STOP:               return .Stop
	case .AGAIN:              return .Again
	case .UNDO:               return .Undo
	case .CUT:                return .Cut
	case .COPY:               return .Copy
	case .PASTE:              return .Paste
	case .FIND:               return .Find
	case .MUTE:               return .Mute
	case .VOLUMEUP:           return .Volume_Up
	case .VOLUMEDOWN:         return .Volume_Down
	case .KP_COMMA:           return .Kp_Comma
	case .KP_EQUALSAS400:     return .Kp_Equals_As_400
	case .ALTERASE:           return .Alt_Erase
	case .SYSREQ:             return .Sys_Req
	case .CANCEL:             return .Cancel
	case .CLEAR:              return .Clear
	case .PRIOR:              return .Prior
	case .RETURN2:            return .Return2
	case .SEPARATOR:          return .Separator
	case .OUT:                return .Out
	case .OPER:               return .Oper
	case .CLEARAGAIN:         return .Clear_Again
	case .CRSEL:              return .Cr_Sel
	case .EXSEL:              return .Ex_Sel
	case .KP_00:              return .Kp_00
	case .KP_000:             return .Kp_000
	case .THOUSANDSSEPARATOR: return .Thousands_Separator
	case .DECIMALSEPARATOR:   return .Decimal_Separator
	case .CURRENCYUNIT:       return .Currency_Unit
	case .CURRENCYSUBUNIT:    return .Currency_Subunit
	case .KP_LEFTPAREN:       return .Kp_Left_Paren
	case .KP_RIGHTPAREN:      return .Kp_Right_Paren
	case .KP_LEFTBRACE:       return .Kp_Left_Brace
	case .KP_RIGHTBRACE:      return .Kp_Right_Brace
	case .KP_TAB:             return .Kp_Tab
	case .KP_BACKSPACE:       return .Kp_Backspace
	case .KP_A:               return .Kp_A
	case .KP_B:               return .Kp_B
	case .KP_C:               return .Kp_C
	case .KP_D:               return .Kp_D
	case .KP_E:               return .Kp_E
	case .KP_F:               return .Kp_F
	case .KP_XOR:             return .Kp_Xor
	case .KP_POWER:           return .Kp_Power
	case .KP_PERCENT:         return .Kp_Percent
	case .KP_LESS:            return .Kp_Less
	case .KP_GREATER:         return .Kp_Greater
	case .KP_AMPERSAND:       return .Kp_Ampersand
	case .KP_DBLAMPERSAND:    return .Kp_Dbl_Ampersand
	case .KP_VERTICALBAR:     return .Kp_Vertical_Bar
	case .KP_DBLVERTICALBAR:  return .Kp_Dbl_Vertical_Bar
	case .KP_COLON:           return .Kp_Colon
	case .KP_HASH:            return .Kp_Hash
	case .KP_SPACE:           return .Kp_Space
	case .KP_AT:              return .Kp_At
	case .KP_EXCLAM:          return .Kp_Exclam
	case .KP_MEMSTORE:        return .Kp_Mem_Store
	case .KP_MEMRECALL:       return .Kp_Mem_Recall
	case .KP_MEMCLEAR:        return .Kp_Mem_Clear
	case .KP_MEMADD:          return .Kp_Mem_Add
	case .KP_MEMSUBTRACT:     return .Kp_Mem_Subtract
	case .KP_MEMMULTIPLY:     return .Kp_Mem_Multiply
	case .KP_MEMDIVIDE:       return .Kp_Mem_Divide
	case .KP_PLUSMINUS:       return .Kp_Plus_Minus
	case .KP_CLEAR:           return .Kp_Clear
	case .KP_CLEARENTRY:      return .Kp_Clear_Entry
	case .KP_BINARY:          return .Kp_Binary
	case .KP_OCTAL:           return .Kp_Octal
	case .KP_DECIMAL:         return .Kp_Decimal
	case .KP_HEXADECIMAL:     return .Kp_Hexadecimal
	case .LCTRL:              return .Left_Ctrl
	case .LSHIFT:             return .Left_Shift
	case .LALT:               return .Left_Alt
	case .LGUI:               return .Left_Gui
	case .RCTRL:              return .Right_Ctrl
	case .RSHIFT:             return .Right_Shift
	case .RALT:               return .Right_Alt
	case .RGUI:               return .Right_Gui
	case .MODE:               return .Mode
	case .AUDIONEXT:          return .Audio_Next
	case .AUDIOPREV:          return .Audio_Prev
	case .AUDIOSTOP:          return .Audio_Stop
	case .AUDIOPLAY:          return .Audio_Play
	case .AUDIOMUTE:          return .Audio_Mute
	case .MEDIASELECT:        return .Media_Select
	case .WWW:                return .WWW
	case .MAIL:               return .Mail
	case .CALCULATOR:         return .Calculator
	case .COMPUTER:           return .Computer
	case .AC_SEARCH:          return .Ac_Search
	case .AC_HOME:            return .Ac_Home
	case .AC_BACK:            return .Ac_Back
	case .AC_FORWARD:         return .Ac_Forward
	case .AC_STOP:            return .Ac_Stop
	case .AC_REFRESH:         return .Ac_Refresh
	case .AC_BOOKMARKS:       return .Ac_Bookmarks
	case .BRIGHTNESSDOWN:     return .Brightness_Down
	case .BRIGHTNESSUP:       return .Brightness_Up
	case .DISPLAYSWITCH:      return .Display_Switch
	case .KBDILLUMTOGGLE:     return .Kbd_Illum_Toggle
	case .KBDILLUMDOWN:       return .Kbd_Illum_Down
	case .KBDILLUMUP:         return .Kbd_Illum_Up
	case .EJECT:              return .Eject
	case .SLEEP:              return .Sleep
	case .APP1:               return .App_1
	case .APP2:               return .App_2
	case .AUDIOREWIND:        return .Audio_Rewind
	case .AUDIOFASTFORWARD:   return .Audio_Fastforward
	}
	// odinfmt: enable

	return .Unknown
}

_key_to_sdl :: proc "contextless" (key: Keyboard_Key) -> sdl.Keycode {
	// odinfmt: disable
	switch key {
	case .Unknown:             return .UNKNOWN
	case .Return:              return .RETURN
	case .Escape:              return .ESCAPE
	case .Backspace:           return .BACKSPACE
	case .Tab:                 return .TAB
	case .Space:               return .SPACE
	case .Exclaim:             return .EXCLAIM
	case .Quotedbl:            return .QUOTEDBL
	case .Hash:                return .HASH
	case .Percent:             return .PERCENT
	case .Dollar:              return .DOLLAR
	case .Ampersand:           return .AMPERSAND
	case .Quote:               return .QUOTE
	case .Left_Paren:          return .LEFTPAREN
	case .Right_Paren:         return .RIGHTPAREN
	case .Asterisk:            return .ASTERISK
	case .Plus:                return .PLUS
	case .Comma:               return .COMMA
	case .Minus:               return .MINUS
	case .Period:              return .PERIOD
	case .Slash:               return .SLASH
	case .Num_0:               return .NUM0
	case .Num_1:               return .NUM1
	case .Num_2:               return .NUM2
	case .Num_3:               return .NUM3
	case .Num_4:               return .NUM4
	case .Num_5:               return .NUM5
	case .Num_6:               return .NUM6
	case .Num_7:               return .NUM7
	case .Num_8:               return .NUM8
	case .Num_9:               return .NUM9
	case .Colon:               return .COLON
	case .Semicolon:           return .SEMICOLON
	case .Less:                return .LESS
	case .Equals:              return .EQUALS
	case .Greater:             return .GREATER
	case .Question:            return .QUESTION
	case .At:                  return .AT
	case .Left_Bracket:        return .LEFTBRACKET
	case .Backslash:           return .BACKSLASH
	case .Right_Bracket:       return .RIGHTBRACKET
	case .Caret:               return .CARET
	case .Underscore:          return .UNDERSCORE
	case .Backquote:           return .BACKQUOTE
	case .a:                   return .a
	case .b:                   return .b
	case .c:                   return .c
	case .d:                   return .d
	case .e:                   return .e
	case .f:                   return .f
	case .g:                   return .g
	case .h:                   return .h
	case .i:                   return .i
	case .j:                   return .j
	case .k:                   return .k
	case .l:                   return .l
	case .m:                   return .m
	case .n:                   return .n
	case .o:                   return .o
	case .p:                   return .p
	case .q:                   return .q
	case .r:                   return .r
	case .s:                   return .s
	case .t:                   return .t
	case .u:                   return .u
	case .v:                   return .v
	case .w:                   return .w
	case .x:                   return .x
	case .y:                   return .y
	case .z:                   return .z
	case .Caps_Lock:           return .CAPSLOCK
	case .F1:                  return .F1
	case .F2:                  return .F2
	case .F3:                  return .F3
	case .F4:                  return .F4
	case .F5:                  return .F5
	case .F6:                  return .F6
	case .F7:                  return .F7
	case .F8:                  return .F8
	case .F9:                  return .F9
	case .F10:                 return .F10
	case .F11:                 return .F11
	case .F12:                 return .F12
	case .Print_Screen:        return .PRINTSCREEN
	case .Scroll_Lock:         return .SCROLLLOCK
	case .Pause:               return .PAUSE
	case .Insert:              return .INSERT
	case .Home:                return .HOME
	case .Page_Up:             return .PAGEUP
	case .Delete:              return .DELETE
	case .End:                 return .END
	case .Page_Down:           return .PAGEDOWN
	case .Right:               return .RIGHT
	case .Left:                return .LEFT
	case .Down:                return .DOWN
	case .Up:                  return .UP
	case .Num_Lock_Clear:      return .NUMLOCKCLEAR
	case .Kp_Divide:           return .KP_DIVIDE
	case .Kp_Multiply:         return .KP_MULTIPLY
	case .Kp_Minus:            return .KP_MINUS
	case .Kp_Plus:             return .KP_PLUS
	case .Kp_Enter:            return .KP_ENTER
	case .Kp_1:                return .KP_1
	case .Kp_2:                return .KP_2
	case .Kp_3:                return .KP_3
	case .Kp_4:                return .KP_4
	case .Kp_5:                return .KP_5
	case .Kp_6:                return .KP_6
	case .Kp_7:                return .KP_7
	case .Kp_8:                return .KP_8
	case .Kp_9:                return .KP_9
	case .Kp_0:                return .KP_0
	case .Kp_Period:           return .KP_PERIOD
	case .Application:         return .APPLICATION
	case .Power:               return .POWER
	case .Kp_Equals:           return .KP_EQUALS
	case .F13:                 return .F13
	case .F14:                 return .F14
	case .F15:                 return .F15
	case .F16:                 return .F16
	case .F17:                 return .F17
	case .F18:                 return .F18
	case .F19:                 return .F19
	case .F20:                 return .F20
	case .F21:                 return .F21
	case .F22:                 return .F22
	case .F23:                 return .F23
	case .F24:                 return .F24
	case .Execute:             return .EXECUTE
	case .Help:                return .HELP
	case .Menu:                return .MENU
	case .Select:              return .SELECT
	case .Stop:                return .STOP
	case .Again:               return .AGAIN
	case .Undo:                return .UNDO
	case .Cut:                 return .CUT
	case .Copy:                return .COPY
	case .Paste:               return .PASTE
	case .Find:                return .FIND
	case .Mute:                return .MUTE
	case .Volume_Up:           return .VOLUMEUP
	case .Volume_Down:         return .VOLUMEDOWN
	case .Kp_Comma:            return .KP_COMMA
	case .Kp_Equals_As_400:    return .KP_EQUALSAS400
	case .Alt_Erase:           return .ALTERASE
	case .Sys_Req:             return .SYSREQ
	case .Cancel:              return .CANCEL
	case .Clear:               return .CLEAR
	case .Prior:               return .PRIOR
	case .Return2:             return .RETURN2
	case .Separator:           return .SEPARATOR
	case .Out:                 return .OUT
	case .Oper:                return .OPER
	case .Clear_Again:         return .CLEARAGAIN
	case .Cr_Sel:              return .CRSEL
	case .Ex_Sel:              return .EXSEL
	case .Kp_00:               return .KP_00
	case .Kp_000:              return .KP_000
	case .Thousands_Separator: return .THOUSANDSSEPARATOR
	case .Decimal_Separator:   return .DECIMALSEPARATOR
	case .Currency_Unit:       return .CURRENCYUNIT
	case .Currency_Subunit:    return .CURRENCYSUBUNIT
	case .Kp_Left_Paren:       return .KP_LEFTPAREN
	case .Kp_Right_Paren:      return .KP_RIGHTPAREN
	case .Kp_Left_Brace:       return .KP_LEFTBRACE
	case .Kp_Right_Brace:      return .KP_RIGHTBRACE
	case .Kp_Tab:              return .KP_TAB
	case .Kp_Backspace:        return .KP_BACKSPACE
	case .Kp_A:                return .KP_A
	case .Kp_B:                return .KP_B
	case .Kp_C:                return .KP_C
	case .Kp_D:                return .KP_D
	case .Kp_E:                return .KP_E
	case .Kp_F:                return .KP_F
	case .Kp_Xor:              return .KP_XOR
	case .Kp_Power:            return .KP_POWER
	case .Kp_Percent:          return .KP_PERCENT
	case .Kp_Less:             return .KP_LESS
	case .Kp_Greater:          return .KP_GREATER
	case .Kp_Ampersand:        return .KP_AMPERSAND
	case .Kp_Dbl_Ampersand:    return .KP_DBLAMPERSAND
	case .Kp_Vertical_Bar:     return .KP_VERTICALBAR
	case .Kp_Dbl_Vertical_Bar: return .KP_DBLVERTICALBAR
	case .Kp_Colon:            return .KP_COLON
	case .Kp_Hash:             return .KP_HASH
	case .Kp_Space:            return .KP_SPACE
	case .Kp_At:               return .KP_AT
	case .Kp_Exclam:           return .KP_EXCLAM
	case .Kp_Mem_Store:        return .KP_MEMSTORE
	case .Kp_Mem_Recall:       return .KP_MEMRECALL
	case .Kp_Mem_Clear:        return .KP_MEMCLEAR
	case .Kp_Mem_Add:          return .KP_MEMADD
	case .Kp_Mem_Subtract:     return .KP_MEMSUBTRACT
	case .Kp_Mem_Multiply:     return .KP_MEMMULTIPLY
	case .Kp_Mem_Divide:       return .KP_MEMDIVIDE
	case .Kp_Plus_Minus:       return .KP_PLUSMINUS
	case .Kp_Clear:            return .KP_CLEAR
	case .Kp_Clear_Entry:      return .KP_CLEARENTRY
	case .Kp_Binary:           return .KP_BINARY
	case .Kp_Octal:            return .KP_OCTAL
	case .Kp_Decimal:          return .KP_DECIMAL
	case .Kp_Hexadecimal:      return .KP_HEXADECIMAL
	case .Left_Ctrl:           return .LCTRL
	case .Left_Shift:          return .LSHIFT
	case .Left_Alt:            return .LALT
	case .Left_Gui:            return .LGUI
	case .Right_Ctrl:          return .RCTRL
	case .Right_Shift:         return .RSHIFT
	case .Right_Alt:           return .RALT
	case .Right_Gui:           return .RGUI
	case .Mode:                return .MODE
	case .Audio_Next:          return .AUDIONEXT
	case .Audio_Prev:          return .AUDIOPREV
	case .Audio_Stop:          return .AUDIOSTOP
	case .Audio_Play:          return .AUDIOPLAY
	case .Audio_Mute:          return .AUDIOMUTE
	case .Media_Select:        return .MEDIASELECT
	case .WWW:                 return .WWW
	case .Mail:                return .MAIL
	case .Calculator:          return .CALCULATOR
	case .Computer:            return .COMPUTER
	case .Ac_Search:           return .AC_SEARCH
	case .Ac_Home:             return .AC_HOME
	case .Ac_Back:             return .AC_BACK
	case .Ac_Forward:          return .AC_FORWARD
	case .Ac_Stop:             return .AC_STOP
	case .Ac_Refresh:          return .AC_REFRESH
	case .Ac_Bookmarks:        return .AC_BOOKMARKS
	case .Brightness_Down:     return .BRIGHTNESSDOWN
	case .Brightness_Up:       return .BRIGHTNESSUP
	case .Display_Switch:      return .DISPLAYSWITCH
	case .Kbd_Illum_Toggle:    return .KBDILLUMTOGGLE
	case .Kbd_Illum_Down:      return .KBDILLUMDOWN
	case .Kbd_Illum_Up:        return .KBDILLUMUP
	case .Eject:               return .EJECT
	case .Sleep:               return .SLEEP
	case .App_1:               return .APP1
	case .App_2:               return .APP2
	case .Audio_Rewind:        return .AUDIOREWIND
	case .Audio_Fastforward:   return .AUDIOFASTFORWARD
	}
	// odinfmt: enable

	return .UNKNOWN
}
