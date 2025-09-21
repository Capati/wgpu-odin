package webgpu

/* Represents various usage features for a texture. */
TextureUsageFeature :: enum Flags {
	Filterable,
	MultisampleX2,
	MultisampleX4,
	MultisampleX8,
	MultisampleX16,
	MultisampleResolve,
	StorageReadOnly,
	StorageWriteOnly,
	StorageReadWrite,
	Blendable,
}

/* Feature flags for a texture format. */
TextureFormatFeatureFlags :: bit_set[TextureUsageFeature;Flags]

/* Checks if the given texture format supports the specified sample count. */
TextureFormatFeatureFlagsSampleCountSupported :: proc "contextless" (
	self: TextureFormatFeatureFlags,
	count: u32,
) -> bool {
	switch count {
	case 1 : return true
	case 2 : return .MultisampleX2 in self
	case 4 : return .MultisampleX4 in self
	case 8 : return .MultisampleX8 in self
	case 16: return .MultisampleX16 in self
	}
	return false
}

/* Checks if the given texture format supports the specified sample count. */
SampleCountSupported :: TextureFormatFeatureFlagsSampleCountSupported

TextureFormatFeatureFlagsSupportedSampleCounts :: proc "contextless" (
	self: TextureFormatFeatureFlags,
) -> (
	flags: MultisampleFlags,
) {
	if .MultisampleX2 in self { flags += {.X2} }
	if .MultisampleX4 in self { flags += {.X4} }
	if .MultisampleX8 in self { flags += {.X8} }
	if .MultisampleX16 in self { flags += {.X16} }
	return flags
}

SupportedSampleCounts :: TextureFormatFeatureFlagsSupportedSampleCounts

/* Features supported by a given texture format */
TextureFormatFeatures :: struct {
	allowedUsages: TextureUsages,
	flags:         TextureFormatFeatureFlags,
}

/* ASTC block dimensions */
ASTCBlock :: enum i32 {
	B4x4,
	B5x4,
	B5x5,
	B6x5,
	B6x6,
	B8x5,
	B8x6,
	B8x8,
	B10x5,
	B10x6,
	B10x8,
	B10x10,
	B12x10,
	B12x12,
}

/* ASTC RGBA channel */
ASTCChannel :: enum i32 {
	Unorm,
	UnormSrgb,
	Hdr,
}

/*
Returns the aspect-specific format of the original format

see <https://gpuweb.github.io/gpuweb/#abstract-opdef-resolving-gputextureaspect>
*/
TextureFormatAspectSpecificFormat :: proc "contextless" (
	self: TextureFormat,
	aspect: TextureAspect,
) -> Maybe(TextureFormat) {
	#partial switch self {
	case .Stencil8:
		if aspect == .StencilOnly {
			return self
		}
	case .Depth16Unorm, .Depth24Plus, .Depth32Float:
		if aspect == .DepthOnly {
			return self
		}
	case .Depth24PlusStencil8:
		#partial switch aspect {
		case .StencilOnly:
			return .Stencil8
		case .DepthOnly:
			return .Depth24Plus
		}
	case .Depth32FloatStencil8:
		#partial switch aspect {
		case .StencilOnly:
			return .Stencil8
		case .DepthOnly:
			return .Depth32Float
		}
	case .NV12:
		// #partial switch aspect {
		// case .Plane0:
		// 	return .R8Unorm
		// case .Plane1:
		// 	return .RG8Unorm
		// }
	}

	// Views to multi-planar formats must specify the plane
	if aspect == .All && !TextureFormatIsMultiPlanarFormat(self) {
		return self
	}

	return .Undefined
}

/*
Check if the format is a depth or stencil component of the given combined
depth-stencil format.
*/
TextureFormatIsDepthStencilComponent :: proc "contextless" (
	self, combinedFormat: TextureFormat,
) -> bool {
	return(
		combinedFormat == .Depth24PlusStencil8 &&
			(self == .Depth24Plus || self == .Stencil8) ||
		combinedFormat == .Depth32FloatStencil8 &&
			(self == .Depth32Float || self == .Stencil8) \
	)
}

/*
Check if the format is a depth and/or stencil format.

see <https://gpuweb.github.io/gpuweb/#depth-formats>
*/
TextureFormatIsDepthStencilFormat :: proc "contextless" (self: TextureFormat) -> bool {
	#partial switch self {
	case .Stencil8,
	     .Depth16Unorm,
	     .Depth24Plus,
	     .Depth24PlusStencil8,
	     .Depth32Float,
	     .Depth32FloatStencil8:
		return true
	}
	return false
}

/*
Returns `true` if the format is a combined depth-stencil format

see <https://gpuweb.github.io/gpuweb/#combined-depth-stencil-format>
*/
TextureFormatIsCombinedDepthStencilFormat :: proc "contextless" (
	self: TextureFormat,
) -> bool {
	#partial switch self {
	case .Depth24PlusStencil8, .Depth32FloatStencil8:
		return true
	}
	return false
}


/* Returns `true` if the format is a multi-planar format.*/
TextureFormatIsMultiPlanarFormat :: proc "contextless" (self: TextureFormat) -> bool {
	return TextureFormatPlanes(self) > 1
}

/* Returns the number of planes a multi-planar format has.*/
TextureFormatPlanes :: proc "contextless" (self: TextureFormat) -> u32 {
	#partial switch self {
	case .NV12:
		return 2
	}
	return 0
}

/* Returns `true` if the format has a color aspect.*/
TextureFormatHasColorAspect :: proc "contextless" (self: TextureFormat) -> bool {
	return !TextureFormatIsDepthStencilFormat(self)
}

/* Returns `true` if the format has a depth aspect.*/
TextureFormatHasDepthAspect :: proc "contextless" (self: TextureFormat) -> bool {
	#partial switch self {
	case .Depth16Unorm,
	     .Depth24Plus,
	     .Depth24PlusStencil8,
	     .Depth32Float,
	     .Depth32FloatStencil8:
		return true
	}
	return false
}

/* Returns `true` if the format has a stencil aspect.*/
TextureFormatHasStencilAspect :: proc "contextless" (self: TextureFormat) -> bool {
	#partial switch self {
	case .Stencil8, .Depth24PlusStencil8, .Depth32FloatStencil8:
		return true
	}
	return false
}

/* Returns the size multiple requirement for a texture using this format.*/
TextureFormatSizeMultipleRequirement :: proc "contextless" (self: TextureFormat) -> (u32, u32) {
	#partial switch self {
	case .NV12:
		return 2, 2
	}
	return TextureFormatBlockDimensions(self)
}

/*
Returns the dimension of a [block](https://gpuweb.github.io/gpuweb/#texel-block) of texels.

Uncompressed formats have a block dimension of `(1, 1)`.
*/
TextureFormatBlockDimensions :: proc "contextless" (self: TextureFormat) -> (w, h: u32) {
	switch self {
	case .R8Unorm, .R8Snorm, .R8Uint, .R8Sint, .R16Uint, .R16Sint, .R16Unorm, .R16Snorm,
		 .R16Float, .RG8Unorm, .RG8Snorm, .RG8Uint, .RG8Sint, .R32Uint, .R32Sint,
		 .R32Float, .RG16Uint, .RG16Sint, .Rg16Unorm, .Rg16Snorm, .RG16Float, .RGBA8Unorm,
		 .RGBA8UnormSrgb, .RGBA8Snorm, .RGBA8Uint, .RGBA8Sint, .BGRA8Unorm,
		 .BGRA8UnormSrgb, .RGB9E5Ufloat, .RGB10A2Uint, .RGB10A2Unorm, .RG11B10Ufloat,
		 .RG32Uint, .RG32Sint, .RG32Float, .RGBA16Uint, .RGBA16Sint, .Rgba16Unorm,
		 .Rgba16Snorm, .RGBA16Float, .RGBA32Uint, .RGBA32Sint, .RGBA32Float, .Stencil8,
		 .Depth16Unorm, .Depth24Plus, .Depth24PlusStencil8, .Depth32Float,
		 .Depth32FloatStencil8, .NV12:
		return 1, 1

	case .BC1RGBAUnorm, .BC1RGBAUnormSrgb, .BC2RGBAUnorm, .BC2RGBAUnormSrgb,
		 .BC3RGBAUnorm, .BC3RGBAUnormSrgb, .BC4RUnorm, .BC4RSnorm, .BC5RGUnorm,
		 .BC5RGSnorm, .BC6HRGBUfloat, .BC6HRGBFloat, .BC7RGBAUnorm, .BC7RGBAUnormSrgb,
		 .ETC2RGB8Unorm, .ETC2RGB8UnormSrgb, .ETC2RGB8A1Unorm, .ETC2RGB8A1UnormSrgb,
		 .ETC2RGBA8Unorm, .ETC2RGBA8UnormSrgb, .EACR11Unorm, .EACR11Snorm,
		 .EACRG11Unorm, .EACRG11Snorm:
		return 4, 4

	case .ASTC4x4Unorm, .ASTC4x4UnormSrgb: return 4, 4
	case .ASTC5x4Unorm, .ASTC5x4UnormSrgb: return 5, 5
	case .ASTC5x5Unorm, .ASTC5x5UnormSrgb: return 5, 5
	case .ASTC6x5Unorm, .ASTC6x5UnormSrgb: return 6, 5
	case .ASTC6x6Unorm, .ASTC6x6UnormSrgb: return 6, 6
	case .ASTC8x5Unorm, .ASTC8x5UnormSrgb: return 8, 5
	case .ASTC8x6Unorm, .ASTC8x6UnormSrgb: return 8, 6
	case .ASTC8x8Unorm, .ASTC8x8UnormSrgb: return 8, 8
	case .ASTC10x5Unorm, .ASTC10x5UnormSrgb: return 10, 5
	case .ASTC10x6Unorm, .ASTC10x6UnormSrgb: return 10, 6
	case .ASTC10x8Unorm, .ASTC10x8UnormSrgb: return 10, 8
	case .ASTC10x10Unorm, .ASTC10x10UnormSrgb: return 10, 10
	case .ASTC12x10Unorm, .ASTC12x10UnormSrgb: return 12, 10
	case .ASTC12x12Unorm, .ASTC12x12UnormSrgb: return 12, 12

	case .Undefined:
		return 1, 1
	}

	return 1, 1
}

/* Returns `true` for compressed formats.*/
TextureFormatIsCompressed :: proc "contextless" (self: TextureFormat) -> bool {
	w, h := TextureFormatBlockDimensions(self)
	return w != 1 && h != 1
}

/* Returns `true` for BCn compressed formats.*/
TextureFormatIsBcn :: proc "contextless" (self: TextureFormat) -> bool {
	features := TextureFormatRequiredFeatures(self)
	return .TextureCompressionBC in features
}

/* Returns the required features (if any) in order to use the texture.*/
TextureFormatRequiredFeatures :: proc "contextless" (self: TextureFormat) -> Features {
	switch self {
	case .R8Unorm, .R8Snorm, .R8Uint, .R8Sint, .R16Uint, .R16Sint, .R16Float, .RG8Unorm,
		 .RG8Snorm, .RG8Uint, .RG8Sint, .R32Float, .R32Uint, .R32Sint, .RG16Uint, .RG16Sint,
		 .RG16Float, .RGBA8Unorm, .RGBA8UnormSrgb, .RGBA8Snorm, .RGBA8Uint, .RGBA8Sint,
		 .BGRA8Unorm, .BGRA8UnormSrgb, .RGB10A2Uint, .RGB10A2Unorm, .RG11B10Ufloat,
		 .RGB9E5Ufloat, .RG32Float, .RG32Uint, .RG32Sint, .RGBA16Uint, .RGBA16Sint,
		 .RGBA16Float, .RGBA32Float, .RGBA32Uint, .RGBA32Sint, .Stencil8, .Depth16Unorm,
		 .Depth24Plus, .Depth24PlusStencil8, .Depth32Float:
		return {} // empty, no features need

	case .Depth32FloatStencil8:
		return {.Depth32FloatStencil8}

	case .NV12:
		return { .TextureFormatNv12 }

	case .R16Unorm, .R16Snorm, .Rg16Unorm, .Rg16Snorm, .Rgba16Unorm, .Rgba16Snorm:
		return {.TextureFormat16bitNorm}

	case .BC1RGBAUnorm, .BC1RGBAUnormSrgb, .BC2RGBAUnorm, .BC2RGBAUnormSrgb,
		 .BC3RGBAUnorm, .BC3RGBAUnormSrgb, .BC4RUnorm, .BC4RSnorm, .BC5RGUnorm,
		 .BC5RGSnorm, .BC6HRGBUfloat, .BC6HRGBFloat, .BC7RGBAUnorm, .BC7RGBAUnormSrgb:
		return {.TextureCompressionBC}

	case .ETC2RGB8Unorm, .ETC2RGB8UnormSrgb, .ETC2RGB8A1Unorm, .ETC2RGB8A1UnormSrgb,
		 .ETC2RGBA8Unorm, .ETC2RGBA8UnormSrgb, .EACR11Unorm, .EACR11Snorm, .EACRG11Unorm,
	     .EACRG11Snorm:
		return {.TextureCompressionETC2}

	case .ASTC4x4Unorm, .ASTC4x4UnormSrgb, .ASTC5x4Unorm, .ASTC5x4UnormSrgb,
		 .ASTC5x5Unorm, .ASTC5x5UnormSrgb, .ASTC6x5Unorm, .ASTC6x5UnormSrgb, .ASTC6x6Unorm,
		 .ASTC6x6UnormSrgb, .ASTC8x5Unorm, .ASTC8x5UnormSrgb, .ASTC8x6Unorm,
		 .ASTC8x6UnormSrgb, .ASTC8x8Unorm, .ASTC8x8UnormSrgb, .ASTC10x5Unorm,
		 .ASTC10x5UnormSrgb, .ASTC10x6Unorm, .ASTC10x6UnormSrgb, .ASTC10x8Unorm,
		 .ASTC10x8UnormSrgb, .ASTC10x10Unorm, .ASTC10x10UnormSrgb, .ASTC12x10Unorm,
		 .ASTC12x10UnormSrgb, .ASTC12x12Unorm, .ASTC12x12UnormSrgb:
		return {.TextureCompressionASTC}

	case .Undefined:
		return {}
	}
	return {}
}

/*
Returns the format features guaranteed by the WebGPU spec.

Additional features are available if
`Features.TextureAdapterSpecificFormatFeatures` is enabled.
*/
TextureFormatGuaranteedFormatFeatures :: proc "contextless" (
	self: TextureFormat,
	deviceFeatures: Features,
) -> (
	features: TextureFormatFeatures,
) {
	// Multisampling
	noaa: TextureFormatFeatureFlags
	msaa: TextureFormatFeatureFlags = { .MultisampleX4 }
	msaaResolve: TextureFormatFeatureFlags = msaa + { .MultisampleResolve }

	// Flags
	basic: TextureUsages = { .CopySrc, .CopyDst, .TextureBinding }
	attachment: TextureUsages = basic + { .RenderAttachment }
	storage: TextureUsages = basic + { .StorageBinding }
	binding: TextureUsages = { .TextureBinding }
	allFlags := TEXTURE_USAGES_ALL
	rg11b10f := attachment if .RG11B10UfloatRenderable in deviceFeatures else basic
	bgra8unorm := attachment + storage if .BGRA8UnormStorage in deviceFeatures else attachment

	flags: TextureFormatFeatureFlags
	allowedUsages: TextureUsages

	switch self {
	case .R8Unorm:                flags = msaaResolve; allowedUsages = attachment
	case .R8Snorm:                flags = noaa; allowedUsages = basic
	case .R8Uint:                 flags = msaa; allowedUsages = attachment
	case .R8Sint:                 flags = msaa; allowedUsages = attachment
	case .R16Uint:                flags = msaa; allowedUsages = attachment
	case .R16Sint:                flags = msaa; allowedUsages = attachment
	case .R16Float:               flags = msaaResolve; allowedUsages = attachment
	case .RG8Unorm:               flags = msaaResolve; allowedUsages = attachment
	case .RG8Snorm:               flags = noaa; allowedUsages = basic
	case .RG8Uint:                flags = msaa; allowedUsages = attachment
	case .RG8Sint:                flags = msaa; allowedUsages = attachment
	case .R32Uint:                flags = noaa; allowedUsages = allFlags
	case .R32Sint:                flags = noaa; allowedUsages = allFlags
	case .R32Float:               flags = msaa; allowedUsages = allFlags
	case .RG16Uint:               flags = msaa; allowedUsages = attachment
	case .RG16Sint:               flags = msaa; allowedUsages = attachment
	case .RG16Float:              flags = msaaResolve; allowedUsages = attachment
	case .RGBA8Unorm:             flags = msaaResolve; allowedUsages = allFlags
	case .RGBA8UnormSrgb:        flags = msaaResolve; allowedUsages = attachment
	case .RGBA8Snorm:             flags = noaa; allowedUsages = storage
	case .RGBA8Uint:              flags = msaa; allowedUsages = allFlags
	case .RGBA8Sint:              flags = msaa; allowedUsages = allFlags
	case .BGRA8Unorm:             flags = msaaResolve; allowedUsages = bgra8unorm
	case .BGRA8UnormSrgb:        flags = msaaResolve; allowedUsages = attachment
	case .RGB10A2Uint:            flags = msaa; allowedUsages = attachment
	case .RGB10A2Unorm:           flags = msaaResolve; allowedUsages = attachment
	case .RG11B10Ufloat:          flags = msaa; allowedUsages = rg11b10f
	case .RG32Uint:               flags = noaa; allowedUsages = allFlags
	case .RG32Sint:               flags = noaa; allowedUsages = allFlags
	case .RG32Float:              flags = noaa; allowedUsages = allFlags
	case .RGBA16Uint:             flags = msaa; allowedUsages = allFlags
	case .RGBA16Sint:             flags = msaa; allowedUsages = allFlags
	case .RGBA16Float:            flags = msaaResolve; allowedUsages = allFlags
	case .RGBA32Uint:             flags = noaa; allowedUsages = allFlags
	case .RGBA32Sint:             flags = noaa; allowedUsages = allFlags
	case .RGBA32Float:            flags = noaa; allowedUsages = allFlags
	case .Stencil8:                flags = msaa; allowedUsages = attachment
	case .Depth16Unorm:           flags = msaa; allowedUsages = attachment
	case .Depth24Plus:            flags = msaa; allowedUsages = attachment
	case .Depth24PlusStencil8:   flags = msaa; allowedUsages = attachment
	case .Depth32Float:           flags = msaa; allowedUsages = attachment
	case .Depth32FloatStencil8:  flags = msaa; allowedUsages = attachment
	case .NV12:                    flags = noaa; allowedUsages = binding
	case .R16Unorm:               flags = msaa; allowedUsages = storage
	case .R16Snorm:               flags = msaa; allowedUsages = storage
	case .Rg16Unorm:              flags = msaa; allowedUsages = storage
	case .Rg16Snorm:              flags = msaa; allowedUsages = storage
	case .Rgba16Unorm:            flags = msaa; allowedUsages = storage
	case .Rgba16Snorm:            flags = msaa; allowedUsages = storage
	case .RGB9E5Ufloat:           flags = noaa; allowedUsages = basic
	case .BC1RGBAUnorm:          flags = noaa; allowedUsages = basic
	case .BC1RGBAUnormSrgb:     flags = noaa; allowedUsages = basic
	case .BC2RGBAUnorm:          flags = noaa; allowedUsages = basic
	case .BC2RGBAUnormSrgb:     flags = noaa; allowedUsages = basic
	case .BC3RGBAUnorm:          flags = noaa; allowedUsages = basic
	case .BC3RGBAUnormSrgb:     flags = noaa; allowedUsages = basic
	case .BC4RUnorm:             flags = noaa; allowedUsages = basic
	case .BC4RSnorm:             flags = noaa; allowedUsages = basic
	case .BC5RGUnorm:            flags = noaa; allowedUsages = basic
	case .BC5RGSnorm:            flags = noaa; allowedUsages = basic
	case .BC6HRGBUfloat:         flags = noaa; allowedUsages = basic
	case .BC6HRGBFloat:          flags = noaa; allowedUsages = basic
	case .BC7RGBAUnorm:          flags = noaa; allowedUsages = basic
	case .BC7RGBAUnormSrgb:     flags = noaa; allowedUsages = basic
	case .ETC2RGB8Unorm:         flags = noaa; allowedUsages = basic
	case .ETC2RGB8UnormSrgb:    flags = noaa; allowedUsages = basic
	case .ETC2RGB8A1Unorm:      flags = noaa; allowedUsages = basic
	case .ETC2RGB8A1UnormSrgb: flags = noaa; allowedUsages = basic
	case .ETC2RGBA8Unorm:        flags = noaa; allowedUsages = basic
	case .ETC2RGBA8UnormSrgb:   flags = noaa; allowedUsages = basic
	case .EACR11Unorm:           flags = noaa; allowedUsages = basic
	case .EACR11Snorm:           flags = noaa; allowedUsages = basic
	case .EACRG11Unorm:          flags = noaa; allowedUsages = basic
	case .EACRG11Snorm:          flags = noaa; allowedUsages = basic

	case .ASTC4x4Unorm, .ASTC4x4UnormSrgb, .ASTC5x4Unorm, .ASTC5x4UnormSrgb,
		 .ASTC5x5Unorm,.ASTC5x5UnormSrgb, .ASTC6x5Unorm, .ASTC6x5UnormSrgb, .ASTC6x6Unorm,
		 .ASTC6x6UnormSrgb,.ASTC8x5Unorm, .ASTC8x5UnormSrgb, .ASTC8x6Unorm,
		 .ASTC8x6UnormSrgb, .ASTC8x8Unorm,.ASTC8x8UnormSrgb, .ASTC10x5Unorm,
		 .ASTC10x5UnormSrgb, .ASTC10x6Unorm, .ASTC10x6UnormSrgb,.ASTC10x8Unorm,
		 .ASTC10x8UnormSrgb, .ASTC10x10Unorm, .ASTC10x10UnormSrgb,.ASTC12x10Unorm,
		 .ASTC12x10UnormSrgb, .ASTC12x12Unorm,
		 .ASTC12x12UnormSrgb:
		flags = noaa; allowedUsages = basic

	case .Undefined:
		unreachable()
	}

	// Get whether the format is filterable, taking features into account
	sample_type1 := TextureFormatSampleType(self, nil, deviceFeatures)
	is_filterable := sample_type1 == .Float

	// Features that enable filtering don't affect blendability
	sample_type2 := TextureFormatSampleType(self, nil, {})
	is_blendable := sample_type2 == .Float

	if is_filterable && .Filterable not_in flags {
		flags += {.Filterable}
	}

	if is_blendable && .Blendable not_in flags {
		flags += {.Blendable}
	}

	features.flags = flags
	features.allowedUsages = allowedUsages

	return
}
/*
Returns the sample type compatible with this format and aspect.

Returns `Undefined` only if this is a combined depth-stencil format or a multi-planar format
and `TextureAspect.All`.
*/
TextureFormatSampleType :: proc "contextless" (
	self: TextureFormat,
	aspect: Maybe(TextureAspect) = nil,
	deviceFeatures: Features = {},
) -> TextureSampleType {
	floatFilterable := TextureSampleType.Float
	// unfilterableFloat := TextureSampleType.UnfilterableFloat
	float32SampleType := TextureSampleType.UnfilterableFloat
	if .Float32Filterable in deviceFeatures {
		float32SampleType = .Float
	}
	depth := TextureSampleType.Depth
	_uint := TextureSampleType.Uint
	sint := TextureSampleType.Sint

	_aspect, aspect_ok := aspect.?

	switch self {
	case .R8Unorm, .R8Snorm, .RG8Unorm, .RG8Snorm, .RGBA8Unorm, .RGBA8UnormSrgb,
		 .RGBA8Snorm, .BGRA8Unorm, .BGRA8UnormSrgb, .R16Float, .RG16Float, .RGBA16Float,
		 .RGB10A2Unorm, .RG11B10Ufloat:
		return floatFilterable

	case .R32Float, .RG32Float, .RGBA32Float:
		return float32SampleType

	case .R8Uint, .RG8Uint, .RGBA8Uint, .R16Uint, .RG16Uint, .RGBA16Uint, .R32Uint,
	     .RG32Uint, .RGBA32Uint, .RGB10A2Uint:
		return _uint

	case .R8Sint, .RG8Sint, .RGBA8Sint, .R16Sint, .RG16Sint, .RGBA16Sint, .R32Sint,
	     .RG32Sint, .RGBA32Sint:
		return sint

	case .Stencil8:
		return _uint

	case .Depth16Unorm, .Depth24Plus, .Depth32Float:
		return depth

	case .Depth24PlusStencil8, .Depth32FloatStencil8:
		if aspect_ok {
			if _aspect == .DepthOnly {
				return depth
			}
			if _aspect == .StencilOnly {
				return _uint
			}
		}
		return .Undefined

	case .NV12:
		// if aspect_ok {
		// 	if _aspect == .Plane0 || _aspect == .Plane1 {
		// 		return unfilterableFloat
		// 	}
		// }
		return .Undefined

	case .R16Unorm, .R16Snorm, .Rg16Unorm, .Rg16Snorm, .Rgba16Unorm, .Rgba16Snorm:
		return floatFilterable

	case .RGB9E5Ufloat, .BC1RGBAUnorm, .BC1RGBAUnormSrgb, .BC2RGBAUnorm,
		 .BC2RGBAUnormSrgb, .BC3RGBAUnorm, .BC3RGBAUnormSrgb, .BC4RUnorm, .BC4RSnorm,
		 .BC5RGUnorm, .BC5RGSnorm, .BC6HRGBUfloat, .BC6HRGBFloat, .BC7RGBAUnorm,
		 .BC7RGBAUnormSrgb, .ETC2RGB8Unorm, .ETC2RGB8UnormSrgb, .ETC2RGB8A1Unorm,
		 .ETC2RGB8A1UnormSrgb, .ETC2RGBA8Unorm, .ETC2RGBA8UnormSrgb, .EACR11Unorm,
		 .EACR11Snorm, .EACRG11Unorm, .EACRG11Snorm, .ASTC4x4Unorm, .ASTC4x4UnormSrgb,
		 .ASTC5x4Unorm, .ASTC5x4UnormSrgb, .ASTC5x5Unorm, .ASTC5x5UnormSrgb, .ASTC6x5Unorm,
		 .ASTC6x5UnormSrgb, .ASTC6x6Unorm, .ASTC6x6UnormSrgb, .ASTC8x5Unorm,
		 .ASTC8x5UnormSrgb, .ASTC8x6Unorm, .ASTC8x6UnormSrgb, .ASTC8x8Unorm,
		 .ASTC8x8UnormSrgb, .ASTC10x5Unorm, .ASTC10x5UnormSrgb, .ASTC10x6Unorm,
		 .ASTC10x6UnormSrgb, .ASTC10x8Unorm, .ASTC10x8UnormSrgb, .ASTC10x10Unorm,
		 .ASTC10x10UnormSrgb, .ASTC12x10Unorm, .ASTC12x10UnormSrgb, .ASTC12x12Unorm,
		 .ASTC12x12UnormSrgb:
		return floatFilterable

	case .Undefined:
		return .Undefined
	}
	return .Undefined
}

/*
The number of bytes one [texel
block](https://gpuweb.github.io/gpuweb/#texel-block) occupies during an image
copy, if applicable.

Known as the [texel block copy
footprint](https://gpuweb.github.io/gpuweb/#texel-block-copy-footprint).

Note that for uncompressed formats this is the same as the size of a single
texel, since uncompressed formats have a block size of 1x1.

Returns `0` if any of the following are true:

 - the format is a combined depth-stencil and no `aspect` was provided
 - the format is a multi-planar format and no `aspect` was provided
 - the format is `Depth24Plus`
 - the format is `Depth24PlusStencil8` and `aspect` is depth.
*/
TextureFormatBlockSize :: proc "contextless" (
	self: TextureFormat,
	aspect: Maybe(TextureAspect) = nil,
) -> u32 {
	_aspect, aspect_ok := aspect.?

	switch self {
	case .R8Unorm, .R8Snorm, .R8Uint, .R8Sint: return 1

	case .RG8Unorm, .RG8Snorm, .RG8Uint, .RG8Sint: return 2
	case .R16Unorm, .R16Snorm, .R16Uint, .R16Sint, .R16Float: return 2

	case .RGBA8Unorm,.RGBA8UnormSrgb,.RGBA8Snorm,.RGBA8Uint,.RGBA8Sint,.BGRA8Unorm,
		 .BGRA8UnormSrgb: return 4

	case .Rg16Unorm, .Rg16Snorm, .RG16Uint, .RG16Sint, .RG16Float: return 4
	case .R32Uint, .R32Sint, .R32Float: return 4
	case .RGB9E5Ufloat, .RGB10A2Uint, .RGB10A2Unorm, .RG11B10Ufloat: return 4

	case .Rgba16Unorm, .Rgba16Snorm, .RGBA16Uint, .RGBA16Sint, .RGBA16Float: return 8
	case .RG32Uint, .RG32Sint, .RG32Float: return 8

	case .RGBA32Uint, .RGBA32Sint, .RGBA32Float: return 16

	case .Stencil8: return 1
	case .Depth16Unorm: return 2
	case .Depth32Float: return 4
	case .Depth24Plus: return 0

	case .Depth24PlusStencil8:
		if aspect_ok {
			#partial switch _aspect {
			case .StencilOnly: return 1
			}
		}
		return 0

	case .Depth32FloatStencil8:
		if aspect_ok {
			#partial switch _aspect {
			case .DepthOnly: return 4
			case .StencilOnly: return 1
			}
		}
		return 0

	case .NV12:
		// if aspect_ok {
		// 	#partial switch _aspect {
		// 	case .Plane0: return 1
		// 	case .Plane1: return 2
		// 	}
		// }
		return 0

	case .BC1RGBAUnorm, .BC1RGBAUnormSrgb, .BC4RUnorm, .BC4RSnorm: return 8

	case .BC2RGBAUnorm, .BC2RGBAUnormSrgb, .BC3RGBAUnorm, .BC3RGBAUnormSrgb,
		 .BC5RGUnorm, .BC5RGSnorm, .BC6HRGBUfloat, .BC6HRGBFloat, .BC7RGBAUnorm,
		 .BC7RGBAUnormSrgb: return 16

	case .ETC2RGB8Unorm, .ETC2RGB8UnormSrgb, .ETC2RGB8A1Unorm, .ETC2RGB8A1UnormSrgb,
		 .EACR11Unorm, .EACR11Snorm: return 8

	case .ETC2RGBA8Unorm, .ETC2RGBA8UnormSrgb, .EACRG11Unorm, .EACRG11Snorm: return 16

	case .ASTC4x4Unorm, .ASTC4x4UnormSrgb, .ASTC5x4Unorm, .ASTC5x4UnormSrgb, .ASTC5x5Unorm,
	     .ASTC5x5UnormSrgb, .ASTC6x5Unorm, .ASTC6x5UnormSrgb, .ASTC6x6Unorm,
		 .ASTC6x6UnormSrgb, .ASTC8x5Unorm, .ASTC8x5UnormSrgb, .ASTC8x6Unorm,
		 .ASTC8x6UnormSrgb, .ASTC8x8Unorm, .ASTC8x8UnormSrgb, .ASTC10x5Unorm,
		 .ASTC10x5UnormSrgb, .ASTC10x6Unorm, .ASTC10x6UnormSrgb, .ASTC10x8Unorm,
		 .ASTC10x8UnormSrgb, .ASTC10x10Unorm, .ASTC10x10UnormSrgb, .ASTC12x10Unorm,
		 .ASTC12x10UnormSrgb, .ASTC12x12Unorm, .ASTC12x12UnormSrgb: return 16

	case .Undefined:
		return 0
	}
	return 0
}

/*
The number of bytes occupied per pixel in a color attachment
<https://gpuweb.github.io/gpuweb/#render-target-pixel-byte-cost>
*/
TextureFormatTargetPixelByteCost :: proc "contextless" (self: TextureFormat) -> u32 {
	switch self {
	case .R8Unorm, .R8Snorm, .R8Uint, .R8Sint: return 1

	case .RG8Unorm,.RG8Snorm,.RG8Uint,.RG8Sint,.R16Uint,.R16Sint,.R16Unorm,.R16Snorm,
		 .R16Float:
		return 2

	case .RGBA8Uint, .RGBA8Sint, .RG16Uint, .RG16Sint, .Rg16Unorm, .Rg16Snorm, .RG16Float,
		 .R32Uint, .R32Sint, .R32Float: return 4

	case .RGBA8Unorm, .RGBA8UnormSrgb, .RGBA8Snorm, .BGRA8Unorm, .BGRA8UnormSrgb,
		 .RGBA16Uint, .RGBA16Sint, .Rgba16Unorm, .Rgba16Snorm, .RGBA16Float, .RG32Uint,
		 .RG32Sint, .RG32Float, .RGB10A2Uint, .RGB10A2Unorm, .RG11B10Ufloat:
		return 8

	case .RGBA32Uint, .RGBA32Sint, .RGBA32Float:
		return 16

	case .Stencil8, .Depth16Unorm, .Depth24Plus, .Depth24PlusStencil8, .Depth32Float,
		 .Depth32FloatStencil8, .NV12, .RGB9E5Ufloat, .BC1RGBAUnorm, .BC1RGBAUnormSrgb,
		 .BC2RGBAUnorm, .BC2RGBAUnormSrgb, .BC3RGBAUnorm, .BC3RGBAUnormSrgb, .BC4RUnorm,
		 .BC4RSnorm, .BC5RGUnorm, .BC5RGSnorm, .BC6HRGBUfloat, .BC6HRGBFloat,
		 .BC7RGBAUnorm, .BC7RGBAUnormSrgb, .ETC2RGB8Unorm, .ETC2RGB8UnormSrgb,
		 .ETC2RGB8A1Unorm, .ETC2RGB8A1UnormSrgb, .ETC2RGBA8Unorm, .ETC2RGBA8UnormSrgb,
		 .EACR11Unorm, .EACR11Snorm, .EACRG11Unorm, .EACRG11Snorm, .ASTC4x4Unorm,
		 .ASTC4x4UnormSrgb, .ASTC5x4Unorm, .ASTC5x4UnormSrgb, .ASTC5x5Unorm,
		 .ASTC5x5UnormSrgb, .ASTC6x5Unorm, .ASTC6x5UnormSrgb, .ASTC6x6Unorm,
		 .ASTC6x6UnormSrgb, .ASTC8x5Unorm, .ASTC8x5UnormSrgb, .ASTC8x6Unorm,
		 .ASTC8x6UnormSrgb, .ASTC8x8Unorm, .ASTC8x8UnormSrgb, .ASTC10x5Unorm,
		 .ASTC10x5UnormSrgb, .ASTC10x6Unorm, .ASTC10x6UnormSrgb, .ASTC10x8Unorm,
		 .ASTC10x8UnormSrgb, .ASTC10x10Unorm, .ASTC10x10UnormSrgb, .ASTC12x10Unorm,
		 .ASTC12x10UnormSrgb, .ASTC12x12Unorm, .ASTC12x12UnormSrgb:
		return 0

	case .Undefined: return 0
	}
	return 0
}

/* See <https://gpuweb.github.io/gpuweb/#render-target-component-alignment> */
TextureFormatTargetComponentAlignment :: proc "contextless" (self: TextureFormat) -> u32 {
	switch self {
	case .R8Unorm, .R8Snorm, .R8Uint, .R8Sint, .RG8Unorm, .RG8Snorm, .RG8Uint, .RG8Sint,
	  	 .RGBA8Unorm, .RGBA8UnormSrgb, .
		 RGBA8Snorm, .RGBA8Uint, .RGBA8Sint, .BGRA8Unorm,
		 .BGRA8UnormSrgb: return 1
	case .R16Uint, .R16Sint, .R16Unorm, .R16Snorm, .R16Float, .RG16Uint, .RG16Sint,
		 .Rg16Unorm, .Rg16Snorm, .RG16Float, .RGBA16Uint, .RGBA16Sint, .Rgba16Unorm,
	 	 .Rgba16Snorm, .RGBA16Float: return 2

	case .R32Uint, .R32Sint, .R32Float, .RG32Uint, .RG32Sint, .RG32Float, .RGBA32Uint,
		 .RGBA32Sint, .RGBA32Float, .RGB10A2Uint, .RGB10A2Unorm, .RG11B10Ufloat: return 4

	case .Stencil8, .Depth16Unorm, .Depth24Plus, .Depth24PlusStencil8, .Depth32Float,
		 .Depth32FloatStencil8, .NV12, .RGB9E5Ufloat, .BC1RGBAUnorm, .BC1RGBAUnormSrgb,
		 .BC2RGBAUnorm, .BC2RGBAUnormSrgb, .BC3RGBAUnorm, .BC3RGBAUnormSrgb, .BC4RUnorm,
		 .BC4RSnorm, .BC5RGUnorm, .BC5RGSnorm, .BC6HRGBUfloat, .BC6HRGBFloat,
		 .BC7RGBAUnorm, .BC7RGBAUnormSrgb, .ETC2RGB8Unorm, .ETC2RGB8UnormSrgb,
		 .ETC2RGB8A1Unorm, .ETC2RGB8A1UnormSrgb, .ETC2RGBA8Unorm, .ETC2RGBA8UnormSrgb,
		 .EACR11Unorm, .EACR11Snorm, .EACRG11Unorm, .EACRG11Snorm, .ASTC4x4Unorm,
		 .ASTC4x4UnormSrgb, .ASTC5x4Unorm, .ASTC5x4UnormSrgb, .ASTC5x5Unorm,
		 .ASTC5x5UnormSrgb, .ASTC6x5Unorm, .ASTC6x5UnormSrgb, .ASTC6x6Unorm,
		 .ASTC6x6UnormSrgb, .ASTC8x5Unorm, .ASTC8x5UnormSrgb, .ASTC8x6Unorm,
		 .ASTC8x6UnormSrgb, .ASTC8x8Unorm, .ASTC8x8UnormSrgb, .ASTC10x5Unorm,
		 .ASTC10x5UnormSrgb, .ASTC10x6Unorm, .ASTC10x6UnormSrgb, .ASTC10x8Unorm,
		 .ASTC10x8UnormSrgb, .ASTC10x10Unorm, .ASTC10x10UnormSrgb, .ASTC12x10Unorm,
		 .ASTC12x10UnormSrgb, .ASTC12x12Unorm, .ASTC12x12UnormSrgb:
		return 0

	case .Undefined: return 0
	}
	return 0
}

/* Returns the number of components this format has. */
TextureFormatComponents :: proc "contextless" (self: TextureFormat) -> u8 {
	return TextureFormatComponentsWithAspect(self, .All)
}

/*
Returns the number of components this format has taking into account the `aspect`.

The `aspect` is only relevant for combined depth-stencil formats and multi-planar formats.
*/
TextureFormatComponentsWithAspect :: proc "contextless" (
	self: TextureFormat,
	aspect: TextureAspect,
) -> u8 {
	switch self {
	case .R8Unorm, .R8Snorm, .R8Uint, .R8Sint, .R16Unorm, .R16Snorm, .R16Uint, .R16Sint,
		 .R16Float, .R32Uint, .R32Sint, .R32Float: return 1

	case .RG8Unorm, .RG8Snorm, .RG8Uint, .RG8Sint, .Rg16Unorm, .Rg16Snorm, .RG16Uint,
		 .RG16Sint, .RG16Float, .RG32Uint, .RG32Sint, .RG32Float:
		return 2

	case .RGBA8Unorm, .RGBA8UnormSrgb, .RGBA8Snorm, .RGBA8Uint, .RGBA8Sint, .BGRA8Unorm,
		 .BGRA8UnormSrgb, .Rgba16Unorm, .Rgba16Snorm, .RGBA16Uint, .RGBA16Sint, .RGBA16Float,
		 .RGBA32Uint, .RGBA32Sint, .RGBA32Float: return 4

	case .RGB9E5Ufloat, .RG11B10Ufloat: return 3
	case .RGB10A2Uint, .RGB10A2Unorm: return 4

	case .Stencil8, .Depth16Unorm, .Depth24Plus, .Depth32Float: return 1

	case .Depth24PlusStencil8, .Depth32FloatStencil8:
		#partial switch aspect {
		case .Undefined: return 0
		case .DepthOnly, .StencilOnly: return 1
		}
		return 2

	case .NV12:
		#partial switch aspect {
		case .Undefined: return 0
		// case .Plane0: return 1
		// case .Plane1: return 2
		}
		return 3

	case .BC4RUnorm, .BC4RSnorm: return 1
	case .BC5RGUnorm, .BC5RGSnorm: return 2
	case .BC6HRGBUfloat, .BC6HRGBFloat: return 3

	case .BC1RGBAUnorm, .BC1RGBAUnormSrgb, .BC2RGBAUnorm, .BC2RGBAUnormSrgb,
		 .BC3RGBAUnorm, .BC3RGBAUnormSrgb, .BC7RGBAUnorm, .BC7RGBAUnormSrgb:
		return 4

	case .EACR11Unorm, .EACR11Snorm: return 1
	case .EACRG11Unorm, .EACRG11Snorm: return 2
	case .ETC2RGB8Unorm, .ETC2RGB8UnormSrgb: return 3

	case .ETC2RGB8A1Unorm, .ETC2RGB8A1UnormSrgb, .ETC2RGBA8Unorm,
		 .ETC2RGBA8UnormSrgb:
		return 4

	case .ASTC4x4Unorm, .ASTC4x4UnormSrgb, .ASTC5x4Unorm, .ASTC5x4UnormSrgb,
		 .ASTC5x5Unorm, .ASTC5x5UnormSrgb, .ASTC6x5Unorm, .ASTC6x5UnormSrgb, .ASTC6x6Unorm,
		 .ASTC6x6UnormSrgb, .ASTC8x5Unorm, .ASTC8x5UnormSrgb, .ASTC8x6Unorm,
		 .ASTC8x6UnormSrgb, .ASTC8x8Unorm, .ASTC8x8UnormSrgb, .ASTC10x5Unorm,
		 .ASTC10x5UnormSrgb, .ASTC10x6Unorm, .ASTC10x6UnormSrgb, .ASTC10x8Unorm,
		 .ASTC10x8UnormSrgb, .ASTC10x10Unorm, .ASTC10x10UnormSrgb, .ASTC12x10Unorm,
		 .ASTC12x10UnormSrgb, .ASTC12x12Unorm, .ASTC12x12UnormSrgb:
		return 4

	case .Undefined:
		return 0
	}
	return 0
}

/* Strips the `Srgb` suffix from the given texture format. */
TextureFormatRemoveSrgbSuffix :: proc "contextless" (
	self: TextureFormat,
) -> (
	ret: TextureFormat,
) {
	ret = self
	#partial switch self {
	case .RGBA8UnormSrgb: return .RGBA8Unorm
	case .BGRA8UnormSrgb: return .BGRA8Unorm
	case .BC1RGBAUnormSrgb: return .BC1RGBAUnorm
	case .BC2RGBAUnormSrgb: return .BC2RGBAUnorm
	case .BC3RGBAUnormSrgb: return .BC3RGBAUnorm
	case .BC7RGBAUnormSrgb: return .BC7RGBAUnorm
	case .ETC2RGB8UnormSrgb: return .ETC2RGB8Unorm
	case .ETC2RGB8A1UnormSrgb: return .ETC2RGB8A1Unorm
	case .ETC2RGBA8UnormSrgb: return .ETC2RGBA8Unorm
	case .ASTC4x4UnormSrgb: return .ASTC4x4Unorm
	case .ASTC5x4UnormSrgb: return .ASTC5x4Unorm
	case .ASTC5x5UnormSrgb: return .ASTC5x5Unorm
	case .ASTC6x5UnormSrgb: return .ASTC6x5Unorm
	case .ASTC6x6UnormSrgb: return .ASTC6x6Unorm
	case .ASTC8x5UnormSrgb: return .ASTC8x5Unorm
	case .ASTC8x6UnormSrgb: return .ASTC8x6Unorm
	case .ASTC8x8UnormSrgb: return .ASTC8x8Unorm
	case .ASTC10x5UnormSrgb: return .ASTC10x5Unorm
	case .ASTC10x6UnormSrgb: return .ASTC10x6Unorm
	case .ASTC10x8UnormSrgb: return .ASTC10x8Unorm
	case .ASTC10x10UnormSrgb: return .ASTC10x10Unorm
	case .ASTC12x10UnormSrgb: return .ASTC12x10Unorm
	case .ASTC12x12UnormSrgb: return .ASTC12x12Unorm
	}
	return
}

/* Adds an `Srgb` suffix to the given texture format, if the format supports it. */
TextureFormatAddSrgbSuffix :: proc "contextless" (
	self: TextureFormat,
) -> (
	ret: TextureFormat,
) {
	ret = self
	#partial switch self {
	case .RGBA8Unorm: return .RGBA8UnormSrgb
	case .BGRA8Unorm: return .BGRA8UnormSrgb
	case .BC1RGBAUnorm: return .BC1RGBAUnormSrgb
	case .BC2RGBAUnorm: return .BC2RGBAUnormSrgb
	case .BC3RGBAUnorm: return .BC3RGBAUnormSrgb
	case .BC7RGBAUnorm: return .BC7RGBAUnormSrgb
	case .ETC2RGB8Unorm: return .ETC2RGB8UnormSrgb
	case .ETC2RGB8A1Unorm: return .ETC2RGB8A1UnormSrgb
	case .ETC2RGBA8Unorm: return .ETC2RGBA8UnormSrgb
	case .ASTC4x4Unorm: return .ASTC4x4UnormSrgb
	case .ASTC5x4Unorm: return .ASTC5x4UnormSrgb
	case .ASTC5x5Unorm: return .ASTC5x5UnormSrgb
	case .ASTC6x5Unorm: return .ASTC6x5UnormSrgb
	case .ASTC6x6Unorm: return .ASTC6x6UnormSrgb
	case .ASTC8x5Unorm: return .ASTC8x5UnormSrgb
	case .ASTC8x6Unorm: return .ASTC8x6UnormSrgb
	case .ASTC8x8Unorm: return .ASTC8x8UnormSrgb
	case .ASTC10x5Unorm: return .ASTC10x5UnormSrgb
	case .ASTC10x6Unorm: return .ASTC10x6UnormSrgb
	case .ASTC10x8Unorm: return .ASTC10x8UnormSrgb
	case .ASTC10x10Unorm: return .ASTC10x10UnormSrgb
	case .ASTC12x10Unorm: return .ASTC12x10UnormSrgb
	case .ASTC12x12Unorm: return .ASTC12x12UnormSrgb
	}
	return
}

/* Returns `true` for srgb formats. */
TextureFormatIsSrgb :: proc "contextless" (self: TextureFormat) -> bool {
	return self != TextureFormatRemoveSrgbSuffix(self)
}

/* Calculate bytes per row from the given row width. */
TextureFormatBytesPerRow :: proc "contextless" (
	format: TextureFormat,
	width: u32,
) -> (
	bytes_per_row: u32,
) {
	block_width, _ := TextureFormatBlockDimensions(format)
	block_size := TextureFormatBlockSize(format)

	// Calculate the number of blocks for the given width
	blocks_in_width := (width + block_width - 1) / block_width

	// Calculate unaligned bytes per row
	unaligned_bytes_per_row := blocks_in_width * block_size

	// Align to COPY_BYTES_PER_ROW_ALIGNMENT
	bytes_per_row =
		(unaligned_bytes_per_row + COPY_BYTES_PER_ROW_ALIGNMENT - 1) &
		~(COPY_BYTES_PER_ROW_ALIGNMENT - 1)

	return
}
