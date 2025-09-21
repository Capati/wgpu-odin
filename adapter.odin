package webgpu

// Core
import "base:runtime"
import "core:fmt"
import "core:strings"
import sa "core:container/small_array"

// Vendor
import "vendor:wgpu"

/*
Handle to a physical graphics and/or compute device.

Adapters can be created using `InstanceRequestAdapter`.

Adapters can be used to open a connection to the corresponding `Device`
on the host system by using `AdapterRequestDevice`.

Does not have to be kept alive.

Corresponds to [WebGPU `GPUAdapter`](https://gpuweb.github.io/gpuweb/#gpu-adapter).
*/
Adapter :: wgpu.Adapter

/* Describes the default queue. */
QueueDescriptor :: wgpu.QueueDescriptor

/*
Describes a `Device`.

For use with `AdapterRequestDevice`.

Corresponds to [WebGPU `GPUDeviceDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpudevicedescriptor).
*/
DeviceDescriptor :: struct {
	label:                       string,
	optionalFeatures:            Features,
	requiredFeatures:            Features,
	requiredLimits:              Limits,
	defaultQueue:                QueueDescriptor,
	deviceLostCallbackInfo:      DeviceLostCallbackInfo,
	uncapturedErrorCallbackInfo: UncapturedErrorCallbackInfo,
	tracePath:                   string,
}

RequestDeviceResult :: struct {
	status:  RequestDeviceStatus,
	message: string,
	device:  Device,
}

/*
Requests a connection to a physical device, creating a logical device.

[Per the WebGPU specification], an `Adapter` may only be used once to create a
device. If another device is wanted, call `InstanceRequestAdapter` again to get
a fresh `Adapter`. However, `wgpu` does not currently enforce this restriction.

**Panics**:
- `AdapterRequestDevice()` was already called on this `Adapter`.
- Features specified by `descriptor` are not supported by this adapter.
- Unsafe features were requested but not enabled when requesting the adapter.
- Limits requested exceed the values provided by the adapter.
- Adapter does not support all features wgpu requires to safely operate.

[Per the WebGPU specification]:
https://www.w3.org/TR/webgpu/#dom-gpuadapter-requestdevice
*/
@(require_results)
AdapterRequestDevice :: proc "c" (
	self: Adapter,
	descriptor: Maybe(DeviceDescriptor) = nil,
	loc := #caller_location,
) -> (
	res: RequestDeviceResult,
) {
	desc, desc_ok := descriptor.?
	if !desc_ok {
		return _adapter_request_device(self, nil)
	}

	raw_desc: wgpu.DeviceDescriptor
	raw_desc.label = desc.label

	adapter_features := AdapterFeatures(self)

	required_features := desc.requiredFeatures
	for f in desc.optionalFeatures {
		if f in adapter_features {
			required_features += {f}
		}
	}

	features: sa.Small_Array(MAX_FEATURES, wgpu.FeatureName)

	// Check for unsupported features
	if required_features != {} {
		for f in required_features {
			if f not_in adapter_features {
				panic_contextless("Required feature not supported by device/backend.", loc)
			}
			sa.push_back(&features, _FeatureFlagsToName(f))
		}

		raw_desc.requiredFeatureCount = uint(sa.len(features))
		raw_desc.requiredFeatures = raw_data(sa.slice(&features))
	}

	adapter_limits := AdapterLimits(self)

	// If no limits is provided, default to the most restrictive limits
	limits := desc.requiredLimits if desc.requiredLimits != {} else LIMITS_MINIMUM_DEFAULT

	// WGPU returns 0 for unused limits
	// Enforce minimum values for all limits even if the current values are lower
	LimitsEnsureMinimum(&limits, LIMITS_MINIMUM_DEFAULT)

	// Check for unsupported limits
	if limits != LIMITS_MINIMUM_DEFAULT {
		if _, limits_ok := LimitsCheck(limits, adapter_limits); !limits_ok {
			panic_contextless("Limits violations detected.", loc)
		}
	}

	raw_limits := wgpu.Limits {
		maxTextureDimension1D                     = limits.maxTextureDimension1D,
		maxTextureDimension2D                     = limits.maxTextureDimension2D,
		maxTextureDimension3D                     = limits.maxTextureDimension3D,
		maxTextureArrayLayers                     = limits.maxTextureArrayLayers,
		maxBindGroups                             = limits.maxBindGroups,
		maxBindGroupsPlusVertexBuffers            = limits.maxBindGroupsPlusVertexBuffers,
		maxBindingsPerBindGroup                   = limits.maxBindingsPerBindGroup,
		maxDynamicUniformBuffersPerPipelineLayout = limits.maxDynamicUniformBuffersPerPipelineLayout,
		maxDynamicStorageBuffersPerPipelineLayout = limits.maxDynamicStorageBuffersPerPipelineLayout,
		maxSampledTexturesPerShaderStage          = limits.maxSampledTexturesPerShaderStage,
		maxSamplersPerShaderStage                 = limits.maxSamplersPerShaderStage,
		maxStorageBuffersPerShaderStage           = limits.maxStorageBuffersPerShaderStage,
		maxStorageTexturesPerShaderStage          = limits.maxStorageTexturesPerShaderStage,
		maxUniformBuffersPerShaderStage           = limits.maxUniformBuffersPerShaderStage,
		maxUniformBufferBindingSize               = limits.maxUniformBufferBindingSize,
		maxStorageBufferBindingSize               = limits.maxStorageBufferBindingSize,
		minUniformBufferOffsetAlignment           = limits.minUniformBufferOffsetAlignment,
		minStorageBufferOffsetAlignment           = limits.minStorageBufferOffsetAlignment,
		maxVertexBuffers                          = limits.maxVertexBuffers,
		maxBufferSize                             = limits.maxBufferSize,
		maxVertexAttributes                       = limits.maxVertexAttributes,
		maxVertexBufferArrayStride                = limits.maxVertexBufferArrayStride,
		maxInterStageShaderVariables              = limits.maxInterStageShaderVariables,
		maxColorAttachments                       = limits.maxColorAttachments,
		maxColorAttachmentBytesPerSample          = limits.maxColorAttachmentBytesPerSample,
		maxComputeWorkgroupStorageSize            = limits.maxComputeWorkgroupStorageSize,
		maxComputeInvocationsPerWorkgroup         = limits.maxComputeInvocationsPerWorkgroup,
		maxComputeWorkgroupSizeX                  = limits.maxComputeWorkgroupSizeX,
		maxComputeWorkgroupSizeY                  = limits.maxComputeWorkgroupSizeY,
		maxComputeWorkgroupSizeZ                  = limits.maxComputeWorkgroupSizeZ,
		maxComputeWorkgroupsPerDimension          = limits.maxComputeWorkgroupsPerDimension,
	}

	when ODIN_OS != .JS {
		native_limits := wgpu.NativeLimits {
			chain                 = { sType = .NativeLimits },
			maxPushConstantSize   = limits.maxPushConstantSize,
			maxNonSamplerBindings = limits.maxNonSamplerBindings,
		}
		raw_limits.nextInChain = &native_limits.chain
	}

	raw_desc.requiredLimits = &raw_limits

	raw_desc.defaultQueue = desc.defaultQueue

	raw_desc.deviceLostCallbackInfo = desc.deviceLostCallbackInfo
	raw_desc.uncapturedErrorCallbackInfo = desc.uncapturedErrorCallbackInfo

	when ODIN_DEBUG && ODIN_OS != .JS {
		device_extras := wgpu.DeviceExtras {
			chain = { sType = .DeviceExtras },
		}
		// Write a trace of all commands to a file so it can be reproduced
		// elsewhere. The trace is cross-platform.
		if desc.tracePath != "" {
			device_extras.tracePath = desc.tracePath
			raw_desc.nextInChain = &device_extras.chain
		}
	}

	return _adapter_request_device(self, &raw_desc)
}

@(private)
_adapter_request_device :: proc "c" (
	self: Adapter,
	descriptor: ^wgpu.DeviceDescriptor = nil,
) -> (
	res: RequestDeviceResult,
) {
	adapter_request_device_callback :: proc "c" (
		status: RequestDeviceStatus,
		device: Device,
		message: string,
		userdata1: rawptr,
		userdata2: rawptr,
	) {
		result := cast(^RequestDeviceResult)userdata1

		result.status = status
		result.message = message
		result.device = nil

		if status == .Success {
			result.device = device
		}
	}

	callback_info := wgpu.RequestDeviceCallbackInfo {
		callback  = adapter_request_device_callback,
		userdata1 = &res,
	}

	wgpu.AdapterRequestDevice(self, descriptor, callback_info)

	return
}

/* Returns whether this adapter may present to the passed surface. */
AdapterIsSurfaceSupported :: proc "c" (self: Adapter, surface: Surface) -> bool {
	caps, status := wgpu.SurfaceGetCapabilities(surface, self)
	defer wgpu.SurfaceCapabilitiesFreeMembers(caps)
	// If wgpu.SurfaceCapabilitiesFreeMembers returns Error, then the API does
	// not advertise support for the given surface and adapter.
	return status == .Success
}

/* The features which can be used to create devices on this adapter. */
AdapterFeatures :: proc "c" (self: Adapter) -> (features: Features) #no_bounds_check {
	supported := wgpu.AdapterGetFeatures(self)
	defer wgpu.SupportedFeaturesFreeMembers(supported)

	raw_features := supported.features[:supported.featureCount]
	features = _FeaturesSliceToFlags(raw_features)

	return
}

AdapterHasFeature :: proc "c" (self: Adapter, features: Features) -> bool {
	if features == {} {
		return true
	}
	available := AdapterFeatures(self)
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

/* The best limits which can be used to create devices on this adapter. */
AdapterLimits :: proc "c" (self: Adapter) -> (limits: Limits) {
	raw_limits: wgpu.Limits

	when ODIN_OS != .JS {
		native := wgpu.NativeLimits {
			chain = { sType = .NativeLimits },
		}
		raw_limits.nextInChain = &native.chain
	}

	status := wgpu.RawAdapterGetLimits(self, &raw_limits)
	if status != .Success {
		return
	}

	limits = _LimitsMergeWebGPUWithNative(raw_limits, native)

	// WGPU returns 0 for unused limits
	// Enforce minimum values for all limits even if the returned values are lower
	LimitsEnsureMinimum(&limits, LIMITS_MINIMUM_DEFAULT)

	return
}

/* Information about an adapter.*/
AdapterInfo :: wgpu.AdapterInfo

/* Get info about the adapter itself. */
AdapterGetInfo :: wgpu.AdapterGetInfo

/* Release the `AdapterInfo` resources (remove the allocated strings). */
AdapterInfoFreeMembers :: wgpu.AdapterInfoFreeMembers

/*
Returns the features supported for a given texture format by this adapter.

Note that the WebGPU spec further restricts the available usages/features. To
disable these restrictions on a device, request the feature
`TextureAdapterSpecificFormatFeatures`.
*/
AdapterGetTextureFormatFeatures :: proc "c" (
	self: Adapter,
	format: TextureFormat,
) -> (
	features: TextureFormatFeatures,
) {
	adapter_features := AdapterFeatures(self)
	return TextureFormatGuaranteedFormatFeatures(format, adapter_features)
}

/*  Increase the `Adapter` reference count. */
AdapterAddRef :: wgpu.AdapterAddRef

/*  Release the `Adapter` resources, use to decrease the reference count. */
AdapterRelease :: wgpu.AdapterRelease

/*
Safely releases the `Adapter` resources and invalidates the handle.
The procedure checks both the pointer validity and the adapter handle before releasing.

Note: After calling this, the adapter handle will be set to `nil` and should not be used.
*/
AdapterReleaseSafe :: proc "c" (self: ^Adapter) {
	if self != nil && self^ != nil {
		wgpu.AdapterRelease(self^)
		self^ = nil
	}
}

/* Get info about the adapter itself as `string`. */
AdapterInfoString :: proc(
	info: AdapterInfo,
	allocator := context.allocator,
) -> (
	str: string,
) {
	sb: strings.Builder
	err: runtime.Allocator_Error

	ta := context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == ta)
	if sb, err = strings.builder_make(ta); err != nil {
		return
	}
	defer strings.builder_destroy(&sb)

	strings.write_string(&sb, info.device)
	strings.write_byte(&sb, '\n')

	strings.write_string(&sb, "  - Driver: ")
	strings.write_string(&sb, info.description if info.description != "" else "Unknown")
	strings.write_byte(&sb, '\n')

	adapterType: string
	switch info.adapterType {
	case .DiscreteGPU:
		adapterType = "Discrete GPU with separate CPU/GPU memory"
	case .IntegratedGPU:
		adapterType = "Integrated GPU with shared CPU/GPU memory"
	case .CPU:
		adapterType = "Cpu / Software Rendering"
	case .Unknown:
		adapterType = "Unknown"
	}
	strings.write_string(&sb, "  - Type: ")
	strings.write_string(&sb, adapterType)
	strings.write_byte(&sb, '\n')

	backend: string
	#partial switch info.backendType {
	case .Null:
		backend = "Empty"
	case .WebGPU:
		backend = "WebGPU in the browser"
	case .D3D11:
		backend = "Direct3D-11"
	case .D3D12:
		backend = "Direct3D-12"
	case .Metal:
		backend = "Metal API"
	case .Vulkan:
		backend = "Vulkan API"
	case .OpenGL:
		backend = "OpenGL"
	case .OpenGLES:
		backend = "OpenGLES"
	}
	strings.write_string(&sb, "  - Backend: ")
	strings.write_string(&sb, backend)

	if str, err = strings.clone(strings.to_string(sb), allocator); err != nil {
		return
	}

	return
}

/* Print info about the adapter itself. */
AdapterInfoPrint :: proc(info: AdapterInfo) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	fmt.printfln("%s", AdapterInfoString(info, context.temp_allocator))
}
