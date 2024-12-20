package rotating_cube

Vertex :: struct {
	position:   [4]f32,
	color:      [4]f32,
	tex_coords: [2]f32,
}

// odinfmt: disable
CUBE_VERTEX_DATA := []Vertex {
    // top (0, 0, 1)
    vertex(-1, -1,  1,  0, 0, 1,  0, 0),
    vertex( 1, -1,  1,  1, 0, 1,  1, 0),
    vertex( 1,  1,  1,  1, 1, 1,  1, 1),
    vertex(-1,  1,  1,  0, 1, 1,  0, 1),
    // bottom (0, 0, -1)
    vertex(-1,  1, -1,  0, 1, 0,  1, 0),
    vertex( 1,  1, -1,  1, 1, 0,  0, 0),
    vertex( 1, -1, -1,  1, 0, 0,  0, 1),
    vertex(-1, -1, -1,  0, 0, 0,  1, 1),
    // right (1, 0, 0)
    vertex( 1, -1, -1,  1, 0, 0,  0, 0),
    vertex( 1,  1, -1,  1, 1, 0,  1, 0),
    vertex( 1,  1,  1,  1, 1, 1,  1, 1),
    vertex( 1, -1,  1,  1, 0, 1,  0, 1),
    // left (-1, 0, 0)
    vertex(-1, -1,  1,  0, 0, 1,  1, 0),
    vertex(-1,  1,  1,  0, 1, 1,  0, 0),
    vertex(-1,  1, -1,  0, 1, 0,  0, 1),
    vertex(-1, -1, -1,  0, 0, 0,  1, 1),
    // front (0, 1, 0)
    vertex( 1,  1, -1,  1, 1, 0,  1, 0),
    vertex(-1,  1, -1,  0, 1, 0,  0, 0),
    vertex(-1,  1,  1,  0, 1, 1,  0, 1),
    vertex( 1,  1,  1,  1, 1, 1,  1, 1),
    // back (0, -1, 0)
    vertex( 1, -1,  1,  1, 0, 1,  0, 0),
    vertex(-1, -1,  1,  0, 0, 1,  1, 0),
    vertex(-1, -1, -1,  0, 0, 0,  1, 1),
    vertex( 1, -1, -1,  1, 0, 0,  0, 1),
}
// odinfmt: enable

vertex :: proc(pos1, pos2, pos3, color1, color2, color3, tc1, tc2: f32) -> Vertex {
	return Vertex {
		position = {pos1, pos2, pos3, 1},
		color = {color1, color2, color3, 1},
		tex_coords = {tc1, tc2},
	}
}

// odinfmt: disable
CUBE_INDICES_DATA :: []u16 {
    0 , 1,  2,  2,  3,  0,  // top
    4 , 5,  6,  6,  7,  4,  // bottom
    8 , 9,  10, 10, 11, 8,  // right
    12, 13, 14, 14, 15, 12, // left
    16, 17, 18, 18, 19, 16, // front
    20, 21, 22, 22, 23, 20, // back
}
// odinfmt: enable
