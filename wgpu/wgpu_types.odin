package wgpu

// Packages
import intr "base:intrinsics"
import "base:runtime"

/* Integral type used for buffer offsets.*/
BufferAddress :: u64
/* Integral type used for buffer slice sizes.*/
BufferSize :: u64
/* Integral type used for buffer slice sizes.*/
ShaderLocation :: u32
/* Integral type used for dynamic bind group offsets.*/
DynamicOffset :: u32

/*
Buffer-Texture copies must have `bytes_per_row` aligned to this number.

This doesn’t apply to `queue_write_texture`.
*/
COPY_BYTES_PER_ROW_ALIGNMENT: u32 : 256
/* An offset into the query resolve buffer has to be aligned to self.*/
QUERY_RESOLVE_BUFFER_ALIGNMENT: BufferAddress : 256
/* Buffer to buffer copy, buffer clear offsets and sizes must be aligned to this number.*/
COPY_BUFFER_ALIGNMENT: BufferAddress : 4
/* Buffer alignment mask to calculate proper size.*/
COPY_BUFFER_ALIGNMENT_MASK :: COPY_BUFFER_ALIGNMENT - 1
/* Size to align mappings.*/
MAP_ALIGNMENT: BufferAddress : 8
/* Vertex buffer strides have to be aligned to this number.*/
VERTEX_STRIDE_ALIGNMENT: BufferAddress : 4
/* Alignment all push constants need.*/
PUSH_CONSTANT_ALIGNMENT: u32 : 4
/* Maximum queries in a query set.*/
QUERY_SET_MAX_QUERIES: u32 : 8192
/* Size of a single piece of query data.*/
QUERY_SIZE: u32 : 8

/* Undefined array layer count.*/
ARRAY_LAYER_COUNT_UNDEFINED :: max(u32)
/* Undefined copy stride.*/
COPY_STRIDE_UNDEFINED :: max(u32)
/* Undefined depth slice.*/
DEPTH_SLICE_UNDEFINED :: max(u32)
/* Undefined 32-bit limit.*/
LIMIT_U32_UNDEFINED :: max(u32)
/* Undefined 64-bit limit.*/
LIMIT_U64_UNDEFINED :: max(u64)
/* Undefined mip level count.*/
MIP_LEVEL_COUNT_UNDEFINED :: max(u32)
/* Undefined query set index.*/
QUERY_SET_INDEX_UNDEFINED :: max(u32)
/* Represents the whole map size.*/
WHOLE_MAP_SIZE :: max(uint)
/* Represents the whole size.*/
WHOLE_SIZE :: max(u64)

/* Base type for enums */
Flags :: distinct u64
Bool :: b32

/* Backends supported by wgpu.*/
Backend :: enum i32 {
	Undefined = 0x00000000,
	Null      = 0x00000001,
	WebGPU    = 0x00000002,
	D3D11     = 0x00000003,
	D3D12     = 0x00000004,
	Metal     = 0x00000005,
	Vulkan    = 0x00000006,
	OpenGL    = 0x00000007,
	OpenGLES  = 0x00000008,
}

/*
Power Preference when choosing a physical adapter.

Corresponds to [WebGPU `GPUPowerPreference`](
https://gpuweb.github.io/gpuweb/#enumdef-gpupowerpreference).
*/
PowerPreference :: enum i32 {
	Undefined       = 0x00000000,
	LowPower        = 0x00000001,
	HighPerformance = 0x00000002,
}

/* HighPerformance. */
DEFAULT_POWER_PREFERENCE: PowerPreference = .HighPerformance

BackendBits :: enum u64 {
	Vulkan,
	GL,
	Metal,
	DX12,
	DX11,
	BrowserWebGPU,
}

/* Represents the backends that wgpu will use.*/
Backends :: distinct bit_set[BackendBits;u64]

/* All the apis that wgpu supports.*/
BACKENDS_ALL :: Backends{}

/* All the apis that wgpu offers first tier of support for.*/
BACKENDS_PRIMARY :: Backends{.Vulkan, .Metal, .DX12, .BrowserWebGPU}

/*
All the apis that wgpu offers second tier of support for.These may
be unsupported/still experimental.
*/
BACKENDS_SECONDARY :: Backends{.GL, .DX11}

/*
Options for requesting adapter.

Corresponds to [WebGPU `GPURequestAdapterOptions`](
https://gpuweb.github.io/gpuweb/#dictdef-gpurequestadapteroptions).
 */
RequestAdapterOptions :: struct {
	feature_level:          FeatureLevel,
	compatible_surface:     Surface,
	power_preference:       PowerPreference,
	backend:                Backend,
	force_fallback_adapter: bool,
}

InstanceFlag :: enum u64 {
	Debug,
	Validation,
	DiscardHalLabels,
}

/*
Instance debugging flags.

These are not part of the webgpu standard.
*/
InstanceFlags :: distinct bit_set[InstanceFlag;u64]

INSTANCE_FLAGS_DEFAULT :: InstanceFlags{}

/* Enable recommended debugging and validation flags.*/
INSTANCE_FLAGS_DEBUGGING :: InstanceFlags{.Debug, .Validation}

/* Supported physical device types.*/
DeviceType :: enum i32 {
	DiscreteGPU   = 0x00000001,
	IntegratedGPU = 0x00000002,
	CPU           = 0x00000003,
	Unknown       = 0x00000004,
}

/* Information about an adapter.*/
AdapterInfo :: struct {
	vendor:       string,
	architecture: string,
	device:       string,
	description:  string,
	backend:      Backend,
	device_type:  DeviceType,
	vendor_id:    u32,
	device_id:    u32,
}

/*  */
ShaderStage :: enum Flags {
	Vertex,
	Fragment,
	Compute,
}

/*
Describes the shader stages that a binding will be visible from.

These can be combined so something that is visible from both vertex and fragment shaders can be
defined as:

`ShaderStages{.Vertex, .Fragment}`

Corresponds to [WebGPU `GPUShaderStageFlags`](
https://gpuweb.github.io/gpuweb/#typedefdef-gpushaderstageflags).
*/
ShaderStages :: distinct bit_set[ShaderStage;Flags]

/* Binding is not visible from any shader stage.*/
SHADER_STAGE_NONE :: ShaderStages{}

/* Binding is visible from the vertex and fragment shaders of a render pipeline.*/
SHADER_STAGE_VERTEX_FRAGMENT :: ShaderStages{.Vertex, .Fragment}

/* Order in which texture data is laid out in memory.*/
TextureDataOrder :: enum {
	LayerMajor,
	MipMajor,
}

/*
Dimensions of a particular texture view.

Corresponds to [WebGPU `GPUTextureViewDimension`](
https://gpuweb.github.io/gpuweb/#enumdef-gputextureviewdimension).
*/
TextureViewDimension :: enum i32 {
	Undefined = 0x00000000,
	D1        = 0x00000001,
	D2        = 0x00000002,
	D2Array   = 0x00000003,
	Cube      = 0x00000004,
	CubeArray = 0x00000005,
	D3        = 0x00000006,
}

/*
Alpha blend factor.

Corresponds to [WebGPU `GPUBlendFactor`](
https://gpuweb.github.io/gpuweb/#enumdef-gpublendfactor).

For further details on how the blend factors are applied, see the analogous
functionality in OpenGL: <https://www.khronos.org/opengl/wiki/Blending#Blending_Parameters>.
*/
BlendFactor :: enum i32 {
	Undefined         = 0x00000000,
	Zero              = 0x00000001,
	One               = 0x00000002,
	Src               = 0x00000003,
	OneMinusSrc       = 0x00000004,
	SrcAlpha          = 0x00000005,
	OneMinusSrcAlpha  = 0x00000006,
	Dst               = 0x00000007,
	OneMinusDst       = 0x00000008,
	DstAlpha          = 0x00000009,
	OneMinusDstAlpha  = 0x0000000A,
	SrcAlphaSaturated = 0x0000000B,
	Constant          = 0x0000000C,
	OneMinusConstant  = 0x0000000D,
	Src1              = 0x0000000E,
	OneMinusSrc1      = 0x0000000F,
	Src1Alpha         = 0x00000010,
	OneMinusSrc1Alpha = 0x00000011,
}

/*
Alpha blend operation.

Corresponds to [WebGPU `GPUBlendOperation`](
https://gpuweb.github.io/gpuweb/#enumdef-gpublendoperation).

For further details on how the blend operations are applied, see
the analogous functionality in OpenGL:
<https://www.khronos.org/opengl/wiki/Blending#Blend_Equations>.
*/
BlendOperation :: enum i32 {
	Undefined       = 0x00000000,
	Add             = 0x00000001,
	Subtract        = 0x00000002,
	ReverseSubtract = 0x00000003,
	Min             = 0x00000004,
	Max             = 0x00000005,
}

/*
Describes a blend component of a [`BlendState`].

Corresponds to [WebGPU `GPUBlendComponent`](
https://gpuweb.github.io/gpuweb/#dictdef-gpublendcomponent).
*/
BlendComponent :: struct {
	operation:  BlendOperation,
	src_factor: BlendFactor,
	dst_factor: BlendFactor,
}

/* Standard blending state that blends source and destination based on source alpha.*/
BLEND_COMPONENT_NORMAL :: BlendComponent {
	operation  = .Add,
	src_factor = .SrcAlpha,
	dst_factor = .OneMinusSrcAlpha,
}

// Default blending state that replaces destination with the source.
BLEND_COMPONENT_REPLACE :: BlendComponent {
	operation  = .Add,
	src_factor = .One,
	dst_factor = .Zero,
}

// Blend state of (1 * src) + ((1 - src_alpha) * dst)
BLEND_COMPONENT_OVER :: BlendComponent {
	operation  = .Add,
	src_factor = .One,
	dst_factor = .OneMinusSrcAlpha,
}

/*  */
DEFAULT_BLEND_COMPONENT :: BLEND_COMPONENT_REPLACE

/*
Returns `true` if the state relies on the constant color, which is
set independently on a render command encoder.
*/
blend_component_uses_constant :: proc "contextless" (self: BlendComponent) -> bool {
	return(
		self.src_factor == .Constant ||
		self.src_factor == .OneMinusConstant ||
		self.dst_factor == .Constant ||
		self.dst_factor == .OneMinusConstant \
	)
}

/*
Describe the blend state of a render pipeline,
within `ColorTargetState`.

Corresponds to [WebGPU `GPUBlendState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpublendstate).
*/
BlendState :: struct {
	color: BlendComponent,
	alpha: BlendComponent,
}

/* Uses alpha blending for both color and alpha channels.*/
@(rodata)
BLEND_STATE_NORMAL := BlendState {
	color = BLEND_COMPONENT_NORMAL,
	alpha = BLEND_COMPONENT_NORMAL,
}

/* Does no color blending, just overwrites the output with the contents of the shader.*/
@(rodata)
BLEND_STATE_REPLACE := BlendState {
	color = BLEND_COMPONENT_REPLACE,
	alpha = BLEND_COMPONENT_REPLACE,
}

/* Does standard alpha blending with non-premultiplied alpha.*/
@(rodata)
BLEND_STATE_ALPHA_BLENDING := BlendState {
	color = BLEND_COMPONENT_NORMAL,
	alpha = BLEND_COMPONENT_OVER,
}

/* Does standard alpha blending with premultiplied alpha.*/
@(rodata)
BLEND_STATE_PREMULTIPLIED_ALPHA_BLENDING := BlendState {
	color = BLEND_COMPONENT_OVER,
	alpha = BLEND_COMPONENT_OVER,
}

/*
Describes the color state of a render pipeline.

Corresponds to [WebGPU `GPUColorTargetState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpucolortargetstate).
*/
ColorTargetState :: struct {
	next_in_chain: ^ChainedStruct,
	format:        TextureFormat,
	blend:         ^BlendState,
	write_mask:    ColorWrites,
}

color_target_state_from_texture_format :: proc(format: TextureFormat) -> ColorTargetState {
	return {format = format, blend = nil, write_mask = COLOR_WRITES_ALL}
}

/*
Primitive type the input mesh is composed of.

Corresponds to [WebGPU `GPUPrimitiveTopology`](
https://gpuweb.github.io/gpuweb/#enumdef-gpuprimitivetopology).
*/
PrimitiveTopology :: enum {
	TriangleList, // Default here, not in wgpu
	PointList,
	LineList,
	LineStrip,
	TriangleStrip,
}

primitive_topology_is_strip :: proc "contextless" (self: PrimitiveTopology) -> bool {
	#partial switch self {
	case .TriangleStrip, .LineStrip:
		return true
	}
	return false
}

/*
Vertex winding order which classifies the "front" face of a triangle.

Corresponds to [WebGPU `GPUFrontFace`](
https://gpuweb.github.io/gpuweb/#enumdef-gpufrontface).
*/
FrontFace :: enum i32 {
	Undefined = 0x00000000,
	CCW       = 0x00000001,
	CW        = 0x00000002,
}

/*
Face of a vertex.

Corresponds to [WebGPU `GPUCullMode`](
https://gpuweb.github.io/gpuweb/#enumdef-gpucullmode).
*/
Face :: enum i32 {
	Undefined = 0x00000000,
	None      = 0x00000001,
	Front     = 0x00000002,
	Back      = 0x00000003,
}

/*
Describes the state of primitive assembly and rasterization in a render pipeline.

Corresponds to [WebGPU `GPUPrimitiveState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuprimitivestate).
*/
PrimitiveState :: struct {
	topology:           PrimitiveTopology,
	strip_index_format: IndexFormat,
	front_face:         FrontFace,
	cull_mode:          Face,
	unclipped_depth:    bool,
}

DEFAULT_PRIMITIVE_STATE :: PrimitiveState {
	topology   = .TriangleList,
	front_face = .CCW,
	cull_mode  = .None,
}

/*
Describes the multi-sampling state of a render pipeline.

Corresponds to [WebGPU `GPUMultisampleState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpumultisamplestate).
*/
MultisampleState :: struct {
	next_in_chain:             ^ChainedStruct,
	count:                     u32,
	mask:                      u32,
	alpha_to_coverage_enabled: bool,
}

/* Default `count = 1` and mask all pixels `0xFFFFFFFF`.*/
DEFAULT_MULTISAMPLE_STATE :: MultisampleState {
	next_in_chain             = nil,
	count                     = 1,
	mask                      = max(u32), // 0xFFFFFFFF
	alpha_to_coverage_enabled = false,
}

Multisample :: enum Flags {
	X1,
	X2,
	X4,
	X8,
	X16,
}

MultisampleFlags :: bit_set[Multisample;Flags]

/* Converts a Multisample enum value to its corresponding `u32` value.*/
multisample_to_value :: proc(self: Multisample) -> u32 {
	// odinfmt: disable
	#partial switch self {
	case .X1  : return 1
	case .X2  : return 2
	case .X4  : return 4
	case .X8  : return 8
	case .X16 : return 16
	}
	// odinfmt: enable
	return 1
}

ColorWrite :: enum Flags {
	Red,
	Green,
	Blue,
	Alpha,
}

/*
Color write mask. Disabled color channels will not be written to.

Corresponds to [WebGPU `GPUColorWriteFlags`](
https://gpuweb.github.io/gpuweb/#typedefdef-gpucolorwriteflags).
*/
ColorWrites :: distinct bit_set[ColorWrite;Flags]

/*  */
COLOR_WRITES_NONE :: ColorWrites{}

/* Enable red, green, and blue channel writes. */
COLOR_WRITES_COLOR :: ColorWrites{.Red, .Green, .Blue}

/* Enable writes to all channels. */
COLOR_WRITES_ALL :: ColorWrites{.Red, .Green, .Blue, .Alpha}

/*  */
DEFAULT_COLOR_WRITES :: COLOR_WRITES_ALL

/*
State of the stencil operation (fixed-pipeline stage).

For use in `DepthStencilState`.

Corresponds to a portion of [WebGPU `GPUDepthStencilState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpudepthstencilstate).
*/
StencilState :: struct {
	front:      StencilFaceState,
	back:       StencilFaceState,
	read_mask:  u32,
	write_mask: u32,
}

/* Returns true if the stencil test is enabled. */
stencil_state_is_enabled :: proc "contextless" (self: StencilState) -> bool {
	return(
		(self.front != STENCIL_FACE_STATE_IGNORE || self.back != STENCIL_FACE_STATE_IGNORE) &&
		(self.read_mask != 0 || self.write_mask != 0) \
	)
}

/* Returns `true` if the state doesn't mutate the target values. */
stencil_state_is_read_only :: proc "contextless" (self: StencilState, cull_mode: Face) -> bool {
	// The rules are defined in step 7 of the "Device timeline initialization steps"
	// subsection of the "Render Pipeline Creation" section of WebGPU
	// (link to the section: https://gpuweb.github.io/gpuweb/#render-pipeline-creation)
	if self.write_mask == 0 {
		return true
	}

	front_ro := cull_mode == .Front || stencil_face_state_is_read_only(self.front)
	back_ro := cull_mode == .Back || stencil_face_state_is_read_only(self.back)

	return front_ro && back_ro
}

/* Returns true if the stencil state uses the reference value for testing. */
stencil_state_needs_ref_value :: proc "contextless" (self: StencilState) -> bool {
	return(
		stencil_face_state_needs_ref_value(self.front) ||
		stencil_face_state_needs_ref_value(self.back) \
	)
}

/*
Describes the biasing setting for the depth target.

For use in `DepthStencilState`.

Corresponds to a portion of [WebGPU `GPUDepthStencilState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpudepthstencilstate).
*/
DepthBiasState :: struct {
	constant:    i32,
	slope_scale: f32,
	clamp:       f32,
}

/* Returns true if the depth biasing is enabled. */
depth_bias_state_is_enabled :: proc "contextless" (self: DepthBiasState) -> bool {
	return self.constant != 0 || self.slope_scale != 0.0
}

/*
Describes the depth/stencil state in a render pipeline.

Corresponds to [WebGPU `GPUDepthStencilState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpudepthstencilstate).
*/
DepthStencilState :: struct {
	format:              TextureFormat,
	depth_write_enabled: bool,
	depth_compare:       CompareFunction,
	stencil:             StencilState,
	bias:                DepthBiasState,
}

/* Returns `true` if the depth testing is enabled. */
depth_stencil_state_is_depth_enabled :: proc "contextless" (self: DepthStencilState) -> bool {
	return(
		(self.depth_compare != .Undefined && self.depth_compare != .Always) ||
		self.depth_write_enabled \
	)
}

/* Returns `true` if the state doesn't mutate the depth buffer. */
depth_stencil_state_is_depth_read_only :: proc "contextless" (self: DepthStencilState) -> bool {
	return !self.depth_write_enabled
}

/* Returns true if the state doesn't mutate the stencil. */
depth_stencil_state_is_stencil_read_only :: proc "contextless" (
	self: DepthStencilState,
	cull_mode: Face,
) -> bool {
	return stencil_state_is_read_only(self.stencil, cull_mode)
}

/* Returns true if the state doesn't mutate either depth or stencil of the target. */
depth_stencil_state_is_read_only :: proc "contextless" (
	self: DepthStencilState,
	cull_mode: Face,
) -> bool {
	return(
		depth_stencil_state_is_depth_read_only(self) &&
		depth_stencil_state_is_stencil_read_only(self, cull_mode) \
	)
}

/*
Format of indices used with pipeline.

Corresponds to [WebGPU `GPUIndexFormat`](
https://gpuweb.github.io/gpuweb/#enumdef-gpuindexformat).
*/
IndexFormat :: enum i32 {
	Undefined = 0x00000000,
	Uint16    = 0x00000001,
	Uint32    = 0x00000002,
}

/*
Operation to perform on the stencil value.

Corresponds to [WebGPU `GPUStencilOperation`](
https://gpuweb.github.io/gpuweb/#enumdef-gpustenciloperation).
*/
StencilOperation :: enum i32 {
	Undefined      = 0x00000000,
	Keep           = 0x00000001,
	Zero           = 0x00000002,
	Replace        = 0x00000003,
	Invert         = 0x00000004,
	IncrementClamp = 0x00000005,
	DecrementClamp = 0x00000006,
	IncrementWrap  = 0x00000007,
	DecrementWrap  = 0x00000008,
}

/*
Describes stencil state in a render pipeline.

If you are not using stencil state, set this to `STENCIL_FACE_STATE_IGNORE`.

Corresponds to [WebGPU `GPUStencilFaceState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpustencilfacestate).
*/
StencilFaceState :: struct {
	compare:       CompareFunction,
	fail_op:       StencilOperation,
	depth_fail_op: StencilOperation,
	pass_op:       StencilOperation,
}

/* Ignore the stencil state for the face. */
STENCIL_FACE_STATE_IGNORE :: StencilFaceState {
	compare       = .Always,
	fail_op       = .Keep,
	depth_fail_op = .Keep,
	pass_op       = .Keep,
}

/* Returns true if the face state uses the reference value for testing or operation. */
stencil_face_state_needs_ref_value :: proc "contextless" (self: StencilFaceState) -> bool {
	return(
		compare_function_needs_ref_value(self.compare) ||
		self.fail_op == .Replace ||
		self.depth_fail_op == .Replace ||
		self.pass_op == .Replace \
	)
}

/* Returns true if the face state doesn't mutate the target values. */
stencil_face_state_is_read_only :: proc "contextless" (self: StencilFaceState) -> bool {
	return self.pass_op == .Keep && self.depth_fail_op == .Keep && self.fail_op == .Keep
}

/*
Comparison function used for depth and stencil operations.

Corresponds to [WebGPU `GPUCompareFunction`](
https://gpuweb.github.io/gpuweb/#enumdef-gpucomparefunction).
*/
CompareFunction :: enum i32 {
	Undefined    = 0x00000000,
	Never        = 0x00000001,
	Less         = 0x00000002,
	Equal        = 0x00000003,
	LessEqual    = 0x00000004,
	Greater      = 0x00000005,
	NotEqual     = 0x00000006,
	GreaterEqual = 0x00000007,
	Always       = 0x00000008,
}

/* Returns `true` if the comparison depends on the reference value. */
compare_function_needs_ref_value :: proc "contextless" (self: CompareFunction) -> bool {
	return self == .Never || self == .Always
}

/*
Whether a vertex buffer is indexed by vertex or by instance.

Corresponds to [WebGPU `GPUVertexStepMode`](
https://gpuweb.github.io/gpuweb/#enumdef-gpuvertexstepmode).
*/
VertexStepMode :: enum i32 {
	VertexBufferNotUsed = 0x00000000,
	Undefined           = 0x00000001,
	Vertex              = 0x00000002,
	Instance            = 0x00000003,
}

/*
Vertex inputs (attributes) to shaders.

Arrays of these can be made with the `vertex_attr_array`
macro. Vertex attributes are assumed to be tightly packed.

Corresponds to [WebGPU `GPUVertexAttribute`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuvertexattribute).
*/
VertexAttribute :: struct {
	format:          VertexFormat,
	offset:          u64,
	shader_location: u32,
}

/*
Vertex Format for a `VertexAttribute` (input).

Corresponds to [WebGPU `GPUVertexFormat`](
https://gpuweb.github.io/gpuweb/#enumdef-gpuvertexformat).
*/
VertexFormat :: enum i32 {
	Uint8           = 0x00000001,
	Uint8x2         = 0x00000002,
	Uint8x4         = 0x00000003,
	Sint8           = 0x00000004,
	Sint8x2         = 0x00000005,
	Sint8x4         = 0x00000006,
	Unorm8          = 0x00000007,
	Unorm8x2        = 0x00000008,
	Unorm8x4        = 0x00000009,
	Snorm8          = 0x0000000A,
	Snorm8x2        = 0x0000000B,
	Snorm8x4        = 0x0000000C,
	Uint16          = 0x0000000D,
	Uint16x2        = 0x0000000E,
	Uint16x4        = 0x0000000F,
	Sint16          = 0x00000010,
	Sint16x2        = 0x00000011,
	Sint16x4        = 0x00000012,
	Unorm16         = 0x00000013,
	Unorm16x2       = 0x00000014,
	Unorm16x4       = 0x00000015,
	Snorm16         = 0x00000016,
	Snorm16x2       = 0x00000017,
	Snorm16x4       = 0x00000018,
	Float16         = 0x00000019,
	Float16x2       = 0x0000001A,
	Float16x4       = 0x0000001B,
	Float32         = 0x0000001C,
	Float32x2       = 0x0000001D,
	Float32x3       = 0x0000001E,
	Float32x4       = 0x0000001F,
	Uint32          = 0x00000020,
	Uint32x2        = 0x00000021,
	Uint32x3        = 0x00000022,
	Uint32x4        = 0x00000023,
	Sint32          = 0x00000024,
	Sint32x2        = 0x00000025,
	Sint32x3        = 0x00000026,
	Sint32x4        = 0x00000027,
	Unorm10_10_10_2 = 0x00000028,
	Unorm8x4Bgra    = 0x00000029,
}

vertex_format_size :: proc "contextless" (self: VertexFormat) -> u64 {
	// odinfmt: disable
	switch self {
	case .Uint8, .Sint8, .Unorm8, .Snorm8: return 1
	case .Uint8x2, .Sint8x2, .Unorm8x2, .Snorm8x2, .Uint16, .Sint16, .Unorm16, .Snorm16, .Float16:
		return 2
	case .Uint8x4, .Sint8x4, .Unorm8x4, .Snorm8x4, .Uint16x2, .Sint16x2, .Unorm16x2, .Snorm16x2,
		 .Float16x2, .Float32, .Uint32, .Sint32, .Unorm10_10_10_2, .Unorm8x4Bgra: return 4
	case .Uint16x4, .Sint16x4, .Unorm16x4, .Snorm16x4, .Float16x4, .Float32x2, .Uint32x2,
		 .Sint32x2 /* .Float64 */: return 8
	case .Float32x3, .Uint32x3, .Sint32x3: return 12
	case .Float32x4, .Uint32x4, .Sint32x4 /* .Float64x2 */: return 16
	/* case .Float64x3: return 24 */
	/* case .Float64x4: return 32 */
	}
	// odinfmt: enable
	return 0
}

BufferUsage :: enum Flags {
	MapRead,
	MapWrite,
	CopySrc,
	CopyDst,
	Index,
	Vertex,
	Uniform,
	Storage,
	Indirect,
	QueryResolve,
}

/*
Different ways that you can use a buffer.

The usages determine what kind of memory the buffer is allocated from and what
actions the buffer can partake in.

Corresponds to [WebGPU `GPUBufferUsageFlags`](
https://gpuweb.github.io/gpuweb/#typedefdef-gpubufferusageflags).
*/
BufferUsages :: distinct bit_set[BufferUsage;Flags]

BUFFER_USAGE_NONE :: BufferUsages{}

/*
Describes a `CommandEncoder`

Corresponds to [WebGPU `GPUCommandEncoderDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpucommandencoderdescriptor).
*/
CommandEncoderDescriptor :: struct {
	label: string,
}

/* Behavior of the presentation engine based on frame rate. */
PresentMode :: enum i32 {
	Undefined   = 0x00000000,
	Fifo        = 0x00000001,
	FifoRelaxed = 0x00000002,
	Immediate   = 0x00000003,
	Mailbox     = 0x00000004,
}

/* Specifies how the alpha channel of the textures should be handled during compositing. */
CompositeAlphaMode :: enum i32 {
	Auto            = 0x00000000,
	Opaque          = 0x00000001,
	Premultiplied   = 0x00000002,
	Unpremultiplied = 0x00000003,
	Inherit         = 0x00000004,
}


TextureUsage :: enum Flags {
	CopySrc,
	CopyDst,
	TextureBinding,
	StorageBinding,
	RenderAttachment,
}

/*
Different ways that you can use a texture.

The usages determine what kind of memory the texture is allocated from and what
actions the texture can partake in.

Corresponds to [WebGPU `GPUTextureUsageFlags`](
https://gpuweb.github.io/gpuweb/#typedefdef-gputextureusageflags).
*/
TextureUsages :: distinct bit_set[TextureUsage;Flags]

TEXTURE_USAGES_NONE :: TextureUsages{}

TEXTURE_USAGES_ALL :: TextureUsages {
	.CopySrc,
	.CopyDst,
	.TextureBinding,
	.StorageBinding,
	.RenderAttachment,
}

/* The capabilities of a given surface and adapter. */
SurfaceCapabilities :: struct {
	allocator:     runtime.Allocator,
	formats:       []TextureFormat,
	present_modes: []PresentMode,
	alpha_modes:   []CompositeAlphaMode,
	usages:        TextureUsages,
}

surface_capabilities_free_members :: proc(self: SurfaceCapabilities) {
	context.allocator = self.allocator
	delete(self.formats)
	delete(self.present_modes)
	delete(self.alpha_modes)
}

/* Status of the received surface image. */
SurfaceStatus :: enum i32 {
	SuccessOptimal    = 0x00000001,
	SuccessSuboptimal = 0x00000002,
	Timeout           = 0x00000003,
	Outdated          = 0x00000004,
	Lost              = 0x00000005,
	OutOfMemory       = 0x00000006,
	DeviceLost        = 0x00000007,
	Error             = 0x00000008,
}

@(private)
WGPUColor :: struct {
	r: f64,
	g: f64,
	b: f64,
	a: f64,
}

/*
RGBA double precision color.

This is not to be used as a generic color type, only for specific wgpu interfaces.
*/
Color :: [4]f64

COLOR_TRANSPARENT :: Color{0.0, 0.0, 0.0, 0.0}
COLOR_BLACK :: Color{0.0, 0.0, 0.0, 1.0}
COLOR_WHITE :: Color{1.0, 1.0, 1.0, 1.0}
COLOR_RED :: Color{1.0, 0.0, 0.0, 1.0}
COLOR_GREEN :: Color{0.0, 1.0, 0.0, 1.0}
COLOR_BLUE :: Color{0.0, 0.0, 1.0, 1.0}

/*
Dimensionality of a texture.

Corresponds to [WebGPU `GPUTextureDimension`](
https://gpuweb.github.io/gpuweb/#enumdef-gputexturedimension).
*/
TextureDimension :: enum i32 {
	Undefined = 0x00000000,
	D1        = 0x00000001,
	D2        = 0x00000002,
	D3        = 0x00000003,
}

/*
Origin of a copy from a 2D image.

Corresponds to [WebGPU `GPUOrigin2D`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuorigin2ddict).
*/
Origin2D :: struct {
	x: u32,
	y: u32,
}
Origin2d :: Origin2D

/* Adds the third dimension to this origin. */
origin_2d_to_3d :: proc "contextless" (self: Origin2D) -> Origin3D {
	return {x = self.x, y = self.y, z = 0}
}

/*
Origin of a copy to/from a texture.

Corresponds to [WebGPU `GPUOrigin3D`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuorigin3ddict).
*/
Origin3D :: struct {
	x: u32,
	y: u32,
	z: u32,
}
Origin3d :: Origin3D

origin_3d_to_2d :: proc "contextless" (self: Origin3D) -> Origin2D {
	return {x = self.x, y = self.y}
}

/*
Extent of a texture related operation.

Corresponds to [WebGPU `GPUExtent3D`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuextent3ddict).
*/
Extent3D :: struct {
	width:                 u32,
	height:                u32,
	depth_or_array_layers: u32,
}
Extent3d :: Extent3D

default_depth :: proc "contextless" () -> u32 {
	return 1
}

DEFAULT_EXTENT_3D :: Extent3D{1, 1, 1}

/*
Calculates the [physical size] backing a texture of the given  format and extent.  This
includes padding to the block width and height of the format.

This is the texture extent that you must upload at when uploading to _mipmaps_ of compressed
textures.

[physical size]: https://gpuweb.github.io/gpuweb/#physical-miplevel-specific-texture-extent
*/
extent_3d_physical_size :: proc "contextless" (
	self: Extent3D,
	format: TextureFormat,
) -> (
	extent: Extent3D,
) {
	block_width, block_height := texture_format_block_dimensions(format)

	extent.width = ((self.width + block_width - 1) / block_width) * block_width
	extent.height = ((self.height + block_height - 1) / block_height) * block_height
	extent.depth_or_array_layers = self.depth_or_array_layers

	return
}

/*
Calculates the maximum possible count of mipmaps.

Treats the depth as part of the mipmaps. If calculating
for a 2DArray texture, which does not mipmap depth, set depth to 1.
*/
extent_3d_max_mips :: proc "contextless" (
	self: Extent3D,
	dimension: TextureDimension,
) -> (
	max_dim: u32,
) {
	// odinfmt: disable
	switch dimension {
	case .Undefined: return 0
	case .D1: return 1
	case .D2: max_dim = max(self.width, self.height)
	case .D3: max_dim = max(self.width, max(self.height, self.depth_or_array_layers))
	}
	// odinfmt: enable
	return 32 - intr.count_leading_zeros(max_dim)
}

/*
Calculates the extent at a given mip level.
Does *not* account for memory size being a multiple of block size.

<https://gpuweb.github.io/gpuweb/#logical-miplevel-specific-texture-extent>
*/
extent_3d_mip_level_size :: proc "contextless" (
	self: Extent3D,
	level: u32,
	dimension: TextureDimension,
) -> (
	extent: Extent3D,
) {
	extent.width = max(1, self.width >> level)

	// odinfmt: disable
	#partial switch dimension {
	case .D1: extent.height = 1
	case: extent.height = max(1, self.height >> level)
	}

	#partial switch dimension {
	case .D1: extent.depth_or_array_layers = 1
	case .D2: extent.depth_or_array_layers = self.depth_or_array_layers
	case .D3: extent.depth_or_array_layers = max(1, self.depth_or_array_layers >> level)
	}
	// odinfmt: enable

	return
}

/*
Describes a `TextureView`.

For use with `texture_create_view`.

Corresponds to [WebGPU `GPUTextureViewDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gputextureviewdescriptor).
*/
TextureViewDescriptor :: struct {
	label:             string,
	format:            TextureFormat,
	dimension:         TextureViewDimension,
	base_mip_level:    u32,
	mip_level_count:   u32,
	base_array_layer:  u32,
	array_layer_count: u32,
	aspect:            TextureAspect,
	usage:             TextureUsages,
}


/*
Calculates the extent at a given mip level.

If the given mip level is larger than possible, returns None.

Treats the depth as part of the mipmaps. If calculating
for a 2DArray texture, which does not mipmap depth, set depth to 1.
*/
texture_descriptor_mip_level_size :: proc "contextless" (
	self: TextureDescriptor,
	level: u32,
) -> (
	extent: Extent3D,
	ok: bool,
) #optional_ok {
	if level >= self.mip_level_count {
		return {}, false
	}
	extent = extent_3d_mip_level_size(self.size, level, self.dimension)
	return extent, true
}

/*
Computes the render extent of this texture.

<https://gpuweb.github.io/gpuweb/#abstract-opdef-compute-render-extent>
*/
texture_descriptor_compute_render_extent :: proc "contextless" (
	self: TextureDescriptor,
	mip_level: u32,
) -> Extent3D {
	return Extent3d {
		width = max(1, self.size.width >> mip_level),
		height = max(1, self.size.height >> mip_level),
		depth_or_array_layers = 1,
	}
}

/*
Returns the number of array layers.

<https://gpuweb.github.io/gpuweb/#abstract-opdef-array-layer-count>
*/
texture_descriptor_array_layer_count :: proc "contextless" (
	self: TextureDescriptor,
) -> (
	count: u32,
) {
	// odinfmt: disable
	switch self.dimension {
	case .Undefined: return 0
	case .D1, .D3: count = 1
	case .D2: count = self.size.depth_or_array_layers
	}
	// odinfmt: enable
	return
}

/* Returns `true` if the given `TextureDescriptor` is compatible with cube textures. */
texture_descriptor_is_cube_compatible :: proc "contextless" (self: TextureDescriptor) -> bool {
	return(
		self.dimension == .D2 &&
		self.size.depth_or_array_layers % 6 == 0 &&
		self.sample_count == 1 &&
		self.size.width == self.size.height \
	)
}

/*
Kind of data the texture holds.

Corresponds to [WebGPU `GPUTextureAspect`](
https://gpuweb.github.io/gpuweb/#enumdef-gputextureaspect).
*/
TextureAspect :: enum i32 {
	Undefined   = 0x00000000,
	All         = 0x00000001,
	StencilOnly = 0x00000002,
	DepthOnly   = 0x00000003,
	Plane0      = 0x00000004,
	Plane1      = 0x00000005,
	Plane2      = 0x00000006,
}

/*
How edges should be handled in texture addressing.

Corresponds to [WebGPU `GPUAddressMode`](
https://gpuweb.github.io/gpuweb/#enumdef-gpuaddressmode).
*/
AddressMode :: enum i32 {
	Undefined    = 0x00000000,
	ClampToEdge  = 0x00000001,
	Repeat       = 0x00000002,
	MirrorRepeat = 0x00000003,
}

/*
Texel mixing mode when sampling between texels.

Corresponds to [WebGPU `GPUFilterMode`](
https://gpuweb.github.io/gpuweb/#enumdef-gpufiltermode).
*/
FilterMode :: enum i32 {
	Undefined = 0x00000000,
	Nearest   = 0x00000001,
	Linear    = 0x00000002,
}

/* A range of push constant memory to pass to a shader stage. */
PushConstantRange :: struct {
	stages: ShaderStages,
	range:  Range(u32),
}

/*
Describes a `CommandBuffer`.

Corresponds to [WebGPU `GPUCommandBufferDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpucommandbufferdescriptor).
*/
CommandBufferDescriptor :: struct {
	label: string,
}

/*
Layout of a texture in a buffer's memory.

Corresponds to [WebGPU `GPUTexelCopyBufferLayout`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuimagedatalayout).
*/
TexelCopyBufferLayout :: struct {
	offset:         u64,
	bytes_per_row:  u32,
	rows_per_image: u32,
}

/*
Specific type of a buffer binding.

Corresponds to [WebGPU `GPUBufferBindingType`](
https://gpuweb.github.io/gpuweb/#enumdef-gpubufferbindingtype).
*/
BufferBindingType :: enum i32 {
	BindingNotUsed  = 0x00000000,
	Undefined       = 0x00000001,
	Uniform         = 0x00000002,
	Storage         = 0x00000003,
	ReadOnlyStorage = 0x00000004,
}

/*
Specific type of a sample in a texture binding.

Corresponds to [WebGPU `GPUTextureSampleType`](
https://gpuweb.github.io/gpuweb/#enumdef-gputexturesampletype).
*/
TextureSampleType :: enum i32 {
	BindingNotUsed    = 0x00000000,
	Undefined         = 0x00000001,
	Float             = 0x00000002,
	UnfilterableFloat = 0x00000003,
	Depth             = 0x00000004,
	Sint              = 0x00000005,
	Uint              = 0x00000006,
}

DEFAULT_TEXTURE_SAMPLE_TYPE :: TextureSampleType.Float

/*
Specific type of a sample in a texture binding.

For use in [`BindingType::StorageTexture`].

Corresponds to [WebGPU `GPUStorageTextureAccess`](
https://gpuweb.github.io/gpuweb/#enumdef-gpustoragetextureaccess).
*/
StorageTextureAccess :: enum i32 {
	BindingNotUsed = 0x00000000,
	Undefined      = 0x00000001,
	WriteOnly      = 0x00000002,
	ReadOnly       = 0x00000003,
	ReadWrite      = 0x00000004,
}

/*
Specific type of a sampler binding.

For use in `BindingType.Sampler`.

Corresponds to [WebGPU `GPUSamplerBindingType`](
https://gpuweb.github.io/gpuweb/#enumdef-gpusamplerbindingtype).
*/
SamplerBindingType :: enum i32 {
	BindingNotUsed = 0x00000000,
	Undefined      = 0x00000001,
	Filtering      = 0x00000002,
	NonFiltering   = 0x00000003,
	Comparison     = 0x00000004,
}

/*
Specific type of a binding.

For use in `BindGroupLayoutEntry`.

Corresponds to WebGPU's mutually exclusive fields within [`GPUBindGroupLayoutEntry`](
https://gpuweb.github.io/gpuweb/#dictdef-gpubindgrouplayoutentry).
*/
BindingType :: union {
	BufferBindingLayout,
	SamplerBindingLayout,
	TextureBindingLayout,
	StorageTextureBindingLayout,
}

/*
Describes a single binding inside a bind group.

Corresponds to [WebGPU `GPUBindGroupLayoutEntry`](
https://gpuweb.github.io/gpuweb/#dictdef-gpubindgrouplayoutentry).
*/
BindGroupLayoutEntry :: struct {
	binding:    u32,
	visibility: ShaderStages,
	type:       BindingType,
	count:      u32,
}

/* Subresource range within an image. */
ImageSubresourceRange :: struct {
	aspect:            TextureAspect,
	base_mip_level:    u32,
	mip_level_count:   u32,
	base_array_layer:  u32,
	array_layer_count: u32,
}

/* Color variation to use when sampler addressing mode is `AddressMode.ClampToBorder`. */
SamplerBorderColor :: enum i32 {
	TransparentBlack,
	OpaqueBlack,
	OpaqueWhite,
	Zero,
}

/*
Selects which DX12 shader compiler to fuse.

If the `Dxc` option is selected, but `dxcompiler.dll` and `dxil.dll` files aren't found,
then this will fall back to the Fxc compiler at runtime and log an error.
*/
Dx12Compiler :: enum i32 {
	Undefined = 0x00000000,
	Fxc       = 0x00000001,
	Dxc       = 0x00000002,
}

/*
Selects which OpenGL ES 3 minor version to request.

When using ANGLE as an OpenGL ES/EGL implementation, explicitly requesting `Version1` can provide a non-conformant ES 3.1 on APIs like D3D11.
*/
Gles3MinorVersion :: enum i32 {
	Automatic = 0x00000000,
	Version0  = 0x00000001,
	Version1  = 0x00000002,
	Version2  = 0x00000003,
}

/* Options for creating an instance. */
InstanceDescriptor :: struct {
	backends:             Backends,
	flags:                InstanceFlags,
	features:             InstanceCapabilities,
	dx12_shader_compiler: Dx12Compiler,
	dxil_path:            string,
	dxc_path:             string,
	gles3_minor_version:  Gles3MinorVersion,
}

DEFAULT_INSTANCE_DESCRIPTOR :: InstanceDescriptor {
	backends = BACKENDS_PRIMARY,
}

/*
Reason for "lose the device".

Corresponds to [WebGPU `GPUDeviceLostReason`](https://gpuweb.github.io/gpuweb/#enumdef-gpudevicelostreason).
*/
DeviceLostReason :: enum i32 {
	Unknown         = 0x00000001,
	Destroyed       = 0x00000002,
	InstanceDropped = 0x00000003,
	FailedCreation  = 0x00000004,
}


/*------------------------------------------------------------------
Other typs
--------------------------------------------------------------------*/


SType :: enum i32 {
	// WebGPU
	ShaderSourceSPIRV                = 0x00000001,
	ShaderSourceWGSL                 = 0x00000002,
	RenderPassMaxDrawCount           = 0x00000003,
	SurfaceSourceMetalLayer          = 0x00000004,
	SurfaceSourceWindowsHWND         = 0x00000005,
	SurfaceSourceXlibWindow          = 0x00000006,
	SurfaceSourceWaylandSurface      = 0x00000007,
	SurfaceSourceAndroidNativeWindow = 0x00000008,
	SurfaceSourceXCBWindow           = 0x00000009,

	// Native
	DeviceExtras                     = 0x00030001,
	NativeLimits                     = 0x00030002,
	PipelineLayoutExtras             = 0x00030003,
	ShaderModuleGLSLDescriptor       = 0x00030004,
	InstanceExtras                   = 0x00030006,
	BindGroupEntryExtras             = 0x00030007,
	BindGroupLayoutEntryExtras       = 0x00030008,
	QuerySetDescriptorExtras         = 0x00030009,
	SurfaceConfigurationExtras       = 0x0003000A,
}

ChainedStruct :: struct {
	next:  ^ChainedStruct,
	stype: SType,
}

ChainedStructOut :: struct {
	next:  ^ChainedStructOut,
	stype: SType,
}

NativeQueryType :: enum i32 {
	PipelineStatistics = 0x00030000,
}

@(private)
WGPUNativeLimits :: struct {
	chain:                    ChainedStructOut,
	max_push_constant_size:   u32,
	max_non_sampler_bindings: u32,
}

CallbackMode :: enum i32 {
	WaitAnyOnly        = 0x00000001,
	AllowProcessEvents = 0x00000002,
	AllowSpontaneous   = 0x00000003,
}

CompilationInfoRequestStatus :: enum i32 {
	Success         = 0x00000001,
	InstanceDropped = 0x00000002,
	Error           = 0x00000003,
	Unknown         = 0x00000004,
}

CompilationMessageType :: enum i32 {
	Error   = 0x00000001,
	Warning = 0x00000002,
	Info    = 0x00000003,
}

CreatePipelineAsyncStatus :: enum i32 {
	Success         = 0x00000001,
	InstanceDropped = 0x00000002,
	ValidationError = 0x00000003,
	InternalError   = 0x00000004,
	Unknown         = 0x00000005,
}

ErrorFilter :: enum i32 {
	Validation  = 0x00000001,
	OutOfMemory = 0x00000002,
	Internal    = 0x00000003,
}

ErrorType :: enum i32 {
	NoError     = 0x00000001,
	Validation  = 0x00000002,
	OutOfMemory = 0x00000003,
	Internal    = 0x00000004,
	Unknown     = 0x00000005,
}

FeatureLevel :: enum i32 {
	Compatibility = 0x00000001,
	Core          = 0x00000002,
}

MapAsyncStatus :: enum i32 {
	Success         = 0x00000001,
	InstanceDropped = 0x00000002,
	Error           = 0x00000003,
	Aborted         = 0x00000004,
	Unknown         = 0x00000005,
}

MipmapFilterMode :: enum i32 {
	Undefined = 0x00000000,
	Nearest   = 0x00000001,
	Linear    = 0x00000002,
}

OptionalBool :: enum i32 {
	False     = 0x00000000,
	True      = 0x00000001,
	Undefined = 0x00000002,
}

PopErrorScopeStatus :: enum i32 {
	Success         = 0x00000001,
	InstanceDropped = 0x00000002,
	EmptyStack      = 0x00000003,
}

QueueWorkDoneStatus :: enum i32 {
	Success         = 0x00000001,
	InstanceDropped = 0x00000002,
	Error           = 0x00000003,
	Unknown         = 0x00000004,
}

RequestAdapterStatus :: enum i32 {
	Success         = 0x00000001,
	InstanceDropped = 0x00000002,
	Unavailable     = 0x00000003,
	Error           = 0x00000004,
	Unknown         = 0x00000005,
}

Status :: enum i32 {
	Success = 0x00000001,
	Error   = 0x00000002,
}

WGSLLanguageFeatureName :: enum i32 {
	ReadonlyAndReadwriteStorageTextures = 0x00000001,
	Packed4x8IntegerDotProduct          = 0x00000002,
	UnrestrictedPointerParameters       = 0x00000003,
	PointerCompositeAccess              = 0x00000004,
}

WaitStatus :: enum i32 {
	Success                 = 0x00000001,
	TimedOut                = 0x00000002,
	UnsupportedTimeout      = 0x00000003,
	UnsupportedCount        = 0x00000004,
	UnsupportedMixedSources = 0x00000005,
}

Proc :: #type proc "c" ()

BufferMapCallback :: #type proc "c" (
	status: MapAsyncStatus,
	message: StringView,
	userdata1: rawptr,
	userdata2: rawptr,
)
CompilationInfoCallback :: #type proc "c" (
	status: CompilationInfoRequestStatus,
	compilation_info: ^WGPUCompilationInfo,
	userdata1: rawptr,
	userdata2: rawptr,
)
CreateComputePipelineAsyncCallback :: #type proc "c" (
	status: CreatePipelineAsyncStatus,
	pipeline: ComputePipeline,
	message: StringView,
	userdata1: rawptr,
	userdata2: rawptr,
)
CreateRenderPipelineAsyncCallback :: #type proc "c" (
	status: CreatePipelineAsyncStatus,
	pipeline: RenderPipeline,
	message: StringView,
	userdata1: rawptr,
	userdata2: rawptr,
)
DeviceLostCallback :: #type proc "c" (
	device: ^Device,
	reason: DeviceLostReason,
	message: StringView,
	userdata1: rawptr,
	userdata2: rawptr,
)
PopErrorScopeCallback :: #type proc "c" (
	status: PopErrorScopeStatus,
	type: ErrorType,
	message: StringView,
	userdata1: rawptr,
	userdata2: rawptr,
)
QueueWorkDoneCallback :: #type proc "c" (
	status: QueueWorkDoneStatus,
	userdata1: rawptr,
	userdata2: rawptr,
)
RequestAdapterCallback :: #type proc "c" (
	status: RequestAdapterStatus,
	adapter: Adapter,
	message: StringView,
	userdata1: rawptr,
	userdata2: rawptr,
)
RequestDeviceCallback :: #type proc "c" (
	status: RequestDeviceStatus,
	device: Device,
	message: StringView,
	userdata1: rawptr,
	userdata2: rawptr,
)
UncapturedErrorCallback :: #type proc "c" (
	device: ^Device,
	type: ErrorType,
	message: StringView,
	userdata1: rawptr,
	userdata2: rawptr,
)

BufferMapCallbackInfo :: struct {
	next_in_chain: ^ChainedStruct,
	mode:          CallbackMode,
	callback:      BufferMapCallback,
	userdata1:     rawptr,
	userdata2:     rawptr,
}

CompilationInfoCallbackInfo :: struct {
	next_in_chain: ^ChainedStruct,
	mode:          CallbackMode,
	callback:      CompilationInfoCallback,
	userdata1:     rawptr,
	userdata2:     rawptr,
}

CreateComputePipelineAsyncCallbackInfo :: struct {
	next_in_chain: ^ChainedStruct,
	mode:          CallbackMode,
	callback:      CreateComputePipelineAsyncCallback,
	userdata1:     rawptr,
	userdata2:     rawptr,
}

CreateRenderPipelineAsyncCallbackInfo :: struct {
	next_in_chain: ^ChainedStruct,
	mode:          CallbackMode,
	callback:      CreateRenderPipelineAsyncCallback,
	userdata1:     rawptr,
	userdata2:     rawptr,
}

DeviceLostCallbackInfo :: struct {
	next_in_chain: ^ChainedStruct,
	mode:          CallbackMode,
	callback:      DeviceLostCallback,
	userdata1:     rawptr,
	userdata2:     rawptr,
}

PopErrorScopeCallbackInfo :: struct {
	next_in_chain: ^ChainedStruct,
	mode:          CallbackMode,
	callback:      PopErrorScopeCallback,
	userdata1:     rawptr,
	userdata2:     rawptr,
}

QueueWorkDoneCallbackInfo :: struct {
	next_in_chain: ^ChainedStruct,
	mode:          CallbackMode,
	callback:      QueueWorkDoneCallback,
	userdata1:     rawptr,
	userdata2:     rawptr,
}

RequestAdapterCallbackInfo :: struct {
	next_in_chain: ^ChainedStruct,
	mode:          CallbackMode,
	callback:      RequestAdapterCallback,
	userdata1:     rawptr,
	userdata2:     rawptr,
}

RequestDeviceCallbackInfo :: struct {
	next_in_chain: ^ChainedStruct,
	mode:          CallbackMode,
	callback:      RequestDeviceCallback,
	userdata1:     rawptr,
	userdata2:     rawptr,
}

UncapturedErrorCallbackInfo :: struct {
	next_in_chain: ^ChainedStruct,
	callback:      UncapturedErrorCallback,
	userdata1:     rawptr,
	userdata2:     rawptr,
}

BufferBindingLayout :: struct {
	next_in_chain:      ^ChainedStruct,
	type:               BufferBindingType,
	has_dynamic_offset: b32,
	min_binding_size:   u64,
}

@(private)
WGPUCommandBufferDescriptor :: struct {
	next_in_chain: ^ChainedStruct,
	label:         StringView,
}

@(private)
WGPUCommandEncoderDescriptor :: struct {
	next_in_chain: ^ChainedStruct,
	label:         StringView,
}

CompilationMessage :: struct {
	next_in_chain: ^ChainedStruct,
	message:       StringView,
	type:          CompilationMessageType,
	line_num:      u64,
	line_pos:      u64,
	offset:        u64,
	length:        u64,
}

@(private)
WGPUConstantEntry :: struct {
	next_in_chain: ^ChainedStruct,
	key:           StringView,
	value:         f64,
}

ConstantEntry :: struct {
	key:   string,
	value: f64,
}

Future :: struct {
	id: u64,
}

InstanceCapabilities :: struct {
	next_in_chain:            ^ChainedStructOut,
	timed_wait_any_enable:    b32,
	timed_wait_any_max_count: uint,
}

@(private)
WGPULimits :: struct {
	next_in_chain:                                   ^ChainedStructOut,
	max_texture_dimension_1d:                        u32,
	max_texture_dimension_2d:                        u32,
	max_texture_dimension_3d:                        u32,
	max_texture_array_layers:                        u32,
	max_bind_groups:                                 u32,
	max_bind_groups_plus_vertex_buffers:             u32,
	max_bindings_per_bind_group:                     u32,
	max_dynamic_uniform_buffers_per_pipeline_layout: u32,
	max_dynamic_storage_buffers_per_pipeline_layout: u32,
	max_sampled_textures_per_shader_stage:           u32,
	max_samplers_per_shader_stage:                   u32,
	max_storage_buffers_per_shader_stage:            u32,
	max_storage_textures_per_shader_stage:           u32,
	max_uniform_buffers_per_shader_stage:            u32,
	max_uniform_buffer_binding_size:                 u64,
	max_storage_buffer_binding_size:                 u64,
	min_uniform_buffer_offset_alignment:             u32,
	min_storage_buffer_offset_alignment:             u32,
	max_vertex_buffers:                              u32,
	max_buffer_size:                                 u64,
	max_vertex_attributes:                           u32,
	max_vertex_buffer_array_stride:                  u32,
	max_inter_stage_shader_variables:                u32,
	max_color_attachments:                           u32,
	max_color_attachment_bytes_per_sample:           u32,
	max_compute_workgroup_storage_size:              u32,
	max_compute_invocations_per_workgroup:           u32,
	max_compute_workgroup_size_x:                    u32,
	max_compute_workgroup_size_y:                    u32,
	max_compute_workgroup_size_z:                    u32,
	max_compute_workgroups_per_dimension:            u32,
}

@(private)
WGPUPipelineLayoutDescriptor :: struct {
	next_in_chain:           ^ChainedStruct,
	label:                   StringView,
	bind_group_layout_count: uint,
	bind_group_layouts:      [^]BindGroupLayout,
}

QueueDescriptor :: struct {
	next_in_chain: ^ChainedStruct,
	label:         StringView,
}

@(private)
WGPURenderBundleDescriptor :: struct {
	next_in_chain: ^ChainedStruct,
	label:         StringView,
}

@(private)
WGPURenderBundleEncoderDescriptor :: struct {
	next_in_chain:        ^ChainedStruct,
	label:                StringView,
	color_format_count:   uint,
	color_formats:        ^TextureFormat,
	depth_stencil_format: TextureFormat,
	sample_count:         u32,
	depth_read_only:      b32,
	stencil_read_only:    b32,
}

RenderPassMaxDrawCount :: struct {
	chain:          ChainedStruct,
	max_draw_count: u64,
}

@(private)
WGPURequestAdapterOptions :: struct {
	next_in_chain:          ^ChainedStruct,
	feature_level:          FeatureLevel,
	power_preference:       PowerPreference,
	force_fallback_adapter: b32,
	backend:                Backend,
	compatible_surface:     Surface,
}

SamplerBindingLayout :: struct {
	next_in_chain: ^ChainedStruct,
	type:          SamplerBindingType,
}

@(private)
WGPUSamplerDescriptor :: struct {
	next_in_chain:  ^ChainedStruct,
	label:          StringView,
	address_mode_u: AddressMode,
	address_mode_v: AddressMode,
	address_mode_w: AddressMode,
	mag_filter:     FilterMode,
	min_filter:     FilterMode,
	mipmap_filter:  MipmapFilterMode,
	lod_min_clamp:  f32,
	lod_max_clamp:  f32,
	compare:        CompareFunction,
	max_anisotropy: u16,
}

StorageTextureBindingLayout :: struct {
	next_in_chain:  ^ChainedStruct,
	access:         StorageTextureAccess,
	format:         TextureFormat,
	view_dimension: TextureViewDimension,
}

SupportedWGSLLanguageFeatures :: struct {
	feature_count: uint,
	features:      [^]WGSLLanguageFeatureName,
}

@(private)
WGPUSurfaceCapabilities :: struct {
	next_in_chain:      ^ChainedStructOut,
	usages:             TextureUsages,
	format_count:       uint,
	formats:            [^]TextureFormat,
	present_mode_count: uint,
	present_modes:      [^]PresentMode,
	alpha_mode_count:   uint,
	alpha_modes:        [^]CompositeAlphaMode,
}

@(private)
WGPUSurfaceConfiguration :: struct {
	next_in_chain:     ^ChainedStruct,
	device:            Device,
	format:            TextureFormat,
	usage:             TextureUsages,
	width:             u32,
	height:            u32,
	view_format_count: uint,
	view_formats:      [^]TextureFormat,
	alpha_mode:        CompositeAlphaMode,
	present_mode:      PresentMode,
}

TextureBindingLayout :: struct {
	next_in_chain:  ^ChainedStruct,
	sample_type:    TextureSampleType,
	view_dimension: TextureViewDimension,
	multisampled:   b32,
}

@(private)
WGPUTextureViewDescriptor :: struct {
	next_in_chain:     ^ChainedStruct,
	label:             StringView,
	format:            TextureFormat,
	dimension:         TextureViewDimension,
	base_mip_level:    u32,
	mip_level_count:   u32,
	base_array_layer:  u32,
	array_layer_count: u32,
	aspect:            TextureAspect,
	usage:             TextureUsages,
}

@(private)
WGPUBindGroupDescriptor :: struct {
	next_in_chain: ^ChainedStruct,
	label:         StringView,
	layout:        BindGroupLayout,
	entry_count:   uint,
	entries:       [^]WGPUBindGroupEntry,
}

@(private)
WGPUBindGroupLayoutEntry :: struct {
	next_in_chain:   ^ChainedStruct,
	binding:         u32,
	visibility:      ShaderStages,
	buffer:          BufferBindingLayout,
	sampler:         SamplerBindingLayout,
	texture:         TextureBindingLayout,
	storage_texture: StorageTextureBindingLayout,
}

@(private)
WGPUComputePassDescriptor :: struct {
	next_in_chain:    ^ChainedStruct,
	label:            StringView,
	timestamp_writes: ^ComputePassTimestampWrites,
}

@(private)
WGPUDepthStencilState :: struct {
	next_in_chain:          ^ChainedStruct,
	format:                 TextureFormat,
	depth_write_enabled:    OptionalBool,
	depth_compare:          CompareFunction,
	stencil_front:          StencilFaceState,
	stencil_back:           StencilFaceState,
	stencil_read_mask:      u32,
	stencil_write_mask:     u32,
	depth_bias:             i32,
	depth_bias_slope_scale: f32,
	depth_bias_clamp:       f32,
}

FutureWaitInfo :: struct {
	future:    Future,
	completed: b32,
}

@(private)
WGPUProgrammableStageDescriptor :: struct {
	next_in_chain:  ^ChainedStruct,
	module:         ShaderModule,
	entry_point:    StringView,
	constant_count: uint,
	constants:      [^]WGPUConstantEntry,
}

@(private)
WGPUVertexBufferLayout :: struct {
	step_mode:       VertexStepMode,
	array_stride:    u64,
	attribute_count: uint,
	attributes:      [^]VertexAttribute,
}

@(private)
WGPUBindGroupLayoutDescriptor :: struct {
	next_in_chain: ^ChainedStruct,
	label:         StringView,
	entry_count:   uint,
	entries:       [^]WGPUBindGroupLayoutEntry,
}

@(private)
WGPUComputePipelineDescriptor :: struct {
	next_in_chain: ^ChainedStruct,
	label:         StringView,
	layout:        PipelineLayout,
	compute:       WGPUProgrammableStageDescriptor,
}

@(private)
WGPURenderPassDescriptor :: struct {
	next_in_chain:            ^ChainedStruct,
	label:                    StringView,
	color_attachment_count:   uint,
	color_attachments:        [^]WGPURenderPassColorAttachment,
	depth_stencil_attachment: ^RenderPassDepthStencilAttachment,
	occlusion_query_set:      QuerySet,
	timestamp_writes:         ^RenderPassTimestampWrites,
}

@(private)
WGPUVertexState :: struct {
	next_in_chain:  ^ChainedStruct,
	module:         ShaderModule,
	entry_point:    StringView,
	constant_count: uint,
	constants:      [^]WGPUConstantEntry,
	buffer_count:   uint,
	buffers:        [^]WGPUVertexBufferLayout,
}

@(private)
WGPUFragmentState :: struct {
	next_in_chain:  ^ChainedStruct,
	module:         ShaderModule,
	entry_point:    StringView,
	constant_count: uint,
	constants:      [^]WGPUConstantEntry,
	target_count:   uint,
	targets:        [^]ColorTargetState,
}

@(private)
WGPURenderPipelineDescriptor :: struct {
	next_in_chain: ^ChainedStruct,
	label:         StringView,
	layout:        PipelineLayout,
	vertex:        WGPUVertexState,
	primitive:     WGPUPrimitiveState,
	depth_stencil: ^WGPUDepthStencilState,
	multisample:   MultisampleState,
	fragment:      ^WGPUFragmentState,
}
