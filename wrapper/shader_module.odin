package wgpu

// STD Library
import "base:runtime"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"

// Local packages
import wgpu "../bindings"

/*
Handle to a compiled shader module.

A `Shader_Module` represents a compiled shader module on the GPU. It can be created by passing
source code to `device_create_shader_module` or valid SPIR-V binary to
`device_create_shader_module_spirv`. Shader modules are used to define programmable stages
of a pipeline.

Corresponds to [WebGPU `GPUShaderModule`](https://gpuweb.github.io/gpuweb/#shader-module).
*/
Shader_Module :: wgpu.Shader_Module

/*
Source of a shader module (`string` or `cstring` for WGSL and `[]u32` for SPIR-V).

The source will be parsed and validated.

Any necessary shader translation (e.g. from WGSL to SPIR-V or vice versa)
will be done internally by wgpu.

This type is unique to the `wgpu-native`. In the WebGPU specification,
only WGSL source code strings are accepted.
*/
Shader_Source :: union {
	string,  /* WGSL, will be `clone_to_cstring` to ensure null terminated */
	cstring, /* WGSL */
	[]u32,   /* SPIR-V */
}

/*
Descriptor for use with `device_create_shader_module`.

Corresponds to [WebGPU `GPUShaderModuleDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpushadermoduledescriptor).
*/
Shader_Module_Descriptor :: struct {
	label  : cstring,
	source : Shader_Source,
}

/* Load a wgsl shader file and return a compiled shader module. */
device_load_wgsl_shader_module :: proc(
	self: Device,
	path: cstring,
	label: cstring = nil,
	loc := #caller_location,
) -> (
	shader_module: Shader_Module,
	ok: bool,
) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	ta := context.temp_allocator

	data, data_ok := os.read_entire_file(string(path), ta)

	if !data_ok {
		error_message := fmt.tprintf("Failed to load WGSL shader file: [%s]", path)
		error_reset_and_update(.Read_File_Failed, error_message, loc)
		return
	}

	// Use the path as label if label is not given
	current_label: cstring = path if label == nil else label

	// Clone to `cstring` to ensure null termination
	c_source, c_source_err := strings.clone_to_cstring(string(data), ta)

	if c_source_err != nil {
		error_message := fmt.tprintf("Failed to allocate the WGSL shader source: [%s]", label)
		error_reset_and_update(c_source_err, error_message, loc)
		return
	}

	descriptor := Shader_Module_Descriptor {
		label  = current_label,
		source = c_source,
	}

	return device_create_shader_module(self, descriptor)
}

/* Load a spirv shader file and return a compiled shader module. */
device_load_spirv_shader_module :: proc(
	self: Device,
	path: cstring,
	label: cstring = nil,
	loc := #caller_location,
) -> (
	shader_module: Shader_Module,
	ok: bool,
) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	data, data_ok := os.read_entire_file(string(path), context.temp_allocator)

	if !data_ok {
		error_message := fmt.tprintf("Failed to load SPIRV shader file: [%s]", path)
		error_reset_and_update(.Read_File_Failed, error_message, loc)
		return
	}

	// Use the path as label if label is not given
	current_label: cstring = path if label == nil else label

	descriptor := Shader_Module_Descriptor {
		label  = current_label,
		source = slice.reinterpret([]u32, data),
	}

	return device_create_shader_module(self, descriptor)
}

/* Set debug label. */
shader_module_set_label :: wgpu.shader_module_set_label

/* Increase the reference count. */
shader_module_reference :: wgpu.shader_module_reference

/* Release the `Shader_Module` resources. */
shader_module_release :: wgpu.shader_module_release
