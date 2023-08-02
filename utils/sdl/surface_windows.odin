//+build windows

package wgpu_utils_sdl

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
    descriptor.Windows_HWND =
    &{hinstance = wm_info.info.win.hinstance, hwnd = wm_info.info.win.window}

    return
}
