package renderer

// Core
import "core:fmt"
import "core:time"

// Package
import wgpu "../../../wrapper"

// Framework
import app "../application"

GET_CURRENT_TEXTURE_MAX_ATTEMPTS :: 3
RENDERER_THROTTLE_DURATION :: 16 * time.Millisecond // 16ms roughly corresponds to 60 fps

get_current_texture_frame :: proc(
	renderer: ^Renderer,
) -> (
	out: ^wgpu.Surface_Texture,
	err: wgpu.Error,
) {
	if app.is_minimized() {
		renderer.skip_frame = true
		time.sleep(RENDERER_THROTTLE_DURATION)
		return
	}

	for attempt in 0 ..< GET_CURRENT_TEXTURE_MAX_ATTEMPTS {
		renderer.output = wgpu.surface_get_current_texture(&renderer.surface) or_return
		renderer.skip_frame = false

		switch renderer.output.status {
		case .Success:
			// Handle suboptimal surface
			if renderer.output.suboptimal {
				resize_surface(renderer, app.get_size()) or_return
				continue // Try again with the new size
			}
			return &renderer.output, nil
		case .Timeout:
			if attempt < GET_CURRENT_TEXTURE_MAX_ATTEMPTS - 1 {
				fmt.println("Timeout getting current texture. Retrying...")
				time.sleep(RENDERER_THROTTLE_DURATION)
				continue
			}
			fallthrough
		case .Outdated, .Lost:
			renderer.skip_frame = true
			resize_surface(renderer, app.get_size()) or_return
			if attempt < GET_CURRENT_TEXTURE_MAX_ATTEMPTS - 1 {
				fmt.println("Surface outdated or lost. Resized and retrying...")
				time.sleep(RENDERER_THROTTLE_DURATION)
				continue
			}
			return nil, wgpu.Error_Type.Unknown
		case .Out_Of_Memory, .Device_Lost:
			fmt.eprintf("Failed to acquire surface texture: %s\n", renderer.output.status)
			return {}, .Internal
		}
	}

	return nil, wgpu.Error_Type.Unknown
}

resize_surface :: proc(renderer: ^Renderer, size: app.Physical_Size) -> (err: wgpu.Error) {
	if !renderer.output.texture.released {
		wgpu.texture_release(&renderer.output.texture)
	}

	// Panic if width or height is zero.
	if size.width == 0 || size.height == 0 {
		return
	}

	// Wait for the device to finish all operations
	// TODO(Capati): Does this make sense here?
	wgpu.device_poll(&renderer.device, true)

	renderer.config.width = size.width
	renderer.config.height = size.height

	// Reconfigure the surface
	wgpu.surface_unconfigure(&renderer.surface)
	wgpu.surface_configure(&renderer.surface, &renderer.device, &renderer.config) or_return

	return
}
