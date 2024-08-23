package wgpu

// The raw bindings
import wgpu "../bindings"

/*
Pre-prepared reusable bundle of GPU operations.

It only supports a handful of render commands, but it makes them reusable. Executing a
`Render_Bundle` is often more efficient than issuing the underlying commands manually.

It can be created by use of a `Render_Bundle_Encoder`, and executed onto a `Command_Encoder`
using `render_pass_encoder_execute_bundles`.
*/
Render_Bundle :: wgpu.Render_Bundle

/* Set debug label. */
render_bundle_set_label :: wgpu.render_bundle_set_label

/* Increase the reference count. */
render_bundle_reference :: wgpu.render_bundle_reference

/* Release the `Render_Bundle` resources. */
render_bundle_release :: wgpu.render_bundle_release
