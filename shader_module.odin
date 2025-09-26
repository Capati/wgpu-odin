package webgpu

// Core
import "base:runtime"
import "core:os"
import "core:slice"

// Vendor
import "vendor:wgpu"

/*
Handle to a compiled shader module.

A `ShaderModule` represents a compiled shader module on the GPU. It can be
created by passing source code to `DeviceCreateShaderModule` or valid SPIR-V
binary to `DeviceCreateShaderModuleSpirV`. Shader modules are used to define
programmable stages of a pipeline.

Corresponds to [WebGPU
`GPUShaderModule`](https://gpuweb.github.io/gpuweb/#shader-module).
*/
ShaderModule :: wgpu.ShaderModule

/*
Load a WGSL shader file and return a compiled shader module.
*/
DeviceLoadWgslShaderModule :: proc(
	self: Device,
	path: string,
	label: string = "",
	loc := #caller_location,
) -> (
	shaderModule: ShaderModule,
) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	source, source_ok := os.read_entire_file(path, context.temp_allocator, loc)
	assert(source_ok, "Failed to read shader path", loc)

	descriptor := ShaderModuleDescriptor {
		label  = label if label != "" else path,
		source = string(source),
	}

	shaderModule = DeviceCreateShaderModule(self, descriptor)

	return
}

/* Load a spirv shader file and return a compiled shader module. */
DeviceLoadSpirVShaderModule :: proc(
	self: Device,
	path: string,
	label: string = "",
	loc := #caller_location,
) -> (
	shaderModule: ShaderModule,
) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	source, source_ok := os.read_entire_file(path, context.temp_allocator, loc)
	assert(source_ok, "Failed to read shader path", loc)

	descriptor := ShaderModuleDescriptor {
		label  = label if label != "" else path,
		source = slice.reinterpret([]u32, source),
	}

	return DeviceCreateShaderModule(self, descriptor)
}

CompilationMessage :: wgpu.CompilationMessage

/*
Compilation information for a shader module.

Corresponds to [WebGPU
`GPUCompilationInfo`](https://gpuweb.github.io/gpuweb/#gpucompilationinfo). The
source locations use bytes, and index a UTF-8 encoded string.
*/
CompilationInfo :: struct {
	messages: []CompilationMessage,
}

/* Get the compilation info for the shader module. */
ShaderModuleGetCompilationInfo :: proc(self: ShaderModule) -> CompilationInfo {
	unimplemented()
}

/* Sets a debug label for the given `ShaderModule`. */
ShaderModuleSetLabel :: #force_inline proc "c" (self: ShaderModule, label: string) {
	wgpu.ShaderModuleSetLabel(self, label)
}

/* Increase the `ShaderModule` reference count. */
ShaderModuleAddRef :: #force_inline proc "c" (self: ShaderModule) {
	wgpu.ShaderModuleAddRef(self)
}

/* Release the `ShaderModule` resources, use to decrease the reference count. */
ShaderModuleRelease :: #force_inline proc "c" (self: ShaderModule) {
	wgpu.ShaderModuleRelease(self)
}

/*
Safely releases the `ShaderModule` resources and invalidates the handle. The
procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
ShaderModuleReleaseSafe :: proc "c" (self: ^ShaderModule) {
	if self != nil && self^ != nil {
		wgpu.ShaderModuleRelease(self^)
		self^ = nil
	}
}
