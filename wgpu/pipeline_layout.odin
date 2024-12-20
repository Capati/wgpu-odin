package wgpu

/*
Handle to a pipeline layout.

A `PipelineLayout` object describes the available binding groups of a pipeline.
It can be created with `device_create_pipeline_layout`.

Corresponds to [WebGPU `GPUPipelineLayout`](https://gpuweb.github.io/gpuweb/#gpupipelinelayout).
*/
PipelineLayout :: distinct rawptr

/* Set debug label. */
@(disabled = !ODIN_DEBUG)
pipeline_layout_set_label :: proc "contextless" (self: PipelineLayout, label: string) {
	c_label: StringViewBuffer
	wgpuPipelineLayoutSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the reference count. */
pipeline_layout_add_ref :: wgpuPipelineLayoutAddRef

/* Release the `PipelineLayout` resources. */
pipeline_layout_release :: wgpuPipelineLayoutRelease
