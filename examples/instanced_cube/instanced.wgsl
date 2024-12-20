struct InstanceInput {
    @location(5) model_matrix_0: vec4<f32>,
    @location(6) model_matrix_1: vec4<f32>,
    @location(7) model_matrix_2: vec4<f32>,
    @location(8) model_matrix_3: vec4<f32>,
};

struct VertexInput {
	@location(0) position : vec4f,
	@location(1) uv : vec2f,
}

struct VertexOutput {
    @builtin(position) Position : vec4f,
    @location(0) fragUV : vec2f,
    @location(1) fragPosition: vec4f,
}

@vertex
fn vs_main(
	model: VertexInput,
	instance: InstanceInput,
) -> VertexOutput {
    let model_matrix = mat4x4<f32>(
        instance.model_matrix_0,
        instance.model_matrix_1,
        instance.model_matrix_2,
        instance.model_matrix_3,
    );

    var output : VertexOutput;
    output.Position = model_matrix * model.position;
    output.fragUV = model.uv;
    output.fragPosition = 0.5 * (model.position + vec4(1.0));
    return output;
}

@fragment
fn fs_main(
    @location(0) fragUV: vec2f,
    @location(1) fragPosition: vec4f
) -> @location(0) vec4f {
    return fragPosition;
}
