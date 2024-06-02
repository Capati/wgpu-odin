package wgpu

// Core
import "core:fmt"

import wgpu "../bindings"

// Print adapter information (name, driver, type and backend).
adapter_print_info :: proc(using self: ^Adapter) {
	fmt.printf("%s\n", properties.name)

	driver_description: cstring = properties.driver_description

	if driver_description == nil || driver_description == "" {
		driver_description = "Unknown"
	}

	fmt.printf("\tDriver: %s\n", driver_description)

	adapter_type: cstring = ""

	switch properties.adapter_type {
	case wgpu.Adapter_Type.Discrete_GPU:
		adapter_type = "Discrete GPU with separate CPU/GPU memory"
	case wgpu.Adapter_Type.Integrated_GPU:
		adapter_type = "Integrated GPU with shared CPU/GPU memory"
	case wgpu.Adapter_Type.CPU:
		adapter_type = "Cpu / Software Rendering"
	case wgpu.Adapter_Type.Unknown:
		adapter_type = "Unknown"
	}

	fmt.printf("\tType: %s\n", adapter_type)

	backend_type: cstring

	#partial switch properties.backend_type {
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

	fmt.printf("\tBackend: %s\n\n", backend_type)
}
