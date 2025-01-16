package wgpu

/*
Handle to a pipeline layout.

A `Pipeline_Layout` object describes the available binding groups of a pipeline.
It can be created with `device_create_pipeline_layout`.

Corresponds to [WebGPU `GPUPipelineLayout`](https://gpuweb.github.io/gpuweb/#gpupipelinelayout).
*/
Pipeline_Layout :: distinct rawptr

/*
Describes a `Pipeline_Layout`.

For use with `device_create_pipeline_layout`.

Corresponds to [WebGPU `GPUPipelineLayoutDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpupipelinelayoutdescriptor).
*/
Pipeline_Layout_Descriptor :: struct {
	label:                string,
	bind_group_layouts:   []Bind_Group_Layout,
	push_constant_ranges: []Push_Constant_Range,
}

/* Sets a debug label for the given `Pipeline_Layout`. */
@(disabled = !ODIN_DEBUG)
pipeline_layout_set_label :: proc "contextless" (self: Pipeline_Layout, label: string) {
	c_label: String_View_Buffer
	wgpuPipelineLayoutSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the `Pipeline_Layout` reference count. */
pipeline_layout_add_ref :: wgpuPipelineLayoutAddRef

/* Release the `Pipeline_Layout` resources, use to decrease the reference count. */
pipeline_layout_release :: wgpuPipelineLayoutRelease

/*
Safely releases the `Pipeline_Layout` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
pipeline_layout_release_safe :: #force_inline proc(self: ^Pipeline_Layout) {
	if self != nil && self^ != nil {
		wgpuPipelineLayoutRelease(self^)
		self^ = nil
	}
}
