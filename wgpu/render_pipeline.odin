package wgpu

/*
Handle to a rendering (graphics) pipeline.

A `RenderPipeline` object represents a graphics pipeline and its stages, bindings, vertex
buffers and targets. It can be created with `device_create_render_pipeline`.

Corresponds to [WebGPU `GPURenderPipeline`](https://gpuweb.github.io/gpuweb/#render-pipeline).
*/
RenderPipeline :: distinct rawptr

/*
Get an object representing the bind group layout at a given group index.
*/
render_pipeline_get_bind_group_layout :: proc "contextless" (
	self: RenderPipeline,
	group_index: u32,
	loc := #caller_location,
) -> (
	bind_group_layout: BindGroupLayout,
	ok: bool,
) #optional_ok {
	error_reset_data(loc)
	bind_group_layout = wgpuRenderPipelineGetBindGroupLayout(self, group_index)
	if get_last_error() != nil {
		if bind_group_layout != nil {
			wgpuBindGroupLayoutRelease(bind_group_layout)
		}
		return
	}

	when ENABLE_ERROR_HANDLING {
		if bind_group_layout == nil {
			error_update_data(ErrorType.Unknown, "Failed to acquire 'BindGroupLayout'")
			return
		}
	}

	return bind_group_layout, true
}

/* set debug label. */
@(disabled = !ODIN_DEBUG)
render_pipeline_set_label :: proc "contextless" (self: RenderPipeline, label: string) {
	c_label: StringViewBuffer
	wgpuRenderPipelineSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the reference count. */
render_pipeline_add_ref :: wgpuRenderPipelineAddRef

/* Release the `RenderPipeline` resources. */
render_pipeline_release :: wgpuRenderPipelineRelease
