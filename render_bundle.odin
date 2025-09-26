package webgpu

// Vendor
import "vendor:wgpu"

/*
Pre-prepared reusable bundle of GPU operations.

It only supports a handful of render commands, but it makes them reusable.
Executing a `RenderBundle` is often more efficient than issuing the underlying
commands manually.

It can be created by use of a `RenderBundleEncoder`, and executed onto a
`Command_Encoder` using `RenderPassExecuteBundles`.
*/
RenderBundle :: wgpu.RenderBundle

/* Sets a debug label for the given `RenderBundle`. */
RenderBundleSetLabel :: wgpu.RenderBundleSetLabel

/* Increase the `RenderBundle` reference count. */
RenderBundleAddRef :: #force_inline proc "c" (self: RenderBundle) {
	wgpu.RenderBundleAddRef(self)
}

/* Release the `RenderBundle` resources, use to decrease the reference count. */
RenderBundleRelease :: #force_inline proc "c" (self: RenderBundle) {
	wgpu.RenderBundleRelease(self)
}

/*
Safely releases the `RenderBundle` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
RenderBundleReleaseSafe :: proc "c" (self: ^RenderBundle) {
	if self != nil && self^ != nil {
		wgpu.RenderBundleRelease(self^)
		self^ = nil
	}
}
