package application

// STD Library
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

nul_search_bytes :: proc "contextless" (buffer: []byte) -> (nul: int) {
	nul = -1
	nul_search: for i in 0 ..< len(buffer) {
		if buffer[i] == 0 {
			nul = i
			break nul_search
		}
	}

	if nul == -1 {
		nul = len(buffer) - 1 // Ensure space for null terminator
	}

	return
}

nul_search :: proc {
	nul_search_bytes,
}
