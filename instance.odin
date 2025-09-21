package webgpu

// Core
import "core:fmt"

// Vendor
import "vendor:wgpu"

/*
Context for all other wgpu objects. Instance of wgpu.

This is the first thing you create when using wgpu.
Its primary use is to create `Adapter`s and `Surface`s.

Does not have to be kept alive.

Corresponds to [WebGPU `GPU`](https://gpuweb.github.io/gpuweb/#gpu-interface).
*/
Instance :: wgpu.Instance

/* Represents a backend that wgpu can use. */
InstanceBackend :: wgpu.InstanceBackend

/* Represents the backends that wgpu will use. */
Backends :: wgpu.InstanceBackendFlags

/* Use all supported backends. */
BACKENDS_ALL :: wgpu.InstanceBackendFlags_All

/* Use only the primary backends that has better support. */
BACKENDS_PRIMARY :: wgpu.InstanceBackendFlags_Primary

/* Use only the secondary backends that has less support. */
BACKENDS_SECONDARY :: wgpu.InstanceBackendFlags_Secondary

/*
Instance debugging flags.

These are not part of the WebGPU standard.
*/
InstanceFlags :: wgpu.InstanceFlags

/* Use no flags. */
INSTANCE_FLAGS_DEFAULT :: InstanceFlags{}

/* Enable recommended debugging and validation flags. */
INSTANCE_FLAGS_DEBUGGING :: InstanceFlags{ .Debug, .Validation }

/* Features enabled on the Instance. */
InstanceCapabilities :: wgpu.InstanceCapabilities

/*
Selects which DX12 shader compiler to fuse.

If the `Dxc` option is selected, but `dxcompiler.dll` and `dxil.dll` files
aren't found, then this will fall back to the Fxc compiler at runtime and log an error.

Options:

- Fxc: Use the legacy FXC (D3DCompiler) shader compiler
- Dxc: Use the modern DXC (DirectXShaderCompiler) for better optimization and
  newer shader models
*/
Dx12Compiler :: wgpu.Dx12Compiler

/*
Specifies the minor version of OpenGL ES 3.x to target. This affects which
OpenGL ES features are available and how shaders are compiled.

Options:

- Automatic: Let WGPU automatically select the best available version
- Version0: Target OpenGL ES 3.0 (minimum required version)
- Version1: Target OpenGL ES 3.1 (adds compute shaders, additional texture formats)
- Version2: Target OpenGL ES 3.2 (adds geometry shaders, tessellation,
  additional features)
*/
Gles3MinorVersion :: wgpu.Gles3MinorVersion

/*
Controls how OpenGL fences are handled for synchronization.

Options:

- Normal: Use standard OpenGL fence behavior
- AutoFinish: Automatically call `glFinish()` to ensure GPU operations complete
*/
GLFenceBehaviour :: wgpu.GLFenceBehaviour

/*
Specifies the maximum DirectX Shader Model version to use with the DXC compiler.
Higher shader models support more advanced features but require newer hardware.

Options:

- V6_0: Shader Model 6.0 (adds wave intrinsics)
- V6_1: Shader Model 6.1 (adds SV_ViewID for VR)
- V6_2: Shader Model 6.2 (adds 16-bit types)
- V6_3: Shader Model 6.3 (adds DXR raytracing)
- V6_4: Shader Model 6.4 (adds integer dot product)
- V6_5: Shader Model 6.5 (adds DXR 1.1, mesh shaders)
- V6_6: Shader Model 6.6 (adds compute shader derivatives)
- V6_7: Shader Model 6.7 (adds advanced texture ops)
*/
DxcMaxShaderModel :: wgpu.DxcMaxShaderModel

/* Options for creating an instance. */
InstanceDescriptor :: struct {
	/* WebGPU */
	features: InstanceCapabilities,

	/* WGPU Native */
	backends: Backends,
	flags:    InstanceFlags,
	dx12: struct {
		shaderCompiler:    Dx12Compiler,
		dxilPath:          string,
		dxcPath:           string,
		dcxMaxShaderModel: DxcMaxShaderModel,
	},
	gl: struct {
		gles3MinorVersion: Gles3MinorVersion,
		fenceBehaviour:    GLFenceBehaviour,
	},
}

INSTANCE_DESCRIPTOR_DEFAULT :: InstanceDescriptor {
	backends = BACKENDS_PRIMARY,
	flags    = INSTANCE_FLAGS_DEFAULT,
}

/*
Create an new instance of wgpu.

**Panics**

If no backend feature for the active target platform is enabled, this procedure will panic.
*/
@(require_results)
CreateInstance :: proc "c" (descriptor: Maybe(InstanceDescriptor) = nil) -> (instance: Instance) {
	if desc, desc_ok := descriptor.?; desc_ok {
		raw_desc: wgpu.InstanceDescriptor
		raw_desc.features = desc.features

		when ODIN_OS != .JS {
			instance_extras := wgpu.InstanceExtras {
				chain               = { sType = .InstanceExtras },
				backends            = desc.backends,
				flags               = desc.flags,
				dx12ShaderCompiler  = desc.dx12.shaderCompiler,
				gles3MinorVersion   = desc.gl.gles3MinorVersion,
				glFenceBehaviour    = desc.gl.fenceBehaviour,
				dxilPath            = desc.dx12.dxilPath,
				dxcPath             = desc.dx12.dxcPath,
				dcxMaxShaderModel   = desc.dx12.dcxMaxShaderModel,
			}

			raw_desc.nextInChain = &instance_extras.chain
		}

		instance = wgpu.CreateInstance(&raw_desc)
	} else {
		instance = wgpu.CreateInstance(nil)
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

FeatureLevel :: wgpu.FeatureLevel

/*
Power Preference when choosing a physical adapter.

Corresponds to [WebGPU `GPUPowerPreference`](
https://gpuweb.github.io/gpuweb/#enumdef-gpupowerpreference).
*/
PowerPreference :: wgpu.PowerPreference

/* Use `HighPerformance`. */
POWER_PREFERENCE_DEFAULT: PowerPreference = .HighPerformance

/*
Options for requesting adapter.

Corresponds to [WebGPU `GPURequestAdapterOptions`](
https://gpuweb.github.io/gpuweb/#dictdef-gpurequestadapteroptions).
 */
RequestAdapterOptions :: struct {
	featureLevel:         FeatureLevel,
	compatibleSurface:    Surface,
	powerPreference:      PowerPreference,
	backend:              Backend,
	forceFallbackAdapter: bool,
}

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
InstanceRequestAdapter :: proc "c" (
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

SurfaceSourceAndroidNativeWindow :: wgpu.SurfaceSourceAndroidNativeWindow
SurfaceSourceCanvasHTMLSelector  :: wgpu.SurfaceSourceCanvasHTMLSelector
SurfaceSourceMetalLayer          :: wgpu.SurfaceSourceMetalLayer
SurfaceSourceWaylandSurface      :: wgpu.SurfaceSourceWaylandSurface
SurfaceSourceWindowsHWND         :: wgpu.SurfaceSourceWindowsHWND
SurfaceSourceXcbWindow           :: wgpu.SurfaceSourceXcbWindow
SurfaceSourceXlibWindow          :: wgpu.SurfaceSourceXlibWindow
// SurfaceSourceSwapChainPanel      :: wgpu.SurfaceSourceSwapChainPanel

/* Describes a surface target. */
SurfaceDescriptor :: struct {
	label:  string,
	target: union {
		SurfaceSourceAndroidNativeWindow,
		SurfaceSourceCanvasHTMLSelector,
		SurfaceSourceMetalLayer,
		SurfaceSourceWaylandSurface,
		SurfaceSourceWindowsHWND,
		SurfaceSourceXcbWindow,
		SurfaceSourceXlibWindow,
		// SurfaceSourceSwapChainPanel,
	},
}

/* Creates a surface from a window target. */
@(require_results)
InstanceCreateSurface :: proc "c" (
	self: Instance,
	descriptor: SurfaceDescriptor,
) -> (
	surface: Surface,
) {
	raw_desc: wgpu.SurfaceDescriptor
	raw_desc.label = descriptor.label

	switch &t in descriptor.target {
	case SurfaceSourceAndroidNativeWindow:
		t.chain.sType = .SurfaceSourceAndroidNativeWindow
		raw_desc.nextInChain = &t.chain

	case SurfaceSourceCanvasHTMLSelector:
		t.chain.sType = .SurfaceSourceCanvasHTMLSelector
		raw_desc.nextInChain = &t.chain

	case SurfaceSourceMetalLayer:
		t.chain.sType = .SurfaceSourceMetalLayer
		raw_desc.nextInChain = &t.chain

	case SurfaceSourceWaylandSurface:
		t.chain.sType = .SurfaceSourceWaylandSurface
		raw_desc.nextInChain = &t.chain

	case SurfaceSourceWindowsHWND:
		t.chain.sType = .SurfaceSourceWindowsHWND
		raw_desc.nextInChain = &t.chain

	case SurfaceSourceXcbWindow:
		t.chain.sType = .SurfaceSourceXCBWindow
		raw_desc.nextInChain = &t.chain

	case SurfaceSourceXlibWindow:
		t.chain.sType = .SurfaceSourceXlibWindow
		raw_desc.nextInChain = &t.chain

	// case SurfaceSourceSwapChainPanel:
	// 	t.chain.sType = .SurfaceSourceSwapChainPanel
	// 	raw_desc.nextInChain = &t.chain
	}

	surface = wgpu.InstanceCreateSurface(self, &raw_desc)

	return
}

/* Processes pending WebGPU events on the instance. */
InstanceProcessEvents :: wgpu.InstanceProcessEvents

/* Increase the reference count. */
InstanceAddRef :: wgpu.InstanceAddRef

/* Release the `Instance` resources. */
InstanceRelease :: wgpu.InstanceRelease

/*
Safely releases the `Instance` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
InstanceReleaseSafe :: #force_inline proc "c" (self: ^Instance) {
	if self != nil && self^ != nil {
		wgpu.InstanceRelease(self^)
		self^ = nil
	}
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
