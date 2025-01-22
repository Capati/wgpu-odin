package wgpu

/* Represents various usage features for a texture. */
Texture_Usage_Feature :: enum Flags {
	Filterable,
	Multisample_X2,
	Multisample_X4,
	Multisample_X8,
	Multisample_X16,
	Multisample_Resolve,
	Storage_Read_Only,
	Storage_Write_Only,
	Storage_Read_Write,
	Blendable,
}

/* Feature flags for a texture format. */
Texture_Format_Feature_Flags :: bit_set[Texture_Usage_Feature;Flags]

/* Checks if the given texture format supports the specified sample count. */
texture_format_feature_flags_sample_count_supported :: proc "contextless" (
	self: Texture_Format_Feature_Flags,
	count: u32,
) -> bool {
	// odinfmt: disable
	switch count {
	case 1 : return true
	case 2 : return .Multisample_X2 in self
	case 4 : return .Multisample_X4 in self
	case 8 : return .Multisample_X8 in self
	case 16: return .Multisample_X16 in self
	}
	// odinfmt: enable
	return false
}

/* Checks if the given texture format supports the specified sample count. */
sample_count_supported :: texture_format_feature_flags_sample_count_supported

texture_format_feature_flags_supported_sample_counts :: proc(
	self: Texture_Format_Feature_Flags,
) -> (
	flags: MultisampleFlags,
) {
	if .Multisample_X2 in self {
		flags += {.X2}
	}
	if .Multisample_X4 in self {
		flags += {.X4}
	}
	if .Multisample_X8 in self {
		flags += {.X8}
	}
	if .Multisample_X16 in self {
		flags += {.X16}
	}
	return flags
}

supported_sample_counts :: texture_format_feature_flags_supported_sample_counts

/* Features supported by a given texture format */
Texture_Format_Features :: struct {
	allowed_usages: Texture_Usages,
	flags:          Texture_Format_Feature_Flags,
}

/* ASTC block dimensions */
Astc_Block :: enum i32 {
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
Astc_Channel :: enum i32 {
	Unorm,
	Unorm_Srgb,
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
	Undefined               = 0x00000000,

	// WebGPU
	R8_Unorm                = 0x00000001,
	R8_Snorm                = 0x00000002,
	R8_Uint                 = 0x00000003,
	R8_Sint                 = 0x00000004,
	R16_Uint                = 0x00000005,
	R16_Sint                = 0x00000006,
	R16_Float               = 0x00000007,
	Rg8_Unorm               = 0x00000008,
	Rg8_Snorm               = 0x00000009,
	Rg8_Uint                = 0x0000000A,
	Rg8_Sint                = 0x0000000B,
	R32_Float               = 0x0000000C,
	R32_Uint                = 0x0000000D,
	R32_Sint                = 0x0000000E,
	Rg16_Uint               = 0x0000000F,
	Rg16_Sint               = 0x00000010,
	Rg16_Float              = 0x00000011,
	Rgba8_Unorm             = 0x00000012,
	Rgba8_Unorm_Srgb        = 0x00000013,
	Rgba8_Snorm             = 0x00000014,
	Rgba8_Uint              = 0x00000015,
	Rgba8_Sint              = 0x00000016,
	Bgra8_Unorm             = 0x00000017,
	Bgra8_Unorm_Srgb        = 0x00000018,
	Rgb10a2_Uint            = 0x00000019,
	Rgb10a2_Unorm           = 0x0000001A,
	Rg11b10_Ufloat          = 0x0000001B,
	Rgb9e5_Ufloat           = 0x0000001C,
	Rg32_Float              = 0x0000001D,
	Rg32_Uint               = 0x0000001E,
	Rg32_Sint               = 0x0000001F,
	Rgba16_Uint             = 0x00000020,
	Rgba16_Sint             = 0x00000021,
	Rgba16_Float            = 0x00000022,
	Rgba32_Float            = 0x00000023,
	Rgba32_Uint             = 0x00000024,
	Rgba32_Sint             = 0x00000025,
	Stencil8                = 0x00000026,
	Depth16_Unorm           = 0x00000027,
	Depth24_Plus            = 0x00000028,
	Depth24_Plus_Stencil8   = 0x00000029,
	Depth32_Float           = 0x0000002A,
	Depth32_Float_Stencil8  = 0x0000002B,
	Bc1_Rgba_Unorm          = 0x0000002C,
	Bc1_Rgba_Unorm_Srgb     = 0x0000002D,
	Bc2_Rgba_Unorm          = 0x0000002E,
	Bc2_Rgba_Unorm_Srgb     = 0x0000002F,
	Bc3_Rgba_Unorm          = 0x00000030,
	Bc3_Rgba_Unorm_Srgb     = 0x00000031,
	Bc4_R_Unorm             = 0x00000032,
	Bc4_R_Snorm             = 0x00000033,
	Bc5_Rg_Unorm            = 0x00000034,
	Bc5_Rg_Snorm            = 0x00000035,
	Bc6h_Rgb_Ufloat         = 0x00000036,
	Bc6h_Rgb_Float          = 0x00000037,
	Bc7_Rgba_Unorm          = 0x00000038,
	Bc7_Rgba_Unorm_Srgb     = 0x00000039,
	Etc2_Rgb8_Unorm         = 0x0000003A,
	Etc2_Rgb8_Unorm_Srgb    = 0x0000003B,
	Etc2_Rgb8_A1_Unorm      = 0x0000003C,
	Etc2_Rgb8_A1_Unorm_Srgb = 0x0000003D,
	Etc2_Rgba8_Unorm        = 0x0000003E,
	Etc2_Rgba8_Unorm_Srgb   = 0x0000003F,
	Eac_R11_Unorm           = 0x00000040,
	Eac_R11_Snorm           = 0x00000041,
	Eac_Rg11_Unorm          = 0x00000042,
	Eac_Rg11_Snorm          = 0x00000043,
	Astc4x4_Unorm           = 0x00000044,
	Astc4x4_Unorm_Srgb      = 0x00000045,
	Astc5x4_Unorm           = 0x00000046,
	Astc5x4_Unorm_Srgb      = 0x00000047,
	Astc5x5_Unorm           = 0x00000048,
	Astc5x5_Unorm_Srgb      = 0x00000049,
	Astc6x5_Unorm           = 0x0000004A,
	Astc6x5_Unorm_Srgb      = 0x0000004B,
	Astc6x6_Unorm           = 0x0000004C,
	Astc6x6_Unorm_Srgb      = 0x0000004D,
	Astc8x5_Unorm           = 0x0000004E,
	Astc8x5_Unorm_Srgb      = 0x0000004F,
	Astc8x6_Unorm           = 0x00000050,
	Astc8x6_Unorm_Srgb      = 0x00000051,
	Astc8x8_Unorm           = 0x00000052,
	Astc8x8_Unorm_Srgb      = 0x00000053,
	Astc10x5_Unorm          = 0x00000054,
	Astc10x5_Unorm_Srgb     = 0x00000055,
	Astc10x6_Unorm          = 0x00000056,
	Astc10x6_Unorm_Srgb     = 0x00000057,
	Astc10x8_Unorm          = 0x00000058,
	Astc10x8_Unorm_Srgb     = 0x00000059,
	Astc10x10_Unorm         = 0x0000005A,
	Astc10x10_Unorm_Srgb    = 0x0000005B,
	Astc12x10_Unorm         = 0x0000005C,
	Astc12x10_Unorm_Srgb    = 0x0000005D,
	Astc12x12_Unorm         = 0x0000005E,
	Astc12x12_Unorm_Srgb    = 0x0000005F,

	// Native
	R16_Unorm               = 0x00030001,
	R16_Snorm               = 0x00030002,
	Rg16_Unorm              = 0x00030003,
	Rg16_Snorm              = 0x00030004,
	Rgba16_Unorm            = 0x00030005,
	Rgba16_Snorm            = 0x00030006,
	NV12                    = 0x00030007,
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
	case .Depth16_Unorm, .Depth24_Plus, .Depth32_Float:
		if aspect == .Depth_Only {
			return self
		}
	case .Depth24_Plus_Stencil8:
		#partial switch aspect {
		case .Stencil_Only:
			return .Stencil8
		case .Depth_Only:
			return .Depth24_Plus
		}
	case .Depth32_Float_Stencil8:
		#partial switch aspect {
		case .Stencil_Only:
			return .Stencil8
		case .Depth_Only:
			return .Depth32_Float
		}
	case .NV12:
		#partial switch aspect {
		case .Plane0:
			return .R8_Unorm
		case .Plane1:
			return .Rg8_Unorm
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
		combined_format == .Depth24_Plus_Stencil8 &&
			(self == .Depth24_Plus || self == .Stencil8) ||
		combined_format == .Depth32_Float_Stencil8 &&
			(self == .Depth32_Float || self == .Stencil8) \
	)
}

/*
Check if the format is a depth and/or stencil format.

see <https://gpuweb.github.io/gpuweb/#depth-formats>
*/
texture_format_is_depth_stencil_format :: proc "contextless" (self: Texture_Format) -> bool {
	#partial switch self {
	case .Stencil8,
	     .Depth16_Unorm,
	     .Depth24_Plus,
	     .Depth24_Plus_Stencil8,
	     .Depth32_Float,
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
	case .Depth24_Plus_Stencil8, .Depth32_Float_Stencil8:
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
	case .Depth16_Unorm,
	     .Depth24_Plus,
	     .Depth24_Plus_Stencil8,
	     .Depth32_Float,
	     .Depth32_Float_Stencil8:
		return true
	}
	return false
}

/* Returns `true` if the format has a stencil aspect.*/
texture_format_has_stencil_aspect :: proc "contextless" (self: Texture_Format) -> bool {
	#partial switch self {
	case .Stencil8, .Depth24_Plus_Stencil8, .Depth32_Float_Stencil8:
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
	case .R8_Unorm, .R8_Snorm, .R8_Uint, .R8_Sint, .R16_Uint, .R16_Sint, .R16_Unorm, .R16_Snorm,
		 .R16_Float, .Rg8_Unorm, .Rg8_Snorm, .Rg8_Uint, .Rg8_Sint, .R32_Uint, .R32_Sint,
		 .R32_Float, .Rg16_Uint, .Rg16_Sint, .Rg16_Unorm, .Rg16_Snorm, .Rg16_Float, .Rgba8_Unorm,
		 .Rgba8_Unorm_Srgb, .Rgba8_Snorm, .Rgba8_Uint, .Rgba8_Sint, .Bgra8_Unorm,
		 .Bgra8_Unorm_Srgb, .Rgb9e5_Ufloat, .Rgb10a2_Uint, .Rgb10a2_Unorm, .Rg11b10_Ufloat,
		 .Rg32_Uint, .Rg32_Sint, .Rg32_Float, .Rgba16_Uint, .Rgba16_Sint, .Rgba16_Unorm,
		 .Rgba16_Snorm, .Rgba16_Float, .Rgba32_Uint, .Rgba32_Sint, .Rgba32_Float, .Stencil8,
		 .Depth16_Unorm, .Depth24_Plus, .Depth24_Plus_Stencil8, .Depth32_Float,
		 .Depth32_Float_Stencil8, .NV12:
		return 1, 1

	case .Bc1_Rgba_Unorm, .Bc1_Rgba_Unorm_Srgb, .Bc2_Rgba_Unorm, .Bc2_Rgba_Unorm_Srgb,
		 .Bc3_Rgba_Unorm, .Bc3_Rgba_Unorm_Srgb, .Bc4_R_Unorm, .Bc4_R_Snorm, .Bc5_Rg_Unorm,
		 .Bc5_Rg_Snorm, .Bc6h_Rgb_Ufloat, .Bc6h_Rgb_Float, .Bc7_Rgba_Unorm, .Bc7_Rgba_Unorm_Srgb,
		 .Etc2_Rgb8_Unorm, .Etc2_Rgb8_Unorm_Srgb, .Etc2_Rgb8_A1_Unorm, .Etc2_Rgb8_A1_Unorm_Srgb,
		 .Etc2_Rgba8_Unorm, .Etc2_Rgba8_Unorm_Srgb, .Eac_R11_Unorm, .Eac_R11_Snorm,
		 .Eac_Rg11_Unorm, .Eac_Rg11_Snorm:
		return 4, 4

	case .Astc4x4_Unorm, .Astc4x4_Unorm_Srgb: return 4, 4
	case .Astc5x4_Unorm, .Astc5x4_Unorm_Srgb: return 5, 5
	case .Astc5x5_Unorm, .Astc5x5_Unorm_Srgb: return 5, 5
	case .Astc6x5_Unorm, .Astc6x5_Unorm_Srgb: return 6, 5
	case .Astc6x6_Unorm, .Astc6x6_Unorm_Srgb: return 6, 6
	case .Astc8x5_Unorm, .Astc8x5_Unorm_Srgb: return 8, 5
	case .Astc8x6_Unorm, .Astc8x6_Unorm_Srgb: return 8, 6
	case .Astc8x8_Unorm, .Astc8x8_Unorm_Srgb: return 8, 8
	case .Astc10x5_Unorm, .Astc10x5_Unorm_Srgb: return 10, 5
	case .Astc10x6_Unorm, .Astc10x6_Unorm_Srgb: return 10, 6
	case .Astc10x8_Unorm, .Astc10x8_Unorm_Srgb: return 10, 8
	case .Astc10x10_Unorm, .Astc10x10_Unorm_Srgb: return 10, 10
	case .Astc12x10_Unorm, .Astc12x10_Unorm_Srgb: return 12, 10
	case .Astc12x12_Unorm, .Astc12x12_Unorm_Srgb: return 12, 12

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
	case .R8_Unorm, .R8_Snorm, .R8_Uint, .R8_Sint, .R16_Uint, .R16_Sint, .R16_Float, .Rg8_Unorm,
		 .Rg8_Snorm, .Rg8_Uint, .Rg8_Sint, .R32_Float, .R32_Uint, .R32_Sint, .Rg16_Uint, .Rg16_Sint,
		 .Rg16_Float, .Rgba8_Unorm, .Rgba8_Unorm_Srgb, .Rgba8_Snorm, .Rgba8_Uint, .Rgba8_Sint,
		 .Bgra8_Unorm, .Bgra8_Unorm_Srgb, .Rgb10a2_Uint, .Rgb10a2_Unorm, .Rg11b10_Ufloat,
		 .Rgb9e5_Ufloat, .Rg32_Float, .Rg32_Uint, .Rg32_Sint, .Rgba16_Uint, .Rgba16_Sint,
		 .Rgba16_Float, .Rgba32_Float, .Rgba32_Uint, .Rgba32_Sint, .Stencil8, .Depth16_Unorm,
		 .Depth24_Plus, .Depth24_Plus_Stencil8, .Depth32_Float:
		return {} // empty, no features need

	case .Depth32_Float_Stencil8:
		return {.Depth32_Float_Stencil8}

	case .NV12:
		return {.Texture_Format_NV12}

	case .R16_Unorm, .R16_Snorm, .Rg16_Unorm, .Rg16_Snorm, .Rgba16_Unorm, .Rgba16_Snorm:
		return {.Texture_Format16bit_Norm}

	case .Bc1_Rgba_Unorm, .Bc1_Rgba_Unorm_Srgb, .Bc2_Rgba_Unorm, .Bc2_Rgba_Unorm_Srgb,
		 .Bc3_Rgba_Unorm, .Bc3_Rgba_Unorm_Srgb, .Bc4_R_Unorm, .Bc4_R_Snorm, .Bc5_Rg_Unorm,
		 .Bc5_Rg_Snorm, .Bc6h_Rgb_Ufloat, .Bc6h_Rgb_Float, .Bc7_Rgba_Unorm, .Bc7_Rgba_Unorm_Srgb:
		return {.Texture_Compression_BC}

	case .Etc2_Rgb8_Unorm, .Etc2_Rgb8_Unorm_Srgb, .Etc2_Rgb8_A1_Unorm, .Etc2_Rgb8_A1_Unorm_Srgb,
		 .Etc2_Rgba8_Unorm, .Etc2_Rgba8_Unorm_Srgb, .Eac_R11_Unorm, .Eac_R11_Snorm, .Eac_Rg11_Unorm,
	     .Eac_Rg11_Snorm:
		return {.Texture_Compression_ETC2}

	case .Astc4x4_Unorm, .Astc4x4_Unorm_Srgb, .Astc5x4_Unorm, .Astc5x4_Unorm_Srgb,
		 .Astc5x5_Unorm, .Astc5x5_Unorm_Srgb, .Astc6x5_Unorm, .Astc6x5_Unorm_Srgb, .Astc6x6_Unorm,
		 .Astc6x6_Unorm_Srgb, .Astc8x5_Unorm, .Astc8x5_Unorm_Srgb, .Astc8x6_Unorm,
		 .Astc8x6_Unorm_Srgb, .Astc8x8_Unorm, .Astc8x8_Unorm_Srgb, .Astc10x5_Unorm,
		 .Astc10x5_Unorm_Srgb, .Astc10x6_Unorm, .Astc10x6_Unorm_Srgb, .Astc10x8_Unorm,
		 .Astc10x8_Unorm_Srgb, .Astc10x10_Unorm, .Astc10x10_Unorm_Srgb, .Astc12x10_Unorm,
		 .Astc12x10_Unorm_Srgb, .Astc12x12_Unorm, .Astc12x12_Unorm_Srgb:
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
	noaa: Texture_Format_Feature_Flags
	msaa: Texture_Format_Feature_Flags = {.Multisample_X4}
	msaa_resolve: Texture_Format_Feature_Flags = msaa + {.Multisample_Resolve}

	// Flags
	basic: Texture_Usages = {.Copy_Src, .Copy_Dst, .Texture_Binding}
	attachment: Texture_Usages = basic + {.Render_Attachment}
	storage: Texture_Usages = basic + {.Storage_Binding}
	binding: Texture_Usages = {.Texture_Binding}
	all_flags := TEXTURE_USAGES_ALL
	rg11b10f := attachment if .RG11B10_Ufloat_Renderable in device_features else basic
	bgra8unorm := attachment + storage if .BGRA8_Unorm_Storage in device_features else attachment

	flags: Texture_Format_Feature_Flags
	allowed_usages: Texture_Usages

	// odinfmt: disable
	switch self {
	case .R8_Unorm: flags = msaa_resolve; allowed_usages = attachment
	case .R8_Snorm: flags = noaa; allowed_usages = basic
	case .R8_Uint: flags = msaa; allowed_usages = attachment
	case .R8_Sint: flags = msaa; allowed_usages = attachment
	case .R16_Uint: flags = msaa; allowed_usages = attachment
	case .R16_Sint: flags = msaa; allowed_usages = attachment
	case .R16_Float: flags = msaa_resolve; allowed_usages = attachment
	case .Rg8_Unorm: flags = msaa_resolve; allowed_usages = attachment
	case .Rg8_Snorm: flags = noaa; allowed_usages = basic
	case .Rg8_Uint: flags = msaa; allowed_usages = attachment
	case .Rg8_Sint: flags = msaa; allowed_usages = attachment
	case .R32_Uint: flags = noaa; allowed_usages = all_flags
	case .R32_Sint: flags = noaa; allowed_usages = all_flags
	case .R32_Float: flags = msaa; allowed_usages = all_flags
	case .Rg16_Uint: flags = msaa; allowed_usages = attachment
	case .Rg16_Sint: flags = msaa; allowed_usages = attachment
	case .Rg16_Float: flags = msaa_resolve; allowed_usages = attachment
	case .Rgba8_Unorm: flags = msaa_resolve; allowed_usages = all_flags
	case .Rgba8_Unorm_Srgb: flags = msaa_resolve; allowed_usages = attachment
	case .Rgba8_Snorm: flags = noaa; allowed_usages = storage
	case .Rgba8_Uint: flags = msaa; allowed_usages = all_flags
	case .Rgba8_Sint: flags = msaa; allowed_usages = all_flags
	case .Bgra8_Unorm: flags = msaa_resolve; allowed_usages = bgra8unorm
	case .Bgra8_Unorm_Srgb: flags = msaa_resolve; allowed_usages = attachment
	case .Rgb10a2_Uint: flags = msaa; allowed_usages = attachment
	case .Rgb10a2_Unorm: flags = msaa_resolve; allowed_usages = attachment
	case .Rg11b10_Ufloat: flags = msaa; allowed_usages = rg11b10f
	case .Rg32_Uint: flags = noaa; allowed_usages = all_flags
	case .Rg32_Sint: flags = noaa; allowed_usages = all_flags
	case .Rg32_Float: flags = noaa; allowed_usages = all_flags
	case .Rgba16_Uint: flags = msaa; allowed_usages = all_flags
	case .Rgba16_Sint: flags = msaa; allowed_usages = all_flags
	case .Rgba16_Float: flags = msaa_resolve; allowed_usages = all_flags
	case .Rgba32_Uint: flags = noaa; allowed_usages = all_flags
	case .Rgba32_Sint: flags = noaa; allowed_usages = all_flags
	case .Rgba32_Float: flags = noaa; allowed_usages = all_flags
	case .Stencil8: flags = msaa; allowed_usages = attachment
	case .Depth16_Unorm: flags = msaa; allowed_usages = attachment
	case .Depth24_Plus: flags = msaa; allowed_usages = attachment
	case .Depth24_Plus_Stencil8: flags = msaa; allowed_usages = attachment
	case .Depth32_Float: flags = msaa; allowed_usages = attachment
	case .Depth32_Float_Stencil8: flags = msaa; allowed_usages = attachment
	case .NV12: flags = noaa; allowed_usages = binding
	case .R16_Unorm: flags = msaa; allowed_usages = storage
	case .R16_Snorm: flags = msaa; allowed_usages = storage
	case .Rg16_Unorm: flags = msaa; allowed_usages = storage
	case .Rg16_Snorm: flags = msaa; allowed_usages = storage
	case .Rgba16_Unorm: flags = msaa; allowed_usages = storage
	case .Rgba16_Snorm: flags = msaa; allowed_usages = storage
	case .Rgb9e5_Ufloat: flags = noaa; allowed_usages = basic
	case .Bc1_Rgba_Unorm: flags = noaa; allowed_usages = basic
	case .Bc1_Rgba_Unorm_Srgb: flags = noaa; allowed_usages = basic
	case .Bc2_Rgba_Unorm: flags = noaa; allowed_usages = basic
	case .Bc2_Rgba_Unorm_Srgb: flags = noaa; allowed_usages = basic
	case .Bc3_Rgba_Unorm: flags = noaa; allowed_usages = basic
	case .Bc3_Rgba_Unorm_Srgb: flags = noaa; allowed_usages = basic
	case .Bc4_R_Unorm: flags = noaa; allowed_usages = basic
	case .Bc4_R_Snorm: flags = noaa; allowed_usages = basic
	case .Bc5_Rg_Unorm: flags = noaa; allowed_usages = basic
	case .Bc5_Rg_Snorm: flags = noaa; allowed_usages = basic
	case .Bc6h_Rgb_Ufloat: flags = noaa; allowed_usages = basic
	case .Bc6h_Rgb_Float: flags = noaa; allowed_usages = basic
	case .Bc7_Rgba_Unorm: flags = noaa; allowed_usages = basic
	case .Bc7_Rgba_Unorm_Srgb: flags = noaa; allowed_usages = basic
	case .Etc2_Rgb8_Unorm: flags = noaa; allowed_usages = basic
	case .Etc2_Rgb8_Unorm_Srgb: flags = noaa; allowed_usages = basic
	case .Etc2_Rgb8_A1_Unorm: flags = noaa; allowed_usages = basic
	case .Etc2_Rgb8_A1_Unorm_Srgb: flags = noaa; allowed_usages = basic
	case .Etc2_Rgba8_Unorm: flags = noaa; allowed_usages = basic
	case .Etc2_Rgba8_Unorm_Srgb: flags = noaa; allowed_usages = basic
	case .Eac_R11_Unorm: flags = noaa; allowed_usages = basic
	case .Eac_R11_Snorm: flags = noaa; allowed_usages = basic
	case .Eac_Rg11_Unorm: flags = noaa; allowed_usages = basic
	case .Eac_Rg11_Snorm: flags = noaa; allowed_usages = basic
	case .Astc4x4_Unorm, .Astc4x4_Unorm_Srgb, .Astc5x4_Unorm, .Astc5x4_Unorm_Srgb,
		 .Astc5x5_Unorm,.Astc5x5_Unorm_Srgb, .Astc6x5_Unorm, .Astc6x5_Unorm_Srgb, .Astc6x6_Unorm,
		 .Astc6x6_Unorm_Srgb,.Astc8x5_Unorm, .Astc8x5_Unorm_Srgb, .Astc8x6_Unorm,
		 .Astc8x6_Unorm_Srgb, .Astc8x8_Unorm,.Astc8x8_Unorm_Srgb, .Astc10x5_Unorm,
		 .Astc10x5_Unorm_Srgb, .Astc10x6_Unorm, .Astc10x6_Unorm_Srgb,.Astc10x8_Unorm,
		 .Astc10x8_Unorm_Srgb, .Astc10x10_Unorm, .Astc10x10_Unorm_Srgb,.Astc12x10_Unorm,
		 .Astc12x10_Unorm_Srgb, .Astc12x12_Unorm,
		 .Astc12x12_Unorm_Srgb:
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
	case .R8_Unorm, .R8_Snorm, .Rg8_Unorm, .Rg8_Snorm, .Rgba8_Unorm, .Rgba8_Unorm_Srgb,
		 .Rgba8_Snorm, .Bgra8_Unorm, .Bgra8_Unorm_Srgb, .R16_Float, .Rg16_Float, .Rgba16_Float,
		 .Rgb10a2_Unorm, .Rg11b10_Ufloat:
		return float_filterable

	case .R32_Float, .Rg32_Float, .Rgba32_Float:
		return float32_sample_type

	case .R8_Uint, .Rg8_Uint, .Rgba8_Uint, .R16_Uint, .Rg16_Uint, .Rgba16_Uint, .R32_Uint,
	     .Rg32_Uint, .Rgba32_Uint, .Rgb10a2_Uint:
		return _uint

	case .R8_Sint, .Rg8_Sint, .Rgba8_Sint, .R16_Sint, .Rg16_Sint, .Rgba16_Sint, .R32_Sint,
	     .Rg32_Sint, .Rgba32_Sint:
		return sint

	case .Stencil8:
		return _uint

	case .Depth16_Unorm, .Depth24_Plus, .Depth32_Float:
		return depth

	case .Depth24_Plus_Stencil8, .Depth32_Float_Stencil8:
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

	case .R16_Unorm, .R16_Snorm, .Rg16_Unorm, .Rg16_Snorm, .Rgba16_Unorm, .Rgba16_Snorm:
		return float_filterable

	case .Rgb9e5_Ufloat, .Bc1_Rgba_Unorm, .Bc1_Rgba_Unorm_Srgb, .Bc2_Rgba_Unorm,
		 .Bc2_Rgba_Unorm_Srgb, .Bc3_Rgba_Unorm, .Bc3_Rgba_Unorm_Srgb, .Bc4_R_Unorm, .Bc4_R_Snorm,
		 .Bc5_Rg_Unorm, .Bc5_Rg_Snorm, .Bc6h_Rgb_Ufloat, .Bc6h_Rgb_Float, .Bc7_Rgba_Unorm,
		 .Bc7_Rgba_Unorm_Srgb, .Etc2_Rgb8_Unorm, .Etc2_Rgb8_Unorm_Srgb, .Etc2_Rgb8_A1_Unorm,
		 .Etc2_Rgb8_A1_Unorm_Srgb, .Etc2_Rgba8_Unorm, .Etc2_Rgba8_Unorm_Srgb, .Eac_R11_Unorm,
		 .Eac_R11_Snorm, .Eac_Rg11_Unorm, .Eac_Rg11_Snorm, .Astc4x4_Unorm, .Astc4x4_Unorm_Srgb,
		 .Astc5x4_Unorm, .Astc5x4_Unorm_Srgb, .Astc5x5_Unorm, .Astc5x5_Unorm_Srgb, .Astc6x5_Unorm,
		 .Astc6x5_Unorm_Srgb, .Astc6x6_Unorm, .Astc6x6_Unorm_Srgb, .Astc8x5_Unorm,
		 .Astc8x5_Unorm_Srgb, .Astc8x6_Unorm, .Astc8x6_Unorm_Srgb, .Astc8x8_Unorm,
		 .Astc8x8_Unorm_Srgb, .Astc10x5_Unorm, .Astc10x5_Unorm_Srgb, .Astc10x6_Unorm,
		 .Astc10x6_Unorm_Srgb, .Astc10x8_Unorm, .Astc10x8_Unorm_Srgb, .Astc10x10_Unorm,
		 .Astc10x10_Unorm_Srgb, .Astc12x10_Unorm, .Astc12x10_Unorm_Srgb, .Astc12x12_Unorm,
		 .Astc12x12_Unorm_Srgb:
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
 - the format is `Depth24_Plus`
 - the format is `Depth24_Plus_Stencil8` and `aspect` is depth.
*/
texture_format_block_size :: proc "contextless" (
	self: Texture_Format,
	aspect: Maybe(Texture_Aspect) = nil,
) -> u32 {
	_aspect, aspect_ok := aspect.?

	// odinfmt: disable
	switch self {
	case .R8_Unorm, .R8_Snorm, .R8_Uint, .R8_Sint: return 1

	case .Rg8_Unorm, .Rg8_Snorm, .Rg8_Uint, .Rg8_Sint: return 2
	case .R16_Unorm, .R16_Snorm, .R16_Uint, .R16_Sint, .R16_Float: return 2

	case .Rgba8_Unorm,.Rgba8_Unorm_Srgb,.Rgba8_Snorm,.Rgba8_Uint,.Rgba8_Sint,.Bgra8_Unorm,
		 .Bgra8_Unorm_Srgb: return 4

	case .Rg16_Unorm, .Rg16_Snorm, .Rg16_Uint, .Rg16_Sint, .Rg16_Float: return 4
	case .R32_Uint, .R32_Sint, .R32_Float: return 4
	case .Rgb9e5_Ufloat, .Rgb10a2_Uint, .Rgb10a2_Unorm, .Rg11b10_Ufloat: return 4

	case .Rgba16_Unorm, .Rgba16_Snorm, .Rgba16_Uint, .Rgba16_Sint, .Rgba16_Float: return 8
	case .Rg32_Uint, .Rg32_Sint, .Rg32_Float: return 8

	case .Rgba32_Uint, .Rgba32_Sint, .Rgba32_Float: return 16

	case .Stencil8: return 1
	case .Depth16_Unorm: return 2
	case .Depth32_Float: return 4
	case .Depth24_Plus: return 0

	case .Depth24_Plus_Stencil8:
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

	case .Bc1_Rgba_Unorm, .Bc1_Rgba_Unorm_Srgb, .Bc4_R_Unorm, .Bc4_R_Snorm: return 8

	case .Bc2_Rgba_Unorm, .Bc2_Rgba_Unorm_Srgb, .Bc3_Rgba_Unorm, .Bc3_Rgba_Unorm_Srgb,
		 .Bc5_Rg_Unorm, .Bc5_Rg_Snorm, .Bc6h_Rgb_Ufloat, .Bc6h_Rgb_Float, .Bc7_Rgba_Unorm,
		 .Bc7_Rgba_Unorm_Srgb: return 16

	case .Etc2_Rgb8_Unorm, .Etc2_Rgb8_Unorm_Srgb, .Etc2_Rgb8_A1_Unorm, .Etc2_Rgb8_A1_Unorm_Srgb,
		 .Eac_R11_Unorm, .Eac_R11_Snorm: return 8

	case .Etc2_Rgba8_Unorm, .Etc2_Rgba8_Unorm_Srgb, .Eac_Rg11_Unorm, .Eac_Rg11_Snorm: return 16

	case .Astc4x4_Unorm, .Astc4x4_Unorm_Srgb, .Astc5x4_Unorm, .Astc5x4_Unorm_Srgb, .Astc5x5_Unorm,
	     .Astc5x5_Unorm_Srgb, .Astc6x5_Unorm, .Astc6x5_Unorm_Srgb, .Astc6x6_Unorm,
		 .Astc6x6_Unorm_Srgb, .Astc8x5_Unorm, .Astc8x5_Unorm_Srgb, .Astc8x6_Unorm,
		 .Astc8x6_Unorm_Srgb, .Astc8x8_Unorm, .Astc8x8_Unorm_Srgb, .Astc10x5_Unorm,
		 .Astc10x5_Unorm_Srgb, .Astc10x6_Unorm, .Astc10x6_Unorm_Srgb, .Astc10x8_Unorm,
		 .Astc10x8_Unorm_Srgb, .Astc10x10_Unorm, .Astc10x10_Unorm_Srgb, .Astc12x10_Unorm,
		 .Astc12x10_Unorm_Srgb, .Astc12x12_Unorm, .Astc12x12_Unorm_Srgb: return 16

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
	case .R8_Unorm, .R8_Snorm, .R8_Uint, .R8_Sint: return 1

	case .Rg8_Unorm,.Rg8_Snorm,.Rg8_Uint,.Rg8_Sint,.R16_Uint,.R16_Sint,.R16_Unorm,.R16_Snorm,
		 .R16_Float:
		return 2

	case .Rgba8_Uint, .Rgba8_Sint, .Rg16_Uint, .Rg16_Sint, .Rg16_Unorm, .Rg16_Snorm, .Rg16_Float,
		 .R32_Uint, .R32_Sint, .R32_Float: return 4

	case .Rgba8_Unorm, .Rgba8_Unorm_Srgb, .Rgba8_Snorm, .Bgra8_Unorm, .Bgra8_Unorm_Srgb,
		 .Rgba16_Uint, .Rgba16_Sint, .Rgba16_Unorm, .Rgba16_Snorm, .Rgba16_Float, .Rg32_Uint,
		 .Rg32_Sint, .Rg32_Float, .Rgb10a2_Uint, .Rgb10a2_Unorm, .Rg11b10_Ufloat:
		return 8

	case .Rgba32_Uint, .Rgba32_Sint, .Rgba32_Float:
		return 16

	case .Stencil8, .Depth16_Unorm, .Depth24_Plus, .Depth24_Plus_Stencil8, .Depth32_Float,
		 .Depth32_Float_Stencil8, .NV12, .Rgb9e5_Ufloat, .Bc1_Rgba_Unorm, .Bc1_Rgba_Unorm_Srgb,
		 .Bc2_Rgba_Unorm, .Bc2_Rgba_Unorm_Srgb, .Bc3_Rgba_Unorm, .Bc3_Rgba_Unorm_Srgb, .Bc4_R_Unorm,
		 .Bc4_R_Snorm, .Bc5_Rg_Unorm, .Bc5_Rg_Snorm, .Bc6h_Rgb_Ufloat, .Bc6h_Rgb_Float,
		 .Bc7_Rgba_Unorm, .Bc7_Rgba_Unorm_Srgb, .Etc2_Rgb8_Unorm, .Etc2_Rgb8_Unorm_Srgb,
		 .Etc2_Rgb8_A1_Unorm, .Etc2_Rgb8_A1_Unorm_Srgb, .Etc2_Rgba8_Unorm, .Etc2_Rgba8_Unorm_Srgb,
		 .Eac_R11_Unorm, .Eac_R11_Snorm, .Eac_Rg11_Unorm, .Eac_Rg11_Snorm, .Astc4x4_Unorm,
		 .Astc4x4_Unorm_Srgb, .Astc5x4_Unorm, .Astc5x4_Unorm_Srgb, .Astc5x5_Unorm,
		 .Astc5x5_Unorm_Srgb, .Astc6x5_Unorm, .Astc6x5_Unorm_Srgb, .Astc6x6_Unorm,
		 .Astc6x6_Unorm_Srgb, .Astc8x5_Unorm, .Astc8x5_Unorm_Srgb, .Astc8x6_Unorm,
		 .Astc8x6_Unorm_Srgb, .Astc8x8_Unorm, .Astc8x8_Unorm_Srgb, .Astc10x5_Unorm,
		 .Astc10x5_Unorm_Srgb, .Astc10x6_Unorm, .Astc10x6_Unorm_Srgb, .Astc10x8_Unorm,
		 .Astc10x8_Unorm_Srgb, .Astc10x10_Unorm, .Astc10x10_Unorm_Srgb, .Astc12x10_Unorm,
		 .Astc12x10_Unorm_Srgb, .Astc12x12_Unorm, .Astc12x12_Unorm_Srgb:
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
	case .R8_Unorm, .R8_Snorm, .R8_Uint, .R8_Sint, .Rg8_Unorm, .Rg8_Snorm, .Rg8_Uint, .Rg8_Sint,
	  	 .Rgba8_Unorm, .Rgba8_Unorm_Srgb, .
		 Rgba8_Snorm, .Rgba8_Uint, .Rgba8_Sint, .Bgra8_Unorm,
		 .Bgra8_Unorm_Srgb: return 1
	case .R16_Uint, .R16_Sint, .R16_Unorm, .R16_Snorm, .R16_Float, .Rg16_Uint, .Rg16_Sint,
		 .Rg16_Unorm, .Rg16_Snorm, .Rg16_Float, .Rgba16_Uint, .Rgba16_Sint, .Rgba16_Unorm,
	 	 .Rgba16_Snorm, .Rgba16_Float: return 2

	case .R32_Uint, .R32_Sint, .R32_Float, .Rg32_Uint, .Rg32_Sint, .Rg32_Float, .Rgba32_Uint,
		 .Rgba32_Sint, .Rgba32_Float, .Rgb10a2_Uint, .Rgb10a2_Unorm, .Rg11b10_Ufloat: return 4

	case .Stencil8, .Depth16_Unorm, .Depth24_Plus, .Depth24_Plus_Stencil8, .Depth32_Float,
		 .Depth32_Float_Stencil8, .NV12, .Rgb9e5_Ufloat, .Bc1_Rgba_Unorm, .Bc1_Rgba_Unorm_Srgb,
		 .Bc2_Rgba_Unorm, .Bc2_Rgba_Unorm_Srgb, .Bc3_Rgba_Unorm, .Bc3_Rgba_Unorm_Srgb, .Bc4_R_Unorm,
		 .Bc4_R_Snorm, .Bc5_Rg_Unorm, .Bc5_Rg_Snorm, .Bc6h_Rgb_Ufloat, .Bc6h_Rgb_Float,
		 .Bc7_Rgba_Unorm, .Bc7_Rgba_Unorm_Srgb, .Etc2_Rgb8_Unorm, .Etc2_Rgb8_Unorm_Srgb,
		 .Etc2_Rgb8_A1_Unorm, .Etc2_Rgb8_A1_Unorm_Srgb, .Etc2_Rgba8_Unorm, .Etc2_Rgba8_Unorm_Srgb,
		 .Eac_R11_Unorm, .Eac_R11_Snorm, .Eac_Rg11_Unorm, .Eac_Rg11_Snorm, .Astc4x4_Unorm,
		 .Astc4x4_Unorm_Srgb, .Astc5x4_Unorm, .Astc5x4_Unorm_Srgb, .Astc5x5_Unorm,
		 .Astc5x5_Unorm_Srgb, .Astc6x5_Unorm, .Astc6x5_Unorm_Srgb, .Astc6x6_Unorm,
		 .Astc6x6_Unorm_Srgb, .Astc8x5_Unorm, .Astc8x5_Unorm_Srgb, .Astc8x6_Unorm,
		 .Astc8x6_Unorm_Srgb, .Astc8x8_Unorm, .Astc8x8_Unorm_Srgb, .Astc10x5_Unorm,
		 .Astc10x5_Unorm_Srgb, .Astc10x6_Unorm, .Astc10x6_Unorm_Srgb, .Astc10x8_Unorm,
		 .Astc10x8_Unorm_Srgb, .Astc10x10_Unorm, .Astc10x10_Unorm_Srgb, .Astc12x10_Unorm,
		 .Astc12x10_Unorm_Srgb, .Astc12x12_Unorm, .Astc12x12_Unorm_Srgb:
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
	case .R8_Unorm, .R8_Snorm, .R8_Uint, .R8_Sint, .R16_Unorm, .R16_Snorm, .R16_Uint, .R16_Sint,
		 .R16_Float, .R32_Uint, .R32_Sint, .R32_Float: return 1

	case .Rg8_Unorm, .Rg8_Snorm, .Rg8_Uint, .Rg8_Sint, .Rg16_Unorm, .Rg16_Snorm, .Rg16_Uint,
		 .Rg16_Sint, .Rg16_Float, .Rg32_Uint, .Rg32_Sint, .Rg32_Float:
		return 2

	case .Rgba8_Unorm, .Rgba8_Unorm_Srgb, .Rgba8_Snorm, .Rgba8_Uint, .Rgba8_Sint, .Bgra8_Unorm,
		 .Bgra8_Unorm_Srgb, .Rgba16_Unorm, .Rgba16_Snorm, .Rgba16_Uint, .Rgba16_Sint, .Rgba16_Float,
		 .Rgba32_Uint, .Rgba32_Sint, .Rgba32_Float: return 4

	case .Rgb9e5_Ufloat, .Rg11b10_Ufloat: return 3
	case .Rgb10a2_Uint, .Rgb10a2_Unorm: return 4

	case .Stencil8, .Depth16_Unorm, .Depth24_Plus, .Depth32_Float: return 1

	case .Depth24_Plus_Stencil8, .Depth32_Float_Stencil8:
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

	case .Bc4_R_Unorm, .Bc4_R_Snorm: return 1
	case .Bc5_Rg_Unorm, .Bc5_Rg_Snorm: return 2
	case .Bc6h_Rgb_Ufloat, .Bc6h_Rgb_Float: return 3

	case .Bc1_Rgba_Unorm, .Bc1_Rgba_Unorm_Srgb, .Bc2_Rgba_Unorm, .Bc2_Rgba_Unorm_Srgb,
		 .Bc3_Rgba_Unorm, .Bc3_Rgba_Unorm_Srgb, .Bc7_Rgba_Unorm, .Bc7_Rgba_Unorm_Srgb:
		return 4

	case .Eac_R11_Unorm, .Eac_R11_Snorm: return 1
	case .Eac_Rg11_Unorm, .Eac_Rg11_Snorm: return 2
	case .Etc2_Rgb8_Unorm, .Etc2_Rgb8_Unorm_Srgb: return 3

	case .Etc2_Rgb8_A1_Unorm, .Etc2_Rgb8_A1_Unorm_Srgb, .Etc2_Rgba8_Unorm,
		 .Etc2_Rgba8_Unorm_Srgb:
		return 4

	case .Astc4x4_Unorm, .Astc4x4_Unorm_Srgb, .Astc5x4_Unorm, .Astc5x4_Unorm_Srgb,
		 .Astc5x5_Unorm, .Astc5x5_Unorm_Srgb, .Astc6x5_Unorm, .Astc6x5_Unorm_Srgb, .Astc6x6_Unorm,
		 .Astc6x6_Unorm_Srgb, .Astc8x5_Unorm, .Astc8x5_Unorm_Srgb, .Astc8x6_Unorm,
		 .Astc8x6_Unorm_Srgb, .Astc8x8_Unorm, .Astc8x8_Unorm_Srgb, .Astc10x5_Unorm,
		 .Astc10x5_Unorm_Srgb, .Astc10x6_Unorm, .Astc10x6_Unorm_Srgb, .Astc10x8_Unorm,
		 .Astc10x8_Unorm_Srgb, .Astc10x10_Unorm, .Astc10x10_Unorm_Srgb, .Astc12x10_Unorm,
		 .Astc12x10_Unorm_Srgb, .Astc12x12_Unorm, .Astc12x12_Unorm_Srgb:
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
	case .Rgba8_Unorm_Srgb: return .Rgba8_Unorm
	case .Bgra8_Unorm_Srgb: return .Bgra8_Unorm
	case .Bc1_Rgba_Unorm_Srgb: return .Bc1_Rgba_Unorm
	case .Bc2_Rgba_Unorm_Srgb: return .Bc2_Rgba_Unorm
	case .Bc3_Rgba_Unorm_Srgb: return .Bc3_Rgba_Unorm
	case .Bc7_Rgba_Unorm_Srgb: return .Bc7_Rgba_Unorm
	case .Etc2_Rgb8_Unorm_Srgb: return .Etc2_Rgb8_Unorm
	case .Etc2_Rgb8_A1_Unorm_Srgb: return .Etc2_Rgb8_A1_Unorm
	case .Etc2_Rgba8_Unorm_Srgb: return .Etc2_Rgba8_Unorm
	case .Astc4x4_Unorm_Srgb: return .Astc4x4_Unorm
	case .Astc5x4_Unorm_Srgb: return .Astc5x4_Unorm
	case .Astc5x5_Unorm_Srgb: return .Astc5x5_Unorm
	case .Astc6x5_Unorm_Srgb: return .Astc6x5_Unorm
	case .Astc6x6_Unorm_Srgb: return .Astc6x6_Unorm
	case .Astc8x5_Unorm_Srgb: return .Astc8x5_Unorm
	case .Astc8x6_Unorm_Srgb: return .Astc8x6_Unorm
	case .Astc8x8_Unorm_Srgb: return .Astc8x8_Unorm
	case .Astc10x5_Unorm_Srgb: return .Astc10x5_Unorm
	case .Astc10x6_Unorm_Srgb: return .Astc10x6_Unorm
	case .Astc10x8_Unorm_Srgb: return .Astc10x8_Unorm
	case .Astc10x10_Unorm_Srgb: return .Astc10x10_Unorm
	case .Astc12x10_Unorm_Srgb: return .Astc12x10_Unorm
	case .Astc12x12_Unorm_Srgb: return .Astc12x12_Unorm
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
	case .Rgba8_Unorm: return .Rgba8_Unorm_Srgb
	case .Bgra8_Unorm: return .Bgra8_Unorm_Srgb
	case .Bc1_Rgba_Unorm: return .Bc1_Rgba_Unorm_Srgb
	case .Bc2_Rgba_Unorm: return .Bc2_Rgba_Unorm_Srgb
	case .Bc3_Rgba_Unorm: return .Bc3_Rgba_Unorm_Srgb
	case .Bc7_Rgba_Unorm: return .Bc7_Rgba_Unorm_Srgb
	case .Etc2_Rgb8_Unorm: return .Etc2_Rgb8_Unorm_Srgb
	case .Etc2_Rgb8_A1_Unorm: return .Etc2_Rgb8_A1_Unorm_Srgb
	case .Etc2_Rgba8_Unorm: return .Etc2_Rgba8_Unorm_Srgb
	case .Astc4x4_Unorm: return .Astc4x4_Unorm_Srgb
	case .Astc5x4_Unorm: return .Astc5x4_Unorm_Srgb
	case .Astc5x5_Unorm: return .Astc5x5_Unorm_Srgb
	case .Astc6x5_Unorm: return .Astc6x5_Unorm_Srgb
	case .Astc6x6_Unorm: return .Astc6x6_Unorm_Srgb
	case .Astc8x5_Unorm: return .Astc8x5_Unorm_Srgb
	case .Astc8x6_Unorm: return .Astc8x6_Unorm_Srgb
	case .Astc8x8_Unorm: return .Astc8x8_Unorm_Srgb
	case .Astc10x5_Unorm: return .Astc10x5_Unorm_Srgb
	case .Astc10x6_Unorm: return .Astc10x6_Unorm_Srgb
	case .Astc10x8_Unorm: return .Astc10x8_Unorm_Srgb
	case .Astc10x10_Unorm: return .Astc10x10_Unorm_Srgb
	case .Astc12x10_Unorm: return .Astc12x10_Unorm_Srgb
	case .Astc12x12_Unorm: return .Astc12x12_Unorm_Srgb
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
