package wgpu

// STD Library
import "base:runtime"
import "core:strings"

// The raw bindings
import wgpu "../bindings"

/*
Open connection to a graphics and/or compute device.

Responsible for the creation of most rendering and compute resources.
These are then used in commands, which are submitted to a `Queue`.

A device may be requested from an adapter with `adapter_request_device`.

Corresponds to [WebGPU `GPUDevice`](https://gpuweb.github.io/gpuweb/#gpu-device).
*/
Device :: wgpu.Device

/* Features that are supported and enabled on device creation. */
Device_Features :: distinct Features

/*
Describes the segment of a buffer to bind.

Corresponds to [WebGPU `GPUBufferBinding`](
https://gpuweb.github.io/gpuweb/#dictdef-gpubufferbinding).
*/
Buffer_Binding :: struct {
	buffer : Buffer,
	offset : u64,
	size   : u64,
}

/*
Resource that can be bound to a pipeline.

Corresponds to [WebGPU `GPUBindingResource`](
https://gpuweb.github.io/gpuweb/#typedefdef-gpubindingresource).
*/
Binding_Resource :: union {
	Buffer_Binding,
	[]Buffer,
	Sampler,
	[]Sampler,
	Texture_View,
	[]Texture_View,
}

/*
An element of a `Bind_Group_Descriptor`, consisting of a bindable resource
and the slot to bind it to.

Corresponds to [WebGPU `GPUBindGroupEntry`](
https://gpuweb.github.io/gpuweb/#dictdef-gpubindgroupentry).
*/
Bind_Group_Entry :: struct {
	binding  : u32,
	resource : Binding_Resource,
}

/*
Describes a group of bindings and the resources to be bound.

For use with `device_create_bind_group`.

Corresponds to [WebGPU `GPUBindGroupDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpubindgroupdescriptor).
*/
Bind_Group_Descriptor :: struct {
	label   : cstring,
	layout  : Bind_Group_Layout,
	entries : []Bind_Group_Entry,
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
) #optional_ok #no_bounds_check {
	desc: wgpu.Bind_Group_Descriptor
	desc.label = descriptor.label

	if descriptor.layout != nil {
		desc.layout = descriptor.layout
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	ta := context.temp_allocator

	extras: [dynamic]wgpu.Bind_Group_Entry_Extras
	extras.allocator = ta

	entry_count := uint(len(descriptor.entries))

	if entry_count > 0 {
		entries := make([]wgpu.Bind_Group_Entry, entry_count, ta)

		for &v, i in descriptor.entries {
			raw_entry := &entries[i]
			raw_entry.binding = v.binding
			raw_extra: ^wgpu.Bind_Group_Entry_Extras

			#partial switch &res in v.resource {
			case []Buffer, []Sampler, []Texture_View:
				append(
					&extras,
					wgpu.Bind_Group_Entry_Extras {
						stype = wgpu.SType(Native_SType.Bind_Group_Entry_Extras),
					},
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

	_error_reset_data(loc)

	bind_group = wgpu.device_create_bind_group(self, &desc)

	if get_last_error() != nil {
		if bind_group != nil {
			wgpu.bind_group_release(bind_group)
		}
		return
	}

	return bind_group, true
}

/*
Specific type of a binding.

For use in `Bind_Group_Layout_Entry`.

Corresponds to WebGPU's mutually exclusive fields within [`GPUBindGroupLayoutEntry`](
https://gpuweb.github.io/gpuweb/#dictdef-gpubindgrouplayoutentry).
*/
Binding_Type :: union {
	wgpu.Buffer_Binding_Layout,
	wgpu.Sampler_Binding_Layout,
	wgpu.Texture_Binding_Layout,
	wgpu.Storage_Texture_Binding_Layout,
}

/*
Describes the shader stages that a binding will be visible from.

These can be combined so something that is visible from both vertex and fragment shaders can
be defined as:

	flags := Shader_Stage_Flags{.Vertex, .Fragment}

Corresponds to [WebGPU `GPUShaderStageFlags`](
https://gpuweb.github.io/gpuweb/#typedefdef-gpushaderstageflags).
*/
Shader_Stage_Flags :: wgpu.Shader_Stage_Flags

/*
Describes a single binding inside a bind group.

Corresponds to [WebGPU `GPUBindGroupLayoutEntry`](
https://gpuweb.github.io/gpuweb/#dictdef-gpubindgrouplayoutentry).
*/
Bind_Group_Layout_Entry :: struct {
	binding    : u32,
	visibility : Shader_Stage_Flags,
	type       : Binding_Type,
	count      : Maybe(u32),
}

/*
Describes a `Bind_Group_Layout`.

For use with `device_create_bind_group_layout`.

Corresponds to [WebGPU `GPUBindGroupLayoutDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpubindgrouplayoutdescriptor).
*/
Bind_Group_Layout_Descriptor :: struct {
	label   : cstring,
	entries : []Bind_Group_Layout_Entry,
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
) #optional_ok #no_bounds_check {
	desc, desc_ok := descriptor.?

	if !desc_ok {
		_error_reset_data(loc)

		bind_group_layout = wgpu.device_create_bind_group_layout(self, nil)

		if get_last_error() != nil {
			if bind_group_layout != nil {
				wgpu.bind_group_layout_release(bind_group_layout)
			}
			return
		}

		return bind_group_layout, true
	}

	raw_desc: wgpu.Bind_Group_Layout_Descriptor
	raw_desc.label = desc.label

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	ta := context.temp_allocator

	extras: [dynamic]wgpu.Bind_Group_Layout_Entry_Extras
	extras.allocator = ta

	entry_count := uint(len(desc.entries))

	if entry_count > 0 {
		entries := make([]wgpu.Bind_Group_Layout_Entry, entry_count, ta)

		for &v, i in desc.entries {
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

			if count, count_ok := v.count.?; count_ok {
				append(
					&extras,
					wgpu.Bind_Group_Layout_Entry_Extras {
						stype = wgpu.SType(wgpu.Native_SType.Bind_Group_Layout_Entry_Extras),
						count = count,
					},
				)
				raw_entry.next_in_chain = &extras[len(extras) - 1].chain
			}
		}

		raw_desc.entry_count = entry_count
		raw_desc.entries = raw_data(entries)
	}

	_error_reset_data(loc)

	bind_group_layout = wgpu.device_create_bind_group_layout(self, &raw_desc)

	if get_last_error() != nil {
		if bind_group_layout != nil {
			wgpu.bind_group_layout_release(bind_group_layout)
		}
		return
	}

	return bind_group_layout, true
}

/*
Describes a `Buffer`.

For use with `device_create_buffer`.

Corresponds to [WebGPU `GPUBufferDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpubufferdescriptor).
*/
Buffer_Descriptor :: wgpu.Buffer_Descriptor

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
	_error_reset_data(loc)

	descriptor := descriptor
	buffer = wgpu.device_create_buffer(self, &descriptor)

	if get_last_error() != nil {
		if buffer != nil {
			wgpu.buffer_release(buffer)
		}
		return
	}

	return buffer, true
}

/*
Describes a `Command_Encoder`.

For use with `device_create_command_encoder`.

Corresponds to [WebGPU `GPUCommandEncoderDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpucommandencoderdescriptor).
*/
Command_Encoder_Descriptor :: wgpu.Command_Encoder_Descriptor

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
	_error_reset_data(loc)

	descriptor := descriptor
	command_encoder = wgpu.device_create_command_encoder(self, &descriptor.? or_else nil)

	if get_last_error() != nil {
		if command_encoder != nil {
			wgpu.command_encoder_release(command_encoder)
		}
		return
	}

	return command_encoder, true
}

/*
Describes a compute pipeline.

For use with `device_create_compute_pipeline`.

Corresponds to [WebGPU `GPUComputePipelineDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpucomputepipelinedescriptor).
*/
Compute_Pipeline_Descriptor :: struct {
	label       : cstring,
	layout      : Pipeline_Layout,
	module      : Shader_Module,
	entry_point : cstring,
	constants   : []Constant_Entry,
}

/* Creates a new `Compute_Pipeline`. */
@(require_results)
device_create_compute_pipeline :: proc "contextless" (
	self: Device,
	descriptor: Compute_Pipeline_Descriptor,
	loc := #caller_location,
) -> (
	compute_pipeline: Compute_Pipeline,
	ok: bool,
) #optional_ok {
	desc: wgpu.Compute_Pipeline_Descriptor
	desc.label = descriptor.label

	if descriptor.layout != nil {
		desc.layout = descriptor.layout
	}

	if descriptor.module != nil {
		desc.compute.module = descriptor.module
	}

	desc.compute.entry_point = descriptor.entry_point

	if len(descriptor.constants) > 0 {
		desc.compute.constant_count = len(descriptor.constants)
		desc.compute.constants = raw_data(descriptor.constants)
	}

	_error_reset_data(loc)

	compute_pipeline = wgpu.device_create_compute_pipeline(self, &desc)

	if get_last_error() != nil {
		if compute_pipeline != nil {
			wgpu.compute_pipeline_release(compute_pipeline)
		}
		return
	}

	return compute_pipeline, true
}

/* A range of push constant memory to pass to a shader stage. */
Push_Constant_Range :: struct {
	stages : Shader_Stage_Flags,
	range  : Range(u32),
}

/*
Describes a `Pipeline_Layout`.

For use with `device_create_pipeline_layout`.

Corresponds to [WebGPU `GPUPipelineLayoutDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpupipelinelayoutdescriptor).
*/
Pipeline_Layout_Descriptor :: struct {
	label                : cstring,
	bind_group_layouts   : []Bind_Group_Layout,
	push_constant_ranges : []Push_Constant_Range,
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
	desc: wgpu.Pipeline_Layout_Descriptor
	desc.label = descriptor.label

	if len(descriptor.bind_group_layouts) > 0 {
		desc.bind_group_layout_count = len(descriptor.bind_group_layouts)
		desc.bind_group_layouts = raw_data(descriptor.bind_group_layouts)
	}

	extras: wgpu.Pipeline_Layout_Extras

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	push_constant_range_count := len(descriptor.push_constant_ranges)

	if push_constant_range_count > 0 {
		push_constant_ranges := make(
			[]wgpu.Push_Constant_Range,
			push_constant_range_count,
			context.temp_allocator,
		)

		for &r, i in descriptor.push_constant_ranges {
			raw_range := &push_constant_ranges[i]
			raw_range.stages = r.stages
			raw_range.start = r.range.start
			raw_range.end = r.range.end
		}

		extras.stype = wgpu.SType(wgpu.Native_SType.Pipeline_Layout_Extras)
		extras.push_constant_range_count = uint(push_constant_range_count)
		extras.push_constant_ranges = raw_data(push_constant_ranges)
		desc.next_in_chain = &extras.chain
	}

	_error_reset_data(loc)

	pipeline_layout = wgpu.device_create_pipeline_layout(self, &desc)

	if get_last_error() != nil {
		if pipeline_layout != nil {
			wgpu.pipeline_layout_release(pipeline_layout)
		}
		return
	}

	return pipeline_layout, true
}

/*
Type of query contained in a `Query_Set`.

Corresponds to [WebGPU `GPUQueryType`](
https://gpuweb.github.io/gpuweb/#enumdef-gpuquerytype).
*/
Query_Type :: enum ENUM_SIZE {
	Occlusion           = 0,
	Timestamp           = 1,
	Pipeline_Statistics = 0x00030000, /* Extras */
}

/*
Describes a [`Query_Set`].

For use with [`device_create_query_set`].

Corresponds to [WebGPU `GPUQuerySetDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuquerysetdescriptor).
*/
Query_Set_Descriptor :: struct {
	label               : cstring,
	type                : Query_Type,
	count               : u32,
	pipeline_statistics : []wgpu.Pipeline_Statistic_Name, /* Extras */
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
	desc: wgpu.Query_Set_Descriptor

	desc.label = descriptor.label
	desc.count = descriptor.count

	extras: wgpu.Query_Set_Descriptor_Extras

	switch descriptor.type {
	case .Occlusion:
		desc.type = .Occlusion
	case .Timestamp:
		desc.type = .Timestamp
	case .Pipeline_Statistics:
		desc.type = cast(wgpu.Query_Type)wgpu.Native_Query_Type.Pipeline_Statistics
		extras.stype = wgpu.SType(wgpu.Native_SType.Query_Set_Descriptor_Extras)
		extras.pipeline_statistic_count = len(descriptor.pipeline_statistics)
		extras.pipeline_statistics = raw_data(descriptor.pipeline_statistics)
		desc.next_in_chain = &extras.chain
	}

	_error_reset_data(loc)

	query_set = wgpu.device_create_query_set(self, &desc)

	if get_last_error() != nil {
		if query_set != nil {
			wgpu.query_set_release(query_set)
		}
		return
	}

	return query_set, true
}

/*
Describes a `Render_Bundle`.

For use with `render_bundle_encoder_finish`.

Corresponds to [WebGPU `GPURenderBundleDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpurenderbundledescriptor).
*/
Render_Bundle_Encoder_Descriptor :: struct {
	label                : cstring,
	color_formats        : []Texture_Format,
	depth_stencil_format : Texture_Format,
	sample_count         : u32,
	depth_read_only      : bool,
	stencil_read_only    : bool,
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
	desc: wgpu.Render_Bundle_Encoder_Descriptor
	desc.label = descriptor.label

	color_format_count := uint(len(descriptor.color_formats))

	if color_format_count > 0 {
		desc.color_format_count = color_format_count
		desc.color_formats = raw_data(descriptor.color_formats)
	}

	desc.depth_stencil_format = descriptor.depth_stencil_format
	desc.sample_count = descriptor.sample_count
	desc.depth_read_only = b32(descriptor.depth_read_only)
	desc.stencil_read_only = b32(descriptor.stencil_read_only)

	_error_reset_data(loc)

	render_bundle_encoder = wgpu.device_create_render_bundle_encoder(self, &desc)

	if get_last_error() != nil {
		if render_bundle_encoder != nil {
			wgpu.render_bundle_encoder_release(render_bundle_encoder)
		}
		return
	}

	return render_bundle_encoder, true
}

/*
Describes how the vertex buffer is interpreted.

For use in [`VertexState`].

Corresponds to [WebGPU `GPUVertexBufferLayout`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuvertexbufferlayout).
*/
Vertex_Buffer_Layout :: struct {
	array_stride : u64,
	step_mode    : Vertex_Step_Mode,
	attributes   : []Vertex_Attribute,
}

/*
Describes the vertex processing in a render pipeline.

For use in [`RenderPipelineDescriptor`].

Corresponds to [WebGPU `GPUVertexState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuvertexstate).
*/
Vertex_State :: struct {
	module      : Shader_Module,
	entry_point : cstring,
	constants   : []Constant_Entry,
	buffers     : []Vertex_Buffer_Layout,
}

/*
Describes the fragment processing in a render pipeline.

For use in [`RenderPipelineDescriptor`].

Corresponds to [WebGPU `GPUFragmentState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpufragmentstate).
*/
Fragment_State :: struct {
	module      : Shader_Module,
	entry_point : cstring,
	constants   : []Constant_Entry,
	targets     : []Color_Target_State,
}

/*
Primitive type the input mesh is composed of.

Corresponds to [WebGPU `GPUPrimitiveTopology`](
https://gpuweb.github.io/gpuweb/#enumdef-gpuprimitivetopology).
*/
Primitive_Topology :: enum {
	Triangle_List, // Default here, not in wgpu
	Point_List,
	Line_List,
	Line_Strip,
	Triangle_Strip,
}

/*
Vertex winding order which classifies the "front" face of a triangle.

Corresponds to [WebGPU `GPUFrontFace`](
https://gpuweb.github.io/gpuweb/#enumdef-gpufrontface).
*/
Front_Face :: wgpu.Front_Face

/*
Face of a vertex.

Corresponds to [WebGPU `GPUCullMode`](
https://gpuweb.github.io/gpuweb/#enumdef-gpucullmode).
*/
Face :: wgpu.Cull_Mode

/*
Describes the state of primitive assembly and rasterization in a render pipeline.

Corresponds to [WebGPU `GPUPrimitiveState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuprimitivestate).
*/
Primitive_State :: struct {
	topology           : Primitive_Topology,
	strip_index_format : Index_Format,
	front_face         : Front_Face,
	cull_mode          : Face,
}

/*
Describes a render (graphics) pipeline.

For use with `device_create_render_pipeline`.

Corresponds to [WebGPU `GPURenderPipelineDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpurenderpipelinedescriptor).
*/
Render_Pipeline_Descriptor :: struct {
	label         : cstring,
	layout        : Pipeline_Layout,
	vertex        : Vertex_State,
	primitive     : Primitive_State,
	depth_stencil : ^Depth_Stencil_State,
	multisample   : Multisample_State,
	fragment      : ^Fragment_State,
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
	desc: wgpu.Render_Pipeline_Descriptor
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

	vertex_buffer_count := uint(len(descriptor.vertex.buffers))

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	if vertex_buffer_count > 0 {
		vertex_buffers := make(
			[]wgpu.Vertex_Buffer_Layout,
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

	fragment: wgpu.Fragment_State

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

		desc.fragment = &fragment
	}

	_error_reset_data(loc)

	render_pipeline = wgpu.device_create_render_pipeline(self, &desc)

	if get_last_error() != nil {
		if render_pipeline != nil {
			wgpu.render_pipeline_release(render_pipeline)
		}
		return
	}

	return render_pipeline, true
}

/* Creates a new `Sampler`. */
@(require_results)
device_create_sampler :: proc "contextless" (
	self: Device,
	descriptor: Sampler_Descriptor = DEFAULT_SAMPLER_DESCRIPTOR,
	loc := #caller_location,
) -> (
	sampler: Sampler,
	ok: bool,
) #optional_ok {
	_error_reset_data(loc)

	descriptor := descriptor
	sampler = wgpu.device_create_sampler(self, &descriptor)

	if get_last_error() != nil {
		if sampler != nil {
			wgpu.sampler_release(sampler)
		}
		return
	}

	return sampler, true
}

// Creates a shader module from either `SPIR-V` or `WGSL` source code.
@(require_results)
device_create_shader_module :: proc(
	self: Device,
	descriptor: Shader_Module_Descriptor,
	loc := #caller_location,
) -> (
	shader_module: Shader_Module,
	ok: bool,
) #optional_ok {
	desc: wgpu.Shader_Module_Descriptor
	desc.label = descriptor.label

	_error_reset_data(loc)

	switch &source in descriptor.source {
	case string:
		runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

		wgsl := wgpu.Shader_Module_WGSL_Descriptor {
			chain = {next = nil, stype = .Shader_Module_WGSL_Descriptor},
			code = strings.clone_to_cstring(source, context.temp_allocator),
		}

		desc.next_in_chain = &wgsl.chain

		shader_module = wgpu.device_create_shader_module(self, &desc)
	case cstring:
		wgsl := wgpu.Shader_Module_WGSL_Descriptor {
			chain = {next = nil, stype = .Shader_Module_WGSL_Descriptor},
			code = source,
		}

		desc.next_in_chain = &wgsl.chain

		shader_module = wgpu.device_create_shader_module(self, &desc)
	case []u32:
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

		shader_module = wgpu.device_create_shader_module(self, &desc)
	}

	if get_last_error() != nil {
		if shader_module != nil {
			wgpu.shader_module_release(shader_module)
		}
		return
	}

	return shader_module, true
}

/*
Describes a `Texture`.

For use with `device_create_texture`.

Corresponds to [WebGPU `GPUTextureDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gputexturedescriptor).
*/
Texture_Descriptor :: struct {
	label           : cstring,
	usage           : Texture_Usage_Flags,
	dimension       : Texture_Dimension,
	size            : Extent_3D,
	format          : Texture_Format,
	mip_level_count : u32,
	sample_count    : u32,
	view_formats    : []Texture_Format,
}

/*  Creates a new `Texture`. */
@(require_results)
device_create_texture :: proc "contextless" (
	self: Device,
	descriptor: Texture_Descriptor,
	loc := #caller_location,
) -> (
	texture: Texture,
	ok: bool,
) #optional_ok {
	desc: wgpu.Texture_Descriptor

	desc.label           = descriptor.label
	desc.usage           = descriptor.usage
	desc.dimension       = descriptor.dimension
	desc.size            = descriptor.size
	desc.format          = descriptor.format
	desc.mip_level_count = descriptor.mip_level_count
	desc.sample_count    = descriptor.sample_count

	view_format_count := uint(len(descriptor.view_formats))

	if view_format_count > 0 {
		desc.view_format_count = view_format_count
		desc.view_formats      = raw_data(descriptor.view_formats)
	}

	_error_reset_data(loc)

	texture = wgpu.device_create_texture(self, &desc)

	if get_last_error() != nil {
		if texture != nil {
			wgpu.texture_release(texture)
		}
		return
	}

	return texture, true
}

/* Destroy the device immediately. */
device_destroy :: wgpu.device_destroy

/*
List all features that may be used with this device.

Functions may panic if you use unsupported features.
*/
device_get_features :: proc "contextless" (
	self: Device,
) -> (
	features: Device_Features,
) #no_bounds_check {
	count := wgpu.device_enumerate_features(self, nil)
	if count == 0 do return

	raw_features: [MAX_FEATURES]wgpu.Feature_Name

	wgpu.device_enumerate_features(self, raw_data(raw_features[:count]))

	features = cast(Device_Features)features_slice_to_flags(raw_features[:count])

	return
}

/*
List all limits that were requested of this device.

If any of these limits are exceeded, functions may panic.
*/
device_get_limits :: proc "contextless" (
	self: Device,
	loc := #caller_location,
) -> (
	limits: Limits,
	ok: bool,
) #optional_ok {
	native := Supported_Limits_Extras {
		stype = SType(Native_SType.Supported_Limits_Extras),
	}

	supported := Supported_Limits {
		next_in_chain = &native.chain,
	}

	_error_reset_data(loc)

	ok = bool(wgpu.device_get_limits(self, &supported))

	if get_last_error() != nil {
		return
	}

	if !ok {
		error_update_data(Error_Type.Unknown, "Failed to fill device limits")
		return
	}

	limits = limits_merge_webgpu_with_native(supported.limits, native.limits)

	// Set minimum values for all limits even if the supported values are lower
	limits_ensure_minimum(&limits, minimum = DOWNLEVEL_WEBGL2_LIMITS)

	return limits, true
}

/* Get a handle to a command queue on the device. */
device_get_queue :: wgpu.device_get_queue

/* Check if device support all features in the given flags. */
device_has_feature :: proc "contextless" (self: Device, features: Features) -> bool {
	if features == {} do return true
	available := device_get_features(self)
	if available == {} do return false
	for f in features {
		if f not_in available || f == .Undefined do return false
	}
	return true
}

/* Check if device support the given feature name. */
device_has_feature_name :: proc "contextless" (self: Device, feature: Feature_Name) -> bool {
	return device_has_feature(self, {feature})
}

device_pop_error_scope :: wgpu.device_pop_error_scope

device_push_error_scope :: wgpu.device_push_error_scope

/* Set debug label. */
device_set_label :: proc "contextless" (self: Device, label: cstring) {
	wgpu.device_set_label(self, label)
}

// Increase the reference count.
device_reference :: wgpu.device_reference


// Release the `Device` and delete internal objects.
device_release :: wgpu.device_release

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
	wrapped_submission_index: ^Wrapped_Submission_Index = nil,
	loc := #caller_location,
) -> (
	result: bool,
	ok: bool,
) #optional_ok {
	_error_reset_data(loc)
	result = bool(wgpu.device_poll(self, b32(wait), wrapped_submission_index))
	ok = get_last_error() == nil
	return
}
