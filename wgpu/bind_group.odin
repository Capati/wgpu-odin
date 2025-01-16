package wgpu

/*
Handle to a binding group.

A `Bind_Group` represents the set of resources bound to the bindings described by a
`Bind_Group_Layout`. It can be created with `device_create_bind_group`. A `Bind_Group` can
be bound to a particular `Render_Pass` with `render_pass_set_bind_group`, or to a
`Compute_Pass` with `compute_pass_set_bind_group`.

Corresponds to [WebGPU `GPUBindGroup`](https://gpuweb.github.io/gpuweb/#gpubindgroup).
*/
Bind_Group :: distinct rawptr

/*
Resource that can be bound to a pipeline.

Corresponds to [WebGPU `GPUBindingResource`](
https://gpuweb.github.io/gpuweb/#typedefdef-gpubindingresource).
*/
Binding_Resource :: union {
	Buffer_Binding,
	Sampler,
	Texture_View,
	[]Buffer,
	[]Sampler,
	[]Texture_View,
}

/*
Describes the segment of a buffer to bind.

Corresponds to [WebGPU `GPUBufferBinding`](
https://gpuweb.github.io/gpuweb/#dictdef-gpubufferbinding).
*/
Buffer_Binding :: struct {
	buffer: Buffer,
	offset: u64,
	size:   u64,
}

/*
An element of a `Bind_Group_Descriptor`, consisting of a bindable resource
and the slot to bind it to.

Corresponds to [WebGPU `GPUBindGroupEntry`](
https://gpuweb.github.io/gpuweb/#dictdef-gpubindgroupentry).
*/
Bind_Group_Entry :: struct {
	binding:  u32,
	resource: Binding_Resource,
}

/*
Describes a group of bindings and the resources to be bound.

For use with `device_create_bind_group`.

Corresponds to [WebGPU `GPUBindGroupDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpubindgroupdescriptor).
*/
Bind_Group_Descriptor :: struct {
	label:   string,
	layout:  Bind_Group_Layout,
	entries: []Bind_Group_Entry,
}

@(disabled = !ODIN_DEBUG)
bind_group_set_label :: proc "contextless" (self: Bind_Group, label: string) {
	c_label: String_View_Buffer
	wgpuBindGroupSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase reference count. */
bind_group_add_ref :: wgpuBindGroupAddRef

/* Release resources, use to decrease the reference count. */
bind_group_release :: wgpuBindGroupRelease

/*
Safely releases the `Bind_Group` resources and invalidates the handle.
The procedure checks both the pointer validity and the Bind group handle before releasing.

Note: After calling this, the Bind group handle will be set to `nil` and should not be used.
*/
bind_group_release_safe :: #force_inline proc(self: ^Bind_Group) {
	if self != nil && self^ != nil {
		wgpuBindGroupRelease(self^)
		self^ = nil
	}
}

@(private)
WGPU_Bind_Group_Entry :: struct {
	next_in_chain: ^Chained_Struct,
	binding:       u32,
	buffer:        Buffer,
	offset:        u64,
	size:          u64,
	sampler:       Sampler,
	texture_view:  Texture_View,
}
