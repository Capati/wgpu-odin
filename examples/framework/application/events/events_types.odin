package events

Key_Mods :: struct {
	left_shift:  bool,
	right_shift: bool,
	left_ctrl:   bool,
	right_ctrl:  bool,
	left_alt:    bool,
	right_alt:   bool,
	left_super:  bool,
	right_super: bool,
	num:         bool,
	caps:        bool,
	mode:        bool,
}

Text_Input_Event :: struct {
	buf: [32]u8,
	ch:  string,
}

Key_Event :: struct {
	key:    Key,
	repeat: bool,
	mods:   Key_Mods,
}

Key_Press_Event :: distinct Key_Event
Key_Release_Event :: distinct Key_Event

Position :: struct {
	x, y: i32,
}

Mouse_Motion_Event :: distinct Position
Mouse_Scroll_Event :: distinct Position

Mouse_Button :: enum {
	Left,
	Right,
	Middle,
	Four,
	Five,
}

Mouse_Button_Event :: struct {
	button: Mouse_Button,
	pos:    Position,
	mods:   Key_Mods,
}

Mouse_Press_Event :: distinct Mouse_Button_Event
Mouse_Release_Event :: distinct Mouse_Button_Event

Framebuffer_Resize_Event :: struct {
	width:  u32,
	height: u32,
}

Focus_Gained_Event :: distinct bool

Focus_Lost_Event :: distinct bool

Quit_Event :: distinct bool

Key :: enum {
	Unknown            = 0,
	A                  = 4,
	B                  = 5,
	C                  = 6,
	D                  = 7,
	E                  = 8,
	F                  = 9,
	G                  = 10,
	H                  = 11,
	I                  = 12,
	J                  = 13,
	K                  = 14,
	L                  = 15,
	M                  = 16,
	N                  = 17,
	O                  = 18,
	P                  = 19,
	Q                  = 20,
	R                  = 21,
	S                  = 22,
	T                  = 23,
	U                  = 24,
	V                  = 25,
	W                  = 26,
	X                  = 27,
	Y                  = 28,
	Z                  = 29,
	Num1               = 30,
	Num2               = 31,
	Num3               = 32,
	Num4               = 33,
	Num5               = 34,
	Num6               = 35,
	Num7               = 36,
	Num8               = 37,
	Num9               = 38,
	Num0               = 39,
	Return             = 40,
	Escape             = 41,
	Backspace          = 42,
	Tab                = 43,
	Space              = 44,
	Minus              = 45,
	Equals             = 46,
	Leftbracket        = 47,
	Rightbracket       = 48,
	Backslash          = 49,
	Nonushash          = 50,
	Semicolon          = 51,
	Apostrophe         = 52,
	Grave              = 53,
	Comma              = 54,
	Period             = 55,
	Slash              = 56,
	Capslock           = 57,
	F1                 = 58,
	F2                 = 59,
	F3                 = 60,
	F4                 = 61,
	F5                 = 62,
	F6                 = 63,
	F7                 = 64,
	F8                 = 65,
	F9                 = 66,
	F10                = 67,
	F11                = 68,
	F12                = 69,
	Printscreen        = 70,
	Scrolllock         = 71,
	Pause              = 72,
	Insert             = 73,
	Home               = 74,
	Pageup             = 75,
	Delete             = 76,
	End                = 77,
	Pagedown           = 78,
	Right              = 79,
	Left               = 80,
	Down               = 81,
	Up                 = 82,
	Numlockclear       = 83,
	Kp_Divide          = 84,
	Kp_Multiply        = 85,
	Kp_Minus           = 86,
	Kp_Plus            = 87,
	Kp_Enter           = 88,
	Kp_1               = 89,
	Kp_2               = 90,
	Kp_3               = 91,
	Kp_4               = 92,
	Kp_5               = 93,
	Kp_6               = 94,
	Kp_7               = 95,
	Kp_8               = 96,
	Kp_9               = 97,
	Kp_0               = 98,
	Kp_Period          = 99,
	Nonusbackslash     = 100,
	Application        = 101,
	Power              = 102,
	Kp_Equals          = 103,
	F13                = 104,
	F14                = 105,
	F15                = 106,
	F16                = 107,
	F17                = 108,
	F18                = 109,
	F19                = 110,
	F20                = 111,
	F21                = 112,
	F22                = 113,
	F23                = 114,
	F24                = 115,
	Execute            = 116,
	Help               = 117,
	Menu               = 118,
	Select             = 119,
	Stop               = 120,
	Again              = 121,
	Undo               = 122,
	Cut                = 123,
	Copy               = 124,
	Paste              = 125,
	Find               = 126,
	Mute               = 127,
	Volumeup           = 128,
	Volumedown         = 129,
	Kp_Comma           = 133,
	Kp_Equalsas400     = 134,
	International1     = 135,
	International2     = 136,
	International3     = 137,
	International4     = 138,
	International5     = 139,
	International6     = 140,
	International7     = 141,
	International8     = 142,
	International9     = 143,
	Lang1              = 144,
	Lang2              = 145,
	Lang3              = 146,
	Lang4              = 147,
	Lang5              = 148,
	Lang6              = 149,
	Lang7              = 150,
	Lang8              = 151,
	Lang9              = 152,
	Alterase           = 153,
	Sysreq             = 154,
	Cancel             = 155,
	Clear              = 156,
	Prior              = 157,
	Return2            = 158,
	Separator          = 159,
	Out                = 160,
	Oper               = 161,
	Clearagain         = 162,
	Crsel              = 163,
	Exsel              = 164,
	Kp_00              = 176,
	Kp_000             = 177,
	Thousandsseparator = 178,
	Decimalseparator   = 179,
	Currencyunit       = 180,
	Currencysubunit    = 181,
	Kp_Leftparen       = 182,
	Kp_Rightparen      = 183,
	Kp_Leftbrace       = 184,
	Kp_Rightbrace      = 185,
	Kp_Tab             = 186,
	Kp_Backspace       = 187,
	Kp_A               = 188,
	Kp_B               = 189,
	Kp_C               = 190,
	Kp_D               = 191,
	Kp_E               = 192,
	Kp_F               = 193,
	Kp_Xor             = 194,
	Kp_Power           = 195,
	Kp_Percent         = 196,
	Kp_Less            = 197,
	Kp_Greater         = 198,
	Kp_Ampersand       = 199,
	Kp_Dblampersand    = 200,
	Kp_Verticalbar     = 201,
	Kp_Dblverticalbar  = 202,
	Kp_Colon           = 203,
	Kp_Hash            = 204,
	Kp_Space           = 205,
	Kp_At              = 206,
	Kp_Exclam          = 207,
	Kp_Memstore        = 208,
	Kp_Memrecall       = 209,
	Kp_Memclear        = 210,
	Kp_Memadd          = 211,
	Kp_Memsubtract     = 212,
	Kp_Memmultiply     = 213,
	Kp_Memdivide       = 214,
	Kp_Plusminus       = 215,
	Kp_Clear           = 216,
	Kp_Clearentry      = 217,
	Kp_Binary          = 218,
	Kp_Octal           = 219,
	Kp_Decimal         = 220,
	Kp_Hexadecimal     = 221,
	Lctrl              = 224,
	Lshift             = 225,
	Lalt               = 226,
	Lgui               = 227,
	Rctrl              = 228,
	Rshift             = 229,
	Ralt               = 230,
	Rgui               = 231,
	Mode               = 257,
	Audionext          = 258,
	Audioprev          = 259,
	Audiostop          = 260,
	Audioplay          = 261,
	Audiomute          = 262,
	Mediaselect        = 263,
	Www                = 264,
	Mail               = 265,
	Calculator         = 266,
	Computer           = 267,
	Ac_Search          = 268,
	Ac_Home            = 269,
	Ac_Back            = 270,
	Ac_Forward         = 271,
	Ac_Stop            = 272,
	Ac_Refresh         = 273,
	Ac_Bookmarks       = 274,
	Brightnessdown     = 275,
	Brightnessup       = 276,
	Displayswitch      = 277,
	Kbdillumtoggle     = 278,
	Kbdillumdown       = 279,
	Kbdillumup         = 280,
	Eject              = 281,
	Sleep              = 282,
	App1               = 283,
	App2               = 284,
	Audiorewind        = 285,
	Audiofastforward   = 286,
	Num_Scancodes      = 512,
}
