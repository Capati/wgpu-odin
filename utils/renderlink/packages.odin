package renderlink

EVENT_PACKAGE    :: #config(RL_EVENT_PACKAGE, true)
GRAPHICS_PACKAGE :: #config(RL_GRAPHICS_PACKAGE, true)
JOYSTICK_PACKAGE :: #config(RL_JOYSTICK_PACKAGE, true)
KEYBOARD_PACKAGE :: #config(RL_KEYBOARD_PACKAGE, true)
MOUSE_PACKAGE    :: #config(RL_MOUSE_PACKAGE, true)
SYSTEM_PACKAGE   :: #config(RL_SYSTEM_PACKAGE, true)
TIMER_PACKAGE    :: #config(RL_TIMER_PACKAGE, true)
WINDOW_PACKAGE   :: #config(RL_WINDOW_PACKAGE, true)

Packages :: enum u8 {
	Audio,
	Data,
	Event,
	Font,
	Graphics,
	Image,
	Joystick,
	Keyboard,
	Math,
	Mouse,
	Physics,
	Sound,
	System,
	Thread,
	Timer,
	Touch,
	Video,
	Window,
}

Packages_Flags :: bit_set[Packages;u32]
PACKAGES_ALL :: Packages_Flags {
	Packages.Audio,
	Packages.Data,
	Packages.Event,
	Packages.Font,
	Packages.Graphics,
	Packages.Image,
	Packages.Joystick,
	Packages.Keyboard,
	Packages.Math,
	Packages.Mouse,
	Packages.Physics,
	Packages.Sound,
	Packages.System,
	Packages.Thread,
	Packages.Timer,
	Packages.Touch,
	Packages.Video,
	Packages.Window,
}
