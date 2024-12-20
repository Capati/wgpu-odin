package wgpu

// Packages
import "base:runtime"
import "core:fmt"
import "core:os"
import "core:slice"

/*
Handle to a compiled shader module.

A `ShaderModule` represents a compiled shader module on the GPU. It can be created by passing
source code to `device_create_shader_module` or valid SPIR-V binary to
`device_create_shader_module_spirv`. Shader modules are used to define programmable stages
of a pipeline.

Corresponds to [WebGPU `GPUShaderModule`](https://gpuweb.github.io/gpuweb/#shader-module).
*/
ShaderModule :: distinct rawptr

/* Load a wgsl shader file and return a compiled shader module. */
device_load_wgsl_shader_module :: proc(
	self: Device,
	path: string,
	label: string = "",
	loc := #caller_location,
) -> (
	shader_module: ShaderModule,
	ok: bool,
) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	data, data_ok := os.read_entire_file(path, context.temp_allocator)

	if !data_ok {
		error_message := fmt.tprintf("Failed to load WGSL shader file: [%s]", path)
		error_reset_and_update(.ReadFileFailed, error_message, loc)
		return
	}

	descriptor := ShaderModuleDescriptor {
		label  = path if label == "" else label,
		source = string(data),
	}

	return device_create_shader_module(self, descriptor)
}

/* Load a spirv shader file and return a compiled shader module. */
device_load_spirv_shader_module :: proc(
	self: Device,
	path: string,
	label: string = "",
	loc := #caller_location,
) -> (
	shader_module: ShaderModule,
	ok: bool,
) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	data, data_ok := os.read_entire_file(path, context.temp_allocator)

	if !data_ok {
		error_message := fmt.tprintf("Failed to load SPIRV shader file: [%s]", path)
		error_reset_and_update(.ReadFileFailed, error_message, loc)
		return
	}

	descriptor := ShaderModuleDescriptor {
		label  = path if label == "" else label,
		source = slice.reinterpret([]u32, data),
	}

	return device_create_shader_module(self, descriptor)
}

/* Set debug label. */
@(disabled = !ODIN_DEBUG)
shader_module_set_label :: proc "contextless" (self: ShaderModule, label: string) {
	c_label: StringViewBuffer
	wgpuShaderModuleSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the reference count. */
shader_module_add_ref :: wgpuShaderModuleAddRef

/* Release the `ShaderModule` resources. */
shader_module_release :: wgpuShaderModuleRelease
