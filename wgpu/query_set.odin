package wgpu

/*
Handle to a query set.

It can be created with `device_create_query_set`.

Corresponds to [WebGPU `GPUQuerySet`](https://gpuweb.github.io/gpuweb/#queryset).
*/
QuerySet :: distinct rawptr

/*
Describes a `QuerySet`.

For use with `device_create_query_set`.

Corresponds to [WebGPU `GPUQuerySetDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuquerysetdescriptor).
*/
QuerySetDescriptor :: struct {
	label:               string,
	type:                QueryType,
	count:               u32,
	pipeline_statistics: []PipelineStatisticsTypes, /* Extras */
}

PIPELINE_STATISTICS :: 0x00030000

/*
Type of query contained in a `QuerySet`.

Corresponds to [WebGPU `GPUQueryType`](
https://gpuweb.github.io/gpuweb/#enumdef-gpuquerytype).
*/
QueryType :: enum i32 {
	Occlusion          = 0x00000001,
	Timestamp          = 0x00000002,
	PipelineStatistics = PIPELINE_STATISTICS, /* Extras */
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
PipelineStatisticsTypes :: enum i32 {
	VertexShaderInvocations   = 0x00000000,
	ClipperInvocations        = 0x00000001,
	ClipperPrimitivesOut      = 0x00000002,
	FragmentShaderInvocations = 0x00000003,
	ComputeShaderInvocations  = 0x00000004,
}

/* Destroys the `QuerySet`. */
query_set_destroy :: wgpuQuerySetDestroy

/* Get the `QuerySet` count. */
query_set_count :: wgpuQuerySetGetCount

/* Get the `QuerySet` type. */
query_set_type :: proc "contextless" (self: QuerySet) -> (type: QueryType) {
	raw_type := cast(i32)(wgpuQuerySetGetType(self))
	switch raw_type {
	case 0:
		type = .Occlusion
	case 1:
		type = .Timestamp
	case PIPELINE_STATISTICS:
		type = .PipelineStatistics
	}
	return
}

/* Sets a debug label for the given `QuerySet`. */
@(disabled = !ODIN_DEBUG)
query_set_set_label :: proc "contextless" (self: QuerySet, label: string) {
	c_label: StringViewBuffer
	wgpuQuerySetSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the `QuerySet` reference count. */
query_set_add_ref :: wgpuQuerySetAddRef

/* Release the `QuerySet` resources, use to decrease the reference count. */
query_set_release :: wgpuQuerySetRelease

@(private)
WGPUQuerySetDescriptor :: struct {
	next_in_chain: ^ChainedStruct,
	label:         StringView,
	type:          QueryType,
	count:         u32,
}
