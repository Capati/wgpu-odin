package wgpu

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

/* Feature flags for a texture format.*/
TextureFormatFeatureFlags :: bit_set[TextureUsageFeature;Flags]

texture_format_feature_flags_sample_count_supported :: proc "contextless" (
	self: TextureFormatFeatureFlags,
	count: u32,
) -> bool {
	// odinfmt: disable
	switch count {
	case 1  : return true
	case 2  : return .MultisampleX2 in self
	case 4  : return .MultisampleX4 in self
	case 8  : return .MultisampleX8 in self
	case 16 : return .MultisampleX16 in self
	}
	// odinfmt: enable
	return false
}

sample_count_supported :: texture_format_feature_flags_sample_count_supported

texture_format_feature_flags_supported_sample_counts :: proc(
	self: TextureFormatFeatureFlags,
) -> (
	flags: MultisampleFlags,
) {
	if .MultisampleX2 in self {
		flags += {.X2}
	}
	if .MultisampleX4 in self {
		flags += {.X4}
	}
	if .MultisampleX8 in self {
		flags += {.X8}
	}
	if .MultisampleX16 in self {
		flags += {.X16}
	}
	return flags
}

supported_sample_counts :: texture_format_feature_flags_supported_sample_counts

/* Features supported by a given texture format */
Texture_Format_Features :: struct {
	allowed_usages: Texture_Usages,
	flags:          TextureFormatFeatureFlags,
}

/* ASTC block dimensions */
AstcBlock :: enum i32 {
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
AstcChannel :: enum i32 {
	Unorm,
	UnormSrgb,
	Hdr,
}

/*
Underlying texture data format.

If there is a conversion in the format (such as srgb -> linear), the conversion listed here is for
loading from texture in a shader.When writing to the texture, the opposite conversion takes place.

Corresponds to [WebGPU `GPUTextureFormat`](
https://gpuweb.github.io/gpuweb/#enumdef-gputextureformat).
*/
Texture_Format :: enum i32 {
	// WebGPU
	Undefined            = 0x00000000,
	R8Unorm              = 0x00000001,
	R8Snorm              = 0x00000002,
	R8Uint               = 0x00000003,
	R8Sint               = 0x00000004,
	R16Uint              = 0x00000005,
	R16Sint              = 0x00000006,
	R16Float             = 0x00000007,
	Rg8Unorm             = 0x00000008,
	Rg8Snorm             = 0x00000009,
	Rg8Uint              = 0x0000000A,
	Rg8Sint              = 0x0000000B,
	R32Float             = 0x0000000C,
	R32Uint              = 0x0000000D,
	R32Sint              = 0x0000000E,
	Rg16Uint             = 0x0000000F,
	Rg16Sint             = 0x00000010,
	Rg16Float            = 0x00000011,
	Rgba8Unorm           = 0x00000012,
	Rgba8UnormSrgb       = 0x00000013,
	Rgba8Snorm           = 0x00000014,
	Rgba8Uint            = 0x00000015,
	Rgba8Sint            = 0x00000016,
	Bgra8Unorm           = 0x00000017,
	Bgra8UnormSrgb       = 0x00000018,
	Rgb10a2Uint          = 0x00000019,
	Rgb10a2Unorm         = 0x0000001A,
	Rg11b10Ufloat        = 0x0000001B,
	Rgb9e5Ufloat         = 0x0000001C,
	Rg32Float            = 0x0000001D,
	Rg32Uint             = 0x0000001E,
	Rg32Sint             = 0x0000001F,
	Rgba16Uint           = 0x00000020,
	Rgba16Sint           = 0x00000021,
	Rgba16Float          = 0x00000022,
	Rgba32Float          = 0x00000023,
	Rgba32Uint           = 0x00000024,
	Rgba32Sint           = 0x00000025,
	Stencil8             = 0x00000026,
	Depth16Unorm         = 0x00000027,
	Depth24Plus          = 0x00000028,
	Depth24PlusStencil8  = 0x00000029,
	Depth32Float         = 0x0000002A,
	Depth32_Float_Stencil8 = 0x0000002B,
	Bc1RgbaUnorm         = 0x0000002C,
	Bc1RgbaUnormSrgb     = 0x0000002D,
	Bc2RgbaUnorm         = 0x0000002E,
	Bc2RgbaUnormSrgb     = 0x0000002F,
	Bc3RgbaUnorm         = 0x00000030,
	Bc3RgbaUnormSrgb     = 0x00000031,
	Bc4RUnorm            = 0x00000032,
	Bc4RSnorm            = 0x00000033,
	Bc5RgUnorm           = 0x00000034,
	Bc5RgSnorm           = 0x00000035,
	Bc6hRgbUfloat        = 0x00000036,
	Bc6hRgbFloat         = 0x00000037,
	Bc7RgbaUnorm         = 0x00000038,
	Bc7RgbaUnormSrgb     = 0x00000039,
	Etc2Rgb8Unorm        = 0x0000003A,
	Etc2Rgb8UnormSrgb    = 0x0000003B,
	Etc2Rgb8A1Unorm      = 0x0000003C,
	Etc2Rgb8A1UnormSrgb  = 0x0000003D,
	Etc2Rgba8Unorm       = 0x0000003E,
	Etc2Rgba8UnormSrgb   = 0x0000003F,
	EacR11Unorm          = 0x00000040,
	EacR11Snorm          = 0x00000041,
	EacRg11Unorm         = 0x00000042,
	EacRg11Snorm         = 0x00000043,
	Astc4x4Unorm         = 0x00000044,
	Astc4x4UnormSrgb     = 0x00000045,
	Astc5x4Unorm         = 0x00000046,
	Astc5x4UnormSrgb     = 0x00000047,
	Astc5x5Unorm         = 0x00000048,
	Astc5x5UnormSrgb     = 0x00000049,
	Astc6x5Unorm         = 0x0000004A,
	Astc6x5UnormSrgb     = 0x0000004B,
	Astc6x6Unorm         = 0x0000004C,
	Astc6x6UnormSrgb     = 0x0000004D,
	Astc8x5Unorm         = 0x0000004E,
	Astc8x5UnormSrgb     = 0x0000004F,
	Astc8x6Unorm         = 0x00000050,
	Astc8x6UnormSrgb     = 0x00000051,
	Astc8x8Unorm         = 0x00000052,
	Astc8x8UnormSrgb     = 0x00000053,
	Astc10x5Unorm        = 0x00000054,
	Astc10x5UnormSrgb    = 0x00000055,
	Astc10x6Unorm        = 0x00000056,
	Astc10x6UnormSrgb    = 0x00000057,
	Astc10x8Unorm        = 0x00000058,
	Astc10x8UnormSrgb    = 0x00000059,
	Astc10x10Unorm       = 0x0000005A,
	Astc10x10UnormSrgb   = 0x0000005B,
	Astc12x10Unorm       = 0x0000005C,
	Astc12x10UnormSrgb   = 0x0000005D,
	Astc12x12Unorm       = 0x0000005E,
	Astc12x12UnormSrgb   = 0x0000005F,

	// Native
	R16Unorm             = 0x00030001,
	R16Snorm             = 0x00030002,
	Rg16Unorm            = 0x00030003,
	Rg16Snorm            = 0x00030004,
	Rgba16Unorm          = 0x00030005,
	Rgba16Snorm          = 0x00030006,
	NV12                 = 0x00030007,
}

/*
Returns the aspect-specific format of the original format

see <https://gpuweb.github.io/gpuweb/#abstract-opdef-resolving-gputextureaspect>
*/
texture_format_aspect_specific_format :: proc(
	self: Texture_Format,
	aspect: Texture_Aspect,
) -> Maybe(Texture_Format) {
	#partial switch self {
	case .Stencil8:
		if aspect == .Stencil_Only {
			return self
		}
	case .Depth16Unorm, .Depth24Plus, .Depth32Float:
		if aspect == .Depth_Only {
			return self
		}
	case .Depth24PlusStencil8:
		#partial switch aspect {
		case .Stencil_Only:
			return .Stencil8
		case .Depth_Only:
			return .Depth24Plus
		}
	case .Depth32_Float_Stencil8:
		#partial switch aspect {
		case .Stencil_Only:
			return .Stencil8
		case .Depth_Only:
			return .Depth32Float
		}
	case .NV12:
		#partial switch aspect {
		case .Plane0:
			return .R8Unorm
		case .Plane1:
			return .Rg8Unorm
		}
	}

	// Views to multi-planar formats must specify the plane
	if aspect == .All && !texture_format_is_multi_planar_format(self) {
		return self
	}

	return .Undefined
}

/*
Check if the format is a depth or stencil component of the given combined depth-stencil format.
*/
texture_format_is_depth_stencil_component :: proc "contextless" (
	self, combined_format: Texture_Format,
) -> bool {
	return(
		combined_format == .Depth24PlusStencil8 && (self == .Depth24Plus || self == .Stencil8) ||
		combined_format == .Depth32_Float_Stencil8 && (self == .Depth32Float || self == .Stencil8) \
	)
}

/*
Check if the format is a depth and/or stencil format.

see <https://gpuweb.github.io/gpuweb/#depth-formats>
*/
texture_format_is_depth_stencil_format :: proc "contextless" (self: Texture_Format) -> bool {
	#partial switch self {
	case .Stencil8,
	     .Depth16Unorm,
	     .Depth24Plus,
	     .Depth24PlusStencil8,
	     .Depth32Float,
	     .Depth32_Float_Stencil8:
		return true
	}

	return false
}

/*
Returns `true` if the format is a combined depth-stencil format

see <https://gpuweb.github.io/gpuweb/#combined-depth-stencil-format>
*/
texture_format_is_combined_depth_stencil_format :: proc "contextless" (
	self: Texture_Format,
) -> bool {
	#partial switch self {
	case .Depth24PlusStencil8, .Depth32_Float_Stencil8:
		return true
	}

	return false
}


/* Returns `true` if the format is a multi-planar format.*/
texture_format_is_multi_planar_format :: proc "contextless" (self: Texture_Format) -> bool {
	return texture_format_planes(self) > 1
}

/* Returns the number of planes a multi-planar format has.*/
texture_format_planes :: proc "contextless" (self: Texture_Format) -> u32 {
	#partial switch self {
	case .NV12:
		return 2
	}
	return 0
}

/* Returns `true` if the format has a color aspect.*/
texture_format_has_color_aspect :: proc "contextless" (self: Texture_Format) -> bool {
	return !texture_format_is_depth_stencil_format(self)
}

/* Returns `true` if the format has a depth aspect.*/
texture_format_has_depth_aspect :: proc "contextless" (self: Texture_Format) -> bool {
	#partial switch self {
	case .Depth16Unorm, .Depth24Plus, .Depth24PlusStencil8, .Depth32Float, .Depth32_Float_Stencil8:
		return true
	}
	return false
}

/* Returns `true` if the format has a stencil aspect.*/
texture_format_has_stencil_aspect :: proc "contextless" (self: Texture_Format) -> bool {
	#partial switch self {
	case .Stencil8, .Depth24PlusStencil8, .Depth32_Float_Stencil8:
		return true
	}
	return false
}

/* Returns the size multiple requirement for a texture using this format.*/
texture_format_size_multiple_requirement :: proc(self: Texture_Format) -> (u32, u32) {
	#partial switch self {
	case .NV12:
		return 2, 2
	}
	return texture_format_block_dimensions(self)
}

/*
Returns the dimension of a [block](https://gpuweb.github.io/gpuweb/#texel-block) of texels.

Uncompressed formats have a block dimension of `(1, 1)`.
*/
texture_format_block_dimensions :: proc "contextless" (self: Texture_Format) -> (w, h: u32) {
	// odinfmt: disable
	switch self {
	case .R8Unorm, .R8Snorm, .R8Uint, .R8Sint, .R16Uint, .R16Sint, .R16Unorm, .R16Snorm,
	     .R16Float, .Rg8Unorm, .Rg8Snorm, .Rg8Uint, .Rg8Sint, .R32Uint, .R32Sint, .R32Float,
	     .Rg16Uint, .Rg16Sint, .Rg16Unorm, .Rg16Snorm, .Rg16Float, .Rgba8Unorm, .Rgba8UnormSrgb,
	     .Rgba8Snorm, .Rgba8Uint, .Rgba8Sint, .Bgra8Unorm, .Bgra8UnormSrgb, .Rgb9e5Ufloat,
	     .Rgb10a2Uint, .Rgb10a2Unorm, .Rg11b10Ufloat, .Rg32Uint, .Rg32Sint, .Rg32Float, .Rgba16Uint,
	     .Rgba16Sint, .Rgba16Unorm, .Rgba16Snorm, .Rgba16Float, .Rgba32Uint, .Rgba32Sint,
	     .Rgba32Float, .Stencil8, .Depth16Unorm, .Depth24Plus, .Depth24PlusStencil8,
	     .Depth32Float, .Depth32_Float_Stencil8, .NV12:
		return 1, 1

	case .Bc1RgbaUnorm, .Bc1RgbaUnormSrgb, .Bc2RgbaUnorm, .Bc2RgbaUnormSrgb, .Bc3RgbaUnorm,
		 .Bc3RgbaUnormSrgb, .Bc4RUnorm, .Bc4RSnorm, .Bc5RgUnorm, .Bc5RgSnorm, .Bc6hRgbUfloat,
	     .Bc6hRgbFloat, .Bc7RgbaUnorm, .Bc7RgbaUnormSrgb, .Etc2Rgb8Unorm, .Etc2Rgb8UnormSrgb,
		 .Etc2Rgb8A1Unorm, .Etc2Rgb8A1UnormSrgb, .Etc2Rgba8Unorm, .Etc2Rgba8UnormSrgb,
	     .EacR11Unorm, .EacR11Snorm, .EacRg11Unorm, .EacRg11Snorm:
		return 4, 4

	case .Astc4x4Unorm, .Astc4x4UnormSrgb: return 4, 4
	case .Astc5x4Unorm, .Astc5x4UnormSrgb: return 5, 5
	case .Astc5x5Unorm, .Astc5x5UnormSrgb: return 5, 5
	case .Astc6x5Unorm, .Astc6x5UnormSrgb: return 6, 5
	case .Astc6x6Unorm, .Astc6x6UnormSrgb: return 6, 6
	case .Astc8x5Unorm, .Astc8x5UnormSrgb: return 8, 5
	case .Astc8x6Unorm, .Astc8x6UnormSrgb: return 8, 6
	case .Astc8x8Unorm, .Astc8x8UnormSrgb: return 8, 8
	case .Astc10x5Unorm, .Astc10x5UnormSrgb: return 10, 5
	case .Astc10x6Unorm, .Astc10x6UnormSrgb: return 10, 6
	case .Astc10x8Unorm, .Astc10x8UnormSrgb: return 10, 8
	case .Astc10x10Unorm, .Astc10x10UnormSrgb: return 10, 10
	case .Astc12x10Unorm, .Astc12x10UnormSrgb: return 12, 10
	case .Astc12x12Unorm, .Astc12x12UnormSrgb: return 12, 12
	case .Undefined:
		return 1, 1
	}
	// odinfmt: enable
	return 1, 1
}

/* Returns `true` for compressed formats.*/
texture_format_is_compressed :: proc "contextless" (self: Texture_Format) -> bool {
	w, h := texture_format_block_dimensions(self)
	return w != 1 && h != 1
}

/* Returns `true` for BCn compressed formats.*/
texture_format_is_bcn :: proc "contextless" (self: Texture_Format) -> bool {
	features := texture_format_required_features(self)
	return .Texture_Compression_BC in features
}

/* Returns the required features (if any) in order to use the texture.*/
texture_format_required_features :: proc "contextless" (self: Texture_Format) -> Features {
	// odinfmt: disable
	switch self {
	case .R8Unorm, .R8Snorm, .R8Uint, .R8Sint, .R16Uint, .R16Sint, .R16Float, .Rg8Unorm,
	     .Rg8Snorm, .Rg8Uint, .Rg8Sint, .R32Float, .R32Uint, .R32Sint, .Rg16Uint,
	     .Rg16Sint, .Rg16Float, .Rgba8Unorm, .Rgba8UnormSrgb, .Rgba8Snorm, .Rgba8Uint, .Rgba8Sint,
	     .Bgra8Unorm, .Bgra8UnormSrgb, .Rgb10a2Uint, .Rgb10a2Unorm, .Rg11b10Ufloat, .Rgb9e5Ufloat,
	     .Rg32Float, .Rg32Uint, .Rg32Sint, .Rgba16Uint, .Rgba16Sint, .Rgba16Float, .Rgba32Float,
	     .Rgba32Uint, .Rgba32Sint, .Stencil8, .Depth16Unorm, .Depth24Plus, .Depth24PlusStencil8,
	     .Depth32Float:
		return {} // empty, no features need

	case .Depth32_Float_Stencil8:
		return {.Depth32_Float_Stencil8}

	case .NV12:
		return {.Texture_Format_NV12}

	case .R16Unorm, .R16Snorm, .Rg16Unorm, .Rg16Snorm, .Rgba16Unorm, .Rgba16Snorm:
		return {.Texture_Format16bit_Norm}

	case .Bc1RgbaUnorm, .Bc1RgbaUnormSrgb, .Bc2RgbaUnorm, .Bc2RgbaUnormSrgb, .Bc3RgbaUnorm,
	     .Bc3RgbaUnormSrgb, .Bc4RUnorm, .Bc4RSnorm, .Bc5RgUnorm, .Bc5RgSnorm, .Bc6hRgbUfloat,
	     .Bc6hRgbFloat, .Bc7RgbaUnorm, .Bc7RgbaUnormSrgb:
		return {.Texture_Compression_BC}

	case .Etc2Rgb8Unorm, .Etc2Rgb8UnormSrgb, .Etc2Rgb8A1Unorm, .Etc2Rgb8A1UnormSrgb,
		 .Etc2Rgba8Unorm, .Etc2Rgba8UnormSrgb, .EacR11Unorm, .EacR11Snorm, .EacRg11Unorm,
	     .EacRg11Snorm:
		return {.Texture_Compression_ETC2}

	case .Astc4x4Unorm, .Astc4x4UnormSrgb, .Astc5x4Unorm, .Astc5x4UnormSrgb, .Astc5x5Unorm,
		 .Astc5x5UnormSrgb, .Astc6x5Unorm, .Astc6x5UnormSrgb, .Astc6x6Unorm, .Astc6x6UnormSrgb,
		 .Astc8x5Unorm, .Astc8x5UnormSrgb, .Astc8x6Unorm, .Astc8x6UnormSrgb, .Astc8x8Unorm,
	     .Astc8x8UnormSrgb, .Astc10x5Unorm, .Astc10x5UnormSrgb, .Astc10x6Unorm, .Astc10x6UnormSrgb,
	     .Astc10x8Unorm, .Astc10x8UnormSrgb, .Astc10x10Unorm, .Astc10x10UnormSrgb,
	     .Astc12x10Unorm, .Astc12x10UnormSrgb, .Astc12x12Unorm, .Astc12x12UnormSrgb:
		return {.Texture_Compression_ASTC}
	case .Undefined:
		return {}
	}
	// odinfmt: enable
	return {}
}

/*
Returns the format features guaranteed by the WebGPU spec.

Additional features are available if `Features.Texture_Adapter_Specific_Format_Features` is enabled.
*/
texture_format_guaranteed_format_features :: proc "contextless" (
	self: Texture_Format,
	device_features: Features,
) -> (
	features: Texture_Format_Features,
) {
	// Multisampling
	noaa: TextureFormatFeatureFlags
	msaa: TextureFormatFeatureFlags = {.MultisampleX4}
	msaa_resolve: TextureFormatFeatureFlags = msaa + {.MultisampleResolve}

	// Flags
	basic: Texture_Usages = {.Copy_Src, .Copy_Dst, .Texture_Binding}
	attachment: Texture_Usages = basic + {.Render_Attachment}
	storage: Texture_Usages = basic + {.Storage_Binding}
	binding: Texture_Usages = {.Texture_Binding}
	all_flags := TEXTURE_USAGES_ALL
	rg11b10f := attachment if .RG11B10_Ufloat_Renderable in device_features else basic
	bgra8unorm := attachment + storage if .BGRA8_Unorm_Storage in device_features else attachment

	flags: TextureFormatFeatureFlags
	allowed_usages: Texture_Usages

	// odinfmt: disable
	switch self {
	case .R8Unorm: flags = msaa_resolve; allowed_usages = attachment
	case .R8Snorm: flags = noaa; allowed_usages = basic
	case .R8Uint: flags = msaa; allowed_usages = attachment
	case .R8Sint: flags = msaa; allowed_usages = attachment
	case .R16Uint: flags = msaa; allowed_usages = attachment
	case .R16Sint: flags = msaa; allowed_usages = attachment
	case .R16Float: flags = msaa_resolve; allowed_usages = attachment
	case .Rg8Unorm: flags = msaa_resolve; allowed_usages = attachment
	case .Rg8Snorm: flags = noaa; allowed_usages = basic
	case .Rg8Uint: flags = msaa; allowed_usages = attachment
	case .Rg8Sint: flags = msaa; allowed_usages = attachment
	case .R32Uint: flags = noaa; allowed_usages = all_flags
	case .R32Sint: flags = noaa; allowed_usages = all_flags
	case .R32Float: flags = msaa; allowed_usages = all_flags
	case .Rg16Uint: flags = msaa; allowed_usages = attachment
	case .Rg16Sint: flags = msaa; allowed_usages = attachment
	case .Rg16Float: flags = msaa_resolve; allowed_usages = attachment
	case .Rgba8Unorm: flags = msaa_resolve; allowed_usages = all_flags
	case .Rgba8UnormSrgb: flags = msaa_resolve; allowed_usages = attachment
	case .Rgba8Snorm: flags = noaa; allowed_usages = storage
	case .Rgba8Uint: flags = msaa; allowed_usages = all_flags
	case .Rgba8Sint: flags = msaa; allowed_usages = all_flags
	case .Bgra8Unorm: flags = msaa_resolve; allowed_usages = bgra8unorm
	case .Bgra8UnormSrgb: flags = msaa_resolve; allowed_usages = attachment
	case .Rgb10a2Uint: flags = msaa; allowed_usages = attachment
	case .Rgb10a2Unorm: flags = msaa_resolve; allowed_usages = attachment
	case .Rg11b10Ufloat: flags = msaa; allowed_usages = rg11b10f
	case .Rg32Uint: flags = noaa; allowed_usages = all_flags
	case .Rg32Sint: flags = noaa; allowed_usages = all_flags
	case .Rg32Float: flags = noaa; allowed_usages = all_flags
	case .Rgba16Uint: flags = msaa; allowed_usages = all_flags
	case .Rgba16Sint: flags = msaa; allowed_usages = all_flags
	case .Rgba16Float: flags = msaa_resolve; allowed_usages = all_flags
	case .Rgba32Uint: flags = noaa; allowed_usages = all_flags
	case .Rgba32Sint: flags = noaa; allowed_usages = all_flags
	case .Rgba32Float: flags = noaa; allowed_usages = all_flags
	case .Stencil8: flags = msaa; allowed_usages = attachment
	case .Depth16Unorm: flags = msaa; allowed_usages = attachment
	case .Depth24Plus: flags = msaa; allowed_usages = attachment
	case .Depth24PlusStencil8: flags = msaa; allowed_usages = attachment
	case .Depth32Float: flags = msaa; allowed_usages = attachment
	case .Depth32_Float_Stencil8: flags = msaa; allowed_usages = attachment
	case .NV12: flags = noaa; allowed_usages = binding
	case .R16Unorm: flags = msaa; allowed_usages = storage
	case .R16Snorm: flags = msaa; allowed_usages = storage
	case .Rg16Unorm: flags = msaa; allowed_usages = storage
	case .Rg16Snorm: flags = msaa; allowed_usages = storage
	case .Rgba16Unorm: flags = msaa; allowed_usages = storage
	case .Rgba16Snorm: flags = msaa; allowed_usages = storage
	case .Rgb9e5Ufloat: flags = noaa; allowed_usages = basic
	case .Bc1RgbaUnorm: flags = noaa; allowed_usages = basic
	case .Bc1RgbaUnormSrgb: flags = noaa; allowed_usages = basic
	case .Bc2RgbaUnorm: flags = noaa; allowed_usages = basic
	case .Bc2RgbaUnormSrgb: flags = noaa; allowed_usages = basic
	case .Bc3RgbaUnorm: flags = noaa; allowed_usages = basic
	case .Bc3RgbaUnormSrgb: flags = noaa; allowed_usages = basic
	case .Bc4RUnorm: flags = noaa; allowed_usages = basic
	case .Bc4RSnorm: flags = noaa; allowed_usages = basic
	case .Bc5RgUnorm: flags = noaa; allowed_usages = basic
	case .Bc5RgSnorm: flags = noaa; allowed_usages = basic
	case .Bc6hRgbUfloat: flags = noaa; allowed_usages = basic
	case .Bc6hRgbFloat: flags = noaa; allowed_usages = basic
	case .Bc7RgbaUnorm: flags = noaa; allowed_usages = basic
	case .Bc7RgbaUnormSrgb: flags = noaa; allowed_usages = basic
	case .Etc2Rgb8Unorm: flags = noaa; allowed_usages = basic
	case .Etc2Rgb8UnormSrgb: flags = noaa; allowed_usages = basic
	case .Etc2Rgb8A1Unorm: flags = noaa; allowed_usages = basic
	case .Etc2Rgb8A1UnormSrgb: flags = noaa; allowed_usages = basic
	case .Etc2Rgba8Unorm: flags = noaa; allowed_usages = basic
	case .Etc2Rgba8UnormSrgb: flags = noaa; allowed_usages = basic
	case .EacR11Unorm: flags = noaa; allowed_usages = basic
	case .EacR11Snorm: flags = noaa; allowed_usages = basic
	case .EacRg11Unorm: flags = noaa; allowed_usages = basic
	case .EacRg11Snorm: flags = noaa; allowed_usages = basic
	case .Astc4x4Unorm, .Astc4x4UnormSrgb, .Astc5x4Unorm, .Astc5x4UnormSrgb, .Astc5x5Unorm,
		 .Astc5x5UnormSrgb, .Astc6x5Unorm, .Astc6x5UnormSrgb, .Astc6x6Unorm, .Astc6x6UnormSrgb,
		 .Astc8x5Unorm, .Astc8x5UnormSrgb, .Astc8x6Unorm, .Astc8x6UnormSrgb, .Astc8x8Unorm,
	     .Astc8x8UnormSrgb, .Astc10x5Unorm, .Astc10x5UnormSrgb, .Astc10x6Unorm, .Astc10x6UnormSrgb,
	     .Astc10x8Unorm, .Astc10x8UnormSrgb, .Astc10x10Unorm, .Astc10x10UnormSrgb,
	     .Astc12x10Unorm, .Astc12x10UnormSrgb, .Astc12x12Unorm, .Astc12x12UnormSrgb:
		flags = noaa; allowed_usages = basic
	case .Undefined:
		unreachable()
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
	// odinfmt: enable

	return
}
/*
Returns the sample type compatible with this format and aspect.

Returns `Undefined` only if this is a combined depth-stencil format or a multi-planar format
and `Texture_Aspect.All`.
*/
texture_format_sample_type :: proc "contextless" (
	self: Texture_Format,
	aspect: Maybe(Texture_Aspect) = nil,
	device_features: Features = {},
) -> Texture_Sample_Type {
	float_filterable := Texture_Sample_Type.Float
	unfilterable_float := Texture_Sample_Type.Unfilterable_Float
	float32_sample_type := Texture_Sample_Type.Unfilterable_Float
	if .Float32_Filterable in device_features {
		float32_sample_type = .Float
	}
	depth := Texture_Sample_Type.Depth
	_uint := Texture_Sample_Type.Uint
	sint := Texture_Sample_Type.Sint

	_aspect, aspect_ok := aspect.?

	// odinfmt: disable
	switch self {
	case .R8Unorm, .R8Snorm, .Rg8Unorm, .Rg8Snorm, .Rgba8Unorm, .Rgba8UnormSrgb, .Rgba8Snorm,
	     .Bgra8Unorm, .Bgra8UnormSrgb, .R16Float, .Rg16Float, .Rgba16Float, .Rgb10a2Unorm,
	     .Rg11b10Ufloat:
		return float_filterable

	case .R32Float, .Rg32Float, .Rgba32Float:
		return float32_sample_type

	case .R8Uint, .Rg8Uint, .Rgba8Uint, .R16Uint, .Rg16Uint, .Rgba16Uint, .R32Uint,
	     .Rg32Uint, .Rgba32Uint, .Rgb10a2Uint:
		return _uint

	case .R8Sint, .Rg8Sint, .Rgba8Sint, .R16Sint, .Rg16Sint, .Rgba16Sint, .R32Sint,
	     .Rg32Sint, .Rgba32Sint:
		return sint

	case .Stencil8:
		return _uint

	case .Depth16Unorm, .Depth24Plus, .Depth32Float:
		return depth

	case .Depth24PlusStencil8, .Depth32_Float_Stencil8:
		if aspect_ok {
			if _aspect == .Depth_Only {
				return depth
			}
			if _aspect == .Stencil_Only {
				return _uint
			}
		}
		return .Undefined

	case .NV12:
		if aspect_ok {
			if _aspect == .Plane0 || _aspect == .Plane1 {
				return unfilterable_float
			}
		}
		return .Undefined

	case .R16Unorm, .R16Snorm, .Rg16Unorm, .Rg16Snorm, .Rgba16Unorm, .Rgba16Snorm:
		return float_filterable

	case .Rgb9e5Ufloat, .Bc1RgbaUnorm, .Bc1RgbaUnormSrgb, .Bc2RgbaUnorm, .Bc2RgbaUnormSrgb,
		 .Bc3RgbaUnorm, .Bc3RgbaUnormSrgb, .Bc4RUnorm, .Bc4RSnorm, .Bc5RgUnorm, .Bc5RgSnorm,
	     .Bc6hRgbUfloat, .Bc6hRgbFloat, .Bc7RgbaUnorm, .Bc7RgbaUnormSrgb, .Etc2Rgb8Unorm,
		 .Etc2Rgb8UnormSrgb, .Etc2Rgb8A1Unorm, .Etc2Rgb8A1UnormSrgb, .Etc2Rgba8Unorm,
		 .Etc2Rgba8UnormSrgb, .EacR11Unorm, .EacR11Snorm, .EacRg11Unorm, .EacRg11Snorm,
	     .Astc4x4Unorm, .Astc4x4UnormSrgb, .Astc5x4Unorm, .Astc5x4UnormSrgb, .Astc5x5Unorm,
	     .Astc5x5UnormSrgb, .Astc6x5Unorm, .Astc6x5UnormSrgb, .Astc6x6Unorm, .Astc6x6UnormSrgb,
	     .Astc8x5Unorm, .Astc8x5UnormSrgb, .Astc8x6Unorm, .Astc8x6UnormSrgb, .Astc8x8Unorm,
	     .Astc8x8UnormSrgb, .Astc10x5Unorm, .Astc10x5UnormSrgb, .Astc10x6Unorm, .Astc10x6UnormSrgb,
	     .Astc10x8Unorm, .Astc10x8UnormSrgb, .Astc10x10Unorm, .Astc10x10UnormSrgb, .Astc12x10Unorm,
	     .Astc12x10UnormSrgb, .Astc12x12Unorm, .Astc12x12UnormSrgb:
		return float_filterable
	case .Undefined:
		return .Undefined
	}
	// odinfmt: enable
	return .Undefined
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
	self: Texture_Format,
	aspect: Maybe(Texture_Aspect) = nil,
) -> u32 {
	_aspect, aspect_ok := aspect.?

	// odinfmt: disable
	switch self {
	case .R8Unorm, .R8Snorm, .R8Uint, .R8Sint: return 1

	case .Rg8Unorm, .Rg8Snorm, .Rg8Uint, .Rg8Sint: return 2
	case .R16Unorm, .R16Snorm, .R16Uint, .R16Sint, .R16Float: return 2

	case .Rgba8Unorm,.Rgba8UnormSrgb,.Rgba8Snorm,.Rgba8Uint,.Rgba8Sint,.Bgra8Unorm,.Bgra8UnormSrgb:
		return 4
	case .Rg16Unorm, .Rg16Snorm, .Rg16Uint, .Rg16Sint, .Rg16Float: return 4
	case .R32Uint, .R32Sint, .R32Float: return 4
	case .Rgb9e5Ufloat, .Rgb10a2Uint, .Rgb10a2Unorm, .Rg11b10Ufloat: return 4

	case .Rgba16Unorm, .Rgba16Snorm, .Rgba16Uint, .Rgba16Sint, .Rgba16Float: return 8
	case .Rg32Uint, .Rg32Sint, .Rg32Float: return 8

	case .Rgba32Uint, .Rgba32Sint, .Rgba32Float: return 16

	case .Stencil8: return 1
	case .Depth16Unorm: return 2
	case .Depth32Float: return 4
	case .Depth24Plus: return 0

	case .Depth24PlusStencil8:
		if aspect_ok {
			#partial switch _aspect {
			case .Stencil_Only: return 1
			}
		}
		return 0

	case .Depth32_Float_Stencil8:
		if aspect_ok {
			#partial switch _aspect {
			case .Depth_Only: return 4
			case .Stencil_Only: return 1
			}
		}
		return 0

	case .NV12:
		if aspect_ok {
			#partial switch _aspect {
			case .Plane0: return 1
			case .Plane1: return 2
			}
		}
		return 0

	case .Bc1RgbaUnorm, .Bc1RgbaUnormSrgb, .Bc4RUnorm, .Bc4RSnorm: return 8

	case .Bc2RgbaUnorm, .Bc2RgbaUnormSrgb, .Bc3RgbaUnorm, .Bc3RgbaUnormSrgb, .Bc5RgUnorm,
		 .Bc5RgSnorm, .Bc6hRgbUfloat, .Bc6hRgbFloat, .Bc7RgbaUnorm, .Bc7RgbaUnormSrgb: return 16

	case .Etc2Rgb8Unorm, .Etc2Rgb8UnormSrgb, .Etc2Rgb8A1Unorm, .Etc2Rgb8A1UnormSrgb, .EacR11Unorm,
		 .EacR11Snorm: return 8
	case .Etc2Rgba8Unorm, .Etc2Rgba8UnormSrgb, .EacRg11Unorm, .EacRg11Snorm: return 16

	case .Astc4x4Unorm, .Astc4x4UnormSrgb, .Astc5x4Unorm, .Astc5x4UnormSrgb, .Astc5x5Unorm,
	     .Astc5x5UnormSrgb, .Astc6x5Unorm, .Astc6x5UnormSrgb, .Astc6x6Unorm, .Astc6x6UnormSrgb,
	     .Astc8x5Unorm, .Astc8x5UnormSrgb, .Astc8x6Unorm, .Astc8x6UnormSrgb, .Astc8x8Unorm,
	     .Astc8x8UnormSrgb, .Astc10x5Unorm, .Astc10x5UnormSrgb, .Astc10x6Unorm, .Astc10x6UnormSrgb,
	     .Astc10x8Unorm, .Astc10x8UnormSrgb, .Astc10x10Unorm, .Astc10x10UnormSrgb, .Astc12x10Unorm,
	     .Astc12x10UnormSrgb, .Astc12x12Unorm, .Astc12x12UnormSrgb:
		return 16
	case .Undefined:
		return 0
	}
	// odinfmt: enable
	return 0
}

/*
The number of bytes occupied per pixel in a color attachment
<https://gpuweb.github.io/gpuweb/#render-target-pixel-byte-cost>
*/
texture_format_target_pixel_byte_cost :: proc "contextless" (self: Texture_Format) -> u32 {
	// odinfmt: disable
	switch self {
	case .R8Unorm, .R8Snorm, .R8Uint, .R8Sint: return 1

	case .Rg8Unorm,.Rg8Snorm,.Rg8Uint,.Rg8Sint,.R16Uint,.R16Sint,.R16Unorm,.R16Snorm,.R16Float:
		return 2

	case .Rgba8Uint, .Rgba8Sint, .Rg16Uint, .Rg16Sint, .Rg16Unorm, .Rg16Snorm, .Rg16Float,
		 .R32Uint, .R32Sint, .R32Float: return 4

	case .Rgba8Unorm, .Rgba8UnormSrgb, .Rgba8Snorm, .Bgra8Unorm, .Bgra8UnormSrgb, .Rgba16Uint,
	     .Rgba16Sint, .Rgba16Unorm, .Rgba16Snorm, .Rgba16Float, .Rg32Uint, .Rg32Sint, .Rg32Float,
		 .Rgb10a2Uint, .Rgb10a2Unorm, .Rg11b10Ufloat:
		return 8

	case .Rgba32Uint, .Rgba32Sint, .Rgba32Float:
		return 16

	case .Stencil8, .Depth16Unorm, .Depth24Plus, .Depth24PlusStencil8, .Depth32Float,
		 .Depth32_Float_Stencil8, .NV12, .Rgb9e5Ufloat, .Bc1RgbaUnorm, .Bc1RgbaUnormSrgb,
		 .Bc2RgbaUnorm, .Bc2RgbaUnormSrgb, .Bc3RgbaUnorm, .Bc3RgbaUnormSrgb, .Bc4RUnorm,
		 .Bc4RSnorm, .Bc5RgUnorm, .Bc5RgSnorm, .Bc6hRgbUfloat, .Bc6hRgbFloat, .Bc7RgbaUnorm,
		 .Bc7RgbaUnormSrgb, .Etc2Rgb8Unorm, .Etc2Rgb8UnormSrgb, .Etc2Rgb8A1Unorm,
		 .Etc2Rgb8A1UnormSrgb, .Etc2Rgba8Unorm, .Etc2Rgba8UnormSrgb, .EacR11Unorm, .EacR11Snorm,
		 .EacRg11Unorm, .EacRg11Snorm, .Astc4x4Unorm, .Astc4x4UnormSrgb, .Astc5x4Unorm,
		 .Astc5x4UnormSrgb, .Astc5x5Unorm, .Astc5x5UnormSrgb, .Astc6x5Unorm, .Astc6x5UnormSrgb,
		 .Astc6x6Unorm, .Astc6x6UnormSrgb, .Astc8x5Unorm, .Astc8x5UnormSrgb, .Astc8x6Unorm,
		 .Astc8x6UnormSrgb, .Astc8x8Unorm, .Astc8x8UnormSrgb, .Astc10x5Unorm, .Astc10x5UnormSrgb,
		 .Astc10x6Unorm, .Astc10x6UnormSrgb, .Astc10x8Unorm, .Astc10x8UnormSrgb, .Astc10x10Unorm,
		 .Astc10x10UnormSrgb, .Astc12x10Unorm, .Astc12x10UnormSrgb, .Astc12x12Unorm,
		 .Astc12x12UnormSrgb:
		return 0

	case .Undefined: return 0
	}
	// odinfmt: enable
	return 0
}

/* See <https://gpuweb.github.io/gpuweb/#render-target-component-alignment> */
texture_format_target_component_alignment :: proc "contextless" (self: Texture_Format) -> u32 {
	// odinfmt: disable
	switch self {
	case .R8Unorm, .R8Snorm, .R8Uint, .R8Sint, .Rg8Unorm, .Rg8Snorm, .Rg8Uint, .Rg8Sint,
	  	 .Rgba8Unorm, .Rgba8UnormSrgb, .
		 Rgba8Snorm, .Rgba8Uint, .Rgba8Sint, .Bgra8Unorm,
		 .Bgra8UnormSrgb: return 1
	case .R16Uint, .R16Sint, .R16Unorm, .R16Snorm, .R16Float, .Rg16Uint, .Rg16Sint,
		 .Rg16Unorm, .Rg16Snorm, .Rg16Float, .Rgba16Uint, .Rgba16Sint, .Rgba16Unorm,
	 	 .Rgba16Snorm, .Rgba16Float: return 2

	case .R32Uint, .R32Sint, .R32Float, .Rg32Uint, .Rg32Sint, .Rg32Float, .Rgba32Uint,
		 .Rgba32Sint, .Rgba32Float, .Rgb10a2Uint, .Rgb10a2Unorm, .Rg11b10Ufloat: return 4

	case .Stencil8, .Depth16Unorm, .Depth24Plus, .Depth24PlusStencil8, .Depth32Float,
		 .Depth32_Float_Stencil8, .NV12, .Rgb9e5Ufloat, .Bc1RgbaUnorm, .Bc1RgbaUnormSrgb,
		 .Bc2RgbaUnorm, .Bc2RgbaUnormSrgb, .Bc3RgbaUnorm, .Bc3RgbaUnormSrgb, .Bc4RUnorm,
		 .Bc4RSnorm, .Bc5RgUnorm, .Bc5RgSnorm, .Bc6hRgbUfloat, .Bc6hRgbFloat, .Bc7RgbaUnorm,
		 .Bc7RgbaUnormSrgb, .Etc2Rgb8Unorm, .Etc2Rgb8UnormSrgb, .Etc2Rgb8A1Unorm,
		 .Etc2Rgb8A1UnormSrgb, .Etc2Rgba8Unorm, .Etc2Rgba8UnormSrgb, .EacR11Unorm, .EacR11Snorm,
		 .EacRg11Unorm, .EacRg11Snorm, .Astc4x4Unorm, .Astc4x4UnormSrgb, .Astc5x4Unorm,
		 .Astc5x4UnormSrgb, .Astc5x5Unorm, .Astc5x5UnormSrgb, .Astc6x5Unorm, .Astc6x5UnormSrgb,
		 .Astc6x6Unorm, .Astc6x6UnormSrgb, .Astc8x5Unorm, .Astc8x5UnormSrgb, .Astc8x6Unorm,
		 .Astc8x6UnormSrgb, .Astc8x8Unorm, .Astc8x8UnormSrgb, .Astc10x5Unorm, .Astc10x5UnormSrgb,
		 .Astc10x6Unorm, .Astc10x6UnormSrgb, .Astc10x8Unorm, .Astc10x8UnormSrgb, .Astc10x10Unorm,
		 .Astc10x10UnormSrgb, .Astc12x10Unorm, .Astc12x10UnormSrgb, .Astc12x12Unorm,
		 .Astc12x12UnormSrgb:
		return 0

	case .Undefined: return 0
	}
	// odinfmt: enable
	return 0
}

/* Returns the number of components this format has. */
texture_format_components :: proc "contextless" (self: Texture_Format) -> u8 {
	return texture_format_components_with_aspect(self, .All)
}

/*
Returns the number of components this format has taking into account the `aspect`.

The `aspect` is only relevant for combined depth-stencil formats and multi-planar formats.
*/
texture_format_components_with_aspect :: proc "contextless" (
	self: Texture_Format,
	aspect: Texture_Aspect,
) -> u8 {
	// odinfmt: disable
	switch self {
	case .R8Unorm, .R8Snorm, .R8Uint, .R8Sint, .R16Unorm, .R16Snorm, .R16Uint, .R16Sint,
		 .R16Float, .R32Uint, .R32Sint, .R32Float: return 1

	case .Rg8Unorm, .Rg8Snorm, .Rg8Uint, .Rg8Sint, .Rg16Unorm, .Rg16Snorm, .Rg16Uint, .Rg16Sint,
		 .Rg16Float, .Rg32Uint, .Rg32Sint, .Rg32Float: return 2

	case .Rgba8Unorm, .Rgba8UnormSrgb, .Rgba8Snorm, .Rgba8Uint, .Rgba8Sint, .Bgra8Unorm,
		 .Bgra8UnormSrgb, .Rgba16Unorm, .Rgba16Snorm, .Rgba16Uint, .Rgba16Sint, .Rgba16Float,
		 .Rgba32Uint, .Rgba32Sint, .Rgba32Float: return 4

	case .Rgb9e5Ufloat, .Rg11b10Ufloat: return 3
	case .Rgb10a2Uint, .Rgb10a2Unorm: return 4

	case .Stencil8, .Depth16Unorm, .Depth24Plus, .Depth32Float:
		return 1

	case .Depth24PlusStencil8, .Depth32_Float_Stencil8:
		#partial switch aspect {
		case .Undefined: return 0
		case .Depth_Only, .Stencil_Only: return 1
		}
		return 2

	case .NV12:
		#partial switch aspect {
		case .Undefined: return 0
		case .Plane0: return 1
		case .Plane1: return 2
		}
		return 3

	case .Bc4RUnorm, .Bc4RSnorm: return 1
	case .Bc5RgUnorm, .Bc5RgSnorm: return 2
	case .Bc6hRgbUfloat, .Bc6hRgbFloat: return 3

	case .Bc1RgbaUnorm, .Bc1RgbaUnormSrgb, .Bc2RgbaUnorm, .Bc2RgbaUnormSrgb, .Bc3RgbaUnorm,
		 .Bc3RgbaUnormSrgb, .Bc7RgbaUnorm, .Bc7RgbaUnormSrgb: return 4

	case .EacR11Unorm, .EacR11Snorm: return 1
	case .EacRg11Unorm, .EacRg11Snorm: return 2
	case .Etc2Rgb8Unorm, .Etc2Rgb8UnormSrgb: return 3

	case .Etc2Rgb8A1Unorm, .Etc2Rgb8A1UnormSrgb, .Etc2Rgba8Unorm, .Etc2Rgba8UnormSrgb: return 4

	case .Astc4x4Unorm, .Astc4x4UnormSrgb, .Astc5x4Unorm, .Astc5x4UnormSrgb, .Astc5x5Unorm,
		 .Astc5x5UnormSrgb, .Astc6x5Unorm, .Astc6x5UnormSrgb, .Astc6x6Unorm, .Astc6x6UnormSrgb,
		 .Astc8x5Unorm, .Astc8x5UnormSrgb, .Astc8x6Unorm, .Astc8x6UnormSrgb, .Astc8x8Unorm,
	     .Astc8x8UnormSrgb, .Astc10x5Unorm, .Astc10x5UnormSrgb, .Astc10x6Unorm, .Astc10x6UnormSrgb,
	     .Astc10x8Unorm, .Astc10x8UnormSrgb, .Astc10x10Unorm, .Astc10x10UnormSrgb,
	     .Astc12x10Unorm, .Astc12x10UnormSrgb, .Astc12x12Unorm, .Astc12x12UnormSrgb:
		return 4

	case .Undefined:
		return 0
	}
	// odinfmt: enable
	return 0
}

/* Strips the `Srgb` suffix from the given texture format. */
texture_format_remove_srgb_suffix :: proc "contextless" (
	self: Texture_Format,
) -> (
	ret: Texture_Format,
) {
	ret = self
	// odinfmt: disable
	#partial switch self {
	case .Rgba8UnormSrgb: return .Rgba8Unorm
	case .Bgra8UnormSrgb: return .Bgra8Unorm
	case .Bc1RgbaUnormSrgb: return .Bc1RgbaUnorm
	case .Bc2RgbaUnormSrgb: return .Bc2RgbaUnorm
	case .Bc3RgbaUnormSrgb: return .Bc3RgbaUnorm
	case .Bc7RgbaUnormSrgb: return .Bc7RgbaUnorm
	case .Etc2Rgb8UnormSrgb: return .Etc2Rgb8Unorm
	case .Etc2Rgb8A1UnormSrgb: return .Etc2Rgb8A1Unorm
	case .Etc2Rgba8UnormSrgb: return .Etc2Rgba8Unorm
	case .Astc4x4UnormSrgb: return .Astc4x4Unorm
	case .Astc5x4UnormSrgb: return .Astc5x4Unorm
	case .Astc5x5UnormSrgb: return .Astc5x5Unorm
	case .Astc6x5UnormSrgb: return .Astc6x5Unorm
	case .Astc6x6UnormSrgb: return .Astc6x6Unorm
	case .Astc8x5UnormSrgb: return .Astc8x5Unorm
	case .Astc8x6UnormSrgb: return .Astc8x6Unorm
	case .Astc8x8UnormSrgb: return .Astc8x8Unorm
	case .Astc10x5UnormSrgb: return .Astc10x5Unorm
	case .Astc10x6UnormSrgb: return .Astc10x6Unorm
	case .Astc10x8UnormSrgb: return .Astc10x8Unorm
	case .Astc10x10UnormSrgb: return .Astc10x10Unorm
	case .Astc12x10UnormSrgb: return .Astc12x10Unorm
	case .Astc12x12UnormSrgb: return .Astc12x12Unorm
	}
	// odinfmt: enable
	return
}

/* Adds an `Srgb` suffix to the given texture format, if the format supports it. */
texture_format_add_srgb_suffix :: proc "contextless" (
	self: Texture_Format,
) -> (
	ret: Texture_Format,
) {
	ret = self
	// odinfmt: disable
	#partial switch self {
	case .Rgba8Unorm: return .Rgba8UnormSrgb
	case .Bgra8Unorm: return .Bgra8UnormSrgb
	case .Bc1RgbaUnorm: return .Bc1RgbaUnormSrgb
	case .Bc2RgbaUnorm: return .Bc2RgbaUnormSrgb
	case .Bc3RgbaUnorm: return .Bc3RgbaUnormSrgb
	case .Bc7RgbaUnorm: return .Bc7RgbaUnormSrgb
	case .Etc2Rgb8Unorm: return .Etc2Rgb8UnormSrgb
	case .Etc2Rgb8A1Unorm: return .Etc2Rgb8A1UnormSrgb
	case .Etc2Rgba8Unorm: return .Etc2Rgba8UnormSrgb
	case .Astc4x4Unorm: return .Astc4x4UnormSrgb
	case .Astc5x4Unorm: return .Astc5x4UnormSrgb
	case .Astc5x5Unorm: return .Astc5x5UnormSrgb
	case .Astc6x5Unorm: return .Astc6x5UnormSrgb
	case .Astc6x6Unorm: return .Astc6x6UnormSrgb
	case .Astc8x5Unorm: return .Astc8x5UnormSrgb
	case .Astc8x6Unorm: return .Astc8x6UnormSrgb
	case .Astc8x8Unorm: return .Astc8x8UnormSrgb
	case .Astc10x5Unorm: return .Astc10x5UnormSrgb
	case .Astc10x6Unorm: return .Astc10x6UnormSrgb
	case .Astc10x8Unorm: return .Astc10x8UnormSrgb
	case .Astc10x10Unorm: return .Astc10x10UnormSrgb
	case .Astc12x10Unorm: return .Astc12x10UnormSrgb
	case .Astc12x12Unorm: return .Astc12x12UnormSrgb
	}
	// odinfmt: enable
	return
}

/* Returns `true` for srgb formats. */
texture_format_is_srgb :: proc "contextless" (self: Texture_Format) -> bool {
	return self != texture_format_remove_srgb_suffix(self)
}

/* Calculate bytes per row from the given row width. */
texture_format_bytes_per_row :: proc "contextless" (
	format: Texture_Format,
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
