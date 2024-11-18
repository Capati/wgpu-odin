package wgpu

// STD Library
import "base:runtime"
import "core:fmt"
import "core:strings"

// The raw bindings
import wgpu "../bindings"

/* Create a string with adapter information (name, driver, type and backend). */
adapter_info_string :: proc(
	self: Adapter,
	allocator := context.allocator,
) -> (
	str: string,
	ok: bool,
) #optional_ok {
	sb: strings.Builder
	err: runtime.Allocator_Error

	ta := context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == ta)
	if sb, err = strings.builder_make(ta); err != nil do return
	defer strings.builder_destroy(&sb)

	info := adapter_get_info(self) or_return

	strings.write_string(&sb, string(info.device))
	strings.write_byte(&sb, '\n')

	description: cstring = info.description
	if description == nil || description == "" {
		description = "Unknown"
	}
	strings.write_string(&sb, "  - Driver: ")
	strings.write_string(&sb, string(description))
	strings.write_byte(&sb, '\n')

	adapter_type: string
	switch info.adapter_type {
	case wgpu.Adapter_Type.Discrete_GPU:
		adapter_type = "Discrete GPU with separate CPU/GPU memory"
	case wgpu.Adapter_Type.Integrated_GPU:
		adapter_type = "Integrated GPU with shared CPU/GPU memory"
	case wgpu.Adapter_Type.CPU:
		adapter_type = "Cpu / Software Rendering"
	case wgpu.Adapter_Type.Unknown:
		adapter_type = "Unknown"
	}
	strings.write_string(&sb, "  - Type: ")
	strings.write_string(&sb, adapter_type)
	strings.write_byte(&sb, '\n')

	backend_type: string
	#partial switch info.backend_type {
	case wgpu.Backend_Type.Null:
		backend_type = "Empty"
	case wgpu.Backend_Type.WebGPU:
		backend_type = "WebGPU in the browser"
	case wgpu.Backend_Type.D3D11:
		backend_type = "Direct3D-11"
	case wgpu.Backend_Type.D3D12:
		backend_type = "Direct3D-12"
	case wgpu.Backend_Type.Metal:
		backend_type = "Metal API"
	case wgpu.Backend_Type.Vulkan:
		backend_type = "Vulkan API"
	case wgpu.Backend_Type.OpenGL:
		backend_type = "OpenGL"
	case wgpu.Backend_Type.OpenGLES:
		backend_type = "OpenGLES"
	}
	strings.write_string(&sb, "  - Backend: ")
	strings.write_string(&sb, backend_type)

	if str, err =  strings.clone(strings.to_string(sb), allocator); err != nil do return

	return str, true
}

/* Print adapter information (name, driver, type and backend. */
adapter_print_info :: proc(self: Adapter) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	fmt.printfln("%s", adapter_info_string(self, context.temp_allocator))
}
