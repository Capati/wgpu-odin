package wgpu

// Core
import "base:runtime"
import "core:fmt"
import "core:mem"

// Package
import wgpu "../bindings"

// Context for all other wgpu objects.
//
// This is the first thing you create when using wgpu. Its primary use is to create `Adapter`s and
// `Surface`s.
//
// Does not have to be kept alive.
Instance :: struct {
	ptr:  Raw_Instance,
	_pad: POINTER_PROMOTION_PADDING,
}

// Options for creating an instance.
Instance_Descriptor :: struct {
	backends:             Instance_Backend_Flags,
	flags:                Instance_Flags,
	dx12_shader_compiler: Dx12_Compiler,
	gles3_minor_version:  Gles3_Minor_Version,
	dxil_path:            cstring,
	dxc_path:             cstring,
}

// Create an new instance of wgpu.
@(require_results)
create_instance :: proc(
	descriptor: Instance_Descriptor = {},
	loc := #caller_location,
) -> (
	instance: Instance,
	err: Error,
) {
	if descriptor == {} {
		instance.ptr = wgpu.create_instance(nil)
	} else {
		instance_extras := Instance_Extras {
			chain = {next = nil, stype = cast(SType)Native_SType.Instance_Extras},
			backends = descriptor.backends,
			flags = descriptor.flags,
			dx12_shader_compiler = descriptor.dx12_shader_compiler,
			gles3_minor_version = descriptor.gles3_minor_version,
			dxil_path = descriptor.dxil_path,
			dxc_path = descriptor.dxc_path,
		}

		desc: wgpu.Instance_Descriptor
		desc.next_in_chain = &instance_extras.chain

		instance.ptr = wgpu.create_instance(&desc)
	}

	if instance.ptr == nil {
		err = wgpu.Error_Type.Unknown
		set_and_update_err_data(
			nil,
			.Create_Instance,
			err,
			"Failed to acquire an instance, for more information check log callback with 'wgpu.set_log_callback'",
			loc,
		)
	}

	return
}

// Describes a surface target.
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

// Creates a surface from a window target.
//
// If the specified display and window target are not supported by any of the backends, then the
// surface will not be supported by any adapters.
@(require_results)
instance_create_surface :: proc(
	using self: Instance,
	descriptor: Surface_Descriptor,
	loc := #caller_location,
) -> (
	surface: Surface,
	err: Error,
) {
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

	surface.ptr = wgpu.instance_create_surface(ptr, &desc)

	if surface.ptr == nil {
		err = wgpu.Error_Type.Unknown
		set_and_update_err_data(
			nil,
			.Create_Surface,
			err,
			"Failed to create surface, for more information check log callback with 'wgpu.set_log_callback'",
			loc,
		)
	}

	return
}

// Retrieves an `Adapter` which matches the given options.
@(require_results)
instance_request_adapter :: proc(
	using self: Instance,
	options: Request_Adapter_Options,
	loc := #caller_location,
) -> (
	adapter: Adapter,
	err: Error,
) {
	Adapter_Response :: struct {
		status:  Request_Adapter_Status,
		message: cstring,
		adapter: Raw_Adapter,
	}

	res: Adapter_Response

	request_adapter_callback :: proc "c" (
		status: Request_Adapter_Status,
		adapter: Raw_Adapter,
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

	options := options
	wgpu.instance_request_adapter(ptr, &options, request_adapter_callback, &res)

	if res.status != .Success {
		err = res.status
		set_and_update_err_data(nil, .Request_Adapter, err, string(res.message), loc)
		return
	}

	adapter.ptr = res.adapter
	defer if err != nil do wgpu.adapter_release(adapter.ptr)

	// Fill adapter details
	adapter.features = _adapter_get_features(adapter, loc) or_return
	adapter.limits = _adapter_get_limits(adapter, loc) or_return
	adapter.info = _adapter_get_info(adapter) or_return

	return
}

// Retrieves all available `Adapters` that match the given options.
@(require_results)
instance_enumerate_adapters :: proc(
	using self: Instance,
	backends: Instance_Backend_Flags,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	adapters: []Adapter,
	err: Error,
) {
	options := Instance_Enumerate_Adapter_Options {
		backends = backends,
	}

	adapter_count: uint = wgpu.instance_enumerate_adapters(ptr, &options, nil)

	if adapter_count == 0 {
		return
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == context.temp_allocator)

	raw_adapters: []Raw_Adapter
	alloc_err: mem.Allocator_Error

	if raw_adapters, alloc_err = make([]Raw_Adapter, adapter_count, context.temp_allocator);
	   alloc_err != nil {
		err = alloc_err
		set_and_update_err_data(nil, .General, err, "Failed to allocate adapters", loc)
		return
	}

	wgpu.instance_enumerate_adapters(ptr, &options, raw_data(raw_adapters))

	if adapters, alloc_err = make([]Adapter, adapter_count, allocator); alloc_err != nil {
		err = alloc_err
		set_and_update_err_data(nil, .General, err, "Failed to allocate adapters", loc)
		return
	}
	defer if err != nil {
		if len(adapters) > 0 {
			for &a in adapters {
				if a.ptr != nil do adapter_release(a)
			}
			delete(adapters)
		}
	}

	for i: uint = 0; i < adapter_count; i += 1 {
		adapters[i] = {
			ptr = raw_adapters[i],
		}

		adapters[i].features = _adapter_get_features(adapters[i], loc) or_return
		adapters[i].limits = _adapter_get_limits(adapters[i], loc) or_return
		adapters[i].info = _adapter_get_info(adapters[i]) or_return
	}

	return
}

// Generates memory report.
instance_generate_report :: proc "contextless" (self: Instance) -> Global_Report {
	report: Global_Report
	wgpu.generate_report(self.ptr, &report)
	return report
}

// Processes pending WebGPU events on the instance.
instance_process_events :: proc "contextless" (self: Instance) {
	wgpu.instance_process_events(self.ptr)
}

// Print memory report.
instance_print_report :: proc(using self: Instance, backend_type: Backend_Type = .Undefined) {
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

// Increase the reference count.
instance_reference :: proc "contextless" (using self: Instance) {
	wgpu.instance_reference(ptr)
}

// Release the `Instance`.
instance_release :: #force_inline proc "contextless" (using self: Instance) {
	wgpu.instance_release(ptr)
}

// Release the `Instance` and modify the raw pointer to `nil`.
instance_release_and_nil :: proc "contextless" (using self: ^Instance) {
	if ptr == nil do return
	wgpu.instance_release(ptr)
	ptr = nil
}
