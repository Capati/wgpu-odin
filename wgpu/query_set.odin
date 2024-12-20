package wgpu

// Packages
import intr "base:intrinsics"

/*
Handle to a query set.

It can be created with `device_create_query_set`.

Corresponds to [WebGPU `GPUQuerySet`](https://gpuweb.github.io/gpuweb/#queryset).
*/
QuerySet :: distinct rawptr

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
	case 0x00030000:
		type = .PipelineStatistics
	}
	return
}

/* Set debug label. */
@(disabled = !ODIN_DEBUG)
query_set_set_label :: proc "contextless" (self: QuerySet, label: string) {
	c_label: StringViewBuffer
	wgpuQuerySetSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the reference count. */
query_set_add_ref :: wgpuQuerySetAddRef

/* Release the `QuerySet` resources. */
query_set_release :: wgpuQuerySetRelease
