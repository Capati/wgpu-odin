package webgpu

// Core
import "base:runtime"
import sa "core:container/small_array"

// Vendor
import "vendor:wgpu"

/*
Open connection to a graphics and/or compute device.

Responsible for the creation of most rendering and compute resources. These are
then used in commands, which are submitted to a `Queue`.

A device may be requested from an adapter with `AdapterRequestDevice`.

Corresponds to [WebGPU
`GPUDevice`](https://gpuweb.github.io/gpuweb/#gpu-device).
*/
Device :: wgpu.Device

/*
List all features that may be used with this device.

Functions may panic if you use unsupported features.
*/
DeviceFeatures :: proc "c" (self: Device) -> (features: Features) #no_bounds_check {
	supported := wgpu.DeviceGetFeatures(self)
	defer wgpu.SupportedFeaturesFreeMembers(supported)

	rawFeatures := supported.features[:supported.featureCount]
	features = _FeaturesSliceToFlags(rawFeatures)

	return
}

/* Check if device support all features in the given flags. */
DeviceHasFeature :: proc "c" (self: Device, features: Features) -> bool {
	if features == {} {
		return true
	}
	available := DeviceFeatures(self)
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

If any of these limits are exceeded, procedures may panic.
*/
DeviceLimits :: proc "c" (self: Device) -> (limits: Limits) {
	raw_limits: wgpu.Limits

	when ODIN_OS != .JS {
		native := wgpu.NativeLimits {
			chain = { sType = .NativeLimits },
		}
		raw_limits.nextInChain = &native.chain
	}

	status := wgpu.RawDeviceGetLimits(self, &raw_limits)
	if status != .Success {
		return
	}

	when ODIN_OS != .JS {
		limits = _LimitsMergeWebGPUWithNative(raw_limits, native)
	} else {
		limits = _LimitsMergeWebGPUWithNative(raw_limits, {})
	}

	// WGPU returns 0 for unused limits
	// Enforce minimum values for all limits even if the returned values are lower
	LimitsEnsureMinimum(&limits, LIMITS_DOWNLEVEL_WEBGL2)

	return
}

/* Defines to unlock configured shader features. */
ShaderDefine :: wgpu.ShaderDefine

/* GLSL module. */
GLSLSource :: struct {
	shader:  string,
	stage:   ShaderStage,
	defines: []ShaderDefine,
}

/*
Source of a shader module:

- `string` for **WGSL**
- `[]u32` for **SPIR-V**
- `GLSLSource` for **GLSL**

The source will be parsed and validated.

Any necessary shader translation (e.g. from WGSL to SPIR-V or vice versa)
will be done internally by wgpu.

This type is unique to the `wgpu-native`. In the WebGPU specification,
only WGSL source code strings are accepted.
*/
ShaderSource :: union {
	string, /* WGSL */
	[]u32, /* SPIR-V */
	GLSLSource, /* GLSL */
}

/*
Descriptor for use with `DeviceCreateShaderModule`.

Corresponds to [WebGPU `GPUShaderModuleDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpushadermoduledescriptor).
*/
ShaderModuleDescriptor :: struct {
	label:  string,
	source: ShaderSource,
}

/* Creates a shader module from either `WGSL`, `SPIR-V` or `GLSL` source code. */
@(require_results)
DeviceCreateShaderModule :: proc "c" (
	self: Device,
	descriptor: ShaderModuleDescriptor,
	loc := #caller_location,
) -> (
	shaderModule: ShaderModule,
) {
	raw_desc: wgpu.ShaderModuleDescriptor
	raw_desc.label = descriptor.label

	switch &source in descriptor.source {
	case string:
		wgsl := wgpu.ShaderSourceWGSL {
			chain = { sType = .ShaderSourceWGSL },
			code  = source,
		}
		raw_desc.nextInChain = &wgsl.chain
		shaderModule = wgpu.DeviceCreateShaderModule(self, &raw_desc)

	case []u32:
		spirv := wgpu.ShaderSourceSPIRV {
			chain = { sType = .ShaderSourceSPIRV },
			code = nil,
		}
		if source != nil {
			codeSize := cast(u32)len(source)
			if codeSize > 0 {
				spirv.codeSize = codeSize
				spirv.code     = raw_data(source)
			}
		}
		raw_desc.nextInChain = &spirv.chain
		shaderModule = wgpu.DeviceCreateShaderModule(self, &raw_desc)

	case GLSLSource:
		glsl := wgpu.ShaderSourceGLSL {
			chain = {  sType = .ShaderSourceGLSL },
			stage = source.stage,
			code  = source.shader,
		}
		if len(source.defines) > 0 {
			glsl.defineCount = uint(len(source.defines))
			glsl.defines = raw_data(source.defines)
		}
		raw_desc.nextInChain = &glsl.chain
		shaderModule = wgpu.DeviceCreateShaderModule(self, &raw_desc)
	}

	return
}

/*
Describes a `Command_Encoder`

Corresponds to [WebGPU `GPUCommandEncoderDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpucommandencoderdescriptor).
*/
CommandEncoderDescriptor :: wgpu.CommandEncoderDescriptor

/* Creates an empty `Command_Encoder`. */
@(require_results)
DeviceCreateCommandEncoder :: proc "c" (
	self: Device,
	descriptor: Maybe(CommandEncoderDescriptor) = nil,
) -> (
	commandEncoder: CommandEncoder,
) {
	if desc, ok := descriptor.?; ok {
		commandEncoder = wgpu.DeviceCreateCommandEncoder(self, &desc)
	} else {
		commandEncoder = wgpu.DeviceCreateCommandEncoder(self, nil)
	}

	return
}

/*
Describes a `RenderBundle`.

For use with `RenderBundleEncoderFinish`.

Corresponds to [WebGPU `GPURenderBundleDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpurenderbundledescriptor).
*/
RenderBundleEncoderDescriptor :: struct {
	label:              string,
	colorFormats:       []TextureFormat,
	depthStencilFormat: TextureFormat,
	sampleCount:        u32,
	depthReadOnly:      bool,
	stencilReadOnly:    bool,
}

/* Creates an empty `RenderBundleEncoder`. */
@(require_results)
DeviceCreateRenderBundleEncoder :: proc "c" (
	self: Device,
	descriptor: RenderBundleEncoderDescriptor,
) -> (
	renderBundleEncoder: RenderBundleEncoder,
) {
	desc: wgpu.RenderBundleEncoderDescriptor
	desc.label = descriptor.label

	colorFormatCount := uint(len(descriptor.colorFormats))
	if colorFormatCount > 0 {
		desc.colorFormatCount = colorFormatCount
		desc.colorFormats = raw_data(descriptor.colorFormats)
	}

	desc.depthStencilFormat = descriptor.depthStencilFormat
	desc.sampleCount = descriptor.sampleCount
	desc.depthReadOnly = b32(descriptor.depthReadOnly)
	desc.stencilReadOnly = b32(descriptor.stencilReadOnly)

	renderBundleEncoder = wgpu.DeviceCreateRenderBundleEncoder(self, &desc)

	return
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
	[]BufferBinding,
	[]Sampler,
	[]TextureView,
}

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

For use with `DeviceCreateBindGroup`.

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
DeviceCreateBindGroup :: proc(
	self: Device,
	descriptor: BindGroupDescriptor,
) -> (
	bind_group: BindGroup,
) #no_bounds_check {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	ta := context.temp_allocator

	// Pre-calculate sizes
	entries_total := len(descriptor.entries)
	extras_total: uint

	for &entry in descriptor.entries {
		#partial switch &res in entry.resource {
		case []BufferBinding, []Sampler, []TextureView:
			extras_total += 1
		}
	}

	// Only allocate what we actually need to pass to wgpu
	entries: []wgpu.BindGroupEntry
	extras: []wgpu.BindGroupEntryExtras

	if entries_total > 0 {
		entries = make([]wgpu.BindGroupEntry, entries_total, ta)
	}

	if extras_total > 0 {
		extras = make([]wgpu.BindGroupEntryExtras, extras_total, ta)
	}

	extras_count: uint

	for &entry, i in descriptor.entries {
		raw_entry := &entries[i]
		raw_entry.binding = entry.binding

		switch &res in entry.resource {
		case BufferBinding:
			raw_entry.buffer = res.buffer
			raw_entry.size = res.size
			raw_entry.offset = res.offset

		case []BufferBinding:
			// Use first binding for offset/size, all buffers for the array
			raw_entry.size = res[0].size
			raw_entry.offset = res[0].offset

			// Extract just the buffer handles we need
			buffers := make([]Buffer, len(res), ta)
			for &binding, j in res {
				buffers[j] = binding.buffer
			}

			extras[extras_count] = {
				chain       = { sType = .BindGroupEntryExtras },
				bufferCount = len(buffers),
				buffers     = raw_data(buffers),
			}
			raw_entry.nextInChain = &extras[extras_count].chain
			extras_count += 1

		case Sampler:
			raw_entry.sampler = res

		case []Sampler:
			extras[extras_count] = {
				chain        = { sType = .BindGroupEntryExtras },
				samplerCount = len(res),
				samplers     = raw_data(res),
			}
			raw_entry.nextInChain = &extras[extras_count].chain
			extras_count += 1

		case TextureView:
			raw_entry.textureView = res

		case []TextureView:
			extras[extras_count] = {
				chain            = { sType = .BindGroupEntryExtras },
				textureViewCount = len(res),
				textureViews     = raw_data(res),
			}
			raw_entry.nextInChain = &extras[extras_count].chain
			extras_count += 1
		}
	}

	assert(extras_count == extras_total)

	desc := wgpu.BindGroupDescriptor {
		label      = descriptor.label,
		layout     = descriptor.layout,
		entryCount = len(entries),
		entries    = raw_data(entries),
	}

	bind_group = wgpu.DeviceCreateBindGroup(self, &desc)

	return
}

/*
Specific type of a buffer binding.

Corresponds to [WebGPU `GPUBufferBindingType`](
https://gpuweb.github.io/gpuweb/#enumdef-gpubufferbindingtype).
*/
BufferBindingType :: wgpu.BufferBindingType

/*
A buffer binding.

For use in `BindingType`.

Corresponds to [WebGPU `GPUBufferBindingLayout`](
https://gpuweb.github.io/gpuweb/#dictdef-gpubufferbindinglayout).
*/
BufferBindingLayout :: wgpu.BufferBindingLayout

/*
Specific type of a sampler binding.

For use in `BindingType`.

Corresponds to [WebGPU `GPUSamplerBindingType`](
https://gpuweb.github.io/gpuweb/#enumdef-gpusamplerbindingtype).
*/
SamplerBindingType :: wgpu.SamplerBindingType

/*
A sampler that can be used to sample a texture.

Example WGSL syntax:

```
@group(0) @binding(0)
var s: sampler;
```

Example GLSL syntax:

```
layout(binding = 0)
uniform sampler s;
```

Corresponds to [WebGPU `GPUSamplerBindingLayout`](
https://gpuweb.github.io/gpuweb/#dictdef-gpusamplerbindinglayout).
*/
SamplerBindingLayout :: wgpu.SamplerBindingLayout

/*
Specific type of a sample in a texture binding.

Corresponds to [WebGPU `GPUTextureSampleType`](
https://gpuweb.github.io/gpuweb/#enumdef-gputexturesampletype).
*/
TextureSampleType :: wgpu.TextureSampleType

/* Use filtered float. */
TEXTURE_SAMPLE_TYPE_DEFAULT :: TextureSampleType.Float

/*
A texture binding.

Example WGSL syntax:

```
@group(0) @binding(0)
var t: texture_2d<f32>;
```

Example GLSL syntax:

```
layout(binding = 0)
uniform texture2D t;
```

Corresponds to [WebGPU `GPUTextureBindingLayout`](
https://gpuweb.github.io/gpuweb/#dictdef-gputexturebindinglayout).
*/
TextureBindingLayout :: wgpu.TextureBindingLayout

/*
Specific type of a sample in a texture binding.

For use in `BindingType`.

Corresponds to [WebGPU `GPUStorageTextureAccess`](
https://gpuweb.github.io/gpuweb/#enumdef-gpustoragetextureaccess).
*/
StorageTextureAccess :: wgpu.StorageTextureAccess

/*
A storage texture.

Example WGSL syntax:

```
@group(0) @binding(0)
var my_storage_image: texture_storage_2d<r32float, write>;
```

Example GLSL syntax:

```
layout(set=0, binding=0, r32f) writeonly uniform image2D myStorageImage;
```
Note that the texture format must be specified in the shader, along with the
access mode. For WGSL, the format must be one of the enumerants in the list
of [storage texel formats](https://gpuweb.github.io/gpuweb/wgsl/#storage-texel-formats).

Corresponds to [WebGPU `GPUStorageTextureBindingLayout`](
https://gpuweb.github.io/gpuweb/#dictdef-gpustoragetexturebindinglayout).
*/
StorageTextureBindingLayout :: wgpu.StorageTextureBindingLayout

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
	visibility: ShaderStages,
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
DeviceCreateBindGroupLayout :: proc(
	self: Device,
	descriptor: Maybe(BindGroupLayoutDescriptor) = nil,
) -> (
	bindGroupLayout: BindGroupLayout,
) {
	desc, desc_ok := descriptor.?

	if !desc_ok {
		bindGroupLayout = wgpu.DeviceCreateBindGroupLayout(self, nil)
		return
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	ta := context.temp_allocator

	entryCount := len(desc.entries)

	// Early exit for empty entries
	if entryCount == 0 {
		raw_desc := wgpu.BindGroupLayoutDescriptor {
			label      = desc.label,
			entryCount = 0,
			entries    = nil,
		}
		bindGroupLayout = wgpu.DeviceCreateBindGroupLayout(self, &raw_desc)
		return
	}

	// Pre-calculate how many entries need extras (count > 0)
	extras_count: uint
	for &entry in desc.entries {
		if entry.count > 0 {
			extras_count += 1
		}
	}

	// Allocate only what we need
	entries := make([]wgpu.BindGroupLayoutEntry, entryCount, ta)
	extras: []wgpu.BindGroupLayoutEntryExtras

	if extras_count > 0 {
		extras = make([]wgpu.BindGroupLayoutEntryExtras, extras_count, ta)
	}

	extrasIndex: uint

	for &entry, i in desc.entries {
		raw_entry := &entries[i]

		raw_entry.binding = entry.binding
		raw_entry.visibility = entry.visibility

		// Handle binding types
		switch bindingType in entry.type {
		case BufferBindingLayout:
			raw_entry.buffer = bindingType
		case SamplerBindingLayout:
			raw_entry.sampler = bindingType
		case TextureBindingLayout:
			raw_entry.texture = bindingType
		case StorageTextureBindingLayout:
			raw_entry.storageTexture = bindingType
		}

		// Handle count extras
		if entry.count > 0 {
			extras[extrasIndex] = wgpu.BindGroupLayoutEntryExtras {
				chain = { sType = .BindGroupLayoutEntryExtras },
				count = entry.count,
			}
			raw_entry.nextInChain = &extras[extrasIndex].chain
			extrasIndex += 1
		}
	}

	assert(extrasIndex == extras_count)

	raw_desc := wgpu.BindGroupLayoutDescriptor {
		label      = desc.label,
		entryCount = uint(entryCount),
		entries    = raw_data(entries),
	}

	bindGroupLayout = wgpu.DeviceCreateBindGroupLayout(self, &raw_desc)

	return
}

/*
Describes a `PipelineLayout`.

For use with `DeviceCreatePipelineLayout`.

Corresponds to [WebGPU `GPUPipelineLayoutDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpupipelinelayoutdescriptor).
*/
PipelineLayoutDescriptor :: struct {
	label:              string,
	bindGroupLayouts:   []BindGroupLayout,
	pushConstantRanges: []PushConstantRange,
}


/* Creates a `PipelineLayout`. */
@(require_results)
DeviceCreatePipelineLayout :: proc(
	self: Device,
	descriptor: PipelineLayoutDescriptor,
) -> (
	pipelineLayout: PipelineLayout,
) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	ta := context.temp_allocator

	bindGroupLayoutCount := len(descriptor.bindGroupLayouts)
	pushConstantRangeCount := len(descriptor.pushConstantRanges)

	desc := wgpu.PipelineLayoutDescriptor {
		label = descriptor.label,
		bindGroupLayoutCount = uint(bindGroupLayoutCount),
		bindGroupLayouts = bindGroupLayoutCount > 0 ? raw_data(descriptor.bindGroupLayouts) : nil,
	}

	// Handle push constant ranges if present
	if pushConstantRangeCount > 0 {
		pushConstantRanges := make([]wgpu.PushConstantRange, pushConstantRangeCount, ta)

		for &range, i in descriptor.pushConstantRanges {
			pushConstantRanges[i] = {
				stages = range.stages,
				start  = range.range.start,
				end    = range.range.end,
			}
		}

		extras := wgpu.PipelineLayoutExtras {
			chain = { sType = .PipelineLayoutExtras },
			pushConstantRangeCount = uint(pushConstantRangeCount),
			pushConstantRanges = raw_data(pushConstantRanges),
		}

		desc.nextInChain = &extras.chain
	}

	pipelineLayout = wgpu.DeviceCreatePipelineLayout(self, &desc)

	return
}

/*
Vertex Format for a `VertexAttribute` (input).

Corresponds to [WebGPU `GPUVertexFormat`](
https://gpuweb.github.io/gpuweb/#enumdef-gpuvertexformat).
*/
VertexFormat :: wgpu.VertexFormat

VertexFormatGetSize :: proc "c" (self: VertexFormat) -> u64 {
	switch self {
	case .Uint8, .Sint8, .Unorm8, .Snorm8: return 1
	case .Uint8x2, .Sint8x2, .Unorm8x2, .Snorm8x2, .Uint16, .Sint16, .Unorm16, .Snorm16, .Float16:
		return 2
	case .Uint8x4, .Sint8x4, .Unorm8x4, .Snorm8x4, .Uint16x2, .Sint16x2, .Unorm16x2, .Snorm16x2,
		 .Float16x2, .Float32, .Uint32, .Sint32, .Unorm10_10_10_2, .Unorm8x4BGRA: return 4
	case .Uint16x4, .Sint16x4, .Unorm16x4, .Snorm16x4, .Float16x4, .Float32x2, .Uint32x2,
		 .Sint32x2 /* .Float64 */: return 8
	case .Float32x3, .Uint32x3, .Sint32x3: return 12
	case .Float32x4, .Uint32x4, .Sint32x4 /* .Float64x2 */: return 16
	/* case .Float64x3: return 24 */
	/* case .Float64x4: return 32 */
	}
	return 0
}

/*
Vertex inputs (attributes) to shaders.

Arrays of these can be made with the `vertex_attr_array` macro. Vertex
attributes are assumed to be tightly packed.

Corresponds to [WebGPU `GPUVertexAttribute`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuvertexattribute).
*/
VertexAttribute :: wgpu.VertexAttribute

/*
Whether a vertex buffer is indexed by vertex or by instance.

Corresponds to [WebGPU `GPUVertexStepMode`](
https://gpuweb.github.io/gpuweb/#enumdef-gpuvertexstepmode).
*/
VertexStepMode :: wgpu.VertexStepMode

/*
Describes how the vertex buffer is interpreted.

For use in `VertexState`.

Corresponds to [WebGPU `GPUVertexBufferLayout`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuvertexbufferlayout).
*/
VertexBufferLayout :: struct {
	arrayStride: u64,
	stepMode:    VertexStepMode,
	attributes:  []VertexAttribute,
}

/*
Describes the vertex processing in a render pipeline.

For use in `RenderPipelineDescriptor`.

Corresponds to [WebGPU `GPUVertexState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuvertexstate).
*/
VertexState :: struct {
	module:     ShaderModule,
	entryPoint: string,
	constants:  []ConstantEntry,
	buffers:    []VertexBufferLayout,
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

PrimitiveTopologyIsStrip :: proc "c" (self: PrimitiveTopology) -> bool {
	#partial switch self {
	case .TriangleStrip, .LineStrip:
		return true
	}
	return false
}

/*
Format of indices used with pipeline.

Corresponds to [WebGPU `GPUIndexFormat`](
https://gpuweb.github.io/gpuweb/#enumdef-gpuindexformat).
*/
IndexFormat :: wgpu.IndexFormat

/*
Vertex winding order which classifies the "front" face of a triangle.

Corresponds to [WebGPU `GPUFrontFace`](
https://gpuweb.github.io/gpuweb/#enumdef-gpufrontface).
*/
FrontFace :: wgpu.FrontFace

/*
Face of a vertex.

Corresponds to [WebGPU `GPUCullMode`](
https://gpuweb.github.io/gpuweb/#enumdef-gpucullmode).
*/
Face :: wgpu.CullMode

/*
Describes the state of primitive assembly and rasterization in a render pipeline.

Corresponds to [WebGPU `GPUPrimitiveState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuprimitivestate).
*/
PrimitiveState :: struct {
	topology:         PrimitiveTopology,
	stripIndexFormat: IndexFormat,
	frontFace:        FrontFace,
	cullMode:         Face,
	unclippedDepth:   bool,
}

PRIMITIVE_STATE_DEFAULT :: PrimitiveState {
	topology  = .TriangleList,
	frontFace = .CCW,
	cullMode  = .None,
}

/*
Describes the multi-sampling state of a render pipeline.

Corresponds to [WebGPU `GPUMultisampleState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpumultisamplestate).
*/
MultisampleState :: struct {
	count:                  u32,
	mask:                   u32,
	alphaToCoverageEnabled: bool,
}

/* Default `count = 1` and mask all pixels `0xFFFFFFFF`. */
MULTISAMPLE_STATE_DEFAULT :: MultisampleState {
	count                  = 1,
	mask                   = max(u32), // 0xFFFFFFFF
	alphaToCoverageEnabled = false,
}

/*
Operation to perform on the stencil value.

Corresponds to [WebGPU `GPUStencilOperation`](
https://gpuweb.github.io/gpuweb/#enumdef-gpustenciloperation).
*/
StencilOperation :: wgpu.StencilOperation

/*
Describes stencil state in a render pipeline.

If you are not using stencil state, set this to `STENCIL_FACE_STATE_IGNORE`.

Corresponds to [WebGPU `GPUStencilFaceState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpustencilfacestate).
*/
StencilFaceState :: wgpu.StencilFaceState

/* Returns true if the face state uses the reference value for testing or operation. */
StencilFaceStateNeedsRefValue :: proc "c" (self: StencilFaceState) -> bool {
	return(
		CompareFunctionNeedsRefValue(self.compare) ||
		self.failOp == .Replace ||
		self.depthFailOp == .Replace ||
		self.passOp == .Replace \
	)
}

/* Returns true if the face state doesn't mutate the target values. */
StencilFaceStateIsReadOnly :: proc "c" (self: StencilFaceState) -> bool {
	return self.passOp == .Keep && self.depthFailOp == .Keep && self.failOp == .Keep
}

/* Ignore the stencil state for the face. */
STENCIL_FACE_STATE_IGNORE :: StencilFaceState {
	compare     = .Always,
	failOp      = .Keep,
	depthFailOp = .Keep,
	passOp      = .Keep,
}

/*
State of the stencil operation (fixed-pipeline stage).

For use in `DepthStencilState`.

Corresponds to a portion of [WebGPU `GPUDepthStencilState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpudepthstencilstate).
*/
StencilState :: struct {
	front:     StencilFaceState,
	back:      StencilFaceState,
	readMask:  u32,
	writeMask: u32,
}

/* Returns true if the stencil test is enabled. */
StencilStateIsEnabled :: proc "c" (self: StencilState) -> bool {
	return(
		(self.front != STENCIL_FACE_STATE_IGNORE || self.back != STENCIL_FACE_STATE_IGNORE) &&
		(self.readMask != 0 || self.writeMask != 0) \
	)
}

/* Returns `true` if the state doesn't mutate the target values. */
StencilStateIsReadOnly :: proc "c" (self: StencilState, cullMode: Face) -> bool {
	// The rules are defined in step 7 of the "Device timeline initialization steps"
	// subsection of the "Render Pipeline Creation" section of WebGPU
	// (link to the section: https://gpuweb.github.io/gpuweb/#render-pipeline-creation)
	if self.writeMask == 0 {
		return true
	}

	front_ro := cullMode == .Front || StencilFaceStateIsReadOnly(self.front)
	back_ro := cullMode == .Back || StencilFaceStateIsReadOnly(self.back)

	return front_ro && back_ro
}

/* Returns `true` if the stencil state uses the reference value for testing. */
StencilStateNeedsRefValue :: proc "c" (self: StencilState) -> bool {
	return(
		StencilFaceStateNeedsRefValue(self.front) ||
		StencilFaceStateNeedsRefValue(self.back) \
	)
}

/*
Describes the biasing setting for the depth target.

For use in `DepthStencilState`.

Corresponds to a portion of [WebGPU `GPUDepthStencilState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpudepthstencilstate).
*/
DepthBiasState :: struct {
	constant:   i32,
	slopeScale: f32,
	clamp:      f32,
}

/* Returns true if the depth biasing is enabled. */
DepthBiasStateIsEnabled :: proc "c" (self: DepthBiasState) -> bool {
	return self.constant != 0 || self.slopeScale != 0.0
}

/*
Describes the depth/stencil state in a render pipeline.

Corresponds to [WebGPU `GPUDepthStencilState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpudepthstencilstate).
*/
DepthStencilState :: struct {
	format:            TextureFormat,
	depthWriteEnabled: bool,
	depthCompare:      CompareFunction,
	stencil:           StencilState,
	bias:              DepthBiasState,
}

/* Returns `true` if the depth testing is enabled. */
DepthStencilStateIsDepthEnabled :: proc "c" (self: DepthStencilState) -> bool {
	return(
		(self.depthCompare != .Undefined && self.depthCompare != .Always) ||
		self.depthWriteEnabled \
	)
}

/* Returns `true` if the state doesn't mutate the depth buffer. */
DepthStencilStateIsDepthReadOnly :: proc "c" (self: DepthStencilState) -> bool {
	return !self.depthWriteEnabled
}

/* Returns true if the state doesn't mutate the stencil. */
DepthStencilStateIsStencilReadOnly :: proc "c" (
	self: DepthStencilState,
	face: Face,
) -> bool {
	return StencilStateIsReadOnly(self.stencil, face)
}

/* Returns true if the state doesn't mutate either depth or stencil of the target. */
DepthStencilStateIsReadOnly :: proc "c" (
	self: DepthStencilState,
	face: Face,
) -> bool {
	return(
		DepthStencilStateIsDepthReadOnly(self) &&
		DepthStencilStateIsStencilReadOnly(self, face) \
	)
}

/*
Describes the color state of a render pipeline.

Corresponds to [WebGPU `GPUColorTargetState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpucolortargetstate).
*/

ColorTargetState :: wgpu.ColorTargetState

/*
Describes the fragment processing in a render pipeline.

For use in `RenderPipelineDescriptor`.

Corresponds to [WebGPU `GPUFragmentState`](
https://gpuweb.github.io/gpuweb/#dictdef-gpufragmentstate).
*/
FragmentState :: struct {
	module:      ShaderModule,
	entryPoint: string,
	constants:   []ConstantEntry,
	targets:     []ColorTargetState,
}

/*
Describes a render (graphics) pipeline.

For use with `DeviceCreateRenderPipeline`.

Corresponds to [WebGPU `GPURenderPipelineDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpurenderpipelinedescriptor).
*/
RenderPipelineDescriptor :: struct {
	label:        string,
	layout:       PipelineLayout,
	vertex:       VertexState,
	primitive:    PrimitiveState,
	depthStencil: DepthStencilState,
	multisample:  MultisampleState,
	fragment:     ^FragmentState,
}

MAX_VERTEX_BUFFERS : int : #config(RL_MAX_VERTEX_BUFFERS, 16)

/* Creates a `RenderPipeline`. */
@(require_results)
DeviceCreateRenderPipeline :: proc "c" (
	self: Device,
	descriptor: RenderPipelineDescriptor,
) -> (
	render_pipeline: RenderPipeline,
) {
	// Main descriptor
	raw_desc := wgpu.RenderPipelineDescriptor {
		label  = descriptor.label,
		layout = descriptor.layout,
	}

	// Vertex state
	raw_desc.vertex.module = descriptor.vertex.module
	raw_desc.vertex.entryPoint = descriptor.vertex.entryPoint

	// Vertex constants
	vertex_constant_count := len(descriptor.vertex.constants)
	if vertex_constant_count > 0 {
		raw_desc.vertex.constantCount = uint(vertex_constant_count)
		raw_desc.vertex.constants = raw_data(descriptor.vertex.constants)
	}

	// Vertex buffers
	vertex_buffers: sa.Small_Array(MAX_VERTEX_BUFFERS, wgpu.VertexBufferLayout)
	if len(descriptor.vertex.buffers) > 0 {
		for &buffer in descriptor.vertex.buffers {
			vertexBuffer: wgpu.VertexBufferLayout

			vertexBuffer.arrayStride = buffer.arrayStride
			vertexBuffer.stepMode    = buffer.stepMode

			attributeCount := len(buffer.attributes)
			if attributeCount > 0 {
				vertexBuffer.attributeCount = uint(attributeCount)
				vertexBuffer.attributes = raw_data(buffer.attributes)
			}

			sa.push_back(&vertex_buffers, vertexBuffer)
		}

		raw_desc.vertex.bufferCount = uint(sa.len(vertex_buffers))
		raw_desc.vertex.buffers = raw_data(sa.slice(&vertex_buffers))
	}

	// Helper function to map primitive topology enum
	mapPrimitiveTopology :: proc "c" (topology: PrimitiveTopology) -> wgpu.PrimitiveTopology {
		switch topology {
		case .TriangleList:  return .TriangleList
		case .PointList:     return .PointList
		case .LineList:      return .LineList
		case .LineStrip:     return .LineStrip
		case .TriangleStrip: return .TriangleStrip
		case:                return .TriangleList // Default fallback
		}
	}

	// Primitive state
	raw_desc.primitive = {
		topology         = mapPrimitiveTopology(descriptor.primitive.topology),
		stripIndexFormat = descriptor.primitive.stripIndexFormat,
		frontFace        = descriptor.primitive.frontFace,
		cullMode         = descriptor.primitive.cullMode,
		unclippedDepth   = b32(descriptor.primitive.unclippedDepth),
	}

	// Depth stencil state (only if format is valid)
	depthStencil: wgpu.DepthStencilState
	if descriptor.depthStencil.format != .Undefined {
		depthStencil = {
			format              = descriptor.depthStencil.format,
			depthWriteEnabled   = .True if descriptor.depthStencil.depthWriteEnabled else .False,
			depthCompare        = descriptor.depthStencil.depthCompare,
			stencilFront        = descriptor.depthStencil.stencil.front,
			stencilBack         = descriptor.depthStencil.stencil.back,
			stencilReadMask     = descriptor.depthStencil.stencil.readMask,
			stencilWriteMask    = descriptor.depthStencil.stencil.writeMask,
			depthBias           = descriptor.depthStencil.bias.constant,
			depthBiasSlopeScale = descriptor.depthStencil.bias.slopeScale,
			depthBiasClamp      = descriptor.depthStencil.bias.clamp,
		}
		raw_desc.depthStencil = &depthStencil
	}

	// Multisample state
	raw_desc.multisample = {
		count = descriptor.multisample.count,
		mask = descriptor.multisample.mask,
		alphaToCoverageEnabled = b32(descriptor.multisample.alphaToCoverageEnabled),
	}
	if raw_desc.multisample.count == 0 {
		raw_desc.multisample.count = 1 // Cannot be 0, default to 1
	}

	// Fragment state (optional)
	fragment: wgpu.FragmentState

	if descriptor.fragment != nil {
		fragment.module = descriptor.fragment.module
		fragment.entryPoint = descriptor.fragment.entryPoint

		// Fragment constants
		fragment_constant_count := len(descriptor.fragment.constants)
		if fragment_constant_count > 0 {
			fragment.constantCount = uint(fragment_constant_count)
			fragment.constants = raw_data(descriptor.fragment.constants)
		}

		// Fragment targets
		target_count := len(descriptor.fragment.targets)
		if target_count > 0 {
			fragment.targetCount = uint(target_count)
			fragment.targets = raw_data(descriptor.fragment.targets)
		}

		raw_desc.fragment = &fragment
	}

	render_pipeline = wgpu.DeviceCreateRenderPipeline(self, &raw_desc)

	return
}

/*
Describes a compute pipeline.

For use with `DeviceCreateComputePipeline`.

Corresponds to [WebGPU `GPUComputePipelineDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpucomputepipelinedescriptor).
*/
ComputePipelineDescriptor :: struct {
	label:       string,
	layout:      PipelineLayout,
	module:      ShaderModule,
	entryPoint: string,
	constants:   []ConstantEntry,
}

/* Creates a new `ComputePipeline`. */
@(require_results)
DeviceCreateComputePipeline :: proc "c" (
	self: Device,
	descriptor: ComputePipelineDescriptor,
) -> (
	computePipeline: ComputePipeline,
) {
	desc: wgpu.ComputePipelineDescriptor
	desc.label = descriptor.label

	if descriptor.layout != nil {
		desc.layout = descriptor.layout
	}

	if descriptor.module != nil {
		desc.compute.module = descriptor.module
	}

	desc.compute.entryPoint = descriptor.entryPoint

	constantCount := uint(len(descriptor.constants))
	if len(descriptor.constants) > 0 {
		desc.compute.constantCount = constantCount
		desc.compute.constants = raw_data(descriptor.constants)
	}

	computePipeline = wgpu.DeviceCreateComputePipeline(self, &desc)

	return
}

BufferUsage :: wgpu.BufferUsage

/*
Different ways that you can use a buffer.

The usages determine what kind of memory the buffer is allocated from and what
actions the buffer can partake in.

Corresponds to [WebGPU `GPUBufferUsageFlags`](
https://gpuweb.github.io/gpuweb/#typedefdef-gpubufferusageflags).
*/
BufferUsages :: wgpu.BufferUsageFlags

BUFFER_USAGES_NONE :: BufferUsages{}

/*
Describes a `Buffer`

Corresponds to [WebGPU `GPUBufferDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpubufferdescriptor).
*/
BufferDescriptor :: struct {
	label:            string,
	usage:            BufferUsages,
	size:             u64,
	mappedAtCreation: bool,
}

/* Creates a new `Buffer`. */
@(require_results)
DeviceCreateBuffer :: proc "c" (self: Device, descriptor: BufferDescriptor) -> (buffer: Buffer) {
	desc := wgpu.BufferDescriptor {
		label            = descriptor.label,
		usage            = descriptor.usage,
		size             = descriptor.size,
		mappedAtCreation = b32(descriptor.mappedAtCreation),
	}

	buffer = wgpu.DeviceCreateBuffer(self, &desc)

	return
}

/* Describes a `Buffer` when allocating. */
BufferDataDescriptor :: struct {
	/* Debug label of a buffer. This will show up in graphics debuggers for easy identification. */
	label:    string,
	/* Contents of a buffer on creation. */
	contents: []byte,
	/* Usages of a buffer. If the buffer is used in any way that isn't specified here,
	the operation will panic. */
	usage:    BufferUsages,
}

@(require_results)
DeviceCreateBufferWithData :: proc(
	self: Device,
	descriptor: BufferDataDescriptor,
	loc := #caller_location,
) -> (
	buffer: Buffer,
) {
	// Skip mapping if the buffer is zero sized
	if descriptor.contents == nil || len(descriptor.contents) == 0 {
		desc: BufferDescriptor = {
			label            = descriptor.label,
			size             = 0,
			usage            = descriptor.usage,
			mappedAtCreation = false,
		}

		return DeviceCreateBuffer(self, desc)
	}

	unpaddedSize := cast(BufferAddress)len(descriptor.contents)

	// Valid vulkan usage is
	// 1. buffer size must be a multiple of COPY_BUFFER_ALIGNMENT.
	// 2. buffer size must be greater than 0.
	// Therefore we round the value up to the nearest multiple, and ensure it's at least
	// COPY_BUFFER_ALIGNMENT.

	alignMask := COPY_BUFFER_ALIGNMENT_MASK
	paddedSize := max(((unpaddedSize + alignMask) & ~alignMask), COPY_BUFFER_ALIGNMENT)

	bufferDescriptor: BufferDescriptor = {
		label              = descriptor.label,
		size               = paddedSize,
		usage              = descriptor.usage,
		mappedAtCreation = true,
	}

	buffer = DeviceCreateBuffer(self, bufferDescriptor)
	assert(buffer != nil)

	// Synchronously and immediately map a buffer for reading. If the buffer is not
	// immediately mappable through `mappedAtCreation` or
	// `buffer_map_async`, will panic.
	mappedBufferView := BufferGetMappedRangeBytes(buffer, {0, paddedSize})
	copy(mappedBufferView.data, descriptor.contents)
	BufferUnmap(buffer)

	return
}

/*
Creates a new `Texture`.

Inputs:

- `descriptor` specifies the general format of the texture.
*/
@(require_results)
DeviceCreateTexture :: proc "c" (
	self: Device,
	descriptor: TextureDescriptor = TEXTURE_DESCRIPTOR_DEFAULT,
) -> (
	texture: Texture,
) {
	desc := wgpu.TextureDescriptor {
		label         = descriptor.label,
		usage         = descriptor.usage,
		dimension     = descriptor.dimension,
		size          = descriptor.size,
		format        = descriptor.format,
		mipLevelCount = descriptor.mipLevelCount,
		sampleCount   = descriptor.sampleCount,
	}

	viewFormatCount := uint(len(descriptor.viewFormats))
	if viewFormatCount > 0 {
		desc.viewFormatCount = viewFormatCount
		desc.viewFormats = raw_data(descriptor.viewFormats)
	}

	texture = wgpu.DeviceCreateTexture(self, &desc)

	return
}

/* Order in which texture data is laid out in memory. */
TextureDataOrder :: enum {
	LayerMajor,
	MipMajor,
}

/*
Upload an entire texture and its mipmaps from a source buffer.

Expects all mipmaps to be tightly packed in the data buffer.

See `TextureDataOrder` for the order in which the data is laid out in memory.

Implicitly adds the `COPY_DST` usage if it is not present in the descriptor,
as it is required to be able to upload the data to the gpu.
*/
@(require_results)
DeviceCreateTextureWithData :: proc "c" (
	self: Device,
	queue: Queue,
	desc: TextureDescriptor,
	order: TextureDataOrder,
	data: []byte,
	loc := #caller_location,
) -> (
	texture: Texture,
) {
	desc := desc

	// Implicitly add the .CopyDst usage
	if .CopyDst not_in desc.usage {
		desc.usage += { .CopyDst }
	}

	texture = DeviceCreateTexture(self, desc)
	assert_contextless(texture != nil, loc = loc)

	// Will return 0 only if it's a combined depth-stencil format
	// If so, default to 4, validation will fail later anyway since the depth or stencil
	// aspect needs to be written to individually
	block_size := TextureFormatBlockSize(desc.format)
	if block_size == 0 {
		block_size = 4
	}
	block_width, block_height := TextureFormatBlockDimensions(desc.format)
	layer_iterations := TextureDescriptorArrayLayerCount(desc)

	outer_iteration, inner_iteration: u32

	switch order {
	case .LayerMajor:
		outer_iteration = layer_iterations
		inner_iteration = desc.mipLevelCount
	case .MipMajor:
		outer_iteration = desc.mipLevelCount
		inner_iteration = layer_iterations
	}

	binary_offset: u32 = 0
	for outer in 0 ..< outer_iteration {
		for inner in 0 ..< inner_iteration {
			layer, mip: u32
			switch order {
			case .LayerMajor:
				layer = outer
				mip = inner
			case .MipMajor:
				layer = inner
				mip = outer
			}

			mipSize, mipSizeOk := TextureDescriptorMipLevelSize(desc, mip)
			assert_contextless(mipSizeOk, "Invalid mip level", loc)
			// copying layers separately
			if desc.dimension != ._3D {
				mipSize.depthOrArrayLayers = 1
			}

			// When uploading mips of compressed textures and the mip is supposed to be
			// a size that isn't a multiple of the block size, the mip needs to be uploaded
			// as its "physical size" which is the size rounded up to the nearest block size.
			mipPhysical := Extent3DPhysicalSize(mipSize, desc.format)

			// All these calculations are performed on the physical size as that's the
			// data that exists in the buffer.
			width_blocks := mipPhysical.width / block_width
			height_blocks := mipPhysical.height / block_height

			bytesPerRow := width_blocks * block_size
			dataSize := bytesPerRow * height_blocks * mipSize.depthOrArrayLayers

			endOffset := binary_offset + dataSize
			assert_contextless(endOffset <= u32(len(data)), "Buffer too small", loc)

			QueueWriteTexture(
				queue,
				{texture = texture, mipLevel = mip, origin = {0, 0, layer}, aspect = .All},
				data[binary_offset:endOffset],
				{offset = 0, bytesPerRow = bytesPerRow, rowsPerImage = height_blocks},
				mipPhysical,
			)

			binary_offset = endOffset
		}
	}

	return
}

/*
Describes a `Sampler`.

For use with `DeviceCreateSampler`.

Corresponds to [WebGPU `GPUSamplerDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpusamplerdescriptor).
*/
SamplerDescriptor :: wgpu.SamplerDescriptor

SAMPLER_DESCRIPTOR_DEFAULT :: SamplerDescriptor {
	addressModeU  = .ClampToEdge,
	addressModeV  = .ClampToEdge,
	addressModeW  = .ClampToEdge,
	magFilter     = .Nearest,
	minFilter     = .Nearest,
	mipmapFilter  = .Nearest,
	lodMinClamp   = 0.0,
	lodMaxClamp   = 32.0,
	compare       = .Undefined,
	maxAnisotropy = 1,
}

/*
Creates a new `Sampler`.

`descriptor` specifies the behavior of the sampler.
*/
@(require_results)
DeviceCreateSampler :: proc "c" (
	self: Device,
	descriptor: SamplerDescriptor = SAMPLER_DESCRIPTOR_DEFAULT,
) -> (
	sampler: Sampler,
) {
	descriptor := descriptor
	sampler = wgpu.DeviceCreateSampler(self, &descriptor)
	return
}

/*
Type of query contained in a `QuerySet`.

Corresponds to [WebGPU `GPUQueryType`](
https://gpuweb.github.io/gpuweb/#enumdef-gpuquerytype).
*/
QueryType :: wgpu.QueryType

/*
Flags for which pipeline data should be recorded.

The amount of values written when resolved depends on the amount of flags. If 3
flags are enabled, 3 64-bit values will be written per-query.

The order they are written is the order they are declared in this bitflags. If
you enabled `CLIPPER_PRIMITIVES_OUT` and `COMPUTE_SHADER_INVOCATIONS`, it would
write 16 bytes, the first 8 bytes being the primitive out value, the last 8
bytes being the compute shader invocation count.
*/
PipelineStatisticName :: wgpu.PipelineStatisticName

/*
Describes a `QuerySet`.

For use with `DeviceCreateQuerySet`.

Corresponds to [WebGPU `GPUQuerySetDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuquerysetdescriptor).
*/
QuerySetDescriptor :: struct {
	label:              string,
	type:               QueryType,
	count:              u32,
	/* Extras */
	pipelineStatistics: []PipelineStatisticName,
}

/* Creates a new `QuerySet`. */
@(require_results)
DeviceCreateQuerySet :: proc "c" (
	self: Device,
	descriptor: QuerySetDescriptor,
) -> (
	querySet: QuerySet,
) {
	desc := wgpu.QuerySetDescriptor {
		label = descriptor.label,
		count = descriptor.count,
	}

	when ODIN_OS != .JS {
		extras: wgpu.QuerySetDescriptorExtras
	}

	switch descriptor.type {
	case .Occlusion:
		desc.type = .Occlusion

	case .Timestamp:
		desc.type = .Timestamp

	case .PipelineStatistics:
		desc.type = .PipelineStatistics
		when ODIN_OS != .JS {
			extras = {
				chain                  = { sType = .QuerySetDescriptorExtras },
				pipelineStatisticCount = len(descriptor.pipelineStatistics),
				pipelineStatistics     = raw_data(descriptor.pipelineStatistics),
			}
			desc.nextInChain = &extras.chain
		}
	}

	querySet = wgpu.DeviceCreateQuerySet(self, &desc)

	return
}

/* Push an error scope. */
DevicePushErrorScope :: wgpu.DevicePushErrorScope

/* Pop an error scope. */
DevicePopErrorScope :: wgpu.DevicePopErrorScope

/* Destroy this device. */
DeviceDestroy :: wgpu.DeviceDestroy

/* Get info about the requested adapter. */
DeviceGetAdapterInfo :: wgpu.DeviceGetAdapterInfo

/* Get a handle to a command queue on the device. */
DeviceGetQueue :: wgpu.DeviceGetQueue

/* Sets a debug label for the given `Device`. */
DeviceSetLabel :: #force_inline proc "c" (self: Device, label: string) {
	wgpu.DeviceSetLabel(self, label)
}

// Increase the `Device` reference count.
DeviceAddRef :: #force_inline proc "c" (self: Device) {
	wgpu.DeviceAddRef(self)
}

// Release the `Device` resources, use to decrease the reference count.
DeviceRelease :: #force_inline proc "c" (self: Device) {
	wgpu.DeviceRelease(self)
}

/*
Safely releases the `Device` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
DeviceReleaseSafe :: proc "c" (self: ^Device) {
	if self != nil && self^ != nil {
		wgpu.DeviceRelease(self^)
		self^ = nil
	}
}
