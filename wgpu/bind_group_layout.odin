package wgpu

/*
Handle to a binding group layout.

A `BindGroupLayout` is a handle to the GPU-side layout of a binding group. It can be used to
create a `BindGroupDescriptor` object, which in turn can be used to create a `BindGroup`
object with `device_create_bind_group`. A series of `BindGroupLayout`s can also be used to
create a `PipelineLayoutDescriptor`, which can be used to create a `PipelineLayout`.

It can be created with `device_create_bind_group_layout`.

Corresponds to [WebGPU `GPUBindGroupLayout`](
https://gpuweb.github.io/gpuweb/#gpubindgrouplayout).
*/
BindGroupLayout :: distinct rawptr

/*
Describes a `BindGroupLayout`.

For use with `device_create_bind_group_layout`.

Corresponds to [WebGPU `GPUBindGroupLayoutDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpubindgrouplayoutdescriptor).
*/
BindGroupLayoutDescriptor :: struct {
	label:   string,
	entries: []BindGroupLayoutEntry,
}

@(disabled = !ODIN_DEBUG)
bind_group_layout_set_label :: proc "contextless" (self: BindGroupLayout, label: string) {
	c_label: StringViewBuffer
	wgpuBindGroupLayoutSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the reference count. */
bind_group_layout_add_ref :: wgpuBindGroupLayoutAddRef

/* Release resources, use to decrease the reference count. */
bind_group_layout_release :: wgpuBindGroupLayoutRelease
