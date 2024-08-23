package wgpu

// STD Library
import intr "base:intrinsics"

/*
Calculates the [physical size] backing a texture of the given  format and extent.  This
includes padding to the block width and height of the format.

This is the texture extent that you must upload at when uploading to _mipmaps_ of compressed
textures.

[physical size]: https://gpuweb.github.io/gpuweb/#physical-miplevel-specific-texture-extent
*/
extent_3d_physical_size :: proc "contextless" (
	self: Extent_3D,
	format: Texture_Format,
) -> (
	extent: Extent_3D,
) {
	block_width, block_height := texture_format_block_dimensions(format)

	extent.width = ((self.width + block_width - 1) / block_width) * block_width
	extent.height = ((self.height + block_height - 1) / block_height) * block_height
	extent.depth_or_array_layers = self.depth_or_array_layers

	return
}

/*
Calculates the maximum possible count of mipmaps.

Treats the depth as part of the mipmaps. If calculating
for a 2DArray texture, which does not mipmap depth, set depth to 1.
*/
extent_3d_max_mips :: proc "contextless" (
	self: Extent_3D,
	dimension: Texture_Dimension,
) -> (
	max_dim: u32,
) {
	switch dimension {
	case .D1:
		return 1
	case .D2:
		max_dim = max(self.width, self.height)
	case .D3:
		max_dim = max(self.width, max(self.height, self.depth_or_array_layers))
	}
	return 32 - intr.count_leading_zeros(max_dim)
}

/*
Calculates the extent at a given mip level.
Does *not* account for memory size being a multiple of block size.

<https://gpuweb.github.io/gpuweb/#logical-miplevel-specific-texture-extent>
*/
extent_3d_mip_level_size :: proc "contextless" (
	self: Extent_3D,
	level: u32,
	dimension: Texture_Dimension,
) -> (
	extent: Extent_3D,
) {
	extent.width = max(1, self.width >> level)

	#partial switch dimension {
	case .D1:
		extent.height = 1
	case:
		extent.height = max(1, self.height >> level)
	}

	#partial switch dimension {
	case .D1:
		extent.depth_or_array_layers = 1
	case .D2:
		extent.depth_or_array_layers = self.depth_or_array_layers
	case .D3:
		extent.depth_or_array_layers = max(1, self.depth_or_array_layers >> level)
	}

	return
}
