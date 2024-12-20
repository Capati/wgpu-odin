package wgpu

// odinfmt: disable
@(private) WGPU_SHARED :: #config(WGPU_SHARED, true)
@(private) WGPU_USE_SYSTEM_LIBRARIES :: #config(WGPU_USE_SYSTEM_LIBRARIES, false)

when ODIN_OS == .Windows {
	when ODIN_ARCH == .amd64 {
		ARCH :: "x86_64"
	} else when ODIN_ARCH == .i386 {
		ARCH :: "i386"
	} else {
		#panic("Unsupported WGPU Native architecture")
	}

	@(private) EXT  :: ".dll.lib" when WGPU_SHARED else ".lib"
	@(private) LIB  :: "lib/windows/" + ARCH + "/wgpu_native" + EXT

	when !#exists(LIB) {
		#panic("Could not find the compiled WGPU Native library at '" + #directory + LIB + "'")
	}

	when WGPU_SHARED {
		foreign import wgpu_native {LIB}
	} else {
		foreign import wgpu_native {
			LIB,
			"system:gdi32.lib",
			"system:dxgi.lib",
			"system:d3dcompiler.lib",
			"system:opengl32.lib",
			"system:user32.lib",
			"system:dwmapi.lib",
			"system:bcrypt.lib",
			"system:ws2_32.lib",
			"system:userenv.lib",
			"system:dbghelp.lib",
			"system:advapi32.lib",
			"system:ntdll.lib",
		}
	}
} else when ODIN_OS == .Darwin {
	when WGPU_USE_SYSTEM_LIBRARIES {
		foreign import wgpu_native "system:wgpu_native"
	} else {
		when ODIN_ARCH == .amd64 {
			@(private) ARCH :: "x86_64"
		} else when ODIN_ARCH == .arm64 {
			@(private) ARCH :: "aarch64"
		} else {
			#panic("Unsupported WGPU Native architecture")
		}

		@(private) LIB  :: "lib/mac_os/" + ARCH + "/libwgpu_native.a"

		when !#exists(LIB) {
			#panic("Could not find the compiled WGPU Native library at '" + #directory + LIB + "'")
		}

		foreign import wgpu_native {
			LIB,
			// "system:CoreFoundation.framework",
			// "system:QuartzCore.framework",
			// "system:Metal.framework",
		}
	}
} else when ODIN_OS == .Linux {
	when WGPU_USE_SYSTEM_LIBRARIES {
		foreign import wgpu_native "system:wgpu_native"
	} else {
		when ODIN_ARCH == .amd64 {
			ARCH :: "x86_64"
		} else when ODIN_ARCH == .arm64 {
			ARCH :: "aarch64"
		} else {
			#panic("Unsupported WGPU Native architecture")
		}

		@(private) LIB  :: "lib/linux/" + ARCH + "/libwgpu_native.a"

		when !#exists(LIB) {
			#panic("Could not find the compiled WGPU Native library at '" + #directory + LIB + "'")
		}

		foreign import wgpu_native {LIB}
	}
} else {
	foreign import wgpu_native "system:wgpu_native"
}
// odinfmt: enable

ARRAY_LAYER_COUNT_UNDEFINED :: max(u32)
COPY_STRIDE_UNDEFINED :: max(u32)
DEPTH_SLICE_UNDEFINED :: max(u32)
LIMIT_U32_UNDEFINED :: max(u32)
LIMIT_U64_UNDEFINED :: max(u64)
MIP_LEVEL_COUNT_UNDEFINED :: max(u32)
QUERY_SET_INDEX_UNDEFINED :: max(u32)
WHOLE_MAP_SIZE :: max(uint)
WHOLE_SIZE :: max(u64)

Flags :: distinct u64
Bool :: b32

AdapterType :: enum i32 {
	DiscreteGPU   = 0x00000001,
	IntegratedGPU = 0x00000002,
	CPU           = 0x00000003,
	Unknown       = 0x00000004,
}

AddressMode :: enum i32 {
	Undefined    = 0x00000000,
	ClampToEdge  = 0x00000001,
	Repeat       = 0x00000002,
	MirrorRepeat = 0x00000003,
}

BackendType :: enum i32 {
	Undefined = 0x00000000,
	Null      = 0x00000001,
	WebGPU    = 0x00000002,
	D3D11     = 0x00000003,
	D3D12     = 0x00000004,
	Metal     = 0x00000005,
	Vulkan    = 0x00000006,
	OpenGL    = 0x00000007,
	OpenGLES  = 0x00000008,
}

BlendFactor :: enum i32 {
	Undefined         = 0x00000000,
	Zero              = 0x00000001,
	One               = 0x00000002,
	Src               = 0x00000003,
	OneMinusSrc       = 0x00000004,
	SrcAlpha          = 0x00000005,
	OneMinusSrcAlpha  = 0x00000006,
	Dst               = 0x00000007,
	OneMinusDst       = 0x00000008,
	DstAlpha          = 0x00000009,
	OneMinusDstAlpha  = 0x0000000A,
	SrcAlphaSaturated = 0x0000000B,
	Constant          = 0x0000000C,
	OneMinusConstant  = 0x0000000D,
	Src1              = 0x0000000E,
	OneMinusSrc1      = 0x0000000F,
	Src1Alpha         = 0x00000010,
	OneMinusSrc1Alpha = 0x00000011,
}

BlendOperation :: enum i32 {
	Undefined       = 0x00000000,
	Add             = 0x00000001,
	Subtract        = 0x00000002,
	ReverseSubtract = 0x00000003,
	Min             = 0x00000004,
	Max             = 0x00000005,
}

BufferBindingType :: enum i32 {
	BindingNotUsed  = 0x00000000,
	Undefined       = 0x00000001,
	Uniform         = 0x00000002,
	Storage         = 0x00000003,
	ReadOnlyStorage = 0x00000004,
}

BufferMapState :: enum i32 {
	Unmapped = 0x00000001,
	Pending  = 0x00000002,
	Mapped   = 0x00000003,
}

CallbackMode :: enum i32 {
	WaitAnyOnly        = 0x00000001,
	AllowProcessEvents = 0x00000002,
	AllowSpontaneous   = 0x00000003,
}

CompareFunction :: enum i32 {
	Undefined    = 0x00000000,
	Never        = 0x00000001,
	Less         = 0x00000002,
	Equal        = 0x00000003,
	LessEqual    = 0x00000004,
	Greater      = 0x00000005,
	NotEqual     = 0x00000006,
	GreaterEqual = 0x00000007,
	Always       = 0x00000008,
}

CompilationInfoRequestStatus :: enum i32 {
	Success         = 0x00000001,
	InstanceDropped = 0x00000002,
	Error           = 0x00000003,
	Unknown         = 0x00000004,
}

CompilationMessageType :: enum i32 {
	Error   = 0x00000001,
	Warning = 0x00000002,
	Info    = 0x00000003,
}

CompositeAlphaMode :: enum i32 {
	Auto            = 0x00000000,
	Opaque          = 0x00000001,
	Premultiplied   = 0x00000002,
	Unpremultiplied = 0x00000003,
	Inherit         = 0x00000004,
}

CreatePipelineAsyncStatus :: enum i32 {
	Success         = 0x00000001,
	InstanceDropped = 0x00000002,
	ValidationError = 0x00000003,
	InternalError   = 0x00000004,
	Unknown         = 0x00000005,
}

Face :: enum i32 {
	Undefined = 0x00000000,
	None      = 0x00000001,
	Front     = 0x00000002,
	Back      = 0x00000003,
}

DeviceLostReason :: enum i32 {
	Unknown         = 0x00000001,
	Destroyed       = 0x00000002,
	InstanceDropped = 0x00000003,
	FailedCreation  = 0x00000004,
}

ErrorFilter :: enum i32 {
	Validation  = 0x00000001,
	OutOfMemory = 0x00000002,
	Internal    = 0x00000003,
}

ErrorType :: enum i32 {
	NoError     = 0x00000001,
	Validation  = 0x00000002,
	OutOfMemory = 0x00000003,
	Internal    = 0x00000004,
	Unknown     = 0x00000005,
}

FeatureLevel :: enum i32 {
	Compatibility = 0x00000001,
	Core          = 0x00000002,
}

FeatureName :: enum i32 {
	// WebGPU
	Undefined                                             = 0x00000000,
	DepthClipControl                                      = 0x00000001,
	Depth32FloatStencil8                                  = 0x00000002,
	TimestampQuery                                        = 0x00000003,
	TextureCompressionBC                                  = 0x00000004,
	TextureCompressionBCSliced3D                          = 0x00000005,
	TextureCompressionETC2                                = 0x00000006,
	TextureCompressionASTC                                = 0x00000007,
	TextureCompressionASTCSliced3D                        = 0x00000008,
	IndirectFirstInstance                                 = 0x00000009,
	ShaderF16                                             = 0x0000000A,
	RG11B10UfloatRenderable                               = 0x0000000B,
	BGRA8UnormStorage                                     = 0x0000000C,
	Float32Filterable                                     = 0x0000000D,
	Float32Blendable                                      = 0x0000000E,
	ClipDistances                                         = 0x0000000F,
	DualSourceBlending                                    = 0x00000010,

	// Native
	PushConstants                                         = 0x00030001,
	TextureAdapterSpecificFormatFeatures                  = 0x00030002,
	MultiDrawIndirect                                     = 0x00030003,
	MultiDrawIndirectCount                                = 0x00030004,
	VertexWritableStorage                                 = 0x00030005,
	TextureBindingArray                                   = 0x00030006,
	SampledTextureAndStorageBufferArrayNonUniformIndexing = 0x00030007,
	PipelineStatisticsQuery                               = 0x00030008,
	StorageResourceBindingArray                           = 0x00030009,
	PartiallyBoundBindingArray                            = 0x0003000A,
	TextureFormat16bitNorm                                = 0x0003000B,
	TextureCompressionAstcHdr                             = 0x0003000C,
	MappablePrimaryBuffers                                = 0x0003000E,
	BufferBindingArray                                    = 0x0003000F,
	UniformBufferAndStorageTextureArrayNonUniformIndexing = 0x00030010,
	SpirvShaderPassthrough                                = 0x00030017,
	VertexAttribute64bit                                  = 0x00030019,
	TextureFormatNv12                                     = 0x0003001A,
	RayTracingAccelerationStructure                       = 0x0003001B,
	RayQuery                                              = 0x0003001C,
	ShaderF64                                             = 0x0003001D,
	ShaderI16                                             = 0x0003001E,
	ShaderPrimitiveIndex                                  = 0x0003001F,
	ShaderEarlyDepthTest                                  = 0x00030020,
	Subgroup                                              = 0x00030021,
	SubgroupVertex                                        = 0x00030022,
	SubgroupBarrier                                       = 0x00030023,
	TimestampQueryInsideEncoders                          = 0x00030024,
	TimestampQueryInsidePasses                            = 0x00030025,
}

FilterMode :: enum i32 {
	Undefined = 0x00000000,
	Nearest   = 0x00000001,
	Linear    = 0x00000002,
}

FrontFace :: enum i32 {
	Undefined = 0x00000000,
	CCW       = 0x00000001,
	CW        = 0x00000002,
}

IndexFormat :: enum i32 {
	Undefined = 0x00000000,
	Uint16    = 0x00000001,
	Uint32    = 0x00000002,
}

LoadOp :: enum i32 {
	Undefined = 0x00000000,
	Load      = 0x00000001,
	Clear     = 0x00000002,
}

MapAsyncStatus :: enum i32 {
	Success         = 0x00000001,
	InstanceDropped = 0x00000002,
	Error           = 0x00000003,
	Aborted         = 0x00000004,
	Unknown         = 0x00000005,
}

MipmapFilterMode :: enum i32 {
	Undefined = 0x00000000,
	Nearest   = 0x00000001,
	Linear    = 0x00000002,
}

OptionalBool :: enum i32 {
	False     = 0x00000000,
	True      = 0x00000001,
	Undefined = 0x00000002,
}

PopErrorScopeStatus :: enum i32 {
	Success         = 0x00000001,
	InstanceDropped = 0x00000002,
	EmptyStack      = 0x00000003,
}

PowerPreference :: enum i32 {
	Undefined       = 0x00000000,
	LowPower        = 0x00000001,
	HighPerformance = 0x00000002,
}

PresentMode :: enum i32 {
	Undefined   = 0x00000000,
	Fifo        = 0x00000001,
	FifoRelaxed = 0x00000002,
	Immediate   = 0x00000003,
	Mailbox     = 0x00000004,
}

@(private)
WGPUPrimitiveTopology :: enum i32 {
	Undefined     = 0x00000000,
	PointList     = 0x00000001,
	LineList      = 0x00000002,
	LineStrip     = 0x00000003,
	TriangleList  = 0x00000004,
	TriangleStrip = 0x00000005,
}

/*
Type of query contained in a `QuerySet`.

Corresponds to [WebGPU `GPUQueryType`](
https://gpuweb.github.io/gpuweb/#enumdef-gpuquerytype).
*/
QueryType :: enum i32 {
	Occlusion          = 0x00000001,
	Timestamp          = 0x00000002,
	PipelineStatistics = 0x00030000, /* Extras */
}

QueueWorkDoneStatus :: enum i32 {
	Success         = 0x00000001,
	InstanceDropped = 0x00000002,
	Error           = 0x00000003,
	Unknown         = 0x00000004,
}

RequestAdapterStatus :: enum i32 {
	Success         = 0x00000001,
	InstanceDropped = 0x00000002,
	Unavailable     = 0x00000003,
	Error           = 0x00000004,
	Unknown         = 0x00000005,
}

RequestDeviceStatus :: enum i32 {
	Success         = 0x00000001,
	InstanceDropped = 0x00000002,
	Error           = 0x00000003,
	Unknown         = 0x00000004,
}

SType :: enum i32 {
	// WebGPU
	ShaderSourceSPIRV                = 0x00000001,
	ShaderSourceWGSL                 = 0x00000002,
	RenderPassMaxDrawCount           = 0x00000003,
	SurfaceSourceMetalLayer          = 0x00000004,
	SurfaceSourceWindowsHWND         = 0x00000005,
	SurfaceSourceXlibWindow          = 0x00000006,
	SurfaceSourceWaylandSurface      = 0x00000007,
	SurfaceSourceAndroidNativeWindow = 0x00000008,
	SurfaceSourceXCBWindow           = 0x00000009,

	// Native
	DeviceExtras                     = 0x00030001,
	NativeLimits                     = 0x00030002,
	PipelineLayoutExtras             = 0x00030003,
	ShaderModuleGLSLDescriptor       = 0x00030004,
	InstanceExtras                   = 0x00030006,
	BindGroupEntryExtras             = 0x00030007,
	BindGroupLayoutEntryExtras       = 0x00030008,
	QuerySetDescriptorExtras         = 0x00030009,
	SurfaceConfigurationExtras       = 0x0003000A,
}

SamplerBindingType :: enum i32 {
	BindingNotUsed = 0x00000000,
	Undefined      = 0x00000001,
	Filtering      = 0x00000002,
	NonFiltering   = 0x00000003,
	Comparison     = 0x00000004,
}

Status :: enum i32 {
	Success = 0x00000001,
	Error   = 0x00000002,
}

StencilOperation :: enum i32 {
	Undefined      = 0x00000000,
	Keep           = 0x00000001,
	Zero           = 0x00000002,
	Replace        = 0x00000003,
	Invert         = 0x00000004,
	IncrementClamp = 0x00000005,
	DecrementClamp = 0x00000006,
	IncrementWrap  = 0x00000007,
	DecrementWrap  = 0x00000008,
}

StorageTextureAccess :: enum i32 {
	BindingNotUsed = 0x00000000,
	Undefined      = 0x00000001,
	WriteOnly      = 0x00000002,
	ReadOnly       = 0x00000003,
	ReadWrite      = 0x00000004,
}

StoreOp :: enum i32 {
	Undefined = 0x00000000,
	Store     = 0x00000001,
	Discard   = 0x00000002,
}

SurfaceGetCurrentTextureStatus :: enum i32 {
	SuccessOptimal    = 0x00000001,
	SuccessSuboptimal = 0x00000002,
	Timeout           = 0x00000003,
	Outdated          = 0x00000004,
	Lost              = 0x00000005,
	OutOfMemory       = 0x00000006,
	DeviceLost        = 0x00000007,
	Error             = 0x00000008,
}

TextureAspect :: enum i32 {
	Undefined   = 0x00000000,
	All         = 0x00000001,
	StencilOnly = 0x00000002,
	DepthOnly   = 0x00000003,
}

TextureDimension :: enum i32 {
	Undefined = 0x00000000,
	D1        = 0x00000001,
	D2        = 0x00000002,
	D3        = 0x00000003,
}

TextureFormat :: enum i32 {
	// WebGPU
	Undefined            = 0x00000000,
	R8Unorm              = 0x00000001,
	R8Snorm              = 0x00000002,
	R8Uint               = 0x00000003,
	R8Sint               = 0x00000004,
	R16Uint              = 0x00000005,
	R16Sint              = 0x00000006,
	R16Float             = 0x00000007,
	Rg8Unorm             = 0x00000008,
	Rg8Snorm             = 0x00000009,
	Rg8Uint              = 0x0000000A,
	Rg8Sint              = 0x0000000B,
	R32Float             = 0x0000000C,
	R32Uint              = 0x0000000D,
	R32Sint              = 0x0000000E,
	Rg16Uint             = 0x0000000F,
	Rg16Sint             = 0x00000010,
	Rg16Float            = 0x00000011,
	Rgba8Unorm           = 0x00000012,
	Rgba8UnormSrgb       = 0x00000013,
	Rgba8Snorm           = 0x00000014,
	Rgba8Uint            = 0x00000015,
	Rgba8Sint            = 0x00000016,
	Bgra8Unorm           = 0x00000017,
	Bgra8UnormSrgb       = 0x00000018,
	Rgb10A2Uint          = 0x00000019,
	Rgb10A2Unorm         = 0x0000001A,
	Rg11B10Ufloat        = 0x0000001B,
	Rgb9E5Ufloat         = 0x0000001C,
	Rg32Float            = 0x0000001D,
	Rg32Uint             = 0x0000001E,
	Rg32Sint             = 0x0000001F,
	Rgba16Uint           = 0x00000020,
	Rgba16Sint           = 0x00000021,
	Rgba16Float          = 0x00000022,
	Rgba32Float          = 0x00000023,
	Rgba32Uint           = 0x00000024,
	Rgba32Sint           = 0x00000025,
	Stencil8             = 0x00000026,
	Depth16Unorm         = 0x00000027,
	Depth24Plus          = 0x00000028,
	Depth24PlusStencil8  = 0x00000029,
	Depth32Float         = 0x0000002A,
	Depth32FloatStencil8 = 0x0000002B,
	Bc1RgbaUnorm         = 0x0000002C,
	Bc1RgbaUnormSrgb     = 0x0000002D,
	Bc2RgbaUnorm         = 0x0000002E,
	Bc2RgbaUnormSrgb     = 0x0000002F,
	Bc3RgbaUnorm         = 0x00000030,
	Bc3RgbaUnormSrgb     = 0x00000031,
	Bc4RUnorm            = 0x00000032,
	Bc4RSnorm            = 0x00000033,
	Bc5RgUnorm           = 0x00000034,
	Bc5RgSnorm           = 0x00000035,
	Bc6HrgbUfloat        = 0x00000036,
	Bc6HrgbFloat         = 0x00000037,
	Bc7RgbaUnorm         = 0x00000038,
	Bc7RgbaUnormSrgb     = 0x00000039,
	Etc2Rgb8Unorm        = 0x0000003A,
	Etc2Rgb8UnormSrgb    = 0x0000003B,
	Etc2Rgb8A1Unorm      = 0x0000003C,
	Etc2Rgb8A1UnormSrgb  = 0x0000003D,
	Etc2Rgba8Unorm       = 0x0000003E,
	Etc2Rgba8UnormSrgb   = 0x0000003F,
	Eacr11Unorm          = 0x00000040,
	Eacr11Snorm          = 0x00000041,
	Eacrg11Unorm         = 0x00000042,
	Eacrg11Snorm         = 0x00000043,
	Astc4x4Unorm         = 0x00000044,
	Astc4x4UnormSrgb     = 0x00000045,
	Astc5x4Unorm         = 0x00000046,
	Astc5x4UnormSrgb     = 0x00000047,
	Astc5x5Unorm         = 0x00000048,
	Astc5x5UnormSrgb     = 0x00000049,
	Astc6x5Unorm         = 0x0000004A,
	Astc6x5UnormSrgb     = 0x0000004B,
	Astc6x6Unorm         = 0x0000004C,
	Astc6x6UnormSrgb     = 0x0000004D,
	Astc8x5Unorm         = 0x0000004E,
	Astc8x5UnormSrgb     = 0x0000004F,
	Astc8x6Unorm         = 0x00000050,
	Astc8x6UnormSrgb     = 0x00000051,
	Astc8x8Unorm         = 0x00000052,
	Astc8x8UnormSrgb     = 0x00000053,
	Astc10x5Unorm        = 0x00000054,
	Astc10x5UnormSrgb    = 0x00000055,
	Astc10x6Unorm        = 0x00000056,
	Astc10x6UnormSrgb    = 0x00000057,
	Astc10x8Unorm        = 0x00000058,
	Astc10x8UnormSrgb    = 0x00000059,
	Astc10x10Unorm       = 0x0000005A,
	Astc10x10UnormSrgb   = 0x0000005B,
	Astc12x10Unorm       = 0x0000005C,
	Astc12x10UnormSrgb   = 0x0000005D,
	Astc12x12Unorm       = 0x0000005E,
	Astc12x12UnormSrgb   = 0x0000005F,

	// Native
	R16Unorm             = 0x00030001,
	R16Snorm             = 0x00030002,
	Rg16Unorm            = 0x00030003,
	Rg16Snorm            = 0x00030004,
	Rgba16Unorm          = 0x00030005,
	Rgba16Snorm          = 0x00030006,
	NV12                 = 0x00030007,
}

TextureSampleType :: enum i32 {
	BindingNotUsed    = 0x00000000,
	Undefined         = 0x00000001,
	Float             = 0x00000002,
	UnfilterableFloat = 0x00000003,
	Depth             = 0x00000004,
	Sint              = 0x00000005,
	Uint              = 0x00000006,
}

TextureViewDimension :: enum i32 {
	Undefined = 0x00000000,
	D1        = 0x00000001,
	D2        = 0x00000002,
	D2Array   = 0x00000003,
	Cube      = 0x00000004,
	CubeArray = 0x00000005,
	D3        = 0x00000006,
}

VertexFormat :: enum i32 {
	Uint8           = 0x00000001,
	Uint8x2         = 0x00000002,
	Uint8x4         = 0x00000003,
	Sint8           = 0x00000004,
	Sint8x2         = 0x00000005,
	Sint8x4         = 0x00000006,
	Unorm8          = 0x00000007,
	Unorm8x2        = 0x00000008,
	Unorm8x4        = 0x00000009,
	Snorm8          = 0x0000000A,
	Snorm8x2        = 0x0000000B,
	Snorm8x4        = 0x0000000C,
	Uint16          = 0x0000000D,
	Uint16x2        = 0x0000000E,
	Uint16x4        = 0x0000000F,
	Sint16          = 0x00000010,
	Sint16x2        = 0x00000011,
	Sint16x4        = 0x00000012,
	Unorm16         = 0x00000013,
	Unorm16x2       = 0x00000014,
	Unorm16x4       = 0x00000015,
	Snorm16         = 0x00000016,
	Snorm16x2       = 0x00000017,
	Snorm16x4       = 0x00000018,
	Float16         = 0x00000019,
	Float16x2       = 0x0000001A,
	Float16x4       = 0x0000001B,
	Float32         = 0x0000001C,
	Float32x2       = 0x0000001D,
	Float32x3       = 0x0000001E,
	Float32x4       = 0x0000001F,
	Uint32          = 0x00000020,
	Uint32x2        = 0x00000021,
	Uint32x3        = 0x00000022,
	Uint32x4        = 0x00000023,
	Sint32          = 0x00000024,
	Sint32x2        = 0x00000025,
	Sint32x3        = 0x00000026,
	Sint32x4        = 0x00000027,
	Unorm10_10_10_2 = 0x00000028,
	Unorm8x4BGRA    = 0x00000029,
}

VertexStepMode :: enum i32 {
	VertexBufferNotUsed = 0x00000000,
	Undefined           = 0x00000001,
	Vertex              = 0x00000002,
	Instance            = 0x00000003,
}

WGSLLanguageFeatureName :: enum i32 {
	ReadonlyAndReadwriteStorageTextures = 0x00000001,
	Packed4x8IntegerDotProduct          = 0x00000002,
	UnrestrictedPointerParameters       = 0x00000003,
	PointerCompositeAccess              = 0x00000004,
}

WaitStatus :: enum i32 {
	Success                 = 0x00000001,
	TimedOut                = 0x00000002,
	UnsupportedTimeout      = 0x00000003,
	UnsupportedCount        = 0x00000004,
	UnsupportedMixedSources = 0x00000005,
}

BufferUsageBits :: enum u64 {
	MapRead,
	MapWrite,
	CopySrc,
	CopyDst,
	Index,
	Vertex,
	Uniform,
	Storage,
	Indirect,
	QueryResolve,
}
BufferUsage :: distinct bit_set[BufferUsageBits;u64]
BUFFER_USAGE_NONE :: BufferUsage{}

ColorWriteMaskBits :: enum u64 {
	Red,
	Green,
	Blue,
	Alpha,
}
ColorWriteMask :: distinct bit_set[ColorWriteMaskBits;u64]
COLOR_WRITE_MASK_NONE :: ColorWriteMask{}
COLOR_WRITE_MASK_ALL :: ColorWriteMask{.Red, .Green, .Blue, .Alpha}

MapModeBits :: enum u64 {
	Read,
	Write,
}
MapMode :: distinct bit_set[MapModeBits;u64]
MAP_MODE_NONE :: MapMode{}

ShaderStageBits :: enum u64 {
	Vertex,
	Fragment,
	Compute,
}
ShaderStage :: distinct bit_set[ShaderStageBits;u64]
SHADER_STAGE_NONE :: ShaderStage{}

TextureUsageBits :: enum u64 {
	CopySrc,
	CopyDst,
	TextureBinding,
	StorageBinding,
	RenderAttachment,
}
TextureUsage :: distinct bit_set[TextureUsageBits;u64]
TEXTURE_USAGE_NONE :: TextureUsage{}
TEXTURE_USAGE_ALL :: TextureUsage {
	.CopySrc,
	.CopyDst,
	.TextureBinding,
	.StorageBinding,
	.RenderAttachment,
}

Proc :: #type proc "c" ()

BufferMapCallback :: #type proc "c" (
	status: MapAsyncStatus,
	message: StringView,
	userdata1: rawptr,
	userdata2: rawptr,
)
CompilationInfoCallback :: #type proc "c" (
	status: CompilationInfoRequestStatus,
	compilation_info: ^CompilationInfo,
	userdata1: rawptr,
	userdata2: rawptr,
)
CreateComputePipelineAsyncCallback :: #type proc "c" (
	status: CreatePipelineAsyncStatus,
	pipeline: ComputePipeline,
	message: StringView,
	userdata1: rawptr,
	userdata2: rawptr,
)
CreateRenderPipelineAsyncCallback :: #type proc "c" (
	status: CreatePipelineAsyncStatus,
	pipeline: RenderPipeline,
	message: StringView,
	userdata1: rawptr,
	userdata2: rawptr,
)
DeviceLostCallback :: #type proc "c" (
	device: ^Device,
	reason: DeviceLostReason,
	message: StringView,
	userdata1: rawptr,
	userdata2: rawptr,
)
PopErrorScopeCallback :: #type proc "c" (
	status: PopErrorScopeStatus,
	type: ErrorType,
	message: StringView,
	userdata1: rawptr,
	userdata2: rawptr,
)
QueueWorkDoneCallback :: #type proc "c" (
	status: QueueWorkDoneStatus,
	userdata1: rawptr,
	userdata2: rawptr,
)
RequestAdapterCallback :: #type proc "c" (
	status: RequestAdapterStatus,
	adapter: Adapter,
	message: StringView,
	userdata1: rawptr,
	userdata2: rawptr,
)
RequestDeviceCallback :: #type proc "c" (
	status: RequestDeviceStatus,
	device: Device,
	message: StringView,
	userdata1: rawptr,
	userdata2: rawptr,
)
UncapturedErrorCallback :: #type proc "c" (
	device: ^Device,
	type: ErrorType,
	message: StringView,
	userdata1: rawptr,
	userdata2: rawptr,
)

ChainedStruct :: struct {
	next:  ^ChainedStruct,
	stype: SType,
}

ChainedStructOut :: struct {
	next:  ^ChainedStructOut,
	stype: SType,
}

BufferMapCallbackInfo :: struct {
	next_in_chain: ^ChainedStruct,
	mode:          CallbackMode,
	callback:      BufferMapCallback,
	userdata1:     rawptr,
	userdata2:     rawptr,
}

CompilationInfoCallbackInfo :: struct {
	next_in_chain: ^ChainedStruct,
	mode:          CallbackMode,
	callback:      CompilationInfoCallback,
	userdata1:     rawptr,
	userdata2:     rawptr,
}

CreateComputePipelineAsyncCallbackInfo :: struct {
	next_in_chain: ^ChainedStruct,
	mode:          CallbackMode,
	callback:      CreateComputePipelineAsyncCallback,
	userdata1:     rawptr,
	userdata2:     rawptr,
}

CreateRenderPipelineAsyncCallbackInfo :: struct {
	next_in_chain: ^ChainedStruct,
	mode:          CallbackMode,
	callback:      CreateRenderPipelineAsyncCallback,
	userdata1:     rawptr,
	userdata2:     rawptr,
}

DeviceLostCallbackInfo :: struct {
	next_in_chain: ^ChainedStruct,
	mode:          CallbackMode,
	callback:      DeviceLostCallback,
	userdata1:     rawptr,
	userdata2:     rawptr,
}

PopErrorScopeCallbackInfo :: struct {
	next_in_chain: ^ChainedStruct,
	mode:          CallbackMode,
	callback:      PopErrorScopeCallback,
	userdata1:     rawptr,
	userdata2:     rawptr,
}

QueueWorkDoneCallbackInfo :: struct {
	next_in_chain: ^ChainedStruct,
	mode:          CallbackMode,
	callback:      QueueWorkDoneCallback,
	userdata1:     rawptr,
	userdata2:     rawptr,
}

RequestAdapterCallbackInfo :: struct {
	next_in_chain: ^ChainedStruct,
	mode:          CallbackMode,
	callback:      RequestAdapterCallback,
	userdata1:     rawptr,
	userdata2:     rawptr,
}

RequestDeviceCallbackInfo :: struct {
	next_in_chain: ^ChainedStruct,
	mode:          CallbackMode,
	callback:      RequestDeviceCallback,
	userdata1:     rawptr,
	userdata2:     rawptr,
}

UncapturedErrorCallbackInfo :: struct {
	next_in_chain: ^ChainedStruct,
	callback:      UncapturedErrorCallback,
	userdata1:     rawptr,
	userdata2:     rawptr,
}

@(private)
WGPUAdapterInfo :: struct {
	next_in_chain: ^ChainedStructOut,
	vendor:        StringView,
	architecture:  StringView,
	device:        StringView,
	description:   StringView,
	backend_type:  BackendType,
	adapter_type:  AdapterType,
	vendor_id:     u32,
	device_id:     u32,
}

@(private)
WGPUBindGroupEntry :: struct {
	next_in_chain: ^ChainedStruct,
	binding:       u32,
	buffer:        Buffer,
	offset:        u64,
	size:          u64,
	sampler:       Sampler,
	texture_view:  TextureView,
}

BlendComponent :: struct {
	operation:  BlendOperation,
	src_factor: BlendFactor,
	dst_factor: BlendFactor,
}

BufferBindingLayout :: struct {
	next_in_chain:      ^ChainedStruct,
	type:               BufferBindingType,
	has_dynamic_offset: b32,
	min_binding_size:   u64,
}

@(private)
WGPUBufferDescriptor :: struct {
	next_in_chain:      ^ChainedStruct,
	label:              StringView,
	usage:              BufferUsage,
	size:               u64,
	mapped_at_creation: b32,
}

Color :: [4]f64

@(private)
WGPUCommandBufferDescriptor :: struct {
	next_in_chain: ^ChainedStruct,
	label:         StringView,
}

@(private)
WGPUCommandEncoderDescriptor :: struct {
	next_in_chain: ^ChainedStruct,
	label:         StringView,
}

CompilationMessage :: struct {
	next_in_chain: ^ChainedStruct,
	message:       StringView,
	type:          CompilationMessageType,
	line_num:      u64,
	line_pos:      u64,
	offset:        u64,
	length:        u64,
}

ComputePassTimestampWrites :: struct {
	query_set:                     QuerySet,
	beginning_of_pass_write_index: u32,
	end_of_pass_write_index:       u32,
}

ConstantEntry :: struct {
	next_in_chain: ^ChainedStruct,
	key:           StringView,
	value:         f64,
}

Extent3D :: struct {
	width:                 u32,
	height:                u32,
	depth_or_array_layers: u32,
}

Future :: struct {
	id: u64,
}

InstanceCapabilities :: struct {
	next_in_chain:            ^ChainedStructOut,
	timed_wait_any_enable:    b32,
	timed_wait_any_max_count: uint,
}

@(private)
WGPULimits :: struct {
	next_in_chain:                                   ^ChainedStructOut,
	max_texture_dimension_1d:                        u32,
	max_texture_dimension_2d:                        u32,
	max_texture_dimension_3d:                        u32,
	max_texture_array_layers:                        u32,
	max_bind_groups:                                 u32,
	max_bind_groups_plus_vertex_buffers:             u32,
	max_bindings_per_bind_group:                     u32,
	max_dynamic_uniform_buffers_per_pipeline_layout: u32,
	max_dynamic_storage_buffers_per_pipeline_layout: u32,
	max_sampled_textures_per_shader_stage:           u32,
	max_samplers_per_shader_stage:                   u32,
	max_storage_buffers_per_shader_stage:            u32,
	max_storage_textures_per_shader_stage:           u32,
	max_uniform_buffers_per_shader_stage:            u32,
	max_uniform_buffer_binding_size:                 u64,
	max_storage_buffer_binding_size:                 u64,
	min_uniform_buffer_offset_alignment:             u32,
	min_storage_buffer_offset_alignment:             u32,
	max_vertex_buffers:                              u32,
	max_buffer_size:                                 u64,
	max_vertex_attributes:                           u32,
	max_vertex_buffer_array_stride:                  u32,
	max_inter_stage_shader_variables:                u32,
	max_color_attachments:                           u32,
	max_color_attachment_bytes_per_sample:           u32,
	max_compute_workgroup_storage_size:              u32,
	max_compute_invocations_per_workgroup:           u32,
	max_compute_workgroup_size_x:                    u32,
	max_compute_workgroup_size_y:                    u32,
	max_compute_workgroup_size_z:                    u32,
	max_compute_workgroups_per_dimension:            u32,
}

MultisampleState :: struct {
	next_in_chain:             ^ChainedStruct,
	count:                     u32,
	mask:                      u32,
	alpha_to_coverage_enabled: b32,
}

Origin3D :: struct {
	x: u32,
	y: u32,
	z: u32,
}

@(private)
WGPUPipelineLayoutDescriptor :: struct {
	next_in_chain:           ^ChainedStruct,
	label:                   StringView,
	bind_group_layout_count: uint,
	bind_group_layouts:      [^]BindGroupLayout,
}

@(private)
WGPUPrimitiveState :: struct {
	next_in_chain:      ^ChainedStruct,
	topology:           WGPUPrimitiveTopology,
	strip_index_format: IndexFormat,
	front_face:         FrontFace,
	cull_mode:          Face,
	unclipped_depth:    b32,
}

@(private)
WGPUQuerySetDescriptor :: struct {
	next_in_chain: ^ChainedStruct,
	label:         StringView,
	type:          QueryType,
	count:         u32,
}

QueueDescriptor :: struct {
	next_in_chain: ^ChainedStruct,
	label:         StringView,
}

@(private)
WGPURenderBundleDescriptor :: struct {
	next_in_chain: ^ChainedStruct,
	label:         StringView,
}

@(private)
WGPURenderBundleEncoderDescriptor :: struct {
	next_in_chain:        ^ChainedStruct,
	label:                StringView,
	color_format_count:   uint,
	color_formats:        ^TextureFormat,
	depth_stencil_format: TextureFormat,
	sample_count:         u32,
	depth_read_only:      b32,
	stencil_read_only:    b32,
}

RenderPassDepthStencilAttachment :: struct {
	view:                TextureView,
	depth_load_op:       LoadOp,
	depth_store_op:      StoreOp,
	depth_clear_value:   f32,
	depth_read_only:     b32,
	stencil_load_op:     LoadOp,
	stencil_store_op:    StoreOp,
	stencil_clear_value: u32,
	stencil_read_only:   b32,
}

RenderPassMaxDrawCount :: struct {
	chain:          ChainedStruct,
	max_draw_count: u64,
}

RenderPassTimestampWrites :: struct {
	query_set:                     QuerySet,
	beginning_of_pass_write_index: u32,
	end_of_pass_write_index:       u32,
}

@(private)
WGPURequestAdapterOptions :: struct {
	next_in_chain:          ^ChainedStruct,
	feature_level:          FeatureLevel,
	power_preference:       PowerPreference,
	force_fallback_adapter: b32,
	backend_type:           BackendType,
	compatible_surface:     Surface,
}

SamplerBindingLayout :: struct {
	next_in_chain: ^ChainedStruct,
	type:          SamplerBindingType,
}

@(private)
WGPUSamplerDescriptor :: struct {
	next_in_chain:  ^ChainedStruct,
	label:          StringView,
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

@(private)
WGPUShaderModuleDescriptor :: struct {
	next_in_chain: ^ChainedStruct,
	label:         StringView,
}

ShaderSourceSPIRV :: struct {
	chain:     ChainedStruct,
	code_size: u32,
	code:      [^]u32,
}

ShaderSourceWGSL :: struct {
	chain: ChainedStruct,
	code:  StringView,
}

StencilFaceState :: struct {
	compare:       CompareFunction,
	fail_op:       StencilOperation,
	depth_fail_op: StencilOperation,
	pass_op:       StencilOperation,
}

StorageTextureBindingLayout :: struct {
	next_in_chain:  ^ChainedStruct,
	access:         StorageTextureAccess,
	format:         TextureFormat,
	view_dimension: TextureViewDimension,
}

SupportedFeatures :: struct {
	feature_count: uint,
	features:      [^]FeatureName,
}

SupportedWGSLLanguageFeatures :: struct {
	feature_count: uint,
	features:      [^]WGSLLanguageFeatureName,
}

@(private)
WGPUSurfaceCapabilities :: struct {
	next_in_chain:      ^ChainedStructOut,
	usages:             TextureUsage,
	format_count:       uint,
	formats:            [^]TextureFormat,
	present_mode_count: uint,
	present_modes:      [^]PresentMode,
	alpha_mode_count:   uint,
	alpha_modes:        [^]CompositeAlphaMode,
}

@(private)
WGPUSurfaceConfiguration :: struct {
	next_in_chain:     ^ChainedStruct,
	device:            Device,
	format:            TextureFormat,
	usage:             TextureUsage,
	width:             u32,
	height:            u32,
	view_format_count: uint,
	view_formats:      [^]TextureFormat,
	alpha_mode:        CompositeAlphaMode,
	present_mode:      PresentMode,
}

@(private)
WGPUSurfaceDescriptor :: struct {
	next_in_chain: ^ChainedStruct,
	label:         StringView,
}

SurfaceSourceAndroidNativeWindow :: struct {
	chain:  ChainedStruct,
	window: rawptr,
}

SurfaceSourceMetalLayer :: struct {
	chain: ChainedStruct,
	layer: rawptr,
}

SurfaceSourceWaylandSurface :: struct {
	chain:   ChainedStruct,
	display: rawptr,
	surface: rawptr,
}

SurfaceSourceWindowsHWND :: struct {
	chain:     ChainedStruct,
	hinstance: rawptr,
	hwnd:      rawptr,
}

SurfaceSourceXCBWindow :: struct {
	chain:      ChainedStruct,
	connection: rawptr,
	window:     u32,
}

SurfaceSourceXlibWindow :: struct {
	chain:   ChainedStruct,
	display: rawptr,
	window:  u64,
}

/*
Surface texture that can be rendered to.
Result of a successful call to `surface_get_current_texture`.

This type is unique to the `wgpu-native`. In the WebGPU specification,
the [`GPUCanvasContext`](https://gpuweb.github.io/gpuweb/#canvas-context) provides
a texture without any additional information.
*/
SurfaceTexture :: struct {
	next_in_chain: ^ChainedStructOut,
	texture:       Texture,
	status:        SurfaceGetCurrentTextureStatus,
}

TexelCopyBufferLayout :: struct {
	offset:         u64,
	bytes_per_row:  u32,
	rows_per_image: u32,
}

TextureBindingLayout :: struct {
	next_in_chain:  ^ChainedStruct,
	sample_type:    TextureSampleType,
	view_dimension: TextureViewDimension,
	multisampled:   b32,
}

@(private)
WGPUTextureViewDescriptor :: struct {
	next_in_chain:     ^ChainedStruct,
	label:             StringView,
	format:            TextureFormat,
	dimension:         TextureViewDimension,
	base_mip_level:    u32,
	mip_level_count:   u32,
	base_array_layer:  u32,
	array_layer_count: u32,
	aspect:            TextureAspect,
	usage:             TextureUsage,
}

VertexAttribute :: struct {
	format:          VertexFormat,
	offset:          u64,
	shader_location: u32,
}

@(private)
WGPUBindGroupDescriptor :: struct {
	next_in_chain: ^ChainedStruct,
	label:         StringView,
	layout:        BindGroupLayout,
	entry_count:   uint,
	entries:       [^]WGPUBindGroupEntry,
}

@(private)
WGPUBindGroupLayoutEntry :: struct {
	next_in_chain:   ^ChainedStruct,
	binding:         u32,
	visibility:      ShaderStage,
	buffer:          BufferBindingLayout,
	sampler:         SamplerBindingLayout,
	texture:         TextureBindingLayout,
	storage_texture: StorageTextureBindingLayout,
}

BlendState :: struct {
	color: BlendComponent,
	alpha: BlendComponent,
}

CompilationInfo :: struct {
	next_in_chain: ^ChainedStruct,
	messageCount:  uint,
	messages:      [^]CompilationMessage,
}

@(private)
WGPUComputePassDescriptor :: struct {
	next_in_chain:    ^ChainedStruct,
	label:            StringView,
	timestamp_writes: ^ComputePassTimestampWrites,
}

DepthStencilState :: struct {
	next_in_chain:          ^ChainedStruct,
	format:                 TextureFormat,
	depth_write_enabled:    OptionalBool,
	depth_compare:          CompareFunction,
	stencil_front:          StencilFaceState,
	stencil_back:           StencilFaceState,
	stencil_read_mask:      u32,
	stencil_write_mask:     u32,
	depth_bias:             i32,
	depth_bias_slope_scale: f32,
	depth_bias_clamp:       f32,
}

@(private)
WGPUDeviceDescriptor :: struct {
	next_in_chain:                  ^ChainedStruct,
	label:                          StringView,
	required_feature_count:         uint,
	required_features:              [^]FeatureName,
	required_limits:                ^WGPULimits,
	default_queue:                  QueueDescriptor,
	device_lost_callback_info:      DeviceLostCallbackInfo,
	uncaptured_error_callback_info: UncapturedErrorCallbackInfo,
}

FutureWaitInfo :: struct {
	future:    Future,
	completed: b32,
}

@(private)
WGPUInstanceDescriptor :: struct {
	next_in_chain: ^ChainedStruct,
	features:      InstanceCapabilities,
}

ProgrammableStageDescriptor :: struct {
	next_in_chain:  ^ChainedStruct,
	module:         ShaderModule,
	entry_point:    StringView,
	constant_count: uint,
	constants:      [^]ConstantEntry,
}

RenderPassColorAttachment :: struct {
	next_in_chain:  ^ChainedStruct,
	view:           TextureView,
	depth_slice:    u32,
	resolve_target: TextureView,
	load_op:        LoadOp,
	store_op:       StoreOp,
	clear_value:    Color,
}

TexelCopyBufferInfo :: struct {
	layout: TexelCopyBufferLayout,
	buffer: Buffer,
}

TexelCopyTextureInfo :: struct {
	texture:   Texture,
	mip_level: u32,
	origin:    Origin3D,
	aspect:    TextureAspect,
}

@(private)
WGPUTextureDescriptor :: struct {
	next_in_chain:     ^ChainedStruct,
	label:             StringView,
	usage:             TextureUsage,
	dimension:         TextureDimension,
	size:              Extent3D,
	format:            TextureFormat,
	mip_level_count:   u32,
	sample_count:      u32,
	view_format_count: uint,
	view_formats:      [^]TextureFormat,
}

@(private)
WGPUVertexBufferLayout :: struct {
	step_mode:       VertexStepMode,
	array_stride:    u64,
	attribute_count: uint,
	attributes:      [^]VertexAttribute,
}

@(private)
WGPUBindGroupLayoutDescriptor :: struct {
	next_in_chain: ^ChainedStruct,
	label:         StringView,
	entry_count:   uint,
	entries:       [^]WGPUBindGroupLayoutEntry,
}

ColorTargetState :: struct {
	next_in_chain: ^ChainedStruct,
	format:        TextureFormat,
	blend:         ^BlendState,
	write_mask:    ColorWriteMask,
}

@(private)
WGPUComputePipelineDescriptor :: struct {
	next_in_chain: ^ChainedStruct,
	label:         StringView,
	layout:        PipelineLayout,
	compute:       ProgrammableStageDescriptor,
}

@(private)
WGPURenderPassDescriptor :: struct {
	next_in_chain:            ^ChainedStruct,
	label:                    StringView,
	color_attachment_count:   uint,
	color_attachments:        [^]RenderPassColorAttachment,
	depth_stencil_attachment: ^RenderPassDepthStencilAttachment,
	occlusion_query_set:      QuerySet,
	timestamp_writes:         ^RenderPassTimestampWrites,
}

@(private)
WGPUVertexState :: struct {
	next_in_chain:  ^ChainedStruct,
	module:         ShaderModule,
	entry_point:    StringView,
	constant_count: uint,
	constants:      [^]ConstantEntry,
	buffer_count:   uint,
	buffers:        [^]WGPUVertexBufferLayout,
}

@(private)
WGPUFragmentState :: struct {
	next_in_chain:  ^ChainedStruct,
	module:         ShaderModule,
	entry_point:    StringView,
	constant_count: uint,
	constants:      [^]ConstantEntry,
	target_count:   uint,
	targets:        [^]ColorTargetState,
}

@(private)
WGPURenderPipelineDescriptor :: struct {
	next_in_chain: ^ChainedStruct,
	label:         StringView,
	layout:        PipelineLayout,
	vertex:        WGPUVertexState,
	primitive:     WGPUPrimitiveState,
	depth_stencil: ^DepthStencilState,
	multisample:   MultisampleState,
	fragment:      ^WGPUFragmentState,
}

@(default_calling_convention = "c")
foreign wgpu_native {
	// odinfmt: disable
	wgpuCreateInstance :: proc(descriptor: ^WGPUInstanceDescriptor) -> Instance ---
	wgpuGetInstanceCapabilities :: proc(capabilities: ^InstanceCapabilities) -> Status ---
	wgpuGetProcAddress :: proc(proc_name: StringView) -> Proc ---

	wgpuAdapterGetFeatures :: proc(adapter: Adapter, features: ^SupportedFeatures) ---
	wgpuAdapterGetInfo :: proc(adapter: Adapter, info: ^WGPUAdapterInfo) -> Status ---
	wgpuAdapterGetLimits :: proc(adapter: Adapter, limits: ^WGPULimits) -> Status ---
	wgpuAdapterHasFeature :: proc(adapter: Adapter, feature: FeatureName) -> b32 ---
	wgpuAdapterRequestDevice :: proc(
		adapter: Adapter,
		descriptor: ^WGPUDeviceDescriptor,
		callback_info: RequestDeviceCallbackInfo) -> Future ---
	wgpuAdapterAddRef :: proc(adapter: Adapter) ---
	wgpuAdapterRelease :: proc(adapter: Adapter) ---

	wgpuAdapterInfoFreeMembers :: proc(adapter_info: WGPUAdapterInfo) ---

	wgpuBindGroupSetLabel :: proc(bind_group: BindGroup, label: StringView) ---
	wgpuBindGroupAddRef :: proc(bind_group: BindGroup) ---
	wgpuBindGroupRelease :: proc(bind_group: BindGroup) ---

	wgpuBindGroupLayoutSetLabel :: proc(bind_group_layout: BindGroupLayout, label: StringView) ---
	wgpuBindGroupLayoutAddRef :: proc(bind_group_layout: BindGroupLayout) ---
	wgpuBindGroupLayoutRelease :: proc(bind_group_layout: BindGroupLayout) ---

	wgpuBufferDestroy :: proc(buffer: Buffer) ---
	wgpuBufferGetConstMappedRange :: proc(buffer: Buffer, offset: uint, size: uint) -> rawptr ---
	wgpuBufferGetMapState :: proc(buffer: Buffer) -> BufferMapState ---
	wgpuBufferGetMappedRange :: proc(buffer: Buffer, offset: uint, size: uint) -> rawptr ---
	wgpuBufferGetSize :: proc(buffer: Buffer) -> u64 ---
	wgpuBufferGetUsage :: proc(buffer: Buffer) -> BufferUsage ---
	wgpuBufferMapAsync :: proc(
		buffer: Buffer,
		mode: MapMode,
		offset: uint,
		size: uint,
		callback_info: BufferMapCallbackInfo) -> Future ---
	wgpuBufferSetLabel :: proc(buffer: Buffer, label: StringView) ---
	wgpuBufferUnmap :: proc(buffer: Buffer) ---
	wgpuBufferAddRef :: proc(buffer: Buffer) ---
	wgpuBufferRelease :: proc(buffer: Buffer) ---

	wgpuCommandBufferSetLabel :: proc(command_buffer: CommandBuffer, label: StringView) ---
	wgpuCommandBufferAddRef :: proc(command_buffer: CommandBuffer) ---
	wgpuCommandBufferRelease :: proc(command_buffer: CommandBuffer) ---

	wgpuCommandEncoderBeginComputePass :: proc(
		command_encoder: CommandEncoder,
		descriptor: ^WGPUComputePassDescriptor) -> ComputePass ---
	wgpuCommandEncoderBeginRenderPass :: proc(
		command_encoder: CommandEncoder,
		#by_ptr descriptor: WGPURenderPassDescriptor) -> RenderPass ---
	wgpuCommandEncoderClearBuffer :: proc(
		command_encoder: CommandEncoder,
		buffer: Buffer,
		offset: u64,
		size: u64) ---
	wgpuCommandEncoderCopyBufferToBuffer :: proc(
		command_encoder: CommandEncoder,
		source: Buffer,
		source_offset: u64,
		destination: Buffer,
		destination_offset: u64,
		size: u64) ---
	wgpuCommandEncoderCopyBufferToTexture :: proc(
		command_encoder: CommandEncoder,
		#by_ptr source: TexelCopyBufferInfo,
		#by_ptr destination: TexelCopyTextureInfo,
		#by_ptr copy_size: Extent3D) ---
	wgpuCommandEncoderCopyTextureToBuffer :: proc(
		command_encoder: CommandEncoder,
		#by_ptr source: TexelCopyTextureInfo,
		#by_ptr destination: TexelCopyBufferInfo,
		#by_ptr copy_size: Extent3D) ---
	wgpuCommandEncoderCopyTextureToTexture :: proc(
		command_encoder: CommandEncoder,
		#by_ptr source: TexelCopyTextureInfo,
		#by_ptr destination: TexelCopyTextureInfo,
		#by_ptr copy_size: Extent3D) ---
	wgpuCommandEncoderFinish :: proc(
		command_encoder: CommandEncoder,
		descriptor: ^WGPUCommandBufferDescriptor) -> CommandBuffer ---
	wgpuCommandEncoderInsertDebugMarker :: proc(
		command_encoder: CommandEncoder,
		marker_label: StringView) ---
	wgpuCommandEncoderPopDebugGroup :: proc(command_encoder: CommandEncoder) ---
	wgpuCommandEncoderPushDebugGroup :: proc(
		command_encoder: CommandEncoder,
		group_label: StringView) ---
	wgpuCommandEncoderResolveQuerySet :: proc(
		command_encoder: CommandEncoder,
		query_set: QuerySet,
		first_query: u32,
		query_count: u32,
		destination: Buffer,
		destination_offset: u64) ---
	wgpuCommandEncoderSetLabel :: proc(command_encoder: CommandEncoder, label: StringView) ---
	wgpuCommandEncoderWriteTimestamp :: proc(
		command_encoder: CommandEncoder,
		query_set: QuerySet,
		query_index: u32) ---
	wgpuCommandEncoderAddRef :: proc(command_encoder: CommandEncoder) ---
	wgpuCommandEncoderRelease :: proc(command_encoder: CommandEncoder) ---

	wgpuComputePassEncoderDispatchWorkgroups :: proc(
		compute_pass_encoder: ComputePass,
		workgroup_count_x: u32,
		workgroup_count_y: u32,
		workgroup_count_z: u32) ---
	wgpuComputePassEncoderDispatchWorkgroupsIndirect :: proc(
		compute_pass_encoder: ComputePass,
		indirect_buffer: Buffer,
		indirect_offset: u64) ---
	wgpuComputePassEncoderEnd :: proc(compute_pass_encoder: ComputePass) ---
	wgpuComputePassEncoderInsertDebugMarker :: proc(
		compute_pass_encoder: ComputePass,
		marker_label: StringView) ---
	wgpuComputePassEncoderPopDebugGroup :: proc(compute_pass_encoder: ComputePass) ---
	wgpuComputePassEncoderPushDebugGroup :: proc(
		compute_pass_encoder: ComputePass,
		group_label: StringView) ---
	wgpuComputePassEncoderSetBindGroup :: proc(
		compute_pass_encoder: ComputePass,
		group_index: u32,
		group: BindGroup,
		dynamic_offset_count: uint,
		dynamic_offsets: [^]u32) ---
	wgpuComputePassEncoderSetLabel :: proc(
		compute_pass_encoder: ComputePass,
		label: StringView) ---
	wgpuComputePassEncoderSetPipeline :: proc(
		compute_pass_encoder: ComputePass,
		pipeline: ComputePipeline) ---
	wgpuComputePassEncoderAddRef :: proc(compute_pass_encoder: ComputePass) ---
	wgpuComputePassEncoderRelease :: proc(compute_pass_encoder: ComputePass) ---

	wgpuComputePipelineGetBindGroupLayout :: proc(
		compute_pipeline: ComputePipeline,
		group_index: u32) -> BindGroupLayout ---
	wgpuComputePipelineSetLabel :: proc(compute_pipeline: ComputePipeline, label: StringView) ---
	wgpuComputePipelineAddRef :: proc(compute_pipeline: ComputePipeline) ---
	wgpuComputePipelineRelease :: proc(compute_pipeline: ComputePipeline) ---

	wgpuDeviceCreateBindGroup :: proc(
		device: Device,
		#by_ptr descriptor: WGPUBindGroupDescriptor) -> BindGroup ---
	wgpuDeviceCreateBindGroupLayout :: proc(
		device: Device,
		descriptor: ^WGPUBindGroupLayoutDescriptor) -> BindGroupLayout ---
	wgpuDeviceCreateBuffer :: proc(
		device: Device,
		#by_ptr descriptor: WGPUBufferDescriptor) -> Buffer ---
	wgpuDeviceCreateCommandEncoder :: proc(
		device: Device,
		descriptor: ^WGPUCommandEncoderDescriptor) -> CommandEncoder ---
	wgpuDeviceCreateComputePipeline :: proc(
		device: Device,
		#by_ptr descriptor: WGPUComputePipelineDescriptor) -> ComputePipeline ---
	wgpuDeviceCreateComputePipelineAsync :: proc(
		device: Device,
		#by_ptr descriptor: WGPUComputePipelineDescriptor,
		callback_info: CreateComputePipelineAsyncCallbackInfo) -> Future ---
	wgpuDeviceCreatePipelineLayout :: proc(
		device: Device,
		#by_ptr descriptor: WGPUPipelineLayoutDescriptor) -> PipelineLayout ---
	wgpuDeviceCreateQuerySet :: proc(
		device: Device,
		#by_ptr descriptor: WGPUQuerySetDescriptor) -> QuerySet ---
	wgpuDeviceCreateRenderBundleEncoder :: proc(
		device: Device,
		#by_ptr descriptor: WGPURenderBundleEncoderDescriptor) -> RenderBundleEncoder ---
	wgpuDeviceCreateRenderPipeline :: proc(
		device: Device,
		#by_ptr descriptor: WGPURenderPipelineDescriptor) -> RenderPipeline ---
	wgpuDeviceCreateRenderPipelineAsync :: proc(
		device: Device,
		#by_ptr descriptor: WGPURenderPipelineDescriptor,
		callback_info: CreateRenderPipelineAsyncCallbackInfo) -> Future ---
	wgpuDeviceCreateSampler :: proc(
		device: Device,
		#by_ptr descriptor: WGPUSamplerDescriptor) -> Sampler ---
	wgpuDeviceCreateShaderModule :: proc(device: Device,
		#by_ptr descriptor: WGPUShaderModuleDescriptor) -> ShaderModule ---
	wgpuDeviceCreateTexture :: proc(device: Device,
		#by_ptr descriptor: WGPUTextureDescriptor) -> Texture ---
	wgpuDeviceDestroy :: proc(device: Device) ---
	wgpuDeviceGetAdapterInfo :: proc(device: Device) -> WGPUAdapterInfo ---
	wgpuDeviceGetFeatures :: proc(device: Device, features: ^SupportedFeatures) ---
	wgpuDeviceGetLimits :: proc(device: Device, limits: ^WGPULimits) -> Status ---
	wgpuDeviceGetLostFuture :: proc(device: Device) -> Future ---
	wgpuDeviceGetQueue :: proc(device: Device) -> Queue ---
	wgpuDeviceHasFeature :: proc(device: Device, feature: FeatureName) -> b32 ---
	wgpuDevicePopErrorScope :: proc(
		device: Device,
		callback_info: PopErrorScopeCallbackInfo) -> Future ---
	wgpuDevicePushErrorScope :: proc(device: Device, filter: ErrorFilter) ---
	wgpuDeviceSetLabel :: proc(device: Device, label: StringView) ---
	wgpuDeviceAddRef :: proc(device: Device) ---
	wgpuDeviceRelease :: proc(device: Device) ---

	wgpuInstanceCreateSurface :: proc(
		instance: Instance,
		#by_ptr descriptor: WGPUSurfaceDescriptor) -> Surface ---
	wgpuInstanceGetWGSLLanguageFeatures :: proc(
		instance: Instance,
		features: ^SupportedWGSLLanguageFeatures) -> Status ---
	wgpuInstanceHasWGSLLanguageFeature :: proc(
		instance: Instance,
		feature: WGSLLanguageFeatureName) -> b32 ---
	wgpuInstanceProcessEvents :: proc(instance: Instance) ---
	wgpuInstanceRequestAdapter :: proc(
		instance: Instance,
		options: ^WGPURequestAdapterOptions,
		callback_info: RequestAdapterCallbackInfo) -> Future ---
	wgpuInstanceWaitAny :: proc(
		instance: Instance,
		future_count: uint,
		futures: ^FutureWaitInfo,
		timeout_ns: u64) -> WaitStatus ---
	wgpuInstanceAddRef :: proc(instance: Instance) ---
	wgpuInstanceRelease :: proc(instance: Instance) ---

	wgpuPipelineLayoutSetLabel :: proc(pipeline_layout: PipelineLayout, label: StringView) ---
	wgpuPipelineLayoutAddRef :: proc(pipeline_layout: PipelineLayout) ---
	wgpuPipelineLayoutRelease :: proc(pipeline_layout: PipelineLayout) ---

	wgpuQuerySetDestroy :: proc(query_set: QuerySet) ---
	wgpuQuerySetGetCount :: proc(query_set: QuerySet) -> u32 ---
	wgpuQuerySetGetType :: proc(query_set: QuerySet) -> QueryType ---
	wgpuQuerySetSetLabel :: proc(query_set: QuerySet, label: StringView) ---
	wgpuQuerySetAddRef :: proc(query_set: QuerySet) ---
	wgpuQuerySetRelease :: proc(query_set: QuerySet) ---

	wgpuQueueOnSubmittedWorkDone :: proc(
		queue: Queue,
		callback_info: QueueWorkDoneCallbackInfo) -> Future ---
	wgpuQueueSetLabel :: proc(queue: Queue, label: StringView) ---
	wgpuQueueSubmit :: proc(queue: Queue, command_count: uint, commands: [^]CommandBuffer) ---
	wgpuQueueWriteBuffer :: proc(
		queue: Queue,
		buffer: Buffer,
		buffer_offset: u64,
		data: rawptr,
		size: uint) ---
	wgpuQueueWriteTexture :: proc(
		queue: Queue,
		#by_ptr destination: TexelCopyTextureInfo,
		data: rawptr,
		data_size: uint,
		#by_ptr data_layout: TexelCopyBufferLayout,
		#by_ptr write_size: Extent3D) ---
	wgpuQueueAddRef :: proc(queue: Queue) ---
	wgpuQueueRelease :: proc(queue: Queue) ---

	wgpuRenderBundleSetLabel :: proc(render_bundle: RenderBundle, label: StringView) ---
	wgpuRenderBundleAddRef :: proc(render_bundle: RenderBundle) ---
	wgpuRenderBundleRelease :: proc(render_bundle: RenderBundle) ---

	wgpuRenderBundleEncoderDraw :: proc(
		render_bundle_encoder: RenderBundleEncoder,
		vertex_count: u32,
		instance_count: u32,
		first_vertex: u32,
		first_instance: u32) ---
	wgpuRenderBundleEncoderDrawIndexed :: proc(
		render_bundle_encoder: RenderBundleEncoder,
		index_count: u32,
		instance_count: u32,
		first_index: u32,
		base_vertex: i32,
		first_instance: u32) ---
	wgpuRenderBundleEncoderDrawIndexedIndirect :: proc(
		render_bundle_encoder: RenderBundleEncoder,
		indirect_buffer: Buffer,
		indirect_offset: u64) ---
	wgpuRenderBundleEncoderDrawIndirect :: proc(
		render_bundle_encoder: RenderBundleEncoder,
		indirect_buffer: Buffer,
		indirect_offset: u64) ---
	wgpuRenderBundleEncoderFinish :: proc(
		render_bundle_encoder: RenderBundleEncoder,
		descriptor: ^WGPURenderBundleDescriptor) -> RenderBundle ---
	wgpuRenderBundleEncoderInsertDebugMarker :: proc(
		render_bundle_encoder: RenderBundleEncoder, marker_label: StringView) ---
	wgpuRenderBundleEncoderPopDebugGroup :: proc(render_bundle_encoder: RenderBundleEncoder) ---
	wgpuRenderBundleEncoderPushDebugGroup :: proc(
		render_bundle_encoder: RenderBundleEncoder, group_label: StringView) ---
	wgpuRenderBundleEncoderSetBindGroup :: proc(
		render_bundle_encoder: RenderBundleEncoder,
		group_index: u32, group: BindGroup, dynamic_offset_count: uint, dynamic_offsets: [^]u32) ---
	wgpuRenderBundleEncoderSetIndexBuffer :: proc(
		render_bundle_encoder: RenderBundleEncoder,
		buffer: Buffer,
		format: IndexFormat,
		offset: u64, size: u64) ---
	wgpuRenderBundleEncoderSetLabel :: proc(
		render_bundle_encoder: RenderBundleEncoder, label: StringView) ---
	wgpuRenderBundleEncoderSetPipeline :: proc(
		render_bundle_encoder: RenderBundleEncoder,
		pipeline: RenderPipeline) ---
	wgpuRenderBundleEncoderSetVertexBuffer :: proc(
		render_bundle_encoder: RenderBundleEncoder,
		slot: u32,
		buffer: Buffer,
		offset: u64,
		size: u64) ---
	wgpuRenderBundleEncoderAddRef :: proc(render_bundle_encoder: RenderBundleEncoder) ---
	wgpuRenderBundleEncoderRelease :: proc(render_bundle_encoder: RenderBundleEncoder) ---

	wgpuRenderPassEncoderBeginOcclusionQuery :: proc(
		render_pass_encoder: RenderPass,
		query_index: u32) ---
	wgpuRenderPassEncoderDraw :: proc(
		render_pass_encoder: RenderPass,
		vertex_count: u32,
		instance_count: u32,
		first_vertex: u32,
		first_instance: u32) ---
	wgpuRenderPassEncoderDrawIndexed :: proc(
		render_pass_encoder: RenderPass,
		index_count: u32,
		instance_count: u32,
		first_index: u32,
		base_vertex: i32,
		first_instance: u32) ---
	wgpuRenderPassEncoderDrawIndexedIndirect :: proc(
		render_pass_encoder: RenderPass,
		indirect_buffer: Buffer,
		indirect_offset: u64) ---
	wgpuRenderPassEncoderDrawIndirect :: proc(
		render_pass_encoder: RenderPass,
		indirect_buffer: Buffer,
		indirect_offset: u64) ---
	wgpuRenderPassEncoderEnd :: proc(render_pass_encoder: RenderPass) ---
	wgpuRenderPassEncoderEndOcclusionQuery :: proc(render_pass_encoder: RenderPass) ---
	wgpuRenderPassEncoderExecuteBundles :: proc(
		render_pass_encoder: RenderPass,
		bundle_count: uint,
		bundles: [^]RenderBundle) ---
	wgpuRenderPassEncoderInsertDebugMarker :: proc(
		render_pass_encoder: RenderPass,
		marker_label: StringView) ---
	wgpuRenderPassEncoderPopDebugGroup :: proc(render_pass_encoder: RenderPass) ---
	wgpuRenderPassEncoderPushDebugGroup :: proc(
		render_pass_encoder: RenderPass,
		group_label: StringView) ---
	wgpuRenderPassEncoderSetBindGroup :: proc(
		render_pass_encoder: RenderPass,
		group_index: u32,
		group: BindGroup,
		dynamic_offset_count: uint,
		dynamic_offsets: [^]u32) ---
	wgpuRenderPassEncoderSetBlendConstant :: proc(
		render_pass_encoder: RenderPass, #by_ptr color: Color) ---
	wgpuRenderPassEncoderSetIndexBuffer :: proc(
		render_pass_encoder: RenderPass,
		buffer: Buffer,
		format: IndexFormat,
		offset: u64,
		size: u64) ---
	wgpuRenderPassEncoderSetLabel :: proc(
		render_pass_encoder: RenderPass, label: StringView) ---
	wgpuRenderPassEncoderSetPipeline :: proc(
		render_pass_encoder: RenderPass, pipeline: RenderPipeline) ---
	wgpuRenderPassEncoderSetScissorRect :: proc(
		render_pass_encoder: RenderPass, x: u32, y: u32, width: u32, height: u32) ---
	wgpuRenderPassEncoderSetStencilReference :: proc(
		render_pass_encoder: RenderPass, reference: u32) ---
	wgpuRenderPassEncoderSetVertexBuffer :: proc(
		render_pass_encoder: RenderPass,
		slot: u32,
		buffer: Buffer,
		offset: u64,
		size: u64) ---
	wgpuRenderPassEncoderSetViewport :: proc(
		render_pass_encoder: RenderPass,
		x: f32,
		y: f32,
		width: f32,
		height: f32,
		min_depth: f32,
		max_depth: f32) ---
	wgpuRenderPassEncoderAddRef :: proc(render_pass_encoder: RenderPass) ---
	wgpuRenderPassEncoderRelease :: proc(render_pass_encoder: RenderPass) ---

	wgpuRenderPipelineGetBindGroupLayout :: proc(
		render_pipeline: RenderPipeline,
		group_index: u32) -> BindGroupLayout ---
	wgpuRenderPipelineSetLabel :: proc(render_pipeline: RenderPipeline, label: StringView) ---
	wgpuRenderPipelineAddRef :: proc(render_pipeline: RenderPipeline) ---
	wgpuRenderPipelineRelease :: proc(render_pipeline: RenderPipeline) ---

	wgpuSamplerSetLabel :: proc(sampler: Sampler, label: StringView) ---
	wgpuSamplerAddRef :: proc(sampler: Sampler) ---
	wgpuSamplerRelease :: proc(sampler: Sampler) ---

	wgpuShaderModuleGetCompilationInfo :: proc(
		shader_module: ShaderModule,
		callback_info: CompilationInfoCallbackInfo) -> Future ---
	wgpuShaderModuleSetLabel :: proc(shader_module: ShaderModule, label: StringView) ---
	wgpuShaderModuleAddRef :: proc(shader_module: ShaderModule) ---
	wgpuShaderModuleRelease :: proc(shader_module: ShaderModule) ---

	wgpuSupportedFeaturesFreeMembers :: proc(supported_features: SupportedFeatures) ---

	wgpuSupportedWGSLLanguageFeaturesFreeMembers :: proc(
		supported_wgsl_language_features: SupportedWGSLLanguageFeatures) ---

	wgpuSurfaceConfigure :: proc(surface: Surface, #by_ptr config: WGPUSurfaceConfiguration) ---
	wgpuSurfaceGetCapabilities :: proc(
		surface: Surface,
		adapter: Adapter,
		capabilities: ^WGPUSurfaceCapabilities) -> Status ---
	wgpuSurfaceGetCurrentTexture :: proc(surface: Surface, surface_texture: ^SurfaceTexture) ---
	wgpuSurfacePresent :: proc(surface: Surface) -> Status ---
	wgpuSurfaceSetLabel :: proc(surface: Surface, label: StringView) ---
	wgpuSurfaceUnconfigure :: proc(surface: Surface) ---
	wgpuSurfaceAddRef :: proc(surface: Surface) ---
	wgpuSurfaceRelease :: proc(surface: Surface) ---

	wgpuSurfaceCapabilitiesFreeMembers :: proc(surfaceCapabilities: WGPUSurfaceCapabilities) ---

	wgpuTextureCreateView :: proc(
		texture: Texture,
		descriptor: ^WGPUTextureViewDescriptor) -> TextureView ---
	wgpuTextureDestroy :: proc(texture: Texture) ---
	wgpuTextureGetDepthOrArrayLayers :: proc(texture: Texture) -> u32 ---
	wgpuTextureGetDimension :: proc(texture: Texture) -> TextureDimension ---
	wgpuTextureGetFormat :: proc(texture: Texture) -> TextureFormat ---
	wgpuTextureGetHeight :: proc(texture: Texture) -> u32 ---
	wgpuTextureGetMipLevelCount :: proc(texture: Texture) -> u32 ---
	wgpuTextureGetSampleCount :: proc(texture: Texture) -> u32 ---
	wgpuTextureGetUsage :: proc(texture: Texture) -> TextureUsage ---
	wgpuTextureGetWidth :: proc(texture: Texture) -> u32 ---
	wgpuTextureSetLabel :: proc(texture: Texture, label: StringView) ---
	wgpuTextureAddRef :: proc(texture: Texture) ---
	wgpuTextureRelease :: proc(texture: Texture) ---

	wgpuTextureViewSetLabel :: proc(texture_view: TextureView, label: StringView) ---
	wgpuTextureViewAddRef :: proc(texture_view: TextureView) ---
	wgpuTextureViewRelease :: proc(texture_view: TextureView) ---
	// odinfmt: enable
}
