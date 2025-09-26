package webgpu

// Vendor
import "vendor:wgpu"

Feature :: enum Flags {
	// WebGPU.
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

	// Native.
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
	// TODO: requires wgpu.h api change
	// AddressModeClampToZero,
	// AddressModeClampToBorder,
	// PolygonModeLine,
	// PolygonModePoint,
	// ConservativeRasterization,
	// ClearTexture,
	SpirvShaderPassthrough,
	// MultiView,
	VertexAttribute64bit,
	TextureFormatNv12,
	RayTracingAccelarationStructure,
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
	// ShaderInt64,
}

MAX_FEATURES :: len(Feature)

/*
Features that are not guaranteed to be supported.

These are either part of the webgpu standard, or are extension features
supported by wgpu when targeting native.

If you want to use a feature, you need to first verify that the adapter supports
the feature.If the adapter does not support the feature, requesting a device
with it enabled will panic.

Corresponds to [WebGPU `GPUFeatureName`](
https://gpuweb.github.io/gpuweb/#enumdef-gpufeaturename).
*/
Features :: bit_set[Feature;Flags]

/* Get the flags of all features which are part of the upstream WebGPU standard. */
FeaturesAllWebGPUFlags :: proc "contextless" (features: Features) -> (ret: Features) {
	for f in features {
		#partial switch f {
		case .DepthClipControl:
			ret += { .DepthClipControl }
		case .Depth32FloatStencil8:
			ret += { .Depth32FloatStencil8 }
		case .TimestampQuery:
			ret += { .TimestampQuery }
		case .TextureCompressionBC:
			ret += { .TextureCompressionBC }
		case .TextureCompressionBCSliced3D:
			ret += { .TextureCompressionBCSliced3D }
		case .TextureCompressionETC2:
			ret += { .TextureCompressionETC2 }
		case .TextureCompressionASTC:
			ret += { .TextureCompressionASTC }
		case .TextureCompressionASTCSliced3D:
			ret += { .TextureCompressionASTCSliced3D }
		case .IndirectFirstInstance:
			ret += { .IndirectFirstInstance }
		case .ShaderF16:
			ret += { .ShaderF16 }
		case .RG11B10UfloatRenderable:
			ret += { .RG11B10UfloatRenderable }
		case .BGRA8UnormStorage:
			ret += { .BGRA8UnormStorage }
		case .Float32Filterable:
			ret += { .Float32Filterable }
		case .Float32Blendable:
			ret += { .Float32Blendable }
		case .ClipDistances:
			ret += { .ClipDistances }
		case .DualSourceBlending:
			ret += { .DualSourceBlending }
		}
	}
	return
}

/* Get the flags of all features that are only available when targeting native (not web).*/
FeaturesAllNativeFlags :: proc "contextless" (features: Features) -> (ret: Features) {
	for f in features {
		#partial switch f {
		case .PushConstants:
			ret += { .PushConstants }
		case .TextureAdapterSpecificFormatFeatures:
			ret += { .TextureAdapterSpecificFormatFeatures }
		case .MultiDrawIndirect:
			ret += { .MultiDrawIndirect }
		case .MultiDrawIndirectCount:
			ret += { .MultiDrawIndirectCount }
		case .VertexWritableStorage:
			ret += { .VertexWritableStorage }
		case .TextureBindingArray:
			ret += { .TextureBindingArray }
		case .SampledTextureAndStorageBufferArrayNonUniformIndexing:
			ret += { .SampledTextureAndStorageBufferArrayNonUniformIndexing }
		case .PipelineStatisticsQuery:
			ret += { .PipelineStatisticsQuery }
		case .StorageResourceBindingArray:
			ret += { .StorageResourceBindingArray }
		case .PartiallyBoundBindingArray:
			ret += { .PartiallyBoundBindingArray }
		case .TextureFormat16bitNorm:
			ret += { .TextureFormat16bitNorm }
		case .TextureCompressionAstcHdr:
			ret += { .TextureCompressionAstcHdr }
		case .MappablePrimaryBuffers:
			ret += { .MappablePrimaryBuffers }
		case .BufferBindingArray:
			ret += { .BufferBindingArray }
		case .UniformBufferAndStorageTextureArrayNonUniformIndexing:
			ret += { .UniformBufferAndStorageTextureArrayNonUniformIndexing }
		case .SpirvShaderPassthrough:
			ret += { .SpirvShaderPassthrough }
		case .VertexAttribute64bit:
			ret += { .VertexAttribute64bit }
		case .TextureFormatNv12:
			ret += { .TextureFormatNv12 }
		case .RayTracingAccelarationStructure:
			ret += { .RayTracingAccelarationStructure }
		case .RayQuery:
			ret += { .RayQuery }
		case .ShaderF64:
			ret += { .ShaderF64 }
		case .ShaderI16:
			ret += { .ShaderI16 }
		case .ShaderPrimitiveIndex:
			ret += { .ShaderPrimitiveIndex }
		case .ShaderEarlyDepthTest:
			ret += { .ShaderEarlyDepthTest }
		case .Subgroup:
			ret += { .Subgroup }
		case .SubgroupVertex:
			ret += { .SubgroupVertex }
		case .SubgroupBarrier:
			ret += { .SubgroupBarrier }
		case .TimestampQueryInsideEncoders:
			ret += { .TimestampQueryInsideEncoders }
		case .TimestampQueryInsidePasses:
			ret += { .TimestampQueryInsidePasses }
		// case .ShaderInt64:
			// ret += { .ShaderInt64 }
		}
	}
	return
}

@(private)
_FeaturesSliceToFlags :: proc "contextless" (features: []wgpu.FeatureName) -> (ret: Features) {
	for &f in features {
		#partial switch f {
		// WebGPU
		case .DepthClipControl:
			ret += { .DepthClipControl }
		case .Depth32FloatStencil8:
			ret += { .Depth32FloatStencil8 }
		case .TimestampQuery:
			ret += { .TimestampQuery }
		case .TextureCompressionBC:
			ret += { .TextureCompressionBC }
		case .TextureCompressionBCSliced3D:
			ret += { .TextureCompressionBCSliced3D }
		case .TextureCompressionETC2:
			ret += { .TextureCompressionETC2 }
		case .TextureCompressionASTC:
			ret += { .TextureCompressionASTC }
		case .TextureCompressionASTCSliced3D:
			ret += { .TextureCompressionASTCSliced3D }
		case .IndirectFirstInstance:
			ret += { .IndirectFirstInstance }
		case .ShaderF16:
			ret += { .ShaderF16 }
		case .RG11B10UfloatRenderable:
			ret += { .RG11B10UfloatRenderable }
		case .BGRA8UnormStorage:
			ret += { .BGRA8UnormStorage }
		case .Float32Filterable:
			ret += { .Float32Filterable }
		case .Float32Blendable:
			ret += { .Float32Blendable }
		case .ClipDistances:
			ret += { .ClipDistances }
		case .DualSourceBlending:
			ret += { .DualSourceBlending }

		// Native
		case .PushConstants:
			ret += { .PushConstants }
		case .TextureAdapterSpecificFormatFeatures:
			ret += { .TextureAdapterSpecificFormatFeatures }
		case .MultiDrawIndirect:
			ret += { .MultiDrawIndirect }
		case .MultiDrawIndirectCount:
			ret += { .MultiDrawIndirectCount }
		case .VertexWritableStorage:
			ret += { .VertexWritableStorage }
		case .TextureBindingArray:
			ret += { .TextureBindingArray }
		case .SampledTextureAndStorageBufferArrayNonUniformIndexing:
			ret += { .SampledTextureAndStorageBufferArrayNonUniformIndexing }
		case .PipelineStatisticsQuery:
			ret += { .PipelineStatisticsQuery }
		case .StorageResourceBindingArray:
			ret += { .StorageResourceBindingArray }
		case .PartiallyBoundBindingArray:
			ret += { .PartiallyBoundBindingArray }
		case .TextureFormat16bitNorm:
			ret += { .TextureFormat16bitNorm }
		case .TextureCompressionAstcHdr:
			ret += { .TextureCompressionAstcHdr }
		case .MappablePrimaryBuffers:
			ret += { .MappablePrimaryBuffers }
		case .BufferBindingArray:
			ret += { .BufferBindingArray }
		case .UniformBufferAndStorageTextureArrayNonUniformIndexing:
			ret += { .UniformBufferAndStorageTextureArrayNonUniformIndexing }
		case .SpirvShaderPassthrough:
			ret += { .SpirvShaderPassthrough }
		case .VertexAttribute64bit:
			ret += { .VertexAttribute64bit }
		case .TextureFormatNv12:
			ret += { .TextureFormatNv12 }
		case .RayTracingAccelarationStructure:
			ret += { .RayTracingAccelarationStructure }
		case .RayQuery:
			ret += { .RayQuery }
		case .ShaderF64:
			ret += { .ShaderF64 }
		case .ShaderI16:
			ret += { .ShaderI16 }
		case .ShaderPrimitiveIndex:
			ret += { .ShaderPrimitiveIndex }
		case .ShaderEarlyDepthTest:
			ret += { .ShaderEarlyDepthTest }
		case .Subgroup:
			ret += { .Subgroup }
		case .SubgroupVertex:
			ret += { .SubgroupVertex }
		case .SubgroupBarrier:
			ret += { .SubgroupBarrier }
		case .TimestampQueryInsideEncoders:
			ret += { .TimestampQueryInsideEncoders }
		case .TimestampQueryInsidePasses:
			ret += { .TimestampQueryInsidePasses }
		// case .ShaderInt64:
			// ret += { .ShaderInt64 }
		}
	}
	return
}

@(private)
_feature_flags_to_name :: proc "contextless" (
	featureName: Feature,
) -> (
	feature: wgpu.FeatureName,
) {
	#partial switch featureName {
	// WebGPU
	case .DepthClipControl:
		return .DepthClipControl
	case .Depth32FloatStencil8:
		return .Depth32FloatStencil8
	case .TimestampQuery:
		return .TimestampQuery
	case .TextureCompressionBC:
		return .TextureCompressionBC
	case .TextureCompressionBCSliced3D:
		return .TextureCompressionBCSliced3D
	case .TextureCompressionETC2:
		return .TextureCompressionETC2
	case .TextureCompressionASTC:
		return .TextureCompressionASTC
	case .TextureCompressionASTCSliced3D:
		return .TextureCompressionASTCSliced3D
	case .IndirectFirstInstance:
		return .IndirectFirstInstance
	case .ShaderF16:
		return .ShaderF16
	case .RG11B10UfloatRenderable:
		return .RG11B10UfloatRenderable
	case .BGRA8UnormStorage:
		return .BGRA8UnormStorage
	case .Float32Filterable:
		return .Float32Filterable
	case .Float32Blendable:
		return .Float32Blendable
	case .ClipDistances:
		return .ClipDistances
	case .DualSourceBlending:
		return .DualSourceBlending

	// Native
	case .PushConstants:
		return .PushConstants
	case .TextureAdapterSpecificFormatFeatures:
		return .TextureAdapterSpecificFormatFeatures
	case .MultiDrawIndirect:
		return .MultiDrawIndirect
	case .MultiDrawIndirectCount:
		return .MultiDrawIndirectCount
	case .VertexWritableStorage:
		return .VertexWritableStorage
	case .TextureBindingArray:
		return .TextureBindingArray
	case .SampledTextureAndStorageBufferArrayNonUniformIndexing:
		return .SampledTextureAndStorageBufferArrayNonUniformIndexing
	case .PipelineStatisticsQuery:
		return .PipelineStatisticsQuery
	case .StorageResourceBindingArray:
		return .StorageResourceBindingArray
	case .PartiallyBoundBindingArray:
		return .PartiallyBoundBindingArray
	case .TextureFormat16bitNorm:
		return .TextureFormat16bitNorm
	case .TextureCompressionAstcHdr:
		return .TextureCompressionAstcHdr
	case .MappablePrimaryBuffers:
		return .MappablePrimaryBuffers
	case .BufferBindingArray:
		return .BufferBindingArray
	case .UniformBufferAndStorageTextureArrayNonUniformIndexing:
		return .UniformBufferAndStorageTextureArrayNonUniformIndexing
	case .SpirvShaderPassthrough:
		return .SpirvShaderPassthrough
	case .VertexAttribute64bit:
		return .VertexAttribute64bit
	case .TextureFormatNv12:
		return .TextureFormatNv12
	case .RayTracingAccelarationStructure:
		return .RayTracingAccelarationStructure
	case .RayQuery:
		return .RayQuery
	case .ShaderF64:
		return .ShaderF64
	case .ShaderI16:
		return .ShaderI16
	case .ShaderPrimitiveIndex:
		return .ShaderPrimitiveIndex
	case .ShaderEarlyDepthTest:
		return .ShaderEarlyDepthTest
	case .Subgroup:
		return .Subgroup
	case .SubgroupVertex:
		return .SubgroupVertex
	case .SubgroupBarrier:
		return .SubgroupBarrier
	case .TimestampQueryInsideEncoders:
		return .TimestampQueryInsideEncoders
	case .TimestampQueryInsidePasses:
		return .TimestampQueryInsidePasses
	// case .ShaderInt64:
		// return .ShaderInt64

	case:
		return .Undefined
	}
}
