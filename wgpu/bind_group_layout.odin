package wgpu

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
Bind_Group_Layout :: distinct rawptr

/*
Describes a `Bind_Group_Layout`.

For use with `device_create_bind_group_layout`.

Corresponds to [WebGPU `GPUBindGroupLayoutDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpubindgrouplayoutdescriptor).
*/
Bind_Group_Layout_Descriptor :: struct {
	label:   string,
	entries: []Bind_Group_Layout_Entry,
}

@(disabled = !ODIN_DEBUG)
bind_group_layout_set_label :: proc "contextless" (self: Bind_Group_Layout, label: string) {
	c_label: String_View_Buffer
	wgpuBindGroupLayoutSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the reference count. */
bind_group_layout_add_ref :: wgpuBindGroupLayoutAddRef

/* Release resources, use to decrease the reference count. */
bind_group_layout_release :: wgpuBindGroupLayoutRelease

/*
Safely releases the `Bind_Group_Layout` resources and invalidates the handle.
The procedure checks both the pointer validity and the Bind group layout handle before releasing.

Note: After calling this, the Bind group layout handle will be set to `nil` and should not be used.
*/
bind_group_layout_release_safe :: #force_inline proc(self: ^Bind_Group_Layout) {
	if self != nil && self^ != nil {
		wgpuBindGroupLayoutRelease(self^)
		self^ = nil
	}
}
