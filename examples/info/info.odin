package info

// Packages
import "base:runtime"
import "core:fmt"

// Local packages
import "root:wgpu"

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

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	ta := context.temp_allocator

	adapters := wgpu.instance_enumerate_adapters(instance, wgpu.BACKENDS_ALL, ta) or_return
	for a in adapters {
		info := wgpu.adapter_get_info(a, ta)
		wgpu.adapter_info_print_info(info)
	}

	adapter := wgpu.instance_request_adapter(instance) or_return
	defer wgpu.adapter_release(adapter)

	fmt.println("\nSelected adapter:\n")
	info := wgpu.adapter_get_info(adapter, ta)
	wgpu.adapter_info_print_info(info)

	return true
}

main :: proc() {
	run()
}
