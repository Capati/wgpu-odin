package cameras_example

// Core
import "core:math"
import la "core:math/linalg"

// WASD_Camera implements an FPS-style camera
WASD_Camera :: struct {
	using camera:         Camera, // Inherited from a base Camera struct
	pitch:                f32, // Camera pitch angle (radians)
	yaw:                  f32, // Camera yaw angle (radians)
	velocity:             la.Vector3f32, // Movement velocity
	movement_speed:       f32, // Speed multiplier for movement
	rotation_speed:       f32, // Speed multiplier for rotation
	friction_coefficient: f32, // Velocity drag coefficient [0..1]
}

// Creates a new WASD camera with optional position and target
wasd_camera_create :: proc "contextless" (
	position: la.Vector3f32,
	target: la.Vector3f32 = {},
) -> (
	camera: WASD_Camera,
) {
	camera.mat = la.MATRIX4F32_IDENTITY
	camera.view = la.MATRIX4F32_IDENTITY
	camera.movement_speed = 10
	camera.rotation_speed = 1
	camera.friction_coefficient = 0.99

	if position != {} || target != {} {
		pos := position == {} ? la.Vector3f32{0, 0, -5} : position
		tgt := target == {} ? la.Vector3f32{0, 0, 0} : target
		back := la.normalize(tgt - position) // Back is direction toward target
		wasd_camera_recalculate_angles(&camera, back)
		camera.position = pos
	}

	return camera
}

wasd_camera_update :: proc "contextless" (
	camera: ^WASD_Camera,
	delta_time: f32,
	input: Input,
) -> la.Matrix4f32 {
	// Update rotation based on analog input
	camera.yaw -= input.analog.x * delta_time * camera.rotation_speed
	camera.pitch -= input.analog.y * delta_time * camera.rotation_speed

	// Wrap yaw and clamp pitch
	camera.yaw = math.mod(camera.yaw, 2 * math.PI)
	camera.pitch = math.clamp(camera.pitch, -math.PI / 2, math.PI / 2)

	// Store current position
	pos := camera.position.xyz

	// Rebuild rotation: forward direction based on yaw and pitch
	forward := la.Vector3f32 {
		math.sin(camera.yaw) * math.cos(camera.pitch),
		math.sin(camera.pitch),
		math.cos(camera.yaw) * math.cos(camera.pitch),
	}
	forward = la.normalize(forward)

	// Basis vectors: back is -forward (direction toward target)
	camera.back = -forward
	camera.right = la.normalize(la.vector_cross3(la.Vector3f32{0, 1, 0}, camera.back))
	camera.up = la.normalize(la.vector_cross3(camera.back, camera.right))

	// Calculate target velocity in world space
	digital := input.digital
	delta_right := b2f(digital.right) - b2f(digital.left)
	delta_up := b2f(digital.up) - b2f(digital.down)
	delta_back := b2f(digital.backward) - b2f(digital.forward)

	target_velocity := la.Vector3f32{0, 0, 0}
	target_velocity += delta_right * camera.right
	target_velocity += delta_up * camera.up
	target_velocity += delta_back * camera.back // Back is -forward, so this moves correctly
	if la.length(target_velocity) > 0 {
		target_velocity = la.normalize(target_velocity)
	}
	target_velocity *= camera.movement_speed

	// Update velocity with friction
	lerp_factor := math.pow(1 - camera.friction_coefficient, delta_time)
	camera.velocity = la.lerp(target_velocity, camera.velocity, lerp_factor)

	// Update position
	camera.position.xyz = pos + camera.velocity * delta_time

	// Build matrices
	update_matrix_from_vectors(camera)

	return camera.view
}

// Recalculates the yaw and pitch values from a directional vector
wasd_camera_recalculate_angles :: proc "contextless" (camera: ^WASD_Camera, dir: la.Vector3f32) {
	camera.yaw = math.atan2(dir.x, dir.z)
	camera.pitch = math.asin(dir.y)
}
