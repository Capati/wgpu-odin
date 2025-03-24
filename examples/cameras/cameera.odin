package cameras_example

// Packages
import la "core:math/linalg"

// User input state.
Input :: struct {
	analog:  Analog_Input, // Analog input (e.g mouse, touchscreen)
	digital: Digital_Input, // Digital input (e.g keyboard state)
}

// Represents continuous input values like mouse movement
Analog_Input :: struct {
	x:        f32, // Horizontal analog input
	y:        f32, // Vertical analog input
	zoom:     f32, // Zoom input value
	touching: bool, // Whether touch/click is active
}

// Represents discrete on/off input states like keyboard keys
Digital_Input :: struct {
	forward:  bool, // Forward movement
	backward: bool, // Backward movement
	left:     bool, // Left movement
	right:    bool, // Right movement
	up:       bool, // Upward movement
	down:     bool, // Downward movement
}

// Camera interface common properties
Camera :: struct {
	mat:      la.Matrix4f32, // Camera matrix (inverse of view matrix)
	view:     la.Matrix4f32, // View matrix
	right:    la.Vector3f32, // Right vector (first column)
	up:       la.Vector3f32, // Up vector (second column)
	back:     la.Vector3f32, // Back vector (third column)
	position: la.Vector3f32, // Position vector (fourth column)
}

// Helper procedures to update the matrix when vectors change
update_matrix_from_vectors :: proc "contextless" (camera: ^Camera) {
	// First column (right vector)
	camera.mat[0, 0] = camera.right.x
	camera.mat[1, 0] = camera.right.y
	camera.mat[2, 0] = camera.right.z
	camera.mat[3, 0] = 0

	// Second column (up vector)
	camera.mat[0, 1] = camera.up.x
	camera.mat[1, 1] = camera.up.y
	camera.mat[2, 1] = camera.up.z
	camera.mat[3, 1] = 0

	// Third column (back vector)
	camera.mat[0, 2] = camera.back.x
	camera.mat[1, 2] = camera.back.y
	camera.mat[2, 2] = camera.back.z
	camera.mat[3, 2] = 0

	// Fourth column (position vector)
	camera.mat[0, 3] = camera.position.x
	camera.mat[1, 3] = camera.position.y
	camera.mat[2, 3] = camera.position.z
	camera.mat[3, 3] = 1

	camera.view = la.matrix4_inverse_f32(camera.mat)
}

scale :: #force_inline proc "contextless" (v: la.Vector3f32, scale: f32) -> la.Vector3f32 {
	return v * scale
}

// Returns `Vector3f32` rotated `angle` radians around `axis`.
rotate :: proc "contextless" (v: la.Vector3f32, axis: la.Vector3f32, angle: f32) -> la.Vector3f32 {
	rotation := la.matrix4_rotate(angle, axis)
	return (rotation * la.Vector4f32{v.x, v.y, v.z, 0}).xyz
}

// Boolean to f32 helper.
b2f :: #force_inline proc "contextless" (b: bool) -> f32 {
	return b ? 1.0 : 0.0
}

camera_update :: proc {
	arcball_camera_update,
	wasd_camera_update,
}
