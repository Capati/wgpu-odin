package wgpu

// Package
import wgpu "../bindings"

// Handle to a query set.
//
// It can be created with `device_create_query_set`.
Query_Set :: struct {
	ptr: Raw_Query_Set,
}

// Destroys the `Query_Set`.
query_set_destroy :: proc(using self: ^Query_Set) {
	wgpu.query_set_destroy(ptr)
}

// Get the `Query_Set` count.
query_set_get_count :: proc(using self: ^Query_Set) -> u32 {
	return wgpu.query_set_get_count(ptr)
}

// Get the `Query_Set` type.
query_set_get_type :: proc(using self: ^Query_Set) -> Query_Type {
	return wgpu.query_set_get_type(ptr)
}

// Set debug label.
query_set_set_label :: proc(using self: ^Query_Set, label: cstring) {
	wgpu.query_set_set_label(ptr, label)
}

// Increase the reference count.
query_set_reference :: proc(using self: ^Query_Set) {
	wgpu.query_set_reference(ptr)
}

// Release the `Query_Set`.
query_set_release :: proc(using self: ^Query_Set) {
	if ptr == nil do return
	wgpu.query_set_release(ptr)
	ptr = nil
}
