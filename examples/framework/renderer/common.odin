package renderer

// Core
import "core:fmt"

// Package
import wgpu "../../../wrapper"

// Framework
import app "../application"

GET_CURRENT_TEXTURE_MAX_ATTEMPTS :: 3

get_current_texture_frame :: proc(
	renderer: ^Renderer,
) -> (
	frame: wgpu.Surface_Texture,
	err: wgpu.Error,
) {
	for attempt in 0 ..< GET_CURRENT_TEXTURE_MAX_ATTEMPTS {
		frame = wgpu.surface_get_current_texture(&renderer.surface) or_return
		renderer.skip_frame = false

		switch frame.status {
		case .Success:
			// Handle suboptimal surface
			if frame.suboptimal {
				size := app.get_size()
				resize_surface(renderer, size)
				continue // Try again with the new size
			}
			return
		case .Timeout:
			if attempt < GET_CURRENT_TEXTURE_MAX_ATTEMPTS - 1 {
				fmt.printf("Timeout getting current texture. Retrying...\n")
				continue
			}
			fallthrough
		case .Outdated, .Lost:
			// Skip this frame
			renderer.skip_frame = true
			if frame.texture.ptr != nil {
				wgpu.texture_release(&frame.texture)
			}
			size := app.get_size()
			resize_surface(renderer, size) or_return
			if attempt < GET_CURRENT_TEXTURE_MAX_ATTEMPTS - 1 {
				fmt.printf("Surface outdated or lost. Resized and retrying...\n")
				continue
			}
			return
		case .Out_Of_Memory, .Device_Lost:
			fmt.eprintf("Failed to acquire surface texture: %s\n", frame.status)
			return {}, .Internal
		}
	}

	return
}

resize_surface :: proc(renderer: ^Renderer, size: app.Physical_Size) -> (err: wgpu.Error) {
	if size.width == 0 && size.height == 0 {
		return
	}

	// Wait for the device to finish all operations
	wgpu.device_poll(&renderer.device, true)

	renderer.config.width = size.width
	renderer.config.height = size.height

	// Reconfigure the surface
	wgpu.surface_unconfigure(&renderer.surface)
	wgpu.surface_configure(&renderer.surface, &renderer.device, &renderer.config) or_return

	return
}
