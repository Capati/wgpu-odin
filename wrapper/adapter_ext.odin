package wgpu

// STD Library
import "base:runtime"
import "core:fmt"
import "core:strings"

// Local Packages
import wgpu "../bindings"

// Get adapter information string (name, driver, type and backend).
adapter_info_string :: proc(using self: Adapter, allocator := context.allocator) -> string {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == context.temp_allocator)

	sb := strings.builder_make(context.temp_allocator)
	defer strings.builder_destroy(&sb)

	strings.write_string(&sb, "  ")
	strings.write_string(&sb, string(info.name))
	strings.write_byte(&sb, '\n')

	driver_description: cstring = info.driver_description
	if driver_description == nil || driver_description == "" {
		driver_description = "Unknown"
	}
	strings.write_string(&sb, "    - Driver: ")
	strings.write_string(&sb, string(driver_description))
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
	strings.write_string(&sb, "    - Type: ")
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
	strings.write_string(&sb, "    - Backend: ")
	strings.write_string(&sb, backend_type)

	return strings.clone(strings.to_string(sb), allocator)
}

// Print adapter information (name, driver, type and backend).
adapter_print_info :: proc(using self: Adapter) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	fmt.printfln("%s", adapter_info_string(self, context.temp_allocator))
}
