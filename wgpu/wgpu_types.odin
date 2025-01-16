package wgpu

// Packages
import intr "base:intrinsics"
import "base:runtime"

/* Integral type used for buffer offsets.*/
Buffer_Address :: u64
/* Integral type used for buffer slice sizes.*/
Buffer_Size :: u64
/* Integral type used for buffer slice sizes.*/
Shader_Location :: u32
/* Integral type used for dynamic bind group offsets.*/
Dynamic_Offset :: u32

/*
Buffer-Texture copies must have `bytes_per_row` aligned to this number.

This doesn’t apply to `queue_write_texture`.
*/
COPY_BYTES_PER_ROW_ALIGNMENT: u32 : 256
/* An offset into the query resolve buffer has to be aligned to self.*/
QUERY_RESOLVE_BUFFER_ALIGNMENT: Buffer_Address : 256
/* Buffer to buffer copy, buffer clear offsets and sizes must be aligned to this number.*/
COPY_BUFFER_ALIGNMENT: Buffer_Address : 4
/* Buffer alignment mask to calculate proper size.*/
COPY_BUFFER_ALIGNMENT_MASK :: COPY_BUFFER_ALIGNMENT - 1
/* Size to align mappings.*/
MAP_ALIGNMENT: Buffer_Address : 8
/* Vertex buffer strides have to be aligned to this number.*/
VERTEX_STRIDE_ALIGNMENT: Buffer_Address : 4
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
Power_Preference :: enum i32 {
	Undefined        = 0x00000000,
	Low_Power        = 0x00000001,
	High_Performance = 0x00000002,
}

/* High_Performance. */
DEFAULT_POWER_PREFERENCE: Power_Preference = .High_Performance

Backend_Bits :: enum u64 {
	Vulkan,
	GL,
	Metal,
	DX12,
	DX11,
	Browser_WebGPU,
}

/* Represents the backends that wgpu will use.*/
Backends :: distinct bit_set[Backend_Bits;u64]

/* All the apis that wgpu supports.*/
BACKENDS_ALL :: Backends{}

/* All the apis that wgpu offers first tier of support for.*/
BACKENDS_PRIMARY :: Backends{.Vulkan, .Metal, .DX12, .Browser_WebGPU}

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
Request_Adapter_Options :: struct {
	feature_level:          Feature_Level,
	compatible_surface:     Surface,
	power_preference:       Power_Preference,
	backend:                Backend,
	force_fallback_adapter: bool,
}

Instance_Flag :: enum u64 {
	Debug,
	Validation,
	Discard_Hal_Labels,
}

/*
Instance debugging flags.

These are not part of the webgpu standard.
*/
Instance_Flags :: distinct bit_set[Instance_Flag;u64]

INSTANCE_FLAGS_DEFAULT :: Instance_Flags{}

/* Enable recommended debugging and validation flags.*/
INSTANCE_FLAGS_DEBUGGING :: Instance_Flags{.Debug, .Validation}

/* Supported physical device types.*/
Device_Type :: enum i32 {
	Discrete_GPU   = 0x00000001,
	Integrated_GPU = 0x00000002,
	CPU            = 0x00000003,
	Unknown        = 0x00000004,
}

/* Information about an adapter.*/
Adapter_Info :: struct {
	vendor:       string,
	architecture: string,
	device:       string,
	description:  string,
	backend:      Backend,
	device_type:  Device_Type,
	vendor_id:    u32,
	device_id:    u32,
}

/*  */
Shader_Stage :: enum Flags {
	Vertex,
	Fragment,
	Compute,
}

/*
Describes the shader stages that a binding will be visible from.

These can be combined so something that is visible from both vertex and fragment shaders can be
defined as:

`Shader_Stages{.Vertex, .Fragment}`

Corresponds to [WebGPU `GPUShaderStageFlags`](
https://gpuweb.github.io/gpuweb/#typedefdef-gpushaderstageflags).
*/
Shader_Stages :: distinct bit_set[Shader_Stage;Flags]

/* Binding is not visible from any shader stage.*/
SHADER_STAGE_NONE :: Shader_Stages{}

/* Binding is visible from the vertex and fragment shaders of a render pipeline.*/
SHADER_STAGE_VERTEX_FRAGMENT :: Shader_Stages{.Vertex, .Fragment}

/* Order in which texture data is laid out in memory.*/
Texture_Data_Order :: enum {
	Layer_Major,
	Mip_Major,
}

/*
Dimensions of a particular texture view.

Corresponds to [WebGPU `GPUTextureViewDimension`](
https://gpuweb.github.io/gpuweb/#enumdef-gputextureviewdimension).
*/
Texture_View_Dimension :: enum i32 {
	Undefined  = 0x00000000,
	D1         = 0x00000001,
	D2         = 0x00000002,
	D2_Array   = 0x00000003,
	Cube       = 0x00000004,
	Cube_Array = 0x00000005,
	D3         = 0x00000006,
}

/*
Alpha blend factor.

Corresponds to [WebGPU `GPUBlendFactor`](
https://gpuweb.github.io/gpuweb/#enumdef-gpublendfactor).

For further details on how the blend factors are applied, see the analogous
functionality in OpenGL: <https://www.khronos.org/opengl/wiki/Blending#Blending_Parameters>.
*/
Blend_Factor :: enum i32 {
	Undefined            = 0x00000000,
	Zero                 = 0x00000001,
	One                  = 0x00000002,
	Src                  = 0x00000003,
	One_Minus_Src        = 0x00000004,
	Src_Alpha            = 0x00000005,
	One_Minus_Src_Alpha  = 0x00000006,
	Dst                  = 0x00000007,
	One_Minus_Dst        = 0x00000008,
	Dst_Alpha            = 0x00000009,
	One_Minus_Dst_Alpha  = 0x0000000A,
	Src_Alpha_Saturated  = 0x0000000B,
	Constant             = 0x0000000C,
	One_Minus_Constant   = 0x0000000D,
	Src1                 = 0x0000000E,
	One_Minus_Src1       = 0x0000000F,
	Src1_Alpha           = 0x00000010,
	One_Minus_Src1_Alpha = 0x00000011,
}

/*
Alpha blend operation.

Corresponds to [WebGPU `GPUBlendOperation`](
https://gpuweb.github.io/gpuweb/#enumdef-gpublendoperation).

For further details on how the blend operations are applied, see
the analogous functionality in OpenGL:
<https://www.khronos.org/opengl/wiki/Blending#Blend_Equations>.
*/
Blend_Operation :: enum i32 {
	Undefined        = 0x00000000,
	Add              = 0x00000001,
	Subtract         = 0x00000002,
	Reverse_Subtract = 0x00000003,
	Min              = 0x00000004,
	Max              = 0x00000005,
}

/*
Describes a blend component of a [`Blend_State`].

Corresponds to [WebGPU `GPUBlendComponent`](
https://gpuweb.github.io/gpuweb/#dictdef-gpublendcomponent).
*/
Blend_Component :: struct {
	operation:  Blend_Operation,
	src_factor: Blend_Factor,
	dst_factor: Blend_Factor,
}

/* Standard blending state that blends source and destination based on source alpha.*/
BLEND_COMPONENT_NORMAL :: Blend_Component {
	operation  = .Add,
	src_factor = .Src_Alpha,
	dst_factor = .One_Minus_Src_Alpha,
}

// Default blending state that replaces destination with the source.
BLEND_COMPONENT_REPLACE :: Blend_Component {
	operation  = .Add,
	src_factor = .One,
	dst_factor = .Zero,
}

// Blend state of (1 * src) + ((1 - src_alpha) * dst)
BLEND_COMPONENT_OVER :: Blend_Component {
	operation  = .Add,
	src_factor = .One,
	dst_factor = .One_Minus_Src_Alpha,
}

/*  */
DEFAULT_BLEND_COMPONENT :: BLEND_COMPONENT_REPLACE

/*
Returns `true` if the state relies on the constant color, which is
set independently on a render command encoder.
*/
blend_component_uses_constant :: proc "contextless" (self: Blend_Component) -> bool {
	return(
		self.src_factor == .Constant ||
		self.src_factor == .One_Minus_Constant ||
		self.dst_factor == .Constant ||
		self.dst_factor == .One_Minus_Constant \
	)
}

/*
Describe the blend state of a render pipeline,
within `Color_Target_State`.

Corresponds to [WebGPU `GPUBlendState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpublendstate).
*/
Blend_State :: struct {
	color: Blend_Component,
	alpha: Blend_Component,
}

/* Uses alpha blending for both color and alpha channels.*/
@(rodata)
BLEND_STATE_NORMAL := Blend_State {
	color = BLEND_COMPONENT_NORMAL,
	alpha = BLEND_COMPONENT_NORMAL,
}

/* Does no color blending, just overwrites the output with the contents of the shader.*/
@(rodata)
BLEND_STATE_REPLACE := Blend_State {
	color = BLEND_COMPONENT_REPLACE,
	alpha = BLEND_COMPONENT_REPLACE,
}

/* Does standard alpha blending with non-premultiplied alpha.*/
@(rodata)
BLEND_STATE_ALPHA_BLENDING := Blend_State {
	color = BLEND_COMPONENT_NORMAL,
	alpha = BLEND_COMPONENT_OVER,
}

/* Does standard alpha blending with premultiplied alpha.*/
@(rodata)
BLEND_STATE_PREMULTIPLIED_ALPHA_BLENDING := Blend_State {
	color = BLEND_COMPONENT_OVER,
	alpha = BLEND_COMPONENT_OVER,
}

/*
Describes the color state of a render pipeline.

Corresponds to [WebGPU `GPUColorTargetState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpucolortargetstate).
*/
Color_Target_State :: struct {
	next_in_chain: ^Chained_Struct,
	format:        Texture_Format,
	blend:         ^Blend_State,
	write_mask:    Color_Writes,
}

color_target_state_from_texture_format :: proc(format: Texture_Format) -> Color_Target_State {
	return {format = format, blend = nil, write_mask = COLOR_WRITES_ALL}
}

/*
Primitive type the input mesh is composed of.

Corresponds to [WebGPU `GPUPrimitiveTopology`](
https://gpuweb.github.io/gpuweb/#enumdef-gpuprimitivetopology).
*/
Primitive_Topology :: enum {
	Triangle_List, // Default here, not in wgpu
	Point_List,
	Line_List,
	Line_Strip,
	Triangle_Strip,
}

primitive_topology_is_strip :: proc "contextless" (self: Primitive_Topology) -> bool {
	#partial switch self {
	case .Triangle_Strip, .Line_Strip:
		return true
	}
	return false
}

/*
Vertex winding order which classifies the "front" face of a triangle.

Corresponds to [WebGPU `GPUFrontFace`](
https://gpuweb.github.io/gpuweb/#enumdef-gpufrontface).
*/
Front_Face :: enum i32 {
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
Primitive_State :: struct {
	topology:           Primitive_Topology,
	strip_index_format: Index_Format,
	front_face:         Front_Face,
	cull_mode:          Face,
	unclipped_depth:    bool,
}

DEFAULT_PRIMITIVE_STATE :: Primitive_State {
	topology   = .Triangle_List,
	front_face = .CCW,
	cull_mode  = .None,
}

/*
Describes the multi-sampling state of a render pipeline.

Corresponds to [WebGPU `GPUMultisampleState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpumultisamplestate).
*/
Multisample_State :: struct {
	next_in_chain:             ^Chained_Struct,
	count:                     u32,
	mask:                      u32,
	alpha_to_coverage_enabled: bool,
}

/* Default `count = 1` and mask all pixels `0xFFFFFFFF`.*/
DEFAULT_MULTISAMPLE_STATE :: Multisample_State {
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

Color_Write :: enum Flags {
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
Color_Writes :: distinct bit_set[Color_Write;Flags]

/*  */
COLOR_WRITES_NONE :: Color_Writes{}

/* Enable red, green, and blue channel writes. */
COLOR_WRITES_COLOR :: Color_Writes{.Red, .Green, .Blue}

/* Enable writes to all channels. */
COLOR_WRITES_ALL :: Color_Writes{.Red, .Green, .Blue, .Alpha}

/*  */
DEFAULT_COLOR_WRITES :: COLOR_WRITES_ALL

/*
State of the stencil operation (fixed-pipeline stage).

For use in `Depth_Stencil_State`.

Corresponds to a portion of [WebGPU `GPUDepthStencilState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpudepthstencilstate).
*/
Stencil_State :: struct {
	front:      Stencil_Face_State,
	back:       Stencil_Face_State,
	read_mask:  u32,
	write_mask: u32,
}

/* Returns true if the stencil test is enabled. */
stencil_state_is_enabled :: proc "contextless" (self: Stencil_State) -> bool {
	return(
		(self.front != STENCIL_FACE_STATE_IGNORE || self.back != STENCIL_FACE_STATE_IGNORE) &&
		(self.read_mask != 0 || self.write_mask != 0) \
	)
}

/* Returns `true` if the state doesn't mutate the target values. */
stencil_state_is_read_only :: proc "contextless" (self: Stencil_State, cull_mode: Face) -> bool {
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
stencil_state_needs_ref_value :: proc "contextless" (self: Stencil_State) -> bool {
	return(
		stencil_face_state_needs_ref_value(self.front) ||
		stencil_face_state_needs_ref_value(self.back) \
	)
}

/*
Describes the biasing setting for the depth target.

For use in `Depth_Stencil_State`.

Corresponds to a portion of [WebGPU `GPUDepthStencilState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpudepthstencilstate).
*/
Depth_Bias_State :: struct {
	constant:    i32,
	slope_scale: f32,
	clamp:       f32,
}

/* Returns true if the depth biasing is enabled. */
depth_bias_state_is_enabled :: proc "contextless" (self: Depth_Bias_State) -> bool {
	return self.constant != 0 || self.slope_scale != 0.0
}

/*
Describes the depth/stencil state in a render pipeline.

Corresponds to [WebGPU `GPUDepthStencilState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpudepthstencilstate).
*/
Depth_Stencil_State :: struct {
	format:              Texture_Format,
	depth_write_enabled: bool,
	depth_compare:       Compare_Function,
	stencil:             Stencil_State,
	bias:                Depth_Bias_State,
}

/* Returns `true` if the depth testing is enabled. */
depth_stencil_state_is_depth_enabled :: proc "contextless" (self: Depth_Stencil_State) -> bool {
	return(
		(self.depth_compare != .Undefined && self.depth_compare != .Always) ||
		self.depth_write_enabled \
	)
}

/* Returns `true` if the state doesn't mutate the depth buffer. */
depth_stencil_state_is_depth_read_only :: proc "contextless" (self: Depth_Stencil_State) -> bool {
	return !self.depth_write_enabled
}

/* Returns true if the state doesn't mutate the stencil. */
depth_stencil_state_is_stencil_read_only :: proc "contextless" (
	self: Depth_Stencil_State,
	cull_mode: Face,
) -> bool {
	return stencil_state_is_read_only(self.stencil, cull_mode)
}

/* Returns true if the state doesn't mutate either depth or stencil of the target. */
depth_stencil_state_is_read_only :: proc "contextless" (
	self: Depth_Stencil_State,
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
Index_Format :: enum i32 {
	Undefined = 0x00000000,
	Uint16    = 0x00000001,
	Uint32    = 0x00000002,
}

/*
Operation to perform on the stencil value.

Corresponds to [WebGPU `GPUStencilOperation`](
https://gpuweb.github.io/gpuweb/#enumdef-gpustenciloperation).
*/
Stencil_Operation :: enum i32 {
	Undefined       = 0x00000000,
	Keep            = 0x00000001,
	Zero            = 0x00000002,
	Replace         = 0x00000003,
	Invert          = 0x00000004,
	Increment_Clamp = 0x00000005,
	Decrement_Clamp = 0x00000006,
	Increment_Wrap  = 0x00000007,
	Decrement_Wrap  = 0x00000008,
}

/*
Describes stencil state in a render pipeline.

If you are not using stencil state, set this to `STENCIL_FACE_STATE_IGNORE`.

Corresponds to [WebGPU `GPUStencilFaceState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpustencilfacestate).
*/
Stencil_Face_State :: struct {
	compare:       Compare_Function,
	fail_op:       Stencil_Operation,
	depth_fail_op: Stencil_Operation,
	pass_op:       Stencil_Operation,
}

/* Ignore the stencil state for the face. */
STENCIL_FACE_STATE_IGNORE :: Stencil_Face_State {
	compare       = .Always,
	fail_op       = .Keep,
	depth_fail_op = .Keep,
	pass_op       = .Keep,
}

/* Returns true if the face state uses the reference value for testing or operation. */
stencil_face_state_needs_ref_value :: proc "contextless" (self: Stencil_Face_State) -> bool {
	return(
		compare_function_needs_ref_value(self.compare) ||
		self.fail_op == .Replace ||
		self.depth_fail_op == .Replace ||
		self.pass_op == .Replace \
	)
}

/* Returns true if the face state doesn't mutate the target values. */
stencil_face_state_is_read_only :: proc "contextless" (self: Stencil_Face_State) -> bool {
	return self.pass_op == .Keep && self.depth_fail_op == .Keep && self.fail_op == .Keep
}

/*
Comparison function used for depth and stencil operations.

Corresponds to [WebGPU `GPUCompareFunction`](
https://gpuweb.github.io/gpuweb/#enumdef-gpucomparefunction).
*/
Compare_Function :: enum i32 {
	Undefined     = 0x00000000,
	Never         = 0x00000001,
	Less          = 0x00000002,
	Equal         = 0x00000003,
	Less_Equal    = 0x00000004,
	Greater       = 0x00000005,
	Not_Equal     = 0x00000006,
	Greater_Equal = 0x00000007,
	Always        = 0x00000008,
}

/* Returns `true` if the comparison depends on the reference value. */
compare_function_needs_ref_value :: proc "contextless" (self: Compare_Function) -> bool {
	return self == .Never || self == .Always
}

/*
Whether a vertex buffer is indexed by vertex or by instance.

Corresponds to [WebGPU `GPUVertexStepMode`](
https://gpuweb.github.io/gpuweb/#enumdef-gpuvertexstepmode).
*/
Vertex_Step_Mode :: enum i32 {
	Vertex_Buffer_Not_Used = 0x00000000,
	Undefined              = 0x00000001,
	Vertex                 = 0x00000002,
	Instance               = 0x00000003,
}

/*
Vertex inputs (attributes) to shaders.

Arrays of these can be made with the `vertex_attr_array`
macro. Vertex attributes are assumed to be tightly packed.

Corresponds to [WebGPU `GPUVertexAttribute`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuvertexattribute).
*/
Vertex_Attribute :: struct {
	format:          Vertex_Format,
	offset:          u64,
	shader_location: u32,
}

/*
Vertex Format for a `Vertex_Attribute` (input).

Corresponds to [WebGPU `GPUVertexFormat`](
https://gpuweb.github.io/gpuweb/#enumdef-gpuvertexformat).
*/
Vertex_Format :: enum i32 {
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
	Unorm8x4_Bgra   = 0x00000029,
}

vertex_format_size :: proc "contextless" (self: Vertex_Format) -> u64 {
	// odinfmt: disable
	switch self {
	case .Uint8, .Sint8, .Unorm8, .Snorm8: return 1
	case .Uint8x2, .Sint8x2, .Unorm8x2, .Snorm8x2, .Uint16, .Sint16, .Unorm16, .Snorm16, .Float16:
		return 2
	case .Uint8x4, .Sint8x4, .Unorm8x4, .Snorm8x4, .Uint16x2, .Sint16x2, .Unorm16x2, .Snorm16x2,
		 .Float16x2, .Float32, .Uint32, .Sint32, .Unorm10_10_10_2, .Unorm8x4_Bgra: return 4
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

Buffer_Usage :: enum Flags {
	Map_Read,
	Map_Write,
	Copy_Src,
	Copy_Dst,
	Index,
	Vertex,
	Uniform,
	Storage,
	Indirect,
	Query_Resolve,
}

/*
Different ways that you can use a buffer.

The usages determine what kind of memory the buffer is allocated from and what
actions the buffer can partake in.

Corresponds to [WebGPU `GPUBufferUsageFlags`](
https://gpuweb.github.io/gpuweb/#typedefdef-gpubufferusageflags).
*/
Buffer_Usages :: distinct bit_set[Buffer_Usage;Flags]

BUFFER_USAGE_NONE :: Buffer_Usages{}

/*
Describes a `Command_Encoder`

Corresponds to [WebGPU `GPUCommandEncoderDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpucommandencoderdescriptor).
*/
Command_Encoder_Descriptor :: struct {
	label: string,
}

/* Behavior of the presentation engine based on frame rate. */
Present_Mode :: enum i32 {
	Undefined    = 0x00000000,
	Fifo         = 0x00000001,
	Fifo_Relaxed = 0x00000002,
	Immediate    = 0x00000003,
	Mailbox      = 0x00000004,
}

/* Specifies how the alpha channel of the textures should be handled during compositing. */
Composite_Alpha_Mode :: enum i32 {
	Auto            = 0x00000000,
	Opaque          = 0x00000001,
	Premultiplied   = 0x00000002,
	Unpremultiplied = 0x00000003,
	Inherit         = 0x00000004,
}

Texture_Usage :: enum Flags {
	Copy_Src,
	Copy_Dst,
	Texture_Binding,
	Storage_Binding,
	Render_Attachment,
}

/*
Different ways that you can use a texture.

The usages determine what kind of memory the texture is allocated from and what
actions the texture can partake in.

Corresponds to [WebGPU `GPUTextureUsageFlags`](
https://gpuweb.github.io/gpuweb/#typedefdef-gputextureusageflags).
*/
Texture_Usages :: distinct bit_set[Texture_Usage;Flags]

TEXTURE_USAGES_NONE :: Texture_Usages{}

TEXTURE_USAGES_ALL :: Texture_Usages {
	.Copy_Src,
	.Copy_Dst,
	.Texture_Binding,
	.Storage_Binding,
	.Render_Attachment,
}

/* The capabilities of a given surface and adapter. */
Surface_Capabilities :: struct {
	allocator:     runtime.Allocator,
	formats:       []Texture_Format,
	present_modes: []Present_Mode,
	alpha_modes:   []Composite_Alpha_Mode,
	usages:        Texture_Usages,
}

surface_capabilities_free_members :: proc(self: Surface_Capabilities) {
	context.allocator = self.allocator
	delete(self.formats)
	delete(self.present_modes)
	delete(self.alpha_modes)
}

/* Status of the received surface image. */
Surface_Status :: enum i32 {
	Success_Optimal    = 0x00000001,
	Success_Suboptimal = 0x00000002,
	Timeout            = 0x00000003,
	Outdated           = 0x00000004,
	Lost               = 0x00000005,
	Out_Of_Memory      = 0x00000006,
	Device_Lost        = 0x00000007,
	Error              = 0x00000008,
}

@(private)
WGPU_Color :: struct {
	r: f64,
	g: f64,
	b: f64,
	a: f64,
}

/* RGBA double precision color. */
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
Texture_Dimension :: enum i32 {
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
Origin_2D :: struct {
	x: u32,
	y: u32,
}

/* Adds the third dimension to this origin. */
origin_2d_to_3d :: proc "contextless" (self: Origin_2D) -> Origin_3D {
	return {x = self.x, y = self.y, z = 0}
}

/*
Origin of a copy to/from a texture.

Corresponds to [WebGPU `GPUOrigin3D`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuorigin3ddict).
*/
Origin_3D :: struct {
	x: u32,
	y: u32,
	z: u32,
}

origin_3d_to_2d :: proc "contextless" (self: Origin_3D) -> Origin_2D {
	return {x = self.x, y = self.y}
}

/*
Extent of a texture related operation.

Corresponds to [WebGPU `GPUExtent3D`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuextent3ddict).
*/
Extent_3D :: struct {
	width:                 u32,
	height:                u32,
	depth_or_array_layers: u32,
}

DEFAULT_EXTENT_3D :: Extent_3D{1, 1, 1}
DEFAULT_DEPTH :: 1

/*
Calculates the [physical size] backing a texture of the given  format and extent.  This
includes padding to the block width and height of the format.

This is the texture extent that you must upload at when uploading to _mipmaps_ of compressed
textures.

[physical size]: https://gpuweb.github.io/gpuweb/#physical-miplevel-specific-texture-extent
*/
extent_3d_physical_size :: proc "contextless" (
	self: Extent_3D,
	format: Texture_Format,
) -> (
	extent: Extent_3D,
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
	self: Extent_3D,
	dimension: Texture_Dimension,
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
	self: Extent_3D,
	level: u32,
	dimension: Texture_Dimension,
) -> (
	extent: Extent_3D,
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
Describes a `Texture_View`.

For use with `texture_create_view`.

Corresponds to [WebGPU `GPUTextureViewDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gputextureviewdescriptor).
*/
Texture_View_Descriptor :: struct {
	label:             string,
	format:            Texture_Format,
	dimension:         Texture_View_Dimension,
	base_mip_level:    u32,
	mip_level_count:   u32,
	base_array_layer:  u32,
	array_layer_count: u32,
	aspect:            Texture_Aspect,
	usage:             Texture_Usages,
}

/*
Calculates the extent at a given mip level.

If the given mip level is larger than possible, returns None.

Treats the depth as part of the mipmaps. If calculating
for a 2DArray texture, which does not mipmap depth, set depth to 1.
*/
texture_descriptor_mip_level_size :: proc "contextless" (
	self: Texture_Descriptor,
	level: u32,
) -> (
	extent: Extent_3D,
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
	self: Texture_Descriptor,
	mip_level: u32,
) -> Extent_3D {
	return Extent_3D {
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
	self: Texture_Descriptor,
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

/* Returns `true` if the given `Texture_Descriptor` is compatible with cube textures. */
texture_descriptor_is_cube_compatible :: proc "contextless" (self: Texture_Descriptor) -> bool {
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
Texture_Aspect :: enum i32 {
	Undefined    = 0x00000000,
	All          = 0x00000001,
	Stencil_Only = 0x00000002,
	Depth_Only   = 0x00000003,
	Plane0       = 0x00000004,
	Plane1       = 0x00000005,
	Plane2       = 0x00000006,
}

/*
How edges should be handled in texture addressing.

Corresponds to [WebGPU `GPUAddressMode`](
https://gpuweb.github.io/gpuweb/#enumdef-gpuaddressmode).
*/
Address_Mode :: enum i32 {
	Undefined     = 0x00000000,
	Clamp_To_Edge = 0x00000001,
	Repeat        = 0x00000002,
	Mirror_Repeat = 0x00000003,
}

/*
Texel mixing mode when sampling between texels.

Corresponds to [WebGPU `GPUFilterMode`](
https://gpuweb.github.io/gpuweb/#enumdef-gpufiltermode).
*/
Filter_Mode :: enum i32 {
	Undefined = 0x00000000,
	Nearest   = 0x00000001,
	Linear    = 0x00000002,
}

/* A range of push constant memory to pass to a shader stage. */
Push_Constant_Range :: struct {
	stages: Shader_Stages,
	range:  Range(u32),
}

/*
Describes a `Command_Buffer`.

Corresponds to [WebGPU `GPUCommandBufferDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpucommandbufferdescriptor).
*/
Command_Buffer_Descriptor :: struct {
	label: string,
}

/*
Layout of a texture in a buffer's memory.

Corresponds to [WebGPU `GPUTexelCopyBufferLayout`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuimagedatalayout).
*/
Texel_Copy_Buffer_Layout :: struct {
	offset:         u64,
	bytes_per_row:  u32,
	rows_per_image: u32,
}

/*
Specific type of a buffer binding.

Corresponds to [WebGPU `GPUBufferBindingType`](
https://gpuweb.github.io/gpuweb/#enumdef-gpubufferbindingtype).
*/
Buffer_Binding_Type :: enum i32 {
	Binding_Not_Used  = 0x00000000,
	Undefined         = 0x00000001,
	Uniform           = 0x00000002,
	Storage           = 0x00000003,
	Read_Only_Storage = 0x00000004,
}

/*
Specific type of a sample in a texture binding.

Corresponds to [WebGPU `GPUTextureSampleType`](
https://gpuweb.github.io/gpuweb/#enumdef-gputexturesampletype).
*/
Texture_Sample_Type :: enum i32 {
	Binding_Not_Used   = 0x00000000,
	Undefined          = 0x00000001,
	Float              = 0x00000002,
	Unfilterable_Float = 0x00000003,
	Depth              = 0x00000004,
	Sint               = 0x00000005,
	Uint               = 0x00000006,
}

DEFAULT_TEXTURE_SAMPLE_TYPE :: Texture_Sample_Type.Float

/*
Specific type of a sample in a texture binding.

For use in [`Binding_Type.StorageTexture`].

Corresponds to [WebGPU `GPUStorageTextureAccess`](
https://gpuweb.github.io/gpuweb/#enumdef-gpustoragetextureaccess).
*/
Storage_Texture_Access :: enum i32 {
	Binding_Not_Used = 0x00000000,
	Undefined        = 0x00000001,
	Write_Only       = 0x00000002,
	Read_Only        = 0x00000003,
	Read_Write       = 0x00000004,
}

/*
Specific type of a sampler binding.

For use in `Binding_Type.Sampler`.

Corresponds to [WebGPU `GPUSamplerBindingType`](
https://gpuweb.github.io/gpuweb/#enumdef-gpusamplerbindingtype).
*/
Sampler_Binding_Type :: enum i32 {
	Binding_Not_Used = 0x00000000,
	Undefined        = 0x00000001,
	Filtering        = 0x00000002,
	Non_Filtering    = 0x00000003,
	Comparison       = 0x00000004,
}

/*
Specific type of a binding.

For use in `Bind_Group_Layout_Entry`.

Corresponds to WebGPU's mutually exclusive fields within [`GPUBindGroupLayoutEntry`](
https://gpuweb.github.io/gpuweb/#dictdef-gpubindgrouplayoutentry).
*/
Binding_Type :: union {
	Buffer_Binding_Layout,
	Sampler_Binding_Layout,
	Texture_Binding_Layout,
	Storage_Texture_Binding_Layout,
}

/*
Describes a single binding inside a bind group.

Corresponds to [WebGPU `GPUBindGroupLayoutEntry`](
https://gpuweb.github.io/gpuweb/#dictdef-gpubindgrouplayoutentry).
*/
Bind_Group_Layout_Entry :: struct {
	binding:    u32,
	visibility: Shader_Stages,
	type:       Binding_Type,
	count:      u32,
}

/* Subresource range within an image. */
Image_Subresource_Range :: struct {
	aspect:            Texture_Aspect,
	base_mip_level:    u32,
	mip_level_count:   u32,
	base_array_layer:  u32,
	array_layer_count: u32,
}

/* Color variation to use when sampler addressing mode is `Address_Mode.ClampToBorder`. */
Sampler_Border_Color :: enum i32 {
	Transparent_Black,
	Opaque_Black,
	Opaque_White,
	Zero,
}

/*
Selects which DX12 shader compiler to fuse.

If the `Dxc` option is selected, but `dxcompiler.dll` and `dxil.dll` files aren't found,
then this will fall back to the Fxc compiler at runtime and log an error.
*/
Dx12_Compiler :: enum i32 {
	Undefined = 0x00000000,
	Fxc       = 0x00000001,
	Dxc       = 0x00000002,
}

/*
Selects which OpenGL ES 3 minor version to request.

When using ANGLE as an OpenGL ES/EGL implementation, explicitly requesting `Version1` can provide a non-conformant ES 3.1 on APIs like D3D11.
*/
Gles3_Minor_Version :: enum i32 {
	Automatic = 0x00000000,
	Version0  = 0x00000001,
	Version1  = 0x00000002,
	Version2  = 0x00000003,
}

/* Options for creating an instance. */
Instance_Descriptor :: struct {
	backends:             Backends,
	flags:                Instance_Flags,
	features:             Instance_Capabilities,
	dx12_shader_compiler: Dx12_Compiler,
	dxil_path:            string,
	dxc_path:             string,
	gles3_minor_version:  Gles3_Minor_Version,
}

DEFAULT_INSTANCE_DESCRIPTOR :: Instance_Descriptor {
	backends = BACKENDS_PRIMARY,
}

/*
Reason for "lose the device".

Corresponds to [WebGPU `GPUDeviceLostReason`](https://gpuweb.github.io/gpuweb/#enumdef-gpudevicelostreason).
*/
Device_Lost_Reason :: enum i32 {
	Unknown          = 0x00000001,
	Destroyed        = 0x00000002,
	Instance_Dropped = 0x00000003,
	Failed_Creation  = 0x00000004,
}

/*------------------------------------------------------------------
Other typs
--------------------------------------------------------------------*/


SType :: enum i32 {
	// WebGPU
	Shader_Source_SPIRV                  = 0x00000001,
	Shader_Source_WGSL                   = 0x00000002,
	Render_Pass_Max_Draw_Count           = 0x00000003,
	Surface_Source_Metal_Layer           = 0x00000004,
	Surface_Source_Windows_HWND          = 0x00000005,
	Surface_Source_Xlib_Window           = 0x00000006,
	Surface_Source_Wayland_Surface       = 0x00000007,
	Surface_Source_Android_Native_Window = 0x00000008,
	Surface_Source_XBC_Window            = 0x00000009,

	// Native
	Device_Extras                        = 0x00030001,
	Native_Limits                        = 0x00030002,
	Pipeline_Layout_Extras               = 0x00030003,
	Shader_Module_GLSL_Descriptor        = 0x00030004,
	Instance_Extras                      = 0x00030006,
	Bind_Group_Entry_Extras              = 0x00030007,
	Bind_Group_Layout_Entry_Extras       = 0x00030008,
	Query_Set_Descriptor_Extras          = 0x00030009,
	Surface_Configuration_Extras         = 0x0003000A,
}

Chained_Struct :: struct {
	next:  ^Chained_Struct,
	stype: SType,
}

Chained_Struct_Out :: struct {
	next:  ^Chained_Struct_Out,
	stype: SType,
}

Native_Query_Type :: enum i32 {
	Pipeline_Statistics = 0x00030000,
}

@(private)
WGPU_Native_Limits :: struct {
	chain:                    Chained_Struct_Out,
	max_push_constant_size:   u32,
	max_non_sampler_bindings: u32,
}

Callback_Mode :: enum i32 {
	Wait_Any_Only        = 0x00000001,
	Allow_Process_Events = 0x00000002,
	Allow_Spontaneous    = 0x00000003,
}

Compilation_Info_Request_Status :: enum i32 {
	Success          = 0x00000001,
	Instance_Dropped = 0x00000002,
	Error            = 0x00000003,
	Unknown          = 0x00000004,
}

Compilation_Message_Type :: enum i32 {
	Error   = 0x00000001,
	Warning = 0x00000002,
	Info    = 0x00000003,
}

Create_Pipeline_Async_Status :: enum i32 {
	Success          = 0x00000001,
	Instance_Dropped = 0x00000002,
	Validation_Error = 0x00000003,
	Internal_Error   = 0x00000004,
	Unknown          = 0x00000005,
}

Error_Filter :: enum i32 {
	Validation    = 0x00000001,
	Out_Of_Memory = 0x00000002,
	Internal      = 0x00000003,
}

Error_Type :: enum i32 {
	NoError       = 0x00000001,
	Validation    = 0x00000002,
	Out_Of_Memory = 0x00000003,
	Internal      = 0x00000004,
	Unknown       = 0x00000005,
}

Feature_Level :: enum i32 {
	Compatibility = 0x00000001,
	Core          = 0x00000002,
}

Map_Async_Status :: enum i32 {
	Success          = 0x00000001,
	Instance_Dropped = 0x00000002,
	Error            = 0x00000003,
	Aborted          = 0x00000004,
	Unknown          = 0x00000005,
}

Mipmap_Filter_Mode :: enum i32 {
	Undefined = 0x00000000,
	Nearest   = 0x00000001,
	Linear    = 0x00000002,
}

Optional_Bool :: enum i32 {
	False     = 0x00000000,
	True      = 0x00000001,
	Undefined = 0x00000002,
}

Pop_Error_Scope_Status :: enum i32 {
	Success          = 0x00000001,
	Instance_Dropped = 0x00000002,
	EmptyStack       = 0x00000003,
}

Queue_Work_Done_Status :: enum i32 {
	Success          = 0x00000001,
	Instance_Dropped = 0x00000002,
	Error            = 0x00000003,
	Unknown          = 0x00000004,
}

Request_Adapter_Status :: enum i32 {
	Success          = 0x00000001,
	Instance_Dropped = 0x00000002,
	Unavailable      = 0x00000003,
	Error            = 0x00000004,
	Unknown          = 0x00000005,
}

Status :: enum i32 {
	Success = 0x00000001,
	Error   = 0x00000002,
}

WGSL_Language_Feature_Name :: enum i32 {
	Readonly_And_Readwrite_Storage_Textures = 0x00000001,
	Packed4x8_Integer_Dot_Product           = 0x00000002,
	Unrestricted_Pointer_Parameters         = 0x00000003,
	Pointer_Composite_Access                = 0x00000004,
}

Wait_Status :: enum i32 {
	Success                   = 0x00000001,
	TimedOut                  = 0x00000002,
	Unsupported_Timeout       = 0x00000003,
	Unsupported_Count         = 0x00000004,
	Unsupported_Mixed_Sources = 0x00000005,
}

Proc :: #type proc "c" ()

Buffer_Map_Callback :: #type proc "c" (
	status: Map_Async_Status,
	message: String_View,
	userdata1: rawptr,
	userdata2: rawptr,
)

Compilation_Info_Callback :: #type proc "c" (
	status: Compilation_Info_Request_Status,
	compilation_info: ^WGPU_Compilation_Info,
	userdata1: rawptr,
	userdata2: rawptr,
)

Create_Compute_Pipeline_Async_Callback :: #type proc "c" (
	status: Create_Pipeline_Async_Status,
	pipeline: Compute_Pipeline,
	message: String_View,
	userdata1: rawptr,
	userdata2: rawptr,
)

Create_Render_Pipeline_Async_Callback :: #type proc "c" (
	status: Create_Pipeline_Async_Status,
	pipeline: Render_Pipeline,
	message: String_View,
	userdata1: rawptr,
	userdata2: rawptr,
)

Device_Lost_Callback :: #type proc "c" (
	device: ^Device,
	reason: Device_Lost_Reason,
	message: String_View,
	userdata1: rawptr,
	userdata2: rawptr,
)

Pop_Error_Scope_Callback :: #type proc "c" (
	status: Pop_Error_Scope_Status,
	type: Error_Type,
	message: String_View,
	userdata1: rawptr,
	userdata2: rawptr,
)

Queue_Work_Done_Callback :: #type proc "c" (
	status: Queue_Work_Done_Status,
	userdata1: rawptr,
	userdata2: rawptr,
)

Request_Adapter_Callback :: #type proc "c" (
	status: Request_Adapter_Status,
	adapter: Adapter,
	message: String_View,
	userdata1: rawptr,
	userdata2: rawptr,
)

Request_Device_Callback :: #type proc "c" (
	status: Request_Device_Status,
	device: Device,
	message: String_View,
	userdata1: rawptr,
	userdata2: rawptr,
)

Uncaptured_Error_Callback :: #type proc "c" (
	device: ^Device,
	type: Error_Type,
	message: String_View,
	userdata1: rawptr,
	userdata2: rawptr,
)

Buffer_Map_Callback_Info :: struct {
	next_in_chain: ^Chained_Struct,
	mode:          Callback_Mode,
	callback:      Buffer_Map_Callback,
	userdata1:     rawptr,
	userdata2:     rawptr,
}

Compilation_Info_Callback_Info :: struct {
	next_in_chain: ^Chained_Struct,
	mode:          Callback_Mode,
	callback:      Compilation_Info_Callback,
	userdata1:     rawptr,
	userdata2:     rawptr,
}

Create_Compute_Pipeline_Async_Callback_Info :: struct {
	next_in_chain: ^Chained_Struct,
	mode:          Callback_Mode,
	callback:      Create_Compute_Pipeline_Async_Callback,
	userdata1:     rawptr,
	userdata2:     rawptr,
}

Create_Render_Pipeline_Async_Callback_Info :: struct {
	next_in_chain: ^Chained_Struct,
	mode:          Callback_Mode,
	callback:      Create_Render_Pipeline_Async_Callback,
	userdata1:     rawptr,
	userdata2:     rawptr,
}

Device_Lost_Callback_Info :: struct {
	next_in_chain: ^Chained_Struct,
	mode:          Callback_Mode,
	callback:      Device_Lost_Callback,
	userdata1:     rawptr,
	userdata2:     rawptr,
}

Pop_Error_Scope_Callback_Info :: struct {
	next_in_chain: ^Chained_Struct,
	mode:          Callback_Mode,
	callback:      Pop_Error_Scope_Callback,
	userdata1:     rawptr,
	userdata2:     rawptr,
}

Queue_Work_Done_Callback_Info :: struct {
	next_in_chain: ^Chained_Struct,
	mode:          Callback_Mode,
	callback:      Queue_Work_Done_Callback,
	userdata1:     rawptr,
	userdata2:     rawptr,
}

Request_Adapter_Callback_Info :: struct {
	next_in_chain: ^Chained_Struct,
	mode:          Callback_Mode,
	callback:      Request_Adapter_Callback,
	userdata1:     rawptr,
	userdata2:     rawptr,
}

Request_Device_Callback_Info :: struct {
	next_in_chain: ^Chained_Struct,
	mode:          Callback_Mode,
	callback:      Request_Device_Callback,
	userdata1:     rawptr,
	userdata2:     rawptr,
}

Uncaptured_Error_Callback_Info :: struct {
	next_in_chain: ^Chained_Struct,
	callback:      Uncaptured_Error_Callback,
	userdata1:     rawptr,
	userdata2:     rawptr,
}

Buffer_Binding_Layout :: struct {
	next_in_chain:      ^Chained_Struct,
	type:               Buffer_Binding_Type,
	has_dynamic_offset: b32,
	min_binding_size:   u64,
}

@(private)
WGPU_Command_Buffer_Descriptor :: struct {
	next_in_chain: ^Chained_Struct,
	label:         String_View,
}

@(private)
WGPU_Command_Encoder_Descriptor :: struct {
	next_in_chain: ^Chained_Struct,
	label:         String_View,
}

Compilation_Message :: struct {
	next_in_chain: ^Chained_Struct,
	message:       String_View,
	type:          Compilation_Message_Type,
	line_num:      u64,
	line_pos:      u64,
	offset:        u64,
	length:        u64,
}

@(private)
WGPU_Constant_Entry :: struct {
	next_in_chain: ^Chained_Struct,
	key:           String_View,
	value:         f64,
}

Constant_Entry :: struct {
	key:   string,
	value: f64,
}

Future :: struct {
	id: u64,
}

Instance_Capabilities :: struct {
	next_in_chain:            ^Chained_Struct_Out,
	timed_wait_any_enable:    b32,
	timed_wait_any_max_count: uint,
}

@(private)
WGPU_Limits :: struct {
	next_in_chain:                                   ^Chained_Struct_Out,
	max_texture_dimension_1d:                        u32,
	max_texture_dimension_2d:                        u32,
	max_texture_dimension_3d:                        u32,
	max_texture_array_layers:                        u32,
	max_bind_groups:                                 u32,
	max_bind_groups_plus_vertex_buffers:             u32, // TODO: not used
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
	max_inter_stage_shader_variables:                u32, // TODO: not used
	max_color_attachments:                           u32, // TODO: not used
	max_color_attachment_bytes_per_sample:           u32, // TODO: not used
	max_compute_workgroup_storage_size:              u32,
	max_compute_invocations_per_workgroup:           u32,
	max_compute_workgroup_size_x:                    u32,
	max_compute_workgroup_size_y:                    u32,
	max_compute_workgroup_size_z:                    u32,
	max_compute_workgroups_per_dimension:            u32,
}

@(private)
WGPU_Pipeline_Layout_Descriptor :: struct {
	next_in_chain:           ^Chained_Struct,
	label:                   String_View,
	bind_group_layout_count: uint,
	bind_group_layouts:      [^]Bind_Group_Layout,
}

Queue_Descriptor :: struct {
	next_in_chain: ^Chained_Struct,
	label:         String_View,
}

@(private)
WGPU_Render_Bundle_Descriptor :: struct {
	next_in_chain: ^Chained_Struct,
	label:         String_View,
}

@(private)
WGPU_Render_Bundle_Encoder_Descriptor :: struct {
	next_in_chain:        ^Chained_Struct,
	label:                String_View,
	color_format_count:   uint,
	color_formats:        ^Texture_Format,
	depth_stencil_format: Texture_Format,
	sample_count:         u32,
	depth_read_only:      b32,
	stencil_read_only:    b32,
}

Render_Pass_Max_Draw_Count :: struct {
	chain:          Chained_Struct,
	max_draw_count: u64,
}

@(private)
WGPU_Request_Adapter_Options :: struct {
	next_in_chain:          ^Chained_Struct,
	feature_level:          Feature_Level,
	power_preference:       Power_Preference,
	force_fallback_adapter: b32,
	backend:                Backend,
	compatible_surface:     Surface,
}

Sampler_Binding_Layout :: struct {
	next_in_chain: ^Chained_Struct,
	type:          Sampler_Binding_Type,
}

@(private)
WGPU_Sampler_Descriptor :: struct {
	next_in_chain:  ^Chained_Struct,
	label:          String_View,
	address_mode_u: Address_Mode,
	address_mode_v: Address_Mode,
	address_mode_w: Address_Mode,
	mag_filter:     Filter_Mode,
	min_filter:     Filter_Mode,
	mipmap_filter:  Mipmap_Filter_Mode,
	lod_min_clamp:  f32,
	lod_max_clamp:  f32,
	compare:        Compare_Function,
	max_anisotropy: u16,
}

Storage_Texture_Binding_Layout :: struct {
	next_in_chain:  ^Chained_Struct,
	access:         Storage_Texture_Access,
	format:         Texture_Format,
	view_dimension: Texture_View_Dimension,
}

Supported_WGSL_Language_Features :: struct {
	feature_count: uint,
	features:      [^]WGSL_Language_Feature_Name,
}

@(private)
WGPU_Surface_Capabilities :: struct {
	next_in_chain:      ^Chained_Struct_Out,
	usages:             Texture_Usages,
	format_count:       uint,
	formats:            [^]Texture_Format,
	present_mode_count: uint,
	present_modes:      [^]Present_Mode,
	alpha_mode_count:   uint,
	alpha_modes:        [^]Composite_Alpha_Mode,
}

@(private)
WGPU_Surface_Configuration :: struct {
	next_in_chain:     ^Chained_Struct,
	device:            Device,
	format:            Texture_Format,
	usage:             Texture_Usages,
	width:             u32,
	height:            u32,
	view_format_count: uint,
	view_formats:      [^]Texture_Format,
	alpha_mode:        Composite_Alpha_Mode,
	present_mode:      Present_Mode,
}

Texture_Binding_Layout :: struct {
	next_in_chain:  ^Chained_Struct,
	sample_type:    Texture_Sample_Type,
	view_dimension: Texture_View_Dimension,
	multisampled:   b32,
}

@(private)
WGPU_Texture_View_Descriptor :: struct {
	next_in_chain:     ^Chained_Struct,
	label:             String_View,
	format:            Texture_Format,
	dimension:         Texture_View_Dimension,
	base_mip_level:    u32,
	mip_level_count:   u32,
	base_array_layer:  u32,
	array_layer_count: u32,
	aspect:            Texture_Aspect,
	usage:             Texture_Usages,
}

@(private)
WGPU_Bind_Group_Descriptor :: struct {
	next_in_chain: ^Chained_Struct,
	label:         String_View,
	layout:        Bind_Group_Layout,
	entry_count:   uint,
	entries:       [^]WGPU_Bind_Group_Entry,
}

@(private)
WGPU_Bind_Group_Layout_Entry :: struct {
	next_in_chain:   ^Chained_Struct,
	binding:         u32,
	visibility:      Shader_Stages,
	buffer:          Buffer_Binding_Layout,
	sampler:         Sampler_Binding_Layout,
	texture:         Texture_Binding_Layout,
	storage_texture: Storage_Texture_Binding_Layout,
}

@(private)
WGPU_Compute_Pass_Descriptor :: struct {
	next_in_chain:    ^Chained_Struct,
	label:            String_View,
	timestamp_writes: ^Compute_Pass_Timestamp_Writes,
}

@(private)
WGPU_Depth_Stencil_State :: struct {
	next_in_chain:          ^Chained_Struct,
	format:                 Texture_Format,
	depth_write_enabled:    Optional_Bool,
	depth_compare:          Compare_Function,
	stencil_front:          Stencil_Face_State,
	stencil_back:           Stencil_Face_State,
	stencil_read_mask:      u32,
	stencil_write_mask:     u32,
	depth_bias:             i32,
	depth_bias_slope_scale: f32,
	depth_bias_clamp:       f32,
}

Future_Wait_Info :: struct {
	future:    Future,
	completed: b32,
}

@(private)
WGPU_Programmable_Stage_Descriptor :: struct {
	next_in_chain:  ^Chained_Struct,
	module:         Shader_Module,
	entry_point:    String_View,
	constant_count: uint,
	constants:      [^]WGPU_Constant_Entry,
}

@(private)
WGPU_Vertex_Buffer_Layout :: struct {
	step_mode:       Vertex_Step_Mode,
	array_stride:    u64,
	attribute_count: uint,
	attributes:      [^]Vertex_Attribute,
}

@(private)
WGPU_Bind_Group_Layout_Descriptor :: struct {
	next_in_chain: ^Chained_Struct,
	label:         String_View,
	entry_count:   uint,
	entries:       [^]WGPU_Bind_Group_Layout_Entry,
}

@(private)
WGPU_Compute_Pipeline_Descriptor :: struct {
	next_in_chain: ^Chained_Struct,
	label:         String_View,
	layout:        Pipeline_Layout,
	compute:       WGPU_Programmable_Stage_Descriptor,
}

@(private)
WGPU_Render_Pass_Descriptor :: struct {
	next_in_chain:            ^Chained_Struct,
	label:                    String_View,
	color_attachment_count:   uint,
	color_attachments:        [^]WGPU_Render_Pass_Color_Attachment,
	depth_stencil_attachment: ^Render_Pass_Depth_Stencil_Attachment,
	occlusion_query_set:      Query_Set,
	timestamp_writes:         ^Render_Pass_Timestamp_Writes,
}

@(private)
WGPU_Vertex_State :: struct {
	next_in_chain:  ^Chained_Struct,
	module:         Shader_Module,
	entry_point:    String_View,
	constant_count: uint,
	constants:      [^]WGPU_Constant_Entry,
	buffer_count:   uint,
	buffers:        [^]WGPU_Vertex_Buffer_Layout,
}

@(private)
WGPU_Fragment_State :: struct {
	next_in_chain:  ^Chained_Struct,
	module:         Shader_Module,
	entry_point:    String_View,
	constant_count: uint,
	constants:      [^]WGPU_Constant_Entry,
	target_count:   uint,
	targets:        [^]Color_Target_State,
}

@(private)
WGPU_Render_Pipeline_Descriptor :: struct {
	next_in_chain: ^Chained_Struct,
	label:         String_View,
	layout:        Pipeline_Layout,
	vertex:        WGPU_Vertex_State,
	primitive:     WGPU_Primitive_State,
	depth_stencil: ^WGPU_Depth_Stencil_State,
	multisample:   Multisample_State,
	fragment:      ^WGPU_Fragment_State,
}
