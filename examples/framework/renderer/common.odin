package renderer

// Core
import "core:fmt"
// Package
import wgpu "../../../wrapper"
// Framework
import app "../application"

get_current_texture_frame :: proc(
    renderer: ^Renderer,
) -> (
    frame: wgpu.Surface_Texture,
    err: wgpu.Error_Type,
) {
    frame = renderer.surface->get_current_texture() or_return
    renderer.skip_frame = false

    switch frame.status {
    case .Success:
        // Handle suboptimal surface
        if frame.suboptimal {
            size := app.get_size()
            resize_surface(renderer, size)
        }
    case .Timeout:
        fallthrough
    case .Outdated:
        fallthrough
    case .Lost:
        // Skip this frame
        renderer.skip_frame = true

        if frame.texture.ptr != nil {
            frame.texture->release()
        }

        size := app.get_size()
        resize_surface(renderer, size)
    case .Out_Of_Memory:
        fallthrough
    case .Device_Lost:
        fmt.eprintf("Failed to acquire surface texture: %s\n", frame.status)
        return {}, .Internal
    }

    return
}

resize_surface :: proc(renderer: ^Renderer, size: app.Physical_Size) -> wgpu.Error_Type {
    if size.width == 0 && size.height == 0 {
        return .No_Error
    }

    renderer.config.width = size.width
    renderer.config.height = size.height

    renderer.surface->unconfigure()
    renderer.surface->configure(&renderer.device, &renderer.config) or_return

    return .No_Error
}
