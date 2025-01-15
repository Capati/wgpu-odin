package wgpu

/*
Handle to a compute pipeline.

A `ComputePipeline` object represents a compute pipeline and its single shader stage.
It can be created with `device_create_compute_pipeline`.

Corresponds to [WebGPU `GPUComputePipeline`](https://gpuweb.github.io/gpuweb/#compute-pipeline).
*/
ComputePipeline :: distinct rawptr

/*
Describes a compute pipeline.

For use with `device_create_compute_pipeline`.

Corresponds to [WebGPU `GPUComputePipelineDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpucomputepipelinedescriptor).
*/
ComputePipelineDescriptor :: struct {
	label:       string,
	layout:      PipelineLayout,
	module:      ShaderModule,
	entry_point: string,
	constants:   []ConstantEntry,
}

/*
Get an object representing the bind group layout at a given index.

If this pipeline was created with a default layout, then bind groups created with the returned
`BindGroupLayout` can only be used with this pipeline.

This method will raise a validation error if there is no bind group layout at `index`.
*/
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

/* Sets a debug label for the given `ComputePipeline`. */
@(disabled = !ODIN_DEBUG)
compute_pipeline_set_label :: proc "contextless" (self: ComputePipeline, label: string) {
	c_label: StringViewBuffer
	wgpuComputePipelineSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the `ComputePipeline` reference count. */
compute_pipeline_add_ref :: wgpuComputePipelineAddRef

/* Release the `ComputePipeline` resources, use to decrease the reference count. */
compute_pipeline_release :: wgpuComputePipelineRelease

/*
Safely releases the `ComputePipeline` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
compute_pipeline_release_safe :: #force_inline proc(self: ^ComputePipeline) {
	if self != nil && self^ != nil {
		wgpuComputePipelineRelease(self^)
		self^ = nil
	}
}
