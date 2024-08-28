package wgpu

// The raw bindings
import wgpu "../bindings"

/* Maximum number of supported features by the WebGPU/native */
MAX_FEATURES :: 50

Raw_Feature_Name :: wgpu.Feature_Name

Feature_Name :: enum FLAGS {
	// WebGPU
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
	Texture_Compression_Astc_Hdr,
	Mappable_Primary_Buffers,
	Buffer_Binding_Array,
	Uniform_Buffer_And_Storage_Texture_Array_Non_Uniform_Indexing,
	Vertex_Attribute64bit,
	Texture_Format_NV12,
	Ray_Tracing_Acceleration_Structure,
	Ray_Query,
	Shader_F64,
	Shader_I16,
	Shader_Primitive_Index,
	Shader_Early_Depth_Test,
}

/*
Features that are not guaranteed to be supported.

These are either part of the webgpu standard, or are extension features supported by
wgpu when targeting native.

If you want to use a feature, you need to first verify that the adapter supports
the feature. If the adapter does not support the feature, requesting a device with it enabled
will panic.

Corresponds to [WebGPU `GPUFeatureName`](
https://gpuweb.github.io/gpuweb/#enumdef-gpufeaturename).
*/
Features :: bit_set[Feature_Name; u64]

/*
Get the flags of all features which are part of the upstream WebGPU standard.
*/
features_all_webgpu_flags :: proc "contextless" (features: Features) -> (ret: Features) {
	for f in features {
		#partial switch f {
		case .Depth_Clip_Control: ret         += {.Depth_Clip_Control}
		case .Depth32_Float_Stencil8: ret     += {.Depth32_Float_Stencil8}
		case .Timestamp_Query: ret            += {.Timestamp_Query}
		case .Texture_Compression_Bc: ret     += {.Texture_Compression_Bc}
		case .Texture_Compression_Etc2: ret   += {.Texture_Compression_Etc2}
		case .Texture_Compression_Astc: ret   += {.Texture_Compression_Astc}
		case .Indirect_First_Instance: ret    += {.Indirect_First_Instance}
		case .Shader_F16: ret                 += {.Shader_F16}
		case .Rg11_B10_Ufloat_Renderable: ret += {.Rg11_B10_Ufloat_Renderable}
		case .Bgra8_Unorm_Storage: ret        += {.Bgra8_Unorm_Storage}
		case .Float32_Filterable: ret         += {.Float32_Filterable}
		}
	}

	return
}

/* Get the flags of all features that are only available when targeting native (not web). */
features_all_native_flags :: proc "contextless" (features: Features) -> (ret: Features) {
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
			case .Texture_Format16bit_Norm: ret += {.Texture_Format16bit_Norm}
			case .Texture_Compression_Astc_Hdr: ret += {.Texture_Compression_Astc_Hdr}
			case .Mappable_Primary_Buffers: ret += {.Mappable_Primary_Buffers}
			case .Buffer_Binding_Array: ret += {.Buffer_Binding_Array}
			case .Uniform_Buffer_And_Storage_Texture_Array_Non_Uniform_Indexing:
				ret += {.Uniform_Buffer_And_Storage_Texture_Array_Non_Uniform_Indexing}
			case .Vertex_Attribute64bit: ret += {.Vertex_Attribute64bit}
			case .Texture_Format_NV12: ret += {.Texture_Format_NV12}
			case .Ray_Tracing_Acceleration_Structure:
				ret += {.Ray_Tracing_Acceleration_Structure}
			case .Ray_Query: ret += {.Ray_Query}
			case .Shader_F64: ret += {.Shader_F64}
			case .Shader_I16: ret += {.Shader_I16}
			case .Shader_Primitive_Index: ret += {.Shader_Primitive_Index}
			case .Shader_Early_Depth_Test: ret += {.Shader_Early_Depth_Test}
		}
	}
	return
}

features_slice_to_flags :: proc "contextless" (
	features_slice: []Raw_Feature_Name,
) -> (
	ret: Features,
) {
	for &f in features_slice {
		switch f {
		// webgpu features
		case .Undefined: ret += {.Undefined}
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

		// Native features
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
		case .Texture_Format16bit_Norm: ret += {.Texture_Format16bit_Norm}
		case .Texture_Compression_Astc_Hdr: ret += {.Texture_Compression_Astc_Hdr}
		case .Mappable_Primary_Buffers: ret += {.Mappable_Primary_Buffers}
		case .Buffer_Binding_Array: ret += {.Buffer_Binding_Array}
		case .Uniform_Buffer_And_Storage_Texture_Array_Non_Uniform_Indexing:
			ret += {.Uniform_Buffer_And_Storage_Texture_Array_Non_Uniform_Indexing}
		case .Vertex_Attribute64bit: ret += {.Vertex_Attribute64bit}
		case .Texture_Format_NV12: ret += {.Texture_Format_NV12}
		case .Ray_Tracing_Acceleration_Structure:
			ret += {.Ray_Tracing_Acceleration_Structure}
		case .Ray_Query: ret += {.Ray_Query}
		case .Shader_F64: ret += {.Shader_F64}
		case .Shader_I16: ret += {.Shader_I16}
		case .Shader_Primitive_Index: ret += {.Shader_Primitive_Index}
		case .Shader_Early_Depth_Test: ret += {.Shader_Early_Depth_Test}
		}
	}
	return
}

features_flag_to_raw_feature_name :: proc "contextless" (
	feature_name: Feature_Name,
) -> (
	feature: Raw_Feature_Name,
) {
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
	case .Push_Constants: return .Push_Constants
	case .Texture_Adapter_Specific_Format_Features:
		return .Texture_Adapter_Specific_Format_Features
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
	case .Texture_Compression_Astc_Hdr: return .Texture_Compression_Astc_Hdr
	case .Mappable_Primary_Buffers: return .Mappable_Primary_Buffers
	case .Buffer_Binding_Array: return .Buffer_Binding_Array
	case .Uniform_Buffer_And_Storage_Texture_Array_Non_Uniform_Indexing:
		return .Uniform_Buffer_And_Storage_Texture_Array_Non_Uniform_Indexing
	case .Vertex_Attribute64bit: return .Vertex_Attribute64bit
	case .Texture_Format_NV12: return .Texture_Format_NV12
	case .Ray_Tracing_Acceleration_Structure:
		return .Ray_Tracing_Acceleration_Structure
	case .Ray_Query: return .Ray_Query
	case .Shader_F64: return .Shader_F64
	case .Shader_I16: return .Shader_I16
	case .Shader_Primitive_Index: return .Shader_Primitive_Index
	case .Shader_Early_Depth_Test: return .Shader_Early_Depth_Test
	}

	return .Undefined
}
