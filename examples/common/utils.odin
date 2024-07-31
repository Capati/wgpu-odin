package examples_common

// Core
import "core:math"
import la "core:math/linalg"

create_view_projection_matrix :: proc(aspect: f32) -> la.Matrix4f32 {
	// 72 deg FOV (2 * PI / 5 radians)
	projection := la.matrix4_perspective_f32(2 * math.PI / 5, aspect, 1.0, 100.0)
	view := la.matrix4_look_at_f32(
		eye = {1.1, 1.1, 1.1},
		centre = {0.0, 0.0, 0.0},
		up = {0.0, 1.0, 0.0},
	)
	return OPEN_GL_TO_WGPU_MATRIX * projection * view
}
