package wgpu

/*
Handle to a compute pipeline.

A `ComputePipeline` object represents a compute pipeline and its single shader stage.
It can be created with `device_create_compute_pipeline`.

Corresponds to [WebGPU `GPUComputePipeline`](https://gpuweb.github.io/gpuweb/#compute-pipeline).
*/
ComputePipeline :: distinct rawptr

/* Get an object representing the bind group layout at a given index. */
@(require_results)
compute_pipeline_get_bind_group_layout :: proc "contextless" (
	self: ComputePipeline,
	group_index: u32,
	loc := #caller_location,
) -> (
	bind_group_layout: BindGroupLayout,
	ok: bool,
) #optional_ok {
	error_reset_data(loc)
	bind_group_layout = wgpuComputePipelineGetBindGroupLayout(self, group_index)
	if get_last_error() != nil {
		if bind_group_layout != nil {
			wgpuBindGroupLayoutRelease(bind_group_layout)
		}
		return
	}

	if bind_group_layout == nil {
		error_update_data(ErrorType.Unknown, "Failed to acquire 'BindGroupLayout'")
		return
	}

	return bind_group_layout, true
}

/* Set debug label. */
@(disabled = !ODIN_DEBUG)
compute_pipeline_set_label :: proc "contextless" (self: ComputePipeline, label: string) {
	c_label: StringViewBuffer
	wgpuComputePipelineSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the reference count. */
compute_pipeline_add_ref :: wgpuComputePipelineAddRef

/* Release the `ComputePipeline` resources. */
compute_pipeline_release :: wgpuComputePipelineRelease
