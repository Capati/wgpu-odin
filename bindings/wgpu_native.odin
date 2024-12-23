package wgpu_bindings

when ODIN_OS == .Windows {
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
} else when ODIN_OS == .Darwin || ODIN_OS == .Linux {
	when WGPU_USE_SYSTEM_LIBRARIES {
		foreign import wgpu_native "system:wgpu_native"
	} else {
		foreign import wgpu_native {LIB}
	}
} else {
	foreign import wgpu_native "system:wgpu_native"
}

Native_SType :: enum ENUM_SIZE {
	Device_Extras                  = 0x00030001,
	Required_Limits_Extras         = 0x00030002,
	Pipeline_Layout_Extras         = 0x00030003,
	Shader_Module_Glsl_Descriptor  = 0x00030004,
	Supported_Limits_Extras        = 0x00030005,
	Instance_Extras                = 0x00030006,
	Bind_Group_Entry_Extras        = 0x00030007,
	Bind_Group_Layout_Entry_Extras = 0x00030008,
	Query_Set_Descriptor_Extras    = 0x00030009,
	Surface_Configuration_Extras   = 0x0003000A,
}

Native_Feature :: enum ENUM_SIZE {
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

Log_Level :: enum ENUM_SIZE {
	Off,
	Error,
	Warn,
	Info,
	Debug,
	Trace,
}

Instance_Backend :: enum ENUM_SIZE {
	Vulkan,
	GL,
	Metal,
	DX12,
	DX11,
	Browser_WebGPU,
}
Instance_Backend_Flags :: distinct bit_set[Instance_Backend;FLAGS]
Instance_Backend_All :: Instance_Backend_Flags{
	.Vulkan,
	.GL,
	.Metal,
	.DX12,
	.DX11,
	.Browser_WebGPU,
}
Instance_Backend_Primary :: Instance_Backend_Flags{
	.Vulkan,
	.Metal,
	.DX12,
	.Browser_WebGPU,
}
Instance_Backend_Secondary :: Instance_Backend_Flags{.GL, .DX11}

Instance_Flag :: enum ENUM_SIZE {
	Debug,
	Validation,
	Discard_Hal_Labels,
}
Instance_Flags :: distinct bit_set[Instance_Flag; FLAGS]
Instance_Flags_Default :: Instance_Flags{}

Dx12_Compiler :: enum ENUM_SIZE {
	Undefined,
	Fxc,
	Dxc,
}

Gles3_Minor_Version :: enum ENUM_SIZE {
	Automatic,
	Version_0,
	Version_1,
	Version_2,
}

Pipeline_Statistic_Name :: enum ENUM_SIZE {
	Vertex_Shader_Invocations,
	Clipper_Invocations,
	Clipper_Primitives_Out,
	Fragment_Shader_Invocations,
	Compute_Shader_Invocations,
}

Native_Query_Type :: enum ENUM_SIZE {
	Pipeline_Statistics = 0x00030000,
}

Instance_Extras :: struct {
	using chain          : Chained_Struct,
	backends             : Instance_Backend_Flags,
	flags                : Instance_Flags,
	dx12_shader_compiler : Dx12_Compiler,
	gles3_minor_version  : Gles3_Minor_Version,
	dxil_path            : cstring,
	dxc_path             : cstring,
}

Device_Extras :: struct {
	using chain : Chained_Struct,
	trace_path  : cstring,
}

Native_Limits :: struct {
	max_push_constant_size   : u32,
	max_non_sampler_bindings : u32,
}

Required_Limits_Extras :: struct {
	using chain : Chained_Struct,
	limits      : Native_Limits,
}

Supported_Limits_Extras :: struct {
	using chain  : Chained_Struct_Out,
	limits       : Native_Limits,
}

Push_Constant_Range :: struct {
	stages : Shader_Stage_Flags,
	start  : u32,
	end    : u32,
}

Pipeline_Layout_Extras :: struct {
	using chain               : Chained_Struct,
	push_constant_range_count : uint,
	push_constant_ranges      : [^]Push_Constant_Range `fmt:"v,push_constant_range_count"`,
}

Submission_Index :: distinct u64

Wrapped_Submission_Index :: struct {
	queue            : Queue,
	submission_index : Submission_Index,
}

Shader_Define :: struct {
	name  : cstring,
	value : cstring,
}

Shader_Module_Glsl_Descriptor :: struct {
	using chain  : Chained_Struct,
	stage        : Shader_Stage,
	code         : cstring,
	define_count : u32,
	defines      : [^]Shader_Define `fmt:"v,define_count"`,
}

Registry_Report :: struct {
	num_allocated          : uint,
	num_kept_from_user     : uint,
	num_released_from_user : uint,
	num_error              : uint,
	element_size           : uint,
}

Hub_Report :: struct {
	adapters           : Registry_Report,
	devices            : Registry_Report,
	queues             : Registry_Report,
	pipeline_layouts   : Registry_Report,
	shader_modules     : Registry_Report,
	bind_group_layouts : Registry_Report,
	bind_groups        : Registry_Report,
	command_buffers    : Registry_Report,
	render_bundles     : Registry_Report,
	render_pipelines   : Registry_Report,
	compute_pipelines  : Registry_Report,
	query_sets         : Registry_Report,
	buffers            : Registry_Report,
	textures           : Registry_Report,
	texture_views      : Registry_Report,
	samplers           : Registry_Report,
}

Global_Report :: struct {
	surfaces     : Registry_Report,
	backend_type : Backend_Type,
	vulkan       : Hub_Report,
	metal        : Hub_Report,
	dx12         : Hub_Report,
	gl           : Hub_Report,
}

Instance_Enumerate_Adapter_Options :: struct {
	next_int_chain : ^Chained_Struct,
	backends       : Instance_Backend_Flags,
}

Bind_Group_Entry_Extras :: struct {
	using chain        : Chained_Struct,
	buffers            : [^]Buffer `fmt:"v,buffer_count"`,
	buffer_count       : uint,
	samplers           : [^]Sampler `fmt:"v,sampler_count"`,
	sampler_count      : uint,
	texture_views      : [^]Texture_View `fmt:"v,texture_view_count"`,
	texture_view_count : uint,
}

Bind_Group_Layout_Entry_Extras :: struct {
	using chain : Chained_Struct,
	count       : u32,
}

Query_Set_Descriptor_Extras :: struct {
	using chain              : Chained_Struct,
	pipeline_statistics      : [^]Pipeline_Statistic_Name `fmt:"v,pipeline_statistic_count"`,
	pipeline_statistic_count : uint,
}

Surface_Configuration_Extras :: struct {
	using chain                   : Chained_Struct,
	desired_maximum_frame_latency : u32,
}

Log_Callback :: #type proc "c" (level: Log_Level, message: cstring, user_data: rawptr)

Native_Texture_Format :: enum ENUM_SIZE {
	// From Features::TEXTURE_FORMAT_16BIT_NORM
	R16_Unorm    = 0x00030001,
	R16_Snorm    = 0x00030002,
	Rg16_Unorm   = 0x00030003,
	Rg16_Snorm   = 0x00030004,
	Rgba16_Unorm = 0x00030005,
	Rgba16_Snorm = 0x00030006,
	// From Features::TEXTURE_FORMAT_NV12
	NV12         = 0x00030007,
}

@(default_calling_convention = "c")
foreign wgpu_native {
	@(link_name = "wgpuGenerateReport")
	generate_report :: proc(instance: Instance, report: ^Global_Report) ---

	@(link_name = "wgpuInstanceEnumerateAdapters")
	instance_enumerate_adapters :: proc(
		instance: Instance,
		options: ^Instance_Enumerate_Adapter_Options,
		adapters: [^]Adapter,
	) -> uint ---

	@(link_name = "wgpuQueueSubmitForIndex")
	queue_submit_for_index :: proc(
		queue: Queue,
		command_count: uint,
		commands: [^]Command_Buffer,
	) -> Submission_Index ---

	@(link_name = "wgpuDevicePoll")
	device_poll :: proc(
		device: Device,
		wait: b32,
		wrapped_submission_index: ^Wrapped_Submission_Index,
	) -> b32 ---

	@(link_name = "wgpuSetLogCallback")
	set_log_callback :: proc(callback: Log_Callback, user_data: rawptr) ---

	@(link_name = "wgpuSetLogLevel")
	set_log_level :: proc(level: Log_Level) ---

	@(link_name = "wgpuGetVersion")
	get_version :: proc() -> u32 ---

	@(link_name = "wgpuRenderPassEncoderSetPushConstants")
	render_pass_encoder_set_push_constants :: proc(
		encoder: Render_Pass_Encoder,
		stages: Shader_Stage_Flags,
		offset: u32,
		size_bytes: u32,
		data: rawptr,
	) ---

	@(link_name = "wgpuRenderPassEncoderMultiDrawIndirect")
	render_pass_encoder_multi_draw_indirect :: proc(
		encoder: Render_Pass_Encoder,
		buffer: Buffer,
		offset: u64,
		count: u32,
	) ---

	@(link_name = "wgpuRenderPassEncoderMultiDrawIndexedIndirect")
	render_pass_encoder_multi_draw_indexed_indirect :: proc(
		encoder: Render_Pass_Encoder,
		buffer: Buffer,
		offset: u64,
		count: u32,
	) ---

	@(link_name = "wgpuRenderPassEncoderMultiDrawIndirectCount")
	render_pass_encoder_multi_draw_indirect_count :: proc(
		encoder: Render_Pass_Encoder,
		buffer: Buffer,
		offset: u64,
		count_buffer: Buffer,
		count_buffer_offset: u32,
		max_count: u32,
	) ---

	@(link_name = "wgpuRenderPassEncoderMultiDrawIndexedIndirectCount")
	render_pass_encoder_multi_draw_indexed_indirect_count :: proc(
		encoder: Render_Pass_Encoder,
		buffer: Buffer,
		offset: u64,
		count_buffer: Buffer,
		count_buffer_offset: u32,
		max_count: u32,
	) ---

	@(link_name = "wgpuComputePassEncoderBeginPipelineStatisticsQuery")
	compute_pass_encoder_begin_pipeline_statistics_query :: proc(
		compute_pass_encoder: Compute_Pass_Encoder,
		query_set: Query_Set,
		query_index: u32,
	) ---

	@(link_name = "wgpuComputePassEncoderEndPipelineStatisticsQuery")
	compute_pass_encoder_end_pipeline_statistics_query :: proc(
		compute_pass_encoder: Compute_Pass_Encoder,
	) ---

	@(link_name = "wgpuRenderPassEncoderBeginPipelineStatisticsQuery")
	render_pass_encoder_begin_pipeline_statistics_query :: proc(
		render_pass_encoder: Render_Pass_Encoder,
		query_set: Query_Set,
		query_index: u32,
	) ---

	@(link_name = "wgpuRenderPassEncoderEndPipelineStatisticsQuery")
	render_pass_encoder_end_pipeline_statistics_query :: proc(
		render_pass_encoder: Render_Pass_Encoder,
	) ---
}
