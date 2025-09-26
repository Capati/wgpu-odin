#+build !js
package webgpu

// Core
import "core:fmt"

// Vendor
import "vendor:wgpu"

RequestAdapterResult :: struct {
	status:  RequestAdapterStatus,
	message: string,
	adapter: Adapter,
}

/*
Retrieves an `Adapter` which matches the given `RequestAdapterOptions`.

Some options are "soft", so treated as non-mandatory. Others are "hard".

If no adapters are found that suffice all the "hard" options, `nil` is returned.

A `compatibleSurface` is required when targeting WebGL2.
*/
@(require_results)
InstanceRequestAdapterSync :: proc "c" (
	self: Instance,
	options: Maybe(RequestAdapterOptions) = nil,
) -> (
	res: RequestAdapterResult,
) {
	request_adapter_callback :: proc "c" (
		status: RequestAdapterStatus,
		adapter: Adapter,
		message: string,
		userdata1: rawptr,
		userdata2: rawptr,
	) {
		result := cast(^RequestAdapterResult)userdata1

		result.status = status
		result.message = message
		result.adapter = nil

		if status == .Success {
			result.adapter = adapter
		}
	}

	callback_info := wgpu.RequestAdapterCallbackInfo {
		callback  = request_adapter_callback,
		userdata1 = &res,
	}

	if opt, opt_ok := options.?; opt_ok {
		raw_options := wgpu.RequestAdapterOptions {
			featureLevel         = opt.featureLevel,
			powerPreference      = opt.powerPreference,
			forceFallbackAdapter = b32(opt.forceFallbackAdapter),
			backendType          = opt.backend,
			compatibleSurface    = opt.compatibleSurface,
		}

		wgpu.InstanceRequestAdapter(self, &raw_options, callback_info)
	} else {
		wgpu.InstanceRequestAdapter(self, nil, callback_info)
	}

	return
}

/*
Retrieves all available `Adapter`s that match the given `Backends`.

**Inputs**

- `backends` - Backends from which to enumerate adapters.
*/
@(require_results)
InstanceEnumerateAdapters :: proc(
	self: Instance,
	backends: Backends = BACKENDS_ALL,
	allocator := context.allocator,
) -> (
	adapters: []Adapter,
) {
	options := wgpu.InstanceEnumerateAdapterOptions {
		backends = backends,
	}
	adapters = wgpu.InstanceEnumerateAdapters(self, &options, allocator)
	return
}

RegistryReport :: wgpu.RegistryReport

HubReport :: wgpu.HubReport

GlobalReport :: wgpu.GlobalReport

/* Generates memory report. */
GenerateReport :: wgpu.GenerateReport

/* Print memory report. */
PrintReport :: proc(self: Instance) {
	report := GenerateReport(self)

	print_registry_report :: proc(report: RegistryReport, prefix: cstring, separator := true) {
		fmt.printf("\t%snumAllocated = %d\n", prefix, report.numAllocated)
		fmt.printf("\t%snumKeptFromUser = %d\n", prefix, report.numKeptFromUser)
		fmt.printf("\t%snumReleasedFromUser = %d\n", prefix, report.numReleasedFromUser)
		fmt.printf("\t%selementSize = %d\n", prefix, report.elementSize)
		if separator {
			fmt.printf("\t----------\n")
		}
	}

	print_hub_report :: proc(report: HubReport, prefix: cstring) {
		if len(prefix) > 0 {
			fmt.printf("  %s:\n", prefix)
		}
		print_registry_report(report.adapters, "adapters.")
		print_registry_report(report.devices, "devices.")
		print_registry_report(report.pipelineLayouts, "pipelineLayouts.")
		print_registry_report(report.shaderModules, "shaderModules.")
		print_registry_report(report.bindGroupLayouts, "bindGroupLayouts.")
		print_registry_report(report.bindGroups, "bindGroups.")
		print_registry_report(report.commandBuffers, "commandBuffers.")
		print_registry_report(report.renderBundles, "renderBundles.")
		print_registry_report(report.renderPipelines, "renderPipelines.")
		print_registry_report(report.computePipelines, "computePipelines.")
		print_registry_report(report.querySets, "querySets.")
		print_registry_report(report.textures, "textures.")
		print_registry_report(report.textureViews, "textureViews.")
		print_registry_report(report.samplers, "samplers.", false)
	}

	fmt.print("Global_Report {\n")

	fmt.print("  Surfaces:\n")
	print_registry_report(report.surfaces, "Surfaces:", false)

	fmt.print("  Overview:\n")
	print_hub_report(report.hub, "")

	fmt.print("}\n")
}

LeakInfo :: struct {
	name:             string,
	leakedCount:      uint,
	elementSize:      uint,
	totalLeakedBytes: uint,
}

LeakReport :: struct {
	leaks:              [18]LeakInfo,
	leakCount:          uint,
	totalLeakedObjects: uint,
	totalLeakedBytes:   uint,
	hasLeaks:           bool,
}

GenerateLeakReport :: proc(self: Instance) -> (leakReport: LeakReport) {
    report := GenerateReport(self)

    check_and_add_leak :: proc(self: ^LeakReport, name: string, registry: RegistryReport) {
		if registry.numAllocated != 0 && registry.numAllocated >= registry.numKeptFromUser {
			leaked := registry.numKeptFromUser
			totalBytes := leaked * registry.elementSize

			self.leaks[self.leakCount] = {
				name             = name,
				leakedCount      = leaked,
				elementSize      = registry.elementSize,
				totalLeakedBytes = totalBytes,
			}

			self.leakCount += 1
			self.totalLeakedObjects += leaked
			self.totalLeakedBytes += totalBytes
			self.hasLeaks = true
		}
	}

    // Check all resource types for leaks
    check_and_add_leak(&leakReport, "Surfaces", report.surfaces)
    check_and_add_leak(&leakReport, "Adapters", report.hub.adapters)
    check_and_add_leak(&leakReport, "Devices", report.hub.devices)
    check_and_add_leak(&leakReport, "Queues", report.hub.queues)
    check_and_add_leak(&leakReport, "Pipeline Layouts", report.hub.pipelineLayouts)
    check_and_add_leak(&leakReport, "Shader Modules", report.hub.shaderModules)
    check_and_add_leak(&leakReport, "Bind Group Layouts", report.hub.bindGroupLayouts)
    check_and_add_leak(&leakReport, "Bind Groups", report.hub.bindGroups)
    check_and_add_leak(&leakReport, "Command Buffers", report.hub.commandBuffers)
    check_and_add_leak(&leakReport, "Render Bundles", report.hub.renderBundles)
    check_and_add_leak(&leakReport, "Render Pipelines", report.hub.renderPipelines)
    check_and_add_leak(&leakReport, "Compute Pipelines", report.hub.computePipelines)
    check_and_add_leak(&leakReport, "Pipeline Caches", report.hub.pipelineCaches)
    check_and_add_leak(&leakReport, "Query Sets", report.hub.querySets)
    check_and_add_leak(&leakReport, "Buffers", report.hub.buffers)
    check_and_add_leak(&leakReport, "Textures", report.hub.textures)
    check_and_add_leak(&leakReport, "Texture Views", report.hub.textureViews)
    check_and_add_leak(&leakReport, "Samplers", report.hub.samplers)

    return
}

LeakReportPrint :: proc(self: LeakReport) {
    if !self.hasLeaks { return }

    fmt.println("WGPU Memory Leak Report:")
    fmt.println("===================")

    // Print individual leak details
	for i in 0 ..< self.leakCount {
        leak := self.leaks[i]
        fmt.printfln(
            "%s: %d leaked objects (size: %d bytes each, total: %d bytes)",
            leak.name,
            leak.leakedCount,
            leak.elementSize,
            leak.totalLeakedBytes,
        )
    }

    fmt.println("-------------------")
    fmt.printfln("Total leaked objects: %d", self.totalLeakedObjects)
    fmt.printfln("Total leaked memory: %d bytes", self.totalLeakedBytes)
    fmt.println("===================")
}

/*
Checks for memory leaks in various registries of the `Instance`.

It generates a memory leak report and prints it to the console.
*/
CheckForMemoryLeaks :: proc(self: Instance) {
    leakReport := GenerateLeakReport(self)
    LeakReportPrint(leakReport)
}
