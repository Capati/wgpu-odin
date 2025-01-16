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
	wgpuCreateInstance :: proc(descriptor: ^WGPU_Instance_Descriptor) -> Instance ---
	wgpuGetInstanceCapabilities :: proc(capabilities: ^Instance_Capabilities) -> Status ---
	wgpuGetProcAddress :: proc(proc_name: String_View) -> Proc ---

	wgpuAdapterGetFeatures :: proc(adapter: Adapter, features: ^WGPU_Supported_Features) ---
	wgpuAdapterGetInfo :: proc(adapter: Adapter, info: ^WGPU_Adapter_Info) -> Status ---
	wgpuAdapterGetLimits :: proc(adapter: Adapter, limits: ^WGPU_Limits) -> Status ---
	wgpuAdapterHasFeature :: proc(adapter: Adapter, feature: Feature_Name) -> b32 ---
	wgpuAdapterRequestDevice :: proc(
		adapter: Adapter,
		descriptor: ^WGPU_Device_Descriptor,
		callback_info: Request_Device_Callback_Info) -> Future ---
	wgpuAdapterAddRef :: proc(adapter: Adapter) ---
	wgpuAdapterRelease :: proc(adapter: Adapter) ---

	wgpuAdapterInfoFreeMembers :: proc(adapter_info: WGPU_Adapter_Info) ---

	wgpuBindGroupSetLabel :: proc(bind_group: Bind_Group, label: String_View) ---
	wgpuBindGroupAddRef :: proc(bind_group: Bind_Group) ---
	wgpuBindGroupRelease :: proc(bind_group: Bind_Group) ---

	wgpuBindGroupLayoutSetLabel :: proc(bind_group_layout: Bind_Group_Layout, label: String_View) ---
	wgpuBindGroupLayoutAddRef :: proc(bind_group_layout: Bind_Group_Layout) ---
	wgpuBindGroupLayoutRelease :: proc(bind_group_layout: Bind_Group_Layout) ---

	wgpuBufferDestroy :: proc(buffer: Buffer) ---
	wgpuBufferGetConstMappedRange :: proc(buffer: Buffer, offset: uint, size: uint) -> rawptr ---
	wgpuBufferGetMapState :: proc(buffer: Buffer) -> Buffer_Map_State ---
	wgpuBufferGetMappedRange :: proc(buffer: Buffer, offset: uint, size: uint) -> rawptr ---
	wgpuBufferGetSize :: proc(buffer: Buffer) -> u64 ---
	wgpuBufferGetUsage :: proc(buffer: Buffer) -> Buffer_Usages ---
	wgpuBufferMapAsync :: proc(
		buffer: Buffer,
		mode: Map_Modes,
		offset: uint,
		size: uint,
		callback_info: Buffer_Map_Callback_Info) -> Future ---
	wgpuBufferSetLabel :: proc(buffer: Buffer, label: String_View) ---
	wgpuBufferUnmap :: proc(buffer: Buffer) ---
	wgpuBufferAddRef :: proc(buffer: Buffer) ---
	wgpuBufferRelease :: proc(buffer: Buffer) ---

	wgpuCommandBufferSetLabel :: proc(command_buffer: Command_Buffer, label: String_View) ---
	wgpuCommandBufferAddRef :: proc(command_buffer: Command_Buffer) ---
	wgpuCommandBufferRelease :: proc(command_buffer: Command_Buffer) ---

	wgpuCommandEncoderBeginComputePass :: proc(
		command_encoder: Command_Encoder,
		descriptor: ^WGPU_Compute_Pass_Descriptor) -> Compute_Pass ---
	wgpuCommandEncoderBeginRenderPass :: proc(
		command_encoder: Command_Encoder,
		#by_ptr descriptor: WGPU_Render_Pass_Descriptor) -> Render_Pass ---
	wgpuCommandEncoderClearBuffer :: proc(
		command_encoder: Command_Encoder,
		buffer: Buffer,
		offset: u64,
		size: u64) ---
	wgpuCommandEncoderCopyBufferToBuffer :: proc(
		command_encoder: Command_Encoder,
		source: Buffer,
		source_offset: u64,
		destination: Buffer,
		destination_offset: u64,
		size: u64) ---
	wgpuCommandEncoderCopyBufferToTexture :: proc(
		command_encoder: Command_Encoder,
		#by_ptr source: Texel_Copy_Buffer_Info,
		#by_ptr destination: Texel_Copy_Texture_Info,
		#by_ptr copy_size: Extent_3D) ---
	wgpuCommandEncoderCopyTextureToBuffer :: proc(
		command_encoder: Command_Encoder,
		#by_ptr source: Texel_Copy_Texture_Info,
		#by_ptr destination: Texel_Copy_Buffer_Info,
		#by_ptr copy_size: Extent_3D) ---
	wgpuCommandEncoderCopyTextureToTexture :: proc(
		command_encoder: Command_Encoder,
		#by_ptr source: Texel_Copy_Texture_Info,
		#by_ptr destination: Texel_Copy_Texture_Info,
		#by_ptr copy_size: Extent_3D) ---
	wgpuCommandEncoderFinish :: proc(
		command_encoder: Command_Encoder,
		descriptor: ^WGPU_Command_Buffer_Descriptor) -> Command_Buffer ---
	wgpuCommandEncoderInsertDebugMarker :: proc(
		command_encoder: Command_Encoder,
		marker_label: String_View) ---
	wgpuCommandEncoderPopDebugGroup :: proc(command_encoder: Command_Encoder) ---
	wgpuCommandEncoderPushDebugGroup :: proc(
		command_encoder: Command_Encoder,
		group_label: String_View) ---
	wgpuCommandEncoderResolveQuerySet :: proc(
		command_encoder: Command_Encoder,
		query_set: Query_Set,
		first_query: u32,
		query_count: u32,
		destination: Buffer,
		destination_offset: u64) ---
	wgpuCommandEncoderSetLabel :: proc(command_encoder: Command_Encoder, label: String_View) ---
	wgpuCommandEncoderWriteTimestamp :: proc(
		command_encoder: Command_Encoder,
		query_set: Query_Set,
		query_index: u32) ---
	wgpuCommandEncoderAddRef :: proc(command_encoder: Command_Encoder) ---
	wgpuCommandEncoderRelease :: proc(command_encoder: Command_Encoder) ---

	wgpuComputePassEncoderDispatchWorkgroups :: proc(
		compute_pass_encoder: Compute_Pass,
		x, y, z: u32) ---
	wgpuComputePassEncoderDispatchWorkgroupsIndirect :: proc(
		compute_pass_encoder: Compute_Pass,
		indirect_buffer: Buffer,
		indirect_offset: u64) ---
	wgpuComputePassEncoderEnd :: proc(compute_pass_encoder: Compute_Pass) ---
	wgpuComputePassEncoderInsertDebugMarker :: proc(
		compute_pass_encoder: Compute_Pass,
		marker_label: String_View) ---
	wgpuComputePassEncoderPopDebugGroup :: proc(compute_pass_encoder: Compute_Pass) ---
	wgpuComputePassEncoderPushDebugGroup :: proc(
		compute_pass_encoder: Compute_Pass,
		group_label: String_View) ---
	wgpuComputePassEncoderSetBindGroup :: proc(
		compute_pass_encoder: Compute_Pass,
		group_index: u32,
		group: Bind_Group,
		dynamic_offset_count: uint,
		dynamic_offsets: [^]u32) ---
	wgpuComputePassEncoderSetLabel :: proc(
		compute_pass_encoder: Compute_Pass,
		label: String_View) ---
	wgpuComputePassEncoderSetPipeline :: proc(
		compute_pass_encoder: Compute_Pass,
		pipeline: Compute_Pipeline) ---
	wgpuComputePassEncoderAddRef :: proc(compute_pass_encoder: Compute_Pass) ---
	wgpuComputePassEncoderRelease :: proc(compute_pass_encoder: Compute_Pass) ---

	wgpuComputePipelineGetBindGroupLayout :: proc(
		compute_pipeline: Compute_Pipeline,
		group_index: u32) -> Bind_Group_Layout ---
	wgpuComputePipelineSetLabel :: proc(compute_pipeline: Compute_Pipeline, label: String_View) ---
	wgpuComputePipelineAddRef :: proc(compute_pipeline: Compute_Pipeline) ---
	wgpuComputePipelineRelease :: proc(compute_pipeline: Compute_Pipeline) ---

	wgpuDeviceCreateBindGroup :: proc(
		device: Device,
		#by_ptr descriptor: WGPU_Bind_Group_Descriptor) -> Bind_Group ---
	wgpuDeviceCreateBindGroupLayout :: proc(
		device: Device,
		descriptor: ^WGPU_Bind_Group_Layout_Descriptor) -> Bind_Group_Layout ---
	wgpuDeviceCreateBuffer :: proc(
		device: Device,
		#by_ptr descriptor: WGPU_Buffer_Descriptor) -> Buffer ---
	wgpuDeviceCreateCommandEncoder :: proc(
		device: Device,
		descriptor: ^WGPU_Command_Encoder_Descriptor) -> Command_Encoder ---
	wgpuDeviceCreateComputePipeline :: proc(
		device: Device,
		#by_ptr descriptor: WGPU_Compute_Pipeline_Descriptor) -> Compute_Pipeline ---
	wgpuDeviceCreateComputePipelineAsync :: proc(
		device: Device,
		#by_ptr descriptor: WGPU_Compute_Pipeline_Descriptor,
		callback_info: Create_Compute_Pipeline_Async_Callback_Info) -> Future ---
	wgpuDeviceCreatePipelineLayout :: proc(
		device: Device,
		#by_ptr descriptor: WGPU_Pipeline_Layout_Descriptor) -> Pipeline_Layout ---
	wgpuDeviceCreateQuerySet :: proc(
		device: Device,
		#by_ptr descriptor: WGPU_Query_Set_Descriptor) -> Query_Set ---
	wgpuDeviceCreateRenderBundleEncoder :: proc(
		device: Device,
		#by_ptr descriptor: WGPU_Render_Bundle_Encoder_Descriptor) -> Render_Bundle_Encoder ---
	wgpuDeviceCreateRenderPipeline :: proc(
		device: Device,
		#by_ptr descriptor: WGPU_Render_Pipeline_Descriptor) -> Render_Pipeline ---
	wgpuDeviceCreateRenderPipelineAsync :: proc(
		device: Device,
		#by_ptr descriptor: WGPU_Render_Pipeline_Descriptor,
		callback_info: Create_Render_Pipeline_Async_Callback_Info) -> Future ---
	wgpuDeviceCreateSampler :: proc(
		device: Device,
		#by_ptr descriptor: WGPU_Sampler_Descriptor) -> Sampler ---
	wgpuDeviceCreateShaderModule :: proc(device: Device,
		#by_ptr descriptor: WGPU_Shader_Module_Descriptor) -> Shader_Module ---
	wgpuDeviceCreateTexture :: proc(device: Device,
		#by_ptr descriptor: WGPU_Texture_Descriptor) -> Texture ---
	wgpuDeviceDestroy :: proc(device: Device) ---
	wgpuDeviceGetAdapterInfo :: proc(device: Device) -> WGPU_Adapter_Info ---
	wgpuDeviceGetFeatures :: proc(device: Device, features: ^WGPU_Supported_Features) ---
	wgpuDeviceGetLimits :: proc(device: Device, limits: ^WGPU_Limits) -> Status ---
	wgpuDeviceGetLostFuture :: proc(device: Device) -> Future ---
	wgpuDeviceGetQueue :: proc(device: Device) -> Queue ---
	wgpuDeviceHasFeature :: proc(device: Device, feature: Feature_Name) -> b32 ---
	wgpuDevicePopErrorScope :: proc(
		device: Device,
		callback_info: Pop_Error_Scope_Callback_Info) -> Future ---
	wgpuDevicePushErrorScope :: proc(device: Device, filter: Error_Filter) ---
	wgpuDeviceSetLabel :: proc(device: Device, label: String_View) ---
	wgpuDeviceAddRef :: proc(device: Device) ---
	wgpuDeviceRelease :: proc(device: Device) ---

	wgpuInstanceCreateSurface :: proc(
		instance: Instance,
		#by_ptr descriptor: WGPU_Surface_Descriptor) -> Surface ---
	wgpuInstanceGetWGSLLanguageFeatures :: proc(
		instance: Instance,
		features: ^Supported_WGSL_Language_Features) -> Status ---
	wgpuInstanceHasWGSLLanguageFeature :: proc(
		instance: Instance,
		feature: WGSL_Language_Feature_Name) -> b32 ---
	wgpuInstanceProcessEvents :: proc(instance: Instance) ---
	wgpuInstanceRequestAdapter :: proc(
		instance: Instance,
		options: ^WGPU_Request_Adapter_Options,
		callback_info: Request_Adapter_Callback_Info) -> Future ---
	wgpuInstanceWaitAny :: proc(
		instance: Instance,
		future_count: uint,
		futures: ^Future_Wait_Info,
		timeout_ns: u64) -> Wait_Status ---
	wgpuInstanceAddRef :: proc(instance: Instance) ---
	wgpuInstanceRelease :: proc(instance: Instance) ---

	wgpuPipelineLayoutSetLabel :: proc(pipeline_layout: Pipeline_Layout, label: String_View) ---
	wgpuPipelineLayoutAddRef :: proc(pipeline_layout: Pipeline_Layout) ---
	wgpuPipelineLayoutRelease :: proc(pipeline_layout: Pipeline_Layout) ---

	wgpuQuerySetDestroy :: proc(query_set: Query_Set) ---
	wgpuQuerySetGetCount :: proc(query_set: Query_Set) -> u32 ---
	wgpuQuerySetGetType :: proc(query_set: Query_Set) -> Query_Type ---
	wgpuQuerySetSetLabel :: proc(query_set: Query_Set, label: String_View) ---
	wgpuQuerySetAddRef :: proc(query_set: Query_Set) ---
	wgpuQuerySetRelease :: proc(query_set: Query_Set) ---

	wgpuQueueOnSubmittedWorkDone :: proc(
		queue: Queue,
		callback_info: Queue_Work_Done_Callback_Info) -> Future ---
	wgpuQueueSetLabel :: proc(queue: Queue, label: String_View) ---
	wgpuQueueSubmit :: proc(queue: Queue, command_count: uint, commands: [^]Command_Buffer) ---
	wgpuQueueWriteBuffer :: proc(
		queue: Queue,
		buffer: Buffer,
		buffer_offset: u64,
		data: rawptr,
		size: uint) ---
	wgpuQueueWriteTexture :: proc(
		queue: Queue,
		#by_ptr destination: Texel_Copy_Texture_Info,
		data: rawptr,
		data_size: uint,
		#by_ptr data_layout: Texel_Copy_Buffer_Layout,
		#by_ptr write_size: Extent_3D) ---
	wgpuQueueAddRef :: proc(queue: Queue) ---
	wgpuQueueRelease :: proc(queue: Queue) ---

	wgpuRenderBundleSetLabel :: proc(render_bundle: Render_Bundle, label: String_View) ---
	wgpuRenderBundleAddRef :: proc(render_bundle: Render_Bundle) ---
	wgpuRenderBundleRelease :: proc(render_bundle: Render_Bundle) ---

	wgpuRenderBundleEncoderDraw :: proc(
		render_bundle_encoder: Render_Bundle_Encoder,
		vertex_count: u32,
		instance_count: u32,
		first_vertex: u32,
		first_instance: u32) ---
	wgpuRenderBundleEncoderDrawIndexed :: proc(
		render_bundle_encoder: Render_Bundle_Encoder,
		index_count: u32,
		instance_count: u32,
		first_index: u32,
		base_vertex: i32,
		first_instance: u32) ---
	wgpuRenderBundleEncoderDrawIndexedIndirect :: proc(
		render_bundle_encoder: Render_Bundle_Encoder,
		indirect_buffer: Buffer,
		indirect_offset: u64) ---
	wgpuRenderBundleEncoderDrawIndirect :: proc(
		render_bundle_encoder: Render_Bundle_Encoder,
		indirect_buffer: Buffer,
		indirect_offset: u64) ---
	wgpuRenderBundleEncoderFinish :: proc(
		render_bundle_encoder: Render_Bundle_Encoder,
		descriptor: ^WGPU_Render_Bundle_Descriptor) -> Render_Bundle ---
	wgpuRenderBundleEncoderInsertDebugMarker :: proc(
		render_bundle_encoder: Render_Bundle_Encoder, marker_label: String_View) ---
	wgpuRenderBundleEncoderPopDebugGroup :: proc(render_bundle_encoder: Render_Bundle_Encoder) ---
	wgpuRenderBundleEncoderPushDebugGroup :: proc(
		render_bundle_encoder: Render_Bundle_Encoder, group_label: String_View) ---
	wgpuRenderBundleEncoderSetBindGroup :: proc(
		render_bundle_encoder: Render_Bundle_Encoder,
		group_index: u32, group: Bind_Group, dynamic_offset_count: uint, dynamic_offsets: [^]u32) ---
	wgpuRenderBundleEncoderSetIndexBuffer :: proc(
		render_bundle_encoder: Render_Bundle_Encoder,
		buffer: Buffer,
		format: Index_Format,
		offset: u64, size: u64) ---
	wgpuRenderBundleEncoderSetLabel :: proc(
		render_bundle_encoder: Render_Bundle_Encoder, label: String_View) ---
	wgpuRenderBundleEncoderSetPipeline :: proc(
		render_bundle_encoder: Render_Bundle_Encoder,
		pipeline: Render_Pipeline) ---
	wgpuRenderBundleEncoderSetVertexBuffer :: proc(
		render_bundle_encoder: Render_Bundle_Encoder,
		slot: u32,
		buffer: Buffer,
		offset: u64,
		size: u64) ---
	wgpuRenderBundleEncoderAddRef :: proc(render_bundle_encoder: Render_Bundle_Encoder) ---
	wgpuRenderBundleEncoderRelease :: proc(render_bundle_encoder: Render_Bundle_Encoder) ---

	wgpuRenderPassEncoderBeginOcclusionQuery :: proc(
		render_pass_encoder: Render_Pass,
		query_index: u32) ---
	wgpuRenderPassEncoderDraw :: proc(
		render_pass_encoder: Render_Pass,
		vertex_count: u32,
		instance_count: u32,
		first_vertex: u32,
		first_instance: u32) ---
	wgpuRenderPassEncoderDrawIndexed :: proc(
		render_pass_encoder: Render_Pass,
		index_count: u32,
		instance_count: u32,
		first_index: u32,
		base_vertex: i32,
		first_instance: u32) ---
	wgpuRenderPassEncoderDrawIndexedIndirect :: proc(
		render_pass_encoder: Render_Pass,
		indirect_buffer: Buffer,
		indirect_offset: u64) ---
	wgpuRenderPassEncoderDrawIndirect :: proc(
		render_pass_encoder: Render_Pass,
		indirect_buffer: Buffer,
		indirect_offset: u64) ---
	wgpuRenderPassEncoderEnd :: proc(render_pass_encoder: Render_Pass) ---
	wgpuRenderPassEncoderEndOcclusionQuery :: proc(render_pass_encoder: Render_Pass) ---
	wgpuRenderPassEncoderExecuteBundles :: proc(
		render_pass_encoder: Render_Pass,
		bundle_count: uint,
		bundles: [^]Render_Bundle) ---
	wgpuRenderPassEncoderInsertDebugMarker :: proc(
		render_pass_encoder: Render_Pass,
		marker_label: String_View) ---
	wgpuRenderPassEncoderPopDebugGroup :: proc(render_pass_encoder: Render_Pass) ---
	wgpuRenderPassEncoderPushDebugGroup :: proc(
		render_pass_encoder: Render_Pass,
		group_label: String_View) ---
	wgpuRenderPassEncoderSetBindGroup :: proc(
		render_pass_encoder: Render_Pass,
		group_index: u32,
		group: Bind_Group,
		dynamic_offset_count: uint,
		dynamic_offsets: [^]u32) ---
	wgpuRenderPassEncoderSetBlendConstant :: proc(
		render_pass_encoder: Render_Pass, #by_ptr color: Color) ---
	wgpuRenderPassEncoderSetIndexBuffer :: proc(
		render_pass_encoder: Render_Pass,
		buffer: Buffer,
		format: Index_Format,
		offset: u64,
		size: u64) ---
	wgpuRenderPassEncoderSetLabel :: proc(
		render_pass_encoder: Render_Pass, label: String_View) ---
	wgpuRenderPassEncoderSetPipeline :: proc(
		render_pass_encoder: Render_Pass, pipeline: Render_Pipeline) ---
	wgpuRenderPassEncoderSetScissorRect :: proc(
		render_pass_encoder: Render_Pass, x: u32, y: u32, width: u32, height: u32) ---
	wgpuRenderPassEncoderSetStencilReference :: proc(
		render_pass_encoder: Render_Pass, reference: u32) ---
	wgpuRenderPassEncoderSetVertexBuffer :: proc(
		render_pass_encoder: Render_Pass,
		slot: u32,
		buffer: Buffer,
		offset: u64,
		size: u64) ---
	wgpuRenderPassEncoderSetViewport :: proc(
		render_pass_encoder: Render_Pass,
		x: f32,
		y: f32,
		width: f32,
		height: f32,
		min_depth: f32,
		max_depth: f32) ---
	wgpuRenderPassEncoderAddRef :: proc(render_pass_encoder: Render_Pass) ---
	wgpuRenderPassEncoderRelease :: proc(render_pass_encoder: Render_Pass) ---

	wgpuRenderPipelineGetBindGroupLayout :: proc(
		render_pipeline: Render_Pipeline,
		group_index: u32) -> Bind_Group_Layout ---
	wgpuRenderPipelineSetLabel :: proc(render_pipeline: Render_Pipeline, label: String_View) ---
	wgpuRenderPipelineAddRef :: proc(render_pipeline: Render_Pipeline) ---
	wgpuRenderPipelineRelease :: proc(render_pipeline: Render_Pipeline) ---

	wgpuSamplerSetLabel :: proc(sampler: Sampler, label: String_View) ---
	wgpuSamplerAddRef :: proc(sampler: Sampler) ---
	wgpuSamplerRelease :: proc(sampler: Sampler) ---

	wgpuShaderModuleGetCompilationInfo :: proc(
		shader_module: Shader_Module,
		callback_info: Compilation_Info_Callback_Info) -> Future ---
	wgpuShaderModuleSetLabel :: proc(shader_module: Shader_Module, label: String_View) ---
	wgpuShaderModuleAddRef :: proc(shader_module: Shader_Module) ---
	wgpuShaderModuleRelease :: proc(shader_module: Shader_Module) ---

	wgpuSupportedFeaturesFreeMembers :: proc(supported_features: WGPU_Supported_Features) ---

	wgpuSupportedWGSLLanguageFeaturesFreeMembers :: proc(
		supported_wgsl_language_features: Supported_WGSL_Language_Features) ---

	wgpuSurfaceConfigure :: proc(surface: Surface, #by_ptr config: WGPU_Surface_Configuration) ---
	wgpuSurfaceGetCapabilities :: proc(
		surface: Surface,
		adapter: Adapter,
		capabilities: ^WGPU_Surface_Capabilities) -> Status ---
	wgpuSurfaceGetCurrentTexture :: proc(surface: Surface, surface_texture: ^WGPU_Surface_Texture) ---
	wgpuSurfacePresent :: proc(surface: Surface) -> Status ---
	wgpuSurfaceSetLabel :: proc(surface: Surface, label: String_View) ---
	wgpuSurfaceUnconfigure :: proc(surface: Surface) ---
	wgpuSurfaceAddRef :: proc(surface: Surface) ---
	wgpuSurfaceRelease :: proc(surface: Surface) ---

	wgpuSurfaceCapabilitiesFreeMembers :: proc(surfaceCapabilities: WGPU_Surface_Capabilities) ---

	wgpuTextureCreateView :: proc(
		texture: Texture,
		descriptor: ^WGPU_Texture_View_Descriptor) -> Texture_View ---
	wgpuTextureDestroy :: proc(texture: Texture) ---
	wgpuTextureGetDepthOrArrayLayers :: proc(texture: Texture) -> u32 ---
	wgpuTextureGetDimension :: proc(texture: Texture) -> Texture_Dimension ---
	wgpuTextureGetFormat :: proc(texture: Texture) -> Texture_Format ---
	wgpuTextureGetHeight :: proc(texture: Texture) -> u32 ---
	wgpuTextureGetMipLevelCount :: proc(texture: Texture) -> u32 ---
	wgpuTextureGetSampleCount :: proc(texture: Texture) -> u32 ---
	wgpuTextureGetUsage :: proc(texture: Texture) -> Texture_Usages ---
	wgpuTextureGetWidth :: proc(texture: Texture) -> u32 ---
	wgpuTextureSetLabel :: proc(texture: Texture, label: String_View) ---
	wgpuTextureAddRef :: proc(texture: Texture) ---
	wgpuTextureRelease :: proc(texture: Texture) ---

	wgpuTextureViewSetLabel :: proc(texture_view: Texture_View, label: String_View) ---
	wgpuTextureViewAddRef :: proc(texture_view: Texture_View) ---
	wgpuTextureViewRelease :: proc(texture_view: Texture_View) ---
}

/* Native */
@(default_calling_convention = "c")
foreign _lib_ {
	wgpuGenerateReport :: proc(instance: Instance, report: ^Global_Report) ---
	wgpuInstanceEnumerateAdapters :: proc(
		instance: Instance,
		options: ^WGPU_Instance_Enumerate_Adapter_Options,
		adapters: [^]Adapter) -> uint ---

	wgpuQueueSubmitForIndex :: proc(
		queue: Queue,
		command_count: uint,
		commands: [^]Command_Buffer) -> Submission_Index ---

	wgpuDevicePoll :: proc(
		device: Device,
		wait: b32,
		wrapped_submission_index: ^Submission_Index) -> b32 ---
	wgpuDeviceCreateShaderModuleSpirV :: proc(
		device: Device,
		#by_ptr descriptor: WGPU_Shader_Module_Descriptor_SPIRV) -> Shader_Module ---

	wgpuSetLogCallback :: proc(callback: Log_Callback, userdata: rawptr) ---

	wgpuSetLogLevel :: proc(level: Log_Level) ---

	wgpuGetVersion :: proc() -> u32 ---

	wgpuRenderPassEncoderSetPushConstants :: proc(
		encoder: Render_Pass,
		stages: Shader_Stages,
		offset: u32,
		size_bytes: u32,
		data: rawptr) ---
	wgpuComputePassEncoderSetPushConstants :: proc(
		encoder: Compute_Pass,
		offset: u32,
		size_bytes: u32,
		data: rawptr) ---

	wgpuRenderPassEncoderMultiDrawIndirect :: proc(
		encoder: Render_Pass,
		buffer: Buffer,
		offset: u64,
		count: u32) ---
	wgpuRenderPassEncoderMultiDrawIndexedIndirect :: proc(
		encoder: Render_Pass,
		buffer: Buffer,
		offset: u64,
		count: u32) ---

	wgpuRenderPassEncoderMultiDrawIndirectCount :: proc(
		encoder: Render_Pass,
		buffer: Buffer,
		offset: u64,
		count_buffer: Buffer,
		count_buffer_offset: u64,
		max_count: u32) ---
	wgpuRenderPassEncoderMultiDrawIndexedIndirectCount :: proc(
		encoder: Render_Pass,
		buffer: Buffer,
		offset: u64,
		count_buffer: Buffer,
		count_buffer_offset: u64,
		max_count: u32) ---

	wgpuComputePassEncoderBeginPipelineStatisticsQuery :: proc(
		compute_pass_encoder: Compute_Pass,
		query_set: Query_Set,
		query_index: u32) ---
	wgpuComputePassEncoderEndPipelineStatisticsQuery :: proc(
		compute_pass_encoder: Compute_Pass) ---
	wgpuRenderPassEncoderBeginPipelineStatisticsQuery :: proc(
		render_pass_encoder: Render_Pass,
		query_set: Query_Set,
		query_index: u32) ---
	wgpuRenderPassEncoderEndPipelineStatisticsQuery :: proc(
		render_pass_encoder: Render_Pass) ---

	wgpuComputePassEncoderWriteTimestamp :: proc(
		compute_pass_encoder: Compute_Pass,
		query_set: Query_Set,
		query_index: u32) ---
	wgpuRenderPassEncoderWriteTimestamp :: proc(
		render_pass_encoder: Render_Pass,
		query_set: Query_Set,
		query_index: u32) ---
}
// odinfmt: enable
