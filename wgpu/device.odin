package wgpu

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

/* Features that are supported and enabled on device creation. */
DeviceFeatures :: distinct Features

/*
Describes the segment of a buffer to bind.

Corresponds to [WebGPU `GPUBufferBinding`](
https://gpuweb.github.io/gpuweb/#dictdef-gpubufferbinding).
*/
BufferBinding :: struct {
	buffer: Buffer,
	offset: u64,
	size:   u64,
}

/*
Resource that can be bound to a pipeline.

Corresponds to [WebGPU `GPUBindingResource`](
https://gpuweb.github.io/gpuweb/#typedefdef-gpubindingresource).
*/
BindingResource :: union {
	BufferBinding,
	Sampler,
	TextureView,
	[]Buffer,
	[]Sampler,
	[]TextureView,
}

/*
An element of a `BindGroupDescriptor`, consisting of a bindable resource
and the slot to bind it to.

Corresponds to [WebGPU `GPUBindGroupEntry`](
https://gpuweb.github.io/gpuweb/#dictdef-gpubindgroupentry).
*/
BindGroupEntry :: struct {
	binding:  u32,
	resource: BindingResource,
}

/*
Describes a group of bindings and the resources to be bound.

For use with `device_create_bind_group`.

Corresponds to [WebGPU `GPUBindGroupDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpubindgroupdescriptor).
*/
BindGroupDescriptor :: struct {
	label:   string,
	layout:  BindGroupLayout,
	entries: []BindGroupEntry,
}

/* Creates a new `BindGroup`. */
@(require_results)
device_create_bind_group :: proc(
	self: Device,
	descriptor: BindGroupDescriptor,
	loc := #caller_location,
) -> (
	bind_group: BindGroup,
	ok: bool,
) #no_bounds_check #optional_ok {
	desc: WGPUBindGroupDescriptor

	when ODIN_DEBUG {
		c_label: StringViewBuffer
		if descriptor.label != "" {
			desc.label = init_string_buffer(&c_label, descriptor.label)
		}
	}

	desc.layout = descriptor.layout

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	ta := context.temp_allocator

	extras: [dynamic]BindGroupEntryExtras
	extras.allocator = ta

	entry_count := uint(len(descriptor.entries))

	if entry_count > 0 {
		entries := make([]WGPUBindGroupEntry, entry_count, ta)

		for &v, i in descriptor.entries {
			raw_entry := &entries[i]
			raw_entry.binding = v.binding
			raw_extra: ^BindGroupEntryExtras

			#partial switch &res in v.resource {
			case []Buffer, []Sampler, []TextureView:
				append(&extras, BindGroupEntryExtras{chain = {stype = .BindGroupEntryExtras}})
				raw_extra = &extras[len(extras) - 1]
			}

			switch &res in v.resource {
			case BufferBinding:
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
			case TextureView:
				raw_entry.texture_view = res
			case []TextureView:
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

/*
Specific type of a binding.

For use in `BindGroupLayoutEntry`.

Corresponds to WebGPU's mutually exclusive fields within [`GPUBindGroupLayoutEntry`](
https://gpuweb.github.io/gpuweb/#dictdef-gpubindgrouplayoutentry).
*/
BindingType :: union {
	BufferBindingLayout,
	SamplerBindingLayout,
	TextureBindingLayout,
	StorageTextureBindingLayout,
}

/*
Describes a single binding inside a bind group.

Corresponds to [WebGPU `GPUBindGroupLayoutEntry`](
https://gpuweb.github.io/gpuweb/#dictdef-gpubindgrouplayoutentry).
*/
BindGroupLayoutEntry :: struct {
	binding:    u32,
	visibility: ShaderStage,
	type:       BindingType,
	count:      u32,
}

/*
Describes a `BindGroupLayout`.

For use with `device_create_bind_group_layout`.

Corresponds to [WebGPU `GPUBindGroupLayoutDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpubindgrouplayoutdescriptor).
*/
BindGroupLayoutDescriptor :: struct {
	label:   string,
	entries: []BindGroupLayoutEntry,
}

/* Creates a new `BindGroupLayout`. */
@(require_results)
device_create_bind_group_layout :: proc(
	self: Device,
	descriptor: Maybe(BindGroupLayoutDescriptor) = nil,
	loc := #caller_location,
) -> (
	bind_group_layout: BindGroupLayout,
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

	raw_desc: WGPUBindGroupLayoutDescriptor

	when ODIN_DEBUG {
		c_label: StringViewBuffer
		if desc.label != "" {
			raw_desc.label = init_string_buffer(&c_label, desc.label)
		}
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	ta := context.temp_allocator

	extras: [dynamic]BindGroupLayoutEntryExtras
	extras.allocator = ta

	entry_count := uint(len(desc.entries))

	if entry_count > 0 {
		entries := make([]WGPUBindGroupLayoutEntry, entry_count, ta)

		for &v, i in desc.entries {
			raw_entry := &entries[i]

			raw_entry.binding = v.binding
			raw_entry.visibility = v.visibility

			switch e in v.type {
			case BufferBindingLayout:
				raw_entry.buffer = e
			case SamplerBindingLayout:
				raw_entry.sampler = e
			case TextureBindingLayout:
				raw_entry.texture = e
			case StorageTextureBindingLayout:
				raw_entry.storage_texture = e
			}

			if v.count > 0 {
				append(
					&extras,
					BindGroupLayoutEntryExtras {
						chain = {stype = .BindGroupLayoutEntryExtras},
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

BufferDescriptor :: struct {
	label:              string,
	usage:              BufferUsage,
	size:               u64,
	mapped_at_creation: bool,
}

/* Creates a new `Buffer`. */
@(require_results)
device_create_buffer :: proc "contextless" (
	self: Device,
	descriptor: BufferDescriptor,
	loc := #caller_location,
) -> (
	buffer: Buffer,
	ok: bool,
) #optional_ok {
	raw_desc := WGPUBufferDescriptor {
		usage              = descriptor.usage,
		size               = descriptor.size,
		mapped_at_creation = b32(descriptor.mapped_at_creation),
	}

	when ODIN_DEBUG {
		c_label: StringViewBuffer
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

CommandEncoderDescriptor :: struct {
	label: string,
}

/* Creates an empty `CommandEncoder`. */
@(require_results)
device_create_command_encoder :: proc "contextless" (
	self: Device,
	descriptor: Maybe(CommandEncoderDescriptor) = nil,
	loc := #caller_location,
) -> (
	command_encoder: CommandEncoder,
	ok: bool,
) #optional_ok {
	error_reset_data(loc)

	if desc, desc_ok := descriptor.?; desc_ok {
		raw_desc := WGPUCommandEncoderDescriptor{}

		when ODIN_DEBUG {
			c_label: StringViewBuffer
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

/*
Describes a compute pipeline.

For use with `device_create_compute_pipeline`.

Corresponds to [WebGPU `GPUComputePipelineDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpucomputepipelinedescriptor).
*/
ComputePipelineDescriptor :: struct {
	label:       string,
	layout:      PipelineLayout,
	module:      ShaderModule,
	entry_point: string,
	constants:   []ConstantEntry,
}

/* Creates a new `ComputePipeline`. */
@(require_results)
device_create_compute_pipeline :: proc "contextless" (
	self: Device,
	descriptor: ComputePipelineDescriptor,
	loc := #caller_location,
) -> (
	compute_pipeline: ComputePipeline,
	ok: bool,
) #optional_ok {
	desc: WGPUComputePipelineDescriptor

	when ODIN_DEBUG {
		c_label: StringViewBuffer
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

	c_entry_point: StringViewBuffer
	desc.compute.entry_point = init_string_buffer(&c_entry_point, descriptor.entry_point)

	if len(descriptor.constants) > 0 {
		desc.compute.constant_count = len(descriptor.constants)
		desc.compute.constants = raw_data(descriptor.constants)
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

/* A range of push constant memory to pass to a shader stage. */
PushConstantRange :: struct {
	stages: ShaderStage,
	range:  Range(u32),
}

/*
Describes a `PipelineLayout`.

For use with `device_create_pipeline_layout`.

Corresponds to [WebGPU `GPUPipelineLayoutDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpupipelinelayoutdescriptor).
*/
PipelineLayoutDescriptor :: struct {
	label:                string,
	bind_group_layouts:   []BindGroupLayout,
	push_constant_ranges: []PushConstantRange,
}

/* Creates a `PipelineLayout`. */
@(require_results)
device_create_pipeline_layout :: proc(
	self: Device,
	descriptor: PipelineLayoutDescriptor,
	loc := #caller_location,
) -> (
	pipeline_layout: PipelineLayout,
	ok: bool,
) #optional_ok {
	desc: WGPUPipelineLayoutDescriptor

	when ODIN_DEBUG {
		c_label: StringViewBuffer
		if descriptor.label != "" {
			desc.label = init_string_buffer(&c_label, descriptor.label)
		}
	}

	if len(descriptor.bind_group_layouts) > 0 {
		desc.bind_group_layout_count = len(descriptor.bind_group_layouts)
		desc.bind_group_layouts = raw_data(descriptor.bind_group_layouts)
	}

	extras: PipelineLayoutExtras

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	push_constant_range_count := len(descriptor.push_constant_ranges)

	if push_constant_range_count > 0 {
		push_constant_ranges := make(
			[]WGPUPushConstantRange,
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
			chain = {stype = .PipelineLayoutExtras},
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

/*
Describes a [`QuerySet`].

For use with [`device_create_query_set`].

Corresponds to [WebGPU `GPUQuerySetDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuquerysetdescriptor).
*/
QuerySetDescriptor :: struct {
	label:               string,
	type:                QueryType,
	count:               u32,
	pipeline_statistics: []PipelineStatisticName, /* Extras */
}

/* Creates a new `QuerySet`. */
@(require_results)
device_create_query_set :: proc "contextless" (
	self: Device,
	descriptor: QuerySetDescriptor,
	loc := #caller_location,
) -> (
	query_set: QuerySet,
	ok: bool,
) #optional_ok {
	desc: WGPUQuerySetDescriptor

	when ODIN_DEBUG {
		c_label: StringViewBuffer
		if descriptor.label != "" {
			desc.label = init_string_buffer(&c_label, descriptor.label)
		}
	}

	desc.count = descriptor.count

	extras: QuerySetDescriptorExtras

	switch descriptor.type {
	case .Occlusion:
		desc.type = .Occlusion
	case .Timestamp:
		desc.type = .Timestamp
	case .PipelineStatistics:
		desc.type = .PipelineStatistics
		extras = {
			chain = {stype = .QuerySetDescriptorExtras},
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

/*
Describes a `RenderBundle`.

For use with `render_bundle_encoder_finish`.

Corresponds to [WebGPU `GPURenderBundleDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpurenderbundledescriptor).
*/
RenderBundleEncoderDescriptor :: struct {
	label:                string,
	color_formats:        []TextureFormat,
	depth_stencil_format: TextureFormat,
	sample_count:         u32,
	depth_read_only:      bool,
	stencil_read_only:    bool,
}

/* Creates an empty `RenderBundleEncoder`. */
@(require_results)
device_create_render_bundle_encoder :: proc "contextless" (
	self: Device,
	descriptor: RenderBundleEncoderDescriptor,
	loc := #caller_location,
) -> (
	render_bundle_encoder: RenderBundleEncoder,
	ok: bool,
) #optional_ok {
	desc: WGPURenderBundleEncoderDescriptor

	when ODIN_DEBUG {
		c_label: StringViewBuffer
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

/*
Describes how the vertex buffer is interpreted.

For use in [`VertexState`].

Corresponds to [WebGPU `GPUVertexBufferLayout`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuvertexbufferlayout).
*/
VertexBufferLayout :: struct {
	array_stride: u64,
	step_mode:    VertexStepMode,
	attributes:   []VertexAttribute,
}

/*
Describes the vertex processing in a render pipeline.

For use in [`RenderPipelineDescriptor`].

Corresponds to [WebGPU `GPUVertexState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuvertexstate).
*/
VertexState :: struct {
	module:      ShaderModule,
	entry_point: string,
	constants:   []ConstantEntry,
	buffers:     []VertexBufferLayout,
}

/*
Describes the fragment processing in a render pipeline.

For use in [`RenderPipelineDescriptor`].

Corresponds to [WebGPU `GPUFragmentState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpufragmentstate).
*/
FragmentState :: struct {
	module:      ShaderModule,
	entry_point: string,
	constants:   []ConstantEntry,
	targets:     []ColorTargetState,
}

/*
Primitive type the input mesh is composed of.

Corresponds to [WebGPU `GPUPrimitiveTopology`](
https://gpuweb.github.io/gpuweb/#enumdef-gpuprimitivetopology).
*/
PrimitiveTopology :: enum {
	TriangleList, // Default here, not in wgpu
	PointList,
	LineList,
	LineStrip,
	TriangleStrip,
}

/*
Describes the state of primitive assembly and rasterization in a render pipeline.

Corresponds to [WebGPU `GPUPrimitiveState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuprimitivestate).
*/
PrimitiveState :: struct {
	topology:           PrimitiveTopology,
	strip_index_format: IndexFormat,
	front_face:         FrontFace,
	cull_mode:          Face,
	unclipped_depth:    bool,
}

/*
Describes a render (graphics) pipeline.

For use with `device_create_render_pipeline`.

Corresponds to [WebGPU `GPURenderPipelineDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpurenderpipelinedescriptor).
*/
RenderPipelineDescriptor :: struct {
	label:         string,
	layout:        PipelineLayout,
	vertex:        VertexState,
	primitive:     PrimitiveState,
	depth_stencil: ^DepthStencilState,
	multisample:   MultisampleState,
	fragment:      ^FragmentState,
}

/* Creates a `RenderPipeline`. */
@(require_results)
device_create_render_pipeline :: proc(
	self: Device,
	descriptor: RenderPipelineDescriptor,
	loc := #caller_location,
) -> (
	render_pipeline: RenderPipeline,
	ok: bool,
) #optional_ok {
	desc: WGPURenderPipelineDescriptor

	when ODIN_DEBUG {
		c_label: StringViewBuffer
		if descriptor.label != "" {
			desc.label = init_string_buffer(&c_label, descriptor.label)
		}
	}

	desc.layout = descriptor.layout

	desc.vertex.module = descriptor.vertex.module

	c_vertex_entry_point: StringViewBuffer
	desc.vertex.entry_point = init_string_buffer(
		&c_vertex_entry_point,
		descriptor.vertex.entry_point,
	)

	if len(descriptor.vertex.constants) > 0 {
		desc.vertex.constant_count = len(descriptor.vertex.constants)
		desc.vertex.constants = raw_data(descriptor.vertex.constants)
	}

	vertex_buffer_count := uint(len(descriptor.vertex.buffers))

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	if vertex_buffer_count > 0 {
		vertex_buffers := make(
			[]WGPUVertexBufferLayout,
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
		unclipped_depth    = b32(descriptor.primitive.unclipped_depth),
	}

	// Because everything in Odin by default is set to 0, the default PrimitiveTopology
	// enum value is `Point_List`. We make `TriangleList` default value by creating a
	// new enum, but here we set the correct/expected wgpu value:
	switch descriptor.primitive.topology {
	case .TriangleList:
		desc.primitive.topology = WGPUPrimitiveTopology.TriangleList
	case .PointList:
		desc.primitive.topology = WGPUPrimitiveTopology.PointList
	case .LineList:
		desc.primitive.topology = WGPUPrimitiveTopology.LineList
	case .LineStrip:
		desc.primitive.topology = WGPUPrimitiveTopology.LineStrip
	case .TriangleStrip:
		desc.primitive.topology = WGPUPrimitiveTopology.TriangleStrip
	}

	desc.depth_stencil = descriptor.depth_stencil

	desc.multisample = descriptor.multisample

	// Multisample count cannot be 0, defaulting to 1
	if desc.multisample.count == 0 {
		desc.multisample.count = 1
	}

	fragment: WGPUFragmentState
	c_fragment_entry_point: StringViewBuffer

	if descriptor.fragment != nil {
		fragment.module = descriptor.fragment.module

		fragment.entry_point = init_string_buffer(
			&c_fragment_entry_point,
			descriptor.fragment.entry_point,
		)

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

	error_reset_data(loc)
	render_pipeline = wgpuDeviceCreateRenderPipeline(self, desc)
	if get_last_error() != nil {
		if render_pipeline != nil {
			wgpuRenderPipelineRelease(render_pipeline)
		}
		return
	}

	return render_pipeline, true
}

SamplerDescriptor :: struct {
	label:          string,
	address_mode_u: AddressMode,
	address_mode_v: AddressMode,
	address_mode_w: AddressMode,
	mag_filter:     FilterMode,
	min_filter:     FilterMode,
	mipmap_filter:  MipmapFilterMode,
	lod_min_clamp:  f32,
	lod_max_clamp:  f32,
	compare:        CompareFunction,
	max_anisotropy: u16,
}

DEFAULT_SAMPLER_DESCRIPTOR :: SamplerDescriptor {
	address_mode_u = .ClampToEdge,
	address_mode_v = .ClampToEdge,
	address_mode_w = .ClampToEdge,
	mag_filter     = .Nearest,
	min_filter     = .Nearest,
	mipmap_filter  = .Nearest,
	lod_min_clamp  = 0.0,
	lod_max_clamp  = 32.0,
	compare        = .Undefined,
	max_anisotropy = 1,
}

/* Creates a new `Sampler`. */
@(require_results)
device_create_sampler :: proc "contextless" (
	self: Device,
	descriptor: SamplerDescriptor = DEFAULT_SAMPLER_DESCRIPTOR,
	loc := #caller_location,
) -> (
	sampler: Sampler,
	ok: bool,
) #optional_ok {
	raw_desc := WGPUSamplerDescriptor {
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
		c_label: StringViewBuffer
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

/*
Source of a shader module (`string` or `cstring` for WGSL and `[]u32` for SPIR-V).

The source will be parsed and validated.

Any necessary shader translation (e.g. from WGSL to SPIR-V or vice versa)
will be done internally by wgpu.

This type is unique to the `wgpu-native`. In the WebGPU specification,
only WGSL source code strings are accepted.
*/
ShaderSource :: union {
	string, /* WGSL, will be `clone_to_cstring` to ensure null terminated */
	[]u32, /* SPIR-V */
}

/*
Descriptor for use with `device_create_shader_module`.

Corresponds to [WebGPU `GPUShaderModuleDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpushadermoduledescriptor).
*/
ShaderModuleDescriptor :: struct {
	label:  string,
	source: ShaderSource,
}

// Creates a shader module from either `SPIR-V` or `WGSL` source code.
@(require_results)
device_create_shader_module :: proc(
	self: Device,
	descriptor: ShaderModuleDescriptor,
	loc := #caller_location,
) -> (
	shader_module: ShaderModule,
	ok: bool,
) #optional_ok {
	raw_desc: WGPUShaderModuleDescriptor

	when ODIN_DEBUG {
		c_label: StringViewBuffer
		if descriptor.label != "" {
			raw_desc.label = init_string_buffer(&c_label, descriptor.label)
		}
	}

	error_reset_data(loc)

	switch &source in descriptor.source {
	case string:
		runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
		wgsl := ShaderSourceWGSL {
			chain = {stype = .ShaderSourceWGSL},
			code = {
				data = strings.clone_to_cstring(source, context.temp_allocator),
				length = STRLEN,
			},
		}
		raw_desc.next_in_chain = &wgsl.chain
		shader_module = wgpuDeviceCreateShaderModule(self, raw_desc)
	case []u32:
		spirv := ShaderSourceSPIRV {
			chain = {stype = .ShaderSourceSPIRV},
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
	}

	if get_last_error() != nil {
		if shader_module != nil {
			wgpuShaderModuleRelease(shader_module)
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
TextureDescriptor :: struct {
	label:           string,
	usage:           TextureUsage,
	dimension:       TextureDimension,
	size:            Extent3D,
	format:          TextureFormat,
	mip_level_count: u32,
	sample_count:    u32,
	view_formats:    []TextureFormat,
}

/*  Creates a new `Texture`. */
@(require_results)
device_create_texture :: proc "contextless" (
	self: Device,
	descriptor: TextureDescriptor,
	loc := #caller_location,
) -> (
	texture: Texture,
	ok: bool,
) #optional_ok {
	raw_desc := WGPUTextureDescriptor {
		usage           = descriptor.usage,
		dimension       = descriptor.dimension,
		size            = descriptor.size,
		format          = descriptor.format,
		mip_level_count = descriptor.mip_level_count,
		sample_count    = descriptor.sample_count,
	}

	when ODIN_DEBUG {
		c_label: StringViewBuffer
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

/* Destroy the device immediately. */
device_destroy :: wgpuDeviceDestroy

/*
List all features that may be used with this device.

Functions may panic if you use unsupported features.
*/
device_get_features :: proc "contextless" (
	self: Device,
) -> (
	features: DeviceFeatures,
) #no_bounds_check {
	supported: SupportedFeatures
	wgpuDeviceGetFeatures(self, &supported)

	raw_features := supported.features[:supported.feature_count]
	features = cast(DeviceFeatures)features_slice_to_flags(raw_features)

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
	native := NativeLimits {
		chain = {stype = SType.NativeLimits},
	}
	base := WGPULimits {
		next_in_chain = &native.chain,
	}

	error_reset_data(loc)
	status := wgpuDeviceGetLimits(self, &base)
	if get_last_error() != nil {
		return
	}
	if status != .Success {
		error_update_data(ErrorType.Unknown, "Failed to fill device limits")
		return
	}

	limits = limits_merge_base_with_native(base, native)

	// Why wgpu returns 0 for some supported limits?
	// Enforce minimum values for all limits even if the returned values are lower
	limits_ensure_minimum(&limits, minimum = DOWNLEVEL_WEBGL2_LIMITS)

	return limits, true
}

/* Get a handle to a command queue on the device. */
device_get_queue :: wgpuDeviceGetQueue

/* Check if device support all features in the given flags. */
device_has_feature :: proc "contextless" (self: Device, features: Features) -> bool {
	if features == {} {
		return true
	}
	available := device_get_features(self)
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

device_pop_error_scope :: wgpuDevicePopErrorScope

device_push_error_scope :: wgpuDevicePushErrorScope

/* Set debug label. */
@(disabled = !ODIN_DEBUG)
device_set_label :: proc "contextless" (self: Device, label: string) {
	c_label: StringViewBuffer
	wgpuDeviceSetLabel(self, init_string_buffer(&c_label, label))
}

// Increase the reference count.
device_add_ref :: wgpuDeviceAddRef


// Release the `Device` and delete internal objects.
device_release :: wgpuDeviceRelease

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
	wrapped_submission_index: ^SubmissionIndex = nil,
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
