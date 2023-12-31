package wgpu

// Core
import "core:runtime"

// Package
import wgpu "../bindings"

// Open connection to a graphics and/or compute device.
//
// Responsible for the creation of most rendering and compute resources. These are then used in
// commands, which are submitted to a `Queue`.
//
// A device may be requested from an adapter with `adapter_request_device`.
Device :: struct {
	_ptr:      WGPU_Device,
	_err_data: ^Error_Data,
	features:  []Feature,
	limits:    Limits,
}

// Check for resource cleanups and mapping callbacks.
device_poll :: proc(
	using self: ^Device,
	wait: bool = true,
	wrapped_submission_index: ^Wrapped_Submission_Index = nil,
) -> bool {
	return wgpu.device_poll(_ptr, wait, wrapped_submission_index)
}

// List all limits that were requested of this device.
//
// If any of these limits are exceeded, functions may panic.
device_get_limits :: proc(self: ^Device) -> Limits {
	supported_extras := Supported_Limits_Extras {
		chain = {stype = SType(Native_SType.Supported_Limits_Extras)},
	}
	supported_limits := Supported_Limits {
		next_in_chain = cast(^Chained_Struct_Out)&supported_extras,
	}
	wgpu.device_get_limits(self._ptr, &supported_limits)

	limits := supported_limits.limits
	extras := supported_extras.limits

	all_limits: Limits = {
		max_texture_dimension_1d                        = limits.max_texture_dimension_1d,
		max_texture_dimension_2d                        = limits.max_texture_dimension_2d,
		max_texture_dimension_3d                        = limits.max_texture_dimension_3d,
		max_texture_array_layers                        = limits.max_texture_array_layers,
		max_bind_groups                                 = limits.max_bind_groups,
		max_bind_groups_plus_vertex_buffers             = limits.max_bind_groups_plus_vertex_buffers,
		max_bindings_per_bind_group                     = limits.max_bindings_per_bind_group,
		max_dynamic_uniform_buffers_per_pipeline_layout = limits.max_dynamic_uniform_buffers_per_pipeline_layout,
		max_dynamic_storage_buffers_per_pipeline_layout = limits.max_dynamic_storage_buffers_per_pipeline_layout,
		max_sampled_textures_per_shader_stage           = limits.max_sampled_textures_per_shader_stage,
		max_samplers_per_shader_stage                   = limits.max_samplers_per_shader_stage,
		max_storage_buffers_per_shader_stage            = limits.max_storage_buffers_per_shader_stage,
		max_storage_textures_per_shader_stage           = limits.max_storage_textures_per_shader_stage,
		max_uniform_buffers_per_shader_stage            = limits.max_uniform_buffers_per_shader_stage,
		max_uniform_buffer_binding_size                 = limits.max_uniform_buffer_binding_size,
		max_storage_buffer_binding_size                 = limits.max_storage_buffer_binding_size,
		min_uniform_buffer_offset_alignment             = limits.min_uniform_buffer_offset_alignment,
		min_storage_buffer_offset_alignment             = limits.min_storage_buffer_offset_alignment,
		max_vertex_buffers                              = limits.max_vertex_buffers,
		max_buffer_size                                 = limits.max_buffer_size,
		max_vertex_attributes                           = limits.max_vertex_attributes,
		max_vertex_buffer_array_stride                  = limits.max_vertex_buffer_array_stride,
		max_inter_stage_shader_components               = limits.max_inter_stage_shader_components,
		max_inter_stage_shader_variables                = limits.max_inter_stage_shader_variables,
		max_color_attachments                           = limits.max_color_attachments,
		max_color_attachment_bytes_per_sample           = limits.max_color_attachment_bytes_per_sample,
		max_compute_workgroup_storage_size              = limits.max_compute_workgroup_storage_size,
		max_compute_invocations_per_workgroup           = limits.max_compute_invocations_per_workgroup,
		max_compute_workgroup_size_x                    = limits.max_compute_workgroup_size_x,
		max_compute_workgroup_size_y                    = limits.max_compute_workgroup_size_y,
		max_compute_workgroup_size_z                    = limits.max_compute_workgroup_size_z,
		max_compute_workgroups_per_dimension            = limits.max_compute_workgroups_per_dimension,
		// Limits extras
		max_push_constant_size                          = extras.max_push_constant_size,
		max_non_sampler_bindings                        = extras.max_non_sampler_bindings,
	}

	return all_limits
}

// Creates a shader module from either `SPIR-V` or `WGSL` source code.
device_create_shader_module :: proc(
	using self: ^Device,
	descriptor: ^Shader_Module_Descriptor,
) -> (
	shader_module: Shader_Module,
	err: Error_Type,
) {
	desc := wgpu.Shader_Module_Descriptor{}

	if descriptor != nil {
		desc.label = descriptor.label

		switch &source in descriptor.source {
		case WGSL_Source:
			wgsl := wgpu.Shader_Module_WGSL_Descriptor {
				chain = {next = nil, stype = .Shader_Module_WGSL_Descriptor},
				code = source,
			}

			desc.next_in_chain = cast(^Chained_Struct)&wgsl
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

			desc.next_in_chain = cast(^Chained_Struct)&spirv
		}
	}

	_err_data.type = .No_Error

	shader_module_ptr := wgpu.device_create_shader_module(_ptr, &desc)

	if _err_data.type != .No_Error {
		if shader_module_ptr != nil {
			wgpu.shader_module_release(shader_module_ptr)
		}
		return {}, _err_data.type
	}

	shader_module._ptr = shader_module_ptr

	return
}

// Creates an empty `Command_Encoder`.
device_create_command_encoder :: proc(
	using self: ^Device,
	descriptor: ^Command_Encoder_Descriptor = nil,
) -> (
	command_encoder: Command_Encoder,
	err: Error_Type,
) {
	_err_data.type = .No_Error

	if descriptor != nil {
		command_encoder._ptr = wgpu.device_create_command_encoder(_ptr, descriptor)
	} else {
		command_encoder._ptr = wgpu.device_create_command_encoder(
			_ptr,
			&Command_Encoder_Descriptor{label = "Default command encoder"},
		)
	}

	if _err_data.type != .No_Error {
		if command_encoder._ptr != nil {
			wgpu.command_encoder_release(command_encoder._ptr)
		}
		return {}, _err_data.type
	}

	command_encoder._err_data = _err_data

	return
}

// List all features that may be used with this device.
//
// Functions may panic if you use unsupported features.
device_get_features :: proc(using self: ^Device, allocator := context.allocator) -> []Feature {
	count := wgpu.device_enumerate_features(_ptr, nil)
	adapter_features := make([]wgpu.Feature_Name, count, allocator)
	wgpu.device_enumerate_features(_ptr, raw_data(adapter_features))

	return transmute([]Feature)adapter_features
}

// Describes the segment of a buffer to bind.
Buffer_Binding :: struct {
	buffer: ^Buffer,
	offset: u64,
	size:   u64,
}

// Resource that can be bound to a pipeline.
Binding_Resource :: union {
	Buffer_Binding,
	^Sampler,
	^Texture_View,
}

// An element of a `Bind_Group_Descriptor`, consisting of a bindable resource
// and the slot to bind it to.
Bind_Group_Entry :: struct {
	binding:  u32,
	resource: Binding_Resource,
}

// Describes a group of bindings and the resources to be bound.
//
// For use with `device_create_bind_group`.
Bind_Group_Descriptor :: struct {
	label:   cstring,
	layout:  ^Bind_Group_Layout,
	entries: []Bind_Group_Entry,
}

// Creates a new `Bind_Group`.
device_create_bind_group :: proc(
	using self: ^Device,
	descriptor: ^Bind_Group_Descriptor,
) -> (
	bind_group: Bind_Group,
	err: Error_Type,
) {
	desc: wgpu.Bind_Group_Descriptor

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	if descriptor != nil {
		desc.label = descriptor.label

		if descriptor.layout != nil {
			desc.layout = descriptor.layout._ptr
		}

		entry_count := cast(uint)len(descriptor.entries)

		if entry_count > 0 {
			bind_group_entry_ptrs := make(
				[]wgpu.Bind_Group_Entry,
				entry_count,
				context.temp_allocator,
			)

			for v, i in descriptor.entries {
				entry := wgpu.Bind_Group_Entry {
					binding = v.binding,
				}

				switch &res in v.resource {
				case Buffer_Binding:
					entry.buffer = res.buffer._ptr
					entry.size = res.size
					entry.offset = res.offset
				case ^Sampler:
					entry.sampler = res._ptr
				case ^Texture_View:
					entry.texture_view = res._ptr
				}

				bind_group_entry_ptrs[i] = entry
			}

			desc.entry_count = entry_count
			desc.entries = raw_data(bind_group_entry_ptrs)
		}
	}

	_err_data.type = .No_Error

	bind_group_ptr := wgpu.device_create_bind_group(_ptr, &desc)

	if _err_data.type != .No_Error {
		if bind_group_ptr != nil {
			wgpu.bind_group_release(bind_group_ptr)
		}
		return {}, _err_data.type
	}

	bind_group._ptr = bind_group_ptr

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
	visibility: wgpu.Shader_Stage_Flags,
	type:       Binding_Type,
}

// Describes a `Bind_Group_Layout`.
Bind_Group_Layout_Descriptor :: struct {
	label:   cstring,
	entries: []Bind_Group_Layout_Entry,
}

// Creates a `Bind_Group_Layout`.
device_create_bind_group_layout :: proc(
	using self: ^Device,
	descriptor: ^Bind_Group_Layout_Descriptor,
) -> (
	bind_group_layout: Bind_Group_Layout,
	err: Error_Type,
) {
	desc := wgpu.Bind_Group_Layout_Descriptor{}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	if descriptor != nil {
		desc.label = descriptor.label

		entry_count := cast(uint)len(descriptor.entries)

		if entry_count > 0 {
			entries := make([]wgpu.Bind_Group_Layout_Entry, entry_count, context.temp_allocator)

			for v, i in descriptor.entries {
				entry := wgpu.Bind_Group_Layout_Entry {
					binding = v.binding,
					visibility = v.visibility,
					buffer =  {
						next_in_chain = nil,
						type = .Undefined,
						has_dynamic_offset = false,
						min_binding_size = 0,
					},
					sampler = {next_in_chain = nil, type = .Undefined},
					texture =  {
						next_in_chain = nil,
						sample_type = .Undefined,
						view_dimension = .Undefined,
						multisampled = false,
					},
					storage_texture =  {
						next_in_chain = nil,
						access = .Undefined,
						format = .Undefined,
						view_dimension = .Undefined,
					},
				}

				switch e in v.type {
				case wgpu.Buffer_Binding_Layout:
					entry.buffer = e
				case wgpu.Sampler_Binding_Layout:
					entry.sampler = e
				case wgpu.Texture_Binding_Layout:
					entry.texture = e
				case wgpu.Storage_Texture_Binding_Layout:
					entry.storage_texture = e
				}

				entries[i] = entry
			}

			desc.entry_count = entry_count
			desc.entries = raw_data(entries)
		}
	}

	_err_data.type = .No_Error

	bind_group_layout_ptr := wgpu.device_create_bind_group_layout(_ptr, &desc)

	if _err_data.type != .No_Error {
		if bind_group_layout_ptr != nil {
			wgpu.bind_group_layout_release(bind_group_layout_ptr)
		}
		return {}, _err_data.type
	}

	bind_group_layout._ptr = bind_group_layout_ptr

	return
}

// Creates a `Buffer`.
device_create_buffer :: proc(
	using self: ^Device,
	descriptor: ^Buffer_Descriptor,
) -> (
	buffer: Buffer,
	err: Error_Type,
) {
	_err_data.type = .No_Error

	buffer_ptr := wgpu.device_create_buffer(_ptr, descriptor)

	if _err_data.type != .No_Error {
		if buffer_ptr != nil {
			wgpu.buffer_release(buffer_ptr)
		}
		return {}, _err_data.type
	}

	wgpu.device_reference(_ptr)

	buffer._ptr = buffer_ptr
	buffer._device_ptr = self._ptr
	buffer._err_data = _err_data
	buffer.size = descriptor.size
	buffer.usage = descriptor.usage

	return
}

// Programmable_Stage_Descriptor :: struct {
// 	module:      ^Shader_Module,
// 	entry_point: cstring,
// 	constants:   []Constant_Entry,
// }

// Describes a compute pipeline.
//
// For use with `device_create_compute_pipeline`.
Compute_Pipeline_Descriptor :: struct {
	label:       cstring,
	layout:      ^Pipeline_Layout,
	module:      ^Shader_Module,
	entry_point: cstring,
	// compute: Programmable_Stage_Descriptor,
}

// Creates a `Compute_Pipeline`.
device_create_compute_pipeline :: proc(
	using self: ^Device,
	descriptor: ^Compute_Pipeline_Descriptor,
) -> (
	compute_pipeline: Compute_Pipeline,
	err: Error_Type,
) {
	desc := wgpu.Compute_Pipeline_Descriptor{}

	if descriptor != nil {
		desc.label = descriptor.label

		if descriptor.layout != nil {
			desc.layout = descriptor.layout._ptr
		}

		compute := wgpu.Programmable_Stage_Descriptor{}

		if descriptor.module != nil {
			compute.module = descriptor.module._ptr
		}

		compute.entry_point = descriptor.entry_point

		desc.compute = compute
	}

	_err_data.type = .No_Error

	compute_pipeline_ptr := wgpu.device_create_compute_pipeline(_ptr, &desc)

	if _err_data.type != .No_Error {
		if compute_pipeline_ptr != nil {
			wgpu.compute_pipeline_release(compute_pipeline_ptr)
		}
		return {}, _err_data.type
	}

	compute_pipeline._ptr = compute_pipeline_ptr

	return
}

// Describes a PipelineLayout.
//
// For use with `device_create_pipeline_layout`.
Pipeline_Layout_Descriptor :: struct {
	label:              cstring,
	bind_group_layouts: []Bind_Group_Layout,
}

// Creates a `Pipeline_Layout`.
device_create_pipeline_layout :: proc(
	using self: ^Device,
	descriptor: ^Pipeline_Layout_Descriptor,
) -> (
	pipeline_layout: Pipeline_Layout,
	err: Error_Type,
) {
	desc := wgpu.Pipeline_Layout_Descriptor {
		next_in_chain = nil,
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	if descriptor != nil {
		desc.label = descriptor.label

		bind_group_layout_count := cast(uint)len(descriptor.bind_group_layouts)

		if bind_group_layout_count > 0 {
			desc.bind_group_layout_count = bind_group_layout_count

			if bind_group_layout_count == 1 {
				desc.bind_group_layouts = &descriptor.bind_group_layouts[0]._ptr
			} else {
				bind_group_layouts_ptrs := make(
					[]WGPU_Bind_Group_Layout,
					bind_group_layout_count,
					context.temp_allocator,
				)

				for b, i in descriptor.bind_group_layouts {
					bind_group_layouts_ptrs[i] = b._ptr
				}

				desc.bind_group_layouts = raw_data(bind_group_layouts_ptrs)
			}
		} else {
			desc.bind_group_layouts = nil
		}
	}

	_err_data.type = .No_Error

	pipeline_layout_ptr := wgpu.device_create_pipeline_layout(_ptr, &desc)

	if _err_data.type != .No_Error {
		if pipeline_layout_ptr != nil {
			wgpu.pipeline_layout_release(pipeline_layout_ptr)
		}
		return {}, _err_data.type
	}

	pipeline_layout._ptr = pipeline_layout_ptr

	return
}

// Describes a `Query_Set`.
//
// For use with `device_create_query_set`.
Query_Set_Descriptor :: struct {
	label: cstring,
	type:  Query_Type,
	count: u32,
}

// Creates a new `Query_Set`.
device_create_query_set :: proc(
	using self: ^Device,
	descriptor: ^Query_Set_Descriptor,
) -> (
	query_set: Query_Set,
	err: Error_Type,
) {
	desc := wgpu.Query_Set_Descriptor{}

	if descriptor != nil {
		desc.label = descriptor.label
		desc.type = descriptor.type
		desc.count = descriptor.count
	}

	_err_data.type = .No_Error

	query_set_ptr := wgpu.device_create_query_set(_ptr, &desc)

	if _err_data.type != .No_Error {
		if query_set_ptr != nil {
			wgpu.query_set_release(query_set_ptr)
		}
		return {}, _err_data.type
	}

	query_set._ptr = query_set_ptr

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
) -> (
	render_bundle_encoder: Render_Bundle_Encoder,
	err: Error_Type,
) {
	desc := wgpu.Render_Bundle_Encoder_Descriptor {
		label = descriptor.label,
	}

	color_format_count := cast(uint)len(descriptor.color_formats)

	if color_format_count > 0 {
		desc.color_format_count = color_format_count
		desc.color_formats = raw_data(descriptor.color_formats)
	}

	desc.depth_stencil_format = descriptor.depth_stencil_format
	desc.sample_count = descriptor.sample_count
	desc.depth_read_only = descriptor.depth_read_only
	desc.stencil_read_only = descriptor.stencil_read_only

	render_bundle_encoder._ptr = wgpu.device_create_render_bundle_encoder(_ptr, &desc)

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
	module:      ^Shader_Module,
	entry_point: cstring,
	buffers:     []Vertex_Buffer_Layout,
}

// Describes the fragment processing in a render pipeline.
//
// For use in `Render_Pipeline_Descriptor`.
Fragment_State :: struct {
	module:      ^Shader_Module,
	entry_point: cstring,
	targets:     []Color_Target_State,
}

// Primitive type the input mesh is composed of.
Primitive_Topology :: enum {
	Triangle_List, // Default
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
	layout:        ^Pipeline_Layout,
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
) -> (
	render_pipeline: Render_Pipeline,
	err: Error_Type,
) {
	// Initial pipeline descriptor
	desc := wgpu.Render_Pipeline_Descriptor {
		next_in_chain = nil,
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	if descriptor != nil {
		desc.label = descriptor.label

		if descriptor.layout != nil {
			desc.layout = descriptor.layout._ptr
		}

		vertex := descriptor.vertex
		vert := wgpu.Vertex_State{}

		if vertex.module != nil {
			vert.module = vertex.module._ptr
		}

		vert.entry_point = vertex.entry_point

		buffer_count := cast(uint)len(vertex.buffers)

		if buffer_count > 0 {
			buffers_slice := make(
				[]wgpu.Vertex_Buffer_Layout,
				buffer_count,
				context.temp_allocator,
			)

			for v, i in vertex.buffers {
				buffer := wgpu.Vertex_Buffer_Layout {
					array_stride = v.array_stride,
					step_mode    = v.step_mode,
				}

				attribute_count := cast(uint)len(v.attributes)

				if attribute_count > 0 {
					buffer.attribute_count = attribute_count
					buffer.attributes = raw_data(v.attributes)
				}

				buffers_slice[i] = buffer
			}

			vert.buffer_count = buffer_count
			vert.buffers = raw_data(buffers_slice)
		}

		desc.vertex = vert

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

		if descriptor.fragment != nil {
			fragment := wgpu.Fragment_State{}

			fragment.entry_point = descriptor.fragment.entry_point

			target_count := cast(uint)len(descriptor.fragment.targets)

			if descriptor.fragment.module != nil {
				fragment.module = descriptor.fragment.module._ptr
			}

			if target_count > 0 {
				targets := make([]Color_Target_State, target_count, context.temp_allocator)

				for v, i in descriptor.fragment.targets {
					target := Color_Target_State {
						format     = v.format,
						write_mask = v.write_mask,
						blend      = v.blend,
					}

					targets[i] = target
				}

				fragment.target_count = target_count
				fragment.targets = raw_data(targets)
			} else {
				fragment.target_count = 0
				fragment.targets = nil
			}

			desc.fragment = &fragment
		}
	}

	_err_data.type = .No_Error

	render_pipeline_ptr := wgpu.device_create_render_pipeline(_ptr, &desc)

	if _err_data.type != .No_Error {
		if render_pipeline_ptr != nil {
			wgpu.render_pipeline_release(render_pipeline_ptr)
		}
		return {}, _err_data.type
	}

	render_pipeline._ptr = render_pipeline_ptr

	return
}

// Creates a new `Sampler`.
device_create_sampler :: proc(
	using self: ^Device,
	descriptor: ^Sampler_Descriptor,
) -> (
	sampler: Sampler,
	err: Error_Type,
) {
	_err_data.type = .No_Error

	sampler_ptr := wgpu.device_create_sampler(_ptr, descriptor)

	if _err_data.type != .No_Error {
		if sampler_ptr != nil {
			wgpu.sampler_release(sampler_ptr)
		}
		return {}, _err_data.type
	}

	sampler._ptr = sampler_ptr

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
) -> (
	texture: Texture,
	err: Error_Type,
) {
	desc: wgpu.Texture_Descriptor

	if descriptor != nil {
		desc = {
			label           = descriptor.label,
			usage           = descriptor.usage,
			dimension       = descriptor.dimension,
			size            = descriptor.size,
			format          = descriptor.format,
			mip_level_count = descriptor.mip_level_count,
			sample_count    = descriptor.sample_count,
		}

		view_format_count := cast(uint)len(descriptor.view_formats)

		if view_format_count > 0 {
			desc.view_format_count = view_format_count
			desc.view_formats = raw_data(descriptor.view_formats)
		}
	}

	_err_data.type = .No_Error

	texture_ptr := wgpu.device_create_texture(_ptr, &desc)

	if _err_data.type != .No_Error {
		if texture_ptr != nil {
			wgpu.texture_release(texture_ptr)
		}
		return {}, _err_data.type
	}

	texture._ptr = texture_ptr
	texture._err_data = _err_data
	texture.descriptor = descriptor^

	return
}

// Get a handle to a command queue on the device
device_get_queue :: proc(using self: ^Device) -> Queue {
	gpu_queue := Queue {
		_ptr      = wgpu.device_get_queue(_ptr),
		_err_data = _err_data,
	}

	return gpu_queue
}

// Check if device support the given feature name.
device_has_feature :: proc(using self: ^Device, feature: Feature) -> bool {
	return wgpu.device_has_feature(_ptr, cast(wgpu.Feature_Name)feature)
}

device_set_uncaptured_error_callback :: proc(
	using self: ^Device,
	callback: Error_Callback,
	user_data: rawptr,
) {
	_err_data.user_cb = callback
	_err_data.user_data = user_data
}

device_pop_error_scope :: proc(using self: ^Device, callback: Error_Callback, user_data: rawptr) {
	wgpu.device_pop_error_scope(_ptr, callback, user_data)
}

device_push_error_scope :: proc(using self: ^Device, filter: Error_Filter) {
	wgpu.device_push_error_scope(_ptr, filter)
}

// Set debug label.
device_set_label :: proc(using self: ^Device, label: cstring) {
	wgpu.device_set_label(_ptr, label)
}

// Increase the reference count.
device_reference :: proc(using self: ^Device) {
	wgpu.device_reference(_ptr)
}

// Release the `Device` and delete internal objects.
device_release :: proc(using self: ^Device) {
	if _ptr != nil {
		delete(features)
		free(_err_data)
		wgpu.device_release(_ptr)
	}
}
