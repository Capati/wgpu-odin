//+build linux

package wgpu_utils_glfw

// Core
import "core:fmt"
import "core:os"
import "core:runtime"

// Vendor
import "vendor:glfw"

// Package
import wgpu "../../wrapper"

get_surface_descriptor :: proc(
    w: glfw.WindowHandle,
) -> (
    descriptor: wgpu.Surface_Descriptor,
    err: wgpu.Error_Type,
) {
    // We use the environment variable `WAYLAND_DISPLAY` to detect wayland
    // sessions, and `DISPLAY` for Xorg/X11 sessions.
    // If both are empty or not set, we can assume there is no support for
    // graphical desktop session.

    runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

    wayland_value, found_wayland := os.lookup_env(
        "WAYLAND_DISPLAY",
        context.temp_allocator,
    )

    // TODO: GLFW vendor is missing native bindings.

    // Setup surface information
    if found_wayland && wayland_value != "" {
        descriptor.target = wgpu.Surface_Descriptor_From_Wayland_Surface {
            display = glfw.GetWaylandDisplay(),
            surface = glfw.GetWaylandWindow(w),
        }

        return
    }

    x11_value, found_x11 := os.lookup_env("DISPLAY", context.temp_allocator)

    if found_x11 && x11_value != "" {
        descriptor.target = wgpu.Surface_Descriptor_From_Xlib_Window {
            display = glfw.GetX11Display(),
            window  = cast(u32)glfw.GetX11Window(w),
        }

        return
    }

    fmt.eprintf("ERROR: Unable to recognize the current desktop session.")
    return {}, .Internal
}
