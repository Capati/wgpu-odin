package renderlink

// Local packages
import wgpu "./../../wrapper"

/* Clears the screen to the specified color. */
graphics_clear :: proc "contextless" (color: Color) #no_bounds_check {
	r := &g_app.renderer

	if r.gpu.is_srgb {
		r.clear_color = wgpu.color_srgb_to_linear(color)
	} else do r.clear_color = color

	r.render_pass_desc.color_attachments[0].clear_value = r.clear_color
}

graphics_is_srgb :: proc() -> bool {
	return g_app.renderer.gpu.is_srgb
}
