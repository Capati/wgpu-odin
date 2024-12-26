package wgpu

/*
Handle to a binding group.

A `BindGroup` represents the set of resources bound to the bindings described by a
`BindGroupLayout`. It can be created with `device_create_bind_group`. A `BindGroup` can
be bound to a particular `RenderPass` with `render_pass_set_bind_group`, or to a
`ComputePass` with `compute_pass_set_bind_group`.

Corresponds to [WebGPU `GPUBindGroup`](https://gpuweb.github.io/gpuweb/#gpubindgroup).
*/
BindGroup :: distinct rawptr

/*
Resource that can be bound to a pipeline.

Corresponds to [WebGPU `GPUBindingResource`](
https://gpuweb.github.io/gpuweb/#typedefdef-gpubindingresource).
*/
BindingResource :: union {
	BufferBinding,
	Sampler,
	TextureView,
	[]Buffer,
	[]Sampler,
	[]TextureView,
}

/*
Describes the segment of a buffer to bind.

Corresponds to [WebGPU `GPUBufferBinding`](
https://gpuweb.github.io/gpuweb/#dictdef-gpubufferbinding).
*/
BufferBinding :: struct {
	buffer: Buffer,
	offset: u64,
	size:   u64,
}

/*
An element of a `BindGroupDescriptor`, consisting of a bindable resource
and the slot to bind it to.

Corresponds to [WebGPU `GPUBindGroupEntry`](
https://gpuweb.github.io/gpuweb/#dictdef-gpubindgroupentry).
*/
BindGroupEntry :: struct {
	binding:  u32,
	resource: BindingResource,
}

/*
Describes a group of bindings and the resources to be bound.

For use with `device_create_bind_group`.

Corresponds to [WebGPU `GPUBindGroupDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpubindgroupdescriptor).
*/
BindGroupDescriptor :: struct {
	label:   string,
	layout:  BindGroupLayout,
	entries: []BindGroupEntry,
}

@(disabled = !ODIN_DEBUG)
bind_group_set_label :: proc "contextless" (self: BindGroup, label: string) {
	c_label: StringViewBuffer
	wgpuBindGroupSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase reference count. */
bind_group_add_ref :: wgpuBindGroupAddRef

/* Release resources, use to decrease the reference count. */
bind_group_release :: wgpuBindGroupRelease

@(private)
WGPUBindGroupEntry :: struct {
	next_in_chain: ^ChainedStruct,
	binding:       u32,
	buffer:        Buffer,
	offset:        u64,
	size:          u64,
	sampler:       Sampler,
	texture_view:  TextureView,
}
