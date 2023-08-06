//+build linux

package wgpu_utils_sdl

// Core
import "core:c"

// Vendor
import sdl "vendor:sdl2"

// Package
import wgpu "../../wrapper"

get_surface_descriptor :: proc(
    window: ^sdl.Window,
) -> (
    descriptor: wgpu.Surface_Descriptor,
    err: wgpu.Error_Type,
) {
    wm_info := get_sys_info(window) or_return

    // Setup surface information
    descriptor = default_surface_descriptor

    if wm_info.subsystem == .WAYLAND {
        descriptor.Wayland_Surface =
        &{display = wm_info.info.wl.display, surface = wm_info.info.wl.surface}
    } else if wm_info.subsystem == .X11 {
        descriptor.Xlib_Window =
        &{
            display = wm_info.info.x11.display,
            window = cast(c.uint32_t)wm_info.info.x11.window,
        }
    }

    return
}
