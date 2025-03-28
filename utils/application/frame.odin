package application

// Packages
import "core:log"
import "core:time"

// Local packages
import "./../../wgpu"

Frame_Texture :: struct {
	using _texture:   wgpu.Surface_Texture,
	skip:             bool,
	view:             wgpu.Texture_View,
	texture_released: bool,
	view_released:    bool,
}

THROTTLE_DURATION :: 16 * time.Millisecond // 16ms roughly corresponds to 60 fps
GET_CURRENT_TEXTURE_MAX_ATTEMPTS :: 3
RENDERER_THROTTLE_DURATION :: THROTTLE_DURATION

get_current_frame :: proc(app: ^Application) -> (ok: bool) {
	release_current_frame(app)

	loop: for attempt in 0 ..< GET_CURRENT_TEXTURE_MAX_ATTEMPTS {
		app.frame._texture = wgpu.surface_get_current_texture(app.gpu.surface) or_return
		app.frame.texture_released = false
		app.frame.skip = false

		switch app.frame.status {
		case .Success_Optimal:
			app.frame.view = wgpu.texture_create_view(app.frame.texture) or_return
			app.frame.view_released = false
			return true
		case .Success_Suboptimal:
			resize_surface(app, get_framebuffer_size(app)) or_return
			continue // Try again with the new size
		case .Timeout:
			if attempt < GET_CURRENT_TEXTURE_MAX_ATTEMPTS - 1 {
				log.warn("[\x1b[33mTimeout\x1b[0m] getting current texture. Retrying...")
				time.sleep(RENDERER_THROTTLE_DURATION)
				continue
			}
			break loop
		case .Outdated, .Lost:
			app.frame.skip = true
			resize_surface(app, get_framebuffer_size(app)) or_return
			if attempt < GET_CURRENT_TEXTURE_MAX_ATTEMPTS - 1 {
				log.warnf("Surface \x1b[33m%v\x1b[0m. Resized and retrying...", app.frame.status)
				time.sleep(RENDERER_THROTTLE_DURATION)
				continue
			}
			break loop
		case .Out_Of_Memory, .Device_Lost, .Error:
			break loop
		}
	}

	log.fatalf("Failed to acquire surface texture: \x1b[31m%v\x1b[0m\n", app.frame.status)
	return
}

resize_surface :: proc(app: ^Application, size: Window_Size) -> (ok: bool) {
	release_current_frame(app)

	// Panic if width or height is zero.
	if size.w == 0 || size.h == 0 {
		log.errorf("Invalid surface size: \x1b[31m%v\x1b[0m", size)
		app.frame.skip = true
		time.sleep(RENDERER_THROTTLE_DURATION)
		return true
	}

	// Wait for the device to finish all operations
	wgpu.device_poll(app.gpu.device, true) or_return

	app.gpu.config.width = u32(size.w)
	app.gpu.config.height = u32(size.h)

	// Reconfigure the surface
	wgpu.surface_unconfigure(app.gpu.surface)
	wgpu.surface_configure(app.gpu.surface, app.gpu.config) or_return

	set_aspect(app, size)

	return true
}

release_current_frame :: proc "contextless" (app: ^Application) {
	if !app.frame.view_released && app.frame.view != nil {
		wgpu.texture_view_release(app.frame.view)
		app.frame.view_released = true
	}

	if !app.frame.texture_released && app.frame.texture != nil {
		wgpu.texture_release(app.frame.texture)
		app.frame.texture_released = true
	}
}
