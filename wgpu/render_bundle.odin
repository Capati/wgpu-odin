package wgpu

/*
Pre-prepared reusable bundle of GPU operations.

It only supports a handful of render commands, but it makes them reusable. Executing a
`RenderBundle` is often more efficient than issuing the underlying commands manually.

It can be created by use of a `RenderBundleEncoder`, and executed onto a `CommandEncoder`
using `render_pass_encoder_execute_bundles`.
*/
RenderBundle :: distinct rawptr

/*
Describes a `RenderBundle`.

Corresponds to [WebGPU `GPURenderBundleDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpurenderbundledescriptor).
*/
RenderBundleDescriptor :: struct {
	label: string,
}

/* Sets a debug label for the given `RenderBundle`. */
@(disabled = !ODIN_DEBUG)
render_bundle_set_label :: proc "contextless" (self: RenderBundle, label: string) {
	c_label: StringViewBuffer
	wgpuRenderBundleSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the `RenderBundle` reference count. */
render_bundle_add_ref :: wgpuRenderBundleAddRef

/* Release the `RenderBundle` resources, use to decrease the reference count. */
render_bundle_release :: wgpuRenderBundleRelease
