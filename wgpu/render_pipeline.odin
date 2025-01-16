package wgpu

/*
Handle to a rendering (graphics) pipeline.

A `Render_Pipeline` object represents a graphics pipeline and its stages, bindings, vertex
buffers and targets. It can be created with `device_create_render_pipeline`.

Corresponds to [WebGPU `GPURenderPipeline`](https://gpuweb.github.io/gpuweb/#render-pipeline).
*/
Render_Pipeline :: distinct rawptr

/*
Get an object representing the bind group layout at a given index.

If this pipeline was created with a default layout, then bind groups created with the returned
`Bind_Group_Layout` can only be used with this pipeline.

This method will raise a validation error if there is no bind group layout at `index`.
*/
render_pipeline_get_bind_group_layout :: proc "contextless" (
	self: Render_Pipeline,
	index: u32,
	loc := #caller_location,
) -> (
	bind_group_layout: Bind_Group_Layout,
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
			error_update_data(Error_Type.Unknown, "Failed to acquire 'Bind_Group_Layout'")
			return
		}
	}

	return bind_group_layout, true
}

/*
Describes how the vertex buffer is interpreted.

For use in `Vertex_State`.

Corresponds to [WebGPU `GPUVertexBufferLayout`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuvertexbufferlayout).
*/
Vertex_Buffer_Layout :: struct {
	array_stride: u64,
	step_mode:    Vertex_Step_Mode,
	attributes:   []Vertex_Attribute,
}

/*
Describes the vertex processing in a render pipeline.

For use in `Render_Pipeline_Descriptor`.

Corresponds to [WebGPU `GPUVertexState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuvertexstate).
*/
Vertex_State :: struct {
	module:      Shader_Module,
	entry_point: string,
	constants:   []Constant_Entry,
	buffers:     []Vertex_Buffer_Layout,
}

/*
Describes the fragment processing in a render pipeline.

For use in `Render_Pipeline_Descriptor`.

Corresponds to [WebGPU `GPUFragmentState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpufragmentstate).
*/
Fragment_State :: struct {
	module:      Shader_Module,
	entry_point: string,
	constants:   []Constant_Entry,
	targets:     []Color_Target_State,
}

/*
Describes a render (graphics) pipeline.

For use with `device_create_render_pipeline`.

Corresponds to [WebGPU `GPURenderPipelineDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpurenderpipelinedescriptor).
*/
Render_Pipeline_Descriptor :: struct {
	label:         string,
	layout:        Pipeline_Layout,
	vertex:        Vertex_State,
	primitive:     Primitive_State,
	depth_stencil: Depth_Stencil_State,
	multisample:   Multisample_State,
	fragment:      ^Fragment_State,
}

/* Sets a label for the given `Render_Pipeline`. */
@(disabled = !ODIN_DEBUG)
render_pipeline_set_label :: proc "contextless" (self: Render_Pipeline, label: string) {
	c_label: String_View_Buffer
	wgpuRenderPipelineSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the `Render_Pipeline` reference count. */
render_pipeline_add_ref :: wgpuRenderPipelineAddRef

/* Release the `Render_Pipeline` resources, use to decrease the reference count. */
render_pipeline_release :: wgpuRenderPipelineRelease

/*
Safely releases the `Render_Pipeline` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
render_pipeline_release_safe :: #force_inline proc(self: ^Render_Pipeline) {
	if self != nil && self^ != nil {
		wgpuRenderPipelineRelease(self^)
		self^ = nil
	}
}
