package wgpu_bindings

import "vendor:darwin/Foundation"
import "vendor:darwin/QuartzCore"
import "vendor:darwin/Metal"
import "vendor:darwin/MetalKit"

// Required by wgpu-native
foreign import _core_animation "system:QuartzCore.framework"
@(private)
foreign _core_animation {
	kCAGravityTopLeft: Foundation.String
}

// For some reason odin does not import Foundation, QuartzCore and the kCAGravityTopLeft global variable without 
// this function.
@(private, require)
_DO_NOT_CALL_odin_force_package_inclusion :: proc() {
	array := Foundation.Array_alloc()->init()
	defer array->release()

	func := QuartzCore.MetalDrawable_layer
	func = nil

	kCAGravityTopLeft->length()
}

_ :: Foundation
_ :: QuartzCore
_ :: Metal
_ :: MetalKit

