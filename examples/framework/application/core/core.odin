package application_core

Physical_Size :: struct {
    width:  u32,
    height: u32,
}

Properties :: struct {
    title: cstring,
    size:  Physical_Size,
}

Application_Error :: enum {
    No_Error,
    Canvas_Failed,
    Gpu_Failed,
    Init_Failed,
}

Platform_Tag :: enum {
    Windows,
    X11,
    Cocoa,
    Wayland,
    Android,
    Browser,
}

Platform_Info :: struct {
    platform_tag: Platform_Tag,
    windows:      struct {
        window:    rawptr,
        hinstance: rawptr,
    },
    x11:          struct {
        display: rawptr,
        window:  uintptr,
    },
    cocoa:        struct {
        window: rawptr,
    },
    wayland:      struct {
        display: rawptr,
        surface: rawptr,
    },
    android:      struct {
        window:  rawptr,
        surface: rawptr,
    },
    browser:      struct {
        selector: cstring,
    },
}

Default_Physical_Size :: Physical_Size{800, 600}
Default_Properties :: Properties {
    title = "Game",
    size  = Default_Physical_Size,
}
