package wgpu_bindings

import "core:c"

when ODIN_OS == .Windows {
    foreign import wgpu_native "./lib/windows-x86_64/wgpu_native.dll.lib"
} else when ODIN_OS == .Darwin {
    when #config(WGPU_USE_SYSTEM_LIBRARIES, false) {
        foreign import wgpu_native "system:wgpu_native"
    } else {
        foreign import wgpu_native "/libs/wgpu/bindings/lib/macos-x86_64/libwgpu.dylib"
    }
} else when ODIN_OS == .Linux {
    when #config(WGPU_USE_SYSTEM_LIBRARIES, false) {
        foreign import wgpu_native "system:wgpu_native"
    } else {
        foreign import wgpu_native "/libs/wgpu/bindings/lib/linux-x86_64/libwgpu_native.so"
    }
} else {
    foreign import wgpu_native "system:wgpu_native"
}

ARRAY_LAYER_COUNT_UNDEFINED: c.ulong : 0xffffffff
COPY_STRIDE_UNDEFINED: c.ulong : 0xffffffff
LIMIT_U32_UNDEFINED: c.ulong : 0xffffffff
LIMIT_U64_UNDEFINED: c.ulonglong : 0xffffffffffffffff
MIP_LEVEL_COUNT_UNDEFINED: c.ulong : 0xffffffff
WHOLE_MAP_SIZE :: c.SIZE_MAX
WHOLE_SIZE: c.ulonglong : 0xffffffffffffffff

Flags :: c.uint32_t

Handle :: rawptr

Adapter :: distinct Handle
Bind_Group :: distinct Handle
Bind_Group_Layout :: distinct Handle
Buffer :: distinct Handle
Command_Buffer :: distinct Handle
Command_Encoder :: distinct Handle
Compute_Pass_Encoder :: distinct Handle
Compute_Pipeline :: distinct Handle
Device :: distinct Handle
Instance :: distinct Handle
Pipeline_Layout :: distinct Handle
Query_Set :: distinct Handle
Queue :: distinct Handle
Render_Bundle :: distinct Handle
Render_Bundle_Encoder :: distinct Handle
Render_Pass_Encoder :: distinct Handle
Render_Pipeline :: distinct Handle
Sampler :: distinct Handle
Shader_Module :: distinct Handle
Surface :: distinct Handle
Swap_Chain :: distinct Handle
Texture :: distinct Handle
Texture_View :: distinct Handle

foreign wgpu_native {
    @(link_name = "wgpuCreateInstance")
    create_instance :: proc(descriptor: ^Instance_Descriptor) -> Instance ---
    @(link_name = "wgpuGetProcAddress")
    get_proc_address :: proc(device: Device, proc_name: cstring) -> Proc ---

    // Methods of Adapter


    @(link_name = "wgpuAdapterEnumerateFeatures")
    adapter_enumerate_features :: proc(adapter: Adapter, features: ^Feature_Name) -> c.size_t ---
    @(link_name = "wgpuAdapterGetLimits")
    adapter_get_limits :: proc(adapter: Adapter, limits: ^Supported_Limits) -> c.bool ---
    @(link_name = "wgpuAdapterGetProperties")
    adapter_get_properties :: proc(adapter: Adapter, properties: ^Adapter_Properties) ---
    @(link_name = "wgpuAdapterHasFeature")
    adapter_has_feature :: proc(adapter: Adapter, feature: Feature_Name) -> c.bool ---
    @(link_name = "wgpuAdapterRequestDevice")
    adapter_request_device :: proc(adapter: Adapter, descriptor: ^Device_Descriptor, callback: Request_Device_Callback, user_data: rawptr) ---
    @(link_name = "wgpuAdapterReference")
    adapter_reference :: proc(adapter: Adapter) ---
    @(link_name = "wgpuAdapterRelease")
    adapter_release :: proc(adapter: Adapter) ---

    // Methods of Bind_Group


    @(link_name = "wgpuBindGroupSetLabel")
    bind_group_set_label :: proc(bind_group: Bind_Group, label: cstring) ---
    @(link_name = "wgpuBindGroupReference")
    bind_group_reference :: proc(bind_group: Bind_Group) ---
    @(link_name = "wgpuBindGroupRelease")
    bind_group_release :: proc(bind_group: Bind_Group) ---


    // Methods of BindGroupLayout


    @(link_name = "wgpuBindGroupLayoutSetLabel")
    bind_group_layout_set_label :: proc(bind_group_layout: Bind_Group_Layout, label: cstring) ---
    @(link_name = "wgpuBindGroupLayoutReference")
    bind_group_layout_reference :: proc(bind_group_layout: Bind_Group_Layout) ---
    @(link_name = "wgpuBindGroupLayoutRelease")
    bind_group_layout_release :: proc(bind_group_layout: Bind_Group_Layout) ---

    // Methods of Buffer


    @(link_name = "wgpuBufferDestroy")
    buffer_destroy :: proc(buffer: Buffer) ---
    @(link_name = "wgpuBufferGetConstMappedRange")
    buffer_get_const_mapped_range :: proc(buffer: Buffer, offset, size: c.size_t) -> rawptr ---
    @(link_name = "wgpuBufferGetMapState")
    buffer_get_map_state :: proc(buffer: Buffer) -> Buffer_Map_State ---
    @(link_name = "wgpuBufferGetMappedRange")
    buffer_get_mapped_range :: proc(buffer: Buffer, offset, size: c.size_t) -> rawptr ---
    @(link_name = "wgpuBufferGetSize")
    buffer_get_size :: proc(buffer: Buffer) -> c.uint64_t ---
    @(link_name = "wgpuBufferGetUsage")
    buffer_get_usage :: proc(buffer: Buffer) -> Buffer_Usage ---
    @(link_name = "wgpuBufferMapAsync")
    buffer_map_async :: proc(buffer: Buffer, mode: Map_Mode_Flags, offset, size: c.size_t, callback: Buffer_Map_Callback, user_data: rawptr) ---
    @(link_name = "wgpuBufferSetLabel")
    buffer_set_label :: proc(buffer: Buffer, label: cstring) ---
    @(link_name = "wgpuBufferUnmap")
    buffer_unmap :: proc(buffer: Buffer) ---
    @(link_name = "wgpuBufferReference")
    buffer_reference :: proc(buffer: Buffer) ---
    @(link_name = "wgpuBufferRelease")
    buffer_release :: proc(buffer: Buffer) ---

    // Methods of CommandBuffer


    @(link_name = "wgpuCommandBufferSetLabel")
    command_buffer_set_label :: proc(command_buffer: Command_Buffer, label: cstring) ---
    @(link_name = "wgpuCommandBufferReference")
    command_buffer_reference :: proc(command_buffer: Command_Buffer) ---
    @(link_name = "wgpuCommandBufferRelease")
    command_buffer_release :: proc(command_buffer: Command_Buffer) ---

    // Methods of CommandEncoder


    @(link_name = "wgpuCommandEncoderBeginComputePass")
    command_encoder_begin_compute_pass :: proc(command_encoder: Command_Encoder, descriptor: ^Compute_Pass_Descriptor) -> Compute_Pass_Encoder ---
    @(link_name = "wgpuCommandEncoderBeginRenderPass")
    command_encoder_begin_render_pass :: proc(command_encoder: Command_Encoder, descriptor: ^Render_Pass_Descriptor) -> Render_Pass_Encoder ---
    @(link_name = "wgpuCommandEncoderClearBuffer")
    command_encoder_clear_buffer :: proc(command_encoder: Command_Encoder, buffer: Buffer, offset, size: c.uint64_t) ---
    @(link_name = "wgpuCommandEncoderCopyBufferToBuffer")
    command_encoder_copy_buffer_to_buffer :: proc(command_encoder: Command_Encoder, source: Buffer, sourceOffset: c.uint64_t, destination: Buffer, destinationOffset: c.uint64_t, size: c.uint64_t) ---
    @(link_name = "wgpuCommandEncoderCopyBufferToTexture")
    command_encoder_copy_buffer_to_texture :: proc(command_encoder: Command_Encoder, source: ^Image_Copy_Buffer, destination: ^Image_Copy_Texture, copy_size: ^Extent_3D) ---
    @(link_name = "wgpuCommandEncoderCopyTextureToBuffer")
    command_encoder_copy_texture_to_buffer :: proc(command_encoder: Command_Encoder, source: ^Image_Copy_Texture, destination: ^Image_Copy_Buffer, copy_size: ^Extent_3D) ---
    @(link_name = "wgpuCommandEncoderCopyTextureToTexture")
    command_encoder_copy_texture_to_texture :: proc(command_encoder: Command_Encoder, source: ^Image_Copy_Texture, destination: ^Image_Copy_Texture, copy_size: ^Extent_3D) ---
    @(link_name = "wgpuCommandEncoderFinish")
    command_encoder_finish :: proc(command_encoder: Command_Encoder, descriptor: ^Command_Buffer_Descriptor) -> Command_Buffer ---
    @(link_name = "wgpuCommandEncoderInsertDebugMarker")
    command_encoder_insert_debug_marker :: proc(command_encoder: Command_Encoder, marker_label: cstring) ---
    @(link_name = "wgpuCommandEncoderPopDebugGroup")
    command_encoder_pop_debug_group :: proc(command_encoder: Command_Encoder) ---
    @(link_name = "wgpuCommandEncoderPushDebugGroup")
    command_encoder_push_debug_group :: proc(command_encoder: Command_Encoder, group_label: cstring) ---
    @(link_name = "wgpuCommandEncoderResolveQuerySet")
    command_encoder_resolve_query_set :: proc(command_encoder: Command_Encoder, querySet: Query_Set, firstQuery: c.uint32_t, query_count: c.uint32_t, destination: Buffer, destination_offset: c.uint64_t) ---
    @(link_name = "wgpuCommandEncoderSetLabel")
    command_encoder_set_label :: proc(command_encoder: Command_Encoder, label: cstring) ---
    @(link_name = "wgpuCommandEncoderWriteTimestamp")
    command_encoder_write_timestamp :: proc(command_encoder: Command_Encoder, querySet: Query_Set, query_index: c.uint32_t) ---
    @(link_name = "wgpuCommandEncoderReference")
    command_encoder_reference :: proc(command_encoder: Command_Encoder) ---
    @(link_name = "wgpuCommandEncoderRelease")
    command_encoder_release :: proc(command_encoder: Command_Encoder) ---

    // Methods of ComputePassEncoder


    @(link_name = "wgpuComputePassEncoderBeginPipelineStatisticsQuery")
    compute_pass_encoder_begin_pipeline_statistics_query :: proc(compute_pass_encoder: Compute_Pass_Encoder, querySet: Query_Set, queryIndex: c.uint32_t) ---
    @(link_name = "wgpuComputePassEncoderDispatchWorkgroups")
    compute_pass_encoder_dispatch_workgroups :: proc(compute_pass_encoder: Compute_Pass_Encoder, workgroup_count_x, workgroup_count_y, workgroup_count_z: c.uint32_t) ---
    @(link_name = "wgpuComputePassEncoderDispatchWorkgroupsIndirect")
    compute_pass_encoder_dispatch_workgroups_indirect :: proc(compute_pass_encoder: Compute_Pass_Encoder, indirect_buffer: Buffer, indirectOffset: c.uint64_t) ---
    @(link_name = "wgpuComputePassEncoderEnd")
    compute_pass_encoder_end :: proc(compute_pass_encoder: Compute_Pass_Encoder) ---
    @(link_name = "wgpuComputePassEncoderEndPipelineStatisticsQuery")
    compute_pass_encoder_end_pipeline_statistics_query :: proc(compute_pass_encoder: Compute_Pass_Encoder) ---
    @(link_name = "wgpuComputePassEncoderInsertDebugMarker")
    compute_pass_encoder_insert_debug_marker :: proc(compute_pass_encoder: Compute_Pass_Encoder, marker_label: cstring) ---
    @(link_name = "wgpuComputePassEncoderPopDebugGroup")
    compute_pass_encoder_pop_debug_group :: proc(compute_pass_encoder: Compute_Pass_Encoder) ---
    @(link_name = "wgpuComputePassEncoderPushDebugGroup")
    compute_pass_encoder_push_debug_group :: proc(compute_pass_encoder: Compute_Pass_Encoder, group_label: cstring) ---
    @(link_name = "wgpuComputePassEncoderSetBindGroup")
    compute_pass_encoder_set_bind_group :: proc(compute_pass_encoder: Compute_Pass_Encoder, group_index: c.uint32_t, group: Bind_Group, dynamic_offset_count: c.size_t, dynamic_offsets: ^c.uint32_t) ---
    @(link_name = "wgpuComputePassEncoderSetLabel")
    compute_pass_encoder_set_label :: proc(compute_pass_encoder: Compute_Pass_Encoder, label: cstring) ---
    @(link_name = "wgpuComputePassEncoderSetPipeline")
    compute_pass_encoder_set_pipeline :: proc(compute_pass_encoder: Compute_Pass_Encoder, pipeline: Compute_Pipeline) ---
    @(link_name = "wgpuComputePassEncoderReference")
    compute_pass_encoder_reference :: proc(compute_pass_encoder: Compute_Pass_Encoder) ---
    @(link_name = "wgpuComputePassEncoderRelease")
    compute_pass_encoder_release :: proc(compute_pass_encoder: Compute_Pass_Encoder) ---

    // Methods of ComputePipeline


    @(link_name = "wgpuComputePipelineGetBindGroupLayout")
    compute_pipeline_get_bind_group_layout :: proc(compute_pipeline: Compute_Pipeline, groupIndex: c.uint32_t) -> Bind_Group_Layout ---
    @(link_name = "wgpuComputePipelineSetLabel")
    compute_pipeline_set_label :: proc(compute_pipeline: Compute_Pipeline, label: cstring) ---
    @(link_name = "wgpuComputePipelineReference")
    compute_pipeline_reference :: proc(compute_pipeline: Compute_Pipeline) ---
    @(link_name = "wgpuComputePipelineRelease")
    compute_pipeline_release :: proc(compute_pipeline: Compute_Pipeline) ---

    // Methods of Device


    @(link_name = "wgpuDeviceCreateBindGroup")
    device_create_bind_group :: proc(device: Device, descriptor: ^Bind_Group_Descriptor) -> Bind_Group ---
    @(link_name = "wgpuDeviceCreateBindGroupLayout")
    device_create_bind_group_layout :: proc(device: Device, descriptor: ^Bind_Group_Layout_Descriptor) -> Bind_Group_Layout ---
    @(link_name = "wgpuDeviceCreateBuffer")
    device_create_buffer :: proc(device: Device, descriptor: ^Buffer_Descriptor) -> Buffer ---
    @(link_name = "wgpuDeviceCreateCommandEncoder")
    device_create_command_encoder :: proc(device: Device, descriptor: ^Command_Encoder_Descriptor) -> Command_Encoder ---
    @(link_name = "wgpuDeviceCreateComputePipeline")
    device_create_compute_pipeline :: proc(device: Device, descriptor: ^Compute_Pipeline_Descriptor) -> Compute_Pipeline ---
    @(link_name = "wgpuDeviceCreateComputePipelineAsync")
    device_create_compute_pipeline_async :: proc(device: Device, descriptor: ^Compute_Pipeline_Descriptor, callback: Create_Compute_Pipeline_Async_Callback, user_data: rawptr) ---
    @(link_name = "wgpuDeviceCreatePipelineLayout")
    device_create_pipeline_layout :: proc(device: Device, descriptor: ^Pipeline_Layout_Descriptor) -> Pipeline_Layout ---
    @(link_name = "wgpuDeviceCreateQuerySet")
    device_create_query_set :: proc(device: Device, descriptor: ^Query_Set_Descriptor) -> Query_Set ---
    @(link_name = "wgpuDeviceCreateRenderBundleEncoder")
    device_create_render_bundle_encoder :: proc(device: Device, descriptor: ^Render_Bundle_Encoder_Descriptor) -> Render_Bundle_Encoder ---
    @(link_name = "wgpuDeviceCreateRenderPipeline")
    device_create_render_pipeline :: proc(device: Device, descriptor: ^Render_Pipeline_Descriptor) -> Render_Pipeline ---
    @(link_name = "wgpuDeviceCreateRenderPipelineAsync")
    device_create_render_pipeline_async :: proc(device: Device, descriptor: ^Render_Pipeline_Descriptor, callback: Create_Render_Pipeline_Async_Callback, user_data: rawptr) ---
    @(link_name = "wgpuDeviceCreateSampler")
    device_create_sampler :: proc(device: Device, descriptor: ^Sampler_Descriptor) -> Sampler ---
    @(link_name = "wgpuDeviceCreateShaderModule")
    device_create_shader_module :: proc(device: Device, descriptor: ^Shader_Module_Descriptor) -> Shader_Module ---
    @(link_name = "wgpuDeviceCreateSwapChain")
    device_create_swap_chain :: proc(device: Device, surface: Surface, descriptor: ^Swap_Chain_Descriptor) -> Swap_Chain ---
    @(link_name = "wgpuDeviceCreateTexture")
    device_create_texture :: proc(device: Device, descriptor: ^Texture_Descriptor) -> Texture ---
    @(link_name = "wgpuDeviceDestroy")
    device_destroy :: proc(device: Device) ---
    @(link_name = "wgpuDeviceEnumerateFeatures")
    device_enumerate_features :: proc(device: Device, features: ^Feature_Name) -> c.size_t ---
    @(link_name = "wgpuDeviceGetLimits")
    device_get_limits :: proc(device: Device, limits: ^Supported_Limits) -> c.bool ---
    @(link_name = "wgpuDeviceGetQueue")
    device_get_queue :: proc(device: Device) -> Queue ---
    @(link_name = "wgpuDeviceHasFeature")
    device_has_feature :: proc(device: Device, feature: Feature_Name) -> c.bool ---
    @(link_name = "wgpuDevicePopErrorScope")
    device_pop_error_scope :: proc(device: Device, callback: Error_Callback, user_data: rawptr) -> c.bool ---
    @(link_name = "wgpuDevicePushErrorScope")
    device_push_error_scope :: proc(device: Device, filter: Error_Filter) ---
    @(link_name = "wgpuDeviceSetDeviceLostCallback")
    device_set_device_lost_callback :: proc(device: Device, callback: Device_Lost_Callback, user_data: rawptr) ---
    @(link_name = "wgpuDeviceSetLabel")
    device_set_label :: proc(device: Device, label: cstring) ---
    @(link_name = "wgpuDeviceSetUncapturedErrorCallback")
    device_set_uncaptured_error_callback :: proc(device: Device, callback: Error_Callback, user_data: rawptr) ---
    @(link_name = "wgpuDeviceReference")
    device_reference :: proc(device: Device) ---
    @(link_name = "wgpuDeviceRelease")
    device_release :: proc(device: Device) ---

    // Methods of Instance


    @(link_name = "wgpuInstanceCreateSurface")
    instance_create_surface :: proc(instance: Instance, descriptor: ^Surface_Descriptor) -> Surface ---
    @(link_name = "wgpuInstanceProcessEvents")
    instance_process_events :: proc(instance: Instance) ---
    @(link_name = "wgpuInstanceRequestAdapter")
    instance_request_adapter :: proc(instance: Instance, options: ^Request_Adapter_Options, callback: Request_Adapter_Callback, user_data: rawptr) ---
    @(link_name = "wgpuInstanceReference")
    instance_reference :: proc(instance: Instance) ---
    @(link_name = "wgpuInstanceRelease")
    instance_release :: proc(instance: Instance) ---

    // Methods of PipelineLayout


    @(link_name = "wgpuPipelineLayoutSetLabel")
    pipeline_layout_set_label :: proc(pipeline_layout: Pipeline_Layout, label: cstring) ---
    @(link_name = "wgpuPipelineLayoutReference")
    pipeline_layout_reference :: proc(pipeline_layout: Pipeline_Layout) ---
    @(link_name = "wgpuPipelineLayoutRelease")
    pipeline_layout_release :: proc(pipeline_layout: Pipeline_Layout) ---

    // Methods of QuerySet


    @(link_name = "wgpuQuerySetDestroy")
    query_set_destroy :: proc(query_set: Query_Set) ---
    @(link_name = "wgpuQuerySetGetCount")
    query_set_get_count :: proc(query_set: Query_Set) -> c.uint32_t ---
    @(link_name = "wgpuQuerySetGetType")
    query_set_get_type :: proc(query_set: Query_Set) -> Query_Type ---
    @(link_name = "wgpuQuerySetSetLabel")
    query_set_set_label :: proc(query_set: Query_Set, label: cstring) ---
    @(link_name = "wgpuQuerySetReference")
    query_set_reference :: proc(query_set: Query_Set) ---
    @(link_name = "wgpuQuerySetRelease")
    query_set_release :: proc(query_set: Query_Set) ---

    // Methods of Queue


    @(link_name = "wgpuQueueOnSubmittedWorkDone")
    queue_on_submitted_work_done :: proc(queue: Queue, callback: Queue_Work_Done_Callback, user_data: rawptr) ---
    @(link_name = "wgpuQueueSetLabel")
    queue_set_label :: proc(queue: Queue, label: cstring) ---
    @(link_name = "wgpuQueueSubmit")
    queue_submit :: proc(queue: Queue, commandCount: c.size_t, commands: ^Command_Buffer) ---
    @(link_name = "wgpuQueueWriteBuffer")
    queue_write_buffer :: proc(queue: Queue, buffer: Buffer, bufferOffset: c.uint64_t, data: rawptr, size: c.size_t) ---
    @(link_name = "wgpuQueueWriteTexture")
    queue_write_texture :: proc(queue: Queue, destination: ^Image_Copy_Texture, data: rawptr, data_size: c.size_t, data_layout: ^Texture_Data_Layout, write_size: ^Extent_3D) ---
    @(link_name = "wgpuQueueReference")
    queue_reference :: proc(queue: Queue) ---
    @(link_name = "wgpuQueueRelease")
    queue_release :: proc(queue: Queue) ---

    // Methods of RenderBundle


    @(link_name = "wgpuRenderBundleSetLabel")
    render_bundle_set_label :: proc(render_bundle: Render_Bundle, label: cstring) ---
    @(link_name = "wgpuRenderBundleReference")
    render_bundle_reference :: proc(render_bundle: Render_Bundle) ---
    @(link_name = "wgpuRenderBundleRelease")
    render_bundle_release :: proc(render_bundle: Render_Bundle) ---


    // Methods of RenderBundleEncoder


    @(link_name = "wgpuRenderBundleEncoderDraw")
    render_bundle_encoder_draw :: proc(render_bundle_encoder: Render_Bundle_Encoder, vertex_count, instance_count, first_vertex, first_instance: c.uint32_t) ---
    @(link_name = "wgpuRenderBundleEncoderDrawIndexed")
    render_bundle_encoder_draw_indexed :: proc(render_bundle_encoder: Render_Bundle_Encoder, index_count, instance_count, first_index: c.uint32_t, base_vertex: c.int32_t, first_instance: c.uint32_t) ---
    @(link_name = "wgpuRenderBundleEncoderDrawIndexedIndirect")
    render_bundle_encoder_draw_indexed_indirect :: proc(render_bundle_encoder: Render_Bundle_Encoder, indirect_buffer: Buffer, indirect_offset: c.uint64_t) ---
    @(link_name = "wgpuRenderBundleEncoderDrawIndirect")
    render_bundle_encoder_draw_indirect :: proc(render_bundle_encoder: Render_Bundle_Encoder, indirect_buffer: Buffer, indirect_offset: c.uint64_t) ---
    @(link_name = "wgpuRenderBundleEncoderFinish")
    render_bundle_encoder_finish :: proc(render_bundle_encoder: Render_Bundle_Encoder, descriptor: ^Render_Bundle_Descriptor) -> Render_Bundle ---
    @(link_name = "wgpuRenderBundleEncoderInsertDebugMarker")
    render_bundle_encoder_insert_debug_marker :: proc(render_bundle_encoder: Render_Bundle_Encoder, marker_label: cstring) ---
    @(link_name = "wgpuRenderBundleEncoderPopDebugGroup")
    render_bundle_encoder_pop_debug_group :: proc(render_bundle_encoder: Render_Bundle_Encoder) ---
    @(link_name = "wgpuRenderBundleEncoderPushDebugGroup")
    render_bundle_encoder_push_debug_group :: proc(render_bundle_encoder: Render_Bundle_Encoder, group_label: cstring) ---
    @(link_name = "wgpuRenderBundleEncoderSetBindGroup")
    render_bundle_encoder_set_bind_group :: proc(render_bundle_encoder: Render_Bundle_Encoder, group_index: c.uint32_t, group: Bind_Group, dynamic_offset_count: c.size_t, dynamic_offsets: ^c.uint32_t) ---
    @(link_name = "wgpuRenderBundleEncoderSetIndexBuffer")
    render_bundle_encoder_set_index_buffer :: proc(render_bundle_encoder: Render_Bundle_Encoder, buffer: Buffer, format: Index_Format, offset: c.uint64_t, size: c.uint64_t) ---
    @(link_name = "wgpuRenderBundleEncoderSetLabel")
    render_bundle_encoder_set_label :: proc(render_bundle_encoder: Render_Bundle_Encoder, label: cstring) ---
    @(link_name = "wgpuRenderBundleEncoderSetPipeline")
    render_bundle_encoder_set_pipeline :: proc(render_bundle_encoder: Render_Bundle_Encoder, pipeline: Render_Pipeline) ---
    @(link_name = "wgpuRenderBundleEncoderSetVertexBuffer")
    render_bundle_encoder_set_vertex_buffer :: proc(render_bundle_encoder: Render_Bundle_Encoder, slot: c.uint32_t, buffer: Buffer, offset, size: c.uint64_t) ---
    @(link_name = "wgpuRenderBundleEncoderReference")
    render_bundle_encoder_reference :: proc(render_bundle_encoder: Render_Bundle_Encoder) ---
    @(link_name = "wgpuRenderBundleEncoderRelease")
    render_bundle_encoder_release :: proc(render_bundle_encoder: Render_Bundle_Encoder) ---

    // Methods of RenderPassEncoder

    @(link_name = "wgpuRenderPassEncoderBeginOcclusionQuery")
    render_pass_encoder_begin_occlusion_query :: proc(render_pass_encoder: Render_Pass_Encoder, query_index: c.uint32_t) ---
    @(link_name = "wgpuRenderPassEncoderBeginPipelineStatisticsQuery")
    render_pass_encoder_begin_pipeline_statistics_query :: proc(render_pass_encoder: Render_Pass_Encoder, query_set: Query_Set, query_index: c.uint32_t) ---
    @(link_name = "wgpuRenderPassEncoderDraw")
    render_pass_encoder_draw :: proc(render_pass_encoder: Render_Pass_Encoder, vertex_count, instance_count, first_vertex, firstInstance: c.uint32_t) ---
    @(link_name = "wgpuRenderPassEncoderDrawIndexed")
    render_pass_encoder_draw_indexed :: proc(render_pass_encoder: Render_Pass_Encoder, index_count, instance_count, firstIndex: c.uint32_t, base_vertex: c.int32_t, first_instance: c.uint32_t) ---
    @(link_name = "wgpuRenderPassEncoderDrawIndexedIndirect")
    render_pass_encoder_draw_indexed_indirect :: proc(render_pass_encoder: Render_Pass_Encoder, indirect_buffer: Buffer, indirect_offset: c.uint64_t) ---
    @(link_name = "wgpuRenderPassEncoderDrawIndirect")
    render_pass_encoder_draw_indirect :: proc(render_pass_encoder: Render_Pass_Encoder, indirect_buffer: Buffer, indirect_offset: c.uint64_t) ---
    @(link_name = "wgpuRenderPassEncoderEnd")
    render_pass_encoder_end :: proc(render_pass_encoder: Render_Pass_Encoder) ---
    @(link_name = "wgpuRenderPassEncoderEndOcclusionQuery")
    render_pass_encoder_end_occlusion_query :: proc(render_pass_encoder: Render_Pass_Encoder) ---
    @(link_name = "wgpuRenderPassEncoderEndPipelineStatisticsQuery")
    render_pass_encoder_end_pipeline_statistics_query :: proc(render_pass_encoder: Render_Pass_Encoder) ---
    @(link_name = "wgpuRenderPassEncoderExecuteBundles")
    render_pass_encoder_execute_bundles :: proc(render_pass_encoder: Render_Pass_Encoder, bundle_count: c.size_t, bundles: ^Render_Bundle) ---
    @(link_name = "wgpuRenderPassEncoderInsertDebugMarker")
    render_pass_encoder_insert_debug_marker :: proc(render_pass_encoder: Render_Pass_Encoder, marker_label: cstring) ---
    @(link_name = "wgpuRenderPassEncoderPopDebugGroup")
    render_pass_encoder_pop_debug_group :: proc(render_pass_encoder: Render_Pass_Encoder) ---
    @(link_name = "wgpuRenderPassEncoderPushDebugGroup")
    render_pass_encoder_push_debug_group :: proc(render_pass_encoder: Render_Pass_Encoder, group_label: cstring) ---
    @(link_name = "wgpuRenderPassEncoderSetBindGroup")
    render_pass_encoder_set_bind_group :: proc(render_pass_encoder: Render_Pass_Encoder, group_index: c.uint32_t, group: Bind_Group, dynamic_offset_count: c.size_t, dynamic_offsets: ^c.uint32_t) ---
    @(link_name = "wgpuRenderPassEncoderSetBlendConstant")
    render_pass_encoder_set_blend_constant :: proc(render_pass_encoder: Render_Pass_Encoder, color: ^Color) ---
    @(link_name = "wgpuRenderPassEncoderSetIndexBuffer")
    render_pass_encoder_set_index_buffer :: proc(render_pass_encoder: Render_Pass_Encoder, buffer: Buffer, format: Index_Format, offset, size: c.uint64_t) ---
    @(link_name = "wgpuRenderPassEncoderSetLabel")
    render_pass_encoder_set_label :: proc(render_pass_encoder: Render_Pass_Encoder, label: cstring) ---
    @(link_name = "wgpuRenderPassEncoderSetPipeline")
    render_pass_encoder_set_pipeline :: proc(render_pass_encoder: Render_Pass_Encoder, pipeline: Render_Pipeline) ---
    @(link_name = "wgpuRenderPassEncoderSetScissorRect")
    render_pass_encoder_set_scissor_rect :: proc(render_pass_encoder: Render_Pass_Encoder, x, y, width, height: c.uint32_t) ---
    @(link_name = "wgpuRenderPassEncoderSetStencilReference")
    render_pass_encoder_set_stencil_reference :: proc(render_pass_encoder: Render_Pass_Encoder, reference: c.uint32_t) ---
    @(link_name = "wgpuRenderPassEncoderSetVertexBuffer")
    render_pass_encoder_set_vertex_buffer :: proc(render_pass_encoder: Render_Pass_Encoder, slot: c.uint32_t, buffer: Buffer, offset, size: c.uint64_t) ---
    @(link_name = "wgpuRenderPassEncoderSetViewport")
    render_pass_encoder_set_viewport :: proc(render_pass_encoder: Render_Pass_Encoder, x, y, width, height, min_depth, max_depth: c.float) ---
    @(link_name = "wgpuRenderPassEncoderReference")
    render_pass_encoder_reference :: proc(render_pass_encoder: Render_Pass_Encoder) ---
    @(link_name = "wgpuRenderPassEncoderRelease")
    render_pass_release :: proc(render_pass_encoder: Render_Pass_Encoder) ---

    // Methods of RenderPipeline


    @(link_name = "wgpuRenderPipelineGetBindGroupLayout")
    render_pipeline_get_bind_group_layout :: proc(render_pipeline: Render_Pipeline, group_index: c.uint32_t) -> Bind_Group_Layout ---
    @(link_name = "wgpuRenderPipelineSetLabel")
    render_pipeline_set_label :: proc(render_pipeline: Render_Pipeline, label: cstring) ---
    @(link_name = "wgpuRenderPipelineReference")
    render_pipeline_reference :: proc(render_pipeline: Render_Pipeline) ---
    @(link_name = "wgpuRenderPipelineRelease")
    render_pipeline_release :: proc(render_pipeline: Render_Pipeline) ---

    // Methods of Sampler


    @(link_name = "wgpuSamplerSetLabel")
    sampler_set_label :: proc(sampler: Sampler, label: cstring) ---
    @(link_name = "wgpuSamplerReference")
    sampler_reference :: proc(sampler: Sampler) ---
    @(link_name = "wgpuSamplerRelease")
    sampler_release :: proc(sampler: Sampler) ---

    // Methods of ShaderModule


    @(link_name = "wgpuShaderModuleGetCompilationInfo")
    shader_module_get_compilation_info :: proc(shader_module: Shader_Module, callback: Compilation_Info_Callback, user_data: rawptr) ---
    @(link_name = "wgpuShaderModuleSetLabel")
    shader_module_set_label :: proc(shader_module: Shader_Module, label: cstring) ---
    @(link_name = "wgpuShaderModuleReference")
    shader_module_reference :: proc(shader_module: Shader_Module) ---
    @(link_name = "wgpuShaderModuleRelease")
    shader_module_release :: proc(shader_module: Shader_Module) ---

    // Methods of Surface


    @(link_name = "wgpuSurfaceGetPreferredFormat")
    surface_get_preferred_format :: proc(surface: Surface, adapter: Adapter) -> Texture_Format ---
    @(link_name = "wgpuSurfaceReference")
    surface_reference :: proc(surface: Surface) ---
    @(link_name = "wgpuSurfaceRelease")
    surface_release :: proc(surface: Surface) ---

    // Methods of SwapChain


    @(link_name = "wgpuSwapChainGetCurrentTextureView")
    swap_chain_get_current_texture_view :: proc(swap_chain: Swap_Chain) -> Texture_View ---
    @(link_name = "wgpuSwapChainPresent")
    swap_chain_present :: proc(swap_chain: Swap_Chain) ---
    @(link_name = "wgpuSwapChainReference")
    swap_chain_reference :: proc(swap_chain: Swap_Chain) ---
    @(link_name = "wgpuSwapChainRelease")
    swap_chain_release :: proc(swap_chain: Swap_Chain) ---

    // Methods of Texture


    @(link_name = "wgpuTextureCreateView")
    texture_create_view :: proc(texture: Texture, descriptor: ^Texture_View_Descriptor) -> Texture_View ---
    @(link_name = "wgpuTextureDestroy")
    texture_destroy :: proc(texture: Texture) ---
    @(link_name = "wgpuTextureGetDepthOrArrayLayers")
    texture_get_depth_or_array_layers :: proc(texture: Texture) -> c.uint32_t ---
    @(link_name = "wgpuTextureGetDimension")
    texture_get_dimension :: proc(texture: Texture) -> Texture_Dimension ---
    @(link_name = "wgpuTextureGetFormat")
    texture_get_format :: proc(texture: Texture) -> Texture_Format ---
    @(link_name = "wgpuTextureGetHeight")
    texture_get_height :: proc(texture: Texture) -> c.uint32_t ---
    @(link_name = "wgpuTextureGetMipLevelCount")
    texture_get_mip_level_count :: proc(texture: Texture) -> c.uint32_t ---
    @(link_name = "wgpuTextureGetSampleCount")
    texture_get_sample_count :: proc(texture: Texture) -> c.uint32_t ---
    @(link_name = "wgpuTextureGetUsage")
    texture_get_usage :: proc(texture: Texture) -> Texture_Usage ---
    @(link_name = "wgpuTextureGetWidth")
    texture_get_width :: proc(texture: Texture) -> c.uint32_t ---
    @(link_name = "wgpuTextureSetLabel")
    texture_set_label :: proc(texture: Texture, label: cstring) ---
    @(link_name = "wgpuTextureReference")
    texture_reference :: proc(texture: Texture) ---
    @(link_name = "wgpuTextureRelease")
    texture_release :: proc(texture: Texture) ---

    // Methods of TextureView


    @(link_name = "wgpuTextureViewSetLabel")
    texture_view_set_label :: proc(texture_view: Texture_View, label: cstring) ---
    @(link_name = "wgpuTextureViewReference")
    texture_view_reference :: proc(texture_view: Texture_View) ---
    @(link_name = "wgpuTextureViewRelease")
    texture_view_release :: proc(texture_view: Texture_View) ---
}
