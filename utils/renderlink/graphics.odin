package application

// Vendor Package
import wgpu "./../../wrapper"

Graphics_Error :: enum {
	None,
	Unsupported_Color_Attachments,
	Unsupported_Depth_Format,
	Unsupported_Sample_Count,
}

graphics_clear_wgpu_color :: proc "contextless" (color: wgpu.Color) #no_bounds_check {
	if g_graphics.gpu.is_srgb {
		g_graphics.clear_color = wgpu.color_srgb_to_linear(color)
	} else do g_graphics.clear_color = color
	g_graphics.render_pass_desc.color_attachments[0].clear_value = g_graphics.clear_color
}

graphics_clear_color :: proc "contextless" (color: Color) {
	graphics_clear_wgpu_color({color.r, color.g, color.b, color.a})
}

// Clears the screen to the specified color.
graphics_clear :: proc {
	graphics_clear_wgpu_color,
	graphics_clear_color,
}

graphics_is_srgb :: proc() -> bool {
	return g_graphics.gpu.is_srgb
}
