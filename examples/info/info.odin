#+build !js
package info

// Core
import "base:runtime"
import "core:fmt"

// Local packages
import wgpu "../../"

main :: proc() {
	wgpu_version := wgpu.GetVersion()

	fmt.printf(
		"WGPU version: %d.%d.%d.%d\n\n",
		wgpu_version.major,
		wgpu_version.minor,
		wgpu_version.patch,
		wgpu_version.build,
	)

	instance := wgpu.CreateInstance()
	defer wgpu.Release(instance)

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	ta := context.temp_allocator

	adapters := wgpu.InstanceEnumerateAdapters(instance, wgpu.BACKENDS_ALL, ta)
	if len(adapters) == 0 {
		fmt.eprintln("No adapters available")
		return
	}

	fmt.println("Available adapter(s):\n")

	for a, i in adapters {
		info, status := wgpu.AdapterGetInfo(a)
		if status != .Success {
			fmt.eprintfln("Failed to get adapter info at index [%d]", i)
			continue
		}
		wgpu.AdapterInfoPrint(info)
		wgpu.AdapterInfoFreeMembers(info)
	}

	adapter_res := wgpu.InstanceRequestAdapterSync(instance)
	if (adapter_res.status != .Success) {
		fmt.eprintfln(
			"Failed to request the selected adapter [%v]: %s",
			adapter_res.status,
			adapter_res.message,
		)
		return
	}

	adapter := adapter_res.adapter
	defer wgpu.Release(adapter)

	fmt.println("\nSelected adapter:\n")
	info, status := wgpu.AdapterGetInfo(adapter)
	if status != .Success {
		fmt.eprintln("Failed to get adapter info for the selected adapter")
		return
	}
	wgpu.AdapterInfoPrint(info)
	wgpu.AdapterInfoFreeMembers(info)
}
