package wgpu

/*
Handle to a binding group.

A `BindGroup` represents the set of resources bound to the bindings described by a
[`BindGroupLayout`]. It can be created with device_create_bind_group. A `BindGroup` can
be bound to a particular `RenderPass` with `render_pass_set_bind_group`, or to a
`Compute_Pass` with `compute_pass_set_bind_group`.

Corresponds to [WebGPU `GPUBindGroup`](https://gpuweb.github.io/gpuweb/#gpubindgroup).
*/
BindGroup :: distinct rawptr

/* Set debug label. */
@(disabled = !ODIN_DEBUG)
bind_group_set_label :: proc "contextless" (self: BindGroup, label: string) {
	c_label: StringViewBuffer
	wgpuBindGroupSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the reference count. */
bind_group_add_ref :: wgpuBindGroupAddRef

/* Release the `BindGroup` resources. */
bind_group_release :: wgpuBindGroupRelease
