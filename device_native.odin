#+build !js
package webgpu

// Vendor
import "vendor:wgpu"

/*
Check for resource cleanups and mapping callbacks. Will block if `wait` is `true`.

Return `true` if the queue is empty, or `false` if there are more queue
submissions still in flight. (Note that, unless access to the [`Queue`] is
coordinated somehow, this information could be out of date by the time the
caller receives it. `Queue`s can be shared between threads, so other threads
could submit new work at any time.)

When running on WebGPU, this is a no-op. `Device`s are automatically polled.
*/
DevicePoll :: proc "c" (
	self: Device,
	wait: bool = true,
	submissionIndex: ^SubmissionIndex = nil,
) -> bool {
	return bool(wgpu.DevicePoll(self, b32(wait), submissionIndex))
}

ShaderModuleDescriptorSpirV :: struct {
	label: string,
	sources: []u32,
}

/* Creates a shader module from SPIR-V binary directly. */
@(require_results)
DeviceCreateShaderModuleSpirV :: proc "c" (
	self: Device,
	descriptor: ShaderModuleDescriptorSpirV,
) -> (
	shaderModule: ShaderModule,
) {
	assert_contextless(descriptor.sources != nil && len(descriptor.sources) > 0,
		"SPIR-V source is required")

	raw_desc: wgpu.ShaderModuleDescriptorSpirV
	raw_desc.label = descriptor.label
	raw_desc.sourceSize = cast(u32)len(descriptor.sources)
	raw_desc.source = raw_data(descriptor.sources)

	shaderModule = wgpu.DeviceCreateShaderModuleSpirV(self, &raw_desc)

	return
}
