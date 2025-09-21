package webgpu

// Vendor
import "vendor:wgpu"

/*
Handle to a query set.

It can be created with `DeviceCreateQuerySet`.

Corresponds to [WebGPU `GPUQuerySet`](https://gpuweb.github.io/gpuweb/#queryset).
*/
QuerySet :: wgpu.QuerySet

/* Destroys the `QuerySet`. */
QuerySetDestroy :: wgpu.QuerySetDestroy

/* Get the `QuerySet` count. */
QuerySetGetCount :: wgpu.QuerySetGetCount

/* Get the `QuerySet` type. */
QuerySetGetType :: wgpu.QuerySetGetType

/* Sets a debug label for the given `QuerySet`. */
QuerySetSetLabel :: wgpu.QuerySetSetLabel

/* Increase the `QuerySet` reference count. */
QuerySetAddRef :: wgpu.QuerySetAddRef

/* Release the `QuerySet` resources, use to decrease the reference count. */
QuerySetRelease :: wgpu.QuerySetRelease

/*
Safely releases the `QuerySet` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
QuerySetReleaseSafe :: proc "c" (self: ^QuerySet) {
	if self != nil && self^ != nil {
		wgpu.QuerySetRelease(self^)
		self^ = nil
	}
}
