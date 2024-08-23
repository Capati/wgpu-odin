package wgpu

// STD Library
import intr "base:intrinsics"

// The raw bindings
import wgpu "../bindings"

/*
Handle to a query set.

It can be created with `device_create_query_set`.

Corresponds to [WebGPU `GPUQuerySet`](https://gpuweb.github.io/gpuweb/#queryset).
*/
Query_Set :: wgpu.Query_Set

/* Destroys the `Query_Set`. */
query_set_destroy :: wgpu.query_set_destroy

/* Get the `Query_Set` count. */
query_set_count :: wgpu.query_set_get_count

/* Get the `Query_Set` type. */
query_set_type :: proc "contextless" (self: Query_Set) -> (type: Query_Type) {
	raw_type := cast(i32)(wgpu.query_set_get_type(self))

	switch raw_type {
	case 0          : type = .Occlusion
	case 1          : type = .Timestamp
	case 0x00030000 : type = .Pipeline_Statistics
	}

	return
}

/* Set debug label. */
query_set_set_label :: wgpu.query_set_set_label

/* Increase the reference count. */
query_set_reference :: wgpu.query_set_reference

/* Release the `Query_Set` resources. */
query_set_release :: wgpu.query_set_release
