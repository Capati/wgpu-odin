package renderer

// Base
import "base:runtime"

// Core
import "core:fmt"
import "core:time"

// Package
import wgpu "../../../wrapper"

// Framework
import app "../application"

when !ODIN_DEBUG {
	_ :: runtime
	_ :: fmt
}

GET_CURRENT_TEXTURE_MAX_ATTEMPTS :: 3
RENDERER_THROTTLE_DURATION :: 16 * time.Millisecond // 16ms roughly corresponds to 60 fps

get_current_texture_frame :: proc "contextless" (
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
		renderer.output = wgpu.surface_get_current_texture(renderer.surface) or_return
		renderer.released = false
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
				when ODIN_DEBUG {
					context = runtime.default_context()
					fmt.println("Timeout getting current texture. Retrying...")
				}
				time.sleep(RENDERER_THROTTLE_DURATION)
				continue
			}
			fallthrough
		case .Outdated, .Lost:
			renderer.skip_frame = true
			resize_surface(renderer, app.get_size()) or_return
			if attempt < GET_CURRENT_TEXTURE_MAX_ATTEMPTS - 1 {
				when ODIN_DEBUG {
					context = runtime.default_context()
					fmt.println("Surface outdated or lost. Resized and retrying...")
				}
				time.sleep(RENDERER_THROTTLE_DURATION)
				continue
			}
			return nil, renderer.output.status
		case .Out_Of_Memory, .Device_Lost:
			when ODIN_DEBUG {
				context = runtime.default_context()
				fmt.eprintf("Failed to acquire surface texture: %s\n", renderer.output.status)
			}
			return nil, renderer.output.status
		}
	}

	return nil, wgpu.Error_Type.Unknown
}

release_current_texture_frame :: proc "contextless" (using self: ^Renderer) {
	if !released && output.texture.ptr != nil {
		wgpu.texture_release(output.texture)
		released = true
	}
}

resize_surface :: proc "contextless" (
	using self: ^Renderer,
	size: app.Physical_Size,
) -> (
	err: wgpu.Error,
) {
	release_current_texture_frame(self)

	// Panic if width or height is zero.
	if size.width == 0 || size.height == 0 {
		skip_frame = true
		time.sleep(RENDERER_THROTTLE_DURATION)
		return
	}

	// Wait for the device to finish all operations
	// TODO(Capati): Does this make sense here?
	wgpu.device_poll(device, true)

	config.width = size.width
	config.height = size.height

	// Reconfigure the surface
	wgpu.surface_unconfigure(surface)
	wgpu.surface_configure(&surface, device, config) or_return

	return
}
