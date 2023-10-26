package examples_common

// Core
import "core:math"
import la "core:math/linalg"

generate_matrix :: proc(aspect: f32) -> la.Matrix4f32 {
    projection := la.matrix4_perspective_f32(math.PI / 4, aspect, 1.0, 10.0)
    view := la.matrix4_look_at_f32(
        eye = {1.5, -5.0, 3.0},
        centre = {0.0, 0.0, 0.0},
        up = {0.0, 0.0, 1.0},
    )
    return la.mul(projection, view)
}
