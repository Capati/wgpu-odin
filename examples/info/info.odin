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

	instance_descriptor := wgpu.Instance_Descriptor {
		backends = wgpu.Instance_Backend_Primary,
	}

	instance, instance_err := wgpu.create_instance(&instance_descriptor)
	if instance_err != nil do return
	defer wgpu.instance_release(&instance)

	adapter, adapter_err := wgpu.instance_request_adapter(
		&instance,
		&{power_preference = .High_Performance},
	)
	if adapter_err != nil do return
	defer wgpu.adapter_release(&adapter)

	fmt.print("Device information:\n\n")
	wgpu.adapter_print_info(&adapter)
}
