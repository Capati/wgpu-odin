@vertex
fn vs(
	@builtin(vertex_index) in_vertex_index: u32
) -> @builtin(position) vec4f {
	var pos = array(
		vec2f( 0.0,  1.0),
		vec2f(-1.0, -1.0),
		vec2f( 1.0, -1.0)
	);

	return vec4f(pos[in_vertex_index], 0.0, 1.0);
}

@fragment fn fs() -> @location(0) vec4f {
	return vec4f(1.0, 0.0, 0.0, 1.0);
}
