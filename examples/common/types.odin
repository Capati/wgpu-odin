package examples_common

// Core
import la "core:math/linalg"
import "core:mem"

// Package
import wgpu "../../wrapper"

// Framework
import app "./../framework/application"
import "./../framework/renderer"

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


// Base fields for framework examples
State_Base :: struct {
	using gpu:        ^renderer.Renderer,
	render_pass_desc: wgpu.Render_Pass_Descriptor,
	color_attachment: ^wgpu.Render_Pass_Color_Attachment,
}

Error :: union #shared_nil {
	app.Application_Error,
	wgpu.Error,
	mem.Allocator_Error,
}
