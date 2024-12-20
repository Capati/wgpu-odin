package application

// Packages
import "core:math"
import la "core:math/linalg"

CameraType :: enum {
	Look_At, // Third person camera
	First_Person, // First person camera
}

Camera :: struct {
	perspective:               Mat4,
	view:                      Mat4,
	right, up, back, position: Vec3,
}

WASDCamera :: struct {
	using camera:         Camera,
	pitch, yaw:           f32,
	velocity:             Vec3,
	movement_speed:       f32,
	rotation_speed:       f32,
	friction_coefficient: f32,
}

ArcballCamera :: struct {
	using camera:         Camera,
	distance:             f32,
	angular_velocity:     f32,
	axis:                 Vec3,
	rotation_speed:       f32,
	zoom_speed:           f32,
	friction_coefficient: f32,
}

new_arcball_camera :: proc(position: Vec3) -> ArcballCamera {
	camera := ArcballCamera {
		camera = Camera{perspective = la.MATRIX4F32_IDENTITY, view = la.MATRIX4F32_IDENTITY},
		rotation_speed = 1,
		zoom_speed = 0.1,
		friction_coefficient = 0.999,
	}

	camera.position = position
	camera.distance = la.length(position)
	camera.back = la.normalize(position)
	camera_recalculate_right(&camera)
	camera_recalculate_up(&camera)

	return camera
}

Input :: struct {
	analog:  struct {
		x, y:     f32,
		zoom:     f32,
		touching: bool,
	},
	digital: struct {
		right, left, up, down, forward, backward: bool,
	},
}

// camera_update_arcball :: proc(camera: ^ArcballCamera, delta_time: f32, input: ^Input) -> Mat4 {
// 	epsilon :: 0.0000001

// 	if input.analog.touching {
// 		camera.angular_velocity = 0
// 	} else {
// 		camera.angular_velocity *= pow(1 - camera.friction_coefficient, delta_time)
// 	}

// 	// Use vector3 operations for movement calculation
// 	movement := vector3{
// 		camera.right.x * input.analog.x + camera.up.x * -input.analog.y,
// 		camera.right.y * input.analog.x + camera.up.y * -input.analog.y,
// 		camera.right.z * input.analog.x + camera.up.z * -input.analog.y,
// 	}

// 	// Use vector_cross3 for cross product
// 	cross_product := vector_cross3(movement, camera.back)
// 	magnitude := vector_length(cross_product)

// 	if magnitude > epsilon {
// 		camera.axis = vector_normalize(cross_product)
// 		camera.angular_velocity = magnitude * camera.rotation_speed
// 	}

// 	rotation_angle := camera.angular_velocity * delta_time
// 	if rotation_angle > epsilon {
// 		// Create rotation quaternion
// 		rotation_quat := quaternion_angle_axis_f32(rotation_angle, camera.axis)
// 		// Rotate the back vector using quaternion
// 		camera.back = quaternion_mul_vector3(rotation_quat, camera.back)
// 		camera.back = vector_normalize(camera.back)
// 		camera.recalculate_right()
// 		camera.recalculate_up()
// 	}

// 	if input.analog.zoom != 0 {
// 		camera.distance *= 1 + input.analog.zoom * camera.zoom_speed
// 	}

// 	// Update position
// 	camera.position = vector3{
// 		camera.back.x * camera.distance,
// 		camera.back.y * camera.distance,
// 		camera.back.z * camera.distance,
// 	}

// 	// Construct view matrix
// 	camera.perspective = matrix4_look_at_f32(
// 		camera.position,
// 		{0, 0, 0}, // target at origin
// 		camera.up,
// 	)

// 	camera.view = matrix4_inverse_f32(camera.perspective)
// 	return camera.view
// }

// camera_update :: proc {
// 	camera_update_arcball,
// }

camera_recalculate_right :: proc(camera: ^ArcballCamera) {
	camera.right = la.normalize(la.cross(camera.up, camera.back))
}

camera_recalculate_up :: proc(camera: ^ArcballCamera) {
	camera.up = la.normalize(la.cross(camera.back, camera.right))
}

// camera_rotate :: proc(vec, axis: Vec3, angle: f32) -> Vec3 {
// 	rotation_matrix := la.matrix2_rotate_f32(axis, angle)
// 	return la.mul(vec, rotation_matrix)
// }

camera_clamp :: proc(x, min, max: f32) -> f32 {
	return math.min(math.max(x, min), max)
}
