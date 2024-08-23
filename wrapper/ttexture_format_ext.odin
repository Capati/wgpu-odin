package wgpu

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

/* Returns `true` if the format has a depth aspect. */
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

/*
Returns the dimension of a [block](https://gpuweb.github.io/gpuweb/#texel-block) of texels.

Uncompressed formats have a block dimension of `(1, 1)`.
*/
texture_format_block_dimensions :: proc "contextless" (self: Texture_Format) -> (w, h: u32) {
	// Commented formats are unimplemented in webgpu.h
	#partial switch self {
	case .R8_Unorm, .R8_Snorm, .R8_Uint, .R8_Sint, .R16_Uint, .R16_Sint, /*.R16_Unorm,*/
	     /*.R16_Snorm,*/ .R16_Float, .Rg8_Unorm, .Rg8_Snorm, .Rg8_Uint, .Rg8_Sint, .R32_Uint,
	     .R32_Sint, .R32_Float, .Rg16_Uint, .Rg16_Sint, /*.Rg16_Unorm,*/ /*.Rg16_Snorm,*/
		 .Rg16_Float, .Rgba8_Unorm, .Rgba8_Unorm_Srgb, .Rgba8_Snorm, .Rgba8_Uint, .Rgba8_Sint,
	     .Bgra8_Unorm, .Bgra8_Unorm_Srgb, .Rgb9_E5_Ufloat, .Rgb10_A2_Uint, .Rgb10_A2_Unorm,
		 .Rg11_B10_Ufloat, .Rg32_Uint, .Rg32_Sint, .Rg32_Float, .Rgba16_Uint, .Rgba16_Sint,
	     /*.Rgba16_Unorm,*/ /*.Rgba16_Snorm,*/ .Rgba16_Float, .Rgba32_Uint, .Rgba32_Sint,
		 .Rgba32_Float, .Stencil8, .Depth16_Unorm, .Depth24_Plus, .Depth24_Plus_Stencil8,
	     .Depth32_Float, .Depth32_Float_Stencil8:
		return 1, 1

	case .Bc1_Rgba_Unorm, .Bc1_Rgba_Unorm_Srgb, .Bc2_Rgba_Unorm, .Bc2_Rgba_Unorm_Srgb,
		 .Bc3_Rgba_Unorm, .Bc3_Rgba_Unorm_Srgb, .Bc4_R_Unorm, .Bc4_R_Snorm, .Bc5_Rg_Unorm,
	  	 .Bc5_Rg_Snorm, .Bc6_Hrgb_Ufloat, .Bc6_Hrgb_Float, .Bc7_Rgba_Unorm, .Bc7_Rgba_Unorm_Srgb,
		 .Etc2_Rgb8_Unorm, .Etc2_Rgb8_Unorm_Srgb, .Etc2_Rgb8_A1_Unorm, .Etc2_Rgb8_A1_Unorm_Srgb,
		 .Etc2_Rgba8_Unorm, .Etc2_Rgba8_Unorm_Srgb, .Eacr11_Unorm, .Eacr11_Snorm, .Eacrg11_Unorm,
		 .Eacrg11_Snorm:
		return 4, 4

	case .Astc4x4_Unorm, .Astc4x4_Unorm_Srgb: return 4, 4
	case .Astc5x4_Unorm, .Astc5x4_Unorm_Srgb: return 5, 5
	case .Astc5x5_Unorm, .Astc5x5_Unorm_Srgb: return 5, 5
	case .Astc6x5_Unorm, .Astc6x5_Unorm_Srgb: return 6, 5
	case .Astc6x6_Unorm, .Astc6x6_Unorm_Srgb: return 6, 6
	case .Astc8x5_Unorm, .Astc8x5_Unorm_Srgb: return 8, 5
	case .Astc8x6_Unorm, .Astc8x6_Unorm_Srgb: return  8, 6
	case .Astc8x8_Unorm, .Astc8x8_Unorm_Srgb: return 8, 8
	case .Astc10x5_Unorm, .Astc10x5_Unorm_Srgb: return 10, 5
	case .Astc10x6_Unorm, .Astc10x6_Unorm_Srgb: return 10, 6
	case .Astc10x8_Unorm, .Astc10x8_Unorm_Srgb: return 10, 8
	case .Astc10x10_Unorm, .Astc10x10_Unorm_Srgb: return 10, 10
	case .Astc12x10_Unorm, .Astc12x10_Unorm_Srgb: return 12, 10
	case .Astc12x12_Unorm, .Astc12x12_Unorm_Srgb: return 12, 12
	}

	return 1, 1
}

/* Returns `true` for compressed formats. */
texture_format_is_compressed :: proc "contextless" (self: Texture_Format) -> bool {
	w, h := texture_format_block_dimensions(self)
	return w != 1 && h != 1
}

/* Returns the required features (if any) in order to use the texture. */
texture_format_required_features :: proc "contextless" (self: Texture_Format) -> Features {
	#partial switch self {
	case .R8_Unorm, .R8_Snorm, .R8_Uint, .R8_Sint, .R16_Uint, .R16_Sint, .R16_Float, .Rg8_Unorm,
		 .Rg8_Snorm, .Rg8_Uint, .Rg8_Sint, .R32_Float, .R32_Uint, .R32_Sint, .Rg16_Uint,
	     .Rg16_Sint, .Rg16_Float, .Rgba8_Unorm, .Rgba8_Unorm_Srgb, .Rgba8_Snorm, .Rgba8_Uint,
		 .Rgba8_Sint, .Bgra8_Unorm, .Bgra8_Unorm_Srgb, .Rgb10_A2_Uint, .Rgb10_A2_Unorm,
		 .Rg11_B10_Ufloat, .Rgb9_E5_Ufloat, .Rg32_Float, .Rg32_Uint, .Rg32_Sint, .Rgba16_Uint,
	     .Rgba16_Sint, .Rgba16_Float, .Rgba32_Float, .Rgba32_Uint, .Rgba32_Sint, .Stencil8,
	     .Depth16_Unorm, .Depth24_Plus, .Depth24_Plus_Stencil8, .Depth32_Float:
		return {} // empty, no features need

	case .Depth32_Float_Stencil8:
		return {.Depth32_Float_Stencil8}

	case .Bc1_Rgba_Unorm, .Bc1_Rgba_Unorm_Srgb, .Bc2_Rgba_Unorm, .Bc2_Rgba_Unorm_Srgb,
		 .Bc3_Rgba_Unorm, .Bc3_Rgba_Unorm_Srgb, .Bc4_R_Unorm, .Bc4_R_Snorm, .Bc5_Rg_Unorm,
		 .Bc5_Rg_Snorm, .Bc6_Hrgb_Ufloat, .Bc6_Hrgb_Float, .Bc7_Rgba_Unorm, .Bc7_Rgba_Unorm_Srgb:
		return {.Texture_Compression_Bc}

	case .Etc2_Rgb8_Unorm, .Etc2_Rgb8_Unorm_Srgb, .Etc2_Rgb8_A1_Unorm, .Etc2_Rgb8_A1_Unorm_Srgb,
		 .Etc2_Rgba8_Unorm, .Etc2_Rgba8_Unorm_Srgb, .Eacr11_Unorm, .Eacr11_Snorm, .Eacrg11_Unorm,
		 .Eacrg11_Snorm:
		return {.Texture_Compression_Etc2}

	// case .R16_Unorm,
	//      .R16_Snorm,
	//      .Rg16_Unorm,
	//      .Rg16_Snorm,
	//      .Rgba16_Unorm,
	//      .Rgba16_Snorm:
	// 	return {}

	case .Astc4x4_Unorm, .Astc4x4_Unorm_Srgb, .Astc5x4_Unorm, .Astc5x4_Unorm_Srgb, .Astc5x5_Unorm,
		 .Astc5x5_Unorm_Srgb, .Astc6x5_Unorm, .Astc6x5_Unorm_Srgb, .Astc6x6_Unorm,
		 .Astc6x6_Unorm_Srgb, .Astc8x5_Unorm, .Astc8x5_Unorm_Srgb, .Astc8x6_Unorm,
		 .Astc8x6_Unorm_Srgb, .Astc8x8_Unorm, .Astc8x8_Unorm_Srgb, .Astc10x5_Unorm,
		 .Astc10x5_Unorm_Srgb, .Astc10x6_Unorm, .Astc10x6_Unorm_Srgb, .Astc10x8_Unorm,
		 .Astc10x8_Unorm_Srgb, .Astc10x10_Unorm, .Astc10x10_Unorm_Srgb, .Astc12x10_Unorm,
		 .Astc12x10_Unorm_Srgb, .Astc12x12_Unorm, .Astc12x12_Unorm_Srgb:
		return {.Texture_Compression_Astc}
	}

	return {}
}

Texture_Usage_Feature :: enum ENUM_SIZE {
	Filterable,
	Multisample_X2,
	Multisample_X4,
	Multisample_X8,
	Multisample_X16,
	Multisample_Resolve,
	Storage_Read_Write,
	Blendable,
}

/* Feature flags for a texture format. */
Texture_Usage_Feature_Flags :: bit_set[Texture_Usage_Feature;FLAGS]

/* Features supported by a given texture format */
Texture_Format_Features :: struct {
	allowed_usages: Texture_Usage_Flags,
	flags:          Texture_Usage_Feature_Flags,
}

texture_usage_feature_flags_sample_count_supported :: proc "contextless" (
	self: Texture_Usage_Feature_Flags,
	count: u32,
) -> bool {
	switch count {
	case 1: return true
	case 2: return .Multisample_X2 in self
	case 4: return .Multisample_X4 in self
	case 8: return .Multisample_X8 in self
	case 16: return .Multisample_X16 in self
	}

	return false
}

/*
Returns the sample type compatible with this format and aspect.

Returns `Undefined` only if this is a combined depth-stencil format or a multi-planar format
and `TextureAspect::All`.
*/
texture_format_sample_type :: proc "contextless" (
	self: Texture_Format,
	aspect: Maybe(Texture_Aspect) = nil,
	device_features: Device_Features = {},
) -> Texture_Sample_Type {
	float_filterable := Texture_Sample_Type.Float
	// unfilterable_float := Texture_Sample_Type.Unfilterable_Float
	float32_sample_type := Texture_Sample_Type.Unfilterable_Float
	if .Float32_Filterable in device_features {
		float32_sample_type = .Float
	}
	depth := Texture_Sample_Type.Depth
	_uint := Texture_Sample_Type.Uint
	sint := Texture_Sample_Type.Sint

	#partial switch self {
	case .R8_Unorm, .R8_Snorm, .Rg8_Unorm, .Rg8_Snorm, .Rgba8_Unorm, .Rgba8_Unorm_Srgb,
	     .Rgba8_Snorm, .Bgra8_Unorm, .Bgra8_Unorm_Srgb, .R16_Float, .Rg16_Float, .Rgba16_Float,
	     .Rgb10_A2_Unorm, .Rg11_B10_Ufloat:
		return float_filterable

	case .R32_Float, .Rg32_Float, .Rgba32_Float:
		return float32_sample_type

	case .R8_Uint, .Rg8_Uint, .Rgba8_Uint, .R16_Uint, .Rg16_Uint, .Rgba16_Uint, .R32_Uint,
	     .Rg32_Uint, .Rgba32_Uint, .Rgb10_A2_Uint:
		return _uint

	case .R8_Sint, .Rg8_Sint, .Rgba8_Sint, .R16_Sint, .Rg16_Sint, .Rgba16_Sint,
	     .R32_Sint, .Rg32_Sint, .Rgba32_Sint:
		return sint

	case .Stencil8:
		return _uint

	case .Depth16_Unorm, .Depth24_Plus, .Depth32_Float:
		return depth

	case .Depth24_Plus_Stencil8, .Depth32_Float_Stencil8:
		_aspect, aspect_ok := aspect.?
		if aspect_ok {
			if _aspect == .Depth_Only do return depth
			if _aspect == .Stencil_Only do return _uint
		}
		return .Undefined

	// case .Nv12:
	// 	return unfilterable_float

	// case .R16_Unorm, .R16_Snorm, .Rg16_Unorm, .Rg16_Snorm, .Rgba16_Unorm, .Rgba16_Snorm:
	// 	return float_filterable

	case .Rgb9_E5_Ufloat, .Bc1_Rgba_Unorm, .Bc1_Rgba_Unorm_Srgb, .Bc2_Rgba_Unorm,
		 .Bc2_Rgba_Unorm_Srgb, .Bc3_Rgba_Unorm, .Bc3_Rgba_Unorm_Srgb, .Bc4_R_Unorm,
	     .Bc4_R_Snorm, .Bc5_Rg_Unorm, .Bc5_Rg_Snorm, .Bc6_Hrgb_Ufloat, .Bc6_Hrgb_Float,
	     .Bc7_Rgba_Unorm, .Bc7_Rgba_Unorm_Srgb, .Etc2_Rgb8_Unorm, .Etc2_Rgb8_Unorm_Srgb,
	     .Etc2_Rgb8_A1_Unorm, .Etc2_Rgb8_A1_Unorm_Srgb, .Etc2_Rgba8_Unorm, .Etc2_Rgba8_Unorm_Srgb,
	     .Eacr11_Unorm, .Eacr11_Snorm, .Eacrg11_Unorm, .Eacrg11_Snorm, .Astc4x4_Unorm,
		 .Astc4x4_Unorm_Srgb, .Astc5x4_Unorm, .Astc5x4_Unorm_Srgb, .Astc5x5_Unorm,
		 .Astc5x5_Unorm_Srgb, .Astc6x5_Unorm, .Astc6x5_Unorm_Srgb, .Astc6x6_Unorm,
		 .Astc6x6_Unorm_Srgb, .Astc8x5_Unorm, .Astc8x5_Unorm_Srgb, .Astc8x6_Unorm,
	     .Astc8x6_Unorm_Srgb, .Astc8x8_Unorm, .Astc8x8_Unorm_Srgb, .Astc10x5_Unorm,
		 .Astc10x5_Unorm_Srgb, .Astc10x6_Unorm, .Astc10x6_Unorm_Srgb, .Astc10x8_Unorm,
		 .Astc10x8_Unorm_Srgb, .Astc10x10_Unorm, .Astc10x10_Unorm_Srgb, .Astc12x10_Unorm,
	     .Astc12x10_Unorm_Srgb, .Astc12x12_Unorm, .Astc12x12_Unorm_Srgb:
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
	self: Texture_Format,
	device_features: Device_Features,
) -> (
	features: Texture_Format_Features,
) {
	// Multisampling
	noaa: Texture_Usage_Feature_Flags
	msaa: Texture_Usage_Feature_Flags = {.Multisample_X4}
	msaa_resolve: Texture_Usage_Feature_Flags = msaa + {.Multisample_Resolve}

	// Flags
	basic: Texture_Usage_Flags = {.Copy_Src, .Copy_Dst, .Texture_Binding}
	attachment: Texture_Usage_Flags = basic + {.Render_Attachment}
	storage: Texture_Usage_Flags = basic + {.Storage_Binding}
	// binding: Texture_Usage_Flags = {.Texture_Binding}
	all_flags := Texture_Usage_Flags_All
	rg11b10f := attachment if .Rg11_B10_Ufloat_Renderable in device_features else basic
	bgra8unorm := attachment + storage if .Bgra8_Unorm_Storage in device_features else attachment

	flags: Texture_Usage_Feature_Flags
	allowed_usages: Texture_Usage_Flags

	#partial switch self {
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
	case .Rgb10_A2_Uint: flags = msaa; allowed_usages = attachment
	case .Rgb10_A2_Unorm: flags = msaa_resolve; allowed_usages = attachment
	case .Rg11_B10_Ufloat: flags = msaa; allowed_usages = rg11b10f
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
	// case .Nv12: flags = noaa; allowed_usages = binding
	// case .TextureFormat_NV12: flags = noaa; allowed_usages = binding
	// case .R16_Unorm: flags = msaa; allowed_usages = storage
	// case .R16_Snorm: flags = msaa; allowed_usages = storage
	// case .Rg16_Unorm: flags = msaa; allowed_usages = storage
	// case .Rg16_Snorm: flags = msaa; allowed_usages = storage
	// case .Rgba16_Unorm: flags = msaa; allowed_usages = storage
	// case .Rgba16_Snorm: flags = msaa; allowed_usages = storage
	case .Rgb9_E5_Ufloat: flags = noaa; allowed_usages = basic
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
	case .Bc6_Hrgb_Ufloat: flags = noaa; allowed_usages = basic
	case .Bc6_Hrgb_Float: flags = noaa; allowed_usages = basic
	case .Bc7_Rgba_Unorm: flags = noaa; allowed_usages = basic
	case .Bc7_Rgba_Unorm_Srgb: flags = noaa; allowed_usages = basic
	case .Etc2_Rgb8_Unorm: flags = noaa; allowed_usages = basic
	case .Etc2_Rgb8_Unorm_Srgb: flags = noaa; allowed_usages = basic
	case .Etc2_Rgb8_A1_Unorm: flags = noaa; allowed_usages = basic
	case .Etc2_Rgb8_A1_Unorm_Srgb: flags = noaa; allowed_usages = basic
	case .Etc2_Rgba8_Unorm: flags = noaa; allowed_usages = basic
	case .Etc2_Rgba8_Unorm_Srgb: flags = noaa; allowed_usages = basic
	case .Eacr11_Unorm: flags = noaa; allowed_usages = basic
	case .Eacr11_Snorm: flags = noaa; allowed_usages = basic
	case .Eacrg11_Unorm: flags = noaa; allowed_usages = basic
	case .Eacrg11_Snorm: flags = noaa; allowed_usages = basic
	case .Astc4x4_Unorm, .Astc4x4_Unorm_Srgb, .Astc5x4_Unorm, .Astc5x4_Unorm_Srgb, .Astc5x5_Unorm,
		 .Astc5x5_Unorm_Srgb, .Astc6x5_Unorm, .Astc6x5_Unorm_Srgb, .Astc6x6_Unorm,
		 .Astc6x6_Unorm_Srgb, .Astc8x5_Unorm, .Astc8x5_Unorm_Srgb, .Astc8x6_Unorm,
		 .Astc8x6_Unorm_Srgb, .Astc8x8_Unorm, .Astc8x8_Unorm_Srgb, .Astc10x5_Unorm,
         .Astc10x5_Unorm_Srgb, .Astc10x6_Unorm, .Astc10x6_Unorm_Srgb, .Astc10x8_Unorm,
		 .Astc10x8_Unorm_Srgb, .Astc10x10_Unorm, .Astc10x10_Unorm_Srgb, .Astc12x10_Unorm,
		 .Astc12x10_Unorm_Srgb, .Astc12x12_Unorm, .Astc12x12_Unorm_Srgb:
		flags = noaa; allowed_usages = basic
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
	self: Texture_Format,
	aspect: Maybe(Texture_Aspect) = nil,
) -> u32 {
	_aspect, aspect_ok := aspect.?

	#partial switch self {
	case .R8_Unorm, .R8_Snorm, .R8_Uint, .R8_Sint:
		return 1

	case .Rg8_Unorm, .Rg8_Snorm, .Rg8_Uint, .Rg8_Sint:
		return 2

	case .R16_Uint, .R16_Sint, .R16_Float, .Rg16_Uint, .Rg16_Sint, .Rg16_Float,
	     .Rgb10_A2_Uint, .Rg11_B10_Ufloat, .Rgb9_E5_Ufloat:
		return 4

	case .Rgba8_Unorm, .Rgba8_Unorm_Srgb, .Rgba8_Snorm, .Rgba8_Uint, .Rgba8_Sint,
	     .Bgra8_Unorm, .Bgra8_Unorm_Srgb:
		return 4

	case .R32_Uint, .R32_Sint, .R32_Float, .Rg32_Uint, .Rg32_Sint, .Rg32_Float:
		return 8

	case .Rgba16_Uint, .Rgba16_Sint, .Rgba16_Float, .Rgba32_Uint, .Rgba32_Sint, .Rgba32_Float,
	     .Bc1_Rgba_Unorm, .Bc1_Rgba_Unorm_Srgb, .Bc4_R_Unorm, .Bc4_R_Snorm, .Bc5_Rg_Unorm,
	     .Bc5_Rg_Snorm, .Bc6_Hrgb_Ufloat, .Bc6_Hrgb_Float, .Bc7_Rgba_Unorm, .Bc7_Rgba_Unorm_Srgb,
		 .Etc2_Rgb8_Unorm, .Etc2_Rgb8_Unorm_Srgb, .Etc2_Rgb8_A1_Unorm, .Etc2_Rgb8_A1_Unorm_Srgb,
		 .Etc2_Rgba8_Unorm, .Etc2_Rgba8_Unorm_Srgb, .Eacr11_Unorm, .Eacr11_Snorm, .Eacrg11_Unorm,
	     .Eacrg11_Snorm, .Astc4x4_Unorm, .Astc4x4_Unorm_Srgb, .Astc5x4_Unorm, .Astc5x4_Unorm_Srgb,
	     .Astc5x5_Unorm, .Astc5x5_Unorm_Srgb, .Astc6x5_Unorm, .Astc6x5_Unorm_Srgb, .Astc6x6_Unorm,
	     .Astc6x6_Unorm_Srgb, .Astc8x5_Unorm, .Astc8x5_Unorm_Srgb, .Astc8x6_Unorm,
		 .Astc8x6_Unorm_Srgb, .Astc8x8_Unorm, .Astc8x8_Unorm_Srgb, .Astc10x5_Unorm,
	     .Astc10x5_Unorm_Srgb, .Astc10x6_Unorm, .Astc10x6_Unorm_Srgb, .Astc10x8_Unorm,
	     .Astc10x8_Unorm_Srgb, .Astc10x10_Unorm, .Astc10x10_Unorm_Srgb, .Astc12x10_Unorm,
	     .Astc12x10_Unorm_Srgb, .Astc12x12_Unorm, .Astc12x12_Unorm_Srgb:
		return 16

	case .Stencil8:
		return 1

	case .Depth16_Unorm:
		return 2

	case .Depth32_Float:
		return 4

	case .Depth24_Plus:
		return 0

	case .Depth24_Plus_Stencil8:
		if aspect_ok {
			#partial switch _aspect {
			case .Depth_Only:
				return 0
			case .Stencil_Only:
				return 1
			}
		}
		return 0

	case .Depth32_Float_Stencil8:
		if aspect_ok {
			#partial switch _aspect {
			case .Depth_Only:
				return 4
			case .Stencil_Only:
				return 1
			}
		}
		return 0
	}

	return 0
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

/*
The number of bytes occupied per pixel in a color attachment
<https://gpuweb.github.io/gpuweb/#render-target-pixel-byte-cost>
*/
texture_format_target_pixel_byte_cost :: proc "contextless" (self: Texture_Format) -> u32 {
	#partial switch self {
	case .R8_Unorm, .R8_Uint, .R8_Sint:
		return 1

	case .Rg8_Unorm, .Rg8_Uint, .Rg8_Sint, .R16_Uint, .R16_Sint, .R16_Float:
		return 2

	case .Rgba8_Uint, .Rgba8_Sint, .Rg16_Uint, .Rg16_Sint, .Rg16_Float,
	     .R32_Uint, .R32_Sint, .R32_Float:
		return 4

	case .Rgba8_Unorm, .Rgba8_Unorm_Srgb, .Bgra8_Unorm, .Bgra8_Unorm_Srgb, .Rgba16_Uint,
		 .Rgba16_Sint, .Rgba16_Float, .Rg32_Uint, .Rg32_Sint, .Rg32_Float, .Rgb10_A2_Uint,
	     .Rgb10_A2_Unorm, .Rg11_B10_Ufloat:
		return 8

	case .Rgba32_Uint, .Rgba32_Sint, .Rgba32_Float:
		return 16
	}

	return 0
}

/* See <https://gpuweb.github.io/gpuweb/#render-target-component-alignment> */
texture_format_target_component_alignment :: proc "contextless" (self: Texture_Format) -> u32 {
	#partial switch self {
	case .R8_Unorm, .R8_Snorm, .R8_Uint, .R8_Sint, .Rg8_Unorm, .Rg8_Snorm, .Rg8_Uint,
	     .Rg8_Sint, .Rgba8_Unorm, .Rgba8_Unorm_Srgb, .Rgba8_Snorm, .Rgba8_Uint, .Rgba8_Sint,
	     .Bgra8_Unorm, .Bgra8_Unorm_Srgb:
		return 1

	case .R16_Uint, .R16_Sint, .R16_Float, .Rg16_Uint, .Rg16_Sint, .Rg16_Float, .Rgba16_Uint,
	     .Rgba16_Sint, .Rgba16_Float:
		return 2

	case .R32_Uint, .R32_Sint, .R32_Float, .Rg32_Uint, .Rg32_Sint, .Rg32_Float, .Rgba32_Uint,
		 .Rgba32_Sint, .Rgba32_Float, .Rgb10_A2_Uint, .Rgb10_A2_Unorm, .Rg11_B10_Ufloat:
		return 4
	}

	return 0
}

/*
Returns the number of components this format has taking into account the `aspect`.

The `aspect` is only relevant for combined depth-stencil formats and multi-planar formats.
*/
texture_format_components_with_aspect :: proc "contextless" (
	self: Texture_Format,
	aspect: Texture_Aspect,
) -> u8 {
	#partial switch self {
	case .R8_Unorm, .R8_Snorm, .R8_Uint, .R8_Sint, /*.R16_Unorm,*/ /*.R16_Snorm,*/
	     .R16_Uint, .R16_Sint, .R16_Float, .R32_Uint, .R32_Sint, .R32_Float:
		return 1

	case .Rg8_Unorm, .Rg8_Snorm, .Rg8_Uint, .Rg8_Sint, /*.Rg16_Unorm,*/ /*.Rg16_Snorm,*/
	     .Rg16_Uint, .Rg16_Sint, .Rg16_Float, .Rg32_Uint, .Rg32_Sint, .Rg32_Float:
		return 2

	case .Rgba8_Unorm, .Rgba8_Unorm_Srgb, .Rgba8_Snorm, .Rgba8_Uint, .Rgba8_Sint, .Bgra8_Unorm,
		 .Bgra8_Unorm_Srgb, /*.Rgba16_Unorm,*/ /*.Rgba16_Snorm,*/ .Rgba16_Uint, .Rgba16_Sint,
	     .Rgba16_Float, .Rgba32_Uint, .Rgba32_Sint, .Rgba32_Float, .Rgb10_A2_Uint, .Rgb10_A2_Unorm:
		return 4

	case .Rgb9_E5_Ufloat, .Rg11_B10_Ufloat:
		return 3

	case .Stencil8, .Depth16_Unorm, .Depth24_Plus, .Depth32_Float:
		return 1

	case .Depth24_Plus_Stencil8, .Depth32_Float_Stencil8:
		switch aspect {
		case .Depth_Only, .Stencil_Only: return 1
		case .All: return 2
		}

	case .Bc4_R_Unorm, .Bc4_R_Snorm, .Eacr11_Unorm, .Eacr11_Snorm:
		return 1

	case .Bc5_Rg_Unorm, .Bc5_Rg_Snorm, .Eacrg11_Unorm, .Eacrg11_Snorm:
		return 2

	case .Bc6_Hrgb_Ufloat, .Bc6_Hrgb_Float, .Etc2_Rgb8_Unorm, .Etc2_Rgb8_Unorm_Srgb:
		return 3

	case .Bc1_Rgba_Unorm, .Bc1_Rgba_Unorm_Srgb, .Bc2_Rgba_Unorm, .Bc2_Rgba_Unorm_Srgb,
		 .Bc3_Rgba_Unorm, .Bc3_Rgba_Unorm_Srgb, .Bc7_Rgba_Unorm, .Bc7_Rgba_Unorm_Srgb,
		 .Etc2_Rgb8_A1_Unorm, .Etc2_Rgb8_A1_Unorm_Srgb, .Etc2_Rgba8_Unorm, .Etc2_Rgba8_Unorm_Srgb,
		 .Astc4x4_Unorm, .Astc4x4_Unorm_Srgb, .Astc5x4_Unorm, .Astc5x4_Unorm_Srgb, .Astc5x5_Unorm,
	     .Astc5x5_Unorm_Srgb, .Astc6x5_Unorm, .Astc6x5_Unorm_Srgb, .Astc6x6_Unorm,
		 .Astc6x6_Unorm_Srgb, .Astc8x5_Unorm, .Astc8x5_Unorm_Srgb, .Astc8x6_Unorm,
		 .Astc8x6_Unorm_Srgb, .Astc8x8_Unorm, .Astc8x8_Unorm_Srgb, .Astc10x5_Unorm,
	     .Astc10x5_Unorm_Srgb, .Astc10x6_Unorm, .Astc10x6_Unorm_Srgb, .Astc10x8_Unorm,
	     .Astc10x8_Unorm_Srgb, .Astc10x10_Unorm, .Astc10x10_Unorm_Srgb, .Astc12x10_Unorm,
	     .Astc12x10_Unorm_Srgb, .Astc12x12_Unorm, .Astc12x12_Unorm_Srgb:
		return 4
	}

	return 0
}

/* Returns the number of components this format has. */
texture_format_components :: proc "contextless" (self: Texture_Format) -> u8 {
	return texture_format_components_with_aspect(self, .All)
}

/* Strips the `Srgb` suffix from the given texture format. */
texture_format_remove_srgb_suffix :: proc "contextless" (
	self: Texture_Format,
) -> (
	ret: Texture_Format,
) {
	ret = self

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

	return
}

/* Adds an `Srgb` suffix to the given texture format, if the format supports it. */
texture_format_add_srgb_suffix :: proc "contextless" (
	self: Texture_Format,
) -> (
	ret: Texture_Format,
) {
	ret = self

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

	return
}

/* Returns `true` for srgb formats. */
texture_format_is_srgb :: proc "contextless" (self: Texture_Format) -> bool {
	return self != texture_format_remove_srgb_suffix(self)
}
