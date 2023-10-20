package wgpu_utils_glfw

// Vendor
import "vendor:glfw"

// Package
import wgpu "../../wrapper"

create_surface :: proc(
    window: glfw.WindowHandle,
    instance: ^wgpu.Instance,
) -> (
    surface: wgpu.Surface,
    err: wgpu.Error_Type,
) {
    surface_descriptor := get_surface_descriptor(window) or_return
    return instance->create_surface(&surface_descriptor)
}
