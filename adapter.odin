package webgpu

// Core
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
AdapterRequestDevice :: proc "c" (
	self: Adapter,
	descriptor: Maybe(DeviceDescriptor) = nil,
	callbackInfo: RequestDeviceCallbackInfo,
	loc := #caller_location,
) -> (
	future: Future,
) {
	desc, desc_ok := descriptor.?
	if !desc_ok {
		return wgpu.AdapterRequestDevice(self, nil, callbackInfo)
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
			sa.push_back(&features, _feature_flags_to_name(f))
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

	return wgpu.AdapterRequestDevice(self, &raw_desc, callbackInfo)
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

	when ODIN_OS != .JS {
		limits = _LimitsMergeWebGPUWithNative(raw_limits, native)
	} else {
		limits = _LimitsMergeWebGPUWithNative(raw_limits, {})
	}

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

/* Increase the `Adapter` reference count. */
AdapterAddRef :: #force_inline proc "c" (self: Adapter) {
	wgpu.AdapterAddRef(self)
}

/* Release the `Adapter` resources, use to decrease the reference count. */
AdapterRelease :: #force_inline proc "c" (self: Adapter) {
	wgpu.AdapterRelease(self)
}

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
