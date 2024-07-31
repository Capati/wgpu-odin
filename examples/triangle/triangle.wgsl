@vertex
fn vs_main(
	@builtin(vertex_index) in_vertex_index: u32
) -> @builtin(position) vec4f {
	var pos = array(
		vec2f( 0.0,  1.0),
		vec2f(-1.0, -1.0),
		vec2f( 1.0, -1.0)
	);

	return vec4f(pos[in_vertex_index], 0.0, 1.0);
}

@fragment
fn fs_main() -> @location(0) vec4f {
	let color = vec3<f32>(1.0, 0.0, 0.0);
	let final_color = apply_color_conversion(color);
	return vec4f(final_color, 1.0);
}
