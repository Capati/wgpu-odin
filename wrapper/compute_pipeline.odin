package wgpu

// The raw bindings
import wgpu "../bindings"

/*
Handle to a compute pipeline.

A `Compute_Pipeline` object represents a compute pipeline and its single shader stage.
It can be created with `device_create_compute_pipeline`.

Corresponds to [WebGPU `GPUComputePipeline`](https://gpuweb.github.io/gpuweb/#compute-pipeline).
*/
Compute_Pipeline :: wgpu.Compute_Pipeline

/* Get an object representing the bind group layout at a given index. */
@(require_results)
compute_pipeline_get_bind_group_layout :: proc "contextless" (
	self: Compute_Pipeline,
	group_index: u32,
	loc := #caller_location,
) -> (
	bind_group_layout: Bind_Group_Layout,
	ok: bool,
) #optional_ok {
	_error_reset_data(loc)

	bind_group_layout = wgpu.compute_pipeline_get_bind_group_layout(self, group_index)

	if get_last_error() != nil {
		if bind_group_layout != nil {
			wgpu.bind_group_layout_release(bind_group_layout)
		}
		return
	}

	if bind_group_layout == nil {
		error_update_data(Error_Type.Unknown, "Failed to acquire 'Bind_Group_Layout'")
		return
	}

	return bind_group_layout, true
}

/* Set debug label. */
compute_pipeline_set_label :: wgpu.compute_pipeline_set_label

/* Increase the reference count. */
compute_pipeline_reference :: wgpu.compute_pipeline_reference

/* Release the `Compute_Pipeline` resources. */
compute_pipeline_release :: wgpu.compute_pipeline_release
