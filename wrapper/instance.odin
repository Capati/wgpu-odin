package wgpu

// STD Library
@(require) import "base:runtime"
import "core:fmt"

// The raw bindings
import wgpu "../bindings"

/*
Context for all other wgpu objects. Instance of wgpu.

This is the first thing you create when using wgpu.
Its primary use is to create `Adapter`s and `Surface`s.

Does not have to be kept alive.

Corresponds to [WebGPU `GPU`](https://gpuweb.github.io/gpuweb/#gpu-interface).
*/
Instance :: wgpu.Instance

/* Options for creating an instance. */
Instance_Descriptor :: struct {
	backends             : Instance_Backend_Flags,
	flags                : Instance_Flags,
	dx12_shader_compiler : Dx12_Compiler,
	gles3_minor_version  : Gles3_Minor_Version,
}

/*
Create an new instance of wgpu.

**Panics**
- If no backend feature for the active target platform is enabled.
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
		instance_extras := Instance_Extras {
			stype                = cast(SType)Native_SType.Instance_Extras,
			backends             = desc.backends,
			flags                = desc.flags,
			gles3_minor_version  = desc.gles3_minor_version,
		}

		// Check the use for the Dxc/Fxc compiler on Windows (DX12 only)
		when ODIN_OS == .Windows {
			runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
			_set_dx12_compiler(&instance_extras, desc.dx12_shader_compiler, context.temp_allocator)
		}

		raw_desc: wgpu.Instance_Descriptor
		raw_desc.next_in_chain = &instance_extras.chain

		instance = wgpu.create_instance(&raw_desc)
	} else {
		instance = wgpu.create_instance(nil)
	}

	ok = instance != nil

	if !ok {
		error_reset_and_update(
			wgpu.Error_Type.Unknown,
			"Failed to acquire an instance, for more information check log callback with " +
			"'wgpu.set_log_callback'",
			loc,
		)
	}

	return
}

/* Describes a surface target. */
Surface_Descriptor :: struct {
	label:  cstring,
	target: union {
		Surface_Descriptor_From_Android_Native_Window,
		Surface_Descriptor_From_Canvas_Html_Selector,
		Surface_Descriptor_From_Metal_Layer,
		Surface_Descriptor_From_Wayland_Surface,
		Surface_Descriptor_From_Windows_HWND,
		Surface_Descriptor_From_Xcb_Window,
		Surface_Descriptor_From_Xlib_Window,
	},
}

/*
Creates a surface from a window target.

If the specified display and window target are not supported by any of the backends, then the
surface will not be supported by any adapters.
*/
@(require_results)
instance_create_surface :: proc(
	self: Instance,
	descriptor: Surface_Descriptor,
	loc := #caller_location,
) -> (
	surface: Surface,
	ok: bool,
) #optional_ok {
	desc: wgpu.Surface_Descriptor
	desc.label = descriptor.label

	switch &t in descriptor.target {
	case Surface_Descriptor_From_Windows_HWND:
		if desc.label == nil || desc.label == "" {
			desc.label = "Windows HWND"
		}
		t.chain.stype = .Surface_Descriptor_From_Windows_HWND
		desc.next_in_chain = &t.chain
	case Surface_Descriptor_From_Xcb_Window:
		if desc.label == nil || desc.label == "" {
			desc.label = "XCB Window"
		}
		t.chain.stype = .Surface_Descriptor_From_Xcb_Window
		desc.next_in_chain = &t.chain
	case Surface_Descriptor_From_Xlib_Window:
		if desc.label == nil || desc.label == "" {
			desc.label = "X11 Window"
		}
		t.chain.stype = .Surface_Descriptor_From_Xlib_Window
		desc.next_in_chain = &t.chain
	case Surface_Descriptor_From_Metal_Layer:
		if desc.label == nil || desc.label == "" {
			desc.label = "Metal Layer"
		}
		t.chain.stype = .Surface_Descriptor_From_Metal_Layer
		desc.next_in_chain = &t.chain
	case Surface_Descriptor_From_Wayland_Surface:
		if desc.label == nil || desc.label == "" {
			desc.label = "Wayland Surface"
		}
		t.chain.stype = .Surface_Descriptor_From_Wayland_Surface
		desc.next_in_chain = &t.chain
	case Surface_Descriptor_From_Android_Native_Window:
		if desc.label == nil || desc.label == "" {
			desc.label = "Android Native Window"
		}
		t.chain.stype = .Surface_Descriptor_From_Android_Native_Window
		desc.next_in_chain = &t.chain
	case Surface_Descriptor_From_Canvas_Html_Selector:
		if desc.label == nil || desc.label == "" {
			desc.label = "Canvas Html Selector"
		}
		t.chain.stype = .Surface_Descriptor_From_Canvas_Html_Selector
		desc.next_in_chain = &t.chain
	}

	surface = wgpu.instance_create_surface(self, &desc)

	ok = surface != nil

	if !ok {
		error_reset_and_update(
			wgpu.Error_Type.Unknown,
			"Failed to create surface, for more information check log callback with " +
			"'wgpu.set_log_callback'",
			loc,
		)
	}

	return
}

/*
Power Preference when choosing a physical adapter.

Corresponds to [WebGPU `GPUPowerPreference`](
https://gpuweb.github.io/gpuweb/#enumdef-gpupowerpreference).
*/
Power_Preference :: wgpu.Power_Preference

/*
Additional information required when requesting an adapter.

For use with `instance_request_adapter`.

Corresponds to [WebGPU `GPURequestAdapterOptions`](
https://gpuweb.github.io/gpuweb/#dictdef-gpurequestadapteroptions).
*/
Request_Adapter_Options :: struct {
	compatible_surface     : Surface,
	power_preference       : Power_Preference,
	backend_type           : Backend_Type,
	force_fallback_adapter : bool,
}

/*
Retrieves an `Adapter` which matches the given `Request_Adapter_Options`.

Some options are "soft", so treated as non-mandatory. Others are "hard". If no adapters are found
that suffice all the "hard" options, `nil` is returned.

A `compatible_surface` is required when targeting WebGL2.
*/
@(require_results)
instance_request_adapter :: proc(
	self: Instance,
	options: Request_Adapter_Options,
	loc := #caller_location,
) -> (
	adapter: Adapter,
	ok: bool,
) #optional_ok {
	res: Adapter_Response

	opts := wgpu.Request_Adapter_Options {
		compatible_surface     = options.compatible_surface,
		power_preference       = options.power_preference,
		backend_type           = options.backend_type,
		force_fallback_adapter = b32(options.force_fallback_adapter),
	}

	wgpu.instance_request_adapter(self, &opts, request_adapter_callback, &res)

	if res.status != .Success {
		error_reset_and_update(res.status, string(res.message), loc)
		return
	}

	return res.adapter, true
}

Adapter_Response :: struct {
	status  : Request_Adapter_Status,
	message : cstring,
	adapter : Adapter,
}

request_adapter_callback :: proc "c" (
	status: Request_Adapter_Status,
	adapter: Adapter,
	message: cstring,
	user_data: rawptr,
) {
	response := cast(^Adapter_Response)user_data

	response.status = status
	response.message = message

	if status == .Success {
		response.adapter = adapter
	}
}

/* Retrieves all available `Adapter`s that match the given `Instance_Backend_Flags`. */
@(require_results)
instance_enumerate_adapters :: proc(
	self: Instance,
	backends: Instance_Backend_Flags,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	adapters: []Adapter,
	ok: bool,
) #optional_ok {
	options := Instance_Enumerate_Adapter_Options {
		backends = backends,
	}

	count := wgpu.instance_enumerate_adapters(self, &options, nil)
	if count == 0 {
		error_reset_and_update(.Unavailable, "No adapters found", loc)
		return
	}

	alloc_err: runtime.Allocator_Error
	if adapters, alloc_err = make([]Adapter, count, allocator); alloc_err != nil {
		error_reset_and_update(alloc_err, "Failed to allocate adapters", loc)
		return
	}

	wgpu.instance_enumerate_adapters(self, &options, raw_data(adapters))

	return adapters, true
}

/* Generates memory report. */
instance_generate_report :: proc "contextless" (self: Instance) -> Global_Report {
	report: Global_Report
	wgpu.generate_report(self, &report)
	return report
}

/* Processes pending WebGPU events on the instance. */
instance_process_events :: wgpu.instance_process_events

/*
Print memory report.

**Inputs**
- `self` - The `Instance` to query.
- `backend_type` - Which backend to retrieve information, leave `Undefined` to get from the report.
*/
instance_print_report :: proc(self: Instance, backend_type: Backend_Type = .Undefined) {
	report := instance_generate_report(self)

	print_registry_report :: proc(report: Registry_Report, prefix: cstring, separator := true) {
		fmt.printf("\t%snum_allocated = %d\n", prefix, report.num_allocated)
		fmt.printf("\t%snum_kept_from_user = %d\n", prefix, report.num_kept_from_user)
		fmt.printf("\t%snum_released_from_user = %d\n", prefix, report.num_released_from_user)
		fmt.printf("\t%snum_error = %d\n", prefix, report.num_error)
		fmt.printf("\t%selement_size = %d\n", prefix, report.element_size)
		if separator do fmt.printf("\t----------\n")
	}

	print_hub_report :: proc(report: Hub_Report, prefix: cstring) {
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

	fmt.print("Global_Report {\n")

	fmt.print("  Surfaces:\n")
	print_registry_report(report.surfaces, "Surfaces:", false)

	backend_type := backend_type if backend_type != .Undefined else report.backend_type

	#partial switch backend_type {
	case .D3D12:
		print_hub_report(report.dx12, "D3D12")
	case .Metal:
		print_hub_report(report.metal, "Metal")
	case .Vulkan:
		print_hub_report(report.vulkan, "Vulkan")
	case .OpenGL:
		print_hub_report(report.gl, "OpenGL")
	case:
		fmt.printf("%s - Invalid backend type: %v", #procedure, backend_type)
	}

	fmt.print("}\n")
}

/* Increase the reference count. */
instance_reference :: wgpu.instance_reference

/* Release the `Instance` resources. */
instance_release :: wgpu.instance_release
