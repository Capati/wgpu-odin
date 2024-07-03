package cube_example

Vertex :: struct {
	position: [3]f32,
	color:    [3]f32,
}

vertex_data := []Vertex {
	// +X Face - red
	vertex(0.5, -0.5, 0.5, 1, 0, 0),
	vertex(0.5, -0.5, -0.5, 1, 0, 0),
	vertex(0.5, 0.5, -0.5, 1, 0, 0),
	vertex(0.5, -0.5, 0.5, 1, 0, 0),
	vertex(0.5, 0.5, -0.5, 1, 0, 0),
	vertex(0.5, 0.5, 0.5, 1, 0, 0),
	// -X Face - cyan
	vertex(-0.5, 0.5, 0.5, 0, 1, 1),
	vertex(-0.5, 0.5, -0.5, 0, 1, 1),
	vertex(-0.5, -0.5, -0.5, 0, 1, 1),
	vertex(-0.5, 0.5, 0.5, 0, 1, 1),
	vertex(-0.5, -0.5, -0.5, 0, 1, 1),
	vertex(-0.5, -0.5, 0.5, 0, 1, 1),
	// + Y Face - green
	vertex(0.5, 0.5, -0.5, 0, 1, 0),
	vertex(-0.5, 0.5, -0.5, 0, 1, 0),
	vertex(-0.5, 0.5, 0.5, 0, 1, 0),
	vertex(0.5, 0.5, -0.5, 0, 1, 0),
	vertex(-0.5, 0.5, 0.5, 0, 1, 0),
	vertex(0.5, 0.5, 0.5, 0, 1, 0),
	// -Y Face - magenta
	vertex(-0.5, -0.5, -0.5, 1, 0, 1),
	vertex(0.5, -0.5, -0.5, 1, 0, 1),
	vertex(0.5, -0.5, 0.5, 1, 0, 1),
	vertex(-0.5, -0.5, -0.5, 1, 0, 1),
	vertex(0.5, -0.5, 0.5, 1, 0, 1),
	vertex(-0.5, -0.5, 0.5, 1, 0, 1),
	// +Z Face - blue
	vertex(0.5, 0.5, 0.5, 0, 0, 1),
	vertex(-0.5, 0.5, 0.5, 0, 0, 1),
	vertex(-0.5, -0.5, 0.5, 0, 0, 1),
	vertex(0.5, 0.5, 0.5, 0, 0, 1),
	vertex(-0.5, -0.5, 0.5, 0, 0, 1),
	vertex(0.5, -0.5, 0.5, 0, 0, 1),
	// -Z Face - yellow
	vertex(0.5, -0.5, -0.5, 1, 1, 0),
	vertex(-0.5, -0.5, -0.5, 1, 1, 0),
	vertex(-0.5, 0.5, -0.5, 1, 1, 0),
	vertex(0.5, -0.5, -0.5, 1, 1, 0),
	vertex(-0.5, 0.5, -0.5, 1, 1, 0),
	vertex(0.5, 0.5, -0.5, 1, 1, 0),
}

vertex :: proc(pos1, pos2, pos3, r, g, b: f32) -> Vertex {
	return Vertex{position = {pos1, pos2, pos3}, color = {r, g, b}}
}
