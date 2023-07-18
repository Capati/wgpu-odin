package wgpu_bindings

import "core:c"

Chained_Struct :: struct {
    next:  ^Chained_Struct,
    stype: SType,
}

Chained_Struct_Out :: struct {
    next:  ^Chained_Struct_Out,
    stype: SType,
}

Adapter_Properties :: struct {
    next_in_chain:      ^Chained_Struct_Out,
    vendor_id:          c.uint32_t,
    vendor_name:        cstring,
    architecture:       cstring,
    device_id:          c.uint32_t,
    name:               cstring,
    driver_description: cstring,
    adapter_type:       Adapter_Type,
    backend_type:       Backend_Type,
}

Bind_Group_Entry :: struct {
    next_in_chain: ^Chained_Struct,
    binding:       c.uint32_t,
    buffer:        Buffer,
    offset:        c.uint64_t,
    size:          c.uint64_t,
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
    has_dynamic_offset: bool,
    min_binding_size:   c.uint64_t,
}

Buffer_Descriptor :: struct {
    next_in_chain:      ^Chained_Struct,
    label:              cstring,
    usage:              Buffer_Usage_Flags,
    size:               c.uint64_t,
    mapped_at_creation: bool,
}

Color :: struct {
    r: c.double,
    g: c.double,
    b: c.double,
    a: c.double,
}

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
    line_num:       c.uint64_t,
    line_pos:       c.uint64_t,
    offset:         c.uint64_t,
    length:         c.uint64_t,
    utf16_line_pos: c.uint64_t,
    utf16_offset:   c.uint64_t,
    utf16_length:   c.uint64_t,
}

Compute_Pass_Timestamp_Write :: struct {
    query_set:   Query_Set,
    query_index: c.uint32_t,
    location:    Compute_Pass_Timestamp_Location,
}

Constant_Entry :: struct {
    next_in_chain: ^Chained_Struct,
    key:           cstring,
    value:         c.double,
}

Extent_3D :: struct {
    width:                 c.uint32_t,
    height:                c.uint32_t,
    depth_or_array_layers: c.uint32_t,
}

Instance_Descriptor :: struct {
    next_in_chain: ^Chained_Struct,
}

Limits :: struct {
    max_texture_dimension_1d:                        c.uint32_t,
    max_texture_dimension_2d:                        c.uint32_t,
    max_texture_dimension_3d:                        c.uint32_t,
    max_texture_array_layers:                        c.uint32_t,
    max_bind_groups:                                 c.uint32_t,
    max_bindings_per_bind_group:                     c.uint32_t,
    max_dynamic_uniform_buffers_per_pipeline_layout: c.uint32_t,
    max_dynamic_storage_buffers_per_pipeline_layout: c.uint32_t,
    max_sampled_textures_per_shader_stage:           c.uint32_t,
    max_samplers_per_shader_stage:                   c.uint32_t,
    max_storage_buffers_per_shader_stage:            c.uint32_t,
    max_storage_textures_per_shader_stage:           c.uint32_t,
    max_uniform_buffers_per_shader_stage:            c.uint32_t,
    max_uniform_buffer_binding_size:                 c.uint64_t,
    max_storage_buffer_binding_size:                 c.uint64_t,
    min_uniform_buffer_offset_alignment:             c.uint32_t,
    min_storage_buffer_offset_alignment:             c.uint32_t,
    max_vertex_buffers:                              c.uint32_t,
    max_buffer_size:                                 c.uint64_t,
    max_vertex_attributes:                           c.uint32_t,
    max_vertex_buffer_array_stride:                  c.uint32_t,
    max_inter_stage_shader_components:               c.uint32_t,
    max_inter_stage_shader_variables:                c.uint32_t,
    max_color_attachments:                           c.uint32_t,
    max_color_attachment_bytes_per_sample:           c.uint32_t,
    max_compute_workgroup_storage_size:              c.uint32_t,
    max_compute_invocations_per_workgroup:           c.uint32_t,
    max_compute_workgroup_size_x:                    c.uint32_t,
    max_compute_workgroup_size_y:                    c.uint32_t,
    max_compute_workgroup_size_z:                    c.uint32_t,
    max_compute_workgroups_per_dimension:            c.uint32_t,
}

Multisample_State :: struct {
    next_in_chain:             ^Chained_Struct,
    count:                     c.uint32_t,
    mask:                      c.uint32_t,
    alpha_to_coverage_enabled: bool,
}

Origin3D :: struct {
    x: c.uint32_t,
    y: c.uint32_t,
    z: c.uint32_t,
}

Pipeline_Layout_Descriptor :: struct {
    next_in_chain:           ^Chained_Struct,
    label:                   cstring,
    bind_group_layout_count: c.size_t,
    bind_group_layouts:      ^Bind_Group_Layout,
}

Primitive_Depth_Clip_Control :: struct {
    chain:           Chained_Struct,
    unclipped_depth: bool,
}

Primitive_State :: struct {
    next_in_chain:      ^Chained_Struct,
    topology:           Primitive_Topology,
    strip_index_format: Index_Format,
    front_face:         Front_Face,
    cull_mode:          Cull_Mode,
}

Query_Set_Descriptor :: struct {
    next_in_chain:             ^Chained_Struct,
    label:                     cstring,
    type:                      Query_Type,
    count:                     c.uint32_t,
    pipeline_statistics:       ^Pipeline_Statistic_Name,
    pipeline_statistics_count: c.size_t,
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
    color_formats_count:  c.size_t,
    color_formats:        ^Texture_Format,
    depth_stencil_format: Texture_Format,
    sample_count:         c.uint32_t,
    depth_read_only:      bool,
    stencil_read_only:    bool,
}

Render_Pass_Depth_Stencil_Attachment :: struct {
    view:                Texture_View,
    depth_load_op:       Load_Op,
    depth_store_op:      Store_Op,
    depth_clear_value:   c.float,
    depth_read_only:     bool,
    stencil_load_op:     Load_Op,
    stencil_store_op:    Store_Op,
    stencil_clear_value: c.uint32_t,
    stencil_read_only:   bool,
}

Render_Pass_Descriptor_Max_Draw_Count :: struct {
    chain:          Chained_Struct,
    max_draw_count: c.uint64_t,
}

Render_Pass_Timestamp_Write :: struct {
    query_set:   Query_Set,
    query_index: c.uint32_t,
    location:    Render_Pass_Timestamp_Location,
}

Request_Adapter_Options :: struct {
    next_in_chain:          ^Chained_Struct,
    compatible_surface:     Surface,
    power_preference:       Power_Preference,
    backend_type:           Backend_Type,
    force_fallback_adapter: bool,
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
    lod_min_clamp:  c.float,
    lod_max_clamp:  c.float,
    compare:        Compare_Function,
    max_anisotropy: c.uint16_t,
}

Shader_Module_Compilation_Hint :: struct {
    next_in_chain: ^Chained_Struct,
    entry_point:   cstring,
    layout:        Pipeline_Layout,
}

Shader_Module_Spirv_Descriptor :: struct {
    chain:     Chained_Struct,
    code_size: c.uint32_t,
    code:      ^c.uint32_t,
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
    window:     c.uint32_t,
}

Surface_Descriptor_From_Xlib_Window :: struct {
    chain:   Chained_Struct,
    display: rawptr,
    window:  c.uint32_t,
}

Swap_Chain_Descriptor :: struct {
    next_in_chain: ^Chained_Struct,
    label:         cstring,
    usage:         Texture_Usage_Flags,
    format:        Texture_Format,
    width:         c.uint32_t,
    height:        c.uint32_t,
    present_mode:  Present_Mode,
}

Texture_Binding_Layout :: struct {
    next_in_chain:  ^Chained_Struct,
    sample_type:    Texture_Sample_Type,
    view_dimension: Texture_View_Dimension,
    multisampled:   bool,
}

Texture_Data_Layout :: struct {
    next_in_chain:  ^Chained_Struct,
    offset:         c.uint64_t,
    bytes_per_row:  c.uint32_t,
    rows_per_image: c.uint32_t,
}

Texture_View_Descriptor :: struct {
    next_in_chain:     ^Chained_Struct,
    label:             cstring,
    format:            Texture_Format,
    dimension:         Texture_View_Dimension,
    base_mip_level:    c.uint32_t,
    mip_level_count:   c.uint32_t,
    base_array_layer:  c.uint32_t,
    array_layer_count: c.uint32_t,
    aspect:            Texture_Aspect,
}

Vertex_Attribute :: struct {
    format:          Vertex_Format,
    offset:          c.uint64_t,
    shader_location: c.uint32_t,
}

Bind_Group_Descriptor :: struct {
    next_in_chain: ^Chained_Struct,
    label:         cstring,
    layout:        Bind_Group_Layout,
    entry_count:   c.size_t,
    entries:       ^Bind_Group_Entry,
}

Bind_Group_Layout_Entry :: struct {
    next_in_chain:   ^Chained_Struct,
    binding:         c.uint32_t,
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
    message_count: c.size_t,
    messages:      ^Compilation_Message,
}

Compute_Pass_Descriptor :: struct {
    next_in_chain:         ^Chained_Struct,
    label:                 cstring,
    timestamp_write_count: c.size_t,
    timestamp_writes:      ^Compute_Pass_Timestamp_Write,
}

Depth_Stencil_State :: struct {
    next_in_chain:          ^Chained_Struct,
    format:                 Texture_Format,
    depth_write_enabled:    bool,
    depth_compare:          Compare_Function,
    stencil_front:          Stencil_Face_State,
    stencil_back:           Stencil_Face_State,
    stencil_read_mask:      c.uint32_t,
    stencil_write_mask:     c.uint32_t,
    depth_bias:             c.int32_t,
    depth_bias_slope_scale: c.float,
    depth_bias_clamp:       c.float,
}

Image_Copy_Buffer :: struct {
    next_in_chain: ^Chained_Struct,
    layout:        Texture_Data_Layout,
    buffer:        Buffer,
}

Image_Copy_Texture :: struct {
    next_in_chain: ^Chained_Struct,
    texture:       Texture,
    mip_level:     c.uint32_t,
    origin:        Origin3D,
    aspect:        Texture_Aspect,
}

Programmable_Stage_Descriptor :: struct {
    next_in_chain:  ^Chained_Struct,
    module:         Shader_Module,
    entry_point:    cstring,
    constant_count: c.size_t,
    constants:      ^Constant_Entry,
}

Render_Pass_Color_Attachment :: struct {
    view:           Texture_View,
    resolve_target: Texture_View,
    load_op:        Load_Op,
    store_op:       Store_Op,
    clear_value:    Color,
}

Required_Limits :: struct {
    next_in_chain: ^Chained_Struct,
    limits:        Limits,
}

Shader_Module_Descriptor :: struct {
    next_in_chain: ^Chained_Struct,
    label:         cstring,
    hint_count:    c.size_t,
    hints:         ^Shader_Module_Compilation_Hint,
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
    mip_level_count:   c.uint32_t,
    sample_count:      c.uint32_t,
    view_format_count: c.size_t,
    view_formats:      ^Texture_Format,
}

Vertex_Buffer_Layout :: struct {
    array_stride:    c.uint64_t,
    step_mode:       Vertex_Step_Mode,
    attribute_count: c.size_t,
    attributes:      ^Vertex_Attribute,
}

Bind_Group_Layout_Descriptor :: struct {
    next_in_chain: ^Chained_Struct,
    label:         cstring,
    entry_count:   c.size_t,
    entries:       ^Bind_Group_Layout_Entry,
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
    next_in_chain:           ^Chained_Struct,
    label:                   cstring,
    required_features_count: c.size_t,
    required_features:       [^]Feature_Name,
    required_limits:         [^]Required_Limits,
    default_queue:           Queue_Descriptor,
    device_lost_callback:    Device_Lost_Callback,
    device_lost_userdata:    rawptr,
}

Render_Pass_Descriptor :: struct {
    next_in_chain:            ^Chained_Struct,
    label:                    cstring,
    color_attachment_count:   c.size_t,
    color_attachments:        ^Render_Pass_Color_Attachment,
    depth_stencil_attachment: ^Render_Pass_Depth_Stencil_Attachment,
    occlusion_query_set:      Query_Set,
    timestamp_write_count:    c.size_t,
    timestamp_writes:         ^Render_Pass_Timestamp_Write,
}

Vertex_State :: struct {
    next_in_chain:  ^Chained_Struct,
    module:         Shader_Module,
    entry_point:    cstring,
    constant_count: c.size_t,
    constants:      ^Constant_Entry,
    buffer_count:   c.size_t,
    buffers:        ^Vertex_Buffer_Layout,
}

Fragment_State :: struct {
    next_in_chain:  ^Chained_Struct,
    module:         Shader_Module,
    entry_point:    cstring,
    constant_count: c.size_t,
    constants:      ^Constant_Entry,
    target_count:   c.size_t,
    targets:        ^Color_Target_State,
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
