package wgpu_bindings

@(private) WGPU_SHARED :: #config(WGPU_SHARED, true)
@(private) WGPU_USE_SYSTEM_LIBRARIES :: #config(WGPU_USE_SYSTEM_LIBRARIES, false)

when ODIN_OS == .Windows {
	when ODIN_ARCH == .amd64 do ARCH :: "x86_64"
	else when ODIN_ARCH == .i386 do ARCH :: "i386"
	else do #panic("Unsupported WGPU Native architecture")

	@(private) EXT  :: ".dll.lib" when WGPU_SHARED else ".lib"
	@(private) LIB  :: "lib/windows/" + ARCH + "/wgpu_native" + EXT

	when !#exists(LIB) {
		#panic("Could not find the compiled WGPU Native library at '" + #directory + LIB + "'")
	}

	when WGPU_SHARED {
		foreign import wgpu_native {LIB}
	} else {
		foreign import wgpu_native {
			LIB,
			"system:gdi32.lib",
			"system:dxgi.lib",
			"system:d3dcompiler.lib",
			"system:opengl32.lib",
			"system:user32.lib",
			"system:dwmapi.lib",
			"system:bcrypt.lib",
			"system:ws2_32.lib",
			"system:userenv.lib",
			"system:dbghelp.lib",
			"system:advapi32.lib",
			"system:ntdll.lib",
		}
	}
} else when ODIN_OS == .Darwin {
	when WGPU_USE_SYSTEM_LIBRARIES {
		foreign import wgpu_native "system:wgpu_native"
	} else {
		when ODIN_ARCH == .amd64 do ARCH :: "x86_64"
		else when ODIN_ARCH == .arm64 do ARCH :: "aarch64"
		else do #panic("Unsupported WGPU Native architecture")

		@(private) LIB  :: "lib/mac_os/" + ARCH + "/libwgpu_native.a"

		when !#exists(LIB) {
			#panic("Could not find the compiled WGPU Native library at '" + #directory + LIB + "'")
		}

		foreign import wgpu_native {LIB}
	}
} else when ODIN_OS == .Linux {
	when WGPU_USE_SYSTEM_LIBRARIES {
		foreign import wgpu_native "system:wgpu_native"
	} else {
		when ODIN_ARCH == .amd64 do ARCH :: "x86_64"
		else when ODIN_ARCH == .arm64 do ARCH :: "aarch64"
		else do #panic("Unsupported WGPU Native architecture")

		@(private) LIB  :: "lib/linux/" + ARCH + "/libwgpu_native.a"

		when !#exists(LIB) {
			#panic("Could not find the compiled WGPU Native library at '" + #directory + LIB + "'")
		}

		foreign import wgpu_native {LIB}
	}
} else {
	foreign import wgpu_native "system:wgpu_native"
}

ARRAY_LAYER_COUNT_UNDEFINED :: max(u32)
COPY_STRIDE_UNDEFINED       :: max(u32)
DEPTH_SLICE_UNDEFINED       :: max(u32)
LIMIT_U32_UNDEFINED         :: max(u32)
LIMIT_U64_UNDEFINED         :: max(u64)
MIP_LEVEL_COUNT_UNDEFINED   :: max(u32)
QUERY_SET_INDEX_UNDEFINED   :: max(u32)
WHOLE_MAP_SIZE              :: max(uint)
WHOLE_SIZE                  :: max(u64)

FLAGS     :: u32
ENUM_SIZE :: i32

Adapter :: distinct rawptr
Bind_Group :: distinct rawptr
Bind_Group_Layout :: distinct rawptr
Buffer :: distinct rawptr
Command_Buffer :: distinct rawptr
Command_Encoder :: distinct rawptr
Compute_Pass_Encoder :: distinct rawptr
Compute_Pipeline :: distinct rawptr
Device :: distinct rawptr
Instance :: distinct rawptr
Pipeline_Layout :: distinct rawptr
Query_Set :: distinct rawptr
Queue :: distinct rawptr
Render_Bundle :: distinct rawptr
Render_Bundle_Encoder :: distinct rawptr
Render_Pass_Encoder :: distinct rawptr
Render_Pipeline :: distinct rawptr
Sampler :: distinct rawptr
Shader_Module :: distinct rawptr
Surface :: distinct rawptr
Texture :: distinct rawptr
Texture_View :: distinct rawptr

Adapter_Type :: enum ENUM_SIZE {
	Discrete_GPU,
	Integrated_GPU,
	CPU,
	Unknown,
}

Address_Mode :: enum ENUM_SIZE {
	Repeat,
	Mirror_Repeat,
	Clamp_To_Edge,
}

Backend_Type :: enum ENUM_SIZE {
	Undefined,
	Null,
	WebGPU,
	D3D11,
	D3D12,
	Metal,
	Vulkan,
	OpenGL,
	OpenGLES,
}

Blend_Factor :: enum ENUM_SIZE {
	Zero,
	One,
	Src,
	One_Minus_Src,
	Src_Alpha,
	One_Minus_Src_Alpha,
	Dst,
	One_Minus_Dst,
	Dst_Alpha,
	One_Minus_Dst_Alpha,
	Src_Alpha_Saturated,
	Constant,
	One_Minus_Constant,
}

Blend_Operation :: enum ENUM_SIZE {
	Add,
	Subtract,
	Reverse_Subtract,
	Min,
	Max,
}

Buffer_Binding_Type :: enum ENUM_SIZE {
	Undefined,
	Uniform,
	Storage,
	Read_Only_Storage,
}

Buffer_Map_Async_Status :: enum ENUM_SIZE {
	Success,
	Validation_Error,
	Error,
	Unknown,
	DeviceLost,
	Destroyed_Before_Callback,
	Unmapped_Before_Callback,
	Mapping_Already_Pending,
	Offset_Out_Of_Range,
	Size_Out_Of_Range,
}

Buffer_Map_State :: enum ENUM_SIZE {
	Unmapped,
	Pending,
	Mapped,
}

Compare_Function :: enum ENUM_SIZE {
	Undefined,
	Never,
	Less,
	Less_Equal,
	Greater,
	Greater_Equal,
	Equal,
	Not_Equal,
	Always,
}

Compilation_Info_Request_Status :: enum ENUM_SIZE {
	Success,
	Error,
	Device_Lost,
	Unknown,
}

Compilation_Message_Type :: enum ENUM_SIZE {
	Error,
	Warning,
	Info,
}

Composite_Alpha_Mode :: enum ENUM_SIZE {
	Auto,
	Opaque,
	Premultiplied,
	Unpremultiplied,
	Inherit,
}

Create_Pipeline_Async_Status :: enum ENUM_SIZE {
	Success,
	Validation_Error,
	Internal_Error,
	Device_Lost,
	Device_Destroyed,
	Unknown,
}

Cull_Mode :: enum ENUM_SIZE {
	None,
	Front,
	Back,
}

Device_Lost_Reason :: enum ENUM_SIZE {
	Unknown   = 0x00000001,
	Destroyed = 0x00000002,
}

Error_Filter :: enum ENUM_SIZE {
	Validation,
	Out_Of_Memory,
	Internal,
}

Error_Type :: enum ENUM_SIZE {
	No_Error,
	Validation,
	Out_Of_Memory,
	Internal,
	Unknown,
	Device_Lost,
}

Feature_Name :: enum ENUM_SIZE {
	// WebGPU
	Undefined                  = 0x00000000,
	Depth_Clip_Control         = 0x00000001,
	Depth32_Float_Stencil8     = 0x00000002,
	Timestamp_Query            = 0x00000003,
	Texture_Compression_Bc     = 0x00000004,
	Texture_Compression_Etc2   = 0x00000005,
	Texture_Compression_Astc   = 0x00000006,
	Indirect_First_Instance    = 0x00000007,
	Shader_F16                 = 0x00000008,
	Rg11_B10_Ufloat_Renderable = 0x00000009,
	Bgra8_Unorm_Storage        = 0x0000000A,
	Float32_Filterable         = 0x0000000B,

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
	Texture_Compression_Astc_Hdr                                  = 0x0003000C,
	Mappable_Primary_Buffers                                      = 0x0003000E,
	Buffer_Binding_Array                                          = 0x0003000F,
	Uniform_Buffer_And_Storage_Texture_Array_Non_Uniform_Indexing = 0x00030010,
	Vertex_Attribute64bit                                         = 0x00030019,
	Texture_Format_NV12                                           = 0x0003001A,
	Ray_Tracing_Acceleration_Structure                            = 0x0003001B,
	Ray_Query                                                     = 0x0003001C,
	Shader_F64                                                    = 0x0003001D,
	Shader_I16                                                    = 0x0003001E,
	Shader_Primitive_Index                                        = 0x0003001F,
	Shader_Early_Depth_Test                                       = 0x00030020,
}

Filter_Mode :: enum ENUM_SIZE {
	Nearest,
	Linear,
}

Front_Face :: enum ENUM_SIZE {
	CCW,
	CW,
}

Index_Format :: enum ENUM_SIZE {
	Undefined,
	Uint16,
	Uint32,
}

Load_Op :: enum ENUM_SIZE {
	Undefined,
	Clear,
	Load,
}

Mipmap_Filter_Mode :: enum ENUM_SIZE {
	Nearest,
	Linear,
}

Power_Preference :: enum ENUM_SIZE {
	Undefined,
	Low_Power,
	High_Performance,
}

Present_Mode :: enum ENUM_SIZE {
	Fifo,
	Fifo_Relaxed,
	Immediate,
	Mailbox,
}

Primitive_Topology :: enum ENUM_SIZE {
	Point_List,
	Line_List,
	Line_Strip,
	Triangle_List,
	Triangle_Strip,
}

Query_Type :: enum ENUM_SIZE {
	Occlusion,
	Timestamp,
}

Queue_Work_Done_Status :: enum ENUM_SIZE {
	Success,
	Error,
	Unknown,
	Device_Lost,
}

Request_Adapter_Status :: enum ENUM_SIZE {
	Success,
	Unavailable,
	Error,
	Unknown,
}

Request_Device_Status :: enum ENUM_SIZE {
	Success,
	Error,
	Unknown,
}

SType :: enum ENUM_SIZE {
	Invalid,
	Surface_Descriptor_From_Metal_Layer,
	Surface_Descriptor_From_Windows_HWND,
	Surface_Descriptor_From_Xlib_Window,
	Surface_Descriptor_From_Canvas_Html_Selector,
	Shader_Module_SPIRV_Descriptor,
	Shader_Module_WGSL_Descriptor,
	Primitive_Depth_Clip_Control,
	Surface_Descriptor_From_Wayland_Surface,
	Surface_Descriptor_From_Android_Native_Window,
	Surface_Descriptor_From_Xcb_Window,
	Render_Pass_Descriptor_Max_Draw_Count,
}

Sampler_Binding_Type :: enum ENUM_SIZE {
	Undefined,
	Filtering,
	Non_Filtering,
	Comparison,
}

Stencil_Operation :: enum ENUM_SIZE {
	Keep,
	Zero,
	Replace,
	Invert,
	Increment_Clamp,
	Decrement_Clamp,
	Increment_Wrap,
	Decrement_Wrap,
}

Storage_Texture_Access :: enum ENUM_SIZE {
	Undefined,
	Write_Only,
	Read_Only,
	Read_Write,
}

Store_Op :: enum ENUM_SIZE {
	Undefined,
	Store,
	Discard,
}

Surface_Get_Current_Texture_Status :: enum ENUM_SIZE {
	Success,
	Timeout,
	Outdated,
	Lost,
	Out_Of_Memory,
	Device_Lost,
}

Texture_Aspect :: enum ENUM_SIZE {
	All,
	Stencil_Only,
	Depth_Only,
}

Texture_Component_Type :: enum ENUM_SIZE {
	Float,
	Sint,
	Uint,
	Depth_Comparison,
}

Texture_Dimension :: enum ENUM_SIZE {
	D1,
	D2,
	D3,
}

Texture_Format :: enum ENUM_SIZE {
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
	Rgb10_A2_Uint           = 0x00000019,
	Rgb10_A2_Unorm          = 0x0000001A,
	Rg11_B10_Ufloat         = 0x0000001B,
	Rgb9_E5_Ufloat          = 0x0000001C,
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
	Bc6_Hrgb_Ufloat         = 0x00000036,
	Bc6_Hrgb_Float          = 0x00000037,
	Bc7_Rgba_Unorm          = 0x00000038,
	Bc7_Rgba_Unorm_Srgb     = 0x00000039,
	Etc2_Rgb8_Unorm         = 0x0000003A,
	Etc2_Rgb8_Unorm_Srgb    = 0x0000003B,
	Etc2_Rgb8_A1_Unorm      = 0x0000003C,
	Etc2_Rgb8_A1_Unorm_Srgb = 0x0000003D,
	Etc2_Rgba8_Unorm        = 0x0000003E,
	Etc2_Rgba8_Unorm_Srgb   = 0x0000003F,
	Eacr11_Unorm            = 0x00000040,
	Eacr11_Snorm            = 0x00000041,
	Eacrg11_Unorm           = 0x00000042,
	Eacrg11_Snorm           = 0x00000043,
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
	// From Features::TEXTURE_FORMAT_16BIT_NORM
	R16_Unorm               = 0x00030001,
	R16_Snorm               = 0x00030002,
	Rg16_Unorm              = 0x00030003,
	Rg16_Snorm              = 0x00030004,
	Rgba16_Unorm            = 0x00030005,
	Rgba16_Snorm            = 0x00030006,
	// From Features::TEXTURE_FORMAT_NV12
	NV12                    = 0x00030007,
}

Texture_Sample_Type :: enum ENUM_SIZE {
	Undefined,
	Float,
	Unfilterable_Float,
	Depth,
	Sint,
	Uint,
}

Texture_View_Dimension :: enum ENUM_SIZE {
	Undefined,
	D1,
	D2,
	D2Array,
	Cube,
	CubeArray,
	D3,
}

Vertex_Format :: enum ENUM_SIZE {
	Undefined,
	Uint8x2,
	Uint8x4,
	Sint8x2,
	Sint8x4,
	Unorm8x2,
	Unorm8x4,
	Snorm8x2,
	Snorm8x4,
	Uint16x2,
	Uint16x4,
	Sint16x2,
	Sint16x4,
	Unorm16x2,
	Unorm16x4,
	Snorm16x2,
	Snorm16x4,
	Float16x2,
	Float16x4,
	Float32,
	Float32x2,
	Float32x3,
	Float32x4,
	Uint32,
	Uint32x2,
	Uint32x3,
	Uint32x4,
	Sint32,
	Sint32x2,
	Sint32x3,
	Sint32x4,
}

Vertex_Step_Mode :: enum ENUM_SIZE {
	Vertex,
	Instance,
	Vertex_Buffer_Not_Used,
}

WGSL_Feature_Name :: enum ENUM_SIZE {
	Undefined                               = 0x00000000,
	Readonly_And_Readwrite_Storage_Textures = 0x00000001,
	Packed4x8_Integer_Dot_Product           = 0x00000002,
	Unrestricted_Pointer_Parameters         = 0x00000003,
	Pointer_Composite_Access                = 0x00000004,
}

Buffer_Usage :: enum ENUM_SIZE {
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
Buffer_Usage_Flags :: bit_set[Buffer_Usage;FLAGS]
Buffer_Usage_Flags_None :: Buffer_Usage_Flags{}

Color_Write_Mask :: enum ENUM_SIZE {
	Red,
	Green,
	Blue,
	Alpha,
}
Color_Write_Mask_Flags :: bit_set[Color_Write_Mask;FLAGS]
Color_Write_Mask_None :: Color_Write_Mask_Flags{}
Color_Write_Mask_All :: Color_Write_Mask_Flags{.Red, .Green, .Blue, .Alpha}

Map_Mode :: enum ENUM_SIZE {
	Read,
	Write,
}
Map_Mode_Flags :: bit_set[Map_Mode;FLAGS]

Shader_Stage :: enum ENUM_SIZE {
	Vertex,
	Fragment,
	Compute,
}
Shader_Stage_Flags :: bit_set[Shader_Stage;FLAGS]
Shader_Stage_Flags_None :: Shader_Stage_Flags{}

Texture_Usage :: enum ENUM_SIZE {
	Copy_Src,
	Copy_Dst,
	Texture_Binding,
	Storage_Binding,
	Render_Attachment,
}
Texture_Usage_Flags :: bit_set[Texture_Usage;FLAGS]
Texture_Usage_Flags_None :: Texture_Usage_Flags{}
Texture_Usage_Flags_All :: Texture_Usage_Flags {
	.Copy_Src,
	.Copy_Dst,
	.Texture_Binding,
	.Storage_Binding,
	.Render_Attachment,
}

Proc :: #type proc "c" ()

Device_Lost_Callback :: #type proc "c" (
	reason: Device_Lost_Reason,
	message: cstring,
	user_data: rawptr,
)

Error_Callback :: #type proc "c" (type: Error_Type, message: cstring, user_data: rawptr)

Adapter_Request_Device_Callback :: #type proc "c" (
	status: Request_Device_Status,
	device: Device,
	message: cstring,
	user_data: rawptr,
)

Buffer_Map_Async_Callback :: #type proc "c" (status: Buffer_Map_Async_Status, user_data: rawptr)

Device_Create_Compute_Pipeline_Async_Callback :: #type proc "c" (
	status: Create_Pipeline_Async_Status,
	pipeline: Compute_Pipeline,
	message: cstring,
	user_data: rawptr,
)

Device_Create_Render_Pipeline_Async_Callback :: #type proc "c" (
	status: Create_Pipeline_Async_Status,
	pipeline: Render_Pipeline,
	message: cstring,
	user_data: rawptr,
)

Instance_Request_Adapter_Callback :: #type proc "c" (
	status: Request_Adapter_Status,
	adapter: Adapter,
	message: cstring,
	user_data: rawptr,
)

Queue_On_Submitted_Work_Done_Callback :: #type proc "c" (
	status: Queue_Work_Done_Status,
	user_data: rawptr,
)

Shader_Module_Get_Compilation_Info_Callback :: #type proc "c" (
	status: Compilation_Info_Request_Status,
	compilation_info: ^Compilation_Info,
	user_data: rawptr,
)

Chained_Struct :: struct {
	next:  ^Chained_Struct,
	stype: SType,
}

Chained_Struct_Out :: struct {
	next:  ^Chained_Struct_Out,
	stype: SType,
}

Adapter_Info :: struct {
	next_in_chain : ^Chained_Struct_Out `fmt:"-"`,
	vendor        : cstring,
	architecture  : cstring,
	device        : cstring,
	description   : cstring,
	backend_type  : Backend_Type,
	adapter_type  : Adapter_Type,
	vendor_id     : u32,
	device_id     : u32,
}

Bind_Group_Entry :: struct {
	next_in_chain: ^Chained_Struct,
	binding:       u32,
	buffer:        Buffer,
	offset:        u64,
	size:          u64,
	sampler:       Sampler,
	texture_view:  Texture_View,
}

Blend_Component :: struct {
	operation:  Blend_Operation,
	src_factor: Blend_Factor,
	dst_factor: Blend_Factor,
}

Buffer_Binding_Layout :: struct {
	next_in_chain:      ^Chained_Struct,
	type:               Buffer_Binding_Type,
	has_dynamic_offset: b32,
	min_binding_size:   u64,
}

Buffer_Descriptor :: struct {
	next_in_chain:      ^Chained_Struct,
	label:              cstring,
	usage:              Buffer_Usage_Flags,
	size:               u64,
	mapped_at_creation: b32,
}

Color :: [4]f64

Command_Buffer_Descriptor :: struct {
	next_in_chain: ^Chained_Struct,
	label:         cstring,
}

Command_Encoder_Descriptor :: struct {
	next_in_chain: ^Chained_Struct,
	label:         cstring,
}

Compilation_Message :: struct {
	next_in_chain:  ^Chained_Struct,
	message:        cstring,
	type:           Compilation_Message_Type,
	line_num:       u64,
	line_pos:       u64,
	offset:         u64,
	length:         u64,
	utf16_line_pos: u64,
	utf16_offset:   u64,
	utf16_length:   u64,
}

Compute_Pass_Timestamp_Writes :: struct {
	query_set:                     Query_Set,
	beginning_of_pass_write_index: u32,
	end_of_pass_write_index:       u32,
}

Constant_Entry :: struct {
	next_in_chain: ^Chained_Struct,
	key:           cstring,
	value:         f64,
}

Extent_3D :: struct {
	width:                 u32,
	height:                u32,
	depth_or_array_layers: u32,
}

Instance_Descriptor :: struct {
	next_in_chain: ^Chained_Struct,
}

Limits :: struct {
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
	max_inter_stage_shader_components:               u32,
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

Multisample_State :: struct {
	next_in_chain:             ^Chained_Struct,
	count:                     u32,
	mask:                      u32,
	alpha_to_coverage_enabled: b32,
}

Origin_3D :: struct {
	x: u32,
	y: u32,
	z: u32,
}

Pipeline_Layout_Descriptor :: struct {
	next_in_chain:           ^Chained_Struct,
	label:                   cstring,
	bind_group_layout_count: uint,
	bind_group_layouts:      [^]Bind_Group_Layout `fmt:"v,bind_group_layout_count"`,
}

Primitive_Depth_Clip_Control :: struct {
	chain:           Chained_Struct,
	unclipped_depth: b32,
}

Primitive_State :: struct {
	next_in_chain:      ^Chained_Struct,
	topology:           Primitive_Topology,
	strip_index_format: Index_Format,
	front_face:         Front_Face,
	cull_mode:          Cull_Mode,
}

Query_Set_Descriptor :: struct {
	next_in_chain: ^Chained_Struct,
	label:         cstring,
	type:          Query_Type,
	count:         u32,
}

Queue_Descriptor :: struct {
	next_in_chain: ^Chained_Struct,
	label:         cstring,
}

Render_Bundle_Descriptor :: struct {
	next_in_chain: ^Chained_Struct,
	label:         cstring,
}

Render_Bundle_Encoder_Descriptor :: struct {
	next_in_chain:        ^Chained_Struct,
	label:                cstring,
	color_format_count:   uint,
	color_formats:        [^]Texture_Format `fmt:"v,color_format_count"`,
	depth_stencil_format: Texture_Format,
	sample_count:         u32,
	depth_read_only:      b32,
	stencil_read_only:    b32,
}

Render_Pass_Depth_Stencil_Attachment :: struct {
	view:                Texture_View,
	depth_load_op:       Load_Op,
	depth_store_op:      Store_Op,
	depth_clear_value:   f32,
	depth_read_only:     b32,
	stencil_load_op:     Load_Op,
	stencil_store_op:    Store_Op,
	stencil_clear_value: u32,
	stencil_read_only:   b32,
}

Render_Pass_Descriptor_Max_Draw_Count :: struct {
	chain:          Chained_Struct,
	max_draw_count: u64,
}

Render_Pass_Timestamp_Writes :: struct {
	query_set:                     Query_Set,
	beginning_of_pass_write_index: u32,
	end_of_pass_write_index:       u32,
}

Request_Adapter_Options :: struct {
	next_in_chain:          ^Chained_Struct,
	compatible_surface:     Surface,
	power_preference:       Power_Preference,
	backend_type:           Backend_Type,
	force_fallback_adapter: b32,
}

Sampler_Binding_Layout :: struct {
	next_in_chain: ^Chained_Struct,
	type:          Sampler_Binding_Type,
}

Sampler_Descriptor :: struct {
	next_in_chain:  ^Chained_Struct,
	label:          cstring,
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

Shader_Module_Compilation_Hint :: struct {
	next_in_chain: ^Chained_Struct,
	entry_point:   cstring,
	layout:        Pipeline_Layout,
}

Shader_Module_SPIRV_Descriptor :: struct {
	chain:     Chained_Struct,
	code_size: u32,
	code:      [^]u32 `fmt:"v,code_size"`,
}

Shader_Module_WGSL_Descriptor :: struct {
	chain: Chained_Struct,
	code:  cstring,
}

Stencil_Face_State :: struct {
	compare:       Compare_Function,
	fail_op:       Stencil_Operation,
	depth_fail_op: Stencil_Operation,
	pass_op:       Stencil_Operation,
}

Storage_Texture_Binding_Layout :: struct {
	next_in_chain:  ^Chained_Struct,
	access:         Storage_Texture_Access,
	format:         Texture_Format,
	view_dimension: Texture_View_Dimension,
}

Surface_Capabilities :: struct {
	next_in_chain      : ^Chained_Struct_Out,
	usages             : Texture_Usage_Flags,
	format_count       : uint,
	formats            : [^]Texture_Format `fmt:"v,format_count"`,
	present_mode_count : uint,
	present_modes      : [^]Present_Mode `fmt:"v,present_mode_count"`,
	alpha_mode_count   : uint,
	alpha_modes        : [^]Composite_Alpha_Mode `fmt:"v,alpha_mode_count"`,
}

Surface_Configuration :: struct {
	next_in_chain:     ^Chained_Struct,
	device:            Device,
	format:            Texture_Format,
	usage:             Texture_Usage_Flags,
	view_format_count: uint,
	view_formats:      [^]Texture_Format `fmt:"v,view_format_count"`,
	alpha_mode:        Composite_Alpha_Mode,
	width:             u32,
	height:            u32,
	present_mode:      Present_Mode,
}

Surface_Descriptor :: struct {
	next_in_chain: ^Chained_Struct,
	label:         cstring,
}

Surface_Descriptor_From_Android_Native_Window :: struct {
	chain:  Chained_Struct,
	window: rawptr,
}

Surface_Descriptor_From_Canvas_Html_Selector :: struct {
	chain:    Chained_Struct,
	selector: cstring,
}

Surface_Descriptor_From_Metal_Layer :: struct {
	chain: Chained_Struct,
	layer: rawptr,
}

Surface_Descriptor_From_Wayland_Surface :: struct {
	chain:   Chained_Struct,
	display: rawptr,
	surface: rawptr,
}

Surface_Descriptor_From_Windows_HWND :: struct {
	chain:     Chained_Struct,
	hinstance: rawptr,
	hwnd:      rawptr,
}

Surface_Descriptor_From_Xcb_Window :: struct {
	chain:      Chained_Struct,
	connection: rawptr,
	window:     u32,
}

Surface_Descriptor_From_Xlib_Window :: struct {
	chain:   Chained_Struct,
	display: rawptr,
	window:  u64,
}

Surface_Texture :: struct {
	texture:    Texture,
	suboptimal: b32,
	status:     Surface_Get_Current_Texture_Status,
}

Texture_Binding_Layout :: struct {
	next_in_chain:  ^Chained_Struct,
	sample_type:    Texture_Sample_Type,
	view_dimension: Texture_View_Dimension,
	multisampled:   b32,
}

Texture_Data_Layout :: struct {
	next_in_chain:  ^Chained_Struct,
	offset:         u64,
	bytes_per_row:  u32,
	rows_per_image: u32,
}

Texture_View_Descriptor :: struct {
	next_in_chain:     ^Chained_Struct,
	label:             cstring,
	format:            Texture_Format,
	dimension:         Texture_View_Dimension,
	base_mip_level:    u32,
	mip_level_count:   u32,
	base_array_layer:  u32,
	array_layer_count: u32,
	aspect:            Texture_Aspect,
}

Uncaptured_Error_Callback_Info :: struct {
	next_in_chain : ^Chained_Struct,
	callback      : Error_Callback,
	userdata      : rawptr,
}

Vertex_Attribute :: struct {
	format:          Vertex_Format,
	offset:          u64,
	shader_location: u32,
}

Bind_Group_Descriptor :: struct {
	next_in_chain: ^Chained_Struct,
	label:         cstring,
	layout:        Bind_Group_Layout,
	entry_count:   uint,
	entries:       [^]Bind_Group_Entry `fmt:"v,entry_count"`,
}

Bind_Group_Layout_Entry :: struct {
	next_in_chain:   ^Chained_Struct,
	binding:         u32,
	visibility:      Shader_Stage_Flags,
	buffer:          Buffer_Binding_Layout,
	sampler:         Sampler_Binding_Layout,
	texture:         Texture_Binding_Layout,
	storage_texture: Storage_Texture_Binding_Layout,
}

Blend_State :: struct {
	color: Blend_Component,
	alpha: Blend_Component,
}

Compilation_Info :: struct {
	next_in_chain: ^Chained_Struct,
	message_count: uint,
	messages:      [^]Compilation_Message `fmt:"v,message_count"`,
}

Compute_Pass_Descriptor :: struct {
	next_in_chain:    ^Chained_Struct,
	label:            cstring,
	timestamp_writes: ^Compute_Pass_Timestamp_Writes,
}

Depth_Stencil_State :: struct {
	next_in_chain:          ^Chained_Struct,
	format:                 Texture_Format,
	depth_write_enabled:    b32,
	depth_compare:          Compare_Function,
	stencil_front:          Stencil_Face_State,
	stencil_back:           Stencil_Face_State,
	stencil_read_mask:      u32,
	stencil_write_mask:     u32,
	depth_bias:             i32,
	depth_bias_slope_scale: f32,
	depth_bias_clamp:       f32,
}

Image_Copy_Buffer :: struct {
	next_in_chain: ^Chained_Struct,
	layout:        Texture_Data_Layout,
	buffer:        Buffer,
}

Image_Copy_Texture :: struct {
	next_in_chain: ^Chained_Struct,
	texture:       Texture,
	mip_level:     u32,
	origin:        Origin_3D,
	aspect:        Texture_Aspect,
}

Programmable_Stage_Descriptor :: struct {
	next_in_chain:  ^Chained_Struct,
	module:         Shader_Module,
	entry_point:    cstring,
	constant_count: uint,
	constants:      [^]Constant_Entry `fmt:"v,constant_count"`,
}

Render_Pass_Color_Attachment :: struct {
	next_in_chain  : ^Chained_Struct,
	view           : Texture_View,
	depth_slice    : u32,
	resolve_target : Texture_View,
	load_op        : Load_Op,
	store_op       : Store_Op,
	clear_value    : Color,
}

Required_Limits :: struct {
	next_in_chain: ^Chained_Struct,
	limits:        Limits,
}

Shader_Module_Descriptor :: struct {
	next_in_chain: ^Chained_Struct,
	label:         cstring,
	hint_count:    uint,
	hints:         [^]Shader_Module_Compilation_Hint `fmt:"v,hint_count"`,
}

Supported_Limits :: struct {
	next_in_chain: ^Chained_Struct_Out,
	limits:        Limits,
}

Texture_Descriptor :: struct {
	next_in_chain:     ^Chained_Struct,
	label:             cstring,
	usage:             Texture_Usage_Flags,
	dimension:         Texture_Dimension,
	size:              Extent_3D,
	format:            Texture_Format,
	mip_level_count:   u32,
	sample_count:      u32,
	view_format_count: uint,
	view_formats:      [^]Texture_Format `fmt:"v,view_format_count"`,
}

Vertex_Buffer_Layout :: struct {
	array_stride:    u64,
	step_mode:       Vertex_Step_Mode,
	attribute_count: uint,
	attributes:      [^]Vertex_Attribute `fmt:"v,attribute_count"`,
}

Bind_Group_Layout_Descriptor :: struct {
	next_in_chain: ^Chained_Struct,
	label:         cstring,
	entry_count:   uint,
	entries:       [^]Bind_Group_Layout_Entry `fmt:"v,entry_count"`,
}

Color_Target_State :: struct {
	next_in_chain: ^Chained_Struct,
	format:        Texture_Format,
	blend:         ^Blend_State,
	write_mask:    Color_Write_Mask_Flags,
}

Compute_Pipeline_Descriptor :: struct {
	next_in_chain: ^Chained_Struct,
	label:         cstring,
	layout:        Pipeline_Layout,
	compute:       Programmable_Stage_Descriptor,
}

Device_Descriptor :: struct {
	next_in_chain                  : ^Chained_Struct,
	label                          : cstring,
	required_feature_count         : uint,
	required_features              : [^]Feature_Name `fmt:"v,required_feature_count"`,
	required_limits                : ^Required_Limits,
	default_queue                  : Queue_Descriptor,
	device_lost_callback           : Device_Lost_Callback,
	device_lost_userdata           : rawptr,
	uncaptured_error_callback_info : Uncaptured_Error_Callback_Info,
}

Render_Pass_Descriptor :: struct {
	next_in_chain:            ^Chained_Struct,
	label:                    cstring,
	color_attachment_count:   uint,
	color_attachments:        [^]Render_Pass_Color_Attachment `fmt:"v,color_attachment_count"`,
	depth_stencil_attachment: ^Render_Pass_Depth_Stencil_Attachment,
	occlusion_query_set:      Query_Set,
	timestamp_writes:         ^Render_Pass_Timestamp_Writes,
}

Vertex_State :: struct {
	next_in_chain:  ^Chained_Struct,
	module:         Shader_Module,
	entry_point:    cstring,
	constant_count: uint,
	constants:      [^]Constant_Entry `fmt:"v,constant_count"`,
	buffer_count:   uint,
	buffers:        [^]Vertex_Buffer_Layout `fmt:"v,buffer_count"`,
}

Fragment_State :: struct {
	next_in_chain:  ^Chained_Struct,
	module:         Shader_Module,
	entry_point:    cstring,
	constant_count: uint,
	constants:      [^]Constant_Entry `fmt:"v,constant_count"`,
	target_count:   uint,
	targets:        [^]Color_Target_State `fmt:"v,target_count"`,
}

Render_Pipeline_Descriptor :: struct {
	next_in_chain: ^Chained_Struct,
	label:         cstring,
	layout:        Pipeline_Layout,
	vertex:        Vertex_State,
	primitive:     Primitive_State,
	depth_stencil: ^Depth_Stencil_State,
	multisample:   Multisample_State,
	fragment:      ^Fragment_State,
}

@(default_calling_convention = "c")
foreign wgpu_native {
	@(link_name = "wgpuCreateInstance")
	create_instance :: proc(descriptor: ^Instance_Descriptor) -> Instance ---

	@(link_name = "wgpuGetProcAddress")
	get_proc_address :: proc(device: Device, proc_name: cstring) -> Proc ---

	/* Methods of Adapter */

	@(link_name = "wgpuAdapterEnumerateFeatures")
	adapter_enumerate_features :: proc(adapter: Adapter, features: [^]Feature_Name) -> uint ---

	@(link_name = "wgpuAdapterGetInfo")
	adapter_get_info :: proc(adapter: Adapter, info: ^Adapter_Info) ---

	@(link_name = "wgpuAdapterGetLimits")
	adapter_get_limits :: proc(adapter: Adapter, limits: ^Supported_Limits) -> b32 ---

	@(link_name = "wgpuAdapterHasFeature")
	adapter_has_feature :: proc(adapter: Adapter, feature: Feature_Name) -> b32 ---

	@(link_name = "wgpuAdapterRequestDevice")
	adapter_request_device :: proc(
		adapter: Adapter,
		descriptor: ^Device_Descriptor,
		callback: Adapter_Request_Device_Callback,
		user_data: rawptr,
	) ---

	@(link_name = "wgpuAdapterReference")
	adapter_reference :: proc(adapter: Adapter) ---

	@(link_name = "wgpuAdapterRelease")
	adapter_release :: proc(adapter: Adapter) ---

	/* Methods of Adapter_Info */

	@(link_name = "wgpuAdapterInfoFreeMembers")
	adapter_info_free_members :: proc(adapter_info: Adapter_Info) ---

	/* Methods of Bind_Group */

	@(link_name = "wgpuBindGroupSetLabel")
	bind_group_set_label :: proc(bind_group: Bind_Group, label: cstring) ---

	@(link_name = "wgpuBindGroupReference")
	bind_group_reference :: proc(bind_group: Bind_Group) ---

	@(link_name = "wgpuBindGroupRelease")
	bind_group_release :: proc(bind_group: Bind_Group) ---

	/* Methods of Bind_Group_Layout */

	@(link_name = "wgpuBindGroupLayoutSetLabel")
	bind_group_layout_set_label :: proc(bind_group_layout: Bind_Group_Layout, label: cstring) ---

	@(link_name = "wgpuBindGroupLayoutReference")
	bind_group_layout_reference :: proc(bind_group_layout: Bind_Group_Layout) ---

	@(link_name = "wgpuBindGroupLayoutRelease")
	bind_group_layout_release :: proc(bind_group_layout: Bind_Group_Layout) ---

	/* Methods of Buffer */

	@(link_name = "wgpuBufferDestroy")
	buffer_destroy :: proc(buffer: Buffer) ---

	@(link_name = "wgpuBufferGetConstMappedRange")
	buffer_get_const_mapped_range :: proc(buffer: Buffer, offset, size: uint) -> rawptr ---

	@(link_name = "wgpuBufferGetMapState")
	buffer_get_map_state :: proc(buffer: Buffer) -> Buffer_Map_State ---

	@(link_name = "wgpuBufferGetMappedRange")
	buffer_get_mapped_range :: proc(buffer: Buffer, offset, size: uint) -> rawptr ---

	@(link_name = "wgpuBufferGetSize")
	buffer_get_size :: proc(buffer: Buffer) -> u64 ---

	@(link_name = "wgpuBufferGetUsage")
	buffer_get_usage :: proc(buffer: Buffer) -> Buffer_Usage ---

	@(link_name = "wgpuBufferMapAsync")
	buffer_map_async :: proc(
		buffer: Buffer,
		mode: Map_Mode_Flags,
		offset,
		size: uint,
		callback: Buffer_Map_Async_Callback,
		user_data: rawptr,
	) ---

	@(link_name = "wgpuBufferSetLabel")
	buffer_set_label :: proc(buffer: Buffer, label: cstring) ---

	@(link_name = "wgpuBufferUnmap")
	buffer_unmap :: proc(buffer: Buffer) ---

	@(link_name = "wgpuBufferReference")
	buffer_reference :: proc(buffer: Buffer) ---

	@(link_name = "wgpuBufferRelease")
	buffer_release :: proc(buffer: Buffer) ---

	/* Methods of Command_Buffer */

	@(link_name = "wgpuCommandBufferSetLabel")
	command_buffer_set_label :: proc(command_buffer: Command_Buffer, label: cstring) ---

	@(link_name = "wgpuCommandBufferReference")
	command_buffer_reference :: proc(command_buffer: Command_Buffer) ---

	@(link_name = "wgpuCommandBufferRelease")
	command_buffer_release :: proc(command_buffer: Command_Buffer) ---

	/* Methods of Command_Encoder */

	@(link_name = "wgpuCommandEncoderBeginComputePass")
	command_encoder_begin_compute_pass :: proc(
		command_encoder: Command_Encoder,
		descriptor: ^Compute_Pass_Descriptor,
	) -> Compute_Pass_Encoder ---

	@(link_name = "wgpuCommandEncoderBeginRenderPass")
	command_encoder_begin_render_pass :: proc(
		command_encoder: Command_Encoder,
		descriptor: ^Render_Pass_Descriptor,
	) -> Render_Pass_Encoder ---

	@(link_name = "wgpuCommandEncoderClearBuffer")
	command_encoder_clear_buffer :: proc(
		command_encoder: Command_Encoder,
		buffer: Buffer,
		offset, size: u64,
	) ---

	@(link_name = "wgpuCommandEncoderCopyBufferToBuffer")
	command_encoder_copy_buffer_to_buffer :: proc(
		command_encoder: Command_Encoder,
		source: Buffer,
		source_offset: u64,
		destination: Buffer,
		destination_offset, size: u64,
	) ---

	@(link_name = "wgpuCommandEncoderCopyBufferToTexture")
	command_encoder_copy_buffer_to_texture :: proc(
		command_encoder: Command_Encoder,
		source: ^Image_Copy_Buffer,
		destination: ^Image_Copy_Texture,
		copy_size: ^Extent_3D,
	) ---

	@(link_name = "wgpuCommandEncoderCopyTextureToBuffer")
	command_encoder_copy_texture_to_buffer :: proc(
		command_encoder: Command_Encoder,
		source: ^Image_Copy_Texture,
		destination: ^Image_Copy_Buffer,
		copy_size: ^Extent_3D,
	) ---

	@(link_name = "wgpuCommandEncoderCopyTextureToTexture")
	command_encoder_copy_texture_to_texture :: proc(
		command_encoder: Command_Encoder,
		source: ^Image_Copy_Texture,
		destination: ^Image_Copy_Texture,
		copy_size: ^Extent_3D,
	) ---

	@(link_name = "wgpuCommandEncoderFinish")
	command_encoder_finish :: proc(
		command_encoder: Command_Encoder,
		 descriptor: ^Command_Buffer_Descriptor) -> Command_Buffer ---

	@(link_name = "wgpuCommandEncoderInsertDebugMarker")
	command_encoder_insert_debug_marker :: proc(
		command_encoder: Command_Encoder,
		 marker_label: cstring) ---

	@(link_name = "wgpuCommandEncoderPopDebugGroup")
	command_encoder_pop_debug_group :: proc(command_encoder: Command_Encoder) ---

	@(link_name = "wgpuCommandEncoderPushDebugGroup")
	command_encoder_push_debug_group :: proc(
		command_encoder: Command_Encoder,
		group_label: cstring,
	) ---

	@(link_name = "wgpuCommandEncoderResolveQuerySet")
	command_encoder_resolve_query_set :: proc(
		command_encoder: Command_Encoder,
		query_set: Query_Set,
		first_query, query_count: u32,
		destination: Buffer,
		destination_offset: u64,
	) ---

	@(link_name = "wgpuCommandEncoderSetLabel")
	command_encoder_set_label :: proc(
		command_encoder: Command_Encoder,
		label: cstring,
	) ---

	@(link_name = "wgpuCommandEncoderWriteTimestamp")
	command_encoder_write_timestamp :: proc(
		command_encoder: Command_Encoder,
		query_set: Query_Set,
		query_index: u32,
	) ---

	@(link_name = "wgpuCommandEncoderReference")
	command_encoder_reference :: proc(command_encoder: Command_Encoder) ---

	@(link_name = "wgpuCommandEncoderRelease")
	command_encoder_release :: proc(command_encoder: Command_Encoder) ---

	/* Methods of Compute_Pass_Encoder */

	@(link_name = "wgpuComputePassEncoderDispatchWorkgroups")
	compute_pass_encoder_dispatch_workgroups :: proc(
		compute_pass_encoder: Compute_Pass_Encoder,
		workgroup_count_x, workgroup_count_y, workgroup_count_z: u32,
	) ---

	@(link_name = "wgpuComputePassEncoderDispatchWorkgroupsIndirect")
	compute_pass_encoder_dispatch_workgroups_indirect :: proc(
		compute_pass_encoder: Compute_Pass_Encoder,
		indirect_buffer: Buffer,
		indirect_offset: u64,
	) ---

	@(link_name = "wgpuComputePassEncoderEnd")
	compute_pass_encoder_end :: proc(compute_pass_encoder: Compute_Pass_Encoder) ---

	@(link_name = "wgpuComputePassEncoderInsertDebugMarker")
	compute_pass_encoder_insert_debug_marker :: proc(
		compute_pass_encoder: Compute_Pass_Encoder,
		marker_label: cstring,
	) ---

	@(link_name = "wgpuComputePassEncoderPopDebugGroup")
	compute_pass_encoder_pop_debug_group :: proc(compute_pass_encoder: Compute_Pass_Encoder) ---

	@(link_name = "wgpuComputePassEncoderPushDebugGroup")
	compute_pass_encoder_push_debug_group :: proc(
		compute_pass_encoder: Compute_Pass_Encoder,
		group_label: cstring,
	) ---

	@(link_name = "wgpuComputePassEncoderSetBindGroup")
	compute_pass_encoder_set_bind_group :: proc(
		compute_pass_encoder: Compute_Pass_Encoder,
		group_index: u32,
		group: Bind_Group,
		dynamic_offset_count: uint,
		dynamic_offsets: [^]u32,
	) ---

	@(link_name = "wgpuComputePassEncoderSetLabel")
	compute_pass_encoder_set_label :: proc(
		compute_pass_encoder: Compute_Pass_Encoder,
		label: cstring,
	) ---

	@(link_name = "wgpuComputePassEncoderSetPipeline")
	compute_pass_encoder_set_pipeline :: proc(
		compute_pass_encoder: Compute_Pass_Encoder,
		pipeline: Compute_Pipeline,
	) ---

	@(link_name = "wgpuComputePassEncoderReference")
	compute_pass_encoder_reference :: proc(compute_pass_encoder: Compute_Pass_Encoder) ---

	@(link_name = "wgpuComputePassEncoderRelease")
	compute_pass_encoder_release :: proc(compute_pass_encoder: Compute_Pass_Encoder) ---

	/* Methods of Compute_Pipeline */

	@(link_name = "wgpuComputePipelineGetBindGroupLayout")
	compute_pipeline_get_bind_group_layout :: proc(
		compute_pipeline: Compute_Pipeline,
		groupIndex: u32,
	) -> Bind_Group_Layout ---

	@(link_name = "wgpuComputePipelineSetLabel")
	compute_pipeline_set_label :: proc(compute_pipeline: Compute_Pipeline, label: cstring) ---

	@(link_name = "wgpuComputePipelineReference")
	compute_pipeline_reference :: proc(compute_pipeline: Compute_Pipeline) ---

	@(link_name = "wgpuComputePipelineRelease")
	compute_pipeline_release :: proc(compute_pipeline: Compute_Pipeline) ---

	/* Methods of Device */

	@(link_name = "wgpuDeviceCreateBindGroup")
	device_create_bind_group :: proc(
		device: Device,
		descriptor: ^Bind_Group_Descriptor,
	) -> Bind_Group ---

	@(link_name = "wgpuDeviceCreateBindGroupLayout")
	device_create_bind_group_layout :: proc(
		device: Device,
		descriptor: ^Bind_Group_Layout_Descriptor,
	) -> Bind_Group_Layout ---

	@(link_name = "wgpuDeviceCreateBuffer")
	device_create_buffer :: proc(device: Device, descriptor: ^Buffer_Descriptor) -> Buffer ---

	@(link_name = "wgpuDeviceCreateCommandEncoder")
	device_create_command_encoder :: proc(
		device: Device,
		descriptor: ^Command_Encoder_Descriptor,
	) -> Command_Encoder ---

	@(link_name = "wgpuDeviceCreateComputePipeline")
	device_create_compute_pipeline :: proc(
		device: Device,
		descriptor: ^Compute_Pipeline_Descriptor,
	) -> Compute_Pipeline ---

	@(link_name = "wgpuDeviceCreateComputePipelineAsync")
	device_create_compute_pipeline_async :: proc(
		device: Device,
		descriptor: ^Compute_Pipeline_Descriptor,
		callback: Device_Create_Compute_Pipeline_Async_Callback,
		user_data: rawptr,
	) ---

	@(link_name = "wgpuDeviceCreatePipelineLayout")
	device_create_pipeline_layout :: proc(
		device: Device,
		descriptor: ^Pipeline_Layout_Descriptor,
	) -> Pipeline_Layout ---

	@(link_name = "wgpuDeviceCreateQuerySet")
	device_create_query_set :: proc(device: Device, descriptor: ^Query_Set_Descriptor) -> Query_Set ---

	@(link_name = "wgpuDeviceCreateRenderBundleEncoder")
	device_create_render_bundle_encoder :: proc(
		device: Device,
		descriptor: ^Render_Bundle_Encoder_Descriptor,
	) -> Render_Bundle_Encoder ---

	@(link_name = "wgpuDeviceCreateRenderPipeline")
	device_create_render_pipeline :: proc(
		device: Device,
		descriptor: ^Render_Pipeline_Descriptor,
	) -> Render_Pipeline ---

	@(link_name = "wgpuDeviceCreateRenderPipelineAsync")
	device_create_render_pipeline_async :: proc(
		device: Device,
		descriptor: ^Render_Pipeline_Descriptor,
		callback: Device_Create_Render_Pipeline_Async_Callback,
		user_data: rawptr,
	) ---

	@(link_name = "wgpuDeviceCreateSampler")
	device_create_sampler :: proc(device: Device, descriptor: ^Sampler_Descriptor) -> Sampler ---

	@(link_name = "wgpuDeviceCreateShaderModule")
	device_create_shader_module :: proc(
		device: Device,
		descriptor: ^Shader_Module_Descriptor,
	) -> Shader_Module ---

	@(link_name = "wgpuDeviceCreateTexture")
	device_create_texture :: proc(device: Device, descriptor: ^Texture_Descriptor) -> Texture ---

	@(link_name = "wgpuDeviceDestroy")
	device_destroy :: proc(device: Device) ---

	@(link_name = "wgpuDeviceEnumerateFeatures")
	device_enumerate_features :: proc(device: Device, features: ^Feature_Name) -> uint ---

	@(link_name = "wgpuDeviceGetLimits")
	device_get_limits :: proc(device: Device, limits: ^Supported_Limits) -> b32 ---

	@(link_name = "wgpuDeviceGetQueue")
	device_get_queue :: proc(device: Device) -> Queue ---

	@(link_name = "wgpuDeviceHasFeature")
	device_has_feature :: proc(device: Device, feature: Feature_Name) -> b32 ---

	@(link_name = "wgpuDevicePopErrorScope")
	device_pop_error_scope :: proc(
		device: Device,
		callback: Error_Callback,
		user_data: rawptr,
	) -> b32 ---

	@(link_name = "wgpuDevicePushErrorScope")
	device_push_error_scope :: proc(device: Device, filter: Error_Filter) ---

	@(link_name = "wgpuDeviceSetDeviceLostCallback")
	device_set_device_lost_callback :: proc(
		device: Device,
		callback: Device_Lost_Callback,
		user_data: rawptr,
	) ---

	@(link_name = "wgpuDeviceSetLabel")
	device_set_label :: proc(device: Device, label: cstring) ---

	@(link_name = "wgpuDeviceReference")
	device_reference :: proc(device: Device) ---

	@(link_name = "wgpuDeviceRelease")
	device_release :: proc(device: Device) ---

	/* Methods of Instance */

	@(link_name = "wgpuInstanceCreateSurface")
	instance_create_surface :: proc(
		instance: Instance,
		descriptor: ^Surface_Descriptor,
	) -> Surface ---

	@(link_name = "wgpuInstanceHasWGSLLanguageFeature")
	instance_has_wgsl_language_feature :: proc(
		instance: Instance,
		feature: WGSL_Feature_Name,
	) -> b32 ---

	@(link_name = "wgpuInstanceProcessEvents")
	instance_process_events :: proc(instance: Instance) ---

	@(link_name = "wgpuInstanceRequestAdapter")
	instance_request_adapter :: proc(
		instance: Instance,
		options: ^Request_Adapter_Options,
		callback: Instance_Request_Adapter_Callback,
		user_data: rawptr,
	) ---

	@(link_name = "wgpuInstanceReference")
	instance_reference :: proc(instance: Instance) ---

	@(link_name = "wgpuInstanceRelease")
	instance_release :: proc(instance: Instance) ---

	/* Methods of Pipeline_Layout */

	@(link_name = "wgpuPipelineLayoutSetLabel")
	pipeline_layout_set_label :: proc(pipeline_layout: Pipeline_Layout, label: cstring) ---

	@(link_name = "wgpuPipelineLayoutReference")
	pipeline_layout_reference :: proc(pipeline_layout: Pipeline_Layout) ---

	@(link_name = "wgpuPipelineLayoutRelease")
	pipeline_layout_release :: proc(pipeline_layout: Pipeline_Layout) ---

	/* Methods of Query_Set */

	@(link_name = "wgpuQuerySetDestroy")
	query_set_destroy :: proc(query_set: Query_Set) ---

	@(link_name = "wgpuQuerySetGetCount")
	query_set_get_count :: proc(query_set: Query_Set) -> u32 ---

	@(link_name = "wgpuQuerySetGetType")
	query_set_get_type :: proc(query_set: Query_Set) -> Query_Type ---

	@(link_name = "wgpuQuerySetSetLabel")
	query_set_set_label :: proc(query_set: Query_Set, label: cstring) ---

	@(link_name = "wgpuQuerySetReference")
	query_set_reference :: proc(query_set: Query_Set) ---

	@(link_name = "wgpuQuerySetRelease")
	query_set_release :: proc(query_set: Query_Set) ---

	/* Methods of Queue */

	@(link_name = "wgpuQueueOnSubmittedWorkDone")
	queue_on_submitted_work_done :: proc(
		queue: Queue,
		callback: Queue_On_Submitted_Work_Done_Callback,
		user_data: rawptr,
	) ---

	@(link_name = "wgpuQueueSetLabel")
	queue_set_label :: proc(queue: Queue, label: cstring) ---

	@(link_name = "wgpuQueueSubmit")
	queue_submit :: proc(queue: Queue, commandCount: uint, commands: [^]Command_Buffer) ---

	@(link_name = "wgpuQueueWriteBuffer")
	queue_write_buffer :: proc(
		queue: Queue,
		buffer: Buffer,
		bufferOffset: u64,
		data: rawptr,
		size: uint,
	) ---

	@(link_name = "wgpuQueueWriteTexture")
	queue_write_texture :: proc(
		queue: Queue,
		destination: ^Image_Copy_Texture,
		data: rawptr,
		data_size: uint,
		data_layout: ^Texture_Data_Layout,
		write_size: ^Extent_3D,
	) ---

	@(link_name = "wgpuQueueReference")
	queue_reference :: proc(queue: Queue) ---

	@(link_name = "wgpuQueueRelease")
	queue_release :: proc(queue: Queue) ---

	/* Methods of Render_Bundle */

	@(link_name = "wgpuRenderBundleSetLabel")
	render_bundle_set_label :: proc(render_bundle: Render_Bundle, label: cstring) ---

	@(link_name = "wgpuRenderBundleReference")
	render_bundle_reference :: proc(render_bundle: Render_Bundle) ---

	@(link_name = "wgpuRenderBundleRelease")
	render_bundle_release :: proc(render_bundle: Render_Bundle) ---

	/* Methods of Render_Bundle_Encoder */

	@(link_name = "wgpuRenderBundleEncoderDraw")
	render_bundle_encoder_draw :: proc(
		render_bundle_encoder: Render_Bundle_Encoder,
		vertex_count, instance_count, first_vertex, first_instance: u32,
	) ---

	@(link_name = "wgpuRenderBundleEncoderDrawIndexed")
	render_bundle_encoder_draw_indexed :: proc(
		render_bundle_encoder: Render_Bundle_Encoder,
		index_count, instance_count, first_index: u32,
		base_vertex: i32,
		first_instance: u32,
	) ---

	@(link_name = "wgpuRenderBundleEncoderDrawIndexedIndirect")
	render_bundle_encoder_draw_indexed_indirect :: proc(
		render_bundle_encoder: Render_Bundle_Encoder,
		indirect_buffer: Buffer,
		indirect_offset: u64,
	) ---

	@(link_name = "wgpuRenderBundleEncoderDrawIndirect")
	render_bundle_encoder_draw_indirect :: proc(
		render_bundle_encoder: Render_Bundle_Encoder,
		indirect_buffer: Buffer,
		indirect_offset: u64,
	) ---

	@(link_name = "wgpuRenderBundleEncoderFinish")
	render_bundle_encoder_finish :: proc(
		render_bundle_encoder: Render_Bundle_Encoder,
		descriptor: ^Render_Bundle_Descriptor,
	) -> Render_Bundle ---

	@(link_name = "wgpuRenderBundleEncoderInsertDebugMarker")
	render_bundle_encoder_insert_debug_marker :: proc(
		render_bundle_encoder: Render_Bundle_Encoder,
		marker_label: cstring,
	) ---

	@(link_name = "wgpuRenderBundleEncoderPopDebugGroup")
	render_bundle_encoder_pop_debug_group :: proc(render_bundle_encoder: Render_Bundle_Encoder) ---

	@(link_name = "wgpuRenderBundleEncoderPushDebugGroup")
	render_bundle_encoder_push_debug_group :: proc(
		render_bundle_encoder: Render_Bundle_Encoder,
		group_label: cstring,
	) ---

	@(link_name = "wgpuRenderBundleEncoderSetBindGroup")
	render_bundle_encoder_set_bind_group :: proc(
		render_bundle_encoder: Render_Bundle_Encoder,
		group_index: u32,
		group: Bind_Group,
		dynamic_offset_count: uint,
		dynamic_offsets: [^]u32,
	) ---

	@(link_name = "wgpuRenderBundleEncoderSetIndexBuffer")
	render_bundle_encoder_set_index_buffer :: proc(
		render_bundle_encoder: Render_Bundle_Encoder,
		buffer: Buffer,
		format: Index_Format,
		offset, size: u64,
	) ---

	@(link_name = "wgpuRenderBundleEncoderSetLabel")
	render_bundle_encoder_set_label :: proc(
		render_bundle_encoder: Render_Bundle_Encoder,
		label: cstring,
	) ---

	@(link_name = "wgpuRenderBundleEncoderSetPipeline")
	render_bundle_encoder_set_pipeline :: proc(
		render_bundle_encoder: Render_Bundle_Encoder,
		pipeline: Render_Pipeline,
	) ---

	@(link_name = "wgpuRenderBundleEncoderSetVertexBuffer")
	render_bundle_encoder_set_vertex_buffer :: proc(
		render_bundle_encoder: Render_Bundle_Encoder,
		slot: u32,
		buffer: Buffer,
		offset, size: u64,
	) ---

	@(link_name = "wgpuRenderBundleEncoderReference")
	render_bundle_encoder_reference :: proc(render_bundle_encoder: Render_Bundle_Encoder) ---

	@(link_name = "wgpuRenderBundleEncoderRelease")
	render_bundle_encoder_release :: proc(render_bundle_encoder: Render_Bundle_Encoder) ---

	/* Methods of Render_Pass_Encoder */

	@(link_name = "wgpuRenderPassEncoderBeginOcclusionQuery")
	render_pass_encoder_begin_occlusion_query :: proc(
		render_pass_encoder: Render_Pass_Encoder,
		query_index: u32,
	) ---

	@(link_name = "wgpuRenderPassEncoderDraw")
	render_pass_encoder_draw :: proc(
		render_pass_encoder: Render_Pass_Encoder,
		vertex_count, instance_count, first_vertex, firstInstance: u32,
	) ---

	@(link_name = "wgpuRenderPassEncoderDrawIndexed")
	render_pass_encoder_draw_indexed :: proc(
		render_pass_encoder: Render_Pass_Encoder,
		index_count, instance_count, firstIndex: u32,
		base_vertex: i32,
		first_instance: u32,
	) ---

	@(link_name = "wgpuRenderPassEncoderDrawIndexedIndirect")
	render_pass_encoder_draw_indexed_indirect :: proc(
		render_pass_encoder: Render_Pass_Encoder,
		indirect_buffer: Buffer,
		indirect_offset: u64,
	) ---

	@(link_name = "wgpuRenderPassEncoderDrawIndirect")
	render_pass_encoder_draw_indirect :: proc(
		render_pass_encoder: Render_Pass_Encoder,
		indirect_buffer: Buffer,
		indirect_offset: u64,
	) ---

	@(link_name = "wgpuRenderPassEncoderEnd")
	render_pass_encoder_end :: proc(render_pass_encoder: Render_Pass_Encoder) ---

	@(link_name = "wgpuRenderPassEncoderEndOcclusionQuery")
	render_pass_encoder_end_occlusion_query :: proc(render_pass_encoder: Render_Pass_Encoder) ---

	@(link_name = "wgpuRenderPassEncoderExecuteBundles")
	render_pass_encoder_execute_bundles :: proc(
		render_pass_encoder: Render_Pass_Encoder,
		bundle_count: uint,
		bundles: [^]Render_Bundle,
	) ---

	@(link_name = "wgpuRenderPassEncoderInsertDebugMarker")
	render_pass_encoder_insert_debug_marker :: proc(
		render_pass_encoder: Render_Pass_Encoder,
		marker_label: cstring,
	) ---

	@(link_name = "wgpuRenderPassEncoderPopDebugGroup")
	render_pass_encoder_pop_debug_group :: proc(render_pass_encoder: Render_Pass_Encoder) ---

	@(link_name = "wgpuRenderPassEncoderPushDebugGroup")
	render_pass_encoder_push_debug_group :: proc(
		render_pass_encoder: Render_Pass_Encoder,
		group_label: cstring,
	) ---

	@(link_name = "wgpuRenderPassEncoderSetBindGroup")
	render_pass_encoder_set_bind_group :: proc(
		render_pass_encoder: Render_Pass_Encoder,
		group_index: u32,
		group: Bind_Group,
		dynamic_offset_count: uint,
		dynamic_offsets: [^]u32,
	) ---

	@(link_name = "wgpuRenderPassEncoderSetBlendConstant")
	render_pass_encoder_set_blend_constant :: proc(
		render_pass_encoder: Render_Pass_Encoder,
		color: ^Color,
	) ---

	@(link_name = "wgpuRenderPassEncoderSetIndexBuffer")
	render_pass_encoder_set_index_buffer :: proc(
		render_pass_encoder: Render_Pass_Encoder,
		buffer: Buffer,
		format: Index_Format,
		offset, size: u64,
	) ---

	@(link_name = "wgpuRenderPassEncoderSetLabel")
	render_pass_encoder_set_label :: proc(
		render_pass_encoder: Render_Pass_Encoder,
		label: cstring,
	) ---

	@(link_name = "wgpuRenderPassEncoderSetPipeline")
	render_pass_encoder_set_pipeline :: proc(
		render_pass_encoder: Render_Pass_Encoder,
		pipeline: Render_Pipeline,
	) ---

	@(link_name = "wgpuRenderPassEncoderSetScissorRect")
	render_pass_encoder_set_scissor_rect :: proc(
		render_pass_encoder: Render_Pass_Encoder,
		x, y, width, height: u32,
	) ---

	@(link_name = "wgpuRenderPassEncoderSetStencilReference")
	render_pass_encoder_set_stencil_reference :: proc(
		render_pass_encoder: Render_Pass_Encoder,
		reference: u32,
	) ---

	@(link_name = "wgpuRenderPassEncoderSetVertexBuffer")
	render_pass_encoder_set_vertex_buffer :: proc(
		render_pass_encoder: Render_Pass_Encoder,
		slot: u32,
		buffer: Buffer,
		offset, size: u64,
	) ---

	@(link_name = "wgpuRenderPassEncoderSetViewport")
	render_pass_encoder_set_viewport :: proc(
		render_pass_encoder: Render_Pass_Encoder,
		x, y, width, height, min_depth, max_depth: f32,
	) ---

	@(link_name = "wgpuRenderPassEncoderReference")
	render_pass_encoder_reference :: proc(render_pass_encoder: Render_Pass_Encoder) ---

	@(link_name = "wgpuRenderPassEncoderRelease")
	render_pass_encoder_release :: proc(render_pass_encoder: Render_Pass_Encoder) ---

	/* Methods of Render_Pipeline */

	@(link_name = "wgpuRenderPipelineGetBindGroupLayout")
	render_pipeline_get_bind_group_layout :: proc(
		render_pipeline: Render_Pipeline,
		group_index: u32,
	) -> Bind_Group_Layout ---

	@(link_name = "wgpuRenderPipelineSetLabel")
	render_pipeline_set_label :: proc(render_pipeline: Render_Pipeline, label: cstring) ---

	@(link_name = "wgpuRenderPipelineReference")
	render_pipeline_reference :: proc(render_pipeline: Render_Pipeline) ---

	@(link_name = "wgpuRenderPipelineRelease")
	render_pipeline_release :: proc(render_pipeline: Render_Pipeline) ---

	/* Methods of Sampler */

	@(link_name = "wgpuSamplerSetLabel")
	sampler_set_label :: proc(sampler: Sampler, label: cstring) ---

	@(link_name = "wgpuSamplerReference")
	sampler_reference :: proc(sampler: Sampler) ---

	@(link_name = "wgpuSamplerRelease")
	sampler_release :: proc(sampler: Sampler) ---

	/* Methods of Shader_Module */

	@(link_name = "wgpuShaderModuleGetCompilationInfo")
	shader_module_get_compilation_info :: proc(
		shader_module: Shader_Module,
		callback: Shader_Module_Get_Compilation_Info_Callback,
		user_data: rawptr,
	) ---

	@(link_name = "wgpuShaderModuleSetLabel")
	shader_module_set_label :: proc(shader_module: Shader_Module, label: cstring) ---

	@(link_name = "wgpuShaderModuleReference")
	shader_module_reference :: proc(shader_module: Shader_Module) ---

	@(link_name = "wgpuShaderModuleRelease")
	shader_module_release :: proc(shader_module: Shader_Module) ---

	/* Methods of Surface */

	@(link_name = "wgpuSurfaceConfigure")
	surface_configure :: proc(surface: Surface, config: ^Surface_Configuration) ---

	@(link_name = "wgpuSurfaceGetCapabilities")
	surface_get_capabilities :: proc(
		surface: Surface,
		adapter: Adapter,
		capabilities: ^Surface_Capabilities,
	) ---

	@(link_name = "wgpuSurfaceGetCurrentTexture")
	surface_get_current_texture :: proc(surface: Surface, surface_texture: ^Surface_Texture) ---

	@(link_name = "wgpuSurfacePresent")
	surface_present :: proc(surface: Surface) ---

	@(link_name = "wgpuSurfaceSetLabel")
	surface_set_label :: proc(surface: Surface, label: cstring) ---

	@(link_name = "wgpuSurfaceUnconfigure")
	surface_unconfigure :: proc(surface: Surface) ---

	@(link_name = "wgpuSurfaceReference")
	surface_reference :: proc(surface: Surface) ---

	@(link_name = "wgpuSurfaceRelease")
	surface_release :: proc(surface: Surface) ---

	/* Methods of Surface_Capabilities */

	@(link_name = "wgpuSurfaceCapabilitiesFreeMembers")
	surface_capabilities_free_members :: proc(capabilities: Surface_Capabilities) ---

	/* Methods of Texture */

	@(link_name = "wgpuTextureCreateView")
	texture_create_view :: proc(
		texture: Texture,
		descriptor: ^Texture_View_Descriptor,
	) -> Texture_View ---

	@(link_name = "wgpuTextureDestroy")
	texture_destroy :: proc(texture: Texture) ---

	@(link_name = "wgpuTextureGetDepthOrArrayLayers")
	texture_get_depth_or_array_layers :: proc(texture: Texture) -> u32 ---

	@(link_name = "wgpuTextureGetDimension")
	texture_get_dimension :: proc(texture: Texture) -> Texture_Dimension ---

	@(link_name = "wgpuTextureGetFormat")
	texture_get_format :: proc(texture: Texture) -> Texture_Format ---

	@(link_name = "wgpuTextureGetHeight")
	texture_get_height :: proc(texture: Texture) -> u32 ---

	@(link_name = "wgpuTextureGetMipLevelCount")
	texture_get_mip_level_count :: proc(texture: Texture) -> u32 ---

	@(link_name = "wgpuTextureGetSampleCount")
	texture_get_sample_count :: proc(texture: Texture) -> u32 ---

	@(link_name = "wgpuTextureGetUsage")
	texture_get_usage :: proc(texture: Texture) -> Texture_Usage ---

	@(link_name = "wgpuTextureGetWidth")
	texture_get_width :: proc(texture: Texture) -> u32 ---

	@(link_name = "wgpuTextureSetLabel")
	texture_set_label :: proc(texture: Texture, label: cstring) ---

	@(link_name = "wgpuTextureReference")
	texture_reference :: proc(texture: Texture) ---

	@(link_name = "wgpuTextureRelease")
	texture_release :: proc(texture: Texture) ---

	/* Methods of Texture_View */

	@(link_name = "wgpuTextureViewSetLabel")
	texture_view_set_label :: proc(texture_view: Texture_View, label: cstring) ---

	@(link_name = "wgpuTextureViewReference")
	texture_view_reference :: proc(texture_view: Texture_View) ---

	@(link_name = "wgpuTextureViewRelease")
	texture_view_release :: proc(texture_view: Texture_View) ---
}
