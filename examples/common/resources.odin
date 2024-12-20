package examples_common

// Packages
import "base:runtime"
import la "core:math/linalg"
import "core:path/filepath"
import "core:strings"

// Local packages
import app "root:utils/application"
import "root:utils/tobj"
import "root:wgpu"

load_model :: proc(
	filename: string,
	device: wgpu.Device,
	queue: wgpu.Queue,
	layout: wgpu.BindGroupLayout,
	allocator := context.allocator,
) -> (
	model: ^Model,
	ok: bool,
) {
	ta := context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == ta)

	obj_models, obj_materials, obj_err := tobj.load_obj(filename, allocator = ta)
	if obj_err != nil {
		tobj.print_error(obj_err)
		return
	}

	materials := make([dynamic]Material, allocator)
	mtl_dir := filepath.dir(filename, ta)
	for &m in obj_materials {
		mtl_filename := filepath.join({mtl_dir, m.diffuse_texture}, allocator = ta)
		diffuse_texture := app.create_texture_from_file(mtl_filename, device, queue) or_return
		bind_group := wgpu.device_create_bind_group(
			device,
			{
				layout = layout,
				entries = {
					{binding = 0, resource = diffuse_texture.view},
					{binding = 1, resource = diffuse_texture.sampler},
				},
			},
		) or_return
		append(
			&materials,
			Material {
				allocator = allocator,
				name = strings.clone(m.name, allocator),
				diffuse_texture = diffuse_texture,
				bind_group = bind_group,
			},
		)
	}

	meshes := make([dynamic]Mesh, allocator)
	for &m in obj_models {
		vertices: [dynamic]ModelVertex;vertices.allocator = ta
		for i in 0 ..< len(m.mesh.vertices) {
			pos := m.mesh.vertices[i]
			texture_coords: la.Vector2f32
			if len(m.mesh.texture_coords) > 0 {
				texture_coords = m.mesh.texture_coords[i]
			}
			normals: la.Vector3f32
			if len(m.mesh.normals) > 0 {
				normals = m.mesh.normals[i]
			}
			append(&vertices, ModelVertex{pos, texture_coords, normals})
		}

		vertex_buffer := wgpu.device_create_buffer_with_data(
			device,
			{contents = wgpu.to_bytes(vertices[:]), usage = {.Vertex}},
		) or_return

		index_buffer := wgpu.device_create_buffer_with_data(
			device,
			{contents = wgpu.to_bytes(m.mesh.indices), usage = {.Index}},
		) or_return

		mesh := Mesh {
			allocator     = allocator,
			name          = strings.clone(m.name, allocator),
			vertex_buffer = vertex_buffer,
			index_buffer  = index_buffer,
			num_elements  = u32(len(m.mesh.indices)),
			material_id   = m.mesh.material_id,
		}

		append(&meshes, mesh)
	}

	model = new_clone(Model{allocator = allocator, meshes = meshes[:], materials = materials[:]})
	assert(model != nil, "Failed to create model!")

	return model, true
}

destroy_mesh :: proc(mesh: Mesh) {
	context.allocator = mesh.allocator
	delete(mesh.name)
	wgpu.release(mesh.vertex_buffer)
	wgpu.release(mesh.index_buffer)
}

destroy_meshes :: proc(mesh: []Mesh) {
	if mesh == nil || len(mesh) == 0 {
		return
	}
	context.allocator = mesh[0].allocator
	for &m in mesh {
		destroy_mesh(m)
	}
	delete(mesh)
}

destroy_material :: proc(material: Material) {
	context.allocator = material.allocator
	delete(material.name)
	app.release(material.diffuse_texture)
	wgpu.release(material.bind_group)
}

destroy_materials :: proc(materials: []Material) {
	if materials == nil || len(materials) == 0 {
		return
	}
	context.allocator = materials[0].allocator
	for &m in materials {
		destroy_material(m)
	}
	delete(materials)
}

destroy_model :: proc(model: ^Model) {
	context.allocator = model.allocator
	destroy_materials(model.materials)
	destroy_meshes(model.meshes)
	free(model)
}
