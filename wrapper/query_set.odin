package wgpu

// Base
import intr "base:intrinsics"

// Package
import wgpu "../bindings"

// Handle to a query set.
//
// It can be created with `device_create_query_set`.
Query_Set :: struct {
	ptr:   Raw_Query_Set,
	type:  Query_Type,
	count: u32,
}

// Destroys the `Query_Set`.
query_set_destroy :: proc "contextless" (using self: Query_Set) {
	wgpu.query_set_destroy(ptr)
}

// Get the `Query_Set` count.
query_set_get_count :: proc "contextless" (using self: Query_Set) -> u32 {
	return count
}

// Get the `Query_Set` type.
query_set_get_type :: proc "contextless" (
	self: Query_Set,
	$T: typeid,
) -> (
	value: T,
	ok: bool,
) where intr.type_is_variant_of(T, Query_Type) #optional_ok {
	value, ok = self.type.(T)
	return
}

// Get the `Query_Set` type from a variant.
query_set_get_type_assert :: proc(
	self: Query_Set,
	$T: typeid,
) -> T where intr.type_is_variant_of(T, Query_Type) {
	value, ok := query_set_get_type(self, T)
	assert(ok, "Invalid query type")
	return value
}

// Set debug label.
query_set_set_label :: proc "contextless" (using self: Query_Set, label: cstring) {
	wgpu.query_set_set_label(ptr, label)
}

// Increase the reference count.
query_set_reference :: proc "contextless" (using self: Query_Set) {
	wgpu.query_set_reference(ptr)
}

// Release the `Query_Set`.
query_set_release :: #force_inline proc "contextless" (using self: Query_Set) {
	wgpu.query_set_release(ptr)
}

// Release the `Query_Set` and modify the raw pointer to `nil`.
query_set_release_and_nil :: proc "contextless" (using self: ^Query_Set) {
	if ptr == nil do return
	wgpu.query_set_release(ptr)
	ptr = nil
}
