package wgpu

Feature :: enum Flags {
	// WebGPU
	DepthClipControl,
	Depth32FloatStencil8,
	TimestampQuery,
	TextureCompressionBC,
	TextureCompressionBCSliced3D,
	TextureCompressionETC2,
	TextureCompressionASTC,
	TextureCompressionASTCSliced3D,
	IndirectFirstInstance,
	ShaderF16,
	RG11B10UfloatRenderable,
	BGRA8UnormStorage,
	Float32Filterable,
	Float32Blendable,
	ClipDistances,
	DualSourceBlending,

	// Native
	PushConstants,
	TextureAdapterSpecificFormatFeatures,
	MultiDrawIndirect,
	MultiDrawIndirectCount,
	VertexWritableStorage,
	TextureBindingArray,
	SampledTextureAndStorageBufferArrayNonUniformIndexing,
	PipelineStatisticsQuery,
	StorageResourceBindingArray,
	PartiallyBoundBindingArray,
	TextureFormat16bitNorm,
	TextureCompressionAstcHdr,
	MappablePrimaryBuffers,
	BufferBindingArray,
	UniformBufferAndStorageTextureArrayNonUniformIndexing,
	SpirvShaderPassthrough,
	VertexAttribute64bit,
	TextureFormatNv12,
	RayTracingAccelerationStructure,
	RayQuery,
	ShaderF64,
	ShaderI16,
	ShaderPrimitiveIndex,
	ShaderEarlyDepthTest,
	Subgroup,
	SubgroupVertex,
	SubgroupBarrier,
	TimestampQueryInsideEncoders,
	TimestampQueryInsidePasses,
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
		case .DepthClipControl: ret += {.DepthClipControl}
		case .Depth32FloatStencil8: ret += {.Depth32FloatStencil8}
		case .TimestampQuery: ret += {.TimestampQuery}
		case .TextureCompressionBC: ret += {.TextureCompressionBC}
		case .TextureCompressionBCSliced3D: ret += {.TextureCompressionBCSliced3D}
		case .TextureCompressionETC2: ret += {.TextureCompressionETC2}
		case .TextureCompressionASTC: ret += {.TextureCompressionASTC}
		case .TextureCompressionASTCSliced3D: ret += {.TextureCompressionASTCSliced3D}
		case .IndirectFirstInstance: ret += {.IndirectFirstInstance}
		case .ShaderF16: ret += {.ShaderF16}
		case .RG11B10UfloatRenderable: ret += {.RG11B10UfloatRenderable}
		case .BGRA8UnormStorage: ret += {.BGRA8UnormStorage}
		case .Float32Filterable: ret += {.Float32Filterable}
		case .Float32Blendable: ret += {.Float32Blendable}
		case .ClipDistances: ret += {.ClipDistances}
		case .DualSourceBlending: ret += {.DualSourceBlending}
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
		case .PushConstants: ret += {.PushConstants}
		case .TextureAdapterSpecificFormatFeatures: ret += {.TextureAdapterSpecificFormatFeatures}
		case .MultiDrawIndirect: ret += {.MultiDrawIndirect}
		case .MultiDrawIndirectCount: ret += {.MultiDrawIndirectCount}
		case .VertexWritableStorage: ret += {.VertexWritableStorage}
		case .TextureBindingArray: ret += {.TextureBindingArray}
		case .SampledTextureAndStorageBufferArrayNonUniformIndexing: ret +=
			{.SampledTextureAndStorageBufferArrayNonUniformIndexing}
		case .PipelineStatisticsQuery: ret += {.PipelineStatisticsQuery}
		case .StorageResourceBindingArray: ret += {.StorageResourceBindingArray}
		case .PartiallyBoundBindingArray: ret += {.PartiallyBoundBindingArray}
		case .TextureFormat16bitNorm: ret += {.TextureFormat16bitNorm}
		case .TextureCompressionAstcHdr: ret += {.TextureCompressionAstcHdr}
		case .MappablePrimaryBuffers: ret += {.MappablePrimaryBuffers}
		case .BufferBindingArray: ret += {.BufferBindingArray}
		case .UniformBufferAndStorageTextureArrayNonUniformIndexing: ret +=
			{.UniformBufferAndStorageTextureArrayNonUniformIndexing}
		case .SpirvShaderPassthrough: ret += {.SpirvShaderPassthrough}
		case .VertexAttribute64bit: ret += {.VertexAttribute64bit}
		case .TextureFormatNv12: ret += {.TextureFormatNv12}
		case .RayTracingAccelerationStructure: ret += {.RayTracingAccelerationStructure}
		case .RayQuery: ret += {.RayQuery}
		case .ShaderF64: ret += {.ShaderF64}
		case .ShaderI16: ret += {.ShaderI16}
		case .ShaderPrimitiveIndex: ret += {.ShaderPrimitiveIndex}
		case .ShaderEarlyDepthTest: ret += {.ShaderEarlyDepthTest}
		case .Subgroup: ret += {.Subgroup}
		case .SubgroupVertex: ret += {.SubgroupVertex}
		case .SubgroupBarrier: ret += {.SubgroupBarrier}
		case .TimestampQueryInsideEncoders: ret += {.TimestampQueryInsideEncoders}
		case .TimestampQueryInsidePasses: ret += {.TimestampQueryInsidePasses}
		}
	}
	// odinfmt: enable
	return
}

features_slice_to_flags :: proc "contextless" (features: []FeatureName) -> (ret: Features) {
	// odinfmt: disable
	for &f in features {
		#partial switch f {
		// WebGPU
		case .DepthClipControl: ret += {.DepthClipControl}
		case .Depth32FloatStencil8: ret += {.Depth32FloatStencil8}
		case .TimestampQuery: ret += {.TimestampQuery}
		case .TextureCompressionBC: ret += {.TextureCompressionBC}
		case .TextureCompressionBCSliced3D: ret += {.TextureCompressionBCSliced3D}
		case .TextureCompressionETC2: ret += {.TextureCompressionETC2}
		case .TextureCompressionASTC: ret += {.TextureCompressionASTC}
		case .TextureCompressionASTCSliced3D: ret += {.TextureCompressionASTCSliced3D}
		case .IndirectFirstInstance: ret += {.IndirectFirstInstance}
		case .ShaderF16: ret += {.ShaderF16}
		case .RG11B10UfloatRenderable: ret += {.RG11B10UfloatRenderable}
		case .BGRA8UnormStorage: ret += {.BGRA8UnormStorage}
		case .Float32Filterable: ret += {.Float32Filterable}
		case .Float32Blendable: ret += {.Float32Blendable}
		case .ClipDistances: ret += {.ClipDistances}
		case .DualSourceBlending: ret += {.DualSourceBlending}

		// Native
		case .PushConstants: ret += {.PushConstants}
		case .TextureAdapterSpecificFormatFeatures: ret += {.TextureAdapterSpecificFormatFeatures}
		case .MultiDrawIndirect: ret += {.MultiDrawIndirect}
		case .MultiDrawIndirectCount: ret += {.MultiDrawIndirectCount}
		case .VertexWritableStorage: ret += {.VertexWritableStorage}
		case .TextureBindingArray: ret += {.TextureBindingArray}
		case .SampledTextureAndStorageBufferArrayNonUniformIndexing: ret +=
			{.SampledTextureAndStorageBufferArrayNonUniformIndexing}
		case .PipelineStatisticsQuery: ret += {.PipelineStatisticsQuery}
		case .StorageResourceBindingArray: ret += {.StorageResourceBindingArray}
		case .PartiallyBoundBindingArray: ret += {.PartiallyBoundBindingArray}
		case .TextureFormat16bitNorm: ret += {.TextureFormat16bitNorm}
		case .TextureCompressionAstcHdr: ret += {.TextureCompressionAstcHdr}
		case .MappablePrimaryBuffers: ret += {.MappablePrimaryBuffers}
		case .BufferBindingArray: ret += {.BufferBindingArray}
		case .UniformBufferAndStorageTextureArrayNonUniformIndexing: ret +=
			{.UniformBufferAndStorageTextureArrayNonUniformIndexing}
		case .SpirvShaderPassthrough: ret += {.SpirvShaderPassthrough}
		case .VertexAttribute64bit: ret += {.VertexAttribute64bit}
		case .TextureFormatNv12: ret += {.TextureFormatNv12}
		case .RayTracingAccelerationStructure: ret += {.RayTracingAccelerationStructure}
		case .RayQuery: ret += {.RayQuery}
		case .ShaderF64: ret += {.ShaderF64}
		case .ShaderI16: ret += {.ShaderI16}
		case .ShaderPrimitiveIndex: ret += {.ShaderPrimitiveIndex}
		case .ShaderEarlyDepthTest: ret += {.ShaderEarlyDepthTest}
		case .Subgroup: ret += {.Subgroup}
		case .SubgroupVertex: ret += {.SubgroupVertex}
		case .SubgroupBarrier: ret += {.SubgroupBarrier}
		case .TimestampQueryInsideEncoders: ret += {.TimestampQueryInsideEncoders}
		case .TimestampQueryInsidePasses: ret += {.TimestampQueryInsidePasses}
		}
	}
	// odinfmt: enable
	return
}

features_flag_to_raw_feature_name :: proc "contextless" (
	feature_name: Feature,
) -> (
	feature: FeatureName,
) {
	// odinfmt: disable
	#partial switch feature_name {
	// WebGPU
	case .DepthClipControl: return .DepthClipControl
	case .Depth32FloatStencil8: return .Depth32FloatStencil8
	case .TimestampQuery: return .TimestampQuery
	case .TextureCompressionBC: return .TextureCompressionBC
	case .TextureCompressionBCSliced3D: return .TextureCompressionBCSliced3D
	case .TextureCompressionETC2: return .TextureCompressionETC2
	case .TextureCompressionASTC: return .TextureCompressionASTC
	case .TextureCompressionASTCSliced3D: return .TextureCompressionASTCSliced3D
	case .IndirectFirstInstance: return .IndirectFirstInstance
	case .ShaderF16: return .ShaderF16
	case .RG11B10UfloatRenderable: return .RG11B10UfloatRenderable
	case .BGRA8UnormStorage: return .BGRA8UnormStorage
	case .Float32Filterable: return .Float32Filterable
	case .Float32Blendable: return .Float32Blendable
	case .ClipDistances: return .ClipDistances
	case .DualSourceBlending: return .DualSourceBlending

	// Native
	case .PushConstants: return .PushConstants
	case .TextureAdapterSpecificFormatFeatures: return .TextureAdapterSpecificFormatFeatures
	case .MultiDrawIndirect: return .MultiDrawIndirect
	case .MultiDrawIndirectCount: return .MultiDrawIndirectCount
	case .VertexWritableStorage: return .VertexWritableStorage
	case .TextureBindingArray: return .TextureBindingArray
	case .SampledTextureAndStorageBufferArrayNonUniformIndexing:
		return .SampledTextureAndStorageBufferArrayNonUniformIndexing
	case .PipelineStatisticsQuery: return .PipelineStatisticsQuery
	case .StorageResourceBindingArray: return .StorageResourceBindingArray
	case .PartiallyBoundBindingArray: return .PartiallyBoundBindingArray
	case .TextureFormat16bitNorm: return .TextureFormat16bitNorm
	case .TextureCompressionAstcHdr: return .TextureCompressionAstcHdr
	case .MappablePrimaryBuffers: return .MappablePrimaryBuffers
	case .BufferBindingArray: return .BufferBindingArray
	case .UniformBufferAndStorageTextureArrayNonUniformIndexing:
		return .UniformBufferAndStorageTextureArrayNonUniformIndexing
	case .SpirvShaderPassthrough: return .SpirvShaderPassthrough
	case .VertexAttribute64bit: return .VertexAttribute64bit
	case .TextureFormatNv12: return .TextureFormatNv12
	case .RayTracingAccelerationStructure: return .RayTracingAccelerationStructure
	case .RayQuery: return .RayQuery
	case .ShaderF64: return .ShaderF64
	case .ShaderI16: return .ShaderI16
	case .ShaderPrimitiveIndex: return .ShaderPrimitiveIndex
	case .ShaderEarlyDepthTest: return .ShaderEarlyDepthTest
	case .Subgroup: return .Subgroup
	case .SubgroupVertex: return .SubgroupVertex
	case .SubgroupBarrier: return .SubgroupBarrier
	case .TimestampQueryInsideEncoders: return .TimestampQueryInsideEncoders
	case .TimestampQueryInsidePasses: return .TimestampQueryInsidePasses
	case: return .Undefined
	}
	// odinfmt: enable
}

@(private)
FeatureName :: enum i32 {
	// WebGPU
	Undefined                                             = 0x00000000,
	DepthClipControl                                      = 0x00000001,
	Depth32FloatStencil8                                  = 0x00000002,
	TimestampQuery                                        = 0x00000003,
	TextureCompressionBC                                  = 0x00000004,
	TextureCompressionBCSliced3D                          = 0x00000005,
	TextureCompressionETC2                                = 0x00000006,
	TextureCompressionASTC                                = 0x00000007,
	TextureCompressionASTCSliced3D                        = 0x00000008,
	IndirectFirstInstance                                 = 0x00000009,
	ShaderF16                                             = 0x0000000A,
	RG11B10UfloatRenderable                               = 0x0000000B,
	BGRA8UnormStorage                                     = 0x0000000C,
	Float32Filterable                                     = 0x0000000D,
	Float32Blendable                                      = 0x0000000E,
	ClipDistances                                         = 0x0000000F,
	DualSourceBlending                                    = 0x00000010,

	// Native
	PushConstants                                         = 0x00030001,
	TextureAdapterSpecificFormatFeatures                  = 0x00030002,
	MultiDrawIndirect                                     = 0x00030003,
	MultiDrawIndirectCount                                = 0x00030004,
	VertexWritableStorage                                 = 0x00030005,
	TextureBindingArray                                   = 0x00030006,
	SampledTextureAndStorageBufferArrayNonUniformIndexing = 0x00030007,
	PipelineStatisticsQuery                               = 0x00030008,
	StorageResourceBindingArray                           = 0x00030009,
	PartiallyBoundBindingArray                            = 0x0003000A,
	TextureFormat16bitNorm                                = 0x0003000B,
	TextureCompressionAstcHdr                             = 0x0003000C,
	MappablePrimaryBuffers                                = 0x0003000E,
	BufferBindingArray                                    = 0x0003000F,
	UniformBufferAndStorageTextureArrayNonUniformIndexing = 0x00030010,
	SpirvShaderPassthrough                                = 0x00030017,
	VertexAttribute64bit                                  = 0x00030019,
	TextureFormatNv12                                     = 0x0003001A,
	RayTracingAccelerationStructure                       = 0x0003001B,
	RayQuery                                              = 0x0003001C,
	ShaderF64                                             = 0x0003001D,
	ShaderI16                                             = 0x0003001E,
	ShaderPrimitiveIndex                                  = 0x0003001F,
	ShaderEarlyDepthTest                                  = 0x00030020,
	Subgroup                                              = 0x00030021,
	SubgroupVertex                                        = 0x00030022,
	SubgroupBarrier                                       = 0x00030023,
	TimestampQueryInsideEncoders                          = 0x00030024,
	TimestampQueryInsidePasses                            = 0x00030025,
}

@(private)
SupportedFeatures :: struct {
	feature_count: uint,
	features:      [^]FeatureName,
}
