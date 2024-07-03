package examples_common

// Core
import "core:math"
import la "core:math/linalg"
import "core:slice"

// Package
import wgpu "./../../wrapper"

generate_matrix :: proc(aspect: f32) -> la.Matrix4f32 {
	projection := la.matrix4_perspective_f32(math.PI / 4, aspect, 1.0, 10.0)
	view := la.matrix4_look_at_f32(
		eye = {1.5, -5.0, 3.0},
		centre = {0.0, 0.0, 0.0},
		up = {0.0, 0.0, 1.0},
	)
	return la.mul(projection, view)
}

create_render_pass_descriptor :: proc(
	label: cstring = nil,
	color: wgpu.Color = wgpu.Color_Black,
	allocator := context.allocator,
) -> (
	desc: wgpu.Render_Pass_Descriptor,
	err: Error,
) {
	desc = wgpu.Render_Pass_Descriptor {
		label             = label,
		color_attachments = slice.clone(
			[]wgpu.Render_Pass_Color_Attachment {
				{
					view        = nil, // Assigned later
					load_op     = .Clear,
					store_op    = .Store,
					clear_value = color,
				},
			},
			allocator,
		) or_return,
	}

	return
}
