package wgpu

// Package
import wgpu "../bindings"

// Backends are set to `Primary`, and `FXC` is chosen as the `dx12_shader_compiler`.
DEFAULT_INSTANCE_DESCRIPTOR :: Instance_Descriptor {
	backends             = wgpu.Instance_Backend_Primary,
	dx12_shader_compiler = DEFAULT_DX12_COMPILER,
}

DEFAULT_DX12_COMPILER :: Dx12_Compiler.Fxc

// High_Performance.
DEFAULT_POWER_PREFERENCE: Power_Preference = .High_Performance

// Default `count = 1` and mask all pixels `0xFFFFFFFF`.
DEFAULT_MULTISAMPLE_STATE :: Multisample_State {
	next_in_chain             = nil,
	count                     = 1,
	mask                      = ~u32(0), // 0xFFFFFFFF
	alpha_to_coverage_enabled = b32(false),
}

DEFAULT_SAMPLER_DESCRIPTOR :: Sampler_Descriptor {
	label          = nil,
	address_mode_u = .Clamp_To_Edge,
	address_mode_v = .Clamp_To_Edge,
	address_mode_w = .Clamp_To_Edge,
	mag_filter     = .Nearest,
	min_filter     = .Nearest,
	mipmap_filter  = .Nearest,
	lod_min_clamp  = 0.0,
	lod_max_clamp  = 32.0,
	compare        = .Undefined,
	max_anisotropy = 1,
}

DEFAULT_DEPTH_STENCIL_STATE :: Depth_Stencil_State {
	stencil_front = {compare = .Always},
	stencil_back = {compare = .Always},
	stencil_read_mask = ~u32(0),
	stencil_write_mask = ~u32(0),
}

DEFAULT_TEXTURE_DESCRIPTOR :: Texture_Descriptor {
	mip_level_count = 1,
	sample_count    = 1,
	dimension       = .D2,
}

DEFAULT_PRIMITIVE_STATE :: Primitive_State {
	topology   = .Triangle_List,
	front_face = .CCW,
	cull_mode  = .None,
}

DEFAULT_RENDER_PIPELINE_DESCRIPTOR: Render_Pipeline_Descriptor : {
	primitive = DEFAULT_PRIMITIVE_STATE,
	depth_stencil = nil,
	multisample = DEFAULT_MULTISAMPLE_STATE,
}
