package wgpu

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

NativeSType :: enum i32 {
	DeviceExtras               = 0x00030001,
	NativeLimits               = 0x00030002,
	PipelineLayoutExtras       = 0x00030003,
	ShaderModuleGLSLDescriptor = 0x00030004,
	InstanceExtras             = 0x00030006,
	BindGroupEntryExtras       = 0x00030007,
	BindGroupLayoutEntryExtras = 0x00030008,
	QuerySetDescriptorExtras   = 0x00030009,
	SurfaceConfigurationExtras = 0x0003000A,
}

NativeFeature :: enum i32 {
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

LogLevel :: enum i32 {
	Off   = 0x00000000,
	Error = 0x00000001,
	Warn  = 0x00000002,
	Info  = 0x00000003,
	Debug = 0x00000004,
	Trace = 0x00000005,
}

InstanceBackendBits :: enum u64 {
	Vulkan,
	GL,
	Metal,
	DX12,
	DX11,
	BrowserWebGPU,
}
InstanceBackend :: distinct bit_set[InstanceBackendBits;u64]
INSTANCE_BACKEND_ALL :: InstanceBackend{}
INSTANCE_BACKEND_PRIMARY :: InstanceBackend{.Vulkan, .Metal, .DX12, .BrowserWebGPU}
INSTANCE_BACKEND_SECONDARY :: InstanceBackend{.GL, .DX11}

InstanceFlagBits :: enum u64 {
	Debug,
	Validation,
	DiscardHalLabels,
}
InstanceFlag :: distinct bit_set[InstanceFlagBits;u64]
INSTANCE_FLAGS_DEFAULT :: InstanceFlag{}

Dx12Compiler :: enum i32 {
	Undefined = 0x00000000,
	Fxc       = 0x00000001,
	Dxc       = 0x00000002,
}

Gles3MinorVersion :: enum i32 {
	Automatic = 0x00000000,
	Version0  = 0x00000001,
	Version1  = 0x00000002,
	Version2  = 0x00000003,
}

PipelineStatisticName :: enum i32 {
	VertexShaderInvocations   = 0x00000000,
	ClipperInvocations        = 0x00000001,
	ClipperPrimitivesOut      = 0x00000002,
	FragmentShaderInvocations = 0x00000003,
	ComputeShaderInvocations  = 0x00000004,
}

NativeQueryType :: enum i32 {
	PipelineStatistics = 0x00030000,
}

InstanceExtras :: struct {
	chain:                ChainedStruct,
	backends:             InstanceBackend,
	flags:                InstanceFlag,
	dx12_shader_compiler: Dx12Compiler,
	gles3_minor_version:  Gles3MinorVersion,
	dxil_path:            StringView,
	dxc_path:             StringView,
}

DeviceExtras :: struct {
	chain:      ChainedStruct,
	trace_path: StringView,
}

NativeLimits :: struct {
	chain:                    ChainedStructOut,
	max_push_constant_size:   u32,
	max_non_sampler_bindings: u32,
}

@(private)
WGPUPushConstantRange :: struct {
	stages: ShaderStage,
	start:  u32,
	end:    u32,
}

PipelineLayoutExtras :: struct {
	chain:                     ChainedStruct,
	push_constant_range_count: uint,
	push_constant_ranges:      [^]WGPUPushConstantRange,
}

SubmissionIndex :: distinct u64

ShaderDefine :: struct {
	name:  StringView,
	value: StringView,
}

ShaderModuleGLSLDescriptor :: struct {
	chain:        ChainedStruct,
	stage:        ShaderStage,
	code:         StringView,
	define_count: u32,
	defines:      [^]ShaderDefine,
}

ShaderModuleDescriptorSpirV :: struct {
	label:       StringView,
	source_size: u32,
	source:      [^]u32,
}

RegistryReport :: struct {
	num_allocated:          uint,
	num_kept_from_user:     uint,
	num_released_from_user: uint,
	element_size:           uint,
}

HubReport :: struct {
	adapters:           RegistryReport,
	devices:            RegistryReport,
	queues:             RegistryReport,
	pipeline_layouts:   RegistryReport,
	shader_modules:     RegistryReport,
	bind_group_layouts: RegistryReport,
	bind_groups:        RegistryReport,
	command_buffers:    RegistryReport,
	render_bundles:     RegistryReport,
	render_pipelines:   RegistryReport,
	compute_pipelines:  RegistryReport,
	pipeline_caches:    RegistryReport,
	query_sets:         RegistryReport,
	buffers:            RegistryReport,
	textures:           RegistryReport,
	texture_views:      RegistryReport,
	samplers:           RegistryReport,
}

GlobalReport :: struct {
	surfaces: RegistryReport,
	hub:      HubReport,
}

InstanceEnumerateAdapterOptions :: struct {
	next_in_chain: ^ChainedStruct,
	backends:      InstanceBackend,
}

BindGroupEntryExtras :: struct {
	chain:              ChainedStruct,
	buffers:            [^]Buffer,
	buffer_count:       uint,
	samplers:           [^]Sampler,
	sampler_count:      uint,
	texture_views:      [^]TextureView,
	texture_view_count: uint,
}

BindGroupLayoutEntryExtras :: struct {
	chain: ChainedStruct,
	count: u32,
}

QuerySetDescriptorExtras :: struct {
	chain:                    ChainedStruct,
	pipeline_statistics:      [^]PipelineStatisticName,
	pipeline_statistic_count: uint,
}

SurfaceConfigurationExtras :: struct {
	chain:                         ChainedStruct,
	desired_maximum_frame_latency: u32,
}

LogCallback :: #type proc "c" (level: LogLevel, message: StringView, user_data: rawptr)

NativeTextureFormat :: enum i32 {
	R16Unorm    = 0x00030001,
	R16Snorm    = 0x00030002,
	Rg16Unorm   = 0x00030003,
	Rg16Snorm   = 0x00030004,
	Rgba16Unorm = 0x00030005,
	Rgba16Snorm = 0x00030006,
	NV12        = 0x00030007,
}

@(default_calling_convention = "c")
foreign wgpu_native {
	// odinfmt: disable
	wgpuGenerateReport :: proc(instance: Instance, report: ^GlobalReport) ---
	wgpuInstanceEnumerateAdapters :: proc(
		instance: Instance,
		options: ^InstanceEnumerateAdapterOptions,
		adapters: [^]Adapter) -> uint ---

	wgpuQueueSubmitForIndex :: proc(
		queue: Queue,
		command_count: uint,
		commands: [^]CommandBuffer) -> SubmissionIndex ---

	wgpuDevicePoll :: proc(
		device: Device,
		wait: b32,
		wrapped_submission_index: ^SubmissionIndex) -> b32 ---
	wgpuDeviceCreateShaderModuleSpirV :: proc(
		device: Device,
		#by_ptr descriptor: ShaderModuleDescriptorSpirV) -> ShaderModule ---

	wgpuSetLogCallback :: proc(callback: LogCallback, userdata: rawptr) ---

	wgpuSetLogLevel :: proc(level: LogLevel) ---

	wgpuGetVersion :: proc() -> u32 ---

	wgpuRenderPassEncoderSetPushConstants :: proc(
		encoder: RenderPass,
		stages: ShaderStage,
		offset: u32,
		size_bytes: u32,
		data: rawptr) ---
	wgpuComputePassEncoderSetPushConstants :: proc(
		encoder: ComputePass,
		offset: u32,
		size_bytes: u32,
		data: rawptr) ---

	wgpuRenderPassEncoderMultiDrawIndirect :: proc(
		encoder: RenderPass,
		buffer: Buffer,
		offset: u64,
		count: u32) ---
	wgpuRenderPassEncoderMultiDrawIndexedIndirect :: proc(
		encoder: RenderPass,
		buffer: Buffer,
		offset: u64,
		count: u32) ---

	wgpuRenderPassEncoderMultiDrawIndirectCount :: proc(
		encoder: RenderPass,
		buffer: Buffer,
		offset: u64,
		count_buffer: Buffer,
		count_buffer_offset: u64,
		max_count: u32) ---
	wgpuRenderPassEncoderMultiDrawIndexedIndirectCount :: proc(
		encoder: RenderPass,
		buffer: Buffer,
		offset: u64,
		count_buffer: Buffer,
		count_buffer_offset: u64,
		max_count: u32) ---

	wgpuComputePassEncoderBeginPipelineStatisticsQuery :: proc(
		compute_pass_encoder: ComputePass,
		query_set: QuerySet,
		query_index: u32) ---
	wgpuComputePassEncoderEndPipelineStatisticsQuery :: proc(
		compute_pass_encoder: ComputePass) ---
	wgpuRenderPassEncoderBeginPipelineStatisticsQuery :: proc(
		render_pass_encoder: RenderPass,
		query_set: QuerySet,
		query_index: u32) ---
	wgpuRenderPassEncoderEndPipelineStatisticsQuery :: proc(
		render_pass_encoder: RenderPass) ---

	wgpuComputePassEncoderWriteTimestamp :: proc(
		compute_pass_encoder: ComputePass,
		query_set: QuerySet,
		query_index: u32) ---
	wgpuRenderPassEncoderWriteTimestamp :: proc(
		render_pass_encoder: RenderPass,
		query_set: QuerySet,
		query_index: u32) ---
	// odinfmt: enable
}
