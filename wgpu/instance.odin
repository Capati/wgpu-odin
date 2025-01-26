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
Create an new instance of wgpu.

**Panics**

If no backend feature for the active target platform is enabled, this procedure will panic.
*/
@(require_results)
create_instance :: proc(
	descriptor: Maybe(Instance_Descriptor) = nil,
	loc := #caller_location,
) -> (
	instance: Instance,
	ok: bool,
) #optional_ok {
	if desc, desc_ok := descriptor.?; desc_ok {
		instance_extras := WGPU_Instance_Extras {
			chain = {stype = .Instance_Extras},
			backends = desc.backends,
			flags = desc.flags,
			gles3_minor_version = desc.gles3_minor_version,
		}

		c_dxil_path: String_View_Buffer
		if desc.dxil_path != "" {
			instance_extras.dxil_path = init_string_buffer(&c_dxil_path, desc.dxil_path)
		}

		c_dxc_path: String_View_Buffer
		if desc.dxc_path != "" {
			instance_extras.dxc_path = init_string_buffer(&c_dxc_path, desc.dxc_path)
		}

		raw_desc: WGPU_Instance_Descriptor
		raw_desc.features = desc.features
		raw_desc.next_in_chain = &instance_extras.chain

		instance = wgpuCreateInstance(&raw_desc)
	} else {
		instance = wgpuCreateInstance(nil)
	}

	ok = instance != nil

	if !ok {
		error_reset_and_update(
			Error_Type.Unknown,
			"Failed to acquire an instance, for more information check log callback with " +
			"'wgpu.set_log_callback'",
			loc,
		)
	}

	return
}

@(private)
WGPU_Instance_Enumerate_Adapter_Options :: struct {
	next_in_chain: ^Chained_Struct,
	backends:      Backends,
}

/*
Retrieves all available `Adapter`s that match the given `Backends`.

**Inputs**

- `backends` - Backends from which to enumerate adapters.
*/
@(require_results)
instance_enumerate_adapters :: proc(
	self: Instance,
	backends: Backends = BACKENDS_ALL,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	adapters: []Adapter,
	ok: bool,
) #optional_ok {
	options := WGPU_Instance_Enumerate_Adapter_Options {
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

/*
Retrieves an `Adapter` which matches the given `Request_Adapter_Options`.

Some options are "soft", so treated as non-mandatory. Others are "hard".

If no adapters are found that suffice all the "hard" options, `nil` is returned.

A `compatible_surface` is required when targeting WebGL2.
*/
@(require_results)
instance_request_adapter :: proc(
	self: Instance,
	options: Maybe(Request_Adapter_Options) = nil,
	loc := #caller_location,
) -> (
	adapter: Adapter,
	ok: bool,
) #optional_ok {
	AdapterResponse :: struct {
		status:  Request_Adapter_Status,
		message: String_View,
		adapter: Adapter,
	}

	request_adapter_callback :: proc "c" (
		status: Request_Adapter_Status,
		adapter: Adapter,
		message: String_View,
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

	res: AdapterResponse
	callback_info := Request_Adapter_Callback_Info {
		callback  = request_adapter_callback,
		userdata1 = &res,
	}

	if opt, opt_ok := options.?; opt_ok {
		raw_options := WGPU_Request_Adapter_Options {
			feature_level          = opt.feature_level,
			power_preference       = opt.power_preference,
			force_fallback_adapter = b32(opt.force_fallback_adapter),
			backend                = opt.backend,
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

/* Creates a surface from a window target. */
@(require_results)
instance_create_surface :: proc(
	self: Instance,
	descriptor: Surface_Descriptor,
	loc := #caller_location,
) -> (
	surface: Surface,
	ok: bool,
) #optional_ok {
	raw_desc: WGPU_Surface_Descriptor

	when ODIN_DEBUG {
		c_label: String_View_Buffer
		if descriptor.label != "" {
			raw_desc.label = init_string_buffer(&c_label, descriptor.label)
		}
	}

	switch &t in descriptor.target {
	case Surface_Source_Windows_HWND:
		t.chain.stype = .Surface_Source_Windows_HWND
		raw_desc.next_in_chain = &t.chain
	case Surface_Source_XCB_Window:
		t.chain.stype = .Surface_Source_XCB_Window
		raw_desc.next_in_chain = &t.chain
	case Surface_Source_Xlib_Window:
		t.chain.stype = .Surface_Source_Xlib_Window
		raw_desc.next_in_chain = &t.chain
	case Surface_Source_Metal_Layer:
		t.chain.stype = .Surface_Source_Metal_Layer
		raw_desc.next_in_chain = &t.chain
	case Surface_Source_Wayland_Surface:
		t.chain.stype = .Surface_Source_Wayland_Surface
		raw_desc.next_in_chain = &t.chain
	case Surface_Source_Android_Native_Window:
		t.chain.stype = .Surface_Source_Android_Native_Window
		raw_desc.next_in_chain = &t.chain
	}

	surface = wgpuInstanceCreateSurface(self, raw_desc)

	ok = surface != nil

	if !ok {
		error_reset_and_update(
			Error_Type.Unknown,
			"Failed to create surface, for more information check log callback with " +
			"'wgpu.set_log_callback'",
			loc,
		)
	}

	return
}

/* Processes pending WebGPU events on the instance. */
instance_process_events :: wgpuInstanceProcessEvents

Registry_Report :: struct {
	num_allocated:          uint,
	num_kept_from_user:     uint,
	num_released_from_user: uint,
	element_size:           uint,
}

Hub_Report :: struct {
	adapters:           Registry_Report,
	devices:            Registry_Report,
	queues:             Registry_Report,
	pipeline_layouts:   Registry_Report,
	shader_modules:     Registry_Report,
	bind_group_layouts: Registry_Report,
	bind_groups:        Registry_Report,
	command_buffers:    Registry_Report,
	render_bundles:     Registry_Report,
	render_pipelines:   Registry_Report,
	compute_pipelines:  Registry_Report,
	pipeline_caches:    Registry_Report,
	query_sets:         Registry_Report,
	buffers:            Registry_Report,
	textures:           Registry_Report,
	texture_views:      Registry_Report,
	samplers:           Registry_Report,
}

Global_Report :: struct {
	surfaces: Registry_Report,
	hub:      Hub_Report,
}

/* Generates memory report. */
generate_report :: proc "contextless" (self: Instance) -> (report: Global_Report) {
	wgpuGenerateReport(self, &report)
	return
}

/* Print memory report. */
print_report :: proc(self: Instance) {
	report := generate_report(self)

	print_registry_report :: proc(report: Registry_Report, prefix: cstring, separator := true) {
		fmt.printf("\t%snum_allocated = %d\n", prefix, report.num_allocated)
		fmt.printf("\t%snum_kept_from_user = %d\n", prefix, report.num_kept_from_user)
		fmt.printf("\t%snum_released_from_user = %d\n", prefix, report.num_released_from_user)
		fmt.printf("\t%selement_size = %d\n", prefix, report.element_size)
		if separator {
			fmt.printf("\t----------\n")
		}
	}

	print_hub_report :: proc(report: Hub_Report, prefix: cstring) {
		if len(prefix) > 0 {
			fmt.printf("  %s:\n", prefix)
		}
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

	fmt.print("Global_Report {\n")

	fmt.print("  Surfaces:\n")
	print_registry_report(report.surfaces, "Surfaces:", false)

	fmt.print("  Overview:\n")
	print_hub_report(report.hub, "")

	fmt.print("}\n")
}

/*
Checks for memory leaks in various registries of the `Instance`. It generates a memory leak report
and prints it to the console.
*/
check_for_memory_leaks :: proc(self: Instance) {
	fmt.println("WGPU Memory Leak Report:")
	fmt.println("===================")

	// Helper function to check for leaks in a registry
	check_registry_leaks :: proc(
		name: string,
		registry: Registry_Report,
	) -> (
		leaks_detected: bool,
	) {
		// Safely check for leaks without underflow
		if registry.num_allocated > registry.num_released_from_user {
			leaked := registry.num_allocated - registry.num_released_from_user
			fmt.printf(
				"%s: %d leaked objects (size: %d bytes each)\n",
				name,
				leaked,
				registry.element_size,
			)
			leaks_detected = true
		}
		return
	}

	report := generate_report(self)

	// Check for leaks in surfaces
	leaks_detected := check_registry_leaks("Surfaces", report.surfaces)

	// Check for leaks in hub components
	leaks_detected |= check_registry_leaks("Adapters", report.hub.adapters)
	leaks_detected |= check_registry_leaks("Devices", report.hub.devices)
	leaks_detected |= check_registry_leaks("Queues", report.hub.queues)
	leaks_detected |= check_registry_leaks("Pipeline Layouts", report.hub.pipeline_layouts)
	leaks_detected |= check_registry_leaks("Shader Modules", report.hub.shader_modules)
	leaks_detected |= check_registry_leaks("Bind Group Layouts", report.hub.bind_group_layouts)
	leaks_detected |= check_registry_leaks("Bind Groups", report.hub.bind_groups)
	leaks_detected |= check_registry_leaks("Command Buffers", report.hub.command_buffers)
	leaks_detected |= check_registry_leaks("Render Bundles", report.hub.render_bundles)
	leaks_detected |= check_registry_leaks("Render Pipelines", report.hub.render_pipelines)
	leaks_detected |= check_registry_leaks("Compute Pipelines", report.hub.compute_pipelines)
	leaks_detected |= check_registry_leaks("Pipeline Caches", report.hub.pipeline_caches)
	leaks_detected |= check_registry_leaks("Query Sets", report.hub.query_sets)
	leaks_detected |= check_registry_leaks("Buffers", report.hub.buffers)
	leaks_detected |= check_registry_leaks("Textures", report.hub.textures)
	leaks_detected |= check_registry_leaks("Texture Views", report.hub.texture_views)
	leaks_detected |= check_registry_leaks("Samplers", report.hub.samplers)

	if !leaks_detected {
		fmt.println("No leaks detected.")
	}

	fmt.println("===================")
}

/* Increase the reference count. */
instance_add_ref :: wgpuInstanceAddRef

/* Release the `Instance` resources. */
instance_release :: wgpuInstanceRelease

/*
Safely releases the `Instance` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
instance_release_safe :: #force_inline proc(self: ^Instance) {
	if self != nil && self^ != nil {
		wgpuInstanceRelease(self^)
		self^ = nil
	}
}

@(private)
WGPU_Instance_Extras :: struct {
	chain:                Chained_Struct,
	backends:             Backends,
	flags:                Instance_Flags,
	dx12_shader_compiler: Dx12_Compiler,
	gles3_minor_version:  Gles3_Minor_Version,
	dxil_path:            String_View,
	dxc_path:             String_View,
}

@(private)
WGPU_Instance_Descriptor :: struct {
	next_in_chain: ^Chained_Struct,
	features:      Instance_Capabilities,
}
