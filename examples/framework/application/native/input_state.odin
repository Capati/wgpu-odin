package native_application

// Package
import "../events"

// Vendor
import sdl "vendor:sdl2"

Key :: events.Key

get_key_state :: proc(key: sdl.KeyboardEvent) -> (key_event: events.Key_Event) {
    key_event = {
        key    = cast(Key)key.keysym.scancode,
        repeat = key.repeat > 0,
        mods   = get_mod_state(key.keysym.mod),
    }

    return
}

get_mouse_state :: proc(button: sdl.MouseButtonEvent) -> (mouse_event: events.Mouse_Button_Event) {
    switch button.button {
    case sdl.BUTTON_LEFT:
        mouse_event.button = .Left
    case sdl.BUTTON_MIDDLE:
        mouse_event.button = .Middle
    case sdl.BUTTON_RIGHT:
        mouse_event.button = .Right
    case sdl.BUTTON_X1:
        mouse_event.button = .Four
    case sdl.BUTTON_X2:
        mouse_event.button = .Five
    }

    mouse_event.mods = get_mod_state(sdl.GetModState())
    mouse_event.pos = {f64(button.x), f64(button.y)}

    return
}

get_mod_state :: proc(mod: sdl.Keymod) -> (key_mods: events.Key_Mods) {
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
