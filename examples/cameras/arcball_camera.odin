package cameras_example

// Packages
import "core:math"
import la "core:math/linalg"

/* Implements an orbiting camera. */
Arcball_Camera :: struct {
	using camera:         Camera,
	distance:             f32,
	angular_velocity:     f32,
	axis:                 la.Vector3f32,
	rotation_speed:       f32,
	zoom_speed:           f32,
	friction_coefficient: f32,
}

arcball_camera_create :: proc "contextless" (position: la.Vector3f32) -> (camera: Arcball_Camera) {
	// Initialize matrices
	camera.mat = la.MATRIX4F32_IDENTITY
	camera.view = la.MATRIX4F32_IDENTITY
	camera.rotation_speed = 1
	camera.zoom_speed = 0.1
	camera.friction_coefficient = 0.999

	// odinfmt: disable
	// Initialize basis vectors from identity matrix
	camera.right    = {1, 0, 0}  // First column of identity
	camera.up       = {0, 1, 0}  // Second column of identity
	camera.back     = {0, 0, 1}  // Third column of identity
	camera.position = {0, 0, 0}  // Fourth column of identity
	// odinfmt: enable

	if position != {} {
		camera.position = position
		camera.distance = la.length(position)
		camera.back = la.normalize(position)
		arcball_camera_recalculate_basis(&camera)
	}

	return camera
}

/* Updates the camera based on user input and time delta. */
arcball_camera_update :: proc "contextless" (
	self: ^Arcball_Camera,
	delta_time: f32,
	input: Input,
) -> la.Matrix4f32 {
	// Process rotation changes from user input and apply inertia
	if input.analog.touching {
		// Reset any existing angular velocity when user starts interacting
		self.angular_velocity = 0

		// Calculate rotation axis by combining horizontal (right) and vertical (up) movement
		// Negative Y movement creates more intuitive controls (moving up rotates down)
		movement := scale(self.right, input.analog.x) + scale(self.up, -input.analog.y)

		// Determine rotation axis through cross product with view direction (back)
		// This creates rotation perpendicular to both movement and view direction
		cross_product := la.vector_cross3(movement, self.back)
		magnitude := la.vector_length(cross_product)

		if magnitude > math.F32_EPSILON {
			// Normalize rotation axis and set angular velocity proportional to movement
			self.axis = la.vector_normalize(cross_product)
			self.angular_velocity = magnitude * self.rotation_speed
		}
	} else {
		// Apply friction when not touching to smoothly decelerate rotation
		// Uses exponential decay for natural-feeling slowdown
		self.angular_velocity *= la.pow(1 - self.friction_coefficient, delta_time)
	}

	// Apply rotation if angular velocity is significant
	rotation_angle := self.angular_velocity * delta_time
	if rotation_angle > math.F32_EPSILON {
		// Create rotation quaternion for smooth interpolation
		rotation := la.quaternion_angle_axis_f32(rotation_angle, self.axis)
		// Rotate view direction using quaternion to minimize error accumulation
		self.back = la.vector_normalize(la.quaternion128_mul_vector3(rotation, self.back))
		// Ensure camera basis vectors remain orthonormal
		arcball_camera_recalculate_basis(self)
	}

	// Handle camera zoom based on input (typically mouse wheel)
	if input.analog.zoom != 0 {
		// Calculate zoom factor - positive zoom moves closer, negative moves away
		zoom_factor := 1 - input.analog.zoom * self.zoom_speed
		// Update and clamp distance to prevent getting too close or too far
		self.distance = math.clamp(
			self.distance * zoom_factor,
			0.1, // min distance
			100.0, // max distance
		)
	}

	// Position camera along view direction at current distance
	self.position = scale(self.back, self.distance)
	// Update matrices used for rendering
	update_matrix_from_vectors(self)

	return self.view
}

/* Recalculates right and up vectors to maintain orthonormal basis. */
arcball_camera_recalculate_basis :: proc "contextless" (self: ^Arcball_Camera) {
	arcball_camera_recalculate_right(self)
	arcball_camera_recalculate_up(self)
}

/* Calculate right vector from world up and back. */
arcball_camera_recalculate_right :: proc "contextless" (camera: ^Arcball_Camera) {
	camera.right = la.normalize(la.cross(camera.up, camera.back))
}

/* Calculate camera up from back and right. */
arcball_camera_recalculate_up :: proc "contextless" (camera: ^Arcball_Camera) {
	camera.up = la.normalize(la.cross(camera.back, camera.right))
}
