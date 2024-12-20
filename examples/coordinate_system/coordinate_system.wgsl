struct Output {
	@builtin(position) position : vec4<f32>,
	@location(0) uv : vec2<f32>
};

@vertex
fn vs_main(
	@location(0) inPos: vec3<f32>,
	@location(1) inUV: vec2<f32>
) -> Output {
	var output: Output;
	output.uv = inUV;
	output.position = vec4<f32>(inPos.xyz, 1.0);
	return output;
}

@group(0) @binding(0) var textureColor: texture_2d<f32>;
@group(0) @binding(1) var samplerColor: sampler;

@fragment
fn fs_main(
@location(0) inUV : vec2<f32>
) -> @location(0) vec4<f32> {
	return textureSample(textureColor, samplerColor, inUV);
}
