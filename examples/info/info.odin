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

	instance := wgpu.create_instance() or_return
	defer wgpu.instance_release(instance)

	adapters := wgpu.instance_enumerate_adapters(instance, wgpu.Instance_Backend_All)
	defer delete(adapters)

	for &a in adapters {
		wgpu.adapter_print_info(a)
	}

	adapter := wgpu.instance_request_adapter(
		instance,
		{power_preference = .High_Performance},
	) or_return
	defer wgpu.adapter_release(adapter)

	fmt.println("\nSelected adapter:\n")
	wgpu.adapter_print_info(adapter)

	return true
}

main :: proc() {
	run()
}
