package tobj

/*
 Tiny but powerful wavefront obj loader.

 Note: Initially created for the examples, need more tests for other cases.

 Refs:
 - https://github.com/Twinklebear/tobj
 - https://github.com/syoyo/tinyobjloader
 - https://github.com/syoyo/tinyobjloader-c
*/

// Packages
import "base:runtime"
import la "core:math/linalg"
import "core:mem"
import "core:mem/virtual"
import "core:os"
import "core:path/filepath"
import "core:strconv"
import "core:strings"

MISSING_INDEX :: max(int)

Material :: struct {
	allocator:          runtime.Allocator,
	name:               string,
	ambient:            la.Vector3f32,
	diffuse:            la.Vector3f32,
	specular:           la.Vector3f32,
	shininess:          f32,
	dissolve:           f32,
	optical_density:    f32,
	ambient_texture:    string,
	diffuse_texture:    string,
	specular_texture:   string,
	normal_texture:     string,
	shininess_texture:  string,
	dissolve_texture:   string,
	illumination_model: u8,
	unknown_param:      map[string]string,
}

Material_Map :: map[string]Material

Mesh :: struct {
	allocator:         runtime.Allocator,
	vertices:          [dynamic]la.Vector3f32,
	vertex_colors:     [dynamic]la.Vector3f32,
	normals:           [dynamic]la.Vector3f32,
	texture_coords:    [dynamic]la.Vector2f32,
	indices:           [dynamic]u32,
	vertices_per_face: [dynamic]u32,
	// vertex_color_indices:  [dynamic]u32,
	// texture_coord_indices: [dynamic]u32,
	// normal_indices:        [dynamic]u32,
	material_id:       uint,
}

Model :: struct {
	allocator: runtime.Allocator,
	mesh:      Mesh,
	name:      string,
}

Vertex_Indices :: struct {
	v, vt, vn: int,
}

Point :: struct {
	a: Vertex_Indices,
}

Line :: struct {
	a: Vertex_Indices,
	b: Vertex_Indices,
}

Triangle :: struct {
	a: Vertex_Indices,
	b: Vertex_Indices,
	c: Vertex_Indices,
}

Quad :: struct {
	a: Vertex_Indices,
	b: Vertex_Indices,
	c: Vertex_Indices,
	d: Vertex_Indices,
}

Polygon :: [dynamic]Vertex_Indices

Face :: union {
	Point,
	Line,
	Triangle,
	Quad,
	Polygon,
}

Load_Settings :: struct {
	triangulate:   bool,
	ignore_points: bool,
	ignore_lines:  bool,
}

DEFAULT_LOAD_SETTINGS :: Load_Settings {
	triangulate   = true,
	ignore_points = true,
	ignore_lines  = true,
}

/* Maps unique vertex combinations to mesh indices */
Index_Map :: map[Vertex_Indices]u32

Temp_Data :: struct {
	line_allocator: mem.Allocator,
	marker:         Marker,
	settings:       Load_Settings,
	index_map:      Index_Map,
	vertices:       [dynamic]f32,
	colors:         [dynamic]f32,
	texture_coords: [dynamic]f32,
	normals:        [dynamic]f32,
	faces:          [dynamic]Face,
}

@(require_results)
load_obj_bytes :: proc(
	content: []byte,
	dir: string,
	settings := DEFAULT_LOAD_SETTINGS,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	models: []Model,
	materials: []Material,
	err: Maybe(Error),
) {
	arena: virtual.Arena
	if arena_err := virtual.arena_init_growing(&arena); arena_err != nil {
		panic("Failed to allocate data", loc)
	}
	defer virtual.arena_destroy(&arena)

	out_models := make([dynamic]Model, allocator)
	defer if err != nil {
		destroy(out_models[:])
	}
	out_materials := make([dynamic]Material, allocator)
	defer if err != nil {
		destroy(out_materials[:])
	}

	ally := virtual.arena_allocator(&arena)

	line_block := make([]byte, 1 * mem.Megabyte)
	assert(line_block != nil)
	defer delete(line_block)
	line_block_arena: mem.Arena
	mem.arena_init(&line_block_arena, line_block[:])
	line_allocator := mem.arena_allocator(&line_block_arena)

	data: Temp_Data
	data.line_allocator = line_allocator
	data.settings = settings
	data.index_map.allocator = ally
	data.vertices.allocator = ally
	data.colors.allocator = ally
	data.texture_coords.allocator = ally
	data.normals.allocator = ally
	data.faces.allocator = ally
	current_material: uint
	data.marker = {
		line   = 0, // Start at line 0 since we increment before processing
		column = 1,
	}

	name: string
	defer if err != nil && len(name) > 0 {
		delete(name)
	}

	lines_iter := string(content)
	for line in strings.split_lines_iterator(&lines_iter) {
		if len(line) == 0 {
			continue
		}

		defer free_all(line_allocator)

		update_marker_for_line(&data.marker, line)

		tokens := strings.fields(line, line_allocator)

		if len(tokens) == 0 {
			err = make_error(&data.marker, "Invalid obj tokens")
			return
		}

		switch tokens[0] {
		// Vertices
		case "v":
			if !parse_f32_n(tokens[1:], &data.vertices, 3) {
				err = make_error(&data.marker, "Invalid vertex")
				return
			}

			// Add vertex colors if present
			if len(tokens) > 4 {
				if !parse_f32_n(tokens[4:], &data.colors, 3) {
					err = make_error(&data.marker, "Invalid vertex color")
					return
				}
			}

		// Texture coordinates
		case "vt":
			if !parse_f32_n(tokens[1:], &data.texture_coords, 2) {
				err = make_error(&data.marker, "Invalid texture coordinate")
				return
			}

		// Normals
		case "vn":
			if !parse_f32_n(tokens[1:], &data.normals, 3) {
				err = make_error(&data.marker, "Invalid vertex normal")
				return
			}

		// Faces
		case "f", "l":
			parse_face(tokens[1:], &data) or_return

		// Objects and groups
		case "o", "g":
			// If we were already parsing an object then a new object name
			// signals the end of the current one, so push it onto our list of objects
			if len(data.faces) > 0 {
				add_mesh(&out_models, &data, current_material, name) or_return
				clear(&data.faces)
			}
			name_view := tokens[1]
			if len(name_view) > 0 {
				name = strings.clone(name_view, allocator)
			}

		// Load a material
		case "mtllib":
			mtllib := tokens[1]
			if len(mtllib) == 0 {
				err = make_error(&data.marker, "Missing mtllib name")
				return
			}
			load_mtl(mtllib, dir, &out_materials, allocator) or_return

		// Uze a material
		case "usemtl":
			usemtl := tokens[1]
			if len(usemtl) == 0 {
				err = make_error(&data.marker, "Missing usemtl name")
				return
			}
			found: bool
			mat_search: for m, i in out_materials[:] {
				if usemtl == m.name {
					current_material = uint(i)
					found = true
					break mat_search
				}
			}
			if !found {
				err = make_error(&data.marker, "Unable to find the material: %s", usemtl)
				return
			}

		// Ignore empty/comment line
		case "#", "":
			continue

		// Unknown
		case:
		}
	}

	// For the last object in the file we won't encounter another object name to
	// tell us when it's done, so if we're parsing an object push the last one
	// on the list as well
	add_mesh(&out_models, &data, current_material, name) or_return

	return out_models[:], out_materials[:], nil
}

@(require_results)
load_obj_filename :: proc(
	filename: string,
	settings := DEFAULT_LOAD_SETTINGS,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	models: []Model,
	materials: []Material,
	err: Maybe(Error),
) {
	ta := context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == ta)
	content, content_ok := os.read_entire_file_from_filename(filename, ta)
	assert(content_ok, "[load_obj]: Failed to read file", loc)
	dir := filepath.dir(filename, ta)
	return load_obj_bytes(content, dir, settings, allocator, loc)
}

load_obj :: proc {
	load_obj_bytes,
	load_obj_filename,
}

@(require_results)
load_mtl_bytes :: proc(
	content: []byte,
	materials: ^[dynamic]Material,
	allocator := context.allocator,
) -> (
	err: Maybe(Error),
) {
	curr_mat: Material
	curr_mat.allocator = allocator

	marker := Marker {
		line   = 0,
		column = 1,
	}

	line_block := make([]byte, 1 * mem.Megabyte)
	assert(line_block != nil)
	defer delete(line_block)
	line_block_arena: mem.Arena
	mem.arena_init(&line_block_arena, line_block[:])
	line_allocator := mem.arena_allocator(&line_block_arena)

	lines_iter := string(content)
	for line in strings.split_lines_iterator(&lines_iter) {
		if len(line) == 0 {
			continue
		}

		defer free_all(line_allocator)

		update_marker_for_line(&marker, line)

		tokens := strings.fields(line, line_allocator)

		if len(tokens) == 0 {
			err = make_error(&marker, "Invalid mtl tokens")
			return
		}

		ok: bool
		switch tokens[0] {
		// New material
		case "newmtl":
			if len(curr_mat.name) > 0 {
				append(materials, curr_mat)
			}
			curr_mat = {
				allocator = allocator,
			}
			name_view := tokens[1]
			if len(name_view) == 0 {
				err = make_error(&marker, "Invalid material name")
				return
			}
			curr_mat.name = strings.clone(name_view, allocator)

		// Ambient
		case "Ka":
			if curr_mat.ambient, ok = parse_vector3f32(tokens[1:]); !ok {
				err = make_error(&marker, "Invalid Ka (ambient)")
				return
			}

		// Diffuse
		case "Kd":
			if curr_mat.diffuse, ok = parse_vector3f32(tokens[1:]); !ok {
				err = make_error(&marker, "Invalid Kd (diffuse)")
				return
			}

		// Specular
		case "Ks":
			if curr_mat.specular, ok = parse_vector3f32(tokens[1:]); !ok {
				err = make_error(&marker, "Invalid Ks (specular)")
				return
			}

		// Shininess
		case "Ns":
			if curr_mat.shininess, ok = parse_f32(tokens[1]); !ok {
				err = make_error(&marker, "Invalid Ns (shininess)")
				return
			}

		// Optical density
		case "Ni":
			if curr_mat.optical_density, ok = parse_f32(tokens[1]); !ok {
				err = make_error(&marker, "Invalid Ni (optical density)")
				return
			}

		// Dissolve
		case "d":
			if curr_mat.dissolve, ok = parse_f32(tokens[1]); !ok {
				err = make_error(&marker, "Invalid d (dissolve)")
				return
			}

		// Ambient texture
		case "map_Ka":
			map_ka := strings.trim(tokens[1], " ")
			if len(map_ka) == 0 {
				err = make_error(&marker, "Invalid map_Ka name")
				return
			}
			curr_mat.ambient_texture = strings.clone(map_ka, allocator)

		// Diffuse texture
		case "map_Kd":
			map_ka := strings.trim(tokens[1], " ")
			if len(map_ka) == 0 {
				err = make_error(&marker, "Invalid map_Kd name")
				return
			}
			curr_mat.diffuse_texture = strings.clone(map_ka, allocator)

		// Specular texture
		case "map_Ks":
			map_ka := strings.trim(tokens[1], " ")
			if len(map_ka) == 0 {
				err = make_error(&marker, "Invalid map_Ks name")
				return
			}
			curr_mat.specular_texture = strings.clone(map_ka, allocator)

		// Normal texture
		case "map_Bump":
			map_ka := strings.trim(tokens[1], " ")
			if len(map_ka) == 0 {
				err = make_error(&marker, "Invalid map_Bump name")
				return
			}
			curr_mat.normal_texture = strings.clone(map_ka, allocator)

		// Shininess texture
		case "map_Ns":
			map_ka := strings.trim(tokens[1], " ")
			if len(map_ka) == 0 {
				err = make_error(&marker, "Invalid map_Ns name")
				return
			}
			curr_mat.shininess_texture = strings.clone(map_ka, allocator)

		// Normal texture
		case "bump":
			map_ka := strings.trim(tokens[1], " ")
			if len(map_ka) == 0 {
				err = make_error(&marker, "Invalid bump name")
				return
			}
			curr_mat.normal_texture = strings.clone(map_ka, allocator)

		// Dissolve texture
		case "map_d":
			map_ka := strings.trim(tokens[1], " ")
			if len(map_ka) == 0 {
				err = make_error(&marker, "Invalid map_d name")
				return
			}
			curr_mat.dissolve_texture = strings.clone(map_ka, allocator)

		// Illumination model
		case "illum":
			illum := tokens[1]
			if len(illum) == 0 {
				err = make_error(&marker, "Missing illum value")
				return
			}
			if illumination_model, illum_ok := strconv.parse_int(tokens[1]); illum_ok {
				curr_mat.illumination_model = u8(illumination_model)
			} else {
				err = make_error(&marker, "Invalid illum value")
				return
			}

		// Ignore empty/comment line
		case "#", "":
			continue

		case:
		}
	}

	// Finalize the last material we were parsing
	if len(curr_mat.name) > 0 {
		append(materials, curr_mat)
	}

	return
}

@(require_results)
load_mtl_filename :: proc(
	filename: string,
	dir: string,
	materials: ^[dynamic]Material,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	err: Maybe(Error),
) {
	ta := context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == ta)
	mtl_filename := filepath.join({dir, filename}, ta)
	content, content_ok := os.read_entire_file_from_filename(mtl_filename, ta)
	assert(content_ok, "[load_mtl_filename]: Failed to read file", loc)
	return load_mtl_bytes(content, materials, allocator)
}

load_mtl :: proc {
	load_mtl_bytes,
	load_mtl_filename,
}

add_mesh :: proc(
	models: ^[dynamic]Model,
	data: ^Temp_Data,
	material_id: uint,
	name: string,
) -> (
	err: Maybe(Error),
) {
	assert(models.allocator.data != nil, "Invalid models allocator")
	allocator := models.allocator
	mesh := export_faces(data, allocator) or_return
	mesh.material_id = material_id
	name := name
	if len(name) == 0 {
		name = strings.clone("unnamed_object", allocator)
	}
	model := Model {
		allocator = allocator,
		mesh      = mesh,
		name      = name,
	}
	append(models, model)
	return
}

parse_f32_n :: proc(tokens: []string, vals: ^[dynamic]f32, n: $N) -> (ok: bool) {
	assert(n > 0, "Invalid number of values")

	initial_len := len(vals)
	values_needed := n

	for token in tokens {
		value, v_ok := strconv.parse_f32(token)
		if !v_ok {
			return
		}

		append(vals, value)
		values_needed -= 1

		if values_needed == 0 {
			return true
		}
	}

	// Check if we got exactly the number of values we needed
	values_parsed := len(vals) - initial_len
	if values_parsed < n {
		return
	}

	return true
}

parse_vector3f32 :: proc(tokens: []string) -> (arr: la.Vector3f32, ok: bool) {
	if len(tokens) < 3 {
		return
	}

	for i := 0; i < 3; i += 1 {
		val, val_ok := strconv.parse_f32(tokens[i])
		if !val_ok {
			return
		}
		arr[i] = val
	}

	return arr, true
}

parse_f32 :: proc(value_str: string) -> (val: f32, ok: bool) {
	return strconv.parse_f32(value_str)
}

/*
Parse the vertex indices from the face string.
*/
@(require_results)
parse_face_indices :: proc(
	face_str: string,
	data: ^Temp_Data,
) -> (
	indices: Vertex_Indices,
	err: Maybe(Error),
) {
	indices = Vertex_Indices {
		v  = MISSING_INDEX,
		vt = MISSING_INDEX,
		vn = MISSING_INDEX,
	}

	// Parsing data is flat, so dividing we get the actual number of v/vt/vn
	vert_len := len(data.vertices) / 3
	tex_len := len(data.texture_coords) / 2
	norm_len := len(data.normals) / 3

	parts := strings.split(face_str, "/", data.line_allocator)

	if len(parts) == 0 {
		err = make_error(&data.marker, "Empty face string")
		return
	}

	// Parse vertex index (always required)
	if v, v_ok := strconv.parse_int(parts[0]); v_ok {
		// Handle relative indices (negative values)
		indices.v = v < 0 ? vert_len + v - 1 : v - 1
		if indices.v < 0 || indices.v >= vert_len {
			err = make_error(&data.marker, "Face vertex index out of bounds")
			return
		}
	} else {
		err = make_error(&data.marker, "Failed to parse vertex index: {}", parts[0])
		return
	}

	// Parse texture coordinate index (if present)
	if len(parts) > 1 && parts[1] != "" {
		if vt, vt_ok := strconv.parse_int(parts[1]); vt_ok {
			indices.vt = vt < 0 ? tex_len + vt - 1 : vt - 1
			if indices.vt < 0 || indices.vt >= tex_len {
				err = make_error(&data.marker, "Face texture coordinate index out of bounds")
				return
			}
		} else {
			err = make_error(&data.marker, "Texture coordinate parse error: {}", parts[1])
			return
		}
	}

	// Parse normal index (if present)
	if len(parts) > 2 && parts[2] != "" {
		if vn, vn_ok := strconv.parse_int(parts[2]); vn_ok {
			indices.vn = vn < 0 ? norm_len + vn - 1 : vn - 1
			if indices.vn < 0 || indices.vn >= norm_len {
				err = make_error(&data.marker, "Face normal index out of bounds")
				return
			}
		} else {
			err = make_error(&data.marker, "Failed to parse normal index: {}", parts[2])
			return
		}
	}

	return
}

/*
Parse vertex indices for a face and append it to the list of faces passed.

Returns `Error` if an error occurred parsing the face.
*/
parse_face :: proc(tokens: []string, data: ^Temp_Data) -> (err: Maybe(Error)) {
	indices := make([dynamic]Vertex_Indices, data.line_allocator)

	for token in tokens {
		res := parse_face_indices(token, data) or_return
		append(&indices, res)
	}

	switch len(indices) {
	case 1:
		append(&data.faces, Point{indices[0]})
	case 2:
		append(&data.faces, Line{indices[0], indices[1]})
	case 3:
		append(&data.faces, Triangle{indices[0], indices[1], indices[2]})
	case 4:
		append(&data.faces, Quad{indices[0], indices[1], indices[2], indices[3]})
	case:
		append(&data.faces, indices)
	}

	return
}

/*
Add a vertex to a mesh by either re-using an existing index (e.g. it's in
the `index_map`) or appending the position, texcoord and normal as
appropriate and creating a new vertex.
*/
add_vertex :: proc(mesh: ^Mesh, vert: Vertex_Indices, data: ^Temp_Data) -> (err: Maybe(Error)) {
	// Check if this exact combination of vertex attributes already exists
	if index, exists := data.index_map[vert]; exists {
		append(&mesh.indices, index) // Reuse existing vertex
		return
	}

	// Validate vertex position index
	v := vert.v
	if v < 0 || v >= len(data.vertices) / 3 {
		err = make_error(
			&data.marker,
			"Face vertex index out of bounds (index: {}, max: {})",
			v,
			len(data.vertices) / 3 - 1,
		)
		return
	}

	// Add vertex positions
	append(
		&mesh.vertices,
		la.Vector3f32 {
			data.vertices[v * 3 + 0],
			data.vertices[v * 3 + 1],
			data.vertices[v * 3 + 2],
		},
	)

	// Handle vertex colors if present
	if v < len(data.colors) / 3 {
		append(
			&mesh.vertex_colors,
			la.Vector3f32{data.colors[v * 3 + 0], data.colors[v * 3 + 1], data.colors[v * 3 + 2]},
		)
	}

	// Handle normals if present
	if vn := vert.vn; vn != MISSING_INDEX {
		if vn >= len(data.normals) / 3 {
			err = make_error(
				&data.marker,
				"Normal index out of bounds (index: {}, max: {})",
				vn,
				len(data.normals) / 3 - 1,
			)
			return
		}
		append(
			&mesh.normals,
			la.Vector3f32 {
				data.normals[vn * 3 + 0],
				data.normals[vn * 3 + 1],
				data.normals[vn * 3 + 2],
			},
		)
	}

	// Handle texture coordinates if present
	if vt := vert.vt; vt != MISSING_INDEX {
		if vt >= len(data.texture_coords) / 2 {
			err = make_error(
				&data.marker,
				"Texture coordinate index out of bounds (index: {}, max: {})",
				vt,
				len(data.texture_coords) / 2 - 1,
			)
			return
		}
		append(
			&mesh.texture_coords,
			la.Vector2f32{data.texture_coords[vt * 2 + 0], data.texture_coords[vt * 2 + 1]},
		)
	}

	// Add new vertex to index map and indices
	next := u32(len(data.index_map)) // New index will be the current length
	data.index_map[vert] = next
	append(&mesh.indices, next)

	return
}

export_faces :: proc(
	data: ^Temp_Data,
	allocator := context.allocator,
) -> (
	mesh: Mesh,
	err: Maybe(Error),
) {
	clear(&data.index_map)

	mesh.allocator = allocator
	mesh.vertices.allocator = allocator
	mesh.vertex_colors.allocator = allocator
	mesh.normals.allocator = allocator
	mesh.texture_coords.allocator = allocator
	mesh.indices.allocator = allocator
	mesh.vertices_per_face.allocator = allocator
	// mesh.vertex_color_indices.allocator = allocator
	// mesh.texture_coord_indices.allocator = allocator
	// mesh.normal_indices.allocator = allocator

	is_all_triangles := true
	for &f in data.faces {
		switch &v in f {
		case Point:
			if !data.settings.ignore_points {
				add_vertex(&mesh, v.a, data) or_return
				if data.settings.triangulate {
					add_vertex(&mesh, v.a, data) or_return
					add_vertex(&mesh, v.a, data) or_return
				} else {
					is_all_triangles = false
					append(&mesh.vertices_per_face, 1)
				}
			}
		case Line:
			if !data.settings.ignore_lines {
				add_vertex(&mesh, v.a, data) or_return
				add_vertex(&mesh, v.b, data) or_return
				if data.settings.triangulate {
					add_vertex(&mesh, v.b, data) or_return
				} else {
					is_all_triangles = false
					append(&mesh.vertices_per_face, 2)
				}
			}
		case Triangle:
			add_vertex(&mesh, v.a, data) or_return
			add_vertex(&mesh, v.b, data) or_return
			add_vertex(&mesh, v.c, data) or_return
			if !data.settings.triangulate {
				append(&mesh.vertices_per_face, 3)
			}
		case Quad:
			/*
				A ●─────────● B   Split into two triangles:
				  │ .       │
				  │   .     │     Triangle 1: A-B-C
				  │     .   │     Triangle 2: A-C-D
				  │       . │
				D ●─────────● C   Order: (A,B,C) + (A,C,D)
			*/
			add_vertex(&mesh, v.a, data) or_return
			add_vertex(&mesh, v.b, data) or_return
			add_vertex(&mesh, v.c, data) or_return
			if data.settings.triangulate {
				add_vertex(&mesh, v.a, data) or_return
				add_vertex(&mesh, v.c, data) or_return
				add_vertex(&mesh, v.d, data) or_return
			} else {
				add_vertex(&mesh, v.d, data) or_return
				is_all_triangles = false
				append(&mesh.vertices_per_face, 4)
			}
		case Polygon:
			if data.settings.triangulate {
				// Triangulate polygon using fan triangulation
				for i := 1; i < len(v) - 1; i += 1 {
					// Create triangle: first vertex, current vertex, next vertex
					add_vertex(&mesh, v[0], data) or_return
					add_vertex(&mesh, v[i], data) or_return
					add_vertex(&mesh, v[i + 1], data) or_return
					append(&mesh.vertices_per_face, 3)
				}
			} else {
				for vertex in v {
					add_vertex(&mesh, vertex, data) or_return
				}
				append(&mesh.vertices_per_face, u32(len(v)))
			}
		}
	}

	if is_all_triangles {
		clear(&mesh.vertices_per_face)
	}

	return
}

destroy_model :: proc(model: Model) {
	context.allocator = model.allocator
	delete(model.mesh.vertices)
	delete(model.mesh.vertex_colors)
	delete(model.mesh.normals)
	delete(model.mesh.texture_coords)
	delete(model.mesh.indices)
	delete(model.mesh.vertices_per_face)
	// delete(model.mesh.vertex_color_indices)
	// delete(model.mesh.texture_coord_indices)
	// delete(model.mesh.normal_indices)
	delete(model.name)
}

destroy_models :: proc(models: []Model) {
	if models == nil || len(models) == 0 {
		return
	}
	context.allocator = models[0].allocator
	for &s in models {
		destroy_model(s)
	}
	delete(models)
}

destroy_material :: proc(material: Material) {
	context.allocator = material.allocator
	delete(material.name)
	delete(material.ambient_texture)
	delete(material.diffuse_texture)
	delete(material.specular_texture)
	delete(material.normal_texture)
	delete(material.shininess_texture)
	delete(material.dissolve_texture)
	for _, &v in material.unknown_param {
		delete(v)
	}
	delete(material.unknown_param)
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

destroy_all :: proc(models: []Model, materials: []Material) {
	destroy_models(models)
	destroy_materials(materials)
}

destroy :: proc {
	destroy_model,
	destroy_models,
	destroy_material,
	destroy_materials,
	destroy_all,
}
