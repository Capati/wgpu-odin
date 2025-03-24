struct Uniforms {
    modelViewProjectionMatrix: mat4x4<f32>,
}

@binding(0) @group(0) var<uniform> uniforms: Uniforms;
@binding(1) @group(0) var mySampler: sampler;
@binding(2) @group(0) var myTexture: texture_2d<f32>;

struct VertexOutput {
    @builtin(position) Position: vec4<f32>,
    @location(0) fragUV: vec2<f32>,
    @location(1) fragPosition: vec4<f32>,
}

@vertex
fn vs_main(
    @location(0) position: vec4<f32>,
    @location(1) uv: vec2<f32>
) -> VertexOutput {
    var output: VertexOutput;
    output.Position = uniforms.modelViewProjectionMatrix * position;
    output.fragUV = uv;
    output.fragPosition = 0.5 * (position + vec4<f32>(1.0, 1.0, 1.0, 1.0));
    return output;
}

@fragment
fn fs_main(
    @location(0) fragUV: vec2<f32>,
    @location(1) fragPosition: vec4<f32>
) -> @location(0) vec4<f32> {
	let texColor = textureSample(myTexture, mySampler, fragUV * 0.8 + vec2(0.1));
	// The threshold of 0.01 used in the shader depends on the base gray color
	let f = select(1.0, 0.0, length(texColor.rgb - vec3(0.5)) < 0.01);
	return f * texColor + (1.0 - f) * fragPosition;
}
