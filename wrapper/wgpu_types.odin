package wgpu

// STD Library
import intr "base:intrinsics"

// The raw bindings
import wgpu "../bindings"

/* Integral type used for buffer offsets. */
Buffer_Address :: u64
/* Integral type used for buffer slice sizes. */
Buffer_Size :: u64
/* Integral type used for buffer slice sizes. */
Shader_Location :: u32
/* Integral type used for dynamic bind group offsets. */
Dynamic_Offset :: u32

/* Buffer-Texture copies must have [`bytes_per_row`] aligned to this number. */
COPY_BYTES_PER_ROW_ALIGNMENT: u32 : 256
/* An offset into the query resolve buffer has to be aligned to self. */
QUERY_RESOLVE_BUFFER_ALIGNMENT: Buffer_Address : 256
/*
Buffer to buffer copy as well as buffer clear offsets and sizes must be aligned to
this number.
*/
COPY_BUFFER_ALIGNMENT: Buffer_Address : 4
/* Buffer alignment mask to calculate proper size */
COPY_BUFFER_ALIGNMENT_MASK :: COPY_BUFFER_ALIGNMENT - 1
/* Size to align mappings. */
MAP_ALIGNMENT: Buffer_Address : 8
/* Vertex buffer strides have to be aligned to this number. */
VERTEX_STRIDE_ALIGNMENT: Buffer_Address : 4
/* Alignment all push constants need */
PUSH_CONSTANT_ALIGNMENT: u32 : 4
/* Maximum queries in a query set */
QUERY_SET_MAX_QUERIES: u32 : 8192
/* Size of a single piece of query data. */
QUERY_SIZE: u32 : 8

/*
An undefined number of array layers for a texture view.
It is used when the number of array layers is not specified or not applicable.
*/
ARRAY_LAYER_COUNT_UNDEFINED  :: wgpu.ARRAY_LAYER_COUNT_UNDEFINED

/*
An undefined stride value for a copy operation.
It is used when the stride is not specified or not applicable.
*/
COPY_STRIDE_UNDEFINED  :: wgpu.COPY_STRIDE_UNDEFINED

/*
An undefined 32-bit unsigned integer limit.
It is used when the limit is not specified or not applicable.
*/
LIMIT_U32_UNDEFINED  :: wgpu.LIMIT_U32_UNDEFINED

/*
An undefined 64-bit unsigned integer limit.
It is used when the limit is not specified or not applicable.
*/
LIMIT_U64_UNDEFINED  :: wgpu.LIMIT_U64_UNDEFINED

/*
An undefined number of mipmap levels for a texture view.
It is used when the number of mipmap levels is not specified or not applicable.
*/
MIP_LEVEL_COUNT_UNDEFINED  :: wgpu.MIP_LEVEL_COUNT_UNDEFINED

/*
An undefined index for a query set.
It is used when the query set index is not specified or not applicable.
*/
QUERY_SET_INDEX_UNDEFINED  :: wgpu.QUERY_SET_INDEX_UNDEFINED

/*
The entire size of a mapped resource.
It is used when the full size of a mapped resource needs to be specified.
*/
WHOLE_MAP_SIZE  :: wgpu.WHOLE_MAP_SIZE

/*
The entire size of a resource.
It is used when the full size of a resource needs to be specified.
*/
WHOLE_SIZE  :: wgpu.WHOLE_SIZE

FLAGS     :: wgpu.FLAGS
ENUM_SIZE :: wgpu.ENUM_SIZE

Native_SType :: wgpu.Native_SType
Native_Feature :: wgpu.Native_Feature
Log_Level :: wgpu.Log_Level
Instance_Backend :: wgpu.Instance_Backend
Instance_Backend_Flags :: wgpu.Instance_Backend_Flags
Instance_Flags :: wgpu.Instance_Flags
Instance_Backend_Primary :: wgpu.Instance_Backend_Primary
Instance_Backend_Secondary :: wgpu.Instance_Backend_Secondary
// Instance_Backend_None :: wgpu.Instance_Backend_None
Dx12_Compiler :: wgpu.Dx12_Compiler
Gles3_Minor_Version :: wgpu.Gles3_Minor_Version
// Pipeline_Statistic_Name :: wgpu.Pipeline_Statistic_Name
Composite_Alpha_Mode :: wgpu.Composite_Alpha_Mode

Instance_Extras :: wgpu.Instance_Extras
Device_Extras :: wgpu.Device_Extras
Required_Limits_Extras :: wgpu.Required_Limits_Extras
// Surface_Configuration_Extras :: wgpu.Surface_Configuration_Extras
Supported_Limits_Extras :: wgpu.Supported_Limits_Extras
// Push_Constant_Range :: wgpu.Push_Constant_Range
// Pipeline_Layout_Extras :: wgpu.Pipeline_Layout_Extras
Submission_Index :: wgpu.Submission_Index
Wrapped_Submission_Index :: wgpu.Wrapped_Submission_Index
Shader_Define :: wgpu.Shader_Define
Shader_Module_Glsl_Descriptor :: wgpu.Shader_Module_Glsl_Descriptor
Registry_Report :: wgpu.Registry_Report
Hub_Report :: wgpu.Hub_Report
Global_Report :: wgpu.Global_Report
Instance_Enumerate_Adapter_Options :: wgpu.Instance_Enumerate_Adapter_Options
Bind_Group_Layout_Entry_Extras :: wgpu.Bind_Group_Layout_Entry_Extras

Log_Callback :: wgpu.Log_Callback

Adapter_Type :: wgpu.Adapter_Type
Address_Mode :: wgpu.Address_Mode
Backend_Type :: wgpu.Backend_Type
Blend_Factor :: wgpu.Blend_Factor
Blend_Operation :: wgpu.Blend_Operation
Buffer_Binding_Type :: wgpu.Buffer_Binding_Type
Buffer_Map_Async_Status :: wgpu.Buffer_Map_Async_Status
Buffer_Map_State :: wgpu.Buffer_Map_State
Compare_Function :: wgpu.Compare_Function
Compilation_Info_Request_Status :: wgpu.Compilation_Info_Request_Status
Compilation_Message_Type :: wgpu.Compilation_Message_Type
Create_Pipeline_Async_Status :: wgpu.Create_Pipeline_Async_Status
Device_Lost_Reason :: wgpu.Device_Lost_Reason
Error_Filter :: wgpu.Error_Filter
Error_Type :: wgpu.Error_Type
// Feature_Name :: wgpu.Feature_Name
Filter_Mode :: wgpu.Filter_Mode

/*
Format of indices used with pipeline.

Corresponds to [WebGPU `GPUIndexFormat`](
https://gpuweb.github.io/gpuweb/#enumdef-gpuindexformat).
*/
Index_Format :: wgpu.Index_Format
Load_Op :: wgpu.Load_Op
Mipmap_Filter_Mode :: wgpu.Mipmap_Filter_Mode
Present_Mode :: wgpu.Present_Mode
// Primitive_Topology :: wgpu.Primitive_Topology
// Query_Type :: wgpu.Query_Type
Queue_Work_Done_Status :: wgpu.Queue_Work_Done_Status
Request_Adapter_Status :: wgpu.Request_Adapter_Status
Request_Device_Status :: wgpu.Request_Device_Status
SType :: wgpu.SType
Sampler_Binding_Type :: wgpu.Sampler_Binding_Type
Stencil_Operation :: wgpu.Stencil_Operation
Storage_Texture_Access :: wgpu.Storage_Texture_Access
Store_Op :: wgpu.Store_Op
Surface_Get_Current_Texture_Status :: wgpu.Surface_Get_Current_Texture_Status
Texture_Aspect :: wgpu.Texture_Aspect
Texture_Component_Type :: wgpu.Texture_Component_Type
Texture_Dimension :: wgpu.Texture_Dimension
Texture_Format :: wgpu.Texture_Format
Texture_Sample_Type :: wgpu.Texture_Sample_Type
Texture_View_Dimension :: wgpu.Texture_View_Dimension
Vertex_Format :: wgpu.Vertex_Format
Vertex_Step_Mode :: wgpu.Vertex_Step_Mode
Buffer_Usage :: wgpu.Buffer_Usage
Buffer_Usage_Flags :: wgpu.Buffer_Usage_Flags
Buffer_Usage_Flags_None :: wgpu.Buffer_Usage_Flags_None
Color_Write_Mask :: wgpu.Color_Write_Mask
Color_Write_Mask_Flags :: wgpu.Color_Write_Mask_Flags
Color_Write_Mask_None :: wgpu.Color_Write_Mask_None
Color_Write_Mask_All :: wgpu.Color_Write_Mask_All
Map_Mode :: wgpu.Map_Mode
Map_Mode_Flags :: wgpu.Map_Mode_Flags
Shader_Stage :: wgpu.Shader_Stage

Shader_Stage_Flags_None :: wgpu.Shader_Stage_Flags_None
Texture_Usage :: wgpu.Texture_Usage
Texture_Usage_Flags :: wgpu.Texture_Usage_Flags
Texture_Usage_Flags_None :: wgpu.Texture_Usage_Flags_None
Texture_Usage_Flags_All :: wgpu.Texture_Usage_Flags_All

Buffer_Map_Callback :: wgpu.Buffer_Map_Callback
Compilation_Info_Callback :: wgpu.Compilation_Info_Callback
Create_Compute_Pipeline_Async_Callback :: wgpu.Create_Compute_Pipeline_Async_Callback
Create_Render_Pipeline_Async_Callback :: wgpu.Create_Render_Pipeline_Async_Callback
Device_Lost_Callback :: wgpu.Device_Lost_Callback
Error_Callback :: wgpu.Error_Callback
Proc :: wgpu.Proc
Queue_Work_Done_Callback :: wgpu.Queue_Work_Done_Callback
Request_Adapter_Callback :: wgpu.Request_Adapter_Callback
Request_Device_Callback :: wgpu.Request_Device_Callback

Chained_Struct :: wgpu.Chained_Struct
Chained_Struct_Out :: wgpu.Chained_Struct_Out
Adapter_Info :: wgpu.Adapter_Properties
// Bind_Group_Entry :: wgpu.Bind_Group_Entry
Blend_Component :: wgpu.Blend_Component
Buffer_Binding_Layout :: wgpu.Buffer_Binding_Layout

Color :: wgpu.Color
Command_Buffer_Descriptor :: wgpu.Command_Buffer_Descriptor

Compilation_Message :: wgpu.Compilation_Message
Compute_Pass_Timestamp_Writes :: wgpu.Compute_Pass_Timestamp_Writes
Constant_Entry :: wgpu.Constant_Entry
Extent_3D :: wgpu.Extent_3D
// Limits :: wgpu.Limits
Multisample_State :: wgpu.Multisample_State
Origin_3D :: wgpu.Origin_3D
Primitive_Depth_Clip_Control :: wgpu.Primitive_Depth_Clip_Control
// Primitive_State :: wgpu.Primitive_State
Queue_Descriptor :: wgpu.Queue_Descriptor
Render_Bundle_Descriptor :: wgpu.Render_Bundle_Descriptor
Render_Pass_Depth_Stencil_Attachment :: wgpu.Render_Pass_Depth_Stencil_Attachment
// Render_Pass_Descriptor_Max_Draw_Count :: wgpu.Render_Pass_Descriptor_Max_Draw_Count
Render_Pass_Timestamp_Writes :: wgpu.Render_Pass_Timestamp_Writes
// Request_Adapter_Options :: wgpu.Request_Adapter_Options
Sampler_Binding_Layout :: wgpu.Sampler_Binding_Layout
Sampler_Descriptor :: wgpu.Sampler_Descriptor
Shader_Module_Compilation_Hint :: wgpu.Shader_Module_Compilation_Hint
Stencil_Face_State :: wgpu.Stencil_Face_State
Storage_Texture_Binding_Layout :: wgpu.Storage_Texture_Binding_Layout
Surface_Descriptor_From_Android_Native_Window :: wgpu.Surface_Descriptor_From_Android_Native_Window
Surface_Descriptor_From_Canvas_Html_Selector :: wgpu.Surface_Descriptor_From_Canvas_Html_Selector
Surface_Descriptor_From_Metal_Layer :: wgpu.Surface_Descriptor_From_Metal_Layer
Surface_Descriptor_From_Wayland_Surface :: wgpu.Surface_Descriptor_From_Wayland_Surface
Surface_Descriptor_From_Windows_HWND :: wgpu.Surface_Descriptor_From_Windows_HWND
Surface_Descriptor_From_Xcb_Window :: wgpu.Surface_Descriptor_From_Xcb_Window
Surface_Descriptor_From_Xlib_Window :: wgpu.Surface_Descriptor_From_Xlib_Window
Texture_Binding_Layout :: wgpu.Texture_Binding_Layout
// Surface_Texture :: wgpu.Surface_Texture
Texture_Data_Layout :: wgpu.Texture_Data_Layout
Texture_View_Descriptor :: wgpu.Texture_View_Descriptor
Vertex_Attribute :: wgpu.Vertex_Attribute
// Bind_Group_Layout_Entry :: wgpu.Bind_Group_Layout_Entry
Blend_State :: wgpu.Blend_State
Compilation_Info :: wgpu.Compilation_Info
Compute_Pass_Descriptor :: wgpu.Compute_Pass_Descriptor
Depth_Stencil_State :: wgpu.Depth_Stencil_State
Image_Copy_Buffer :: wgpu.Image_Copy_Buffer
Image_Copy_Texture :: wgpu.Image_Copy_Texture
Render_Pass_Color_Attachment :: wgpu.Render_Pass_Color_Attachment
Required_Limits :: wgpu.Required_Limits
Supported_Limits :: wgpu.Supported_Limits
// Texture_Descriptor :: wgpu.Texture_Descriptor
Color_Target_State :: wgpu.Color_Target_State
// Device_Descriptor :: wgpu.Device_Descriptor

Range :: struct($T: typeid) where intr.type_is_ordered(T) {
	start, end: T,
}

range_init :: proc "contextless" (
	$T: typeid,
	start, end: T,
) -> Range(T) where intr.type_is_ordered(T) {
	return Range(T){start, end}
}

/* Check if the range is empty */
range_is_empty :: proc "contextless" (r: Range($T)) -> bool {
	return r.start >= r.end
}

/* Check if a value is within the Range */
range_contains :: proc "contextless" (
	r: Range($T),
	value: T,
) -> bool {
	return value >= r.start && value < r.end
}

/* Get the length of the Range */
range_len :: proc "contextless" (r: Range($T)) -> T {
	if range_is_empty(r) do return 0
	return r.end - r.start
}

/* Iterator for the Range */
Range_Iterator :: struct($T: typeid) {
	current, end: T,
}

/* Create an iterator for the Range */
range_iterator :: proc "contextless" (r: Range($T)) -> Range_Iterator(T) {
	return Range_Iterator(T){r.start, r.end}
}

/* Get the next value from the iterator */
range_next :: proc "contextless" (
	it: ^Range_Iterator($T),
	value: ^T,
) -> bool {
	if it.current < it.end {
		value^ = it.current
		it.current += 1
		return true
	}
	return false
}

Texture_Resource :: struct {
	texture: Texture,
	sampler: Sampler,
	view:    Texture_View,
}
