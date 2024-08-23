package wgpu

// The raw bindings
import wgpu "../bindings"

/*
Handle to a binding group.

A `Bind_Group` represents the set of resources bound to the bindings described by a
[`BindGroupLayout`]. It can be created with device_create_bind_group. A `Bind_Group` can
be bound to a particular `Render_Pass` with `render_pass_set_bind_group`, or to a
`Compute_Pass` with `compute_pass_set_bind_group`.

Corresponds to [WebGPU `GPUBindGroup`](https://gpuweb.github.io/gpuweb/#gpubindgroup).
*/
Bind_Group :: wgpu.Bind_Group

/* Set debug label. */
bind_group_set_label :: wgpu.bind_group_set_label

/* Increase the reference count. */
bind_group_reference :: wgpu.bind_group_reference

/* Release the `Bind_Group` resources. */
bind_group_release :: wgpu.bind_group_release
