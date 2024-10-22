#+private
package renderlink

// Local packages
import wgpu "./../../wrapper"

_create_framebuffer :: proc "contextless" (
	format: wgpu.Texture_Format,
	sample_count: u32 = 1,
	is_depth: bool = false,
	loc := #caller_location,
) -> (
	fb: Framebuffer,
	ok: bool,
) {
	r := &g_app.renderer

	format_features := wgpu.texture_format_guaranteed_format_features(format, r.gpu.features)

	size := _window_get_size()

	texture_descriptor := wgpu.Texture_Descriptor {
		size            = wgpu.Extent_3D{size.width, size.height, 1},
		mip_level_count = 1,
		sample_count    = sample_count,
		dimension       = .D2,
		format          = format,
		usage           = format_features.allowed_usages,
	}

	fb.texture = wgpu.device_create_texture(r.gpu.device, texture_descriptor, loc) or_return

	fb.view = wgpu.texture_create_view(fb.texture) or_return
	fb.format = format
	fb.sample_count = sample_count
	fb.is_depth = is_depth

	return fb, true
}

_create_msaa_framebuffer :: proc "contextless" (sample_count: u32 = 1) -> (ok: bool) {
	r := &g_app.renderer

	r.msaa_framebuffer = _create_framebuffer(r.gpu.config.format, sample_count, false) or_return

	return true
}

_create_depth_framebuffer :: proc "contextless" (
	depth_format: wgpu.Texture_Format,
	sample_count: u32 = 1,
) -> (
	ok: bool,
) {
	r := &g_app.renderer

	r.depth_framebuffer = _create_framebuffer(depth_format, sample_count, true) or_return

	// Setup depth stencil attachment
	r.depth_stencil_attachment = wgpu.Render_Pass_Depth_Stencil_Attachment {
		view              = r.depth_framebuffer.view,
		depth_load_op     = .Clear,
		depth_store_op    = .Store,
		depth_clear_value = 1.0,
	}

	// Update render pass descriptor
	r.render_pass_desc.depth_stencil_attachment = &r.depth_stencil_attachment

	return true
}

_destroy_framebuffer :: proc "contextless" (fb: Framebuffer) {
	if fb.view != nil {
		wgpu.texture_view_release(fb.view)
	}

	if fb.texture != nil {
		wgpu.texture_destroy(fb.texture)
		wgpu.texture_release(fb.texture)
	}
}

_resize_framebuffers :: proc "contextless" (new_size: Window_Size) -> (ok: bool) {
	r := &g_app.renderer

	if r.settings.sample_count == 1 && !r.settings.use_depth_stencil {
		return true /* No framebuffer to resize */
	}

	if r.settings.sample_count > 1 {
		_destroy_framebuffer(r.msaa_framebuffer)
		_create_msaa_framebuffer(r.settings.sample_count) or_return
	}

	if r.settings.use_depth_stencil {
		_destroy_framebuffer(r.depth_framebuffer)
		_create_depth_framebuffer(
			r.settings.depth_format,
			r.settings.sample_count,
		) or_return
	}

	return true
}
