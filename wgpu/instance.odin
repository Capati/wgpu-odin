package wgpu

// Packages
import "base:runtime"
import "core:fmt"

/*
Context for all other wgpu objects. Instance of wgpu.

This is the first thing you create when using wgpu.
Its primary use is to create `Adapter`s and `Surface`s.

Does not have to be kept alive.

Corresponds to [WebGPU `GPU`](https://gpuweb.github.io/gpuweb/#gpu-interface).
*/
Instance :: distinct rawptr

/*
Options for creating an instance.
*/
InstanceDescriptor :: struct {
	backends:             InstanceBackend,
	flags:                InstanceFlag,
	dx12_shader_compiler: Dx12Compiler,
	gles3_minor_version:  Gles3MinorVersion,
	features:             InstanceCapabilities,
	dxil_path:            string,
	dxc_path:             string,
}

DEFAULT_INSTANCE_DESCRIPTOR :: InstanceDescriptor {
	backends = INSTANCE_BACKEND_PRIMARY,
}

// Create an new instance of wgpu.
@(require_results)
create_instance :: proc(
	descriptor: Maybe(InstanceDescriptor) = nil,
	loc := #caller_location,
) -> (
	instance: Instance,
	ok: bool,
) #optional_ok {
	if desc, desc_ok := descriptor.?; desc_ok {
		instance_extras := InstanceExtras {
			chain = {stype = .InstanceExtras},
			backends = desc.backends,
			flags = desc.flags,
			gles3_minor_version = desc.gles3_minor_version,
		}

		when ODIN_DEBUG {
			c_dxil_path: StringViewBuffer
			if desc.dxil_path != "" {
				instance_extras.dxil_path = init_string_buffer(&c_dxil_path, desc.dxil_path)
			}

			c_dxc_path: StringViewBuffer
			if desc.dxc_path != "" {
				instance_extras.dxc_path = init_string_buffer(&c_dxc_path, desc.dxc_path)
			}
		}

		raw_desc: WGPUInstanceDescriptor
		raw_desc.features = desc.features
		raw_desc.next_in_chain = &instance_extras.chain

		instance = wgpuCreateInstance(&raw_desc)
	} else {
		instance = wgpuCreateInstance(nil)
	}

	ok = instance != nil

	if !ok {
		error_reset_and_update(
			ErrorType.Unknown,
			"Failed to acquire an instance, for more information check log callback with " +
			"'wgpu.set_log_callback'",
			loc,
		)
	}

	return
}

// Describes a surface target.
SurfaceDescriptor :: struct {
	label:  string,
	target: union {
		SurfaceSourceAndroidNativeWindow,
		SurfaceSourceMetalLayer,
		SurfaceSourceWaylandSurface,
		SurfaceSourceWindowsHWND,
		SurfaceSourceXCBWindow,
		SurfaceSourceXlibWindow,
	},
}

// Creates a surface from a window target.
@(require_results)
instance_create_surface :: proc(
	self: Instance,
	descriptor: SurfaceDescriptor,
	loc := #caller_location,
) -> (
	surface: Surface,
	ok: bool,
) #optional_ok {
	raw_desc: WGPUSurfaceDescriptor

	when ODIN_DEBUG {
		c_label: StringViewBuffer
		if descriptor.label != "" {
			raw_desc.label = init_string_buffer(&c_label, descriptor.label)
		}
	}

	switch &t in descriptor.target {
	case SurfaceSourceWindowsHWND:
		t.chain.stype = .SurfaceSourceWindowsHWND
		raw_desc.next_in_chain = &t.chain
	case SurfaceSourceXCBWindow:
		t.chain.stype = .SurfaceSourceXCBWindow
		raw_desc.next_in_chain = &t.chain
	case SurfaceSourceXlibWindow:
		t.chain.stype = .SurfaceSourceXlibWindow
		raw_desc.next_in_chain = &t.chain
	case SurfaceSourceMetalLayer:
		t.chain.stype = .SurfaceSourceMetalLayer
		raw_desc.next_in_chain = &t.chain
	case SurfaceSourceWaylandSurface:
		t.chain.stype = .SurfaceSourceWaylandSurface
		raw_desc.next_in_chain = &t.chain
	case SurfaceSourceAndroidNativeWindow:
		t.chain.stype = .SurfaceSourceAndroidNativeWindow
		raw_desc.next_in_chain = &t.chain
	}

	surface = wgpuInstanceCreateSurface(self, raw_desc)

	ok = surface != nil

	if !ok {
		error_reset_and_update(
			ErrorType.Unknown,
			"Failed to create surface, for more information check log callback with " +
			"'wgpu.set_log_callback'",
			loc,
		)
	}

	return
}

// Additional information required when requesting an adapter.
RequestAdapterOptions :: struct {
	feature_level:          FeatureLevel,
	compatible_surface:     Surface,
	power_preference:       PowerPreference,
	backend_type:           BackendType,
	force_fallback_adapter: bool,
}

// HighPerformance.
DEFAULT_POWER_PREFERENCE: PowerPreference = .HighPerformance

// Retrieves an `Adapter` which matches the given `RequestAdapterOptions`.
@(require_results)
instance_request_adapter :: proc(
	self: Instance,
	options: Maybe(RequestAdapterOptions) = nil,
	loc := #caller_location,
) -> (
	adapter: Adapter,
	ok: bool,
) #optional_ok {
	res: AdapterResponse
	callback_info := RequestAdapterCallbackInfo {
		callback  = request_adapter_callback,
		userdata1 = &res,
	}

	if opt, opt_ok := options.?; opt_ok {
		raw_options := WGPURequestAdapterOptions {
			feature_level          = opt.feature_level,
			power_preference       = opt.power_preference,
			force_fallback_adapter = b32(opt.force_fallback_adapter),
			backend_type           = opt.backend_type,
			compatible_surface     = opt.compatible_surface,
		}

		wgpuInstanceRequestAdapter(self, &raw_options, callback_info)
	} else {
		wgpuInstanceRequestAdapter(self, nil, callback_info)
	}

	if res.status != .Success {
		error_reset_and_update(res.status, string(res.message.data), loc)
		return
	}

	return res.adapter, true
}

AdapterResponse :: struct {
	status:  RequestAdapterStatus,
	message: StringView,
	adapter: Adapter,
}

request_adapter_callback :: proc "c" (
	status: RequestAdapterStatus,
	adapter: Adapter,
	message: StringView,
	userdata1: rawptr,
	userdata2: rawptr,
) {
	response := cast(^AdapterResponse)userdata1

	response.status = status
	response.message = message

	if status == .Success {
		response.adapter = adapter
	}
}

// Retrieves all available `Adapter`s that match the given `InstanceBackend`.
@(require_results)
instance_enumerate_adapters :: proc(
	self: Instance,
	backends: InstanceBackend = INSTANCE_BACKEND_ALL,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	adapters: []Adapter,
	ok: bool,
) #optional_ok {
	options := InstanceEnumerateAdapterOptions {
		backends = backends,
	}

	count := wgpuInstanceEnumerateAdapters(self, &options, nil)
	if count == 0 {
		error_reset_and_update(.Unavailable, "No adapters found", loc)
		return
	}

	alloc_err: runtime.Allocator_Error
	if adapters, alloc_err = make([]Adapter, count, allocator); alloc_err != nil {
		error_reset_and_update(alloc_err, "Failed to allocate adapters", loc)
		return
	}

	wgpuInstanceEnumerateAdapters(self, &options, raw_data(adapters))

	return adapters, true
}

/* Generates memory report. */
instance_generate_report :: proc "contextless" (self: Instance) -> (report: GlobalReport) {
	wgpuGenerateReport(self, &report)
	return
}

// Processes pending WebGPU events on the instance.
instance_process_events :: wgpuInstanceProcessEvents

// Print memory report.
instance_print_report :: proc(self: Instance, backend_type: BackendType = .Undefined) {
	report := instance_generate_report(self)

	print_registry_report :: proc(report: RegistryReport, prefix: cstring, separator := true) {
		fmt.printf("\t%snum_allocated = %d\n", prefix, report.num_allocated)
		fmt.printf("\t%snum_kept_from_user = %d\n", prefix, report.num_kept_from_user)
		fmt.printf("\t%snum_released_from_user = %d\n", prefix, report.num_released_from_user)
		fmt.printf("\t%selement_size = %d\n", prefix, report.element_size)
		if separator {
			fmt.printf("\t----------\n")
		}
	}

	print_hub_report :: proc(report: HubReport, prefix: cstring) {
		fmt.printf("  %s:\n", prefix)
		print_registry_report(report.adapters, "adapters.")
		print_registry_report(report.devices, "devices.")
		print_registry_report(report.pipeline_layouts, "pipeline_layouts.")
		print_registry_report(report.shader_modules, "shader_modules.")
		print_registry_report(report.bind_group_layouts, "bind_group_layouts.")
		print_registry_report(report.bind_groups, "bind_groups.")
		print_registry_report(report.command_buffers, "command_buffers.")
		print_registry_report(report.render_bundles, "render_bundles.")
		print_registry_report(report.render_pipelines, "render_pipelines.")
		print_registry_report(report.compute_pipelines, "compute_pipelines.")
		print_registry_report(report.query_sets, "query_sets.")
		print_registry_report(report.textures, "textures.")
		print_registry_report(report.texture_views, "texture_views.")
		print_registry_report(report.samplers, "samplers.", false)
	}

	fmt.print("GlobalReport {\n")

	fmt.print("  Surfaces:\n")
	print_registry_report(report.surfaces, "Surfaces:", false)

	fmt.print("  Overview:\n")
	print_hub_report(report.hub, "")

	fmt.print("}\n")
}

// Increase the reference count.
instance_add_ref :: wgpuInstanceAddRef

// Release the `Instance` resources.
instance_release :: wgpuInstanceRelease
