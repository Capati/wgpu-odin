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

Native_SType :: enum c.int {
    Device_Extras                 = 0x60000001,
    Adapter_Extras                = 0x60000002,
    Required_Limits_Extras        = 0x60000003,
    Pipeline_Layout_Extras        = 0x60000004,
    Shader_Module_Glsl_Descriptor = 0x60000005,
    Supported_Limits_Extras       = 0x60000003,
    Instance_Extras               = 0x60000006,
    Swap_Chain_Descriptor_Extras  = 0x60000007,
}

Native_Feature :: enum c.int {
    Push_Constants                           = 0x60000001,
    Texture_Adapter_Specific_Format_Features = 0x60000002,
    Multi_Draw_Indirect                      = 0x60000003,
    Multi_Draw_Indirect_Count                = 0x60000004,
    Vertex_Writable_Storage                  = 0x60000005,
}

Log_Level :: enum c.int {
    Off,
    Error,
    Warn,
    Info,
    Debug,
    Trace,
}

Instance_Backend :: enum c.int {
    Vulkan         = 1,
    GL             = 2,
    Metal          = 3,
    DX12           = 4,
    DX11           = 5,
    Browser_WebGPU = 6,
}
Instance_Backend_Flags :: bit_set[Instance_Backend;Flags]
Instance_Backend_Primary :: Instance_Backend_Flags{
    .Vulkan,
    .Metal,
    .DX12,
    .Browser_WebGPU,
}
Instance_Backend_Secondary :: Instance_Backend_Flags{.GL, .DX11}
Instance_Backend_None :: Instance_Backend_Flags{}

Dx12_Compiler :: enum c.int {
    Undefined,
    Fxc,
    Dxc,
}

Composite_Alpha_Mode :: enum c.int {
    Auto,
    Opaque,
    Pre_Multiplied,
    Pos_tMultiplied,
    Inherit,
}

Instance_Extras :: struct {
    chain:                Chained_Struct,
    backends:             Instance_Backend_Flags,
    dx12_shader_compiler: Dx12_Compiler,
    dxil_path:            cstring,
    dxc_path:             cstring,
}

Device_Extras :: struct {
    chain:      Chained_Struct,
    trace_path: cstring,
}

Required_Limits_Extras :: struct {
    chain:                  Chained_Struct,
    max_push_constant_size: c.uint32_t,
}

Supported_Limits_Extras :: struct {
    chain:                  Chained_Struct_Out,
    max_push_constant_size: c.uint32_t,
}

Push_Constant_Range :: struct {
    stages: Shader_Stage_Flags,
    start:  c.uint32_t,
    end:    c.uint32_t,
}

Pipeline_Layout_Extras :: struct {
    chain:                     Chained_Struct,
    push_constant_range_count: c.uint32_t,
    push_constant_ranges:      ^Push_Constant_Range,
}

Submission_Index :: c.uint64_t

Wrapped_Submission_Index :: struct {
    queue:            Queue,
    submission_index: Submission_Index,
}

Shader_Define :: struct {
    name:  cstring,
    value: cstring,
}

Shader_Module_Glsl_Descriptor :: struct {
    chain:        Chained_Struct,
    stage:        Shader_Stage,
    code:         cstring,
    define_count: c.uint32_t,
    defines:      ^Shader_Define,
}

Storage_Report :: struct {
    num_occupied: c.size_t,
    num_vacant:   c.size_t,
    num_error:    c.size_t,
    element_size: c.size_t,
}

Hub_Report :: struct {
    adapters:           Storage_Report,
    devices:            Storage_Report,
    pipeline_layouts:   Storage_Report,
    shader_modules:     Storage_Report,
    bind_group_layouts: Storage_Report,
    bind_groups:        Storage_Report,
    command_buffers:    Storage_Report,
    render_bundles:     Storage_Report,
    render_pipelines:   Storage_Report,
    compute_pipelines:  Storage_Report,
    query_sets:         Storage_Report,
    buffers:            Storage_Report,
    textures:           Storage_Report,
    texture_views:      Storage_Report,
    samplers:           Storage_Report,
}

Global_Report :: struct {
    surfaces:     Storage_Report,
    backend_type: Backend_Type,
    vulkan:       Hub_Report,
    metal:        Hub_Report,
    dx12:         Hub_Report,
    dx11:         Hub_Report,
    gl:           Hub_Report,
}

Surface_Capabilities :: struct {
    format_count:       c.size_t,
    formats:            [^]Texture_Format,
    present_mode_count: c.size_t,
    present_modes:      [^]Present_Mode,
    alpha_mode_count:   c.size_t,
    alpha_modes:        [^]Composite_Alpha_Mode,
}

Swap_Chain_Descriptor_Extras :: struct {
    chain:             Chained_Struct,
    alpha_mode:        Composite_Alpha_Mode,
    view_format_count: c.size_t,
    view_formats:      ^Texture_Format,
}

Instance_Enumerate_Adapter_Options :: struct {
    chain:    Chained_Struct,
    backends: Instance_Backend_Flags,
}

Log_Callback :: #type proc "c" (level: Log_Level, message: cstring, user_data: rawptr)

foreign wgpu_native {
    @(link_name = "wgpuGenerateReport")
    generate_report :: proc(instance: Instance, report: ^Global_Report) ---

    @(link_name = "wgpuInstanceEnumerateAdapters")
    instance_enumerate_adapters :: proc(instance: Instance, options: ^Instance_Enumerate_Adapter_Options, adapters: [^]Adapter) -> c.size_t ---

    @(link_name = "wgpuQueueSubmitForIndex")
    queue_submit_for_index :: proc(queue: Queue, command_count: c.uint32_t, commands: ^Command_Buffer) -> Submission_Index ---

    @(link_name = "wgpuDevicePoll")
    device_poll :: proc(device: Device, wait: bool, wrapped_submission_index: ^Wrapped_Submission_Index) -> bool ---

    @(link_name = "wgpuSetLogCallback")
    set_log_callback :: proc(callback: Log_Callback, user_data: rawptr) ---

    @(link_name = "wgpuSetLogLevel")
    set_log_level :: proc(level: Log_Level) ---

    @(link_name = "wgpuGetVersion")
    get_version :: proc() -> c.uint32_t ---

    @(link_name = "wgpuSurfaceGetCapabilities")
    surface_get_capabilities :: proc(surface: Surface, adapter: Adapter, capabilities: ^Surface_Capabilities) ---

    @(link_name = "wgpuRenderPassEncoderSetPushConstants")
    render_pass_encoder_set_push_constants :: proc(encoder: Render_Pass_Encoder, stages: Shader_Stage_Flags, offset: c.uint32_t, size_bytes: c.uint32_t, data: rawptr) ---

    @(link_name = "wgpuRenderPassEncoderMultiDrawIndirect")
    render_pass_encoder_multi_draw_indirect :: proc(encoder: Render_Pass_Encoder, buffer: Buffer, offset: c.uint64_t, count: c.uint32_t) ---
    @(link_name = "wgpuRenderPassEncoderMultiDrawIndexedIndirect")
    render_pass_encoder_multi_draw_indexed_indirect :: proc(encoder: Render_Pass_Encoder, buffer: Buffer, offset, count: c.uint32_t) ---

    @(link_name = "wgpuRenderPassEncoderMultiDrawIndirectCount")
    render_pass_encoder_multi_draw_indirect_count :: proc(encoder: Render_Pass_Encoder, buffer: Buffer, offset: c.uint64_t, count_buffer: Buffer, count_buffer_offset, max_count: c.uint32_t) ---
    @(link_name = "wgpuRenderPassEncoderMultiDrawIndexedIndirectCount")
    render_pass_encoder_multi_draw_indexed_indirect_count :: proc(encoder: Render_Pass_Encoder, buffer: Buffer, offset: c.uint64_t, count_buffer: Buffer, count_buffer_offset, max_count: c.uint32_t) ---
}
