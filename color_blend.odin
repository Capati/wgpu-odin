package webgpu

// Vendor
import "vendor:wgpu"

/*
Describes a blend component of a `BlendState`.

Corresponds to [WebGPU `GPUBlendComponent`](
https://gpuweb.github.io/gpuweb/#dictdef-gpublendcomponent).
*/
BlendComponent :: wgpu.BlendComponent

/* Standard blending state that blends source and destination based on source alpha. */
BLEND_COMPONENT_NORMAL :: BlendComponent {
	operation = .Add,
	srcFactor = .SrcAlpha,
	dstFactor = .OneMinusSrcAlpha,
}

// Default blending state that replaces destination with the source.
BLEND_COMPONENT_REPLACE :: BlendComponent {
	operation = .Add,
	srcFactor = .One,
	dstFactor = .Zero,
}

// Blend state of (1 * src) + ((1 - src_alpha) * dst)
BLEND_COMPONENT_OVER :: BlendComponent {
	operation = .Add,
	srcFactor = .One,
	dstFactor = .OneMinusSrcAlpha,
}

BLEND_COMPONENT_DEFAULT :: BLEND_COMPONENT_REPLACE

/*
Returns `true` if the state relies on the constant color, which is set
independently on a render command encoder.
*/
BlendComponentUsesConstant :: proc "c" (self: BlendComponent) -> bool {
	return(
		self.srcFactor == .Constant ||
		self.srcFactor == .OneMinusConstant ||
		self.dstFactor == .Constant ||
		self.dstFactor == .OneMinusConstant \
	)
}

/*
Describe the blend state of a render pipeline,
within `Color_Target_State`.

Corresponds to [WebGPU `GPUBlendState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpublendstate).
*/
BlendState :: wgpu.BlendState

/* Uses alpha blending for both color and alpha channels. */
@(rodata)
BLEND_STATE_NORMAL := BlendState {
	color = BLEND_COMPONENT_NORMAL,
	alpha = BLEND_COMPONENT_NORMAL,
}

/* Does no color blending, just overwrites the output with the contents of the shader. */
@(rodata)
BLEND_STATE_REPLACE := BlendState {
	color = BLEND_COMPONENT_REPLACE,
	alpha = BLEND_COMPONENT_REPLACE,
}

/* Does standard alpha blending with non-premultiplied alpha. */
@(rodata)
BLEND_STATE_ALPHA_BLENDING := BlendState {
	color = BLEND_COMPONENT_NORMAL,
	alpha = BLEND_COMPONENT_OVER,
}

/* Does standard alpha blending with premultiplied alpha. */
@(rodata)
BLEND_STATE_PREMULTIPLIED_ALPHA_BLENDING := BlendState {
	color = BLEND_COMPONENT_OVER,
	alpha = BLEND_COMPONENT_OVER,
}
