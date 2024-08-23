package wgpu

// The raw bindings
import wgpu "../bindings"

/*
Handle to a binding group layout.

A `Bind_Group_Layout` is a handle to the GPU-side layout of a binding group. It can be used to
create a `Bind_Group_Descriptor` object, which in turn can be used to create a `Bind_Group`
object with `device_create_bind_group`. A series of `Bind_Group_Layout`s can also be used to
create a `Pipeline_Layout_Descriptor`, which can be used to create a `Pipeline_Layout`.

It can be created with `device_create_bind_group_layout`.

Corresponds to [WebGPU `GPUBindGroupLayout`](
https://gpuweb.github.io/gpuweb/#gpubindgrouplayout).
*/
Bind_Group_Layout :: wgpu.Bind_Group_Layout

/* Set debug label. */
bind_group_layout_set_label :: wgpu.bind_group_layout_set_label

/* Increase the reference count. */
bind_group_layout_reference :: wgpu.bind_group_layout_reference

/* Release the `Bind_Group_Layout` resources. */
bind_group_layout_release :: wgpu.bind_group_layout_release
