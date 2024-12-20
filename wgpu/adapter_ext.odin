package wgpu

// Packages
import "base:runtime"
import "core:fmt"
import "core:strings"

/* Create a string from adapter information (device, driver, type and backend). */
adapter_info_string :: proc(
	info: AdapterInfo,
	allocator := context.allocator,
) -> (
	str: string,
	ok: bool,
) #optional_ok {
	sb: strings.Builder
	err: runtime.Allocator_Error

	ta := context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == ta)
	if sb, err = strings.builder_make(ta); err != nil {
		return
	}
	defer strings.builder_destroy(&sb)

	strings.write_string(&sb, info.device)
	strings.write_byte(&sb, '\n')

	strings.write_string(&sb, "  - Driver: ")
	strings.write_string(&sb, info.description if info.description != "" else "Unknown")
	strings.write_byte(&sb, '\n')

	adapter_type: string
	switch info.adapter_type {
	case AdapterType.DiscreteGPU:
		adapter_type = "Discrete GPU with separate CPU/GPU memory"
	case AdapterType.IntegratedGPU:
		adapter_type = "Integrated GPU with shared CPU/GPU memory"
	case AdapterType.CPU:
		adapter_type = "Cpu / Software Rendering"
	case AdapterType.Unknown:
		adapter_type = "Unknown"
	}
	strings.write_string(&sb, "  - Type: ")
	strings.write_string(&sb, adapter_type)
	strings.write_byte(&sb, '\n')

	backend_type: string
	#partial switch info.backend_type {
	case BackendType.Null:
		backend_type = "Empty"
	case BackendType.WebGPU:
		backend_type = "WebGPU in the browser"
	case BackendType.D3D11:
		backend_type = "Direct3D-11"
	case BackendType.D3D12:
		backend_type = "Direct3D-12"
	case BackendType.Metal:
		backend_type = "Metal API"
	case BackendType.Vulkan:
		backend_type = "Vulkan API"
	case BackendType.OpenGL:
		backend_type = "OpenGL"
	case BackendType.OpenGLES:
		backend_type = "OpenGLES"
	}
	strings.write_string(&sb, "  - Backend: ")
	strings.write_string(&sb, backend_type)

	if str, err = strings.clone(strings.to_string(sb), allocator); err != nil {
		return
	}

	return str, true
}

/* Print adapter information (name, driver, type and backend. */
adapter_info_print_info :: proc(info: AdapterInfo) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	fmt.printfln("%s", adapter_info_string(info, context.temp_allocator))
}
