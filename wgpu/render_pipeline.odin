package wgpu

/*
Handle to a rendering (graphics) pipeline.

A `RenderPipeline` object represents a graphics pipeline and its stages, bindings, vertex
buffers and targets. It can be created with `device_create_render_pipeline`.

Corresponds to [WebGPU `GPURenderPipeline`](https://gpuweb.github.io/gpuweb/#render-pipeline).
*/
RenderPipeline :: distinct rawptr

/*
Get an object representing the bind group layout at a given index.

If this pipeline was created with a default layout, then bind groups created with the returned
`BindGroupLayout` can only be used with this pipeline.

This method will raise a validation error if there is no bind group layout at `index`.
*/
render_pipeline_get_bind_group_layout :: proc "contextless" (
	self: RenderPipeline,
	index: u32,
	loc := #caller_location,
) -> (
	bind_group_layout: BindGroupLayout,
	ok: bool,
) #optional_ok {
	error_reset_data(loc)
	bind_group_layout = wgpuRenderPipelineGetBindGroupLayout(self, index)
	if has_error() {
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

/*
Describes how the vertex buffer is interpreted.

For use in `VertexState`.

Corresponds to [WebGPU `GPUVertexBufferLayout`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuvertexbufferlayout).
*/
VertexBufferLayout :: struct {
	array_stride: u64,
	step_mode:    VertexStepMode,
	attributes:   []VertexAttribute,
}

/*
Describes the vertex processing in a render pipeline.

For use in `RenderPipelineDescriptor`.

Corresponds to [WebGPU `GPUVertexState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuvertexstate).
*/
VertexState :: struct {
	module:      ShaderModule,
	entry_point: string,
	constants:   []ConstantEntry,
	buffers:     []VertexBufferLayout,
}

/*
Describes the fragment processing in a render pipeline.

For use in `RenderPipelineDescriptor`.

Corresponds to [WebGPU `GPUFragmentState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpufragmentstate).
*/
FragmentState :: struct {
	module:      ShaderModule,
	entry_point: string,
	constants:   []ConstantEntry,
	targets:     []ColorTargetState,
}

/*
Describes a render (graphics) pipeline.

For use with `device_create_render_pipeline`.

Corresponds to [WebGPU `GPURenderPipelineDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpurenderpipelinedescriptor).
*/
RenderPipelineDescriptor :: struct {
	label:         string,
	layout:        PipelineLayout,
	vertex:        VertexState,
	primitive:     PrimitiveState,
	depth_stencil: DepthStencilState,
	multisample:   MultisampleState,
	fragment:      ^FragmentState,
}

/* Sets a label for the given `RenderPipeline`. */
@(disabled = !ODIN_DEBUG)
render_pipeline_set_label :: proc "contextless" (self: RenderPipeline, label: string) {
	c_label: StringViewBuffer
	wgpuRenderPipelineSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the `RenderPipeline` reference count. */
render_pipeline_add_ref :: wgpuRenderPipelineAddRef

/* Release the `RenderPipeline` resources, use to decrease the reference count. */
render_pipeline_release :: wgpuRenderPipelineRelease

/*
Safely releases the `RenderPipeline` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
render_pipeline_release_safe :: #force_inline proc(self: ^RenderPipeline) {
	if self != nil && self^ != nil {
		wgpuRenderPipelineRelease(self^)
		self^ = nil
	}
}
