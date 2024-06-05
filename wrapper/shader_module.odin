package wgpu

// Core
import "core:fmt"
import "core:os"
import "core:runtime"
import "core:slice"
import "core:strings"

// Package
import wgpu "../bindings"

// Handle to a compiled shader module.
//
// A `Shader_Module` represents a compiled shader module on the GPU. It can be created by passing
// source code to `device_create_shader_module` or valid SPIR-V binary to
// `device_create_shader_module_spirv`. Shader modules are used to define programmable stages of a
// pipeline.
Shader_Module :: struct {
	ptr: Raw_Shader_Module,
}

WGSL_Source :: cstring
SPIRV_Source :: []u32

// Source of a shader module.
Shader_Source :: union {
	WGSL_Source,
	SPIRV_Source,
}

Shader_Module_Descriptor :: struct {
	label:  cstring,
	source: Shader_Source,
}

// Load a wgsl shader file and return a compiled shader module.
device_load_wgsl_shader_module :: proc(
	using self: ^Device,
	path: cstring,
	label: cstring = nil,
) -> (
	shader_module: Shader_Module,
	err: Error_Type,
) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	data, data_ok := os.read_entire_file(string(path), context.temp_allocator)

	if !data_ok {
		fmt.eprintf("Failed to load WGSL shader file: [%s]\n", path)
		return {}, .Unknown
	}

	// Use the path as label if label is not given
	current_label: cstring = path if label == nil else label

	descriptor := Shader_Module_Descriptor {
		label  = current_label,
		// clone to cstring to ensure null termination
		source = strings.clone_to_cstring(string(data), context.temp_allocator),
	}

	return device_create_shader_module(self, &descriptor)
}

// Load a spirv shader file and return a compiled shader module.
device_load_spirv_shader_module :: proc(
	using self: ^Device,
	path: cstring,
	label: cstring = nil,
) -> (
	shader_module: Shader_Module,
	err: Error_Type,
) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	data, data_ok := os.read_entire_file(string(path), context.temp_allocator)

	if !data_ok {
		fmt.eprintf("Failed to load SPIRV shader file: [%s]\n", path)
		return {}, .Unknown
	}

	// Use the path as label if label is not given
	current_label: cstring = path if label == nil else label

	descriptor := Shader_Module_Descriptor {
		label  = current_label,
		source = slice.reinterpret([]u32, data),
	}

	return device_create_shader_module(self, &descriptor)
}

// Set debug label.
shader_module_set_label :: proc(using self: ^Shader_Module, label: cstring) {
	wgpu.shader_module_set_label(ptr, label)
}

// Increase the reference count.
shader_module_reference :: proc(using self: ^Shader_Module) {
	wgpu.shader_module_reference(ptr)
}

// Release the `Shader_Module`.
shader_module_release :: proc(using self: ^Shader_Module) {
	if ptr == nil do return
	wgpu.shader_module_release(ptr)
	ptr = nil
}
