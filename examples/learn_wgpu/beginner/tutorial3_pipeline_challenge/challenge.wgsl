// Vertex shader

struct VertexOutput {
	@builtin(position) clip_position: vec4<f32>,
	@location(0) color: vec2<f32>,
};

@vertex
fn vs_main(
	@builtin(vertex_index) in_vertex_index: u32,
) -> VertexOutput {
	var out: VertexOutput;
	let x = f32(1 - i32(in_vertex_index)) * 0.5;
	let y = f32(i32(in_vertex_index & 1u) * 2 - 1) * 0.5;
	out.color = vec2<f32>(smoothstep(-0.5, 0.5, x), smoothstep(-0.5, 0.5, y));
	out.clip_position = vec4<f32>(x, y, 0.0, 1.0);
	return out;
}

// Fragment shader

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
	return vec4(srgb_to_linear(vec3<f32>(in.color, 0.5)), 1.0);
}

