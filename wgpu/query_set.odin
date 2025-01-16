package wgpu

/*
Handle to a query set.

It can be created with `device_create_query_set`.

Corresponds to [WebGPU `GPUQuerySet`](https://gpuweb.github.io/gpuweb/#queryset).
*/
Query_Set :: distinct rawptr

/*
Describes a `Query_Set`.

For use with `device_create_query_set`.

Corresponds to [WebGPU `GPUQuerySetDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuquerysetdescriptor).
*/
Query_Set_Descriptor :: struct {
	label:               string,
	type:                Query_Type,
	count:               u32,
	pipeline_statistics: []Pipeline_Statistics_Types, /* Extras */
}

PIPELINE_STATISTICS :: 0x00030000

/*
Type of query contained in a `Query_Set`.

Corresponds to [WebGPU `GPUQueryType`](
https://gpuweb.github.io/gpuweb/#enumdef-gpuquerytype).
*/
Query_Type :: enum i32 {
	Occlusion           = 0x00000001,
	Timestamp           = 0x00000002,
	Pipeline_Statistics = PIPELINE_STATISTICS, /* Extras */
}

/*
Flags for which pipeline data should be recorded.

The amount of values written when resolved depends
on the amount of flags. If 3 flags are enabled, 3
64-bit values will be written per-query.

The order they are written is the order they are declared
in this bitflags. If you enabled `CLIPPER_PRIMITIVES_OUT`
and `COMPUTE_SHADER_INVOCATIONS`, it would write 16 bytes,
the first 8 bytes being the primitive out value, the last 8
bytes being the compute shader invocation count.
*/
Pipeline_Statistics_Types :: enum i32 {
	Vertex_Shader_Invocations   = 0x00000000,
	Clipper_Invocations         = 0x00000001,
	Clipper_Primitives_Out      = 0x00000002,
	Fragment_Shader_Invocations = 0x00000003,
	Compute_Shader_Invocations  = 0x00000004,
}

/* Destroys the `Query_Set`. */
query_set_destroy :: wgpuQuerySetDestroy

/* Get the `Query_Set` count. */
query_set_count :: wgpuQuerySetGetCount

/* Get the `Query_Set` type. */
query_set_type :: proc "contextless" (self: Query_Set) -> (type: Query_Type) {
	raw_type := cast(i32)(wgpuQuerySetGetType(self))
	switch raw_type {
	case 0:
		type = .Occlusion
	case 1:
		type = .Timestamp
	case PIPELINE_STATISTICS:
		type = .Pipeline_Statistics
	}
	return
}

/* Sets a debug label for the given `Query_Set`. */
@(disabled = !ODIN_DEBUG)
query_set_set_label :: proc "contextless" (self: Query_Set, label: string) {
	c_label: String_View_Buffer
	wgpuQuerySetSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the `Query_Set` reference count. */
query_set_add_ref :: wgpuQuerySetAddRef

/* Release the `Query_Set` resources, use to decrease the reference count. */
query_set_release :: wgpuQuerySetRelease

/*
Safely releases the `Query_Set` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
query_set_release_safe :: #force_inline proc(self: ^Query_Set) {
	if self != nil && self^ != nil {
		wgpuQuerySetRelease(self^)
		self^ = nil
	}
}

@(private)
WGPU_Query_Set_Descriptor :: struct {
	next_in_chain: ^Chained_Struct,
	label:         String_View,
	type:          Query_Type,
	count:         u32,
}
