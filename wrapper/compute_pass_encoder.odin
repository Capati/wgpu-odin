package wgpu

// Package
import wgpu "../bindings"

Compute_Pass_Encoder :: struct {
    ptr:          WGPU_Compute_Pass_Encoder,
    err_data:     ^Error_Data,
    using vtable: ^Compute_Pass_Encoder_VTable,
}

@(private)
Compute_Pass_Encoder_VTable :: struct {
    begin_pipeline_statistics_query: proc(
        self: ^Compute_Pass_Encoder,
        query_set: Query_Set,
        query_index: u32,
    ),
    dispatch_workgroups:             proc(
        self: ^Compute_Pass_Encoder,
        workgroup_count_x: u32,
        workgroup_count_y: u32 = 1,
        workgroup_count_z: u32 = 1,
    ),
    dispatch_workgroups_indirect:    proc(
        self: ^Compute_Pass_Encoder,
        indirect_buffer: Buffer,
        indirect_offset: u64,
    ),
    end:                             proc(self: ^Compute_Pass_Encoder) -> Error_Type,
    end_pipeline_statistics_query:   proc(self: ^Compute_Pass_Encoder),
    insert_debug_marker:             proc(self: ^Compute_Pass_Encoder, marker_label: cstring),
    pop_debug_group:                 proc(self: ^Compute_Pass_Encoder),
    push_debug_group:                proc(self: ^Compute_Pass_Encoder, group_label: cstring),
    set_bind_group:                  proc(
        self: ^Compute_Pass_Encoder,
        group_index: u32,
        group: ^Bind_Group,
        dynamic_offsets: []u32 = {},
    ),
    set_label:                       proc(self: ^Compute_Pass_Encoder, label: cstring),
    set_pipeline:                    proc(
        self: ^Compute_Pass_Encoder,
        pipeline: ^Compute_Pipeline,
    ),
    reference:                       proc(self: ^Compute_Pass_Encoder),
    release:                         proc(self: ^Compute_Pass_Encoder),
}

@(private)
default_compute_pass_encoder_vtable := Compute_Pass_Encoder_VTable {
    begin_pipeline_statistics_query = compute_pass_encoder_begin_pipeline_statistics_query,
    dispatch_workgroups             = compute_pass_encoder_dispatch_workgroups,
    dispatch_workgroups_indirect    = compute_pass_encoder_dispatch_workgroups_indirect,
    end                             = compute_pass_encoder_end,
    end_pipeline_statistics_query   = compute_pass_encoder_end_pipeline_statistics_query,
    insert_debug_marker             = compute_pass_encoder_insert_debug_marker,
    pop_debug_group                 = compute_pass_encoder_pop_debug_group,
    push_debug_group                = compute_pass_encoder_push_debug_group,
    set_bind_group                  = compute_pass_encoder_set_bind_group,
    set_label                       = compute_pass_encoder_set_label,
    set_pipeline                    = compute_pass_encoder_set_pipeline,
    reference                       = compute_pass_encoder_reference,
    release                         = compute_pass_encoder_release,
}

@(private)
default_compute_pass_encoder := Compute_Pass_Encoder {
    ptr    = nil,
    vtable = &default_compute_pass_encoder_vtable,
}

compute_pass_encoder_begin_pipeline_statistics_query :: proc(
    using self: ^Compute_Pass_Encoder,
    query_set: Query_Set,
    query_index: u32,
) {
    wgpu.compute_pass_encoder_begin_pipeline_statistics_query(ptr, query_set.ptr, query_index)
}

compute_pass_encoder_dispatch_workgroups :: proc(
    using self: ^Compute_Pass_Encoder,
    workgroup_count_x: u32,
    workgroup_count_y: u32 = 1,
    workgroup_count_z: u32 = 1,
) {
    wgpu.compute_pass_encoder_dispatch_workgroups(
        ptr,
        workgroup_count_x,
        workgroup_count_y,
        workgroup_count_z,
    )
}

compute_pass_encoder_dispatch_workgroups_indirect :: proc(
    using self: ^Compute_Pass_Encoder,
    indirect_buffer: Buffer,
    indirect_offset: u64,
) {
    wgpu.compute_pass_encoder_dispatch_workgroups_indirect(
        ptr,
        indirect_buffer.ptr,
        indirect_offset,
    )
}

compute_pass_encoder_end :: proc(using self: ^Compute_Pass_Encoder) -> Error_Type {
    err_data.type = .No_Error

    wgpu.compute_pass_encoder_end(ptr)

    return err_data.type
}

compute_pass_encoder_end_pipeline_statistics_query :: proc(using self: ^Compute_Pass_Encoder) {
    wgpu.compute_pass_encoder_end_pipeline_statistics_query(ptr)
}

compute_pass_encoder_insert_debug_marker :: proc(
    using self: ^Compute_Pass_Encoder,
    marker_label: cstring,
) {
    wgpu.compute_pass_encoder_insert_debug_marker(ptr, marker_label)
}

compute_pass_encoder_pop_debug_group :: proc(using self: ^Compute_Pass_Encoder) {
    wgpu.compute_pass_encoder_pop_debug_group(ptr)
}

compute_pass_encoder_push_debug_group :: proc(
    using self: ^Compute_Pass_Encoder,
    group_label: cstring,
) {
    wgpu.compute_pass_encoder_push_debug_group(ptr, group_label)
}

compute_pass_encoder_set_bind_group :: proc(
    using self: ^Compute_Pass_Encoder,
    group_index: u32,
    group: ^Bind_Group,
    dynamic_offsets: []u32 = {},
) {
    dynamic_offset_count := cast(uint)len(dynamic_offsets)

    if dynamic_offset_count == 0 {
        wgpu.compute_pass_encoder_set_bind_group(ptr, group_index, group.ptr, 0, nil)
    } else {
        wgpu.compute_pass_encoder_set_bind_group(
            ptr,
            group_index,
            group.ptr,
            dynamic_offset_count,
            raw_data(dynamic_offsets),
        )
    }
}

compute_pass_encoder_set_label :: proc(using self: ^Compute_Pass_Encoder, label: cstring) {
    wgpu.compute_pass_encoder_set_label(ptr, label)
}

compute_pass_encoder_set_pipeline :: proc(
    using self: ^Compute_Pass_Encoder,
    pipeline: ^Compute_Pipeline,
) {
    wgpu.compute_pass_encoder_set_pipeline(ptr, pipeline.ptr)
}

compute_pass_encoder_reference :: proc(using self: ^Compute_Pass_Encoder) {
    wgpu.compute_pass_encoder_reference(ptr)
}

compute_pass_encoder_release :: proc(using self: ^Compute_Pass_Encoder) {
    wgpu.compute_pass_encoder_release(ptr)
}
