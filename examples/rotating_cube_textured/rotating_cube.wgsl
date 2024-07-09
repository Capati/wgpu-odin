struct Uniforms {
    modelViewProjectionMatrix: mat4x4f,
}

@binding(0) @group(0) var<uniform> uniforms: Uniforms;

struct VertexOutput {
    @builtin(position) Position: vec4f,
    @location(0) fragUV: vec2f,
    @location(1) fragPosition: vec4f,
}

@vertex
fn vs_main(
    @location(0) position: vec4f,
    @location(1) uv: vec2f
) -> VertexOutput {
    var output: VertexOutput;
    output.Position = uniforms.modelViewProjectionMatrix * position;
    output.fragUV = uv;
	output.fragPosition = 0.8 * (position + vec4(1.0, 1.0, 1.0, 1.0));
    return output;
}

@group(0) @binding(1) var mySampler: sampler;
@group(0) @binding(2) var myTexture: texture_2d<f32>;

@fragment
fn fs_main(
  @location(0) fragUV: vec2f,
  @location(1) fragPosition: vec4f
) -> @location(0) vec4f {
	let srgb_color = textureSample(myTexture, mySampler, fragUV) * fragPosition;
	let linear_color = srgb_to_linear(srgb_color.rgb);
    return vec4(linear_color, srgb_color.a);
}
