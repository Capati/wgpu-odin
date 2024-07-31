package examples_common

// Core
import la "core:math/linalg"

// Note: Models centered on (0, 0, 0) will be halfway inside the clipping area. This is
// for when you aren't using a camera matrix.
// odinfmt: disable
OPEN_GL_TO_WGPU_MATRIX :: la.Matrix4f32 {
    1.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 0.5, 0.5,
    0.0, 0.0, 0.0, 1.0,
}
// odinfmt: enable
