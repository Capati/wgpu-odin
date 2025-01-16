package wgpu

Feature :: enum Flags {
	// WebGPU
	Depth_Clip_Control,
	Depth32_Float_Stencil8,
	Timestamp_Query,
	Texture_Compression_BC,
	Texture_Compression_BC_Sliced3D,
	Texture_Compression_ETC2,
	Texture_Compression_ASTC,
	Texture_Compression_ASTC_Sliced3D,
	Indirect_First_Instance,
	Shader_F16,
	RG11B10_Ufloat_Renderable,
	BGRA8_Unorm_Storage,
	Float32_Filterable,
	Float32_Blendable,
	Clip_Distances,
	Dual_Source_Blending,

	// Native
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
	Texture_Format16bit_Norm,
	Texture_Compression_ASTC_Hdr,
	Mappable_Primary_Buffers,
	Buffer_Binding_Array,
	Uniform_Buffer_And_Storage_Texture_Array_Non_Uniform_Indexing,
	Spirv_Shader_Passthrough,
	Vertex_Attribute64bit,
	Texture_Format_NV12,
	Ray_Tracing_Acceleration_Structure,
	Ray_Query,
	Shader_F64,
	Shader_I16,
	Shader_Primitive_Index,
	Shader_Early_Depth_Test,
	Subgroup,
	Subgroup_Vertex,
	Subgroup_Barrier,
	Timestamp_Query_Inside_Encoders,
	Timestamp_Query_Inside_Passes,
}

MAX_FEATURES :: len(Feature)

/*
Features that are not guaranteed to be supported.

These are either part of the webgpu standard, or are extension features supported by
wgpu when targeting native.

If you want to use a feature, you need to first verify that the adapter supports
the feature.If the adapter does not support the feature, requesting a device with it enabled
will panic.

Corresponds to [WebGPU `GPUFeatureName`](
https://gpuweb.github.io/gpuweb/#enumdef-gpufeaturename).
*/
Features :: bit_set[Feature;Flags]

/* Get the flags of all features which are part of the upstream WebGPU standard.*/
features_all_webgpu_flags :: proc "contextless" (features: Features) -> (ret: Features) {
	// odinfmt: disable
	for f in features {
		#partial switch f {
		case .Depth_Clip_Control: ret += {.Depth_Clip_Control}
		case .Depth32_Float_Stencil8: ret += {.Depth32_Float_Stencil8}
		case .Timestamp_Query: ret += {.Timestamp_Query}
		case .Texture_Compression_BC: ret += {.Texture_Compression_BC}
		case .Texture_Compression_BC_Sliced3D: ret += {.Texture_Compression_BC_Sliced3D}
		case .Texture_Compression_ETC2: ret += {.Texture_Compression_ETC2}
		case .Texture_Compression_ASTC: ret += {.Texture_Compression_ASTC}
		case .Texture_Compression_ASTC_Sliced3D: ret += {.Texture_Compression_ASTC_Sliced3D}
		case .Indirect_First_Instance: ret += {.Indirect_First_Instance}
		case .Shader_F16: ret += {.Shader_F16}
		case .RG11B10_Ufloat_Renderable: ret += {.RG11B10_Ufloat_Renderable}
		case .BGRA8_Unorm_Storage: ret += {.BGRA8_Unorm_Storage}
		case .Float32_Filterable: ret += {.Float32_Filterable}
		case .Float32_Blendable: ret += {.Float32_Blendable}
		case .Clip_Distances: ret += {.Clip_Distances}
		case .Dual_Source_Blending: ret += {.Dual_Source_Blending}
		}
	}
	// odinfmt: enable
	return
}

/* Get the flags of all features that are only available when targeting native (not web).*/
features_all_native_flags :: proc "contextless" (features: Features) -> (ret: Features) {
	// odinfmt: disable
	for f in features {
		#partial switch f {
		case .Push_Constants: ret += {.Push_Constants}
		case .Texture_Adapter_Specific_Format_Features: ret += {.Texture_Adapter_Specific_Format_Features}
		case .Multi_Draw_Indirect: ret += {.Multi_Draw_Indirect}
		case .Multi_Draw_Indirect_Count: ret += {.Multi_Draw_Indirect_Count}
		case .Vertex_Writable_Storage: ret += {.Vertex_Writable_Storage}
		case .Texture_Binding_Array: ret += {.Texture_Binding_Array}
		case .Sampled_Texture_And_Storage_Buffer_Array_Non_Uniform_Indexing: ret +=
			{.Sampled_Texture_And_Storage_Buffer_Array_Non_Uniform_Indexing}
		case .Pipeline_Statistics_Query: ret += {.Pipeline_Statistics_Query}
		case .Storage_Resource_Binding_Array: ret += {.Storage_Resource_Binding_Array}
		case .Partially_Bound_Binding_Array: ret += {.Partially_Bound_Binding_Array}
		case .Texture_Format16bit_Norm: ret += {.Texture_Format16bit_Norm}
		case .Texture_Compression_ASTC_Hdr: ret += {.Texture_Compression_ASTC_Hdr}
		case .Mappable_Primary_Buffers: ret += {.Mappable_Primary_Buffers}
		case .Buffer_Binding_Array: ret += {.Buffer_Binding_Array}
		case .Uniform_Buffer_And_Storage_Texture_Array_Non_Uniform_Indexing: ret +=
			{.Uniform_Buffer_And_Storage_Texture_Array_Non_Uniform_Indexing}
		case .Spirv_Shader_Passthrough: ret += {.Spirv_Shader_Passthrough}
		case .Vertex_Attribute64bit: ret += {.Vertex_Attribute64bit}
		case .Texture_Format_NV12: ret += {.Texture_Format_NV12}
		case .Ray_Tracing_Acceleration_Structure: ret += {.Ray_Tracing_Acceleration_Structure}
		case .Ray_Query: ret += {.Ray_Query}
		case .Shader_F64: ret += {.Shader_F64}
		case .Shader_I16: ret += {.Shader_I16}
		case .Shader_Primitive_Index: ret += {.Shader_Primitive_Index}
		case .Shader_Early_Depth_Test: ret += {.Shader_Early_Depth_Test}
		case .Subgroup: ret += {.Subgroup}
		case .Subgroup_Vertex: ret += {.Subgroup_Vertex}
		case .Subgroup_Barrier: ret += {.Subgroup_Barrier}
		case .Timestamp_Query_Inside_Encoders: ret += {.Timestamp_Query_Inside_Encoders}
		case .Timestamp_Query_Inside_Passes: ret += {.Timestamp_Query_Inside_Passes}
		}
	}
	// odinfmt: enable
	return
}

features_slice_to_flags :: proc "contextless" (features: []Feature_Name) -> (ret: Features) {
	// odinfmt: disable
	for &f in features {
		#partial switch f {
		// WebGPU
		case .Depth_Clip_Control: ret += {.Depth_Clip_Control}
		case .Depth32_Float_Stencil8: ret += {.Depth32_Float_Stencil8}
		case .Timestamp_Query: ret += {.Timestamp_Query}
		case .Texture_Compression_BC: ret += {.Texture_Compression_BC}
		case .Texture_Compression_BC_Sliced3D: ret += {.Texture_Compression_BC_Sliced3D}
		case .Texture_Compression_ETC2: ret += {.Texture_Compression_ETC2}
		case .Texture_Compression_ASTC: ret += {.Texture_Compression_ASTC}
		case .Texture_Compression_ASTC_Sliced3D: ret += {.Texture_Compression_ASTC_Sliced3D}
		case .Indirect_First_Instance: ret += {.Indirect_First_Instance}
		case .Shader_F16: ret += {.Shader_F16}
		case .RG11B10_Ufloat_Renderable: ret += {.RG11B10_Ufloat_Renderable}
		case .BGRA8_Unorm_Storage: ret += {.BGRA8_Unorm_Storage}
		case .Float32_Filterable: ret += {.Float32_Filterable}
		case .Float32_Blendable: ret += {.Float32_Blendable}
		case .Clip_Distances: ret += {.Clip_Distances}
		case .Dual_Source_Blending: ret += {.Dual_Source_Blending}

		// Native
		case .Push_Constants: ret += {.Push_Constants}
		case .Texture_Adapter_Specific_Format_Features: ret += {.Texture_Adapter_Specific_Format_Features}
		case .Multi_Draw_Indirect: ret += {.Multi_Draw_Indirect}
		case .Multi_Draw_Indirect_Count: ret += {.Multi_Draw_Indirect_Count}
		case .Vertex_Writable_Storage: ret += {.Vertex_Writable_Storage}
		case .Texture_Binding_Array: ret += {.Texture_Binding_Array}
		case .Sampled_Texture_And_Storage_Buffer_Array_Non_Uniform_Indexing: ret +=
			{.Sampled_Texture_And_Storage_Buffer_Array_Non_Uniform_Indexing}
		case .Pipeline_Statistics_Query: ret += {.Pipeline_Statistics_Query}
		case .Storage_Resource_Binding_Array: ret += {.Storage_Resource_Binding_Array}
		case .Partially_Bound_Binding_Array: ret += {.Partially_Bound_Binding_Array}
		case .Texture_Format16bit_Norm: ret += {.Texture_Format16bit_Norm}
		case .Texture_Compression_ASTC_Hdr: ret += {.Texture_Compression_ASTC_Hdr}
		case .Mappable_Primary_Buffers: ret += {.Mappable_Primary_Buffers}
		case .Buffer_Binding_Array: ret += {.Buffer_Binding_Array}
		case .Uniform_Buffer_And_Storage_Texture_Array_Non_Uniform_Indexing: ret +=
			{.Uniform_Buffer_And_Storage_Texture_Array_Non_Uniform_Indexing}
		case .Spirv_Shader_Passthrough: ret += {.Spirv_Shader_Passthrough}
		case .Vertex_Attribute64bit: ret += {.Vertex_Attribute64bit}
		case .Texture_Format_NV12: ret += {.Texture_Format_NV12}
		case .Ray_Tracing_Acceleration_Structure: ret += {.Ray_Tracing_Acceleration_Structure}
		case .Ray_Query: ret += {.Ray_Query}
		case .Shader_F64: ret += {.Shader_F64}
		case .Shader_I16: ret += {.Shader_I16}
		case .Shader_Primitive_Index: ret += {.Shader_Primitive_Index}
		case .Shader_Early_Depth_Test: ret += {.Shader_Early_Depth_Test}
		case .Subgroup: ret += {.Subgroup}
		case .Subgroup_Vertex: ret += {.Subgroup_Vertex}
		case .Subgroup_Barrier: ret += {.Subgroup_Barrier}
		case .Timestamp_Query_Inside_Encoders: ret += {.Timestamp_Query_Inside_Encoders}
		case .Timestamp_Query_Inside_Passes: ret += {.Timestamp_Query_Inside_Passes}
		}
	}
	// odinfmt: enable
	return
}

features_flag_to_raw_feature_name :: proc "contextless" (
	feature_name: Feature,
) -> (
	feature: Feature_Name,
) {
	// odinfmt: disable
	#partial switch feature_name {
	// WebGPU
	case .Depth_Clip_Control: return .Depth_Clip_Control
	case .Depth32_Float_Stencil8: return .Depth32_Float_Stencil8
	case .Timestamp_Query: return .Timestamp_Query
	case .Texture_Compression_BC: return .Texture_Compression_BC
	case .Texture_Compression_BC_Sliced3D: return .Texture_Compression_BC_Sliced3D
	case .Texture_Compression_ETC2: return .Texture_Compression_ETC2
	case .Texture_Compression_ASTC: return .Texture_Compression_ASTC
	case .Texture_Compression_ASTC_Sliced3D: return .Texture_Compression_ASTC_Sliced3D
	case .Indirect_First_Instance: return .Indirect_First_Instance
	case .Shader_F16: return .Shader_F16
	case .RG11B10_Ufloat_Renderable: return .RG11B10_Ufloat_Renderable
	case .BGRA8_Unorm_Storage: return .BGRA8_Unorm_Storage
	case .Float32_Filterable: return .Float32_Filterable
	case .Float32_Blendable: return .Float32_Blendable
	case .Clip_Distances: return .Clip_Distances
	case .Dual_Source_Blending: return .Dual_Source_Blending

	// Native
	case .Push_Constants: return .Push_Constants
	case .Texture_Adapter_Specific_Format_Features: return .Texture_Adapter_Specific_Format_Features
	case .Multi_Draw_Indirect: return .Multi_Draw_Indirect
	case .Multi_Draw_Indirect_Count: return .Multi_Draw_Indirect_Count
	case .Vertex_Writable_Storage: return .Vertex_Writable_Storage
	case .Texture_Binding_Array: return .Texture_Binding_Array
	case .Sampled_Texture_And_Storage_Buffer_Array_Non_Uniform_Indexing:
		return .Sampled_Texture_And_Storage_Buffer_Array_Non_Uniform_Indexing
	case .Pipeline_Statistics_Query: return .Pipeline_Statistics_Query
	case .Storage_Resource_Binding_Array: return .Storage_Resource_Binding_Array
	case .Partially_Bound_Binding_Array: return .Partially_Bound_Binding_Array
	case .Texture_Format16bit_Norm: return .Texture_Format16bit_Norm
	case .Texture_Compression_ASTC_Hdr: return .Texture_Compression_ASTC_Hdr
	case .Mappable_Primary_Buffers: return .Mappable_Primary_Buffers
	case .Buffer_Binding_Array: return .Buffer_Binding_Array
	case .Uniform_Buffer_And_Storage_Texture_Array_Non_Uniform_Indexing:
		return .Uniform_Buffer_And_Storage_Texture_Array_Non_Uniform_Indexing
	case .Spirv_Shader_Passthrough: return .Spirv_Shader_Passthrough
	case .Vertex_Attribute64bit: return .Vertex_Attribute64bit
	case .Texture_Format_NV12: return .Texture_Format_NV12
	case .Ray_Tracing_Acceleration_Structure: return .Ray_Tracing_Acceleration_Structure
	case .Ray_Query: return .Ray_Query
	case .Shader_F64: return .Shader_F64
	case .Shader_I16: return .Shader_I16
	case .Shader_Primitive_Index: return .Shader_Primitive_Index
	case .Shader_Early_Depth_Test: return .Shader_Early_Depth_Test
	case .Subgroup: return .Subgroup
	case .Subgroup_Vertex: return .Subgroup_Vertex
	case .Subgroup_Barrier: return .Subgroup_Barrier
	case .Timestamp_Query_Inside_Encoders: return .Timestamp_Query_Inside_Encoders
	case .Timestamp_Query_Inside_Passes: return .Timestamp_Query_Inside_Passes
	case: return .Undefined
	}
	// odinfmt: enable
}

@(private)
Feature_Name :: enum i32 {
	// WebGPU
	Undefined                                                     = 0x00000000,
	Depth_Clip_Control                                            = 0x00000001,
	Depth32_Float_Stencil8                                        = 0x00000002,
	Timestamp_Query                                               = 0x00000003,
	Texture_Compression_BC                                        = 0x00000004,
	Texture_Compression_BC_Sliced3D                               = 0x00000005,
	Texture_Compression_ETC2                                      = 0x00000006,
	Texture_Compression_ASTC                                      = 0x00000007,
	Texture_Compression_ASTC_Sliced3D                             = 0x00000008,
	Indirect_First_Instance                                       = 0x00000009,
	Shader_F16                                                    = 0x0000000A,
	RG11B10_Ufloat_Renderable                                     = 0x0000000B,
	BGRA8_Unorm_Storage                                           = 0x0000000C,
	Float32_Filterable                                            = 0x0000000D,
	Float32_Blendable                                             = 0x0000000E,
	Clip_Distances                                                = 0x0000000F,
	Dual_Source_Blending                                          = 0x00000010,

	// Native
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
	Texture_Format16bit_Norm                                      = 0x0003000B,
	Texture_Compression_ASTC_Hdr                                  = 0x0003000C,
	Mappable_Primary_Buffers                                      = 0x0003000E,
	Buffer_Binding_Array                                          = 0x0003000F,
	Uniform_Buffer_And_Storage_Texture_Array_Non_Uniform_Indexing = 0x00030010,
	Spirv_Shader_Passthrough                                      = 0x00030017,
	Vertex_Attribute64bit                                         = 0x00030019,
	Texture_Format_NV12                                           = 0x0003001A,
	Ray_Tracing_Acceleration_Structure                            = 0x0003001B,
	Ray_Query                                                     = 0x0003001C,
	Shader_F64                                                    = 0x0003001D,
	Shader_I16                                                    = 0x0003001E,
	Shader_Primitive_Index                                        = 0x0003001F,
	Shader_Early_Depth_Test                                       = 0x00030020,
	Subgroup                                                      = 0x00030021,
	Subgroup_Vertex                                               = 0x00030022,
	Subgroup_Barrier                                              = 0x00030023,
	Timestamp_Query_Inside_Encoders                               = 0x00030024,
	Timestamp_Query_Inside_Passes                                 = 0x00030025,
}

@(private)
WGPU_Supported_Features :: struct {
	feature_count: uint,
	features:      [^]Feature_Name,
}
