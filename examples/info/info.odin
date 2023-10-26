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

    instance, instance_err := wgpu.create_instance(&instance_descriptor)
    if instance_err != .No_Error {
        fmt.eprintln("ERROR Creating Instance:", wgpu.get_error_message())
        return
    }
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

    adapter->print_info()
}
