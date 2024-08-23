package wgpu

// Local packages
import wgpu "../bindings"

/*
Handle to a rendering (graphics) pipeline.

A `Render_Pipeline` object represents a graphics pipeline and its stages, bindings, vertex
buffers and targets. It can be created with `device_create_render_pipeline`.

Corresponds to [WebGPU `GPURenderPipeline`](https://gpuweb.github.io/gpuweb/#render-pipeline).
*/
Render_Pipeline :: wgpu.Render_Pipeline

/*
Get an object representing the bind group layout at a given index.
*/
render_pipeline_get_bind_group_layout :: proc "contextless" (
	self: Render_Pipeline,
	index: u32,
	loc := #caller_location,
) -> (
	bind_group_layout: Bind_Group_Layout,
	ok: bool,
) #optional_ok {
	_error_reset_data(loc)

	bind_group_layout = wgpu.render_pipeline_get_bind_group_layout(self, index)

	if get_last_error() != nil {
		if bind_group_layout != nil {
			wgpu.bind_group_layout_release(bind_group_layout)
		}
		return
	}

	when ENABLE_ERROR_HANDLING {
		if bind_group_layout == nil {
			error_update_data(Error_Type.Unknown, "Failed to acquire 'Bind_Group_Layout'")
			return
		}
	}

	return bind_group_layout, true
}

/* set debug label. */
render_pipeline_set_label :: wgpu.render_pipeline_set_label

/* Increase the reference count. */
render_pipeline_reference :: wgpu.render_pipeline_reference

/* Release the `Render_Pipeline` resources. */
render_pipeline_release :: wgpu.render_pipeline_release
