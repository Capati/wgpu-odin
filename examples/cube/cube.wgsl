struct VertexOut {
	@builtin(position) position: vec4f,
	@location(0) color: vec4f
}

@group(0) @binding(0)
var<uniform> mvpMat : mat4x4<f32>;

@vertex
fn vertex_main(
	@location(0) position: vec3f,
	@location(1) color: vec3f
	) -> VertexOut
{
	var output : VertexOut;
	output.position = mvpMat * vec4f(position, 1.0);
	output.color = vec4f(color, 1.0);
	return output;
}

@fragment
fn fragment_main(fragData: VertexOut) -> @location(0) vec4f
{
	return fragData.color;
}
