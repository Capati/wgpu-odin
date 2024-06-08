package wgpu

// Package
import wgpu "../bindings"

// NOTE: Commented lines are wrapped types.


ARRAY_LAYER_COUNT_UNDEFINED :: wgpu.ARRAY_LAYER_COUNT_UNDEFINED
COPY_STRIDE_UNDEFINED :: wgpu.COPY_STRIDE_UNDEFINED
LIMIT_U32_UNDEFINED :: wgpu.LIMIT_U32_UNDEFINED
LIMIT_U64_UNDEFINED :: wgpu.LIMIT_U64_UNDEFINED
MIP_LEVEL_COUNT_UNDEFINED :: wgpu.MIP_LEVEL_COUNT_UNDEFINED
WGPU_QUERY_SET_INDEX_UNDEFINED :: wgpu.WGPU_QUERY_SET_INDEX_UNDEFINED
WHOLE_MAP_SIZE :: wgpu.WGPU_WHOLE_MAP_SIZE
WHOLE_SIZE :: wgpu.WHOLE_SIZE

Raw_Adapter :: wgpu.Adapter
Raw_Bind_Group :: wgpu.Bind_Group
Raw_Bind_Group_Layout :: wgpu.Bind_Group_Layout
Raw_Buffer :: wgpu.Buffer
Raw_Command_Buffer :: wgpu.Command_Buffer
Raw_Command_Encoder :: wgpu.Command_Encoder
Raw_Compute_Pass_Encoder :: wgpu.Compute_Pass_Encoder
Raw_Compute_Pipeline :: wgpu.Compute_Pipeline
Raw_Device :: wgpu.Device
Raw_Instance :: wgpu.Instance
Raw_Pipeline_Layout :: wgpu.Pipeline_Layout
Raw_Query_Set :: wgpu.Query_Set
Raw_Queue :: wgpu.Queue
Raw_Render_Bundle :: wgpu.Render_Bundle
Raw_Render_Bundle_Encoder :: wgpu.Render_Bundle_Encoder
Raw_Render_Pass_Encoder :: wgpu.Render_Pass_Encoder
Raw_Render_Pipeline :: wgpu.Render_Pipeline
Raw_Sampler :: wgpu.Sampler
Raw_Shader_Module :: wgpu.Shader_Module
Raw_Surface :: wgpu.Surface
Raw_Texture :: wgpu.Texture
Raw_Texture_View :: wgpu.Texture_View

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
Pipeline_Statistic_Name :: wgpu.Pipeline_Statistic_Name
Composite_Alpha_Mode :: wgpu.Composite_Alpha_Mode

Instance_Extras :: wgpu.Instance_Extras
Device_Extras :: wgpu.Device_Extras
Required_Limits_Extras :: wgpu.Required_Limits_Extras
// Surface_Configuration_Extras :: wgpu.Surface_Configuration_Extras
Supported_Limits_Extras :: wgpu.Supported_Limits_Extras
Push_Constant_Range :: wgpu.Push_Constant_Range
// Pipeline_Layout_Extras :: wgpu.Pipeline_Layout_Extras
Submission_Index :: wgpu.Submission_Index
Wrapped_Submission_Index :: wgpu.Wrapped_Submission_Index
Shader_Define :: wgpu.Shader_Define
Shader_Module_Glsl_Descriptor :: wgpu.Shader_Module_Glsl_Descriptor
Registry_Report :: wgpu.Registry_Report
Hub_Report :: wgpu.Hub_Report
Global_Report :: wgpu.Global_Report
Instance_Enumerate_Adapter_Options :: wgpu.Instance_Enumerate_Adapter_Options

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
Cull_Mode :: wgpu.Cull_Mode
Device_Lost_Reason :: wgpu.Device_Lost_Reason
Error_Filter :: wgpu.Error_Filter
Error_Type :: wgpu.Error_Type
// Feature_Name :: wgpu.Feature_Name
Filter_Mode :: wgpu.Filter_Mode
Front_Face :: wgpu.Front_Face
Index_Format :: wgpu.Index_Format
Load_Op :: wgpu.Load_Op
Mipmap_Filter_Mode :: wgpu.Mipmap_Filter_Mode
Power_Preference :: wgpu.Power_Preference
Present_Mode :: wgpu.Present_Mode
// Primitive_Topology :: wgpu.Primitive_Topology
Query_Type :: wgpu.Query_Type
Queue_Work_Done_Status :: wgpu.Queue_Work_Done_Status
Request_Adapter_Status :: wgpu.Request_Adapter_Status
Request_Device_Status :: wgpu.Request_Device_Status
SType :: wgpu.SType
Sampler_Binding_Type :: wgpu.Sampler_Binding_Type
Stencil_Operation :: wgpu.Stencil_Operation
Storage_Texture_Access :: wgpu.Storage_Texture_Access
Store_Op :: wgpu.Store_Op
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
Shader_Stage_Flags :: wgpu.Shader_Stage_Flags
Shader_Stage_Flags_None :: wgpu.Shader_Stage_Flags_None
Texture_Usage :: wgpu.Texture_Usage
Texture_Usage_Flags :: wgpu.Texture_Usage_Flags
Texture_Usage_Flags_None :: wgpu.Texture_Usage_Flags_None

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
Adapter_Properties :: wgpu.Adapter_Properties
// Bind_Group_Entry :: wgpu.Bind_Group_Entry
Blend_Component :: wgpu.Blend_Component
Buffer_Binding_Layout :: wgpu.Buffer_Binding_Layout
Buffer_Descriptor :: wgpu.Buffer_Descriptor
Color :: wgpu.Color
Command_Buffer_Descriptor :: wgpu.Command_Buffer_Descriptor
Command_Encoder_Descriptor :: wgpu.Command_Encoder_Descriptor
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
Request_Adapter_Options :: wgpu.Request_Adapter_Options
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
