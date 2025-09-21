package webgpu

// Core
import "base:runtime"
import "core:fmt"
import "core:log"
import "core:strings"
import sa "core:container/small_array"

// Vendor
import "vendor:wgpu"

/*
Represents the sets of limits an adapter/device supports.

We provide three different defaults.
- `DOWNLEVEL_LIMITS`. This is a set of limits that is guaranteed to work on
  almost all backends, including "downlevel" backends such as OpenGL and D3D11,
  other than WebGL.For most applications we recommend using these limits,
  assuming they are high enough for your application, and you do not intent to
  support WebGL.
- `DOWNLEVEL_WEBGL2_LIMITS`. This is a set of limits that is lower even than the
  `DOWNLEVEL_LIMITS`, configured to be low enough to support running in the
  browser using WebGL2.
- `DEFAULT_LIMITS`.This is the set of limits that is guaranteed to work on all
  modern backends and is guaranteed to be supported by WebGPU.Applications
  needing more modern features can use this as a reasonable set of limits if
  they are targeting only desktop and modern mobile devices.

We recommend starting with the most restrictive limits you can and manually
increasing the limits you need boosted.This will let you stay running on all
hardware that supports the limits you need.

Limits "better" than the default must be supported by the adapter and requested
when requesting a device.If limits "better" than the adapter supports are
requested, requesting a device will panic.Once a device is requested, you may
only use resources up to the limits requested _even_ if the adapter supports
"better" limits.

Requesting limits that are "better" than you need may cause performance to
decrease because the implementation needs to support more than is needed.You
should ideally only request exactly what you need.

Corresponds to [WebGPU `GPUSupportedLimits`](
https://gpuweb.github.io/gpuweb/#gpusupportedlimits).
*/
Limits :: struct {
	// WebGPU
	maxTextureDimension1D:                     u32,
	maxTextureDimension2D:                     u32,
	maxTextureDimension3D:                     u32,
	maxTextureArrayLayers:                     u32,
	maxBindGroups:                             u32,
	maxBindGroupsPlusVertexBuffers:            u32, // TODO: not used
	maxBindingsPerBindGroup:                   u32,
	maxDynamicUniformBuffersPerPipelineLayout: u32,
	maxDynamicStorageBuffersPerPipelineLayout: u32,
	maxSampledTexturesPerShaderStage:          u32,
	maxSamplersPerShaderStage:                 u32,
	maxStorageBuffersPerShaderStage:           u32,
	maxStorageTexturesPerShaderStage:          u32,
	maxUniformBuffersPerShaderStage:           u32,
	maxUniformBufferBindingSize:               u64,
	maxStorageBufferBindingSize:               u64,
	minUniformBufferOffsetAlignment:           u32,
	minStorageBufferOffsetAlignment:           u32,
	maxVertexBuffers:                          u32,
	maxBufferSize:                             u64,
	maxVertexAttributes:                       u32,
	maxVertexBufferArrayStride:                u32,
	maxInterStageShaderVariables:              u32, // TODO: not used
	maxColorAttachments:                       u32, // TODO: not used
	maxColorAttachmentBytesPerSample:          u32, // TODO: not used
	maxComputeWorkgroupStorageSize:            u32,
	maxComputeInvocationsPerWorkgroup:         u32,
	maxComputeWorkgroupSizeX:                  u32,
	maxComputeWorkgroupSizeY:                  u32,
	maxComputeWorkgroupSizeZ:                  u32,
	maxComputeWorkgroupsPerDimension:          u32,

	// Native
	maxPushConstantSize:                       u32,
	maxNonSamplerBindings:                     u32,
}

/*
This is the set of limits that is guaranteed to work on all modern backends and
is guaranteed to be supported by WebGPU.Applications needing more modern
features can use this as a reasonable set of limits if they are targeting only
desktop and modern mobile devices.
*/
LIMITS_DEFAULT :: Limits {
	// WebGPU
	maxTextureDimension1D                     = 8192, // 8k
	maxTextureDimension2D                     = 8192, // 8k
	maxTextureDimension3D                     = 2048, // 2k
	maxTextureArrayLayers                     = 256,
	maxBindGroups                             = 4,
	maxBindGroupsPlusVertexBuffers            = 24,
	maxBindingsPerBindGroup                   = 1000,
	maxDynamicUniformBuffersPerPipelineLayout = 8,
	maxDynamicStorageBuffersPerPipelineLayout = 4,
	maxSampledTexturesPerShaderStage          = 16,
	maxSamplersPerShaderStage                 = 16,
	maxStorageBuffersPerShaderStage           = 4,
	maxStorageTexturesPerShaderStage          = 4,
	maxUniformBuffersPerShaderStage           = 12,
	maxUniformBufferBindingSize               = 64 << 10, // 64 KiB
	maxStorageBufferBindingSize               = 128 << 20, // 128MB
	minUniformBufferOffsetAlignment           = 256,
	minStorageBufferOffsetAlignment           = 256,
	maxVertexBuffers                          = 8,
	maxBufferSize                             = 256 << 20, // 256MB
	maxVertexAttributes                       = 16,
	maxVertexBufferArrayStride                = 2048,
	maxInterStageShaderVariables              = 60,
	maxColorAttachments                       = 8,
	maxColorAttachmentBytesPerSample          = 32,
	maxComputeWorkgroupStorageSize            = 16384,
	maxComputeInvocationsPerWorkgroup         = 256,
	maxComputeWorkgroupSizeX                  = 256,
	maxComputeWorkgroupSizeY                  = 256,
	maxComputeWorkgroupSizeZ                  = 64,
	maxComputeWorkgroupsPerDimension          = 65535,

	// Native
	maxPushConstantSize                       = 0,
	maxNonSamplerBindings                     = 1_000_000,
}

/*
This is a set of limits that is guaranteed to work on almost all backends,
including “downlevel” backends such as OpenGL and D3D11, other than WebGL.For
most applications we recommend using these limits, assuming they are high enough
for your application, and you not intent to support WebGL.
*/
LIMITS_DOWNLEVEL :: Limits {
	// WebGPU
	maxTextureDimension1D                     = 2048,
	maxTextureDimension2D                     = 2048,
	maxTextureDimension3D                     = 256,
	maxTextureArrayLayers                     = 256,
	maxBindGroups                             = 4,
	maxBindGroupsPlusVertexBuffers            = 24,
	maxBindingsPerBindGroup                   = 1000,
	maxDynamicUniformBuffersPerPipelineLayout = 8,
	maxDynamicStorageBuffersPerPipelineLayout = 4,
	maxSampledTexturesPerShaderStage          = 16,
	maxSamplersPerShaderStage                 = 16,
	maxStorageBuffersPerShaderStage           = 4,
	maxStorageTexturesPerShaderStage          = 4,
	maxUniformBuffersPerShaderStage           = 12,
	maxUniformBufferBindingSize               = 16 << 10, // (16 KiB)
	maxStorageBufferBindingSize               = 128 << 20, // (128 MiB)
	minUniformBufferOffsetAlignment           = 256,
	minStorageBufferOffsetAlignment           = 256,
	maxVertexBuffers                          = 8,
	maxBufferSize                             = 256 << 20, // (256 MiB)
	maxVertexAttributes                       = 16,
	maxVertexBufferArrayStride                = 2048,
	maxInterStageShaderVariables              = 16,
	maxColorAttachments                       = 8,
	maxColorAttachmentBytesPerSample          = 32,
	maxComputeWorkgroupStorageSize            = 16352,
	maxComputeInvocationsPerWorkgroup         = 256,
	maxComputeWorkgroupSizeX                  = 256,
	maxComputeWorkgroupSizeY                  = 256,
	maxComputeWorkgroupSizeZ                  = 64,
	maxComputeWorkgroupsPerDimension          = 65535,

	// Native
	maxPushConstantSize                       = 0,
	maxNonSamplerBindings                     = 1_000_000,
}

/*
This is a set of limits that is lower even than the `DOWNLEVEL_LIMITS`,
configured to be low enough to support running in the browser using WebGL2.
*/
LIMITS_DOWNLEVEL_WEBGL2 :: Limits {
	// WebGPU
	maxTextureDimension1D                     = 2048,
	maxTextureDimension2D                     = 2048,
	maxTextureDimension3D                     = 256,
	maxTextureArrayLayers                     = 256,
	maxBindGroups                             = 4,
	maxBindGroupsPlusVertexBuffers            = 24,
	maxBindingsPerBindGroup                   = 1000,
	maxDynamicUniformBuffersPerPipelineLayout = 8,
	maxDynamicStorageBuffersPerPipelineLayout = 0,
	maxSampledTexturesPerShaderStage          = 16,
	maxSamplersPerShaderStage                 = 16,
	maxStorageBuffersPerShaderStage           = 0,
	maxStorageTexturesPerShaderStage          = 0,
	maxUniformBuffersPerShaderStage           = 11,
	maxUniformBufferBindingSize               = 16 << 10, // (16 KiB)
	maxStorageBufferBindingSize               = 0,
	minUniformBufferOffsetAlignment           = 256,
	minStorageBufferOffsetAlignment           = 256,
	maxVertexBuffers                          = 8,
	maxBufferSize                             = 256 << 20, // (256 MiB)
	maxVertexAttributes                       = 16,
	maxVertexBufferArrayStride                = 255,
	maxInterStageShaderVariables              = 16,
	maxColorAttachments                       = 8,
	maxColorAttachmentBytesPerSample          = 32,
	maxComputeWorkgroupStorageSize            = 0,
	maxComputeInvocationsPerWorkgroup         = 0,
	maxComputeWorkgroupSizeX                  = 0,
	maxComputeWorkgroupSizeY                  = 0,
	maxComputeWorkgroupSizeZ                  = 0,
	maxComputeWorkgroupsPerDimension          = 0,

	// Native limits (extras)
	maxPushConstantSize                       = 0,
	maxNonSamplerBindings                     = 1_000_000,
}

LIMITS_MINIMUM_DEFAULT :: LIMITS_DOWNLEVEL

/*
Modify the current limits to use the resolution limits of the other.

This is useful because the swapchain might need to be larger than any other
image in the application.

If your application only needs 512x512, you might be running on a 4k display and
need extremely high resolution limits.
*/
LimitsUsingResolution :: proc "contextless" (self: ^Limits, other: Limits) -> Limits {
	self.maxTextureDimension1D = other.maxTextureDimension1D
	self.maxTextureDimension2D = other.maxTextureDimension2D
	self.maxTextureDimension3D = other.maxTextureDimension3D
	return self^
}

/*
Modify the current limits to use the buffer alignment limits of the adapter.

This is useful for when you'd like to dynamically use the "best" supported
buffer alignments.
*/
LimitsUsingAlignment :: proc "contextless" (self: ^Limits, other: Limits) -> Limits {
	self.minUniformBufferOffsetAlignment = other.minUniformBufferOffsetAlignment
	self.minStorageBufferOffsetAlignment = other.minStorageBufferOffsetAlignment
	return self^
}

Limits_Violation_Value :: struct {
	field_name: string,
	current:    u64,
	allowed:    u64,
}

LIMITS_MAX_VIOLATIONS :: 33

Limits_Violations :: sa.Small_Array(LIMITS_MAX_VIOLATIONS, Limits_Violation_Value)

Limits_Violation :: struct {
	values: Limits_Violations,
	ok:     bool,
}

/*
Compares two `Limits` structures and identifies any violations where the `self`
limits exceed or fall short of the `allowed` limits.

Inputs:

- `self: Limits`: The limits to be checked.
- `allowed: Limits`: The reference limits that `self` is checked against.

Returns:

- `violations: Limits_Violation`: A structure containing information about any
  limit violations.
*/
@(require_results)
LimitsCheck :: proc "c" (
	self: Limits,
	allowed: Limits,
) -> (
	violations: Limits_Violation,
	ok: bool,
) {
	add_violation :: proc "contextless" (
		violations: ^Limits_Violations,
		field_name: string,
		current, allowed: u64,
	) {
		violation := Limits_Violation_Value {
			field_name = field_name,
			current    = current,
			allowed    = allowed,
		}

		ensure_contextless(sa.append(violations, violation), "Too many limit violations")
	}

	check_max :: proc "contextless" (
		violations: ^Limits_Violations,
		field_name: string,
		#any_int current, allowed: u64,
	) {
		if current > allowed {
			add_violation(violations, field_name, current, allowed)
		}
	}

	check_min :: proc "contextless" (
		violations: ^Limits_Violations,
		field_name: string,
		#any_int current, allowed: u64,
	) {
		if current < allowed {
			add_violation(violations, field_name, current, allowed)
		}
	}

	// Check all max limits
	check_max(&violations.values, "maxTextureDimension1D",
		self.maxTextureDimension1D, allowed.maxTextureDimension1D)
	check_max(&violations.values, "maxTextureDimension2D",
		self.maxTextureDimension2D,	allowed.maxTextureDimension2D,
	)
	check_max(&violations.values, "maxTextureDimension3D",
		self.maxTextureDimension3D,	allowed.maxTextureDimension3D,
	)
	check_max(&violations.values, "maxTextureArrayLayers",
		self.maxTextureArrayLayers,	allowed.maxTextureArrayLayers,
	)
	check_max(&violations.values, "maxBindGroups",
		self.maxBindGroups,	allowed.maxBindGroups,
	)
	check_max(&violations.values, "maxDynamicUniformBuffersPerPipelineLayout",
		self.maxDynamicUniformBuffersPerPipelineLayout,
		allowed.maxDynamicUniformBuffersPerPipelineLayout,
	)
	check_max(&violations.values, "maxDynamicStorageBuffersPerPipelineLayout",
		self.maxDynamicStorageBuffersPerPipelineLayout,
		allowed.maxDynamicStorageBuffersPerPipelineLayout,
	)
	check_max(&violations.values, "maxSampledTexturesPerShaderStage",
		self.maxSampledTexturesPerShaderStage,	allowed.maxSampledTexturesPerShaderStage,
	)
	check_max(&violations.values, "maxSamplersPerShaderStage",
		self.maxSamplersPerShaderStage,	allowed.maxSamplersPerShaderStage,
	)
	check_max(&violations.values, "maxStorageBuffersPerShaderStage",
		self.maxStorageBuffersPerShaderStage,	allowed.maxStorageBuffersPerShaderStage,
	)
	check_max(&violations.values, "maxStorageTexturesPerShaderStage",
		self.maxStorageTexturesPerShaderStage,	allowed.maxStorageTexturesPerShaderStage,
	)
	check_max(&violations.values, "maxUniformBuffersPerShaderStage",
		self.maxUniformBuffersPerShaderStage,	allowed.maxUniformBuffersPerShaderStage,
	)
	check_max(&violations.values, "maxUniformBufferBindingSize",
		self.maxUniformBufferBindingSize,	allowed.maxUniformBufferBindingSize,
	)
	check_max(&violations.values, "maxStorageBufferBindingSize",
		self.maxStorageBufferBindingSize,	allowed.maxStorageBufferBindingSize,
	)
	check_max(&violations.values, "maxVertexBuffers",
		self.maxVertexBuffers,	allowed.maxVertexBuffers,
	)
	check_max(&violations.values, "maxVertexAttributes",
		self.maxVertexAttributes,	allowed.maxVertexAttributes,
	)
	check_max(&violations.values, "maxVertexBufferArrayStride",
		self.maxVertexBufferArrayStride,	allowed.maxVertexBufferArrayStride,
	)
	check_max(&violations.values, "maxComputeWorkgroupStorageSize",
		self.maxComputeWorkgroupStorageSize,	allowed.maxComputeWorkgroupStorageSize,
	)
	check_max(&violations.values, "maxComputeInvocationsPerWorkgroup",
		self.maxComputeInvocationsPerWorkgroup,	allowed.maxComputeInvocationsPerWorkgroup,
	)
	check_max(&violations.values, "maxComputeWorkgroupSizeX",
		self.maxComputeWorkgroupSizeX,	allowed.maxComputeWorkgroupSizeX,
	)
	check_max(&violations.values, "maxComputeWorkgroupSizeY",
		self.maxComputeWorkgroupSizeY,	allowed.maxComputeWorkgroupSizeY,
	)
	check_max(&violations.values, "maxComputeWorkgroupSizeZ",
		self.maxComputeWorkgroupSizeZ,	allowed.maxComputeWorkgroupSizeZ,
	)
	check_max(&violations.values, "maxComputeWorkgroupsPerDimension",
		self.maxComputeWorkgroupsPerDimension,	allowed.maxComputeWorkgroupsPerDimension,
	)

	// Check all min limits
	check_min(&violations.values, "minUniformBufferOffsetAlignment",
		self.minUniformBufferOffsetAlignment,	allowed.minUniformBufferOffsetAlignment,
	)
	check_min(&violations.values, "minStorageBufferOffsetAlignment",
		self.minStorageBufferOffsetAlignment,	allowed.minStorageBufferOffsetAlignment,
	)

	// Skip unused fields
	// - maxBindGroupsPlusVertexBuffers
	// - maxInterStageShaderVariables
	// - maxColorAttachments
	// - maxColorAttachmentBytesPerSample

	violations.ok = sa.len(violations.values) == 0
	ok = violations.ok

	return
}

LimitsViolationLog :: proc(violations: Limits_Violation) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	violation_str := LimitsViolationToString(violations, context.temp_allocator)
	log.fatalf("Limits violations detected:\n%s", violation_str)
}

LimitsViolationToString :: proc(
	violation: Limits_Violation,
	allocator := context.allocator,
) -> (
	str: string,
) {
	if violation.ok || sa.len(violation.values) == 0 {
		return
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == context.temp_allocator)

	b := strings.builder_make(context.temp_allocator)
	defer strings.builder_destroy(&b)

	violations := violation.values
	violations_slice := sa.slice(&violations)

	for &value, iter in violations_slice {
		fmt.sbprintf(&b, "%s:\n", value.field_name)
		fmt.sbprintf(&b, "  Current value: %d\n", value.current)
		fmt.sbprintf(&b, "  Allowed value: %d\n", value.allowed)
		strings.write_string(&b, "  Violation: ")

		if value.current > value.allowed {
			strings.write_string(&b, "Value exceeds the maximum allowed.\n")
		} else {
			strings.write_string(&b, "Value is below the minimum required.\n")
		}

		if iter > 1 {
			strings.write_string(&b, "\n")
		}
	}

	str = strings.clone(strings.to_string(b), allocator)

	return
}

LimitsEnsureMinimum :: proc "contextless" (a: ^Limits, b := LIMITS_MINIMUM_DEFAULT) -> Limits {
	// WebGPU
	a.maxTextureDimension1D = max(a.maxTextureDimension1D, b.maxTextureDimension1D)
	a.maxTextureDimension2D = max(a.maxTextureDimension2D, b.maxTextureDimension2D)
	a.maxTextureDimension3D = max(a.maxTextureDimension3D, b.maxTextureDimension3D)
	a.maxTextureArrayLayers = max(a.maxTextureArrayLayers, b.maxTextureArrayLayers)
	a.maxBindGroups = max(a.maxBindGroups, b.maxBindGroups)
	a.maxBindGroupsPlusVertexBuffers = max(
		a.maxBindGroupsPlusVertexBuffers,
		b.maxBindGroupsPlusVertexBuffers,
	)
	a.maxBindingsPerBindGroup = max(
		a.maxBindingsPerBindGroup,
		b.maxBindingsPerBindGroup,
	)
	a.maxDynamicUniformBuffersPerPipelineLayout = max(
		a.maxDynamicUniformBuffersPerPipelineLayout,
		b.maxDynamicUniformBuffersPerPipelineLayout,
	)
	a.maxDynamicStorageBuffersPerPipelineLayout = max(
		a.maxDynamicStorageBuffersPerPipelineLayout,
		b.maxDynamicStorageBuffersPerPipelineLayout,
	)
	a.maxSampledTexturesPerShaderStage = max(
		a.maxSampledTexturesPerShaderStage,
		b.maxSampledTexturesPerShaderStage,
	)
	a.maxSamplersPerShaderStage = max(
		a.maxSamplersPerShaderStage,
		b.maxSamplersPerShaderStage,
	)
	a.maxStorageBuffersPerShaderStage = max(
		a.maxStorageBuffersPerShaderStage,
		b.maxStorageBuffersPerShaderStage,
	)
	a.maxStorageTexturesPerShaderStage = max(
		a.maxStorageTexturesPerShaderStage,
		b.maxStorageTexturesPerShaderStage,
	)
	a.maxUniformBuffersPerShaderStage = max(
		a.maxUniformBuffersPerShaderStage,
		b.maxUniformBuffersPerShaderStage,
	)
	a.maxUniformBufferBindingSize = max(
		a.maxUniformBufferBindingSize,
		b.maxUniformBufferBindingSize,
	)
	a.maxStorageBufferBindingSize = max(
		a.maxStorageBufferBindingSize,
		b.maxStorageBufferBindingSize,
	)
	a.minUniformBufferOffsetAlignment = min(
		a.minUniformBufferOffsetAlignment,
		b.minUniformBufferOffsetAlignment,
	)
	a.minStorageBufferOffsetAlignment = min(
		a.minStorageBufferOffsetAlignment,
		b.minStorageBufferOffsetAlignment,
	)
	a.maxVertexBuffers = max(a.maxVertexBuffers, b.maxVertexBuffers)
	a.maxBufferSize = max(a.maxBufferSize, b.maxBufferSize)
	a.maxVertexAttributes = max(a.maxVertexAttributes, b.maxVertexAttributes)
	a.maxVertexBufferArrayStride = max(
		a.maxVertexBufferArrayStride,
		b.maxVertexBufferArrayStride,
	)
	a.maxInterStageShaderVariables = max(
		a.maxInterStageShaderVariables,
		b.maxInterStageShaderVariables,
	)
	a.maxColorAttachments = max(a.maxColorAttachments, b.maxColorAttachments)
	a.maxColorAttachmentBytesPerSample = max(
		a.maxColorAttachmentBytesPerSample,
		b.maxColorAttachmentBytesPerSample,
	)
	a.maxComputeWorkgroupStorageSize = max(
		a.maxComputeWorkgroupStorageSize,
		b.maxComputeWorkgroupStorageSize,
	)
	a.maxComputeInvocationsPerWorkgroup = max(
		a.maxComputeInvocationsPerWorkgroup,
		b.maxComputeInvocationsPerWorkgroup,
	)
	a.maxComputeWorkgroupSizeX = max(
		a.maxComputeWorkgroupSizeX,
		b.maxComputeWorkgroupSizeX,
	)
	a.maxComputeWorkgroupSizeY = max(
		a.maxComputeWorkgroupSizeY,
		b.maxComputeWorkgroupSizeY,
	)
	a.maxComputeWorkgroupSizeZ = max(
		a.maxComputeWorkgroupSizeZ,
		b.maxComputeWorkgroupSizeZ,
	)
	a.maxComputeWorkgroupsPerDimension = max(
		a.maxComputeWorkgroupsPerDimension,
		b.maxComputeWorkgroupsPerDimension,
	)

	// Native
	a.maxPushConstantSize = max(a.maxPushConstantSize, b.maxPushConstantSize)
	a.maxNonSamplerBindings = max(a.maxNonSamplerBindings, b.maxNonSamplerBindings)

	return a^
}

@(private)
_LimitsMergeWebGPUWithNative :: proc "contextless" (
	webgpu: wgpu.Limits,
	native: wgpu.NativeLimits,
) -> (
	limits: Limits,
) {
	limits = {
		maxTextureDimension1D                     = webgpu.maxTextureDimension1D,
		maxTextureDimension2D                     = webgpu.maxTextureDimension2D,
		maxTextureDimension3D                     = webgpu.maxTextureDimension3D,
		maxTextureArrayLayers                     = webgpu.maxTextureArrayLayers,
		maxBindGroups                             = webgpu.maxBindGroups,
		maxBindGroupsPlusVertexBuffers            = webgpu.maxBindGroupsPlusVertexBuffers,
		maxBindingsPerBindGroup                   = webgpu.maxBindingsPerBindGroup,
		maxDynamicUniformBuffersPerPipelineLayout = webgpu.maxDynamicUniformBuffersPerPipelineLayout,
		maxDynamicStorageBuffersPerPipelineLayout = webgpu.maxDynamicStorageBuffersPerPipelineLayout,
		maxSampledTexturesPerShaderStage          = webgpu.maxSampledTexturesPerShaderStage,
		maxSamplersPerShaderStage                 = webgpu.maxSamplersPerShaderStage,
		maxStorageBuffersPerShaderStage           = webgpu.maxStorageBuffersPerShaderStage,
		maxStorageTexturesPerShaderStage          = webgpu.maxStorageTexturesPerShaderStage,
		maxUniformBuffersPerShaderStage           = webgpu.maxUniformBuffersPerShaderStage,
		maxUniformBufferBindingSize               = webgpu.maxUniformBufferBindingSize,
		maxStorageBufferBindingSize               = webgpu.maxStorageBufferBindingSize,
		minUniformBufferOffsetAlignment           = webgpu.minUniformBufferOffsetAlignment,
		minStorageBufferOffsetAlignment           = webgpu.minStorageBufferOffsetAlignment,
		maxVertexBuffers                          = webgpu.maxVertexBuffers,
		maxBufferSize                             = webgpu.maxBufferSize,
		maxVertexAttributes                       = webgpu.maxVertexAttributes,
		maxVertexBufferArrayStride                = webgpu.maxVertexBufferArrayStride,
		maxInterStageShaderVariables              = webgpu.maxInterStageShaderVariables,
		maxColorAttachments                       = webgpu.maxColorAttachments,
		maxColorAttachmentBytesPerSample          = webgpu.maxColorAttachmentBytesPerSample,
		maxComputeWorkgroupStorageSize            = webgpu.maxComputeWorkgroupStorageSize,
		maxComputeInvocationsPerWorkgroup         = webgpu.maxComputeInvocationsPerWorkgroup,
		maxComputeWorkgroupSizeX                  = webgpu.maxComputeWorkgroupSizeX,
		maxComputeWorkgroupSizeY                  = webgpu.maxComputeWorkgroupSizeY,
		maxComputeWorkgroupSizeZ                  = webgpu.maxComputeWorkgroupSizeZ,
		maxComputeWorkgroupsPerDimension          = webgpu.maxComputeWorkgroupsPerDimension,

		// Native
		maxPushConstantSize                       = native.maxPushConstantSize,
		maxNonSamplerBindings                     = native.maxNonSamplerBindings,
	}

	return
}
