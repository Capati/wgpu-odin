package webgpu

// Vendor
import "vendor:wgpu"

/*
Handle to a binding group layout.

A `BindGroupLayout` is a handle to the GPU-side layout of a binding group. It
can be used to create a `BindGroupDescriptor` object, which in turn can be used
to create a `BindGroup` object with `DeviceCreateBindGroup`. A series of
`BindGroupLayout`s can also be used to create a `PipelineLayoutDescriptor`,
which can be used to create a `PipelineLayout`.

It can be created with `DeviceCreateBindGroupLayout`.

Corresponds to [WebGPU `GPUBindGroupLayout`](
https://gpuweb.github.io/gpuweb/#gpubindgrouplayout).
*/
BindGroupLayout :: wgpu.BindGroupLayout

/* Sets a debug label for the given `BindGroupLayout`. */
BindGroupLayoutSetLabel :: #force_inline proc "c" (self: BindGroupLayout, label: cstring) {
	wgpu.BindGroupLayoutSetLabel(self, label)
}

/* Increase the reference count. */
BindGroupLayoutAddRef :: #force_inline proc "c" (self: BindGroupLayout) {
	wgpu.BindGroupLayoutAddRef(self)
}

/* Release resources, use to decrease the reference count. */
BindGroupLayoutRelease :: #force_inline proc "c" (self: BindGroupLayout) {
	wgpu.BindGroupLayoutRelease(self)
}

/*
Safely releases the `BindGroupLayout` resources and invalidates the handle. The
procedure checks both the pointer validity and the Bind group layout handle
before releasing.

Note: After calling this, the Bind group layout handle will be set to `nil` and
should not be used.
*/
BindGroupLayoutReleaseSafe :: proc "c" (self: ^BindGroupLayout) {
	if self != nil && self^ != nil {
		wgpu.BindGroupLayoutRelease(self^)
		self^ = nil
	}
}
