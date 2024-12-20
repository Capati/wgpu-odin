package examples_common

// Packages
import "base:runtime"
import la "core:math/linalg"

// Local packages
import app "root:utils/application"
import "root:wgpu"

Material :: struct {
	allocator:       runtime.Allocator,
	name:            string,
	diffuse_texture: app.Texture,
	bind_group:      wgpu.BindGroup,
}

Mesh :: struct {
	allocator:     runtime.Allocator,
	name:          string,
	vertex_buffer: wgpu.Buffer,
	index_buffer:  wgpu.Buffer,
	num_elements:  u32,
	material_id:   uint,
}

Model :: struct {
	allocator: runtime.Allocator,
	meshes:    []Mesh,
	materials: []Material,
}

ModelVertex :: struct {
	vertices:       la.Vector3f32,
	texture_coords: la.Vector2f32,
	normals:        la.Vector3f32,
}

MODEL_VERTEX_LAYOUT :: wgpu.VertexBufferLayout {
	array_stride = size_of(ModelVertex),
	step_mode    = .Vertex,
	attributes   = {
		{offset = 0, shader_location = 0, format = .Float32x3},
		{
			offset = u64(offset_of(ModelVertex, texture_coords)),
			shader_location = 1,
			format = .Float32x2,
		},
		{offset = u64(offset_of(ModelVertex, normals)), shader_location = 2, format = .Float32x3},
	},
}

mesh_draw :: proc(
	rpass: wgpu.RenderPass,
	mesh: Mesh,
	material: Material,
	camera_bind_group: wgpu.BindGroup,
) {
	#force_inline mesh_draw_instanced(rpass, mesh, material, {0, 1}, camera_bind_group)
}

mesh_draw_instanced :: proc(
	rpass: wgpu.RenderPass,
	mesh: Mesh,
	material: Material,
	instances: wgpu.Range(u32),
	camera_bind_group: wgpu.BindGroup,
) {
	wgpu.render_pass_set_vertex_buffer(rpass, 0, {buffer = mesh.vertex_buffer})
	wgpu.render_pass_set_index_buffer(rpass, {buffer = mesh.index_buffer}, .Uint32)
	wgpu.render_pass_set_bind_group(rpass, 0, material.bind_group)
	wgpu.render_pass_set_bind_group(rpass, 1, camera_bind_group)
	wgpu.render_pass_draw_indexed(rpass, {0, mesh.num_elements}, 0, instances)
}

model_draw :: proc(rpass: wgpu.RenderPass, model: ^Model, camera_bind_group: wgpu.BindGroup) {
	#force_inline model_draw_instanced(rpass, model, {0, 1}, camera_bind_group)
}

model_draw_instanced :: proc(
	rpass: wgpu.RenderPass,
	model: ^Model,
	instances: wgpu.Range(u32),
	camera_bind_group: wgpu.BindGroup,
) {
	for &m in model.meshes {
		material := model.materials[m.material_id]
		mesh_draw_instanced(rpass, m, material, instances, camera_bind_group)
	}
}
