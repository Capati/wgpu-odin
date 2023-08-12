package info

// Core
import "core:fmt"

// Package
import wgpu "../../wrapper"

main :: proc() {
    wgpu_version := wgpu.get_version()

    fmt.printf(
        "WGPU version: %d.%d.%d.%d\n\n",
        wgpu_version.major,
        wgpu_version.minor,
        wgpu_version.patch,
        wgpu_version.build,
    )

    // Instance
    instance_descriptor := wgpu.Instance_Descriptor {
        backends = wgpu.Instance_Backend_Primary,
    }

    instance := wgpu.create_instance(&instance_descriptor)
    defer instance->release()

    // Adapter
    adapter, adapter_err := instance->request_adapter(
        &{power_preference = .High_Performance},
    )
    if adapter_err != .No_Error {
        fmt.eprintln("ERROR Creating Adapter:", wgpu.get_error_message())
        return
    }
    defer adapter->release()

    print_adapter_information(adapter.info)
}

print_adapter_information :: proc(info: wgpu.Adapter_Info) {
    fmt.print("Selected device:\n\n")
    fmt.printf("%s\n", info.name)

    driver_description: cstring = info.driver_description

    if driver_description == nil || driver_description == "" {
        driver_description = "Unknown"
    }

    fmt.printf("\tDriver: %s\n", driver_description)

    adapter_type: cstring = ""

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

    fmt.printf("\tType: %s\n", adapter_type)

    backend_type: cstring

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

    fmt.printf("\tBackend: %s\n", backend_type)
}
