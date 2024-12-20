package wgpu

/*
Check if the format is a depth or stencil component of the given combined depth-stencil format.
*/
texture_format_is_depth_stencil_component :: proc "contextless" (
	self, combined_format: TextureFormat,
) -> bool {
	return(
		combined_format == .Depth24PlusStencil8 && (self == .Depth24Plus || self == .Stencil8) ||
		combined_format == .Depth32FloatStencil8 && (self == .Depth32Float || self == .Stencil8) \
	)
}

/*
Check if the format is a depth and/or stencil format.

see <https://gpuweb.github.io/gpuweb/#depth-formats>
*/
texture_format_is_depth_stencil_format :: proc "contextless" (self: TextureFormat) -> bool {
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
texture_format_is_combined_depth_stencil_format :: proc "contextless" (
	self: TextureFormat,
) -> bool {
	#partial switch self {
	case .Depth24PlusStencil8, .Depth32FloatStencil8:
		return true
	}

	return false
}

/* Returns `true` if the format has a depth aspect. */
texture_format_has_depth_aspect :: proc "contextless" (self: TextureFormat) -> bool {
	#partial switch self {
	case .Depth16Unorm, .Depth24Plus, .Depth24PlusStencil8, .Depth32Float, .Depth32FloatStencil8:
		return true
	}

	return false
}

/*
Returns the dimension of a [block](https://gpuweb.github.io/gpuweb/#texel-block) of texels.

Uncompressed formats have a block dimension of `(1, 1)`.
*/
texture_format_block_dimensions :: proc "contextless" (self: TextureFormat) -> (w, h: u32) {
	#partial switch self {
	case .R8Unorm,
	     .R8Snorm,
	     .R8Uint,
	     .R8Sint,
	     .R16Uint,
	     .R16Sint,
	     .R16Unorm,
	     .R16Snorm,
	     .R16Float,
	     .Rg8Unorm,
	     .Rg8Snorm,
	     .Rg8Uint,
	     .Rg8Sint,
	     .R32Uint,
	     .R32Sint,
	     .R32Float,
	     .Rg16Uint,
	     .Rg16Sint,
	     .Rg16Unorm,
	     .Rg16Snorm,
	     .Rg16Float,
	     .Rgba8Unorm,
	     .Rgba8UnormSrgb,
	     .Rgba8Snorm,
	     .Rgba8Uint,
	     .Rgba8Sint,
	     .Bgra8Unorm,
	     .Bgra8UnormSrgb,
	     .Rgb9E5Ufloat,
	     .Rgb10A2Uint,
	     .Rgb10A2Unorm,
	     .Rg11B10Ufloat,
	     .Rg32Uint,
	     .Rg32Sint,
	     .Rg32Float,
	     .Rgba16Uint,
	     .Rgba16Sint,
	     .Rgba16Unorm,
	     .Rgba16Snorm,
	     .Rgba16Float,
	     .Rgba32Uint,
	     .Rgba32Sint,
	     .Rgba32Float,
	     .Stencil8,
	     .Depth16Unorm,
	     .Depth24Plus,
	     .Depth24PlusStencil8,
	     .Depth32Float,
	     .Depth32FloatStencil8:
		return 1, 1

	case .Bc1RgbaUnorm,
	     .Bc1RgbaUnormSrgb,
	     .Bc2RgbaUnorm,
	     .Bc2RgbaUnormSrgb,
	     .Bc3RgbaUnorm,
	     .Bc3RgbaUnormSrgb,
	     .Bc4RUnorm,
	     .Bc4RSnorm,
	     .Bc5RgUnorm,
	     .Bc5RgSnorm,
	     .Bc6HrgbUfloat,
	     .Bc6HrgbFloat,
	     .Bc7RgbaUnorm,
	     .Bc7RgbaUnormSrgb,
	     .Etc2Rgb8Unorm,
	     .Etc2Rgb8UnormSrgb,
	     .Etc2Rgb8A1Unorm,
	     .Etc2Rgb8A1UnormSrgb,
	     .Etc2Rgba8Unorm,
	     .Etc2Rgba8UnormSrgb,
	     .Eacr11Unorm,
	     .Eacr11Snorm,
	     .Eacrg11Unorm,
	     .Eacrg11Snorm:
		return 4, 4

	case .Astc4x4Unorm, .Astc4x4UnormSrgb:
		return 4, 4
	case .Astc5x4Unorm, .Astc5x4UnormSrgb:
		return 5, 5
	case .Astc5x5Unorm, .Astc5x5UnormSrgb:
		return 5, 5
	case .Astc6x5Unorm, .Astc6x5UnormSrgb:
		return 6, 5
	case .Astc6x6Unorm, .Astc6x6UnormSrgb:
		return 6, 6
	case .Astc8x5Unorm, .Astc8x5UnormSrgb:
		return 8, 5
	case .Astc8x6Unorm, .Astc8x6UnormSrgb:
		return 8, 6
	case .Astc8x8Unorm, .Astc8x8UnormSrgb:
		return 8, 8
	case .Astc10x5Unorm, .Astc10x5UnormSrgb:
		return 10, 5
	case .Astc10x6Unorm, .Astc10x6UnormSrgb:
		return 10, 6
	case .Astc10x8Unorm, .Astc10x8UnormSrgb:
		return 10, 8
	case .Astc10x10Unorm, .Astc10x10UnormSrgb:
		return 10, 10
	case .Astc12x10Unorm, .Astc12x10UnormSrgb:
		return 12, 10
	case .Astc12x12Unorm, .Astc12x12UnormSrgb:
		return 12, 12
	}

	return 1, 1
}

/* Returns `true` for compressed formats. */
texture_format_is_compressed :: proc "contextless" (self: TextureFormat) -> bool {
	w, h := texture_format_block_dimensions(self)
	return w != 1 && h != 1
}

/* Returns the required features (if any) in order to use the texture. */
texture_format_required_features :: proc "contextless" (self: TextureFormat) -> Features {
	#partial switch self {
	case .R8Unorm,
	     .R8Snorm,
	     .R8Uint,
	     .R8Sint,
	     .R16Uint,
	     .R16Sint,
	     .R16Float,
	     .Rg8Unorm,
	     .Rg8Snorm,
	     .Rg8Uint,
	     .Rg8Sint,
	     .R32Float,
	     .R32Uint,
	     .R32Sint,
	     .Rg16Uint,
	     .Rg16Sint,
	     .Rg16Float,
	     .Rgba8Unorm,
	     .Rgba8UnormSrgb,
	     .Rgba8Snorm,
	     .Rgba8Uint,
	     .Rgba8Sint,
	     .Bgra8Unorm,
	     .Bgra8UnormSrgb,
	     .Rgb10A2Uint,
	     .Rgb10A2Unorm,
	     .Rg11B10Ufloat,
	     .Rgb9E5Ufloat,
	     .Rg32Float,
	     .Rg32Uint,
	     .Rg32Sint,
	     .Rgba16Uint,
	     .Rgba16Sint,
	     .Rgba16Float,
	     .Rgba32Float,
	     .Rgba32Uint,
	     .Rgba32Sint,
	     .Stencil8,
	     .Depth16Unorm,
	     .Depth24Plus,
	     .Depth24PlusStencil8,
	     .Depth32Float:
		return {} // empty, no features need

	case .Depth32FloatStencil8:
		return {.Depth32FloatStencil8}

	case .Bc1RgbaUnorm,
	     .Bc1RgbaUnormSrgb,
	     .Bc2RgbaUnorm,
	     .Bc2RgbaUnormSrgb,
	     .Bc3RgbaUnorm,
	     .Bc3RgbaUnormSrgb,
	     .Bc4RUnorm,
	     .Bc4RSnorm,
	     .Bc5RgUnorm,
	     .Bc5RgSnorm,
	     .Bc6HrgbUfloat,
	     .Bc6HrgbFloat,
	     .Bc7RgbaUnorm,
	     .Bc7RgbaUnormSrgb:
		return {.TextureCompressionBC}

	case .Etc2Rgb8Unorm,
	     .Etc2Rgb8UnormSrgb,
	     .Etc2Rgb8A1Unorm,
	     .Etc2Rgb8A1UnormSrgb,
	     .Etc2Rgba8Unorm,
	     .Etc2Rgba8UnormSrgb,
	     .Eacr11Unorm,
	     .Eacr11Snorm,
	     .Eacrg11Unorm,
	     .Eacrg11Snorm:
		return {.TextureCompressionETC2}

	case .R16Unorm, .R16Snorm, .Rg16Unorm, .Rg16Snorm, .Rgba16Unorm, .Rgba16Snorm:
		return {.TextureFormat16bitNorm}

	case .Astc4x4Unorm,
	     .Astc4x4UnormSrgb,
	     .Astc5x4Unorm,
	     .Astc5x4UnormSrgb,
	     .Astc5x5Unorm,
	     .Astc5x5UnormSrgb,
	     .Astc6x5Unorm,
	     .Astc6x5UnormSrgb,
	     .Astc6x6Unorm,
	     .Astc6x6UnormSrgb,
	     .Astc8x5Unorm,
	     .Astc8x5UnormSrgb,
	     .Astc8x6Unorm,
	     .Astc8x6UnormSrgb,
	     .Astc8x8Unorm,
	     .Astc8x8UnormSrgb,
	     .Astc10x5Unorm,
	     .Astc10x5UnormSrgb,
	     .Astc10x6Unorm,
	     .Astc10x6UnormSrgb,
	     .Astc10x8Unorm,
	     .Astc10x8UnormSrgb,
	     .Astc10x10Unorm,
	     .Astc10x10UnormSrgb,
	     .Astc12x10Unorm,
	     .Astc12x10UnormSrgb,
	     .Astc12x12Unorm,
	     .Astc12x12UnormSrgb:
		return {.TextureCompressionASTC}
	}

	return {}
}

TextureUsageFeatureBits :: enum i32 {
	Filterable,
	MultisampleX2,
	MultisampleX4,
	MultisampleX8,
	MultisampleX16,
	MultisampleResolve,
	StorageReadWrite,
	Blendable,
}

/* Feature flags for a texture format. */
TextureUsageFeatures :: bit_set[TextureUsageFeatureBits;u64]

/* Features supported by a given texture format */
TextureFormatFeatures :: struct {
	allowed_usages: TextureUsage,
	flags:          TextureUsageFeatures,
}

texture_usage_feature_flags_sample_count_supported :: proc "contextless" (
	self: TextureUsageFeatures,
	count: u32,
) -> bool {
	switch count {
	case 1:
		return true
	case 2:
		return .MultisampleX2 in self
	case 4:
		return .MultisampleX4 in self
	case 8:
		return .MultisampleX8 in self
	case 16:
		return .MultisampleX16 in self
	}

	return false
}

/*
Returns the sample type compatible with this format and aspect.

Returns `Undefined` only if this is a combined depth-stencil format or a multi-planar format
and `TextureAspect::All`.
*/
texture_format_sample_type :: proc "contextless" (
	self: TextureFormat,
	aspect: Maybe(TextureAspect) = nil,
	device_features: DeviceFeatures = {},
) -> TextureSampleType {
	float_filterable := TextureSampleType.Float
	unfilterable_float := TextureSampleType.UnfilterableFloat
	float32_sample_type := TextureSampleType.UnfilterableFloat
	if .Float32Filterable in device_features {
		float32_sample_type = .Float
	}
	depth := TextureSampleType.Depth
	_uint := TextureSampleType.Uint
	sint := TextureSampleType.Sint

	#partial switch self {
	case .R8Unorm,
	     .R8Snorm,
	     .Rg8Unorm,
	     .Rg8Snorm,
	     .Rgba8Unorm,
	     .Rgba8UnormSrgb,
	     .Rgba8Snorm,
	     .Bgra8Unorm,
	     .Bgra8UnormSrgb,
	     .R16Float,
	     .Rg16Float,
	     .Rgba16Float,
	     .Rgb10A2Unorm,
	     .Rg11B10Ufloat:
		return float_filterable

	case .R32Float, .Rg32Float, .Rgba32Float:
		return float32_sample_type

	case .R8Uint,
	     .Rg8Uint,
	     .Rgba8Uint,
	     .R16Uint,
	     .Rg16Uint,
	     .Rgba16Uint,
	     .R32Uint,
	     .Rg32Uint,
	     .Rgba32Uint,
	     .Rgb10A2Uint:
		return _uint

	case .R8Sint,
	     .Rg8Sint,
	     .Rgba8Sint,
	     .R16Sint,
	     .Rg16Sint,
	     .Rgba16Sint,
	     .R32Sint,
	     .Rg32Sint,
	     .Rgba32Sint:
		return sint

	case .Stencil8:
		return _uint

	case .Depth16Unorm, .Depth24Plus, .Depth32Float:
		return depth

	case .Depth24PlusStencil8, .Depth32FloatStencil8:
		_aspect, aspect_ok := aspect.?
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
		return unfilterable_float

	case .R16Unorm, .R16Snorm, .Rg16Unorm, .Rg16Snorm, .Rgba16Unorm, .Rgba16Snorm:
		return float_filterable

	case .Rgb9E5Ufloat,
	     .Bc1RgbaUnorm,
	     .Bc1RgbaUnormSrgb,
	     .Bc2RgbaUnorm,
	     .Bc2RgbaUnormSrgb,
	     .Bc3RgbaUnorm,
	     .Bc3RgbaUnormSrgb,
	     .Bc4RUnorm,
	     .Bc4RSnorm,
	     .Bc5RgUnorm,
	     .Bc5RgSnorm,
	     .Bc6HrgbUfloat,
	     .Bc6HrgbFloat,
	     .Bc7RgbaUnorm,
	     .Bc7RgbaUnormSrgb,
	     .Etc2Rgb8Unorm,
	     .Etc2Rgb8UnormSrgb,
	     .Etc2Rgb8A1Unorm,
	     .Etc2Rgb8A1UnormSrgb,
	     .Etc2Rgba8Unorm,
	     .Etc2Rgba8UnormSrgb,
	     .Eacr11Unorm,
	     .Eacr11Snorm,
	     .Eacrg11Unorm,
	     .Eacrg11Snorm,
	     .Astc4x4Unorm,
	     .Astc4x4UnormSrgb,
	     .Astc5x4Unorm,
	     .Astc5x4UnormSrgb,
	     .Astc5x5Unorm,
	     .Astc5x5UnormSrgb,
	     .Astc6x5Unorm,
	     .Astc6x5UnormSrgb,
	     .Astc6x6Unorm,
	     .Astc6x6UnormSrgb,
	     .Astc8x5Unorm,
	     .Astc8x5UnormSrgb,
	     .Astc8x6Unorm,
	     .Astc8x6UnormSrgb,
	     .Astc8x8Unorm,
	     .Astc8x8UnormSrgb,
	     .Astc10x5Unorm,
	     .Astc10x5UnormSrgb,
	     .Astc10x6Unorm,
	     .Astc10x6UnormSrgb,
	     .Astc10x8Unorm,
	     .Astc10x8UnormSrgb,
	     .Astc10x10Unorm,
	     .Astc10x10UnormSrgb,
	     .Astc12x10Unorm,
	     .Astc12x10UnormSrgb,
	     .Astc12x12Unorm,
	     .Astc12x12UnormSrgb:
		return float_filterable
	}

	return .Undefined
}

/*
Returns the format features guaranteed by the WebGPU spec.

Additional features are available if `Features.Texture_Adapter_Specific_Format_Features`
is enabled.
*/
texture_format_guaranteed_format_features :: proc "contextless" (
	self: TextureFormat,
	device_features: DeviceFeatures,
) -> (
	features: TextureFormatFeatures,
) {
	// Multisampling
	noaa: TextureUsageFeatures
	msaa: TextureUsageFeatures = {.MultisampleX4}
	msaa_resolve: TextureUsageFeatures = msaa + {.MultisampleResolve}

	// Flags
	basic: TextureUsage = {.CopySrc, .CopyDst, .TextureBinding}
	attachment: TextureUsage = basic + {.RenderAttachment}
	storage: TextureUsage = basic + {.StorageBinding}
	binding: TextureUsage = {.TextureBinding}
	all_flags := TEXTURE_USAGE_ALL
	rg11b10f := attachment if .RG11B10UfloatRenderable in device_features else basic
	bgra8unorm := attachment + storage if .BGRA8UnormStorage in device_features else attachment

	flags: TextureUsageFeatures
	allowed_usages: TextureUsage

	#partial switch self {
	case .R8Unorm:
		flags = msaa_resolve;allowed_usages = attachment
	case .R8Snorm:
		flags = noaa;allowed_usages = basic
	case .R8Uint:
		flags = msaa;allowed_usages = attachment
	case .R8Sint:
		flags = msaa;allowed_usages = attachment
	case .R16Uint:
		flags = msaa;allowed_usages = attachment
	case .R16Sint:
		flags = msaa;allowed_usages = attachment
	case .R16Float:
		flags = msaa_resolve;allowed_usages = attachment
	case .Rg8Unorm:
		flags = msaa_resolve;allowed_usages = attachment
	case .Rg8Snorm:
		flags = noaa;allowed_usages = basic
	case .Rg8Uint:
		flags = msaa;allowed_usages = attachment
	case .Rg8Sint:
		flags = msaa;allowed_usages = attachment
	case .R32Uint:
		flags = noaa;allowed_usages = all_flags
	case .R32Sint:
		flags = noaa;allowed_usages = all_flags
	case .R32Float:
		flags = msaa;allowed_usages = all_flags
	case .Rg16Uint:
		flags = msaa;allowed_usages = attachment
	case .Rg16Sint:
		flags = msaa;allowed_usages = attachment
	case .Rg16Float:
		flags = msaa_resolve;allowed_usages = attachment
	case .Rgba8Unorm:
		flags = msaa_resolve;allowed_usages = all_flags
	case .Rgba8UnormSrgb:
		flags = msaa_resolve;allowed_usages = attachment
	case .Rgba8Snorm:
		flags = noaa;allowed_usages = storage
	case .Rgba8Uint:
		flags = msaa;allowed_usages = all_flags
	case .Rgba8Sint:
		flags = msaa;allowed_usages = all_flags
	case .Bgra8Unorm:
		flags = msaa_resolve;allowed_usages = bgra8unorm
	case .Bgra8UnormSrgb:
		flags = msaa_resolve;allowed_usages = attachment
	case .Rgb10A2Uint:
		flags = msaa;allowed_usages = attachment
	case .Rgb10A2Unorm:
		flags = msaa_resolve;allowed_usages = attachment
	case .Rg11B10Ufloat:
		flags = msaa;allowed_usages = rg11b10f
	case .Rg32Uint:
		flags = noaa;allowed_usages = all_flags
	case .Rg32Sint:
		flags = noaa;allowed_usages = all_flags
	case .Rg32Float:
		flags = noaa;allowed_usages = all_flags
	case .Rgba16Uint:
		flags = msaa;allowed_usages = all_flags
	case .Rgba16Sint:
		flags = msaa;allowed_usages = all_flags
	case .Rgba16Float:
		flags = msaa_resolve;allowed_usages = all_flags
	case .Rgba32Uint:
		flags = noaa;allowed_usages = all_flags
	case .Rgba32Sint:
		flags = noaa;allowed_usages = all_flags
	case .Rgba32Float:
		flags = noaa;allowed_usages = all_flags
	case .Stencil8:
		flags = msaa;allowed_usages = attachment
	case .Depth16Unorm:
		flags = msaa;allowed_usages = attachment
	case .Depth24Plus:
		flags = msaa;allowed_usages = attachment
	case .Depth24PlusStencil8:
		flags = msaa;allowed_usages = attachment
	case .Depth32Float:
		flags = msaa;allowed_usages = attachment
	case .Depth32FloatStencil8:
		flags = msaa;allowed_usages = attachment
	case .NV12:
		flags = noaa;allowed_usages = binding
	case .R16Unorm:
		flags = msaa;allowed_usages = storage
	case .R16Snorm:
		flags = msaa;allowed_usages = storage
	case .Rg16Unorm:
		flags = msaa;allowed_usages = storage
	case .Rg16Snorm:
		flags = msaa;allowed_usages = storage
	case .Rgba16Unorm:
		flags = msaa;allowed_usages = storage
	case .Rgba16Snorm:
		flags = msaa;allowed_usages = storage
	case .Rgb9E5Ufloat:
		flags = noaa;allowed_usages = basic
	case .Bc1RgbaUnorm:
		flags = noaa;allowed_usages = basic
	case .Bc1RgbaUnormSrgb:
		flags = noaa;allowed_usages = basic
	case .Bc2RgbaUnorm:
		flags = noaa;allowed_usages = basic
	case .Bc2RgbaUnormSrgb:
		flags = noaa;allowed_usages = basic
	case .Bc3RgbaUnorm:
		flags = noaa;allowed_usages = basic
	case .Bc3RgbaUnormSrgb:
		flags = noaa;allowed_usages = basic
	case .Bc4RUnorm:
		flags = noaa;allowed_usages = basic
	case .Bc4RSnorm:
		flags = noaa;allowed_usages = basic
	case .Bc5RgUnorm:
		flags = noaa;allowed_usages = basic
	case .Bc5RgSnorm:
		flags = noaa;allowed_usages = basic
	case .Bc6HrgbUfloat:
		flags = noaa;allowed_usages = basic
	case .Bc6HrgbFloat:
		flags = noaa;allowed_usages = basic
	case .Bc7RgbaUnorm:
		flags = noaa;allowed_usages = basic
	case .Bc7RgbaUnormSrgb:
		flags = noaa;allowed_usages = basic
	case .Etc2Rgb8Unorm:
		flags = noaa;allowed_usages = basic
	case .Etc2Rgb8UnormSrgb:
		flags = noaa;allowed_usages = basic
	case .Etc2Rgb8A1Unorm:
		flags = noaa;allowed_usages = basic
	case .Etc2Rgb8A1UnormSrgb:
		flags = noaa;allowed_usages = basic
	case .Etc2Rgba8Unorm:
		flags = noaa;allowed_usages = basic
	case .Etc2Rgba8UnormSrgb:
		flags = noaa;allowed_usages = basic
	case .Eacr11Unorm:
		flags = noaa;allowed_usages = basic
	case .Eacr11Snorm:
		flags = noaa;allowed_usages = basic
	case .Eacrg11Unorm:
		flags = noaa;allowed_usages = basic
	case .Eacrg11Snorm:
		flags = noaa;allowed_usages = basic
	case .Astc4x4Unorm,
	     .Astc4x4UnormSrgb,
	     .Astc5x4Unorm,
	     .Astc5x4UnormSrgb,
	     .Astc5x5Unorm,
	     .Astc5x5UnormSrgb,
	     .Astc6x5Unorm,
	     .Astc6x5UnormSrgb,
	     .Astc6x6Unorm,
	     .Astc6x6UnormSrgb,
	     .Astc8x5Unorm,
	     .Astc8x5UnormSrgb,
	     .Astc8x6Unorm,
	     .Astc8x6UnormSrgb,
	     .Astc8x8Unorm,
	     .Astc8x8UnormSrgb,
	     .Astc10x5Unorm,
	     .Astc10x5UnormSrgb,
	     .Astc10x6Unorm,
	     .Astc10x6UnormSrgb,
	     .Astc10x8Unorm,
	     .Astc10x8UnormSrgb,
	     .Astc10x10Unorm,
	     .Astc10x10UnormSrgb,
	     .Astc12x10Unorm,
	     .Astc12x10UnormSrgb,
	     .Astc12x12Unorm,
	     .Astc12x12UnormSrgb:
		flags = noaa;allowed_usages = basic
	}

	// Get whether the format is filterable, taking features into account
	sample_type1 := texture_format_sample_type(self, nil, device_features)
	is_filterable := sample_type1 == .Float

	// Features that enable filtering don't affect blendability
	sample_type2 := texture_format_sample_type(self, nil, {})
	is_blendable := sample_type2 == .Float

	if is_filterable && .Filterable not_in flags {
		flags += {.Filterable}
	}

	if is_blendable && .Blendable not_in flags {
		flags += {.Blendable}
	}

	features.flags = flags
	features.allowed_usages = allowed_usages

	return
}

/*
The number of bytes one [texel block](https://gpuweb.github.io/gpuweb/#texel-block) occupies
during an image copy, if applicable.

Known as the [texel block copy footprint](https://gpuweb.github.io/gpuweb/#texel-block-copy-footprint).

Note that for uncompressed formats this is the same as the size of a single texel,
since uncompressed formats have a block size of 1x1.

Returns `0` if any of the following are true:
 - the format is a combined depth-stencil and no `aspect` was provided
 - the format is a multi-planar format and no `aspect` was provided
 - the format is `Depth24Plus`
 - the format is `Depth24PlusStencil8` and `aspect` is depth.
*/
texture_format_block_size :: proc "contextless" (
	self: TextureFormat,
	aspect: Maybe(TextureAspect) = nil,
) -> u32 {
	_aspect, aspect_ok := aspect.?

	#partial switch self {
	case .R8Unorm, .R8Snorm, .R8Uint, .R8Sint:
		return 1

	case .Rg8Unorm, .Rg8Snorm, .Rg8Uint, .Rg8Sint:
		return 2

	case .R16Uint,
	     .R16Sint,
	     .R16Float,
	     .Rg16Uint,
	     .Rg16Sint,
	     .Rg16Float,
	     .Rgb10A2Uint,
	     .Rg11B10Ufloat,
	     .Rgb9E5Ufloat:
		return 4

	case .Rgba8Unorm,
	     .Rgba8UnormSrgb,
	     .Rgba8Snorm,
	     .Rgba8Uint,
	     .Rgba8Sint,
	     .Bgra8Unorm,
	     .Bgra8UnormSrgb:
		return 4

	case .R32Uint, .R32Sint, .R32Float, .Rg32Uint, .Rg32Sint, .Rg32Float:
		return 8

	case .Rgba16Uint,
	     .Rgba16Sint,
	     .Rgba16Float,
	     .Rgba32Uint,
	     .Rgba32Sint,
	     .Rgba32Float,
	     .Bc1RgbaUnorm,
	     .Bc1RgbaUnormSrgb,
	     .Bc4RUnorm,
	     .Bc4RSnorm,
	     .Bc5RgUnorm,
	     .Bc5RgSnorm,
	     .Bc6HrgbUfloat,
	     .Bc6HrgbFloat,
	     .Bc7RgbaUnorm,
	     .Bc7RgbaUnormSrgb,
	     .Etc2Rgb8Unorm,
	     .Etc2Rgb8UnormSrgb,
	     .Etc2Rgb8A1Unorm,
	     .Etc2Rgb8A1UnormSrgb,
	     .Etc2Rgba8Unorm,
	     .Etc2Rgba8UnormSrgb,
	     .Eacr11Unorm,
	     .Eacr11Snorm,
	     .Eacrg11Unorm,
	     .Eacrg11Snorm,
	     .Astc4x4Unorm,
	     .Astc4x4UnormSrgb,
	     .Astc5x4Unorm,
	     .Astc5x4UnormSrgb,
	     .Astc5x5Unorm,
	     .Astc5x5UnormSrgb,
	     .Astc6x5Unorm,
	     .Astc6x5UnormSrgb,
	     .Astc6x6Unorm,
	     .Astc6x6UnormSrgb,
	     .Astc8x5Unorm,
	     .Astc8x5UnormSrgb,
	     .Astc8x6Unorm,
	     .Astc8x6UnormSrgb,
	     .Astc8x8Unorm,
	     .Astc8x8UnormSrgb,
	     .Astc10x5Unorm,
	     .Astc10x5UnormSrgb,
	     .Astc10x6Unorm,
	     .Astc10x6UnormSrgb,
	     .Astc10x8Unorm,
	     .Astc10x8UnormSrgb,
	     .Astc10x10Unorm,
	     .Astc10x10UnormSrgb,
	     .Astc12x10Unorm,
	     .Astc12x10UnormSrgb,
	     .Astc12x12Unorm,
	     .Astc12x12UnormSrgb:
		return 16

	case .Stencil8:
		return 1

	case .Depth16Unorm:
		return 2

	case .Depth32Float:
		return 4

	case .Depth24Plus:
		return 0

	case .Depth24PlusStencil8:
		if aspect_ok {
			#partial switch _aspect {
			case .DepthOnly:
				return 0
			case .StencilOnly:
				return 1
			}
		}
		return 0

	case .Depth32FloatStencil8:
		if aspect_ok {
			#partial switch _aspect {
			case .DepthOnly:
				return 4
			case .StencilOnly:
				return 1
			}
		}
		return 0
	}

	return 0
}

/* Calculate bytes per row from the given row width. */
texture_format_bytes_per_row :: proc "contextless" (
	format: TextureFormat,
	width: u32,
) -> (
	bytes_per_row: u32,
) {
	block_width, _ := texture_format_block_dimensions(format)
	block_size := texture_format_block_size(format)

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

/*
The number of bytes occupied per pixel in a color attachment
<https://gpuweb.github.io/gpuweb/#render-target-pixel-byte-cost>
*/
texture_format_target_pixel_byte_cost :: proc "contextless" (self: TextureFormat) -> u32 {
	#partial switch self {
	case .R8Unorm, .R8Uint, .R8Sint:
		return 1

	case .Rg8Unorm, .Rg8Uint, .Rg8Sint, .R16Uint, .R16Sint, .R16Float:
		return 2

	case .Rgba8Uint, .Rgba8Sint, .Rg16Uint, .Rg16Sint, .Rg16Float, .R32Uint, .R32Sint, .R32Float:
		return 4

	case .Rgba8Unorm,
	     .Rgba8UnormSrgb,
	     .Bgra8Unorm,
	     .Bgra8UnormSrgb,
	     .Rgba16Uint,
	     .Rgba16Sint,
	     .Rgba16Float,
	     .Rg32Uint,
	     .Rg32Sint,
	     .Rg32Float,
	     .Rgb10A2Uint,
	     .Rgb10A2Unorm,
	     .Rg11B10Ufloat:
		return 8

	case .Rgba32Uint, .Rgba32Sint, .Rgba32Float:
		return 16
	}

	return 0
}

/* See <https://gpuweb.github.io/gpuweb/#render-target-component-alignment> */
texture_format_target_component_alignment :: proc "contextless" (self: TextureFormat) -> u32 {
	#partial switch self {
	case .R8Unorm,
	     .R8Snorm,
	     .R8Uint,
	     .R8Sint,
	     .Rg8Unorm,
	     .Rg8Snorm,
	     .Rg8Uint,
	     .Rg8Sint,
	     .Rgba8Unorm,
	     .Rgba8UnormSrgb,
	     .Rgba8Snorm,
	     .Rgba8Uint,
	     .Rgba8Sint,
	     .Bgra8Unorm,
	     .Bgra8UnormSrgb:
		return 1

	case .R16Uint,
	     .R16Sint,
	     .R16Float,
	     .Rg16Uint,
	     .Rg16Sint,
	     .Rg16Float,
	     .Rgba16Uint,
	     .Rgba16Sint,
	     .Rgba16Float:
		return 2

	case .R32Uint,
	     .R32Sint,
	     .R32Float,
	     .Rg32Uint,
	     .Rg32Sint,
	     .Rg32Float,
	     .Rgba32Uint,
	     .Rgba32Sint,
	     .Rgba32Float,
	     .Rgb10A2Uint,
	     .Rgb10A2Unorm,
	     .Rg11B10Ufloat:
		return 4
	}

	return 0
}

/*
Returns the number of components this format has taking into account the `aspect`.

The `aspect` is only relevant for combined depth-stencil formats and multi-planar formats.
*/
texture_format_components_with_aspect :: proc "contextless" (
	self: TextureFormat,
	aspect: TextureAspect,
) -> u8 {
	#partial switch self {
	case .R8Unorm,
	     .R8Snorm,
	     .R8Uint,
	     .R8Sint,
	     .R16Unorm,
	     .R16Snorm,
	     .R16Uint,
	     .R16Sint,
	     .R16Float,
	     .R32Uint,
	     .R32Sint,
	     .R32Float:
		return 1

	case .Rg8Unorm,
	     .Rg8Snorm,
	     .Rg8Uint,
	     .Rg8Sint,
	     .Rg16Unorm,
	     .Rg16Snorm,
	     .Rg16Uint,
	     .Rg16Sint,
	     .Rg16Float,
	     .Rg32Uint,
	     .Rg32Sint,
	     .Rg32Float:
		return 2

	case .Rgba8Unorm,
	     .Rgba8UnormSrgb,
	     .Rgba8Snorm,
	     .Rgba8Uint,
	     .Rgba8Sint,
	     .Bgra8Unorm,
	     .Bgra8UnormSrgb,
	     .Rgba16Unorm,
	     .Rgba16Snorm,
	     .Rgba16Uint,
	     .Rgba16Sint,
	     .Rgba16Float,
	     .Rgba32Uint,
	     .Rgba32Sint,
	     .Rgba32Float,
	     .Rgb10A2Uint,
	     .Rgb10A2Unorm:
		return 4

	case .Rgb9E5Ufloat, .Rg11B10Ufloat:
		return 3

	case .Stencil8, .Depth16Unorm, .Depth24Plus, .Depth32Float:
		return 1

	case .Depth24PlusStencil8, .Depth32FloatStencil8:
		switch aspect {
		case .Undefined:
			return 0
		case .DepthOnly, .StencilOnly:
			return 1
		case .All:
			return 2
		}

	case .Bc4RUnorm, .Bc4RSnorm, .Eacr11Unorm, .Eacr11Snorm:
		return 1

	case .Bc5RgUnorm, .Bc5RgSnorm, .Eacrg11Unorm, .Eacrg11Snorm:
		return 2

	case .Bc6HrgbUfloat, .Bc6HrgbFloat, .Etc2Rgb8Unorm, .Etc2Rgb8UnormSrgb:
		return 3

	case .Bc1RgbaUnorm,
	     .Bc1RgbaUnormSrgb,
	     .Bc2RgbaUnorm,
	     .Bc2RgbaUnormSrgb,
	     .Bc3RgbaUnorm,
	     .Bc3RgbaUnormSrgb,
	     .Bc7RgbaUnorm,
	     .Bc7RgbaUnormSrgb,
	     .Etc2Rgb8A1Unorm,
	     .Etc2Rgb8A1UnormSrgb,
	     .Etc2Rgba8Unorm,
	     .Etc2Rgba8UnormSrgb,
	     .Astc4x4Unorm,
	     .Astc4x4UnormSrgb,
	     .Astc5x4Unorm,
	     .Astc5x4UnormSrgb,
	     .Astc5x5Unorm,
	     .Astc5x5UnormSrgb,
	     .Astc6x5Unorm,
	     .Astc6x5UnormSrgb,
	     .Astc6x6Unorm,
	     .Astc6x6UnormSrgb,
	     .Astc8x5Unorm,
	     .Astc8x5UnormSrgb,
	     .Astc8x6Unorm,
	     .Astc8x6UnormSrgb,
	     .Astc8x8Unorm,
	     .Astc8x8UnormSrgb,
	     .Astc10x5Unorm,
	     .Astc10x5UnormSrgb,
	     .Astc10x6Unorm,
	     .Astc10x6UnormSrgb,
	     .Astc10x8Unorm,
	     .Astc10x8UnormSrgb,
	     .Astc10x10Unorm,
	     .Astc10x10UnormSrgb,
	     .Astc12x10Unorm,
	     .Astc12x10UnormSrgb,
	     .Astc12x12Unorm,
	     .Astc12x12UnormSrgb:
		return 4
	}

	return 0
}

/* Returns the number of components this format has. */
texture_format_components :: proc "contextless" (self: TextureFormat) -> u8 {
	return texture_format_components_with_aspect(self, .All)
}

/* Strips the `Srgb` suffix from the given texture format. */
texture_format_remove_srgb_suffix :: proc "contextless" (
	self: TextureFormat,
) -> (
	ret: TextureFormat,
) {
	ret = self

	#partial switch self {
	case .Rgba8UnormSrgb:
		return .Rgba8Unorm
	case .Bgra8UnormSrgb:
		return .Bgra8Unorm
	case .Bc1RgbaUnormSrgb:
		return .Bc1RgbaUnorm
	case .Bc2RgbaUnormSrgb:
		return .Bc2RgbaUnorm
	case .Bc3RgbaUnormSrgb:
		return .Bc3RgbaUnorm
	case .Bc7RgbaUnormSrgb:
		return .Bc7RgbaUnorm
	case .Etc2Rgb8UnormSrgb:
		return .Etc2Rgb8Unorm
	case .Etc2Rgb8A1UnormSrgb:
		return .Etc2Rgb8A1Unorm
	case .Etc2Rgba8UnormSrgb:
		return .Etc2Rgba8Unorm
	case .Astc4x4UnormSrgb:
		return .Astc4x4Unorm
	case .Astc5x4UnormSrgb:
		return .Astc5x4Unorm
	case .Astc5x5UnormSrgb:
		return .Astc5x5Unorm
	case .Astc6x5UnormSrgb:
		return .Astc6x5Unorm
	case .Astc6x6UnormSrgb:
		return .Astc6x6Unorm
	case .Astc8x5UnormSrgb:
		return .Astc8x5Unorm
	case .Astc8x6UnormSrgb:
		return .Astc8x6Unorm
	case .Astc8x8UnormSrgb:
		return .Astc8x8Unorm
	case .Astc10x5UnormSrgb:
		return .Astc10x5Unorm
	case .Astc10x6UnormSrgb:
		return .Astc10x6Unorm
	case .Astc10x8UnormSrgb:
		return .Astc10x8Unorm
	case .Astc10x10UnormSrgb:
		return .Astc10x10Unorm
	case .Astc12x10UnormSrgb:
		return .Astc12x10Unorm
	case .Astc12x12UnormSrgb:
		return .Astc12x12Unorm
	}

	return
}

/* Adds an `Srgb` suffix to the given texture format, if the format supports it. */
texture_format_add_srgb_suffix :: proc "contextless" (
	self: TextureFormat,
) -> (
	ret: TextureFormat,
) {
	ret = self

	#partial switch self {
	case .Rgba8Unorm:
		return .Rgba8UnormSrgb
	case .Bgra8Unorm:
		return .Bgra8UnormSrgb
	case .Bc1RgbaUnorm:
		return .Bc1RgbaUnormSrgb
	case .Bc2RgbaUnorm:
		return .Bc2RgbaUnormSrgb
	case .Bc3RgbaUnorm:
		return .Bc3RgbaUnormSrgb
	case .Bc7RgbaUnorm:
		return .Bc7RgbaUnormSrgb
	case .Etc2Rgb8Unorm:
		return .Etc2Rgb8UnormSrgb
	case .Etc2Rgb8A1Unorm:
		return .Etc2Rgb8A1UnormSrgb
	case .Etc2Rgba8Unorm:
		return .Etc2Rgba8UnormSrgb
	case .Astc4x4Unorm:
		return .Astc4x4UnormSrgb
	case .Astc5x4Unorm:
		return .Astc5x4UnormSrgb
	case .Astc5x5Unorm:
		return .Astc5x5UnormSrgb
	case .Astc6x5Unorm:
		return .Astc6x5UnormSrgb
	case .Astc6x6Unorm:
		return .Astc6x6UnormSrgb
	case .Astc8x5Unorm:
		return .Astc8x5UnormSrgb
	case .Astc8x6Unorm:
		return .Astc8x6UnormSrgb
	case .Astc8x8Unorm:
		return .Astc8x8UnormSrgb
	case .Astc10x5Unorm:
		return .Astc10x5UnormSrgb
	case .Astc10x6Unorm:
		return .Astc10x6UnormSrgb
	case .Astc10x8Unorm:
		return .Astc10x8UnormSrgb
	case .Astc10x10Unorm:
		return .Astc10x10UnormSrgb
	case .Astc12x10Unorm:
		return .Astc12x10UnormSrgb
	case .Astc12x12Unorm:
		return .Astc12x12UnormSrgb
	}

	return
}

/* Returns `true` for srgb formats. */
texture_format_is_srgb :: proc "contextless" (self: TextureFormat) -> bool {
	return self != texture_format_remove_srgb_suffix(self)
}
