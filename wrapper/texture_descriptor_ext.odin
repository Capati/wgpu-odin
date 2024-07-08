package wgpu

texture_descriptor_is_cube_compatible :: proc(self: Texture_Descriptor) -> bool {
	return(
		self.dimension == .D2 &&
		self.size.depth_or_array_layers % 6 == 0 &&
		self.sample_count == 1 &&
		self.size.width == self.size.height \
	)
}

texture_descriptor_array_layer_count :: proc(self: Texture_Descriptor) -> (count: u32) {
	switch self.dimension {
	case .D1, .D3:
		count = 1
	case .D2:
		count = self.size.depth_or_array_layers
	}
	return
}

texture_descriptor_mip_level_size :: proc(
	self: Texture_Descriptor,
	level: u32,
) -> (
	extent: Extent_3D,
	ok: bool,
) #optional_ok {
	if level >= self.mip_level_count do return {}, false
	extent = extent_3d_mip_level_size(self.size, level, self.dimension)
	return extent, true
}
