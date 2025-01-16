package wgpu

// Packages
import "base:runtime"
import "core:strings"

/*
Open connection to a graphics and/or compute device.

Responsible for the creation of most rendering and compute resources.
These are then used in commands, which are submitted to a `Queue`.

A device may be requested from an adapter with `adapter_request_device`.

Corresponds to [WebGPU `GPUDevice`](https://gpuweb.github.io/gpuweb/#gpu-device).
*/
Device :: distinct rawptr

/*
Describes a `Device`.

For use with `adapter_request_device`.

Corresponds to [WebGPU `GPUDeviceDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpudevicedescriptor).
*/
Device_Descriptor :: struct {
	label:                          string,
	optional_features:              Features,
	required_features:              Features,
	required_limits:                Limits,
	device_lost_callback_info:      Device_Lost_Callback_Info,
	uncaptured_error_callback_info: Uncaptured_Error_Callback_Info,
	trace_path:                     string,
}

/*
Check for resource cleanups and mapping callbacks. Will block if [`Maintain::Wait`] is passed.

Return `true` if the queue is empty, or `false` if there are more queue
submissions still in flight. (Note that, unless access to the [`Queue`] is
coordinated somehow, this information could be out of date by the time
the caller receives it. `Queue`s can be shared between threads, so
other threads could submit new work at any time.)

When running on WebGPU, this is a no-op. `Device`s are automatically polled.
*/
device_poll :: proc "contextless" (
	self: Device,
	wait: bool = true,
	wrapped_submission_index: ^Submission_Index = nil,
	loc := #caller_location,
) -> (
	result: bool,
	ok: bool,
) #optional_ok {
	error_reset_data(loc)
	result = bool(wgpuDevicePoll(self, b32(wait), wrapped_submission_index))
	ok = get_last_error() == nil
	return
}

/*
List all features that may be used with this device.

Functions may panic if you use unsupported features.
*/
device_features :: proc "contextless" (self: Device) -> (features: Features) #no_bounds_check {
	supported: WGPU_Supported_Features
	wgpuDeviceGetFeatures(self, &supported)
	defer wgpuSupportedFeaturesFreeMembers(supported)

	raw_features := supported.features[:supported.feature_count]
	features = features_slice_to_flags(raw_features)

	return
}

/* Check if device support all features in the given flags. */
device_has_feature :: proc "contextless" (self: Device, features: Features) -> bool {
	if features == {} {
		return true
	}
	available := device_features(self)
	if available == {} {
		return false
	}
	for f in features {
		if f not_in available {
			return false
		}
	}
	return true
}

/*
List all limits that were requested of this device.

If any of these limits are exceeded, functions may panic.
*/
device_limits :: proc "contextless" (
	self: Device,
	loc := #caller_location,
) -> (
	limits: Limits,
	ok: bool,
) #optional_ok {
	native := WGPU_Native_Limits {
		chain = {stype = SType.Native_Limits},
	}
	base := WGPU_Limits {
		next_in_chain = &native.chain,
	}

	error_reset_data(loc)
	status := wgpuDeviceGetLimits(self, &base)
	if get_last_error() != nil {
		return
	}
	if status != .Success {
		error_update_data(Error_Type.Unknown, "Failed to fill device limits")
		return
	}

	limits = limits_merge_webgpu_with_native(base, native)

	// Why wgpu returns 0 for some supported limits?
	// Enforce minimum values for all limits even if the returned values are lower
	limits_ensure_minimum(&limits, DEFAULT_MINIMUM_LIMITS)

	return limits, true
}

@(private)
WGPU_Shader_Module_Descriptor :: struct {
	next_in_chain: ^Chained_Struct,
	label:         String_View,
}

@(private)
WGPU_Shader_Source_SPIRV :: struct {
	chain:     Chained_Struct,
	code_size: u32,
	code:      [^]u32,
}

@(private)
WGPU_Shader_Source_WGSL :: struct {
	chain: Chained_Struct,
	code:  String_View,
}

/* Creates a shader module from either `WGSL`, `SPIR-V` or `GLSL` source code. */
@(require_results)
device_create_shader_module :: proc(
	self: Device,
	descriptor: Shader_Module_Descriptor,
	loc := #caller_location,
) -> (
	shader_module: Shader_Module,
	ok: bool,
) #optional_ok {
	raw_desc: WGPU_Shader_Module_Descriptor

	when ODIN_DEBUG {
		c_label: String_View_Buffer
		if descriptor.label != "" {
			raw_desc.label = init_string_buffer(&c_label, descriptor.label)
		}
	}

	error_reset_data(loc)

	switch &source in descriptor.source {
	case string:
		runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
		wgsl := WGPU_Shader_Source_WGSL {
			chain = {stype = .Shader_Source_WGSL},
			code = {
				data = strings.clone_to_cstring(source, context.temp_allocator),
				length = STRLEN,
			},
		}
		raw_desc.next_in_chain = &wgsl.chain
		shader_module = wgpuDeviceCreateShaderModule(self, raw_desc)
	case cstring:
		wgsl := WGPU_Shader_Source_WGSL {
			chain = {stype = .Shader_Source_WGSL},
			code = {data = source, length = STRLEN},
		}
		raw_desc.next_in_chain = &wgsl.chain
		shader_module = wgpuDeviceCreateShaderModule(self, raw_desc)
	case []u32:
		spirv := WGPU_Shader_Source_SPIRV {
			chain = {stype = .Shader_Source_SPIRV},
			code = nil,
		}
		if source != nil {
			code_size := cast(u32)len(source)
			if code_size > 0 {
				spirv.code_size = code_size
				spirv.code = raw_data(source)
			}
		}
		raw_desc.next_in_chain = &spirv.chain
		shader_module = wgpuDeviceCreateShaderModule(self, raw_desc)
	case GLSL_Source:
		runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
		ta := context.temp_allocator
		glsl := WGPU_Shader_Module_GLSL_Descriptor {
			chain = {stype = .Shader_Module_GLSL_Descriptor},
			stage = source.stage,
			code = {data = strings.clone_to_cstring(source.shader, ta), length = STRLEN},
		}
		if len(source.defines) > 0 {
			defines := make([]WGPU_Shader_Define, len(source.defines), ta)
			for &d, i in source.defines {
				defines[i] = {
					name  = {strings.clone_to_cstring(d.name, ta), STRLEN},
					value = {strings.clone_to_cstring(d.value, ta), STRLEN},
				}
			}
			glsl.define_count = u32(len(defines))
			glsl.defines = raw_data(defines)
		}
		raw_desc.next_in_chain = &glsl.chain
		shader_module = wgpuDeviceCreateShaderModule(self, raw_desc)
	}

	if get_last_error() != nil {
		if shader_module != nil {
			wgpuShaderModuleRelease(shader_module)
		}
		return
	}

	return shader_module, true
}

@(private)
WGPU_Shader_Module_Descriptor_SPIRV :: struct {
	label:       String_View,
	source_size: u32,
	source:      [^]u32,
}

Shader_Module_Descriptor_SPIRV :: struct {
	label:  string,
	source: []u32,
}

// Creates a shader module from SPIR-V binary directly.
@(require_results)
device_create_shader_module_spirv :: proc(
	self: Device,
	descriptor: Shader_Module_Descriptor_SPIRV,
	loc := #caller_location,
) -> (
	shader_module: Shader_Module,
	ok: bool,
) #optional_ok {
	assert(descriptor.source != nil && len(descriptor.source) > 0, "SPIR-V source is required")

	raw_desc: WGPU_Shader_Module_Descriptor_SPIRV

	when ODIN_DEBUG {
		c_label: String_View_Buffer
		if descriptor.label != "" {
			raw_desc.label = init_string_buffer(&c_label, descriptor.label)
		}
	}

	raw_desc.source_size = cast(u32)len(descriptor.source)
	raw_desc.source = raw_data(descriptor.source)

	error_reset_data(loc)
	shader_module = wgpuDeviceCreateShaderModuleSpirV(self, raw_desc)

	if get_last_error() != nil {
		if shader_module != nil {
			wgpuShaderModuleRelease(shader_module)
		}
		return
	}

	return shader_module, true
}

/* Creates an empty `Command_Encoder`. */
@(require_results)
device_create_command_encoder :: proc "contextless" (
	self: Device,
	descriptor: Maybe(Command_Encoder_Descriptor) = nil,
	loc := #caller_location,
) -> (
	command_encoder: Command_Encoder,
	ok: bool,
) #optional_ok {
	error_reset_data(loc)

	if desc, desc_ok := descriptor.?; desc_ok {
		raw_desc := WGPU_Command_Encoder_Descriptor{}

		when ODIN_DEBUG {
			c_label: String_View_Buffer
			if desc.label != "" {
				raw_desc.label = init_string_buffer(&c_label, desc.label)
			}
		}

		command_encoder = wgpuDeviceCreateCommandEncoder(self, &raw_desc)
	} else {
		command_encoder = wgpuDeviceCreateCommandEncoder(self, nil)
	}

	if get_last_error() != nil {
		if command_encoder != nil {
			wgpuCommandEncoderRelease(command_encoder)
		}
		return
	}

	return command_encoder, true
}

/* Creates an empty `Render_Bundle_Encoder`. */
@(require_results)
device_create_render_bundle_encoder :: proc "contextless" (
	self: Device,
	descriptor: Render_Bundle_Encoder_Descriptor,
	loc := #caller_location,
) -> (
	render_bundle_encoder: Render_Bundle_Encoder,
	ok: bool,
) #optional_ok {
	desc: WGPU_Render_Bundle_Encoder_Descriptor

	when ODIN_DEBUG {
		c_label: String_View_Buffer
		if descriptor.label != "" {
			desc.label = init_string_buffer(&c_label, descriptor.label)
		}
	}

	color_format_count := uint(len(descriptor.color_formats))

	if color_format_count > 0 {
		desc.color_format_count = color_format_count
		desc.color_formats = raw_data(descriptor.color_formats)
	}

	desc.depth_stencil_format = descriptor.depth_stencil_format
	desc.sample_count = descriptor.sample_count
	desc.depth_read_only = b32(descriptor.depth_read_only)
	desc.stencil_read_only = b32(descriptor.stencil_read_only)

	error_reset_data(loc)
	render_bundle_encoder = wgpuDeviceCreateRenderBundleEncoder(self, desc)
	if get_last_error() != nil {
		if render_bundle_encoder != nil {
			wgpuRenderBundleEncoderRelease(render_bundle_encoder)
		}
		return
	}

	return render_bundle_encoder, true
}

@(private)
WGPU_Bind_Group_Entry_Extras :: struct {
	chain:              Chained_Struct,
	buffers:            [^]Buffer,
	buffer_count:       uint,
	samplers:           [^]Sampler,
	sampler_count:      uint,
	texture_views:      [^]Texture_View,
	texture_view_count: uint,
}

/* Creates a new `Bind_Group`. */
@(require_results)
device_create_bind_group :: proc(
	self: Device,
	descriptor: Bind_Group_Descriptor,
	loc := #caller_location,
) -> (
	bind_group: Bind_Group,
	ok: bool,
) #no_bounds_check #optional_ok {
	desc: WGPU_Bind_Group_Descriptor

	when ODIN_DEBUG {
		c_label: String_View_Buffer
		if descriptor.label != "" {
			desc.label = init_string_buffer(&c_label, descriptor.label)
		}
	}

	desc.layout = descriptor.layout

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	ta := context.temp_allocator

	extras: [dynamic]WGPU_Bind_Group_Entry_Extras
	extras.allocator = ta

	entry_count := uint(len(descriptor.entries))

	if entry_count > 0 {
		entries := make([]WGPU_Bind_Group_Entry, entry_count, ta)

		for &v, i in descriptor.entries {
			raw_entry := &entries[i]
			raw_entry.binding = v.binding
			raw_extra: ^WGPU_Bind_Group_Entry_Extras

			#partial switch &res in v.resource {
			case []Buffer, []Sampler, []Texture_View:
				append(
					&extras,
					WGPU_Bind_Group_Entry_Extras{chain = {stype = .Bind_Group_Entry_Extras}},
				)
				raw_extra = &extras[len(extras) - 1]
			}

			switch &res in v.resource {
			case Buffer_Binding:
				raw_entry.buffer = res.buffer
				raw_entry.size = res.size
				raw_entry.offset = res.offset
			case []Buffer:
				raw_extra.buffer_count = len(res)
				raw_extra.buffers = raw_data(res)
			case Sampler:
				raw_entry.sampler = res
			case []Sampler:
				raw_extra.sampler_count = len(res)
				raw_extra.samplers = raw_data(res)
			case Texture_View:
				raw_entry.texture_view = res
			case []Texture_View:
				raw_extra.texture_view_count = len(res)
				raw_extra.texture_views = raw_data(res)
			}

			if len(extras) > 0 {
				raw_entry.next_in_chain = &raw_extra.chain
			}
		}

		desc.entry_count = entry_count
		desc.entries = raw_data(entries)
	}

	error_reset_data(loc)
	bind_group = wgpuDeviceCreateBindGroup(self, desc)
	if get_last_error() != nil {
		if bind_group != nil {
			wgpuBindGroupRelease(bind_group)
		}
		return
	}

	return bind_group, true
}

@(private)
WGPU_Bind_Group_Layout_Entry_Extras :: struct {
	chain: Chained_Struct,
	count: u32,
}

/* Creates a new `Bind_Group_Layout`. */
@(require_results)
device_create_bind_group_layout :: proc(
	self: Device,
	descriptor: Maybe(Bind_Group_Layout_Descriptor) = nil,
	loc := #caller_location,
) -> (
	bind_group_layout: Bind_Group_Layout,
	ok: bool,
) #no_bounds_check #optional_ok {
	desc, desc_ok := descriptor.?

	if !desc_ok {
		error_reset_data(loc)

		bind_group_layout = wgpuDeviceCreateBindGroupLayout(self, nil)

		if get_last_error() != nil {
			if bind_group_layout != nil {
				wgpuBindGroupLayoutRelease(bind_group_layout)
			}
			return
		}

		return bind_group_layout, true
	}

	raw_desc: WGPU_Bind_Group_Layout_Descriptor

	when ODIN_DEBUG {
		c_label: String_View_Buffer
		if desc.label != "" {
			raw_desc.label = init_string_buffer(&c_label, desc.label)
		}
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	ta := context.temp_allocator

	extras: [dynamic]WGPU_Bind_Group_Layout_Entry_Extras
	extras.allocator = ta

	entry_count := uint(len(desc.entries))

	if entry_count > 0 {
		entries := make([]WGPU_Bind_Group_Layout_Entry, entry_count, ta)

		for &v, i in desc.entries {
			raw_entry := &entries[i]

			raw_entry.binding = v.binding
			raw_entry.visibility = v.visibility

			switch e in v.type {
			case Buffer_Binding_Layout:
				raw_entry.buffer = e
			case Sampler_Binding_Layout:
				raw_entry.sampler = e
			case Texture_Binding_Layout:
				raw_entry.texture = e
			case Storage_Texture_Binding_Layout:
				raw_entry.storage_texture = e
			}

			if v.count > 0 {
				append(
					&extras,
					WGPU_Bind_Group_Layout_Entry_Extras {
						chain = {stype = .Bind_Group_Layout_Entry_Extras},
						count = v.count,
					},
				)
				raw_entry.next_in_chain = &extras[len(extras) - 1].chain
			}
		}

		raw_desc.entry_count = entry_count
		raw_desc.entries = raw_data(entries)
	}

	error_reset_data(loc)
	bind_group_layout = wgpuDeviceCreateBindGroupLayout(self, &raw_desc)
	if get_last_error() != nil {
		if bind_group_layout != nil {
			wgpuBindGroupLayoutRelease(bind_group_layout)
		}
		return
	}

	return bind_group_layout, true
}

@(private)
WGPU_Push_Constant_Range :: struct {
	stages: Shader_Stages,
	start:  u32,
	end:    u32,
}

@(private)
WGPU_Pipeline_Layout_Extras :: struct {
	chain:                     Chained_Struct,
	push_constant_range_count: uint,
	push_constant_ranges:      [^]WGPU_Push_Constant_Range,
}

/* Creates a `Pipeline_Layout`. */
@(require_results)
device_create_pipeline_layout :: proc(
	self: Device,
	descriptor: Pipeline_Layout_Descriptor,
	loc := #caller_location,
) -> (
	pipeline_layout: Pipeline_Layout,
	ok: bool,
) #optional_ok {
	desc: WGPU_Pipeline_Layout_Descriptor

	when ODIN_DEBUG {
		c_label: String_View_Buffer
		if descriptor.label != "" {
			desc.label = init_string_buffer(&c_label, descriptor.label)
		}
	}

	if len(descriptor.bind_group_layouts) > 0 {
		desc.bind_group_layout_count = len(descriptor.bind_group_layouts)
		desc.bind_group_layouts = raw_data(descriptor.bind_group_layouts)
	}

	extras: WGPU_Pipeline_Layout_Extras

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	push_constant_range_count := len(descriptor.push_constant_ranges)

	if push_constant_range_count > 0 {
		push_constant_ranges := make(
			[]WGPU_Push_Constant_Range,
			push_constant_range_count,
			context.temp_allocator,
		)

		for &r, i in descriptor.push_constant_ranges {
			raw_range := &push_constant_ranges[i]
			raw_range.stages = r.stages
			raw_range.start = r.range.start
			raw_range.end = r.range.end
		}

		extras = {
			chain = {stype = .Pipeline_Layout_Extras},
			push_constant_range_count = uint(push_constant_range_count),
			push_constant_ranges = raw_data(push_constant_ranges),
		}

		desc.next_in_chain = &extras.chain
	}

	error_reset_data(loc)
	pipeline_layout = wgpuDeviceCreatePipelineLayout(self, desc)
	if get_last_error() != nil {
		if pipeline_layout != nil {
			wgpuPipelineLayoutRelease(pipeline_layout)
		}
		return
	}

	return pipeline_layout, true
}

/* Creates a `Render_Pipeline`. */
@(require_results)
device_create_render_pipeline :: proc(
	self: Device,
	descriptor: Render_Pipeline_Descriptor,
	loc := #caller_location,
) -> (
	render_pipeline: Render_Pipeline,
	ok: bool,
) #optional_ok {
	raw_desc: WGPU_Render_Pipeline_Descriptor

	when ODIN_DEBUG {
		c_label: String_View_Buffer
		if descriptor.label != "" {
			raw_desc.label = init_string_buffer(&c_label, descriptor.label)
		}
	}

	raw_desc.layout = descriptor.layout

	raw_desc.vertex.module = descriptor.vertex.module

	c_vertex_entry_point: String_View_Buffer
	raw_desc.vertex.entry_point = init_string_buffer(
		&c_vertex_entry_point,
		descriptor.vertex.entry_point,
	)

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	if len(descriptor.vertex.constants) > 0 {
		vertex_constants := make(
			[]WGPU_Constant_Entry,
			len(descriptor.vertex.constants),
			context.temp_allocator,
		)
		for &c, i in descriptor.vertex.constants {
			vertex_constants[i].key = init_string_buffer_owned(c.key, context.temp_allocator)
			vertex_constants[i].value = c.value
		}
		raw_desc.vertex.constant_count = len(vertex_constants)
		raw_desc.vertex.constants = raw_data(vertex_constants)
	}

	vertex_buffer_count := uint(len(descriptor.vertex.buffers))

	if vertex_buffer_count > 0 {
		vertex_buffers := make(
			[]WGPU_Vertex_Buffer_Layout,
			vertex_buffer_count,
			context.temp_allocator,
		)

		for v, i in descriptor.vertex.buffers {
			raw_buffer := &vertex_buffers[i]

			raw_buffer.array_stride = v.array_stride
			raw_buffer.step_mode = v.step_mode

			attribute_count := uint(len(v.attributes))

			if attribute_count > 0 {
				raw_buffer.attribute_count = attribute_count
				raw_buffer.attributes = raw_data(v.attributes)
			}
		}

		raw_desc.vertex.buffer_count = vertex_buffer_count
		raw_desc.vertex.buffers = raw_data(vertex_buffers)
	}

	raw_desc.primitive = {
		strip_index_format = descriptor.primitive.strip_index_format,
		front_face         = descriptor.primitive.front_face,
		cull_mode          = descriptor.primitive.cull_mode,
		unclipped_depth    = b32(descriptor.primitive.unclipped_depth),
	}

	// Because everything in Odin by default is set to 0, the default Primitive_Topology
	// enum value is `Point_List`. We make `Triangle_List` default value by creating a
	// new enum, but here we set the correct/expected wgpu value:
	switch descriptor.primitive.topology {
	case .Triangle_List:
		raw_desc.primitive.topology = WGPU_Primitive_Topology.Triangle_List
	case .Point_List:
		raw_desc.primitive.topology = WGPU_Primitive_Topology.Point_List
	case .Line_List:
		raw_desc.primitive.topology = WGPU_Primitive_Topology.Line_List
	case .Line_Strip:
		raw_desc.primitive.topology = WGPU_Primitive_Topology.Line_Strip
	case .Triangle_Strip:
		raw_desc.primitive.topology = WGPU_Primitive_Topology.Triangle_Strip
	}

	depth_stencil: WGPU_Depth_Stencil_State
	// Only sets up the depth stencil state if a valid format was specified
	if descriptor.depth_stencil.format != .Undefined {
		depth_stencil = {
			format                 = descriptor.depth_stencil.format,
			depth_write_enabled    = .True if descriptor.depth_stencil.depth_write_enabled else .False,
			depth_compare          = descriptor.depth_stencil.depth_compare,
			stencil_front          = descriptor.depth_stencil.stencil.front,
			stencil_back           = descriptor.depth_stencil.stencil.back,
			stencil_read_mask      = descriptor.depth_stencil.stencil.read_mask,
			stencil_write_mask     = descriptor.depth_stencil.stencil.write_mask,
			depth_bias             = descriptor.depth_stencil.bias.constant,
			depth_bias_slope_scale = descriptor.depth_stencil.bias.slope_scale,
			depth_bias_clamp       = descriptor.depth_stencil.bias.clamp,
		}
		raw_desc.depth_stencil = &depth_stencil
	}

	raw_desc.multisample = descriptor.multisample

	// Multisample count cannot be 0, defaulting to 1
	if raw_desc.multisample.count == 0 {
		raw_desc.multisample.count = 1
	}

	fragment: WGPU_Fragment_State
	c_fragment_entry_point: String_View_Buffer

	if descriptor.fragment != nil {
		fragment.module = descriptor.fragment.module

		fragment.entry_point = init_string_buffer(
			&c_fragment_entry_point,
			descriptor.fragment.entry_point,
		)

		if len(descriptor.fragment.constants) > 0 {
			fragment_constants := make(
				[]WGPU_Constant_Entry,
				len(descriptor.fragment.constants),
				context.temp_allocator,
			)
			for &c, i in descriptor.fragment.constants {
				fragment_constants[i].key = init_string_buffer_owned(c.key, context.temp_allocator)
				fragment_constants[i].value = c.value
			}
			fragment.constant_count = len(fragment_constants)
			fragment.constants = raw_data(fragment_constants)
		}

		if len(descriptor.fragment.targets) > 0 {
			fragment.target_count = len(descriptor.fragment.targets)
			fragment.targets = raw_data(descriptor.fragment.targets)
		}

		raw_desc.fragment = &fragment
	}

	error_reset_data(loc)
	render_pipeline = wgpuDeviceCreateRenderPipeline(self, raw_desc)
	if get_last_error() != nil {
		if render_pipeline != nil {
			wgpuRenderPipelineRelease(render_pipeline)
		}
		return
	}

	return render_pipeline, true
}

/* Creates a new `Compute_Pipeline`. */
@(require_results)
device_create_compute_pipeline :: proc(
	self: Device,
	descriptor: Compute_Pipeline_Descriptor,
	loc := #caller_location,
) -> (
	compute_pipeline: Compute_Pipeline,
	ok: bool,
) #optional_ok {
	desc: WGPU_Compute_Pipeline_Descriptor

	when ODIN_DEBUG {
		c_label: String_View_Buffer
		if descriptor.label != "" {
			desc.label = init_string_buffer(&c_label, descriptor.label)
		}
	}

	if descriptor.layout != nil {
		desc.layout = descriptor.layout
	}

	if descriptor.module != nil {
		desc.compute.module = descriptor.module
	}

	c_entry_point: String_View_Buffer
	desc.compute.entry_point = init_string_buffer(&c_entry_point, descriptor.entry_point)

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	if len(descriptor.constants) > 0 {
		constants := make([]WGPU_Constant_Entry, len(descriptor.constants), context.temp_allocator)
		for &c, i in descriptor.constants {
			constants[i].key = init_string_buffer_owned(c.key, context.temp_allocator)
			constants[i].value = c.value
		}
		desc.compute.constant_count = len(constants)
		desc.compute.constants = raw_data(constants)
	}

	error_reset_data(loc)
	compute_pipeline = wgpuDeviceCreateComputePipeline(self, desc)
	if get_last_error() != nil {
		if compute_pipeline != nil {
			wgpuComputePipelineRelease(compute_pipeline)
		}
		return
	}

	return compute_pipeline, true
}

/* Creates a new `Buffer`. */
@(require_results)
device_create_buffer :: proc "contextless" (
	self: Device,
	descriptor: Buffer_Descriptor,
	loc := #caller_location,
) -> (
	buffer: Buffer,
	ok: bool,
) #optional_ok {
	raw_desc := WGPU_Buffer_Descriptor {
		usage              = descriptor.usage,
		size               = descriptor.size,
		mapped_at_creation = b32(descriptor.mapped_at_creation),
	}

	when ODIN_DEBUG {
		c_label: String_View_Buffer
		if descriptor.label != "" {
			raw_desc.label = init_string_buffer(&c_label, descriptor.label)
		}
	}

	error_reset_data(loc)
	buffer = wgpuDeviceCreateBuffer(self, raw_desc)
	if get_last_error() != nil {
		if buffer != nil {
			wgpuBufferRelease(buffer)
		}
		return
	}

	return buffer, true
}

/* Describes a `Buffer` when allocating. */
Buffer_Data_Descriptor :: struct {
	/* Debug label of a buffer. This will show up in graphics debuggers for easy identification. */
	label:    string,
	/* Contents of a buffer on creation. */
	contents: []byte,
	/* Usages of a buffer. If the buffer is used in any way that isn't specified here,
	the operation will panic. */
	usage:    Buffer_Usages,
}

Buffer_Init_Descriptor :: Buffer_Data_Descriptor

@(require_results)
device_create_buffer_with_data :: proc(
	self: Device,
	descriptor: Buffer_Data_Descriptor,
	loc := #caller_location,
) -> (
	buffer: Buffer,
	ok: bool,
) #optional_ok {
	// Skip mapping if the buffer is zero sized
	if descriptor.contents == nil || len(descriptor.contents) == 0 {
		buffer_descriptor: Buffer_Descriptor = {
			label              = descriptor.label,
			size               = 0,
			usage              = descriptor.usage,
			mapped_at_creation = false,
		}

		return device_create_buffer(self, buffer_descriptor, loc)
	}

	unpadded_size := cast(Buffer_Address)len(descriptor.contents)

	// Valid vulkan usage is
	// 1. buffer size must be a multiple of COPY_BUFFER_ALIGNMENT.
	// 2. buffer size must be greater than 0.
	// Therefore we round the value up to the nearest multiple, and ensure it's at least
	// COPY_BUFFER_ALIGNMENT.

	align_mask := COPY_BUFFER_ALIGNMENT_MASK
	padded_size := max(((unpadded_size + align_mask) & ~align_mask), COPY_BUFFER_ALIGNMENT)

	buffer_descriptor: Buffer_Descriptor = {
		label              = descriptor.label,
		size               = padded_size,
		usage              = descriptor.usage,
		mapped_at_creation = true,
	}

	buffer = device_create_buffer(self, buffer_descriptor, loc) or_return

	// Synchronously and immediately map a buffer for reading. If the buffer is not
	// immediately mappable through `mapped_at_creation` or
	// `buffer_map_async`, will panic.
	mapped_buffer_view := buffer_get_mapped_range_bytes(buffer, {0, padded_size}, loc) or_return
	copy(mapped_buffer_view.data, descriptor.contents)
	buffer_unmap(buffer, loc) or_return

	return buffer, true
}

device_create_buffer_init :: device_create_buffer_with_data

/*
Creates a new `Texture`.

`descriptor` specifies the general format of the texture.
*/
@(require_results)
device_create_texture :: proc "contextless" (
	self: Device,
	descriptor: Texture_Descriptor,
	loc := #caller_location,
) -> (
	texture: Texture,
	ok: bool,
) #optional_ok {
	raw_desc := WGPU_Texture_Descriptor {
		usage           = descriptor.usage,
		dimension       = descriptor.dimension,
		size            = descriptor.size,
		format          = descriptor.format,
		mip_level_count = descriptor.mip_level_count,
		sample_count    = descriptor.sample_count,
	}

	when ODIN_DEBUG {
		c_label: String_View_Buffer
		if descriptor.label != "" {
			raw_desc.label = init_string_buffer(&c_label, descriptor.label)
		}
	}

	view_format_count := uint(len(descriptor.view_formats))

	if view_format_count > 0 {
		raw_desc.view_format_count = view_format_count
		raw_desc.view_formats = raw_data(descriptor.view_formats)
	}

	error_reset_data(loc)
	texture = wgpuDeviceCreateTexture(self, raw_desc)
	if get_last_error() != nil {
		if texture != nil {
			wgpuTextureRelease(texture)
		}
		return
	}

	return texture, true
}

/*
Upload an entire texture and its mipmaps from a source buffer.

Expects all mipmaps to be tightly packed in the data buffer.

See `Texture_Data_Order` for the order in which the data is laid out in memory.

Implicitly adds the `COPY_DST` usage if it is not present in the descriptor,
as it is required to be able to upload the data to the gpu.
*/
@(require_results)
device_create_texture_with_data :: proc(
	self: Device,
	queue: Queue,
	desc: Texture_Descriptor,
	order: Texture_Data_Order,
	data: []byte,
	loc := #caller_location,
) -> (
	texture: Texture,
	ok: bool,
) #optional_ok {
	desc := desc

	// Implicitly add the .Copy_Dst usage
	if .Copy_Dst not_in desc.usage {
		desc.usage += {.Copy_Dst}
	}

	texture = device_create_texture(self, desc, loc) or_return
	defer if !ok {
		texture_release(texture)
	}

	// Will return 0 only if it's a combined depth-stencil format
	// If so, default to 4, validation will fail later anyway since the depth or stencil
	// aspect needs to be written to individually
	block_size := texture_format_block_size(desc.format)
	if block_size == 0 {
		block_size = 4
	}
	block_width, block_height := texture_format_block_dimensions(desc.format)
	layer_iterations := texture_descriptor_array_layer_count(desc)

	outer_iteration, inner_iteration: u32

	switch order {
	case .Layer_Major:
		outer_iteration = layer_iterations
		inner_iteration = desc.mip_level_count
	case .Mip_Major:
		outer_iteration = desc.mip_level_count
		inner_iteration = layer_iterations
	}

	binary_offset: u32 = 0
	for outer in 0 ..< outer_iteration {
		for inner in 0 ..< inner_iteration {
			layer, mip: u32
			switch order {
			case .Layer_Major:
				layer = outer
				mip = inner
			case .Mip_Major:
				layer = inner
				mip = outer
			}

			mip_size, mip_size_ok := texture_descriptor_mip_level_size(desc, mip)
			assert(mip_size_ok, "Invalid mip level")
			// if !mip_size_ok {
			// 	err = Error_Type.Validation
			// 	set_and_update_err_data(self._err_data, .Assert, err, "Invalid mip level", loc)
			// 	return
			// }

			// copying layers separately
			if desc.dimension != .D3 {
				mip_size.depth_or_array_layers = 1
			}

			// When uploading mips of compressed textures and the mip is supposed to be
			// a size that isn't a multiple of the block size, the mip needs to be uploaded
			// as its "physical size" which is the size rounded up to the nearest block size.
			mip_physical := extent_3d_physical_size(mip_size, desc.format)

			// All these calculations are performed on the physical size as that's the
			// data that exists in the buffer.
			width_blocks := mip_physical.width / block_width
			height_blocks := mip_physical.height / block_height

			bytes_per_row := width_blocks * block_size
			data_size := bytes_per_row * height_blocks * mip_size.depth_or_array_layers

			end_offset := binary_offset + data_size
			assert(end_offset <= u32(len(data)), "Buffer too small")
			// if end_offset > u32(len(data)) {
			// 	err = Error_Type.Validation
			// 	set_and_update_err_data(self._err_data, .Assert, err, "Buffer too small", loc)
			// 	return
			// }

			queue_write_texture(
				queue,
				{texture = texture, mip_level = mip, origin = {0, 0, layer}, aspect = .All},
				data[binary_offset:end_offset],
				{offset = 0, bytes_per_row = bytes_per_row, rows_per_image = height_blocks},
				mip_physical,
				loc,
			) or_return

			binary_offset = end_offset
		}
	}

	return texture, true
}

/*
Creates a new `Sampler`.

`descriptor` specifies the behavior of the sampler.
*/
@(require_results)
device_create_sampler :: proc "contextless" (
	self: Device,
	descriptor: Sampler_Descriptor = DEFAULT_SAMPLER_DESCRIPTOR,
	loc := #caller_location,
) -> (
	sampler: Sampler,
	ok: bool,
) #optional_ok {
	raw_desc := WGPU_Sampler_Descriptor {
		address_mode_u = descriptor.address_mode_u,
		address_mode_v = descriptor.address_mode_v,
		address_mode_w = descriptor.address_mode_w,
		mag_filter     = descriptor.mag_filter,
		min_filter     = descriptor.min_filter,
		mipmap_filter  = descriptor.mipmap_filter,
		lod_min_clamp  = descriptor.lod_min_clamp,
		lod_max_clamp  = descriptor.lod_max_clamp,
		compare        = descriptor.compare,
		max_anisotropy = descriptor.max_anisotropy,
	}

	when ODIN_DEBUG {
		c_label: String_View_Buffer
		if descriptor.label != "" {
			raw_desc.label = init_string_buffer(&c_label, descriptor.label)
		}
	}

	error_reset_data(loc)
	sampler = wgpuDeviceCreateSampler(self, raw_desc)
	if get_last_error() != nil {
		if sampler != nil {
			wgpuSamplerRelease(sampler)
		}
		return
	}

	return sampler, true
}

@(private)
WGPU_Query_Set_Descriptor_Extras :: struct {
	chain:                    Chained_Struct,
	pipeline_statistics:      [^]Pipeline_Statistics_Types,
	pipeline_statistic_count: uint,
}

/* Creates a new `Query_Set`. */
@(require_results)
device_create_query_set :: proc "contextless" (
	self: Device,
	descriptor: Query_Set_Descriptor,
	loc := #caller_location,
) -> (
	query_set: Query_Set,
	ok: bool,
) #optional_ok {
	desc: WGPU_Query_Set_Descriptor

	when ODIN_DEBUG {
		c_label: String_View_Buffer
		if descriptor.label != "" {
			desc.label = init_string_buffer(&c_label, descriptor.label)
		}
	}

	desc.count = descriptor.count

	extras: WGPU_Query_Set_Descriptor_Extras

	switch descriptor.type {
	case .Occlusion:
		desc.type = .Occlusion
	case .Timestamp:
		desc.type = .Timestamp
	case .Pipeline_Statistics:
		desc.type = .Pipeline_Statistics
		extras = {
			chain = {stype = .Query_Set_Descriptor_Extras},
			pipeline_statistic_count = len(descriptor.pipeline_statistics),
			pipeline_statistics = raw_data(descriptor.pipeline_statistics),
		}
		desc.next_in_chain = &extras.chain
	}

	error_reset_data(loc)
	query_set = wgpuDeviceCreateQuerySet(self, desc)
	if get_last_error() != nil {
		if query_set != nil {
			wgpuQuerySetRelease(query_set)
		}
		return
	}

	return query_set, true
}

/* Push an error scope. */
device_push_error_scope :: wgpuDevicePushErrorScope

/* Pop an error scope. */
device_pop_error_scope :: wgpuDevicePopErrorScope

/* Destroy this device. */
device_destroy :: wgpuDeviceDestroy

/* Get info about the requested adapter. */
device_adapter_info :: proc(
	self: Device,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	info: Adapter_Info,
	ok: bool,
) #optional_ok {
	raw_info := wgpuDeviceGetAdapterInfo(self)
	defer wgpuAdapterInfoFreeMembers(raw_info)
	fill_adapter_info(&info, &raw_info, allocator)
	return info, true
}

/* Get a handle to a command queue on the device. */
device_get_queue :: wgpuDeviceGetQueue

/* Sets a debug label for the given `Device`. */
@(disabled = !ODIN_DEBUG)
device_set_label :: proc "contextless" (self: Device, label: string) {
	c_label: String_View_Buffer
	wgpuDeviceSetLabel(self, init_string_buffer(&c_label, label))
}

// Increase the `Device` reference count.
device_add_ref :: wgpuDeviceAddRef

// Release the `Device` resources, use to decrease the reference count.
device_release :: wgpuDeviceRelease

/*
Safely releases the `Device` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
device_release_safe :: #force_inline proc(self: ^Device) {
	if self != nil && self^ != nil {
		wgpuDeviceRelease(self^)
		self^ = nil
	}
}

@(private)
WGPU_Primitive_Topology :: enum i32 {
	Undefined      = 0x00000000,
	Point_List     = 0x00000001,
	Line_List      = 0x00000002,
	Line_Strip     = 0x00000003,
	Triangle_List  = 0x00000004,
	Triangle_Strip = 0x00000005,
}

@(private)
WGPU_Primitive_State :: struct {
	next_in_chain:      ^Chained_Struct,
	topology:           WGPU_Primitive_Topology,
	strip_index_format: Index_Format,
	front_face:         Front_Face,
	cull_mode:          Face,
	unclipped_depth:    b32,
}
