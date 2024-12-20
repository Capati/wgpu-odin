package wgpu

// Default `count = 1` and mask all pixels `0xFFFFFFFF`.
DEFAULT_MULTISAMPLE_STATE :: MultisampleState {
	next_in_chain             = nil,
	count                     = 1,
	mask                      = max(u32), // 0xFFFFFFFF
	alpha_to_coverage_enabled = b32(false),
}

DEFAULT_DEPTH_STENCIL_STATE :: DepthStencilState {
	stencil_front = {compare = .Always},
	stencil_back = {compare = .Always},
	stencil_read_mask = max(u32),
	stencil_write_mask = max(u32),
}

DEFAULT_TEXTURE_DESCRIPTOR :: TextureDescriptor {
	mip_level_count = 1,
	sample_count    = 1,
	dimension       = .D2,
}

DEFAULT_PRIMITIVE_STATE :: PrimitiveState {
	topology   = .TriangleList,
	front_face = .CCW,
	cull_mode  = .None,
}

DEFAULT_RENDER_PIPELINE_DESCRIPTOR: RenderPipelineDescriptor : {
	primitive = DEFAULT_PRIMITIVE_STATE,
	depth_stencil = nil,
	multisample = DEFAULT_MULTISAMPLE_STATE,
}
