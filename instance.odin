package webgpu

// Vendor
import "vendor:wgpu"

/*
Context for all other wgpu objects. Instance of wgpu.

This is the first thing you create when using wgpu.
Its primary use is to create `Adapter`s and `Surface`s.

Does not have to be kept alive.

Corresponds to [WebGPU `GPU`](https://gpuweb.github.io/gpuweb/#gpu-interface).
*/
Instance :: wgpu.Instance

/* Represents a backend that wgpu can use. */
InstanceBackend :: wgpu.InstanceBackend

/* Represents the backends that wgpu will use. */
Backends :: wgpu.InstanceBackendFlags

/* Use all supported backends. */
BACKENDS_ALL :: wgpu.InstanceBackendFlags_All

/* Use only the primary backends that has better support. */
BACKENDS_PRIMARY :: wgpu.InstanceBackendFlags_Primary

/* Use only the secondary backends that has less support. */
BACKENDS_SECONDARY :: wgpu.InstanceBackendFlags_Secondary

/*
Instance debugging flags.

These are not part of the WebGPU standard.
*/
InstanceFlags :: wgpu.InstanceFlags

/* Use no flags. */
INSTANCE_FLAGS_DEFAULT :: InstanceFlags{}

/* Enable recommended debugging and validation flags. */
INSTANCE_FLAGS_DEBUGGING :: InstanceFlags{ .Debug, .Validation }

/* Features enabled on the Instance. */
InstanceCapabilities :: wgpu.InstanceCapabilities

/*
Selects which DX12 shader compiler to fuse.

If the `Dxc` option is selected, but `dxcompiler.dll` and `dxil.dll` files
aren't found, then this will fall back to the Fxc compiler at runtime and log an error.

Options:

- Fxc: Use the legacy FXC (D3DCompiler) shader compiler
- Dxc: Use the modern DXC (DirectXShaderCompiler) for better optimization and
  newer shader models
*/
Dx12Compiler :: wgpu.Dx12Compiler

/*
Specifies the minor version of OpenGL ES 3.x to target. This affects which
OpenGL ES features are available and how shaders are compiled.

Options:

- Automatic: Let WGPU automatically select the best available version
- Version0: Target OpenGL ES 3.0 (minimum required version)
- Version1: Target OpenGL ES 3.1 (adds compute shaders, additional texture formats)
- Version2: Target OpenGL ES 3.2 (adds geometry shaders, tessellation,
  additional features)
*/
Gles3MinorVersion :: wgpu.Gles3MinorVersion

/*
Controls how OpenGL fences are handled for synchronization.

Options:

- Normal: Use standard OpenGL fence behavior
- AutoFinish: Automatically call `glFinish()` to ensure GPU operations complete
*/
GLFenceBehaviour :: wgpu.GLFenceBehaviour

/*
Specifies the maximum DirectX Shader Model version to use with the DXC compiler.
Higher shader models support more advanced features but require newer hardware.

Options:

- V6_0: Shader Model 6.0 (adds wave intrinsics)
- V6_1: Shader Model 6.1 (adds SV_ViewID for VR)
- V6_2: Shader Model 6.2 (adds 16-bit types)
- V6_3: Shader Model 6.3 (adds DXR raytracing)
- V6_4: Shader Model 6.4 (adds integer dot product)
- V6_5: Shader Model 6.5 (adds DXR 1.1, mesh shaders)
- V6_6: Shader Model 6.6 (adds compute shader derivatives)
- V6_7: Shader Model 6.7 (adds advanced texture ops)
*/
DxcMaxShaderModel :: wgpu.DxcMaxShaderModel

/* Options for creating an instance. */
InstanceDescriptor :: struct {
	/* WebGPU */
	features: InstanceCapabilities,

	/* WGPU Native */
	backends: Backends,
	flags:    InstanceFlags,
	dx12: struct {
		shaderCompiler:    Dx12Compiler,
		dxilPath:          string,
		dxcPath:           string,
		dcxMaxShaderModel: DxcMaxShaderModel,
	},
	gl: struct {
		gles3MinorVersion: Gles3MinorVersion,
		fenceBehaviour:    GLFenceBehaviour,
	},
}

INSTANCE_DESCRIPTOR_DEFAULT :: InstanceDescriptor {
	backends = BACKENDS_PRIMARY,
	flags    = INSTANCE_FLAGS_DEFAULT,
}

/*
Create an new instance of wgpu.

**Panics**

If no backend feature for the active target platform is enabled, this procedure will panic.
*/
@(require_results)
CreateInstance :: proc "c" (descriptor: Maybe(InstanceDescriptor) = nil) -> (instance: Instance) {
	if desc, desc_ok := descriptor.?; desc_ok {
		raw_desc: wgpu.InstanceDescriptor
		raw_desc.features = desc.features

		when ODIN_OS != .JS {
			instance_extras := wgpu.InstanceExtras {
				chain               = { sType = .InstanceExtras },
				backends            = desc.backends,
				flags               = desc.flags,
				dx12ShaderCompiler  = desc.dx12.shaderCompiler,
				gles3MinorVersion   = desc.gl.gles3MinorVersion,
				glFenceBehaviour    = desc.gl.fenceBehaviour,
				dxilPath            = desc.dx12.dxilPath,
				dxcPath             = desc.dx12.dxcPath,
				dcxMaxShaderModel   = desc.dx12.dcxMaxShaderModel,
			}

			raw_desc.nextInChain = &instance_extras.chain
		}

		instance = wgpu.CreateInstance(&raw_desc)
	} else {
		instance = wgpu.CreateInstance(nil)
	}

	return
}

FeatureLevel :: wgpu.FeatureLevel

/*
Power Preference when choosing a physical adapter.

Corresponds to [WebGPU `GPUPowerPreference`](
https://gpuweb.github.io/gpuweb/#enumdef-gpupowerpreference).
*/
PowerPreference :: wgpu.PowerPreference

/* Use `HighPerformance`. */
POWER_PREFERENCE_DEFAULT: PowerPreference = .HighPerformance

/*
Options for requesting adapter.

Corresponds to [WebGPU `GPURequestAdapterOptions`](
https://gpuweb.github.io/gpuweb/#dictdef-gpurequestadapteroptions).
 */
RequestAdapterOptions :: struct {
	featureLevel:         FeatureLevel,
	compatibleSurface:    Surface,
	powerPreference:      PowerPreference,
	backend:              Backend,
	forceFallbackAdapter: bool,
}

/*
Retrieves an `Adapter` which matches the given `RequestAdapterOptions`.

Some options are "soft", so treated as non-mandatory. Others are "hard".

If no adapters are found that suffice all the "hard" options, `nil` is returned.

A `compatibleSurface` is required when targeting WebGL2.
*/
InstanceRequestAdapter :: proc "c" (
	self: Instance,
	options: Maybe(RequestAdapterOptions) = nil,
	callbackInfo: wgpu.RequestAdapterCallbackInfo,
) -> (
	future: wgpu.Future,
) {
	if opt, opt_ok := options.?; opt_ok {
		raw_options := wgpu.RequestAdapterOptions {
			featureLevel         = opt.featureLevel,
			powerPreference      = opt.powerPreference,
			forceFallbackAdapter = b32(opt.forceFallbackAdapter),
			backendType          = opt.backend,
			compatibleSurface    = opt.compatibleSurface,
		}

		future = wgpu.InstanceRequestAdapter(self, &raw_options, callbackInfo)
	} else {
		future = wgpu.InstanceRequestAdapter(self, nil, callbackInfo)
	}

	return
}

SurfaceSourceAndroidNativeWindow :: wgpu.SurfaceSourceAndroidNativeWindow
SurfaceSourceCanvasHTMLSelector  :: wgpu.SurfaceSourceCanvasHTMLSelector
SurfaceSourceMetalLayer          :: wgpu.SurfaceSourceMetalLayer
SurfaceSourceWaylandSurface      :: wgpu.SurfaceSourceWaylandSurface
SurfaceSourceWindowsHWND         :: wgpu.SurfaceSourceWindowsHWND
SurfaceSourceXcbWindow           :: wgpu.SurfaceSourceXcbWindow
SurfaceSourceXlibWindow          :: wgpu.SurfaceSourceXlibWindow
// SurfaceSourceSwapChainPanel      :: wgpu.SurfaceSourceSwapChainPanel

/* Describes a surface target. */
SurfaceDescriptor :: struct {
	label:  string,
	target: union {
		SurfaceSourceAndroidNativeWindow,
		SurfaceSourceCanvasHTMLSelector,
		SurfaceSourceMetalLayer,
		SurfaceSourceWaylandSurface,
		SurfaceSourceWindowsHWND,
		SurfaceSourceXcbWindow,
		SurfaceSourceXlibWindow,
		// SurfaceSourceSwapChainPanel,
	},
}

/* Creates a surface from a window target. */
@(require_results)
InstanceCreateSurface :: proc "c" (
	self: Instance,
	descriptor: SurfaceDescriptor,
) -> (
	surface: Surface,
) {
	raw_desc: wgpu.SurfaceDescriptor
	raw_desc.label = descriptor.label

	switch &t in descriptor.target {
	case SurfaceSourceAndroidNativeWindow:
		t.chain.sType = .SurfaceSourceAndroidNativeWindow
		raw_desc.nextInChain = &t.chain

	case SurfaceSourceCanvasHTMLSelector:
		t.chain.sType = .SurfaceSourceCanvasHTMLSelector
		raw_desc.nextInChain = &t.chain

	case SurfaceSourceMetalLayer:
		t.chain.sType = .SurfaceSourceMetalLayer
		raw_desc.nextInChain = &t.chain

	case SurfaceSourceWaylandSurface:
		t.chain.sType = .SurfaceSourceWaylandSurface
		raw_desc.nextInChain = &t.chain

	case SurfaceSourceWindowsHWND:
		t.chain.sType = .SurfaceSourceWindowsHWND
		raw_desc.nextInChain = &t.chain

	case SurfaceSourceXcbWindow:
		t.chain.sType = .SurfaceSourceXCBWindow
		raw_desc.nextInChain = &t.chain

	case SurfaceSourceXlibWindow:
		t.chain.sType = .SurfaceSourceXlibWindow
		raw_desc.nextInChain = &t.chain

	// case SurfaceSourceSwapChainPanel:
	// 	t.chain.sType = .SurfaceSourceSwapChainPanel
	// 	raw_desc.nextInChain = &t.chain
	}

	surface = wgpu.InstanceCreateSurface(self, &raw_desc)

	return
}

/* Processes pending WebGPU events on the instance. */
InstanceProcessEvents :: wgpu.InstanceProcessEvents

/* Increase the reference count. */
InstanceAddRef :: #force_inline proc "c" (self: Instance) {
	wgpu.InstanceAddRef(self)
}

/* Release the `Instance` resources. */
InstanceRelease :: #force_inline proc "c" (self: Instance) {
	wgpu.InstanceRelease(self)
}

/*
Safely releases the `Instance` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
InstanceReleaseSafe :: #force_inline proc "c" (self: ^Instance) {
	if self != nil && self^ != nil {
		wgpu.InstanceRelease(self^)
		self^ = nil
	}
}
