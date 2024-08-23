package wgpu

// The raw bindings
import wgpu "../bindings"

/*
Handle to a pipeline layout.

A `Pipeline_Layout` object describes the available binding groups of a pipeline.
It can be created with `device_create_pipeline_layout`.

Corresponds to [WebGPU `GPUPipelineLayout`](https://gpuweb.github.io/gpuweb/#gpupipelinelayout).
*/
Pipeline_Layout :: wgpu.Pipeline_Layout

/* Set debug label. */
pipeline_layout_set_label :: wgpu.pipeline_layout_set_label

/* Increase the reference count. */
pipeline_layout_reference :: wgpu.pipeline_layout_reference

/* Release the `Pipeline_Layout` resources. */
pipeline_layout_release :: wgpu.pipeline_layout_release
