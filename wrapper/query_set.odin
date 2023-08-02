package wgpu

// Package
import wgpu "../bindings"

Query_Set :: struct {
    ptr:          WGPU_Query_Set,
    using vtable: ^Query_Set_VTable,
}

@(private)
Query_Set_VTable :: struct {
    destroy:   proc(self: ^Query_Set),
    get_count: proc(self: ^Query_Set) -> u32,
    get_type:  proc(self: ^Query_Set) -> Query_Type,
    set_label: proc(self: ^Query_Set, label: cstring),
    reference: proc(self: ^Query_Set),
    release:   proc(self: ^Query_Set),
}

@(private)
default_query_set_vtable := Query_Set_VTable {
    destroy   = query_set_destroy,
    get_count = query_set_get_count,
    get_type  = query_set_get_type,
    set_label = query_set_set_label,
    reference = query_set_reference,
}

@(private)
default_query_set := Query_Set {
    ptr    = nil,
    vtable = &default_query_set_vtable,
}

// Destroys the `Query_Set`.
query_set_destroy :: proc(using self: ^Query_Set) {
    wgpu.query_set_destroy(ptr)
}

query_set_get_count :: proc(using self: ^Query_Set) -> u32 {
    return wgpu.query_set_get_count(ptr)
}

query_set_get_type :: proc(using self: ^Query_Set) -> Query_Type {
    return wgpu.query_set_get_type(ptr)
}

query_set_set_label :: proc(using self: ^Query_Set, label: cstring) {
    wgpu.query_set_set_label(ptr, label)
}

query_set_reference :: proc(using self: ^Query_Set) {
    wgpu.query_set_reference(ptr)
}

// Release the `Query_Set`.
query_set_release :: proc(using self: ^Query_Set) {
    wgpu.query_set_release(ptr)
}
