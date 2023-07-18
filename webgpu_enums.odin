package wgpu_bindings

import "core:c"

Adapter_Type :: enum c.int {
    Discrete_GPU,
    Integrated_GPU,
    CPU,
    Unknown,
}

Address_Mode :: enum c.int {
    Repeat,
    MirrorRepeat,
    ClampToEdge,
}

Backend_Type :: enum c.int {
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

Blend_Factor :: enum c.int {
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

Blend_Operation :: enum c.int {
    Add,
    Subtract,
    ReverseSubtract,
    Min,
    Max,
}

Buffer_Binding_Type :: enum c.int {
    Undefined,
    Uniform,
    Storage,
    Read_Only_Storage,
}

Buffer_Map_Async_Status :: enum c.int {
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

Buffer_Map_State :: enum c.int {
    Unmapped,
    Pending,
    Mapped,
}

Compare_Function :: enum c.int {
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

Compilation_Info_Request_Status :: enum c.int {
    Success,
    Error,
    Device_Lost,
    Unknown,
}

Compilation_Message_Type :: enum c.int {
    Error,
    Warning,
    Info,
}

Compute_Pass_Timestamp_Location :: enum c.int {
    Beginning,
    End,
}

Create_Pipeline_Async_Status :: enum c.int {
    Success,
    Validation_Error,
    Internal_Error,
    Device_Lost,
    Device_Destroyed,
    Unknown,
}

Cull_Mode :: enum c.int {
    None,
    Front,
    Back,
}

Device_Lost_Reason :: enum c.int {
    Undefined,
    Destroyed,
}

Error_Filter :: enum c.int {
    Validation,
    Out_Of_Memory,
    Internal,
}

Error_Type :: enum c.int {
    No_Error,
    Validation,
    Out_Of_Memory,
    Internal,
    Unknown,
    Device_Lost,
}

Feature_Name :: enum c.int {
    Undefined,
    Depth_Clip_Control,
    Depth32_Float_Stencil8,
    Timestamp_Query,
    Pipeline_Statistics_Query,
    Texture_Compression_Bc,
    Texture_Compression_Etc2,
    Texture_Compression_Astc,
    Indirect_First_Instance,
    Shader_F16,
    Rg11_B10_Ufloat_Renderable,
    Bgra8_Unorm_Storage,
    Float32_Filterable,
}

Filter_Mode :: enum c.int {
    Nearest,
    Linear,
}

Front_Face :: enum c.int {
    CCW,
    CW,
}

Index_Format :: enum c.int {
    Undefined,
    Uint16,
    Uint32,
}

Load_Op :: enum c.int {
    Undefined,
    Clear,
    Load,
}

Mipmap_Filter_Mode :: enum c.int {
    Nearest,
    Linear,
}

Pipeline_Statistic_Name :: enum c.int {
    Vertex_Shader_Invocations,
    Clipper_Invocations,
    Clipper_Primitives_Out,
    Fragment_Shader_Invocations,
    Compute_Shader_Invocations,
}

Power_Preference :: enum c.int {
    Undefined,
    Low_Power,
    High_Performance,
}

Present_Mode :: enum c.int {
    Immediate,
    Mailbox,
    Fifo,
}

Primitive_Topology :: enum c.int {
    Point_List,
    Line_List,
    Line_Strip,
    Triangle_List,
    Triangle_Strip,
}

Query_Type :: enum c.int {
    Occlusion,
    Pipeline_Statistics,
    Timestamp,
}

Queue_Work_Done_Status :: enum c.int {
    Success,
    Error,
    Unknown,
    Device_Lost,
}

Render_Pass_Timestamp_Location :: enum c.int {
    Beginning,
    End,
}

Request_Adapter_Status :: enum c.int {
    Success,
    Unavailable,
    Error,
    Unknown,
}

Request_Device_Status :: enum c.int {
    Success,
    Error,
    Unknown,
}

SType :: enum c.int {
    Invalid,
    Surface_Descriptor_From_Metal_Layer,
    Surface_Descriptor_From_Windows_HWND,
    Surface_Descriptor_From_Xlib_Window,
    Surface_Descriptor_From_Canvas_Html_Selector,
    Shader_Module_Spirv_Descriptor,
    Shader_Module_WGSL_Descriptor,
    Primitive_Depth_Clip_Control,
    Surface_Descriptor_From_Wayland_Surface,
    Surface_Descriptor_From_Android_Native_Window,
    Surface_Descriptor_From_Xcb_Window,
    Render_Pass_Descriptor_Max_Draw_Count,
}

Sampler_Binding_Type :: enum c.int {
    Undefined,
    Filtering,
    Non_Filtering,
    Comparison,
}

Stencil_Operation :: enum c.int {
    Keep,
    Zero,
    Replace,
    Invert,
    Increment_Clamp,
    Decrement_Clamp,
    Increment_Wrap,
    Decrement_Wrap,
}

Storage_Texture_Access :: enum c.int {
    Undefined,
    WriteOnly,
}

Store_Op :: enum c.int {
    Undefined,
    Store,
    Discard,
}

Texture_Aspect :: enum c.int {
    All,
    Stencil_Only,
    Depth_Only,
}

Texture_Component_Type :: enum c.int {
    Float,
    Sint,
    Uint,
    Depth_Comparison,
}

Texture_Dimension :: enum c.int {
    _1D,
    _2D,
    _3D,
}

Texture_Format :: enum c.int {
    Undefined,
    R8_Unorm,
    R8_Snorm,
    R8_Uint,
    R8_Sint,
    R16_Uint,
    R16_Sint,
    R16_Float,
    Rg8_Unorm,
    Rg8_Snorm,
    Rg8_Uint,
    Rg8_Sint,
    R32_Float,
    R32_Uint,
    R32_Sint,
    Rg16_Uint,
    Rg16_Sint,
    Rg16_Float,
    Rgba8_Unorm,
    Rgba8_Unorm_Srgb,
    Rgba8_Snorm,
    Rgba8_Uint,
    Rgba8_Sint,
    Bgra8_Unorm,
    Bgra8_Unorm_Srgb,
    Rgb10_A2_Unorm,
    Rg11_B10_Ufloat,
    Rgb9_E5_Ufloat,
    Rg32_Float,
    Rg32_Uint,
    Rg32_Sint,
    Rgba16_Uint,
    Rgba16_Sint,
    Rgba16_Float,
    Rgba32_Float,
    Rgba32_Uint,
    Rgba32_Sint,
    Stencil8,
    Depth16_Unorm,
    Depth24_Plus,
    Depth24_Plus_Stencil8,
    Depth32_Float,
    Depth32_Float_Stencil8,
    Bc1_Rgba_Unorm,
    Bc1_Rgba_Unorm_Srgb,
    Bc2_Rgba_Unorm,
    Bc2_Rgba_Unorm_Srgb,
    Bc3_Rgba_Unorm,
    Bc3_Rgba_Unorm_Srgb,
    Bc4_R_Unorm,
    Bc4_R_Snorm,
    Bc5_Rg_Unorm,
    Bc5_Rg_Snorm,
    Bc6_Hrgb_Ufloat,
    Bc6_Hrgb_Float,
    Bc7_Rgba_Unorm,
    Bc7_Rgba_Unorm_Srgb,
    Etc2_Rgb8_Unorm,
    Etc2_Rgb8_Unorm_Srgb,
    Etc2_Rgb8_A1_Unorm,
    Etc2_Rgb8_A1_Unorm_Srgb,
    Etc2_Rgba8_Unorm,
    Etc2_Rgba8_Unorm_Srgb,
    Eacr11_Unorm,
    Eacr11_Snorm,
    Eacrg11_Unorm,
    Eacrg11_Snorm,
    Astc4x4_Unorm,
    Astc4x4_Unorm_Srgb,
    Astc5x4_Unorm,
    Astc5x4_Unorm_Srgb,
    Astc5x5_Unorm,
    Astc5x5_Unorm_Srgb,
    Astc6x5_Unorm,
    Astc6x5_Unorm_Srgb,
    Astc6x6_Unorm,
    Astc6x6_Unorm_Srgb,
    Astc8x5_Unorm,
    Astc8x5_Unorm_Srgb,
    Astc8x6_Unorm,
    Astc8x6_Unorm_Srgb,
    Astc8x8_Unorm,
    Astc8x8_Unorm_Srgb,
    Astc10x5_Unorm,
    Astc10x5_Unorm_Srgb,
    Astc10x6_Unorm,
    Astc10x6_Unorm_Srgb,
    Astc10x8_Unorm,
    Astc10x8_Unorm_Srgb,
    Astc10x10_Unorm,
    Astc10x10_Unorm_Srgb,
    Astc12x10_Unorm,
    Astc12x10_Unorm_Srgb,
    Astc12x12_Unorm,
    Astc12x12_Unorm_Srgb,
}

Texture_Sample_Type :: enum c.int {
    Undefined,
    Float,
    Unfilterable_Float,
    Depth,
    Sint,
    Uint,
}

Texture_View_Dimension :: enum c.int {
    Undefined,
    _1D,
    _2D,
    _2DArray,
    Cube,
    CubeArray,
    _3D,
}

Vertex_Format :: enum c.int {
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

Vertex_Step_Mode :: enum c.int {
    Vertex,
    Instance,
    Vertex_Buffer_Not_Used,
}

Buffer_Usage :: enum c.int {
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
Buffer_Usage_Flags :: bit_set[Buffer_Usage;Flags]
Buffer_Usage_Flags_None :: Buffer_Usage_Flags{}

Color_Write_Mask :: enum c.int {
    Red,
    Green,
    Blue,
    Alpha,
}
Color_Write_Mask_Flags :: bit_set[Color_Write_Mask;Flags]
Color_Write_Mask_Flags_None :: Color_Write_Mask_Flags{}
Color_Write_Mask_Flags_All :: Color_Write_Mask_Flags{.Red, .Green, .Blue, .Alpha}

Map_Mode :: enum c.int {
    Read,
    Write,
}
Map_Mode_Flags :: bit_set[Map_Mode;Flags]

Shader_Stage :: enum c.int {
    Vertex,
    Fragment,
    Compute,
}
Shader_Stage_Flags :: bit_set[Shader_Stage;Flags]
Shader_Stage_Flags_None :: Shader_Stage_Flags{}

Texture_Usage :: enum c.int {
    Copy_Src,
    Copy_Dst,
    Texture_Binding,
    Storage_Binding,
    Render_Attachment,
}
Texture_Usage_Flags :: bit_set[Texture_Usage;Flags]
Texture_Usage_Flags_None :: Texture_Usage_Flags{}
