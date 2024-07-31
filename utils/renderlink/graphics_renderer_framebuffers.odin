//+private
package application

// Vendor Package
import wgpu "./../../wrapper"

_create_framebuffer :: proc "contextless" (
	format: wgpu.Texture_Format,
	sample_count: u32 = 1,
	is_depth: bool = false,
	loc := #caller_location,
) -> (
	fb: Framebuffer,
	err: Error,
) {
	format_features := wgpu.texture_format_guaranteed_format_features(
		format,
		g_graphics.gpu.device.features,
	)

	size := _window_get_size()

	texture_descriptor := wgpu.Texture_Descriptor {
		size            = wgpu.Extent_3D{size.width, size.height, 1},
		mip_level_count = 1,
		sample_count    = sample_count,
		dimension       = .D2,
		format          = format,
		usage           = format_features.allowed_usages,
	}

	fb.texture = wgpu.device_create_texture(
		g_graphics.gpu.device,
		texture_descriptor,
		loc,
	) or_return
	fb.view = wgpu.texture_create_view(fb.texture) or_return
	fb.format = format
	fb.sample_count = sample_count
	fb.is_depth = is_depth

	return
}

_create_msaa_framebuffer :: proc "contextless" (sample_count: u32 = 1) -> (err: Error) {
	g_graphics.msaa_framebuffer = _create_framebuffer(
		g_graphics.gpu.config.format,
		sample_count,
		false,
	) or_return

	return
}

_create_depth_framebuffer :: proc "contextless" (
	depth_format: wgpu.Texture_Format,
	sample_count: u32 = 1,
) -> (
	err: Error,
) {
	g_graphics.depth_framebuffer = _create_framebuffer(depth_format, sample_count, true) or_return

	// Setup depth stencil attachment
	g_graphics.depth_stencil_attachment = wgpu.Render_Pass_Depth_Stencil_Attachment {
		view              = g_graphics.depth_framebuffer.view.ptr,
		depth_load_op     = .Clear,
		depth_store_op    = .Store,
		depth_clear_value = 1.0,
	}

	// Update render pass descriptor
	g_graphics.render_pass_desc.depth_stencil_attachment = &g_graphics.depth_stencil_attachment

	return
}

_destroy_framebuffer :: proc "contextless" (fb: Framebuffer) {
	if fb.view.ptr != nil {
		wgpu.texture_view_release(fb.view)
	}

	if fb.texture.ptr != nil {
		wgpu.texture_destroy(fb.texture)
		wgpu.texture_release(fb.texture)
	}
}

_resize_framebuffers :: proc "contextless" (new_size: Window_Size) -> (err: Error) {
	if g_graphics.settings.sample_count == 1 && !g_graphics.settings.use_depth_stencil do return

	if g_graphics.settings.sample_count > 1 {
		_destroy_framebuffer(g_graphics.msaa_framebuffer)
		_create_msaa_framebuffer(g_graphics.settings.sample_count) or_return
	}

	if g_graphics.settings.use_depth_stencil {
		_destroy_framebuffer(g_graphics.depth_framebuffer)
		_create_depth_framebuffer(
			g_graphics.settings.depth_format,
			g_graphics.settings.sample_count,
		) or_return
	}

	return
}
