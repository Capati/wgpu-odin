package info

// STD Library
import "core:fmt"

// Local packages
import wgpu "../../wrapper"

run :: proc() -> (ok: bool) {
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

	instance := wgpu.create_instance(instance_descriptor) or_return
	defer wgpu.instance_release(instance)

	adapter := wgpu.instance_request_adapter(
		instance,
		{power_preference = .High_Performance},
	) or_return
	defer wgpu.adapter_release(adapter)

	fmt.print("Device information:\n\n")
	wgpu.adapter_print_info(adapter)

	return true
}

main :: proc() {
	run()
}
