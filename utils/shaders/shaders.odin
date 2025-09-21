package wgpu_shader_utils

// Core
import "core:mem"
import "core:strings"

// Local packages
import wgpu "../../"

LINEAR_TO_SRGB_WGSL: string : #load("linear_to_srgb.wgsl", string)
SRGB_TO_LINEAR_WGSL: string : #load("srgb_to_linear.wgsl", string)

// odinfmt: disable
SRGB_TO_LINEAR_COLOR_CONVERSION: string : SRGB_TO_LINEAR_WGSL + `
fn apply_color_conversion(color: vec3<f32>) -> vec3<f32> {
	return srgb_to_linear(color);
}
`

LINEAR_TO_SRGB_COLOR_CONVERSION: string : LINEAR_TO_SRGB_WGSL + `
fn apply_color_conversion(color: vec3<f32>) -> vec3<f32> {
	return linear_to_srgb(color);
}
`

NON_COLOR_CONVERSION: string : `
fn apply_color_conversion(color: vec3<f32>) -> vec3<f32> {
    return color;
}
`
// odinfmt: enable

apply_color_conversion :: proc(
	source: string,
	is_srgb: bool,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	res: string,
	ok: bool,
) #optional_ok {
	err: mem.Allocator_Error

	if is_srgb {
		res, err = strings.join({SRGB_TO_LINEAR_COLOR_CONVERSION, source}, "\n", allocator)
	} else {
		res, err = strings.join({NON_COLOR_CONVERSION, source}, "\n", allocator)
	}

	if err != nil {
		wgpu.error_reset_and_update(err, "Failed to create the shader string", loc)
		return
	}

	return res, true
}
