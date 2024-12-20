struct VertexOutput {
    @builtin(position) position: vec4f,
    @location(0) color: vec3f,
}

@vertex
fn vs_main(
    @builtin(vertex_index) in_vertex_index: u32
) -> VertexOutput {
    var pos = array(
        vec2f( 0.0,  1.0),  // Top vertex
        vec2f(-1.0, -1.0),  // Bottom left vertex
        vec2f( 1.0, -1.0)   // Bottom right vertex
    );

    // Define colors for each vertex
    var colors = array(
        vec3f(1.0, 0.0, 0.0),  // Red for top vertex
        vec3f(0.0, 1.0, 0.0),  // Green for bottom left
        vec3f(0.0, 0.0, 1.0)   // Blue for bottom right
    );

    var output: VertexOutput;
    output.position = vec4f(pos[in_vertex_index], 0.0, 1.0);
    output.color = colors[in_vertex_index];
    return output;
}

@fragment
fn fs_main(
    @location(0) color: vec3f
) -> @location(0) vec4f {
	return vec4f(color, 1.0);
}
