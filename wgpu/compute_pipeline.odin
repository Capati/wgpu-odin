package wgpu

/*
Handle to a compute pipeline.

A `Compute_Pipeline` object represents a compute pipeline and its single shader stage.
It can be created with `device_create_compute_pipeline`.

Corresponds to [WebGPU `GPUComputePipeline`](https://gpuweb.github.io/gpuweb/#compute-pipeline).
*/
Compute_Pipeline :: distinct rawptr

/*
Describes a compute pipeline.

For use with `device_create_compute_pipeline`.

Corresponds to [WebGPU `GPUComputePipelineDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpucomputepipelinedescriptor).
*/
Compute_Pipeline_Descriptor :: struct {
	label:       string,
	layout:      Pipeline_Layout,
	module:      Shader_Module,
	entry_point: string,
	constants:   []Constant_Entry,
}

/*
Get an object representing the bind group layout at a given index.

If this pipeline was created with a default layout, then bind groups created with the returned
`Bind_Group_Layout` can only be used with this pipeline.

This method will raise a validation error if there is no bind group layout at `index`.
*/
@(require_results)
compute_pipeline_get_bind_group_layout :: proc "contextless" (
	self: Compute_Pipeline,
	group_index: u32,
	loc := #caller_location,
) -> (
	bind_group_layout: Bind_Group_Layout,
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
		error_update_data(Error_Type.Unknown, "Failed to acquire 'Bind_Group_Layout'")
		return
	}

	return bind_group_layout, true
}

/* Sets a debug label for the given `Compute_Pipeline`. */
@(disabled = !ODIN_DEBUG)
compute_pipeline_set_label :: proc "contextless" (self: Compute_Pipeline, label: string) {
	c_label: String_View_Buffer
	wgpuComputePipelineSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the `Compute_Pipeline` reference count. */
compute_pipeline_add_ref :: wgpuComputePipelineAddRef

/* Release the `Compute_Pipeline` resources, use to decrease the reference count. */
compute_pipeline_release :: wgpuComputePipelineRelease

/*
Safely releases the `Compute_Pipeline` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
compute_pipeline_release_safe :: #force_inline proc(self: ^Compute_Pipeline) {
	if self != nil && self^ != nil {
		wgpuComputePipelineRelease(self^)
		self^ = nil
	}
}
