package cube_map_example

Vertex :: struct {
	position:   [4]f32,
	tex_coords: [2]f32,
}

// odinfmt: disable
CUBE_VERTEX_DATA := []Vertex {
    // Front face
    vertex(-1, -1,  1,  0, 0),  // 0
    vertex( 1, -1,  1,  1, 0),  // 1
    vertex( 1,  1,  1,  1, 1),  // 2
    vertex(-1,  1,  1,  0, 1),  // 3
    // Back face
    vertex(-1, -1, -1,  1, 0),  // 4
    vertex( 1, -1, -1,  0, 0),  // 5
    vertex( 1,  1, -1,  0, 1),  // 6
    vertex(-1,  1, -1,  1, 1),  // 7
}

vertex :: proc(pos1, pos2, pos3, tc1, tc2: f32) -> Vertex {
    return Vertex {
        position = {pos1, pos2, pos3, 1},
        tex_coords = {tc1, tc2},
    }
}

CUBE_INDICES_DATA :: []u16 {
    0, 1, 2, 2, 3, 0,  // front
    5, 4, 7, 7, 6, 5,  // back
    1, 5, 6, 6, 2, 1,  // right
    4, 0, 3, 3, 7, 4,  // left
    3, 2, 6, 6, 7, 3,  // top
    4, 5, 1, 1, 0, 4,  // bottom
}
// odinfmt: enable
