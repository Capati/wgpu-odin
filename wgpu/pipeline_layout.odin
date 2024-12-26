package wgpu

/*
Handle to a pipeline layout.

A `PipelineLayout` object describes the available binding groups of a pipeline.
It can be created with `device_create_pipeline_layout`.

Corresponds to [WebGPU `GPUPipelineLayout`](https://gpuweb.github.io/gpuweb/#gpupipelinelayout).
*/
PipelineLayout :: distinct rawptr

/*
Describes a `PipelineLayout`.

For use with `device_create_pipeline_layout`.

Corresponds to [WebGPU `GPUPipelineLayoutDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpupipelinelayoutdescriptor).
*/
PipelineLayoutDescriptor :: struct {
	label:                string,
	bind_group_layouts:   []BindGroupLayout,
	push_constant_ranges: []PushConstantRange,
}

/* Sets a debug label for the given `PipelineLayout`. */
@(disabled = !ODIN_DEBUG)
pipeline_layout_set_label :: proc "contextless" (self: PipelineLayout, label: string) {
	c_label: StringViewBuffer
	wgpuPipelineLayoutSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the `PipelineLayout` reference count. */
pipeline_layout_add_ref :: wgpuPipelineLayoutAddRef

/* Release the `PipelineLayout` resources, use to decrease the reference count. */
pipeline_layout_release :: wgpuPipelineLayoutRelease
