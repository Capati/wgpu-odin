package wgpu

@(private)
// Webgpu and native features.
Raw_Feature_Name :: enum FLAGS {
	Undefined                                                     = 0x00000000,
	Depth_Clip_Control                                            = 0x00000001,
	Depth32_Float_Stencil8                                        = 0x00000002,
	Timestamp_Query                                               = 0x00000003,
	Texture_Compression_Bc                                        = 0x00000004,
	Texture_Compression_Etc2                                      = 0x00000005,
	Texture_Compression_Astc                                      = 0x00000006,
	Indirect_First_Instance                                       = 0x00000007,
	Shader_F16                                                    = 0x00000008,
	Rg11_B10_Ufloat_Renderable                                    = 0x00000009,
	Bgra8_Unorm_Storage                                           = 0x0000000A,
	Float32_Filterable                                            = 0x0000000B,

	// Native features
	Push_Constants                                                = 0x00030001,
	Texture_Adapter_Specific_Format_Features                      = 0x00030002,
	Multi_Draw_Indirect                                           = 0x00030003,
	Multi_Draw_Indirect_Count                                     = 0x00030004,
	Vertex_Writable_Storage                                       = 0x00030005,
	Texture_Binding_Array                                         = 0x00030006,
	Sampled_Texture_And_Storage_Buffer_Array_Non_Uniform_Indexing = 0x00030007,
	Pipeline_Statistics_Query                                     = 0x00030008,
	Storage_Resource_Binding_Array                                = 0x00030009,
	Partially_Bound_Binding_Array                                 = 0x0003000A,
}

Feature_Name :: enum FLAGS {
	Undefined,
	Depth_Clip_Control,
	Depth32_Float_Stencil8,
	Timestamp_Query,
	Texture_Compression_Bc,
	Texture_Compression_Etc2,
	Texture_Compression_Astc,
	Indirect_First_Instance,
	Shader_F16,
	Rg11_B10_Ufloat_Renderable,
	Bgra8_Unorm_Storage,
	Float32_Filterable,

	// Native features
	Push_Constants,
	Texture_Adapter_Specific_Format_Features,
	Multi_Draw_Indirect,
	Multi_Draw_Indirect_Count,
	Vertex_Writable_Storage,
	Texture_Binding_Array,
	Sampled_Texture_And_Storage_Buffer_Array_Non_Uniform_Indexing,
	Pipeline_Statistics_Query,
	Storage_Resource_Binding_Array,
	Partially_Bound_Binding_Array,
}

// Features that are not guaranteed to be supported.
//
// These are either part of the webgpu standard, or are extension features supported by
// wgpu when targeting native.
//
// If you want to use a feature, you need to first verify that the adapter supports
// the feature. If the adapter does not support the feature, requesting a device with it enabled
// will panic.
//
// Corresponds to [WebGPU `GPUFeatureName`](
// https://gpuweb.github.io/gpuweb/#enumdef-gpufeaturename).
Features :: bit_set[Feature_Name;FLAGS]

/*============================================================================
** Public procedures
**============================================================================*/


// Get the flags of all features which are part of the upstream WebGPU standard.
features_all_webgpu_flags :: proc(features: Features) -> (ret: Features) {
	// odinfmt: disable
	for f in features {
		#partial switch f {
		case .Depth_Clip_Control: ret += {.Depth_Clip_Control}
		case .Depth32_Float_Stencil8: ret += {.Depth32_Float_Stencil8}
		case .Timestamp_Query: ret += {.Timestamp_Query}
		case .Texture_Compression_Bc: ret += {.Texture_Compression_Bc}
		case .Texture_Compression_Etc2: ret += {.Texture_Compression_Etc2}
		case .Texture_Compression_Astc: ret += {.Texture_Compression_Astc}
		case .Indirect_First_Instance: ret += {.Indirect_First_Instance}
		case .Shader_F16: ret += {.Shader_F16}
		case .Rg11_B10_Ufloat_Renderable: ret += {.Rg11_B10_Ufloat_Renderable}
		case .Bgra8_Unorm_Storage: ret += {.Bgra8_Unorm_Storage}
		case .Float32_Filterable: ret += {.Float32_Filterable}
		}
	}
	// odinfmt: enable

	return
}

// Get the flags of all features that are only available when targeting native (not web).
features_all_native_flags :: proc(features: Features) -> (ret: Features) {
	// odinfmt: disable
	for f in features {
		#partial switch f {
		case .Push_Constants: ret += {.Push_Constants}
		case .Texture_Adapter_Specific_Format_Features:
			ret += {.Texture_Adapter_Specific_Format_Features}
		case .Multi_Draw_Indirect: ret += {.Multi_Draw_Indirect}
		case .Multi_Draw_Indirect_Count: ret += {.Multi_Draw_Indirect_Count}
		case .Vertex_Writable_Storage: ret += {.Vertex_Writable_Storage}
		case .Texture_Binding_Array: ret += {.Texture_Binding_Array}
		case .Sampled_Texture_And_Storage_Buffer_Array_Non_Uniform_Indexing:
			ret += {.Sampled_Texture_And_Storage_Buffer_Array_Non_Uniform_Indexing}
		case .Pipeline_Statistics_Query: ret += {.Pipeline_Statistics_Query}
		case .Storage_Resource_Binding_Array: ret += {.Storage_Resource_Binding_Array}
		case .Partially_Bound_Binding_Array: ret += {.Partially_Bound_Binding_Array}
		}
	}
	// odinfmt: enable

	return
}

/*============================================================================
** Private procedures
**============================================================================*/


@(private)
features_slice_to_flags :: proc(features_slice: []Raw_Feature_Name) -> (features: Features) {
	// odinfmt: disable
	for &f in features_slice {
		switch f {
		// webgpu features
		case .Undefined: features += {.Undefined}
		case .Depth_Clip_Control: features += {.Depth_Clip_Control}
		case .Depth32_Float_Stencil8: features += {.Depth32_Float_Stencil8}
		case .Timestamp_Query: features += {.Timestamp_Query}
		case .Texture_Compression_Bc: features += {.Texture_Compression_Bc}
		case .Texture_Compression_Etc2: features += {.Texture_Compression_Etc2}
		case .Texture_Compression_Astc: features += {.Texture_Compression_Astc}
		case .Indirect_First_Instance: features += {.Indirect_First_Instance}
		case .Shader_F16: features += {.Shader_F16}
		case .Rg11_B10_Ufloat_Renderable: features += {.Rg11_B10_Ufloat_Renderable}
		case .Bgra8_Unorm_Storage: features += {.Bgra8_Unorm_Storage}
		case .Float32_Filterable: features += {.Float32_Filterable}

		// Native features
		case .Push_Constants: features += {.Push_Constants}
		case .Texture_Adapter_Specific_Format_Features:
			features += {.Texture_Adapter_Specific_Format_Features}
		case .Multi_Draw_Indirect: features += {.Multi_Draw_Indirect}
		case .Multi_Draw_Indirect_Count: features += {.Multi_Draw_Indirect_Count}
		case .Vertex_Writable_Storage: features += {.Vertex_Writable_Storage}
		case .Texture_Binding_Array: features += {.Texture_Binding_Array}
		case .Sampled_Texture_And_Storage_Buffer_Array_Non_Uniform_Indexing:
			features += {.Sampled_Texture_And_Storage_Buffer_Array_Non_Uniform_Indexing}
		case .Pipeline_Statistics_Query: features += {.Pipeline_Statistics_Query}
		case .Storage_Resource_Binding_Array: features += {.Storage_Resource_Binding_Array}
		case .Partially_Bound_Binding_Array: features += {.Partially_Bound_Binding_Array}
		}
	}
	// odinfmt: enable

	return
}

@(private)
features_flag_to_raw_feature_name :: proc(
	feature_name: Feature_Name,
) -> (
	feature: Raw_Feature_Name,
) {
	// odinfmt: disable
	// webgpu features
	switch feature_name {
	case .Undefined: return .Undefined
	case .Depth_Clip_Control: return .Depth_Clip_Control
	case .Depth32_Float_Stencil8: return .Depth32_Float_Stencil8
	case .Timestamp_Query: return .Timestamp_Query
	case .Texture_Compression_Bc: return .Texture_Compression_Bc
	case .Texture_Compression_Etc2: return .Texture_Compression_Etc2
	case .Texture_Compression_Astc: return .Texture_Compression_Astc
	case .Indirect_First_Instance: return .Indirect_First_Instance
	case .Shader_F16: return .Shader_F16
	case .Rg11_B10_Ufloat_Renderable: return .Rg11_B10_Ufloat_Renderable
	case .Bgra8_Unorm_Storage: return .Bgra8_Unorm_Storage
	case .Float32_Filterable: return .Float32_Filterable

	// Native features
	case .Push_Constants:
		return .Push_Constants
	case .Texture_Adapter_Specific_Format_Features:
		return .Texture_Adapter_Specific_Format_Features
	case .Multi_Draw_Indirect:
		return .Multi_Draw_Indirect
	case .Multi_Draw_Indirect_Count:
		return .Multi_Draw_Indirect_Count
	case .Vertex_Writable_Storage:
		return .Vertex_Writable_Storage
	case .Texture_Binding_Array:
		return .Texture_Binding_Array
	case .Sampled_Texture_And_Storage_Buffer_Array_Non_Uniform_Indexing:
		return(
			.Sampled_Texture_And_Storage_Buffer_Array_Non_Uniform_Indexing \
		)
	case .Pipeline_Statistics_Query:
		return .Pipeline_Statistics_Query
	case .Storage_Resource_Binding_Array:
		return .Storage_Resource_Binding_Array
	case .Partially_Bound_Binding_Array:
		return .Partially_Bound_Binding_Array
	}
	// odinfmt: enable

	return .Undefined
}
