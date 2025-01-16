package wgpu

// Packages
import "base:runtime"
import "core:fmt"
import "core:os"
import "core:slice"

/*
Handle to a compiled shader module.

A `Shader_Module` represents a compiled shader module on the GPU. It can be created by passing
source code to `device_create_shader_module` or valid SPIR-V binary to
`device_create_shader_module_spirv`. Shader modules are used to define programmable stages
of a pipeline.

Corresponds to [WebGPU `GPUShaderModule`](https://gpuweb.github.io/gpuweb/#shader-module).
*/
Shader_Module :: distinct rawptr

/* Defines to unlock configured shader features. */
Shader_Define :: struct {
	name:  string,
	value: string,
}

/* GLSL module. */
GLSL_Source :: struct {
	shader:  string,
	stage:   Shader_Stage,
	defines: []Shader_Define,
}

/*
Source of a shader module:

- `string` or `cstring` for **WGSL**
- `[]u32` for **SPIR-V**
- `GLSL_Source` for **GLSL**

**Note**: the `cstring` type is assumed to be null-terminated.

The source will be parsed and validated.

Any necessary shader translation (e.g. from WGSL to SPIR-V or vice versa)
will be done internally by wgpu.

This type is unique to the `wgpu-native`. In the WebGPU specification,
only WGSL source code strings are accepted.
*/
Shader_Source :: union {
	string, /* WGSL, will be `clone_to_cstring` to ensure null terminated */
	cstring, /* WGSL, null-terminated */
	[]u32, /* SPIR-V */
	GLSL_Source, /* GLSL */
}

/*
Descriptor for use with `device_create_shader_module`.

Corresponds to [WebGPU `GPUShaderModuleDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpushadermoduledescriptor).
*/
Shader_Module_Descriptor :: struct {
	label:  string,
	source: Shader_Source,
}

/* Load a wgsl shader file and return a compiled shader module. */
device_load_wgsl_shader_module :: proc(
	self: Device,
	path: string,
	label: string = "",
	loc := #caller_location,
) -> (
	shader_module: Shader_Module,
	ok: bool,
) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	data, data_ok := os.read_entire_file(path, context.temp_allocator)

	if !data_ok {
		error_message := fmt.tprintf("Failed to load WGSL shader file: [%s]", path)
		error_reset_and_update(.ReadFileFailed, error_message, loc)
		return
	}

	descriptor := Shader_Module_Descriptor {
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
	shader_module: Shader_Module,
	ok: bool,
) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	data, data_ok := os.read_entire_file(path, context.temp_allocator)

	if !data_ok {
		error_message := fmt.tprintf("Failed to load SPIRV shader file: [%s]", path)
		error_reset_and_update(.ReadFileFailed, error_message, loc)
		return
	}

	descriptor := Shader_Module_Descriptor {
		label  = path if label == "" else label,
		source = slice.reinterpret([]u32, data),
	}

	return device_create_shader_module(self, descriptor)
}

/*
Compilation information for a shader module.

Corresponds to [WebGPU `GPUCompilationInfo`](https://gpuweb.github.io/gpuweb/#gpucompilationinfo).
The source locations use bytes, and index a UTF-8 encoded string.
*/
Compilation_Info :: struct {
	messages: []Compilation_Message,
}

/* Get the compilation info for the shader module. */
shader_module_get_compilation_info :: proc(
	self: Shader_Module,
	callback_info: Compilation_Info_Callback_Info,
) -> Future {
	unimplemented()
}

/* Sets a debug label for the given `Shader_Module`. */
@(disabled = !ODIN_DEBUG)
shader_module_set_label :: proc "contextless" (self: Shader_Module, label: string) {
	c_label: String_View_Buffer
	wgpuShaderModuleSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the `Shader_Module` reference count. */
shader_module_add_ref :: wgpuShaderModuleAddRef

/* Release the `Shader_Module` resources, use to decrease the reference count. */
shader_module_release :: wgpuShaderModuleRelease

/*
Safely releases the `Shader_Module` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
shader_module_release_safe :: #force_inline proc(self: ^Shader_Module) {
	if self != nil && self^ != nil {
		wgpuShaderModuleRelease(self^)
		self^ = nil
	}
}

@(private)
WGPU_Shader_Define :: struct {
	name:  String_View,
	value: String_View,
}

@(private)
WGPU_Shader_Module_GLSL_Descriptor :: struct {
	chain:        Chained_Struct,
	stage:        Shader_Stage,
	code:         String_View,
	define_count: u32,
	defines:      [^]WGPU_Shader_Define,
}

WGPU_Compilation_Info :: struct {
	next_in_chain: ^Chained_Struct,
	messageCount:  uint,
	messages:      [^]Compilation_Message,
}
