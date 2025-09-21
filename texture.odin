package webgpu

// Core
import intr "base:intrinsics"

// Vendor
import "vendor:wgpu"

/*
Handle to a texture on the GPU.

It can be created with `DeviceCreateTexture`.

Corresponds to [WebGPU `GPUTexture`](https://gpuweb.github.io/gpuweb/#texture-interface).
*/
Texture :: wgpu.Texture

/*
Different ways that you can use a texture.
*/
TextureUsage :: wgpu.TextureUsage

/*
Different ways that you can use a texture.

The usages determine what kind of memory the texture is allocated from and what
actions the texture can partake in.

Corresponds to [WebGPU `GPUTextureUsageFlags`](
https://gpuweb.github.io/gpuweb/#typedefdef-gputextureusageflags).
*/
TextureUsages :: wgpu.TextureUsageFlags

/* No texture usages. */
TEXTURE_USAGES_NONE :: TextureUsages{}

/* Add all texture usages. */
TEXTURE_USAGES_ALL :: TextureUsages {
	.CopySrc,
	.CopyDst,
	.TextureBinding,
	.StorageBinding,
	.RenderAttachment,
}

/*
Dimensionality of a texture.

Corresponds to [WebGPU `GPUTextureDimension`](
https://gpuweb.github.io/gpuweb/#enumdef-gputexturedimension).
*/
TextureDimension :: wgpu.TextureDimension

/*
Extent of a texture related operation.

Corresponds to [WebGPU `GPUExtent3D`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuextent3ddict).
*/
Extent3D :: wgpu.Extent3D

/* Default `Extent3D` value: `{ 1, 1, 1 }` */
EXTENT3D_DEFAULT :: Extent3D{ 1, 1, 1 }

/*
Calculates the physical size backing a texture of the given  format and
extent. This includes padding to the block width and height of the format.

This is the texture extent that you must upload at when uploading to mipmaps
of compressed textures.

[physical size]:
https://gpuweb.github.io/gpuweb/#physical-miplevel-specific-texture-extent
*/
Extent3DPhysicalSize :: proc "c" (
	self: Extent3D,
	format: TextureFormat,
) -> (
	extent: Extent3D,
) {
	blockWidth, blockHeight := TextureFormatBlockDimensions(format)

	extent.width = ((self.width + blockWidth - 1) / blockWidth) * blockWidth
	extent.height = ((self.height + blockHeight - 1) / blockHeight) * blockHeight
	extent.depthOrArrayLayers = self.depthOrArrayLayers

	return
}

/*
Calculates the maximum possible count of mipmaps.

Treats the depth as part of the mipmaps. If calculating
for a 2DArray texture, which does not mipmap depth, set depth to 1.
*/
Extent3DMaxMips :: proc "c" (
	self: Extent3D,
	dimension: TextureDimension,
) -> (
	maxDim: u32,
) {
	switch dimension {
	case .Undefined: return 0
	case ._1D:       return 1
	case ._2D:       maxDim = max(self.width, self.height)
	case ._3D:       maxDim = max(self.width, max(self.height, self.depthOrArrayLayers))
	}
	return 32 - intr.count_leading_zeros(maxDim)
}

/*
Calculates the extent at a given mip level.
Does *not* account for memory size being a multiple of block size.

<https://gpuweb.github.io/gpuweb/#logical-miplevel-specific-texture-extent>
*/
Extent3DMipLevelSize :: proc "c" (
	self: Extent3D,
	level: u32,
	dimension: TextureDimension,
) -> (
	extent: Extent3D,
) {
	extent.width = max(1, self.width >> level)

	#partial switch dimension {
	case ._1D: extent.height = 1
	case:     extent.height = max(1, self.height >> level)
	}

	#partial switch dimension {
	case ._1D: extent.depthOrArrayLayers = 1
	case ._2D: extent.depthOrArrayLayers = self.depthOrArrayLayers
	case ._3D: extent.depthOrArrayLayers = max(1, self.depthOrArrayLayers >> level)
	}

	return
}

/*
Underlying texture data format.

If there is a conversion in the format (such as srgb -> linear), the conversion
listed here is for loading from texture in a shader.When writing to the texture,
the opposite conversion takes place.

Corresponds to [WebGPU `GPUTextureFormat`](
https://gpuweb.github.io/gpuweb/#enumdef-gputextureformat).
*/
TextureFormat :: wgpu.TextureFormat

/*
Kind of data the texture holds.

Corresponds to [WebGPU `GPUTextureAspect`](
https://gpuweb.github.io/gpuweb/#enumdef-gputextureaspect).
*/
TextureAspect :: wgpu.TextureAspect

/*
How edges should be handled in texture addressing.

Corresponds to [WebGPU `GPUAddressMode`](
https://gpuweb.github.io/gpuweb/#enumdef-gpuaddressmode).
*/
AddressMode :: wgpu.AddressMode

/*
Texel mixing mode when sampling between texels.

Corresponds to [WebGPU `GPUFilterMode`](
https://gpuweb.github.io/gpuweb/#enumdef-gpufiltermode).
*/
FilterMode :: wgpu.FilterMode

/*
Dimensions of a particular texture view.

Corresponds to [WebGPU `GPUTextureViewDimension`](
https://gpuweb.github.io/gpuweb/#enumdef-gputextureviewdimension).
*/
TextureViewDimension :: wgpu.TextureViewDimension

/*
Describes a `TextureView`.

For use with `TextureCreateView`.

Corresponds to [WebGPU `GPUTextureViewDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gputextureviewdescriptor).
*/
TextureViewDescriptor :: wgpu.TextureViewDescriptor

/*
Origin of a copy to/from a texture.

Corresponds to [WebGPU `GPUOrigin3D`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuorigin3ddict).
*/
Origin3D :: wgpu.Origin3D

/*
Origin of a copy from a 2D image.

Corresponds to [WebGPU `GPUOrigin2D`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuorigin2ddict).
*/
Origin2D :: struct {
	x: u32,
	y: u32,
}

/* Adds the third dimension to this origin. */
Origin2dTo3D :: proc "c" (self: Origin2D) -> Origin3D {
	return {x = self.x, y = self.y, z = 0}
}

/* Ignore the third dimension of this origin. */
Origin3dTo2D :: proc "c" (self: Origin3D) -> Origin2D {
	return {x = self.x, y = self.y}
}

/*
Describes a `Texture`.

For use with `DeviceCreateTexture`.

Corresponds to [WebGPU `GPUTextureDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gputexturedescriptor).
*/
TextureDescriptor :: struct {
	label:         string,
	usage:         TextureUsages,
	dimension:     TextureDimension,
	size:          Extent3D,
	format:        TextureFormat,
	mipLevelCount: u32,
	sampleCount:   u32,
	viewFormats:   []TextureFormat,
}

TEXTURE_DESCRIPTOR_DEFAULT :: TextureDescriptor {
	mipLevelCount = 1,
	sampleCount   = 1,
	dimension     = ._2D,
}

/*
Calculates the extent at a given mip level.

If the given mip level is larger than possible, returns None.

Treats the depth as part of the mipmaps. If calculating
for a 2DArray texture, which does not mipmap depth, set depth to 1.
*/
@(require_results)
TextureDescriptorMipLevelSize :: proc "c" (
	self: TextureDescriptor,
	level: u32,
) -> (
	extent: Extent3D,
	ok: bool,
) #optional_ok {
	if level >= self.mipLevelCount {
		return {}, false
	}
	extent = Extent3DMipLevelSize(self.size, level, self.dimension)
	return extent, true
}

/*
Computes the render extent of this texture.

<https://gpuweb.github.io/gpuweb/#abstract-opdef-compute-render-extent>
*/
@(require_results)
TextureDescriptorComputeRenderExtent :: proc "c" (
	self: TextureDescriptor,
	mipLevel: u32,
) -> Extent3D {
	return Extent3D {
		width = max(1, self.size.width >> mipLevel),
		height = max(1, self.size.height >> mipLevel),
		depthOrArrayLayers = 1,
	}
}

/*
Returns the number of array layers.

<https://gpuweb.github.io/gpuweb/#abstract-opdef-array-layer-count>
*/
@(require_results)
TextureDescriptorArrayLayerCount :: proc "c" (
	self: TextureDescriptor,
) -> (
	count: u32,
) {
	switch self.dimension {
	case .Undefined: return 0
	case ._1D, ._3D:   count = 1
	case ._2D:        count = self.size.depthOrArrayLayers
	}
	return
}

/* Returns `true` if the given `TextureDescriptor` is compatible with cube textures. */
@(require_results)
TextureDescriptorIsCubeCompatible :: proc "c" (self: TextureDescriptor) -> bool {
	return(
		self.dimension == ._2D &&
		self.size.depthOrArrayLayers % 6 == 0 &&
		self.sampleCount == 1 &&
		self.size.width == self.size.height \
	)
}

/* Creates a view of this texture. */
@(require_results)
TextureCreateView :: proc "c" (
	self: Texture,
	descriptor: Maybe(TextureViewDescriptor) = nil,
) -> (
	textureView: TextureView,
) {
	if desc, desc_ok := descriptor.?; desc_ok {
		textureView = wgpu.TextureCreateView(self, &desc)
	} else {
		textureView = wgpu.TextureCreateView(self, nil)
	}
	return
}

/* Destroy the associated native resources as soon as possible. */
TextureDestroy :: wgpu.TextureDestroy

/* Make an `TexelCopyTextureInfo` representing the whole texture with the given origin. */
@(require_results)
TextureAsImageCopy :: proc "c" (self: Texture, origin: Origin3D = {}) -> TexelCopyTextureInfo {
	return { texture = self, mipLevel = 0, origin = origin, aspect = .All }
}

/*
Returns the size of this `Texture`.

This is always equal to the `size` that was specified when creating the texture.
*/
@(require_results)
TextureGetSize :: proc "c" (self: Texture) -> Extent3D {
	return {
		width              = TextureGetWidth(self),
		height             = TextureGetHeight(self),
		depthOrArrayLayers = TextureGetDepthOrArrayLayers(self),
	}
}

/*
Returns the width of this `Texture`.

This is always equal to the `size.width` that was specified when creating the texture.
*/
TextureGetWidth :: wgpu.TextureGetWidth

/*
Returns the height of this `Texture`.

This is always equal to the `size.height` that was specified when creating the texture.
*/
TextureGetHeight :: wgpu.TextureGetHeight

/*
Returns the depth or layer count of this `Texture`.

This is always equal to the `size.depthOrArrayLayers` that was specified when
creating the texture.
*/
TextureGetDepthOrArrayLayers :: wgpu.TextureGetDepthOrArrayLayers

/*
Returns the mipLevelCount of this `Texture`.

This is always equal to the `mipLevelCount` that was specified when creating the texture.
*/
TextureGetMipLevelCount :: wgpu.TextureGetMipLevelCount

/*
Returns the sample count of this `Texture`.

This is always equal to the `sampleCount` that was specified when creating the texture.
*/
TextureGetSampleCount :: wgpu.TextureGetSampleCount

/*
Returns the dimension of this `Texture`.

This is always equal to the `dimension` that was specified when creating the texture.
*/
TextureGetDimension :: wgpu.TextureGetDimension

/*
Returns the format of this `Texture`.

This is always equal to the `format` that was specified when creating the texture.
*/
TextureGetFormat :: wgpu.TextureGetFormat

/*
Returns the allowed usages of this `Texture`.

This is always equal to the `usage` that was specified when creating the texture.
*/
TextureGetUsage :: wgpu.TextureGetUsage

/*
Returns a descriptor for this `Texture`.

This is always equal to the values that was specified when creating the texture.
*/
TextureGetDescriptor :: proc "c" (self: Texture) -> (desc: TextureDescriptor) {
	desc.usage         = TextureGetUsage(self)
	desc.dimension     = TextureGetDimension(self)
	desc.size          = TextureGetSize(self)
	desc.format        = TextureGetFormat(self)
	desc.mipLevelCount = TextureGetMipLevelCount(self)
	desc.sampleCount   = TextureGetSampleCount(self)
	return
}

/* Set a debug label for the given `Texture`. */
TextureSetLabel :: wgpu.TextureSetLabel

/* Increase the `Texture` reference count. */
TextureAddRef :: wgpu.TextureAddRef

/* Release the `Texture` resources, use to decrease the reference count. */
TextureRelease :: wgpu.TextureRelease

/*
Safely releases the `Texture` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
TextureReleaseSafe :: proc "c" (self: ^Texture) {
	if self != nil && self^ != nil {
		wgpu.TextureRelease(self^)
		self^ = nil
	}
}
