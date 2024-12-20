package wgpu

/* Standard blending state that blends source and destination based on source alpha. */
BLEND_COMPONENT_NORMAL :: BlendComponent {
	operation  = .Add,
	src_factor = .SrcAlpha,
	dst_factor = .OneMinusSrcAlpha,
}

// Default blending state that replaces destination with the source.
BLEND_COMPONENT_REPLACE :: BlendComponent {
	operation  = .Add,
	src_factor = .One,
	dst_factor = .Zero,
}

// Blend state of (1 * src) + ((1 - src_alpha) * dst)
BLEND_COMPONENT_OVER :: BlendComponent {
	operation  = .Add,
	src_factor = .One,
	dst_factor = .OneMinusSrcAlpha,
}

Default_Blend_Component :: BLEND_COMPONENT_REPLACE

/* Blend mode that uses alpha blending for both color and alpha channels. */
@(rodata)
BLEND_STATE_NORMAL := BlendState {
	color = BLEND_COMPONENT_NORMAL,
	alpha = BLEND_COMPONENT_NORMAL,
}

/*
Blend mode that does no color blending, just overwrites the output with the contents
of the shader.
*/
@(rodata)
BLEND_STATE_REPLACE := BlendState {
	color = BLEND_COMPONENT_REPLACE,
	alpha = BLEND_COMPONENT_REPLACE,
}

/* Blend mode that does standard alpha blending with non-premultiplied alpha. */
@(rodata)
BLEND_STATE_ALPHA_BLENDING := BlendState {
	color = BLEND_COMPONENT_NORMAL,
	alpha = BLEND_COMPONENT_OVER,
}

/* Blend mode that does standard alpha blending with premultiplied alpha. */
@(rodata)
BLEND_STATE_PREMULTIPLIED_ALPHA_BLENDING := BlendState {
	color = BLEND_COMPONENT_OVER,
	alpha = BLEND_COMPONENT_OVER,
}

/*
Returns `true` if the state relies on the constant color, which is
set independently on a render command encoder.
*/
blend_component_uses_constant :: proc "contextless" (self: BlendComponent) -> bool {
	return(
		self.src_factor == .Constant ||
		self.src_factor == .OneMinusConstant ||
		self.dst_factor == .Constant ||
		self.dst_factor == .OneMinusConstant \
	)
}
