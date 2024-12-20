struct Uniforms {
	modelViewProjectionMatrix: mat4x4f,
}

@binding(0) @group(0) var<uniform> uniforms: Uniforms;

struct VertexOutput {
	@builtin(position) Position: vec4f,
	@location(0) fragUV: vec2f,
	@location(1) fragColor: vec4f,
}

@vertex
fn vs_main(
	@location(0) position: vec4f,
	@location(1) color: vec4f,
	@location(2) uv: vec2f
) -> VertexOutput {
	var output: VertexOutput;
	output.Position = uniforms.modelViewProjectionMatrix * position;
	output.fragUV = uv;
	output.fragColor = color;
	return output;
}

@fragment
fn fs_main(
	@location(0) fragUV: vec2f,
	@location(1) fragColor: vec4f
) -> @location(0) vec4f {
	return fragColor;
}
