package webgpu

// Core
import intr "base:intrinsics"

// Vendor
import "vendor:wgpu"

/* Integral type used for buffer offsets. */
BufferAddress :: u64
/* Integral type used for buffer slice sizes. */
BufferSize :: u64
/* Integral type used for buffer slice sizes. */
ShaderLocation :: u32
/* Integral type used for dynamic bind group offsets. */
DynamicOffset :: u32

/*
Buffer-Texture copies must have `bytesPerRow` aligned to this number.

This doesn’t apply to `QueueWriteTexture`.
*/
COPY_BYTES_PER_ROW_ALIGNMENT: u32 : 256
/* An offset into the query resolve buffer has to be aligned to self. */
QUERY_RESOLVE_BUFFER_ALIGNMENT: BufferAddress : 256
/* Buffer to buffer copy, buffer clear offsets and sizes must be aligned to this number. */
COPY_BUFFER_ALIGNMENT: BufferAddress : 4
/* Buffer alignment mask to calculate proper size. */
COPY_BUFFER_ALIGNMENT_MASK :: COPY_BUFFER_ALIGNMENT - 1
/* Size to align mappings. */
MAP_ALIGNMENT: BufferAddress : 8
/* Vertex buffer strides have to be aligned to this number. */
VERTEX_STRIDE_ALIGNMENT: BufferAddress : 4
/* Alignment all push constants need. */
PUSH_CONSTANT_ALIGNMENT: u32 : 4
/* Maximum queries in a query set. */
QUERY_SET_MAX_QUERIES: u32 : 8192
/* Size of a single piece of query data. */
QUERY_SIZE: u32 : 8

/* Undefined array layer count. */
ARRAY_LAYER_COUNT_UNDEFINED :: max(u32)
/* Undefined copy stride. */
COPY_STRIDE_UNDEFINED :: max(u32)
/* Undefined depth slice. */
DEPTH_SLICE_UNDEFINED :: max(u32)
/* Undefined 32-bit limit. */
LIMIT_U32_UNDEFINED :: max(u32)
/* Undefined 64-bit limit. */
LIMIT_U64_UNDEFINED :: max(u64)
/* Undefined mip level count. */
MIP_LEVEL_COUNT_UNDEFINED :: max(u32)
/* Undefined query set index. */
QUERY_SET_INDEX_UNDEFINED :: max(u32)
/* Represents the whole map size. */
WHOLE_MAP_SIZE :: max(uint)
/* Represents the whole size. */
WHOLE_SIZE :: max(u64)

/* Base type for enums */
Flags :: wgpu.Flags

/* Backends supported by wgpu. */
Backend :: wgpu.BackendType

/* Supported physical device types. */
DeviceType :: wgpu.AdapterType

/* Types of shader stages that a binding will be visible from. */
ShaderStage :: wgpu.ShaderStage

/*
Describes the shader stages that a binding will be visible from.

These can be combined so something that is visible from both vertex and fragment
shaders can be defined as:

`ShaderStages{.Vertex, .Fragment}`

Corresponds to [WebGPU `GPUShaderStageFlags`](
https://gpuweb.github.io/gpuweb/#typedefdef-gpushaderstageflags).
*/
ShaderStages :: wgpu.ShaderStageFlags

/* Binding is not visible from any shader stage. */
SHADER_STAGE_NONE :: ShaderStages{}

/* Binding is visible from the vertex and fragment shaders of a render pipeline. */
SHADER_STAGE_VERTEX_FRAGMENT :: ShaderStages{ .Vertex, .Fragment }

ColorTargetStateFromTextureFormat :: proc "c" (
	format: TextureFormat,
) -> ColorTargetState {
	return { format = format, blend = nil, writeMask = COLOR_WRITES_ALL }
}

Multisample :: enum Flags {
	X1,
	X2,
	X4,
	X8,
	X16,
}

MultisampleFlags :: bit_set[Multisample;Flags]

/* Converts a Multisample enum value to its corresponding `u32` value. */
MultisampleToValue :: proc "c" (self: Multisample) -> u32 {
	#partial switch self {
	case .X1  : return 1
	case .X2  : return 2
	case .X4  : return 4
	case .X8  : return 8
	case .X16 : return 16
	}
	return 1
}

/* Color write mask types. */
ColorWrite :: wgpu.ColorWriteMask

/*
Color write mask. Disabled color channels will not be written to.

Corresponds to [WebGPU `GPUColorWriteFlags`](
https://gpuweb.github.io/gpuweb/#typedefdef-gpucolorwriteflags).
*/
ColorWrites :: wgpu.ColorWriteMaskFlags

/*  No color writes. */
COLOR_WRITES_NONE :: ColorWrites{}

/* Enable red, green, and blue channel writes. */
COLOR_WRITES_COLOR :: ColorWrites{.Red, .Green, .Blue}

/* Enable writes to all channels. */
COLOR_WRITES_ALL :: ColorWrites{.Red, .Green, .Blue, .Alpha}

/* Enable writes to all channels. */
COLOR_WRITES_DEFAULT :: COLOR_WRITES_ALL

/*
Comparison function used for depth and stencil operations.

Corresponds to [WebGPU `GPUCompareFunction`](
https://gpuweb.github.io/gpuweb/#enumdef-gpucomparefunction).
*/
CompareFunction :: wgpu.CompareFunction

/* Returns `true` if the comparison depends on the reference value. */
CompareFunctionNeedsRefValue :: proc "c" (self: CompareFunction) -> bool {
	return self == .Never || self == .Always
}

/* RGBA double precision color. */
Color :: wgpu.Color

COLOR_TRANSPARENT :: Color{0.0, 0.0, 0.0, 0.0}
COLOR_BLACK       :: Color{0.0, 0.0, 0.0, 1.0}
COLOR_WHITE       :: Color{1.0, 1.0, 1.0, 1.0}
COLOR_RED         :: Color{1.0, 0.0, 0.0, 1.0}
COLOR_GREEN       :: Color{0.0, 1.0, 0.0, 1.0}
COLOR_BLUE        :: Color{0.0, 0.0, 1.0, 1.0}

DEFAULT_DEPTH :: 1

/* A range of push constant memory to pass to a shader stage. */
PushConstantRange :: struct {
	stages: ShaderStages,
	range:  Range(u32),
}

/* Subresource range within an image. */
ImageSubresourceRange :: struct {
	aspect:            TextureAspect,
	base_mip_level:    u32,
	mipLevelCount:   u32,
	base_array_layer:  u32,
	array_layer_count: u32,
}

/* Color variation to use when sampler addressing mode is `AddressMode.ClampToBorder`. */
SamplerBorderColor :: enum i32 {
	Transparent_Black,
	Opaque_Black,
	Opaque_White,
	Zero,
}

ChainedStruct :: wgpu.ChainedStruct

ChainedStructOut :: wgpu.ChainedStructOut

CompilationMessageType :: wgpu.CompilationMessageType

ErrorFilter :: wgpu.ErrorFilter

MipmapFilterMode :: wgpu.MipmapFilterMode

OptionalBool :: wgpu.OptionalBool

Status :: wgpu.Status

WGSLLanguageFeatureName :: wgpu.WGSLLanguageFeatureName

ConstantEntry :: wgpu.ConstantEntry

Future :: wgpu.Future

SupportedWGSLLanguageFeatures :: wgpu.SupportedWGSLLanguageFeatures

FutureWaitInfo :: wgpu.FutureWaitInfo
