package webgpu

/*
Aligns the given size to the specified alignment.
*/
@(require_results)
AlignSize :: #force_inline proc "contextless" (#any_int size, align: u64) -> u64 {
	return (size + (align - 1)) & ~(align - 1)
}


/*
Check if the given value is aligned to the specified alignment.
*/
@(require_results)
IsAligned :: #force_inline proc "contextless" (#any_int value, align: u64) -> bool {
    return (value & (align - 1)) == 0
}

/*
location information for a vertex in a shader.
*/
VertexLocation :: struct {
	location: ShaderLocation,
	format:   VertexFormat,
}

/*
Create an array of `[N]VertexAttribute`, each element representing a vertex
attribute with a specified shader location and format. The attributes' offsets
are calculated automatically based on the size of each format.

Arguments:

- `N`: Compile-time constant specifying the number of vertex attributes.
- `locations`: Specify the shader location and vertex format for each `N` locations.

Example:

	attributes := wgpu.vertex_attr_array(2, {0, .Float32x4}, {1, .Float32x2})

Result in:

	attributes := []VertexAttribute {
		{format = .Float32x4, offset = 0, shader_location = 0},
		{
			format = .Float32x2,
			offset = 16,
			shader_location = 1,
		},
	},

**Notes**:

- The number of locations provided must match the compile-time constant `N`.
- Offsets are calculated automatically, assuming tightly packed attributes.
*/
VertexAttrArray :: proc "contextless" (
	$N: int,
	locations: ..VertexLocation,
) -> (
	attributes: [N]VertexAttribute,
) {
	assert_contextless(len(locations) == N,
		"Number of locations must match the generic parameter '$N'")

	offset: u64 = 0

	for v, i in locations {
		format := v.format
		attributes[i] = VertexAttribute {
			format         = format,
			offset         = offset,
			shaderLocation = v.location,
		}
		offset += VertexFormatGetSize(format)
	}

	return
}

/*
Release a resource.
*/
Release :: proc {
	AdapterRelease,
	BindGroupRelease,
	BindGroupLayoutRelease,
	BufferRelease,
	CommandBufferRelease,
	CommandEncoderRelease,
	ComputePassRelease,
	ComputePipelineRelease,
	DeviceRelease,
	InstanceRelease,
	PipelineLayoutRelease,
	QuerySetRelease,
	QueueRelease,
	RenderBundleRelease,
	RenderBundleEncoderRelease,
	RenderPassRelease,
	RenderPipelineRelease,
	SamplerRelease,
	ShaderModuleRelease,
	SurfaceRelease,
	TextureRelease,
	TextureViewRelease,
	SurfaceTextureRelease,
}

/*
Safely releases a resource.
*/
ReleaseSafe :: proc {
	AdapterReleaseSafe,
	BindGroupReleaseSafe,
	BindGroupLayoutReleaseSafe,
	BufferReleaseSafe,
	CommandBufferReleaseSafe,
	CommandEncoderReleaseSafe,
	ComputePassReleaseSafe,
	ComputePipelineReleaseSafe,
	DeviceReleaseSafe,
	InstanceReleaseSafe,
	PipelineLayoutReleaseSafe,
	QuerySetReleaseSafe,
	QueueReleaseSafe,
	RenderBundleReleaseSafe,
	RenderBundleEncoderReleaseSafe,
	RenderPassReleaseSafe,
	RenderPipelineReleaseSafe,
	SamplerReleaseSafe,
	ShaderModuleReleaseSafe,
	SurfaceReleaseSafe,
	TextureReleaseSafe,
	TextureViewReleaseSafe,
	SurfaceTextureReleaseSafe,
}

/*
Increase the reference count of a resource.
*/
AddRef :: proc {
	AdapterAddRef,
	BindGroupAddRef,
	BindGroupLayoutAddRef,
	BufferAddRef,
	CommandBufferAddRef,
	CommandEncoderAddRef,
	ComputePassAddRef,
	ComputePipelineAddRef,
	DeviceAddRef,
	InstanceAddRef,
	PipelineLayoutAddRef,
	QuerySetAddRef,
	QueueAddRef,
	RenderBundleAddRef,
	RenderBundleEncoderAddRef,
	RenderPassAddRef,
	RenderPipelineAddRef,
	SamplerAddRef,
	ShaderModuleAddRef,
	SurfaceAddRef,
	TextureAddRef,
	TextureViewAddRef,
}
