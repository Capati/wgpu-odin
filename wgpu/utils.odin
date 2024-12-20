package wgpu

VertexLocation :: struct {
	location: ShaderLocation,
	format:   VertexFormat,
}

size_of_vertex_format :: proc(format: VertexFormat) -> u64 {
	#partial switch format {
	case .Uint8x2, .Sint8x2, .Unorm8x2, .Snorm8x2:
		return 2
	case .Uint8x4, .Sint8x4, .Unorm8x4, .Snorm8x4:
		return 4
	case .Uint16x2, .Sint16x2, .Unorm16x2, .Snorm16x2, .Float16x2:
		return 4
	case .Uint16x4, .Sint16x4, .Unorm16x4, .Snorm16x4, .Float16x4:
		return 8
	case .Float32, .Uint32, .Sint32:
		return 4
	case .Float32x2, .Uint32x2, .Sint32x2:
		return 8
	case .Float32x3, .Uint32x3, .Sint32x3:
		return 12
	case .Float32x4, .Uint32x4, .Sint32x4:
		return 16
	}

	return 0
}

/*
Create an array of `[N]VertexAttribute`, each element representing a vertex attribute with a
specified shader location and format. The attributes' offsets are calculated automatically based
on the size of each format.

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
vertex_attr_array :: proc(
	$N: int,
	locations: ..VertexLocation,
) -> (
	attributes: [N]VertexAttribute,
) {
	assert(len(locations) == N, "Number of locations must match the generic parameter '$N'")

	offset: u64 = 0

	for v, i in locations {
		format := v.format
		attributes[i] = VertexAttribute {
			format          = format,
			offset          = offset,
			shader_location = v.location,
		}
		offset += size_of_vertex_format(format)
	}

	return
}

/* Release a resource. */
release :: proc {
	adapter_release,
	bind_group_release,
	bind_group_layout_release,
	buffer_release,
	command_buffer_release,
	command_encoder_release,
	compute_pass_release,
	compute_pipeline_release,
	device_release,
	instance_release,
	pipeline_layout_release,
	query_set_release,
	queue_release,
	render_bundle_release,
	render_bundle_encoder_release,
	render_pass_release,
	render_pipeline_release,
	sampler_release,
	shader_module_release,
	surface_release,
	texture_release,
	texture_view_release,
}

/* Increase the reference count of a resource. */
add_ref :: proc {
	adapter_add_ref,
	bind_group_add_ref,
	bind_group_layout_add_ref,
	buffer_add_ref,
	command_buffer_add_ref,
	command_encoder_add_ref,
	compute_pass_add_ref,
	compute_pipeline_add_ref,
	device_add_ref,
	instance_add_ref,
	pipeline_layout_add_ref,
	query_set_add_ref,
	queue_add_ref,
	render_bundle_add_ref,
	render_bundle_encoder_add_ref,
	render_pass_add_ref,
	render_pipeline_add_ref,
	sampler_add_ref,
	shader_module_add_ref,
	surface_add_ref,
	texture_add_ref,
	texture_view_add_ref,
}
