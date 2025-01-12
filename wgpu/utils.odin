package wgpu

// Packages
import intr "base:intrinsics"

/* Aligns the given size to the specified alignment. */
@(require_results)
align_size :: #force_inline proc "contextless" (#any_int size, align: u64) -> u64 {
	return (size + (align - 1)) & ~(align - 1)
}

/* location information for a vertex in a shader. */
VertexLocation :: struct {
	location: ShaderLocation,
	format:   VertexFormat,
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
		offset += vertex_format_size(format)
	}

	return
}

Range :: struct($T: typeid) where intr.type_is_ordered(T) {
	start, end: T,
}

range_init :: proc "contextless" (
	$T: typeid,
	start, end: T,
) -> Range(T) where intr.type_is_ordered(T) {
	return Range(T){start, end}
}

/* Get the length of the Range */
range_len :: proc "contextless" (r: Range($T)) -> T {
	if range_is_empty(r) {
		return 0
	}
	return (r.end - r.start) + 1
}

/* Check if the range is empty */
range_is_empty :: proc "contextless" (r: Range($T)) -> bool {
	return r.end < r.start
}

/* Check if a value is within the Range */
range_contains :: proc "contextless" (r: Range($T), value: T) -> bool {
	return value >= r.start && value < r.end
}

/* Iterator for the Range */
Range_Iterator :: struct($T: typeid) {
	current, end: T,
}

/* Create an iterator for the Range */
range_iterator :: proc "contextless" (r: Range($T)) -> Range_Iterator(T) {
	return Range_Iterator(T){r.start, r.end}
}

/* Get the next value from the iterator */
range_next :: proc "contextless" (it: ^Range_Iterator($T), value: ^T) -> bool {
	if it.current < it.end {
		value^ = it.current
		it.current += 1
		return true
	}
	return false
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
	surface_texture_release,
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
