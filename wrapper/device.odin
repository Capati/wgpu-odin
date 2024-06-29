package wgpu

// Core
import "base:runtime"
import "core:mem"

// Package
import wgpu "../bindings"

// Open connection to a graphics and/or compute device.
//
// Responsible for the creation of most rendering and compute resources. These are then used in
// commands, which are submitted to a `Queue`.
//
// A device may be requested from an adapter with `adapter_request_device`.
Device :: struct {
	ptr:       Raw_Device,
	features:  Device_Features,
	limits:    Limits,
	_err_data: ^Error_Data,
}

// Features that are supported and enabled on device creation.
Device_Features :: distinct Features

// Describes the segment of a buffer to bind.
Buffer_Binding :: struct {
	buffer: Raw_Buffer,
	offset: u64,
	size:   u64,
}

// Resource that can be bound to a pipeline.
Binding_Resource :: union {
	Buffer_Binding,
	Raw_Sampler,
	Raw_Texture_View,
}

Bind_Group_Entry_Extras :: struct {
	buffers:       []Raw_Buffer,
	samplers:      []Raw_Sampler,
	texture_views: []Raw_Texture_View,
}

// An element of a `Bind_Group_Descriptor`, consisting of a bindable resource
// and the slot to bind it to.
Bind_Group_Entry :: struct {
	binding:     u32,
	resource:    Binding_Resource,
	extras:      ^Bind_Group_Entry_Extras,
	_raw_extras: wgpu.Bind_Group_Entry_Extras, // for internal use
}

// Describes a group of bindings and the resources to be bound.
//
// For use with `device_create_bind_group`.
Bind_Group_Descriptor :: struct {
	label:   cstring,
	layout:  Raw_Bind_Group_Layout,
	entries: []Bind_Group_Entry,
}

// Creates a new `Bind_Group`.
device_create_bind_group :: proc(
	using self: ^Device,
	descriptor: ^Bind_Group_Descriptor,
	loc := #caller_location,
) -> (
	bind_group: Bind_Group,
	err: Error,
) {
	desc: wgpu.Bind_Group_Descriptor
	desc.label = descriptor.label

	if descriptor.layout != nil {
		desc.layout = descriptor.layout
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	entry_count := cast(uint)len(descriptor.entries)

	if entry_count > 0 {
		entries := make([]wgpu.Bind_Group_Entry, entry_count, context.temp_allocator)

		for &v, i in descriptor.entries {
			raw_entry := &entries[i]
			raw_entry.binding = v.binding

			switch &res in v.resource {
			case Buffer_Binding:
				raw_entry.buffer = res.buffer
				raw_entry.size = res.size
				raw_entry.offset = res.offset
			case Raw_Sampler:
				raw_entry.sampler = res
			case Raw_Texture_View:
				raw_entry.texture_view = res
			}

			if v.extras != nil {
				if len(v.extras.buffers) > 0 {
					v._raw_extras.buffer_count = len(v.extras.buffers)
					v._raw_extras.buffers = raw_data(v.extras.buffers)
				}

				if len(v.extras.samplers) > 0 {
					v._raw_extras.sampler_count = len(v.extras.samplers)
					v._raw_extras.samplers = raw_data(v.extras.samplers)
				}

				if len(v.extras.texture_views) > 0 {
					v._raw_extras.texture_view_count = len(v.extras.texture_views)
					v._raw_extras.texture_views = raw_data(v.extras.texture_views)
				}

				if v._raw_extras.buffer_count > 0 ||
				   v._raw_extras.sampler_count > 0 ||
				   v._raw_extras.texture_view_count > 0 {
					v._raw_extras.chain.stype = wgpu.SType(Native_SType.Bind_Group_Entry_Extras)
					raw_entry.next_in_chain = &v._raw_extras.chain
				}
			}
		}

		desc.entry_count = entry_count
		desc.entries = raw_data(entries)
	}

	set_and_reset_err_data(_err_data, loc)

	bind_group.ptr = wgpu.device_create_bind_group(ptr, &desc)

	if err = get_last_error(); err != nil {
		if bind_group.ptr != nil {
			wgpu.bind_group_release(bind_group.ptr)
		}
	}

	return
}

// Specific type of a binding.
Binding_Type :: union {
	wgpu.Buffer_Binding_Layout,
	wgpu.Sampler_Binding_Layout,
	wgpu.Texture_Binding_Layout,
	wgpu.Storage_Texture_Binding_Layout,
}

// Describes a single binding inside a bind group.
Bind_Group_Layout_Entry :: struct {
	binding:    u32,
	visibility: Shader_Stage_Flags,
	type:       Binding_Type,
	extras:     ^Bind_Group_Layout_Entry_Extras,
}

// Describes a `Bind_Group_Layout`.
Bind_Group_Layout_Descriptor :: struct {
	label:   cstring,
	entries: []Bind_Group_Layout_Entry,
}

// Creates a `Bind_Group_Layout`.
device_create_bind_group_layout :: proc(
	using self: ^Device,
	descriptor: ^Bind_Group_Layout_Descriptor = nil,
	loc := #caller_location,
) -> (
	bind_group_layout: Bind_Group_Layout,
	err: Error,
) {
	if descriptor == nil {
		set_and_reset_err_data(_err_data, loc)
		bind_group_layout.ptr = wgpu.device_create_bind_group_layout(ptr, nil)

		if err = get_last_error(); err != nil {
			if bind_group_layout.ptr != nil {
				wgpu.bind_group_layout_release(bind_group_layout.ptr)
			}
		}

		return
	}

	desc: wgpu.Bind_Group_Layout_Descriptor
	desc.label = descriptor.label

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	entry_count := cast(uint)len(descriptor.entries)

	if entry_count > 0 {
		entries := make([]wgpu.Bind_Group_Layout_Entry, entry_count, context.temp_allocator)

		for &v, i in descriptor.entries {
			raw_entry := &entries[i]

			raw_entry.binding = v.binding
			raw_entry.visibility = v.visibility

			switch e in v.type {
			case wgpu.Buffer_Binding_Layout:
				raw_entry.buffer = e
			case wgpu.Sampler_Binding_Layout:
				raw_entry.sampler = e
			case wgpu.Texture_Binding_Layout:
				raw_entry.texture = e
			case wgpu.Storage_Texture_Binding_Layout:
				raw_entry.storage_texture = e
			}


			if v.extras != nil {
				v.extras.chain.stype = wgpu.SType(wgpu.Native_SType.Bind_Group_Layout_Entry_Extras)
				raw_entry.next_in_chain = &v.extras.chain
			}
		}

		desc.entry_count = entry_count
		desc.entries = raw_data(entries)
	}

	set_and_reset_err_data(_err_data, loc)

	bind_group_layout.ptr = wgpu.device_create_bind_group_layout(ptr, &desc)

	if err = get_last_error(); err != nil {
		if bind_group_layout.ptr != nil {
			wgpu.bind_group_layout_release(bind_group_layout.ptr)
		}
	}

	return
}

// Creates a `Buffer`.
device_create_buffer :: proc(
	using self: ^Device,
	descriptor: ^Buffer_Descriptor,
	loc := #caller_location,
) -> (
	buffer: Buffer,
	err: Error,
) {
	set_and_reset_err_data(_err_data, loc)

	buffer.ptr = wgpu.device_create_buffer(ptr, descriptor)

	if err = get_last_error(); err != nil {
		if buffer.ptr != nil {
			wgpu.buffer_release(buffer.ptr)
		}
		return
	}

	buffer.size = descriptor.size
	buffer.usage = descriptor.usage
	buffer._err_data = _err_data

	return
}

// Creates an empty `Command_Encoder`.
device_create_command_encoder :: proc(
	using self: ^Device,
	descriptor: ^Command_Encoder_Descriptor = nil,
	loc := #caller_location,
) -> (
	command_encoder: Command_Encoder,
	err: Error,
) {
	set_and_reset_err_data(_err_data, loc)

	if descriptor != nil {
		command_encoder.ptr = wgpu.device_create_command_encoder(ptr, descriptor)
	} else {
		command_encoder.ptr = wgpu.device_create_command_encoder(ptr, nil)
	}

	if err = get_last_error(); err != nil {
		if command_encoder.ptr != nil {
			wgpu.command_encoder_release(command_encoder.ptr)
		}
		return
	}

	command_encoder._err_data = _err_data

	return
}

Programmable_Stage_Descriptor :: struct {
	module:      Raw_Shader_Module,
	entry_point: cstring,
	constants:   []Constant_Entry,
}

// Describes a compute pipeline.
//
// For use with `device_create_compute_pipeline`.
Compute_Pipeline_Descriptor :: struct {
	label:   cstring,
	layout:  Raw_Pipeline_Layout,
	compute: Programmable_Stage_Descriptor,
}

@(private = "file")
_device_create_compute_pipeline_descriptor :: proc(
	descriptor: ^Compute_Pipeline_Descriptor,
) -> (
	desc: wgpu.Compute_Pipeline_Descriptor,
) {
	if descriptor == nil do return

	desc.label = descriptor.label

	if descriptor.layout != nil {
		desc.layout = descriptor.layout
	}

	if descriptor.compute.module != nil {
		desc.compute.module = descriptor.compute.module
	}

	desc.compute.entry_point = descriptor.compute.entry_point

	if len(descriptor.compute.constants) > 0 {
		desc.compute.constant_count = len(descriptor.compute.constants)
		desc.compute.constants = raw_data(descriptor.compute.constants)
	}

	return
}

// Creates a `Compute_Pipeline`.
device_create_compute_pipeline :: proc(
	using self: ^Device,
	descriptor: ^Compute_Pipeline_Descriptor,
	loc := #caller_location,
) -> (
	compute_pipeline: Compute_Pipeline,
	err: Error,
) {
	desc := _device_create_compute_pipeline_descriptor(descriptor)

	set_and_reset_err_data(_err_data, loc)

	compute_pipeline.ptr = wgpu.device_create_compute_pipeline(
		ptr,
		&desc if descriptor != nil else nil,
	)

	if err = get_last_error(); err != nil {
		if compute_pipeline.ptr != nil {
			wgpu.compute_pipeline_release(compute_pipeline.ptr)
		}
		return
	}

	compute_pipeline._err_data = _err_data

	return
}

// Creates a `Compute_Pipeline` async.
device_create_compute_pipeline_async :: proc(
	using self: ^Device,
	descriptor: ^Compute_Pipeline_Descriptor,
	callback: Create_Compute_Pipeline_Async_Callback,
	user_data: rawptr,
	loc := #caller_location,
) -> (
	err: Error,
) {
	desc := _device_create_compute_pipeline_descriptor(descriptor)

	set_and_reset_err_data(_err_data, loc)

	wgpu.device_create_compute_pipeline_async(
		ptr,
		&desc if descriptor != nil else nil,
		callback,
		user_data,
	)

	err = get_last_error()

	return
}

Pipeline_Layout_Extras :: struct {
	push_constant_ranges: []Push_Constant_Range,
}

// Describes a PipelineLayout.
//
// For use with `device_create_pipeline_layout`.
Pipeline_Layout_Descriptor :: struct {
	label:              cstring,
	bind_group_layouts: []Raw_Bind_Group_Layout,
	extras:             ^Pipeline_Layout_Extras,
}

// Creates a `Pipeline_Layout`.
device_create_pipeline_layout :: proc(
	using self: ^Device,
	descriptor: ^Pipeline_Layout_Descriptor,
	loc := #caller_location,
) -> (
	pipeline_layout: Pipeline_Layout,
	err: Error,
) {
	desc: wgpu.Pipeline_Layout_Descriptor
	desc.label = descriptor.label

	if len(descriptor.bind_group_layouts) > 0 {
		desc.bind_group_layout_count = len(descriptor.bind_group_layouts)
		desc.bind_group_layouts = raw_data(descriptor.bind_group_layouts)
	}

	extras: wgpu.Pipeline_Layout_Extras

	if descriptor.extras != nil && len(descriptor.extras.push_constant_ranges) > 0 {
		extras.push_constant_range_count = len(descriptor.extras.push_constant_ranges)
		extras.push_constant_ranges = raw_data(descriptor.extras.push_constant_ranges)

		extras.chain.next = nil
		extras.chain.stype = wgpu.SType(wgpu.Native_SType.Pipeline_Layout_Extras)
		desc.next_in_chain = &extras.chain
	}

	set_and_reset_err_data(_err_data, loc)

	pipeline_layout.ptr = wgpu.device_create_pipeline_layout(ptr, &desc)

	if err = get_last_error(); err != nil {
		if pipeline_layout.ptr != nil {
			wgpu.pipeline_layout_release(pipeline_layout.ptr)
		}
	}

	return
}

Query_Set_Descriptor_Extras :: struct {
	pipeline_statistics: []Pipeline_Statistic_Name,
}

// Describes a `Query_Set`.
//
// For use with `device_create_query_set`.
Query_Set_Descriptor :: struct {
	label:  cstring,
	type:   Query_Type,
	count:  u32,
	extras: ^Query_Set_Descriptor_Extras,
}

// Creates a new `Query_Set`.
device_create_query_set :: proc(
	using self: ^Device,
	descriptor: ^Query_Set_Descriptor,
	loc := #caller_location,
) -> (
	query_set: Query_Set,
	err: Error,
) {
	desc: wgpu.Query_Set_Descriptor

	desc.label = descriptor.label
	desc.type = descriptor.type
	desc.count = descriptor.count

	extras: wgpu.Query_Set_Descriptor_Extras

	if descriptor.extras != nil {
		extras.chain.stype = wgpu.SType(wgpu.Native_SType.Query_Set_Descriptor_Extras)

		if len(descriptor.extras.pipeline_statistics) > 0 {
			extras.pipeline_statistic_count = len(descriptor.extras.pipeline_statistics)
			extras.pipeline_statistics = raw_data(descriptor.extras.pipeline_statistics)
		}

		desc.next_in_chain = &extras.chain
	}

	set_and_reset_err_data(_err_data, loc)

	query_set.ptr = wgpu.device_create_query_set(ptr, &desc)

	if err = get_last_error(); err != nil {
		if query_set.ptr != nil {
			wgpu.query_set_release(query_set.ptr)
		}
	}

	return
}

// Describes a `Render_Bundle_Encoder`.
//
// For use with `device_create_render_bundle_encoder`.
Render_Bundle_Encoder_Descriptor :: struct {
	label:                cstring,
	color_formats:        []Texture_Format,
	depth_stencil_format: Texture_Format,
	sample_count:         u32,
	depth_read_only:      bool,
	stencil_read_only:    bool,
}

// Creates an empty `Render_Bundle_Encoder`.
device_create_render_bundle_encoder :: proc(
	using self: ^Device,
	descriptor: ^Render_Bundle_Encoder_Descriptor,
	loc := #caller_location,
) -> (
	render_bundle_encoder: Render_Bundle_Encoder,
	err: Error,
) {
	desc: wgpu.Render_Bundle_Encoder_Descriptor
	desc.label = descriptor.label

	color_format_count := cast(uint)len(descriptor.color_formats)

	if color_format_count > 0 {
		desc.color_format_count = color_format_count
		desc.color_formats = raw_data(descriptor.color_formats)
	}

	desc.depth_stencil_format = descriptor.depth_stencil_format
	desc.sample_count = descriptor.sample_count
	desc.depth_read_only = descriptor.depth_read_only
	desc.stencil_read_only = descriptor.stencil_read_only

	set_and_reset_err_data(_err_data, loc)

	render_bundle_encoder.ptr = wgpu.device_create_render_bundle_encoder(ptr, &desc)

	if err = get_last_error(); err != nil {
		if render_bundle_encoder.ptr != nil {
			wgpu.render_bundle_encoder_release(render_bundle_encoder.ptr)
		}
		return
	}

	render_bundle_encoder._err_data = _err_data

	return
}

@(private = "file")
_device_create_render_pipeline_descriptor :: proc(
	descriptor: ^Render_Pipeline_Descriptor,
	allocator: mem.Allocator,
) -> (
	desc: wgpu.Render_Pipeline_Descriptor,
) {
	desc.label = descriptor.label

	if descriptor.layout != nil {
		desc.layout = descriptor.layout
	}

	if descriptor.vertex.module != nil {
		desc.vertex.module = descriptor.vertex.module
	}

	desc.vertex.entry_point = descriptor.vertex.entry_point

	if len(descriptor.vertex.constants) > 0 {
		desc.vertex.constant_count = len(descriptor.vertex.constants)
		desc.vertex.constants = raw_data(descriptor.vertex.constants)
	}

	vertex_buffer_count := cast(uint)len(descriptor.vertex.buffers)

	if vertex_buffer_count > 0 {
		vertex_buffers := make([]wgpu.Vertex_Buffer_Layout, vertex_buffer_count, allocator)

		for v, i in descriptor.vertex.buffers {
			raw_buffer := &vertex_buffers[i]

			raw_buffer.array_stride = v.array_stride
			raw_buffer.step_mode = v.step_mode

			attribute_count := cast(uint)len(v.attributes)

			if attribute_count > 0 {
				raw_buffer.attribute_count = attribute_count
				raw_buffer.attributes = raw_data(v.attributes)
			}
		}

		desc.vertex.buffer_count = vertex_buffer_count
		desc.vertex.buffers = raw_data(vertex_buffers)
	}

	desc.primitive = {
		strip_index_format = descriptor.primitive.strip_index_format,
		front_face         = descriptor.primitive.front_face,
		cull_mode          = descriptor.primitive.cull_mode,
	}

	// Because everything in Odin by default is set to 0, the default Primitive_Topology
	// enum value is `Point_List`. We make `Triangle_List` default value by creating a
	// new enum, but here we set the correct/expected wgpu value:
	switch descriptor.primitive.topology {
	case .Triangle_List:
		desc.primitive.topology = wgpu.Primitive_Topology.Triangle_List
	case .Point_List:
		desc.primitive.topology = wgpu.Primitive_Topology.Point_List
	case .Line_List:
		desc.primitive.topology = wgpu.Primitive_Topology.Line_List
	case .Line_Strip:
		desc.primitive.topology = wgpu.Primitive_Topology.Line_Strip
	case .Triangle_Strip:
		desc.primitive.topology = wgpu.Primitive_Topology.Triangle_Strip
	}

	if descriptor.depth_stencil != nil {
		desc.depth_stencil = descriptor.depth_stencil
	}

	desc.multisample = descriptor.multisample

	// Multisample count cannot be 0, defaulting to 1
	if desc.multisample.count == 0 {
		desc.multisample.count = 1
	}

	fragment := new(wgpu.Fragment_State, allocator)

	if descriptor.fragment != nil {
		if descriptor.fragment.module != nil {
			fragment.module = descriptor.fragment.module
		}

		fragment.entry_point = descriptor.fragment.entry_point

		if len(descriptor.fragment.constants) > 0 {
			fragment.constant_count = len(descriptor.fragment.constants)
			fragment.constants = raw_data(descriptor.fragment.constants)
		}

		if len(descriptor.fragment.targets) > 0 {
			fragment.target_count = len(descriptor.fragment.targets)
			fragment.targets = raw_data(descriptor.fragment.targets)
		}

		desc.fragment = fragment
	}

	return
}

// Describes how the vertex buffer is interpreted.
//
// For use in `Vertex_State`.
Vertex_Buffer_Layout :: struct {
	array_stride: u64,
	step_mode:    Vertex_Step_Mode,
	attributes:   []Vertex_Attribute,
}

// Describes the vertex processing in a render pipeline.
//
// For use in `Render_Pipeline_Descriptor`.
Vertex_State :: struct {
	module:      Raw_Shader_Module,
	entry_point: cstring,
	constants:   []Constant_Entry,
	buffers:     []Vertex_Buffer_Layout,
}

// Describes the fragment processing in a render pipeline.
//
// For use in `Render_Pipeline_Descriptor`.
Fragment_State :: struct {
	module:      Raw_Shader_Module,
	entry_point: cstring,
	constants:   []Constant_Entry,
	targets:     []Color_Target_State,
}

// Primitive type the input mesh is composed of.
Primitive_Topology :: enum {
	Triangle_List, // Default here, not in wgpu
	Point_List,
	Line_List,
	Line_Strip,
	Triangle_Strip,
}

// Describes the state of primitive assembly and rasterization in a render pipeline.
Primitive_State :: struct {
	topology:           Primitive_Topology,
	strip_index_format: Index_Format,
	front_face:         Front_Face,
	cull_mode:          Cull_Mode,
}

// Describes a render (graphics) pipeline.
//
// For use with `device_create_render_pipeline`.
Render_Pipeline_Descriptor :: struct {
	label:         cstring,
	layout:        Raw_Pipeline_Layout,
	vertex:        Vertex_State,
	primitive:     Primitive_State,
	depth_stencil: ^Depth_Stencil_State,
	multisample:   Multisample_State,
	fragment:      ^Fragment_State,
}

// Creates a `Render_Pipeline`.
device_create_render_pipeline :: proc(
	using self: ^Device,
	descriptor: ^Render_Pipeline_Descriptor,
	loc := #caller_location,
) -> (
	render_pipeline: Render_Pipeline,
	err: Error,
) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	desc := _device_create_render_pipeline_descriptor(descriptor, context.temp_allocator)

	set_and_reset_err_data(_err_data, loc)

	render_pipeline.ptr = wgpu.device_create_render_pipeline(ptr, &desc)

	if err = get_last_error(); err != nil {
		if render_pipeline.ptr != nil {
			wgpu.render_pipeline_release(render_pipeline.ptr)
		}
		return
	}

	render_pipeline._err_data = _err_data

	return
}

// Creates a `Render_Pipeline` async.
device_create_render_pipeline_async :: proc(
	using self: ^Device,
	descriptor: ^Render_Pipeline_Descriptor,
	callback: Create_Render_Pipeline_Async_Callback,
	user_data: rawptr,
	loc := #caller_location,
) -> (
	err: Error,
) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	desc := _device_create_render_pipeline_descriptor(descriptor, context.temp_allocator)

	set_and_reset_err_data(_err_data, loc)

	wgpu.device_create_render_pipeline_async(ptr, &desc, callback, user_data)

	err = get_last_error()

	return
}

// Creates a new `Sampler`.
device_create_sampler :: proc(
	using self: ^Device,
	descriptor: ^Sampler_Descriptor = nil,
	loc := #caller_location,
) -> (
	sampler: Sampler,
	err: Error,
) {
	set_and_reset_err_data(_err_data, loc)

	sampler.ptr = wgpu.device_create_sampler(ptr, descriptor if descriptor != nil else nil)

	if err = get_last_error(); err != nil {
		if sampler.ptr != nil {
			wgpu.sampler_release(sampler.ptr)
		}
	}

	return
}

// Creates a shader module from either `SPIR-V` or `WGSL` source code.
device_create_shader_module :: proc(
	using self: ^Device,
	descriptor: ^Shader_Module_Descriptor,
	loc := #caller_location,
) -> (
	shader_module: Shader_Module,
	err: Error,
) {
	desc: wgpu.Shader_Module_Descriptor
	desc.label = descriptor.label

	set_and_reset_err_data(_err_data, loc)

	switch &source in descriptor.source {
	case WGSL_Source:
		wgsl := wgpu.Shader_Module_WGSL_Descriptor {
			chain = {next = nil, stype = .Shader_Module_WGSL_Descriptor},
			code = source,
		}

		desc.next_in_chain = &wgsl.chain

		shader_module.ptr = wgpu.device_create_shader_module(ptr, &desc)
	case SPIRV_Source:
		spirv := wgpu.Shader_Module_SPIRV_Descriptor {
			chain = {next = nil, stype = .Shader_Module_SPIRV_Descriptor},
			code = nil,
		}

		if source != nil {
			code_size := cast(u32)len(source)

			if code_size > 0 {
				spirv.code_size = code_size
				spirv.code = raw_data(source)
			}
		}

		desc.next_in_chain = &spirv.chain

		shader_module.ptr = wgpu.device_create_shader_module(ptr, &desc)
	}

	if err = get_last_error(); err != nil {
		if shader_module.ptr != nil {
			wgpu.shader_module_release(shader_module.ptr)
		}
	}

	return
}

// Describes a `Texture`.
Texture_Descriptor :: struct {
	label:           cstring,
	usage:           Texture_Usage_Flags,
	dimension:       Texture_Dimension,
	size:            Extent_3D,
	format:          Texture_Format,
	mip_level_count: u32,
	sample_count:    u32,
	view_formats:    []Texture_Format,
}

// Creates a new `Texture`.
//
// `descriptor` specifies the general format of the texture.
device_create_texture :: proc(
	using self: ^Device,
	descriptor: ^Texture_Descriptor,
	loc := #caller_location,
) -> (
	texture: Texture,
	err: Error,
) {
	desc: wgpu.Texture_Descriptor

	desc.label = descriptor.label
	desc.usage = descriptor.usage
	desc.dimension = descriptor.dimension
	desc.size = descriptor.size
	desc.format = descriptor.format
	desc.mip_level_count = descriptor.mip_level_count
	desc.sample_count = descriptor.sample_count

	view_format_count := cast(uint)len(descriptor.view_formats)

	if view_format_count > 0 {
		desc.view_format_count = view_format_count
		desc.view_formats = raw_data(descriptor.view_formats)
	}

	set_and_reset_err_data(_err_data, loc)

	texture.ptr = wgpu.device_create_texture(ptr, &desc)

	if err = get_last_error(); err != nil {
		if texture.ptr != nil {
			wgpu.texture_release(texture.ptr)
		}
		return
	}

	texture.descriptor = descriptor^
	texture._err_data = _err_data

	return
}

device_destroy :: proc(using self: ^Device) {
	wgpu.device_destroy(ptr)
}

@(private)
_device_get_features :: proc(
	self: ^Device,
	loc := #caller_location,
) -> (
	features: Device_Features,
	err: Error,
) {
	count := wgpu.device_enumerate_features(self.ptr, nil)

	if count == 0 do return

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	raw_features, alloc_err := make([]wgpu.Feature_Name, count, context.temp_allocator)

	if alloc_err != nil {
		err = alloc_err
		set_and_update_err_data(nil, .General, err, "Failed to get device features", loc)
		return
	}

	wgpu.device_enumerate_features(self.ptr, raw_data(raw_features))

	features_slice := transmute([]Raw_Feature_Name)raw_features
	features = cast(Device_Features)features_slice_to_flags(&features_slice)

	return
}

// List all features that may be used with this device.
//
// Functions may panic if you use unsupported features.
device_get_features :: proc(self: ^Device) -> Device_Features {
	return self.features // filled on request device
}

@(private)
_device_get_limits :: proc(
	self: ^Device,
	loc := #caller_location,
) -> (
	limits: Limits,
	err: Error,
) {
	native := Supported_Limits_Extras {
		chain = {stype = SType(Native_SType.Supported_Limits_Extras)},
	}

	supported := Supported_Limits {
		next_in_chain = &native.chain,
	}

	set_and_reset_err_data(self._err_data, loc)

	result := wgpu.device_get_limits(self.ptr, &supported)

	if err = get_last_error(); err != nil {
		return
	}

	if !result {
		err = Error_Type.Unknown
		update_error_data(self._err_data, .Request_Device, err, "Failed to fill device limits")
		return
	}

	limits = limits_merge_webgpu_with_native(supported.limits, native.limits)

	return
}

// List all limits that were requested of this device.
//
// If any of these limits are exceeded, functions may panic.
device_get_limits :: proc(self: ^Device) -> Limits {
	return self.limits // filled on request device
}

// Get a handle to a command queue on the device
device_get_queue :: proc(using self: ^Device) -> (queue: Queue) {
	queue = Queue {
		ptr       = wgpu.device_get_queue(ptr),
		_err_data = _err_data,
	}

	return
}

// Check if device support the given feature name.
device_has_feature_name :: proc(self: ^Device, feature: Feature_Name) -> bool {
	return feature in self.features
}

// Check if device support all features in the given flags.
device_has_feature :: proc(self: ^Device, features: Features) -> bool {
	if features == {} do return true
	for f in features {
		if f not_in self.features || f == .Undefined do return false
	}
	return true
}

device_pop_error_scope :: proc(using self: ^Device, callback: Error_Callback, user_data: rawptr) {
	wgpu.device_pop_error_scope(ptr, callback, user_data)
}

device_push_error_scope :: proc(using self: ^Device, filter: Error_Filter) {
	wgpu.device_push_error_scope(ptr, filter)
}

device_set_uncaptured_error_callback :: proc(
	using self: ^Device,
	callback: Error_Callback,
	user_data: rawptr,
) {
	when WGPU_ENABLE_ERROR_HANDLING {
		set_user_data_uncaptured_error_callback(_err_data, callback, user_data)
	} else {
		wgpu.device_set_uncaptured_error_callback(ptr, callback, user_data)
	}
}

// Set debug label.
device_set_label :: proc(using self: ^Device, label: cstring) {
	wgpu.device_set_label(ptr, label)
}

// Increase the reference count.
device_reference :: proc(using self: ^Device) {
	wgpu.device_reference(ptr)
}


// Release the `Device` and delete internal objects.
device_release :: proc(using self: ^Device) {
	wgpu.device_release(ptr)
}

// Release the `Device` and delete internal objects and modify the raw pointer to `nil`.
device_release_and_nil :: proc(using self: ^Device) {
	if ptr == nil do return
	wgpu.device_release(ptr)
	ptr = nil
}

// Check for resource cleanups and mapping callbacks.
device_poll :: proc(
	using self: ^Device,
	wait: bool = true,
	wrapped_submission_index: ^Wrapped_Submission_Index = nil,
	loc := #caller_location,
) -> (
	result: bool,
	err: Error,
) {
	set_and_reset_err_data(_err_data, loc)
	result = wgpu.device_poll(ptr, wait, wrapped_submission_index)
	err = get_last_error()

	return
}
