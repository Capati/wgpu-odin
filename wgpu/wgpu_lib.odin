package wgpu

// odinfmt: disable
@(private) WGPU_SHARED :: #config(WGPU_SHARED, true)
@(private) WGPU_USE_SYSTEM_LIBRARIES :: #config(WGPU_USE_SYSTEM_LIBRARIES, false)

when ODIN_OS == .Windows {
	when ODIN_ARCH == .amd64 {
		ARCH :: "x86_64"
	} else when ODIN_ARCH == .i386 {
		ARCH :: "i386"
	} else {
		#panic("Unsupported WGPU Native architecture")
	}

	@(private) EXT  :: ".dll.lib" when WGPU_SHARED else ".lib"
	@(private) LIB  :: "lib/windows/" + ARCH + "/wgpu_native" + EXT

	when !#exists(LIB) {
		#panic("Could not find the compiled WGPU Native library at '" + #directory + LIB + "'")
	}

	when WGPU_SHARED {
		foreign import _lib_ {LIB}
	} else {
		foreign import _lib_ {
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
		foreign import _lib_ "system:wgpu_native"
	} else {
		when ODIN_ARCH == .amd64 {
			@(private) ARCH :: "x86_64"
		} else when ODIN_ARCH == .arm64 {
			@(private) ARCH :: "aarch64"
		} else {
			#panic("Unsupported WGPU Native architecture")
		}

		@(private) LIB  :: "lib/mac_os/" + ARCH + "/libwgpu_native.a"

		when !#exists(LIB) {
			#panic("Could not find the compiled WGPU Native library at '" + #directory + LIB + "'")
		}

		foreign import _lib_ {
			LIB,
			// "system:CoreFoundation.framework",
			// "system:QuartzCore.framework",
			// "system:Metal.framework",
		}
	}
} else when ODIN_OS == .Linux {
	when WGPU_USE_SYSTEM_LIBRARIES {
		foreign import _lib_ "system:wgpu_native"
	} else {
		when ODIN_ARCH == .amd64 {
			ARCH :: "x86_64"
		} else when ODIN_ARCH == .arm64 {
			ARCH :: "aarch64"
		} else {
			#panic("Unsupported WGPU Native architecture")
		}

		@(private) LIB  :: "lib/linux/" + ARCH + "/libwgpu_native.a"

		when !#exists(LIB) {
			#panic("Could not find the compiled WGPU Native library at '" + #directory + LIB + "'")
		}

		foreign import _lib_ {LIB}
	}
} else {
	foreign import _lib_ "system:wgpu_native"
}

/* WebGPU */
@(default_calling_convention = "c")
foreign _lib_ {
	wgpuCreateInstance :: proc(descriptor: ^WGPUInstanceDescriptor) -> Instance ---
	wgpuGetInstanceCapabilities :: proc(capabilities: ^InstanceCapabilities) -> Status ---
	wgpuGetProcAddress :: proc(proc_name: StringView) -> Proc ---

	wgpuAdapterGetFeatures :: proc(adapter: Adapter, features: ^SupportedFeatures) ---
	wgpuAdapterGetInfo :: proc(adapter: Adapter, info: ^WGPUAdapterInfo) -> Status ---
	wgpuAdapterGetLimits :: proc(adapter: Adapter, limits: ^WGPULimits) -> Status ---
	wgpuAdapterHasFeature :: proc(adapter: Adapter, feature: FeatureName) -> b32 ---
	wgpuAdapterRequestDevice :: proc(
		adapter: Adapter,
		descriptor: ^WGPUDeviceDescriptor,
		callback_info: RequestDeviceCallbackInfo) -> Future ---
	wgpuAdapterAddRef :: proc(adapter: Adapter) ---
	wgpuAdapterRelease :: proc(adapter: Adapter) ---

	wgpuAdapterInfoFreeMembers :: proc(adapter_info: WGPUAdapterInfo) ---

	wgpuBindGroupSetLabel :: proc(bind_group: BindGroup, label: StringView) ---
	wgpuBindGroupAddRef :: proc(bind_group: BindGroup) ---
	wgpuBindGroupRelease :: proc(bind_group: BindGroup) ---

	wgpuBindGroupLayoutSetLabel :: proc(bind_group_layout: BindGroupLayout, label: StringView) ---
	wgpuBindGroupLayoutAddRef :: proc(bind_group_layout: BindGroupLayout) ---
	wgpuBindGroupLayoutRelease :: proc(bind_group_layout: BindGroupLayout) ---

	wgpuBufferDestroy :: proc(buffer: Buffer) ---
	wgpuBufferGetConstMappedRange :: proc(buffer: Buffer, offset: uint, size: uint) -> rawptr ---
	wgpuBufferGetMapState :: proc(buffer: Buffer) -> BufferMapState ---
	wgpuBufferGetMappedRange :: proc(buffer: Buffer, offset: uint, size: uint) -> rawptr ---
	wgpuBufferGetSize :: proc(buffer: Buffer) -> u64 ---
	wgpuBufferGetUsage :: proc(buffer: Buffer) -> BufferUsages ---
	wgpuBufferMapAsync :: proc(
		buffer: Buffer,
		mode: MapMode,
		offset: uint,
		size: uint,
		callback_info: BufferMapCallbackInfo) -> Future ---
	wgpuBufferSetLabel :: proc(buffer: Buffer, label: StringView) ---
	wgpuBufferUnmap :: proc(buffer: Buffer) ---
	wgpuBufferAddRef :: proc(buffer: Buffer) ---
	wgpuBufferRelease :: proc(buffer: Buffer) ---

	wgpuCommandBufferSetLabel :: proc(command_buffer: CommandBuffer, label: StringView) ---
	wgpuCommandBufferAddRef :: proc(command_buffer: CommandBuffer) ---
	wgpuCommandBufferRelease :: proc(command_buffer: CommandBuffer) ---

	wgpuCommandEncoderBeginComputePass :: proc(
		command_encoder: CommandEncoder,
		descriptor: ^WGPUComputePassDescriptor) -> ComputePass ---
	wgpuCommandEncoderBeginRenderPass :: proc(
		command_encoder: CommandEncoder,
		#by_ptr descriptor: WGPURenderPassDescriptor) -> RenderPass ---
	wgpuCommandEncoderClearBuffer :: proc(
		command_encoder: CommandEncoder,
		buffer: Buffer,
		offset: u64,
		size: u64) ---
	wgpuCommandEncoderCopyBufferToBuffer :: proc(
		command_encoder: CommandEncoder,
		source: Buffer,
		source_offset: u64,
		destination: Buffer,
		destination_offset: u64,
		size: u64) ---
	wgpuCommandEncoderCopyBufferToTexture :: proc(
		command_encoder: CommandEncoder,
		#by_ptr source: TexelCopyBufferInfo,
		#by_ptr destination: TexelCopyTextureInfo,
		#by_ptr copy_size: Extent3D) ---
	wgpuCommandEncoderCopyTextureToBuffer :: proc(
		command_encoder: CommandEncoder,
		#by_ptr source: TexelCopyTextureInfo,
		#by_ptr destination: TexelCopyBufferInfo,
		#by_ptr copy_size: Extent3D) ---
	wgpuCommandEncoderCopyTextureToTexture :: proc(
		command_encoder: CommandEncoder,
		#by_ptr source: TexelCopyTextureInfo,
		#by_ptr destination: TexelCopyTextureInfo,
		#by_ptr copy_size: Extent3D) ---
	wgpuCommandEncoderFinish :: proc(
		command_encoder: CommandEncoder,
		descriptor: ^WGPUCommandBufferDescriptor) -> CommandBuffer ---
	wgpuCommandEncoderInsertDebugMarker :: proc(
		command_encoder: CommandEncoder,
		marker_label: StringView) ---
	wgpuCommandEncoderPopDebugGroup :: proc(command_encoder: CommandEncoder) ---
	wgpuCommandEncoderPushDebugGroup :: proc(
		command_encoder: CommandEncoder,
		group_label: StringView) ---
	wgpuCommandEncoderResolveQuerySet :: proc(
		command_encoder: CommandEncoder,
		query_set: QuerySet,
		first_query: u32,
		query_count: u32,
		destination: Buffer,
		destination_offset: u64) ---
	wgpuCommandEncoderSetLabel :: proc(command_encoder: CommandEncoder, label: StringView) ---
	wgpuCommandEncoderWriteTimestamp :: proc(
		command_encoder: CommandEncoder,
		query_set: QuerySet,
		query_index: u32) ---
	wgpuCommandEncoderAddRef :: proc(command_encoder: CommandEncoder) ---
	wgpuCommandEncoderRelease :: proc(command_encoder: CommandEncoder) ---

	wgpuComputePassEncoderDispatchWorkgroups :: proc(
		compute_pass_encoder: ComputePass,
		x, y, z: u32) ---
	wgpuComputePassEncoderDispatchWorkgroupsIndirect :: proc(
		compute_pass_encoder: ComputePass,
		indirect_buffer: Buffer,
		indirect_offset: u64) ---
	wgpuComputePassEncoderEnd :: proc(compute_pass_encoder: ComputePass) ---
	wgpuComputePassEncoderInsertDebugMarker :: proc(
		compute_pass_encoder: ComputePass,
		marker_label: StringView) ---
	wgpuComputePassEncoderPopDebugGroup :: proc(compute_pass_encoder: ComputePass) ---
	wgpuComputePassEncoderPushDebugGroup :: proc(
		compute_pass_encoder: ComputePass,
		group_label: StringView) ---
	wgpuComputePassEncoderSetBindGroup :: proc(
		compute_pass_encoder: ComputePass,
		group_index: u32,
		group: BindGroup,
		dynamic_offset_count: uint,
		dynamic_offsets: [^]u32) ---
	wgpuComputePassEncoderSetLabel :: proc(
		compute_pass_encoder: ComputePass,
		label: StringView) ---
	wgpuComputePassEncoderSetPipeline :: proc(
		compute_pass_encoder: ComputePass,
		pipeline: ComputePipeline) ---
	wgpuComputePassEncoderAddRef :: proc(compute_pass_encoder: ComputePass) ---
	wgpuComputePassEncoderRelease :: proc(compute_pass_encoder: ComputePass) ---

	wgpuComputePipelineGetBindGroupLayout :: proc(
		compute_pipeline: ComputePipeline,
		group_index: u32) -> BindGroupLayout ---
	wgpuComputePipelineSetLabel :: proc(compute_pipeline: ComputePipeline, label: StringView) ---
	wgpuComputePipelineAddRef :: proc(compute_pipeline: ComputePipeline) ---
	wgpuComputePipelineRelease :: proc(compute_pipeline: ComputePipeline) ---

	wgpuDeviceCreateBindGroup :: proc(
		device: Device,
		#by_ptr descriptor: WGPUBindGroupDescriptor) -> BindGroup ---
	wgpuDeviceCreateBindGroupLayout :: proc(
		device: Device,
		descriptor: ^WGPUBindGroupLayoutDescriptor) -> BindGroupLayout ---
	wgpuDeviceCreateBuffer :: proc(
		device: Device,
		#by_ptr descriptor: WGPUBufferDescriptor) -> Buffer ---
	wgpuDeviceCreateCommandEncoder :: proc(
		device: Device,
		descriptor: ^WGPUCommandEncoderDescriptor) -> CommandEncoder ---
	wgpuDeviceCreateComputePipeline :: proc(
		device: Device,
		#by_ptr descriptor: WGPUComputePipelineDescriptor) -> ComputePipeline ---
	wgpuDeviceCreateComputePipelineAsync :: proc(
		device: Device,
		#by_ptr descriptor: WGPUComputePipelineDescriptor,
		callback_info: CreateComputePipelineAsyncCallbackInfo) -> Future ---
	wgpuDeviceCreatePipelineLayout :: proc(
		device: Device,
		#by_ptr descriptor: WGPUPipelineLayoutDescriptor) -> PipelineLayout ---
	wgpuDeviceCreateQuerySet :: proc(
		device: Device,
		#by_ptr descriptor: WGPUQuerySetDescriptor) -> QuerySet ---
	wgpuDeviceCreateRenderBundleEncoder :: proc(
		device: Device,
		#by_ptr descriptor: WGPURenderBundleEncoderDescriptor) -> RenderBundleEncoder ---
	wgpuDeviceCreateRenderPipeline :: proc(
		device: Device,
		#by_ptr descriptor: WGPURenderPipelineDescriptor) -> RenderPipeline ---
	wgpuDeviceCreateRenderPipelineAsync :: proc(
		device: Device,
		#by_ptr descriptor: WGPURenderPipelineDescriptor,
		callback_info: CreateRenderPipelineAsyncCallbackInfo) -> Future ---
	wgpuDeviceCreateSampler :: proc(
		device: Device,
		#by_ptr descriptor: WGPUSamplerDescriptor) -> Sampler ---
	wgpuDeviceCreateShaderModule :: proc(device: Device,
		#by_ptr descriptor: WGPUShaderModuleDescriptor) -> ShaderModule ---
	wgpuDeviceCreateTexture :: proc(device: Device,
		#by_ptr descriptor: WGPUTextureDescriptor) -> Texture ---
	wgpuDeviceDestroy :: proc(device: Device) ---
	wgpuDeviceGetAdapterInfo :: proc(device: Device) -> WGPUAdapterInfo ---
	wgpuDeviceGetFeatures :: proc(device: Device, features: ^SupportedFeatures) ---
	wgpuDeviceGetLimits :: proc(device: Device, limits: ^WGPULimits) -> Status ---
	wgpuDeviceGetLostFuture :: proc(device: Device) -> Future ---
	wgpuDeviceGetQueue :: proc(device: Device) -> Queue ---
	wgpuDeviceHasFeature :: proc(device: Device, feature: FeatureName) -> b32 ---
	wgpuDevicePopErrorScope :: proc(
		device: Device,
		callback_info: PopErrorScopeCallbackInfo) -> Future ---
	wgpuDevicePushErrorScope :: proc(device: Device, filter: ErrorFilter) ---
	wgpuDeviceSetLabel :: proc(device: Device, label: StringView) ---
	wgpuDeviceAddRef :: proc(device: Device) ---
	wgpuDeviceRelease :: proc(device: Device) ---

	wgpuInstanceCreateSurface :: proc(
		instance: Instance,
		#by_ptr descriptor: WGPUSurfaceDescriptor) -> Surface ---
	wgpuInstanceGetWGSLLanguageFeatures :: proc(
		instance: Instance,
		features: ^SupportedWGSLLanguageFeatures) -> Status ---
	wgpuInstanceHasWGSLLanguageFeature :: proc(
		instance: Instance,
		feature: WGSLLanguageFeatureName) -> b32 ---
	wgpuInstanceProcessEvents :: proc(instance: Instance) ---
	wgpuInstanceRequestAdapter :: proc(
		instance: Instance,
		options: ^WGPURequestAdapterOptions,
		callback_info: RequestAdapterCallbackInfo) -> Future ---
	wgpuInstanceWaitAny :: proc(
		instance: Instance,
		future_count: uint,
		futures: ^FutureWaitInfo,
		timeout_ns: u64) -> WaitStatus ---
	wgpuInstanceAddRef :: proc(instance: Instance) ---
	wgpuInstanceRelease :: proc(instance: Instance) ---

	wgpuPipelineLayoutSetLabel :: proc(pipeline_layout: PipelineLayout, label: StringView) ---
	wgpuPipelineLayoutAddRef :: proc(pipeline_layout: PipelineLayout) ---
	wgpuPipelineLayoutRelease :: proc(pipeline_layout: PipelineLayout) ---

	wgpuQuerySetDestroy :: proc(query_set: QuerySet) ---
	wgpuQuerySetGetCount :: proc(query_set: QuerySet) -> u32 ---
	wgpuQuerySetGetType :: proc(query_set: QuerySet) -> QueryType ---
	wgpuQuerySetSetLabel :: proc(query_set: QuerySet, label: StringView) ---
	wgpuQuerySetAddRef :: proc(query_set: QuerySet) ---
	wgpuQuerySetRelease :: proc(query_set: QuerySet) ---

	wgpuQueueOnSubmittedWorkDone :: proc(
		queue: Queue,
		callback_info: QueueWorkDoneCallbackInfo) -> Future ---
	wgpuQueueSetLabel :: proc(queue: Queue, label: StringView) ---
	wgpuQueueSubmit :: proc(queue: Queue, command_count: uint, commands: [^]CommandBuffer) ---
	wgpuQueueWriteBuffer :: proc(
		queue: Queue,
		buffer: Buffer,
		buffer_offset: u64,
		data: rawptr,
		size: uint) ---
	wgpuQueueWriteTexture :: proc(
		queue: Queue,
		#by_ptr destination: TexelCopyTextureInfo,
		data: rawptr,
		data_size: uint,
		#by_ptr data_layout: TexelCopyBufferLayout,
		#by_ptr write_size: Extent3D) ---
	wgpuQueueAddRef :: proc(queue: Queue) ---
	wgpuQueueRelease :: proc(queue: Queue) ---

	wgpuRenderBundleSetLabel :: proc(render_bundle: RenderBundle, label: StringView) ---
	wgpuRenderBundleAddRef :: proc(render_bundle: RenderBundle) ---
	wgpuRenderBundleRelease :: proc(render_bundle: RenderBundle) ---

	wgpuRenderBundleEncoderDraw :: proc(
		render_bundle_encoder: RenderBundleEncoder,
		vertex_count: u32,
		instance_count: u32,
		first_vertex: u32,
		first_instance: u32) ---
	wgpuRenderBundleEncoderDrawIndexed :: proc(
		render_bundle_encoder: RenderBundleEncoder,
		index_count: u32,
		instance_count: u32,
		first_index: u32,
		base_vertex: i32,
		first_instance: u32) ---
	wgpuRenderBundleEncoderDrawIndexedIndirect :: proc(
		render_bundle_encoder: RenderBundleEncoder,
		indirect_buffer: Buffer,
		indirect_offset: u64) ---
	wgpuRenderBundleEncoderDrawIndirect :: proc(
		render_bundle_encoder: RenderBundleEncoder,
		indirect_buffer: Buffer,
		indirect_offset: u64) ---
	wgpuRenderBundleEncoderFinish :: proc(
		render_bundle_encoder: RenderBundleEncoder,
		descriptor: ^WGPURenderBundleDescriptor) -> RenderBundle ---
	wgpuRenderBundleEncoderInsertDebugMarker :: proc(
		render_bundle_encoder: RenderBundleEncoder, marker_label: StringView) ---
	wgpuRenderBundleEncoderPopDebugGroup :: proc(render_bundle_encoder: RenderBundleEncoder) ---
	wgpuRenderBundleEncoderPushDebugGroup :: proc(
		render_bundle_encoder: RenderBundleEncoder, group_label: StringView) ---
	wgpuRenderBundleEncoderSetBindGroup :: proc(
		render_bundle_encoder: RenderBundleEncoder,
		group_index: u32, group: BindGroup, dynamic_offset_count: uint, dynamic_offsets: [^]u32) ---
	wgpuRenderBundleEncoderSetIndexBuffer :: proc(
		render_bundle_encoder: RenderBundleEncoder,
		buffer: Buffer,
		format: IndexFormat,
		offset: u64, size: u64) ---
	wgpuRenderBundleEncoderSetLabel :: proc(
		render_bundle_encoder: RenderBundleEncoder, label: StringView) ---
	wgpuRenderBundleEncoderSetPipeline :: proc(
		render_bundle_encoder: RenderBundleEncoder,
		pipeline: RenderPipeline) ---
	wgpuRenderBundleEncoderSetVertexBuffer :: proc(
		render_bundle_encoder: RenderBundleEncoder,
		slot: u32,
		buffer: Buffer,
		offset: u64,
		size: u64) ---
	wgpuRenderBundleEncoderAddRef :: proc(render_bundle_encoder: RenderBundleEncoder) ---
	wgpuRenderBundleEncoderRelease :: proc(render_bundle_encoder: RenderBundleEncoder) ---

	wgpuRenderPassEncoderBeginOcclusionQuery :: proc(
		render_pass_encoder: RenderPass,
		query_index: u32) ---
	wgpuRenderPassEncoderDraw :: proc(
		render_pass_encoder: RenderPass,
		vertex_count: u32,
		instance_count: u32,
		first_vertex: u32,
		first_instance: u32) ---
	wgpuRenderPassEncoderDrawIndexed :: proc(
		render_pass_encoder: RenderPass,
		index_count: u32,
		instance_count: u32,
		first_index: u32,
		base_vertex: i32,
		first_instance: u32) ---
	wgpuRenderPassEncoderDrawIndexedIndirect :: proc(
		render_pass_encoder: RenderPass,
		indirect_buffer: Buffer,
		indirect_offset: u64) ---
	wgpuRenderPassEncoderDrawIndirect :: proc(
		render_pass_encoder: RenderPass,
		indirect_buffer: Buffer,
		indirect_offset: u64) ---
	wgpuRenderPassEncoderEnd :: proc(render_pass_encoder: RenderPass) ---
	wgpuRenderPassEncoderEndOcclusionQuery :: proc(render_pass_encoder: RenderPass) ---
	wgpuRenderPassEncoderExecuteBundles :: proc(
		render_pass_encoder: RenderPass,
		bundle_count: uint,
		bundles: [^]RenderBundle) ---
	wgpuRenderPassEncoderInsertDebugMarker :: proc(
		render_pass_encoder: RenderPass,
		marker_label: StringView) ---
	wgpuRenderPassEncoderPopDebugGroup :: proc(render_pass_encoder: RenderPass) ---
	wgpuRenderPassEncoderPushDebugGroup :: proc(
		render_pass_encoder: RenderPass,
		group_label: StringView) ---
	wgpuRenderPassEncoderSetBindGroup :: proc(
		render_pass_encoder: RenderPass,
		group_index: u32,
		group: BindGroup,
		dynamic_offset_count: uint,
		dynamic_offsets: [^]u32) ---
	wgpuRenderPassEncoderSetBlendConstant :: proc(
		render_pass_encoder: RenderPass, #by_ptr color: Color) ---
	wgpuRenderPassEncoderSetIndexBuffer :: proc(
		render_pass_encoder: RenderPass,
		buffer: Buffer,
		format: IndexFormat,
		offset: u64,
		size: u64) ---
	wgpuRenderPassEncoderSetLabel :: proc(
		render_pass_encoder: RenderPass, label: StringView) ---
	wgpuRenderPassEncoderSetPipeline :: proc(
		render_pass_encoder: RenderPass, pipeline: RenderPipeline) ---
	wgpuRenderPassEncoderSetScissorRect :: proc(
		render_pass_encoder: RenderPass, x: u32, y: u32, width: u32, height: u32) ---
	wgpuRenderPassEncoderSetStencilReference :: proc(
		render_pass_encoder: RenderPass, reference: u32) ---
	wgpuRenderPassEncoderSetVertexBuffer :: proc(
		render_pass_encoder: RenderPass,
		slot: u32,
		buffer: Buffer,
		offset: u64,
		size: u64) ---
	wgpuRenderPassEncoderSetViewport :: proc(
		render_pass_encoder: RenderPass,
		x: f32,
		y: f32,
		width: f32,
		height: f32,
		min_depth: f32,
		max_depth: f32) ---
	wgpuRenderPassEncoderAddRef :: proc(render_pass_encoder: RenderPass) ---
	wgpuRenderPassEncoderRelease :: proc(render_pass_encoder: RenderPass) ---

	wgpuRenderPipelineGetBindGroupLayout :: proc(
		render_pipeline: RenderPipeline,
		group_index: u32) -> BindGroupLayout ---
	wgpuRenderPipelineSetLabel :: proc(render_pipeline: RenderPipeline, label: StringView) ---
	wgpuRenderPipelineAddRef :: proc(render_pipeline: RenderPipeline) ---
	wgpuRenderPipelineRelease :: proc(render_pipeline: RenderPipeline) ---

	wgpuSamplerSetLabel :: proc(sampler: Sampler, label: StringView) ---
	wgpuSamplerAddRef :: proc(sampler: Sampler) ---
	wgpuSamplerRelease :: proc(sampler: Sampler) ---

	wgpuShaderModuleGetCompilationInfo :: proc(
		shader_module: ShaderModule,
		callback_info: CompilationInfoCallbackInfo) -> Future ---
	wgpuShaderModuleSetLabel :: proc(shader_module: ShaderModule, label: StringView) ---
	wgpuShaderModuleAddRef :: proc(shader_module: ShaderModule) ---
	wgpuShaderModuleRelease :: proc(shader_module: ShaderModule) ---

	wgpuSupportedFeaturesFreeMembers :: proc(supported_features: SupportedFeatures) ---

	wgpuSupportedWGSLLanguageFeaturesFreeMembers :: proc(
		supported_wgsl_language_features: SupportedWGSLLanguageFeatures) ---

	wgpuSurfaceConfigure :: proc(surface: Surface, #by_ptr config: WGPUSurfaceConfiguration) ---
	wgpuSurfaceGetCapabilities :: proc(
		surface: Surface,
		adapter: Adapter,
		capabilities: ^WGPUSurfaceCapabilities) -> Status ---
	wgpuSurfaceGetCurrentTexture :: proc(surface: Surface, surface_texture: ^WGPUSurfaceTexture) ---
	wgpuSurfacePresent :: proc(surface: Surface) -> Status ---
	wgpuSurfaceSetLabel :: proc(surface: Surface, label: StringView) ---
	wgpuSurfaceUnconfigure :: proc(surface: Surface) ---
	wgpuSurfaceAddRef :: proc(surface: Surface) ---
	wgpuSurfaceRelease :: proc(surface: Surface) ---

	wgpuSurfaceCapabilitiesFreeMembers :: proc(surfaceCapabilities: WGPUSurfaceCapabilities) ---

	wgpuTextureCreateView :: proc(
		texture: Texture,
		descriptor: ^WGPUTextureViewDescriptor) -> TextureView ---
	wgpuTextureDestroy :: proc(texture: Texture) ---
	wgpuTextureGetDepthOrArrayLayers :: proc(texture: Texture) -> u32 ---
	wgpuTextureGetDimension :: proc(texture: Texture) -> TextureDimension ---
	wgpuTextureGetFormat :: proc(texture: Texture) -> TextureFormat ---
	wgpuTextureGetHeight :: proc(texture: Texture) -> u32 ---
	wgpuTextureGetMipLevelCount :: proc(texture: Texture) -> u32 ---
	wgpuTextureGetSampleCount :: proc(texture: Texture) -> u32 ---
	wgpuTextureGetUsage :: proc(texture: Texture) -> TextureUsages ---
	wgpuTextureGetWidth :: proc(texture: Texture) -> u32 ---
	wgpuTextureSetLabel :: proc(texture: Texture, label: StringView) ---
	wgpuTextureAddRef :: proc(texture: Texture) ---
	wgpuTextureRelease :: proc(texture: Texture) ---

	wgpuTextureViewSetLabel :: proc(texture_view: TextureView, label: StringView) ---
	wgpuTextureViewAddRef :: proc(texture_view: TextureView) ---
	wgpuTextureViewRelease :: proc(texture_view: TextureView) ---
}

/* Native */
@(default_calling_convention = "c")
foreign _lib_ {
	wgpuGenerateReport :: proc(instance: Instance, report: ^GlobalReport) ---
	wgpuInstanceEnumerateAdapters :: proc(
		instance: Instance,
		options: ^WGPUInstanceEnumerateAdapterOptions,
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
		#by_ptr descriptor: WGPUShaderModuleDescriptorSpirV) -> ShaderModule ---

	wgpuSetLogCallback :: proc(callback: LogCallback, userdata: rawptr) ---

	wgpuSetLogLevel :: proc(level: LogLevel) ---

	wgpuGetVersion :: proc() -> u32 ---

	wgpuRenderPassEncoderSetPushConstants :: proc(
		encoder: RenderPass,
		stages: ShaderStages,
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
}
// odinfmt: enable
