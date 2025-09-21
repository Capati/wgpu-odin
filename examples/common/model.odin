package examples_common

// Core
import "base:runtime"
import la "core:math/linalg"

// Local packages
import wgpu "../../"
import app "../../utils/application"

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

Model_Vertex :: struct {
	vertices:       la.Vector3f32,
	texture_coords: la.Vector2f32,
	normals:        la.Vector3f32,
}

MODEL_VERTEX_LAYOUT :: wgpu.VertexBufferLayout {
	arrayStride = size_of(Model_Vertex),
	stepMode    = .Vertex,
	attributes   = {
		{offset = 0, shaderLocation = 0, format = .Float32x3},
		{
			offset = u64(offset_of(Model_Vertex, texture_coords)),
			shaderLocation = 1,
			format = .Float32x2,
		},
		{offset = u64(offset_of(Model_Vertex, normals)), shaderLocation = 2, format = .Float32x3},
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
	wgpu.RenderPassSetVertexBuffer(rpass, 0, {buffer = mesh.vertex_buffer})
	wgpu.RenderPassSetIndexBuffer(rpass, {buffer = mesh.index_buffer}, .Uint32)
	wgpu.RenderPassSetBindGroup(rpass, 0, material.bind_group)
	wgpu.RenderPassSetBindGroup(rpass, 1, camera_bind_group)
	wgpu.RenderPassDrawIndexed(rpass, {0, mesh.num_elements}, 0, instances)
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
