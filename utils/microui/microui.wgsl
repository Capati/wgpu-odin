struct VertexInput {
    @location(0) position: vec2<f32>,
    @location(1) uv: vec2<f32>,
    @location(2) color: vec4<f32>,
};

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) uv: vec2<f32>,
    @location(1) color: vec4<f32>,
};

@group(0) @binding(0) var atlas_texture: texture_2d<f32>;
@group(0) @binding(1) var atlas_sampler: sampler;

@vertex
fn vs_main(in: VertexInput) -> VertexOutput {
    var out: VertexOutput;
    out.clip_position = vec4(in.position, 0.0, 1.0);
    out.uv = in.uv;
    out.color = in.color;
    return out;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
	let atlas_color = textureSample(atlas_texture, atlas_sampler, in.uv);

    let linear_atlas = vec4<f32>(srgb_to_linear(atlas_color.rgb), atlas_color.a);
    let linear_input = vec4<f32>(srgb_to_linear(in.color.rgb), in.color.a);

	// Perform color multiplication in linear space
    let final_color = linear_input * linear_atlas;

    return final_color;
}
