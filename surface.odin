package webgpu

// Core
import "base:runtime"
import "core:slice"

// Vendor
import "vendor:wgpu"

/*
Handle to a presentable surface.

A `Surface` represents a platform-specific surface (e.g. a window) onto which
rendered images may be presented. A `Surface` may be created with the procedure
`InstanceCreateSurface`.

This type is unique to the API of `wgpu-native`. In the WebGPU specification,
[`GPUCanvasContext`](https://gpuweb.github.io/gpuweb/#canvas-context) serves a
similar role.
*/
Surface :: wgpu.Surface

/* Behavior of the presentation engine based on frame rate. */
PresentMode :: wgpu.PresentMode

/* Specifies how the alpha channel of the textures should be handled during compositing. */
CompositeAlphaMode :: wgpu.CompositeAlphaMode

/* The capabilities of a given surface and adapter. */
SurfaceCapabilities :: struct {
	allocator:    runtime.Allocator,
	formats:      []TextureFormat,
	presentModes: []PresentMode,
	alphaModes:   []CompositeAlphaMode,
	usages:       TextureUsages,
}

/*
Returns the capabilities of the surface when used with the given adapter.

Returns `false` if surface is incompatible with the adapter.
*/
@(require_results)
SurfaceGetCapabilities :: proc(
	self: Surface,
	adapter: Adapter,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	caps: SurfaceCapabilities,
	ok: bool,
) #optional_ok {
	raw_caps, status := wgpu.SurfaceGetCapabilities(self, adapter)
	if status != .Success { return }

	defer wgpu.SurfaceCapabilitiesFreeMembers(raw_caps)

	caps.allocator = allocator
	caps.usages = raw_caps.usages

	context.allocator = allocator

	if raw_caps.formatCount > 0 {
		caps.formats = make([]TextureFormat, raw_caps.formatCount)
		temp := slice.from_ptr(raw_caps.formats, int(raw_caps.formatCount))
		copy(caps.formats, temp)
	}

	if raw_caps.presentModeCount > 0 {
		caps.presentModes = make([]PresentMode, raw_caps.presentModeCount)
		temp := slice.from_ptr(raw_caps.presentModes, int(raw_caps.presentModeCount))
		copy(caps.presentModes, temp)
	}

	if raw_caps.alphaModeCount > 0 {
		caps.alphaModes = make([]CompositeAlphaMode, raw_caps.alphaModeCount)
		temp := slice.from_ptr(raw_caps.alphaModes, int(raw_caps.alphaModeCount))
		copy(caps.alphaModes, temp)
	}

	return caps, true
}

SurfaceCapabilitiesFreeMembers :: proc(caps: SurfaceCapabilities) {
	context.allocator = caps.allocator
	delete(caps.formats)
	delete(caps.presentModes)
	delete(caps.alphaModes)
}

RawSurfaceGetCapabilities :: wgpu.SurfaceGetCapabilities
RawSurfaceCapabilitiesFreeMembers :: wgpu.SurfaceCapabilitiesFreeMembers

/*
Describes a `Surface`.

For use with `SurfaceConfigure`.

Corresponds to [WebGPU `GPUCanvasConfiguration`](
https://gpuweb.github.io/gpuweb/#canvas-configuration).
*/
SurfaceConfiguration :: struct {
	device:                     Device,
	format:                     TextureFormat,
	usage:                      TextureUsages,
	width:                      u32,
	height:                     u32,
	viewFormats:                []TextureFormat,
	alphaMode:                  CompositeAlphaMode,
	presentMode:                PresentMode,
	// Extras
	desiredMaximumFrameLatency: u32,
}

/*
Return a default `SurfaceConfiguration` from `width` and `height` to use for the
`Surface` with this adapter.

Returns `false` if the surface isn't supported by this adapter.
*/
SurfaceGetDefaultConfig :: proc(
	self: Surface,
	adapter: Adapter,
	width, height: u32,
) -> (
	config: SurfaceConfiguration,
	ok: bool,
) #optional_ok {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	ta := context.temp_allocator

	caps, caps_ok := SurfaceGetCapabilities(self, adapter, ta)
	if !caps_ok { return }

	config = {
		usage       = { .RenderAttachment },
		format      = caps.formats[0],
		width       = width,
		height      = height,
		presentMode = caps.presentModes[0],
		alphaMode   = .Auto,
	}

	return config, true
}

/*
Initializes `Surface` for presentation.

**Panics**
- A old `SurfaceTexture` is still alive referencing an old surface.
- Texture format requested is unsupported on the surface.
- `config.width` or `config.height` is zero.
*/
SurfaceConfigure :: proc "c" (
	self: Surface,
	config: SurfaceConfiguration,
	loc := #caller_location,
) {
	assert_contextless(config.width != 0, "Surface width cannot be zero", loc)
	assert_contextless(config.height != 0, "Surface height cannot be zero", loc)

	alpha_mode := config.alphaMode

	// Alpha mode 'Auto' is not a valid enum value for WebGPU
	when ODIN_OS == .JS {
		if alpha_mode == .Auto {
			alpha_mode = .Opaque
		}
	}

	raw_config := wgpu.SurfaceConfiguration {
		device      = config.device,
		format      = config.format,
		usage       = config.usage,
		width       = config.width,
		height      = config.height,
		alphaMode   = alpha_mode,
		presentMode = config.presentMode,
	}

	if len(config.viewFormats) > 0 {
		raw_config.viewFormatCount = len(config.viewFormats)
		raw_config.viewFormats = raw_data(config.viewFormats)
	}

	when ODIN_OS != .JS {
		extras: wgpu.SurfaceConfigurationExtras
		if config.desiredMaximumFrameLatency > 0 {
			extras = {
				chain = { sType = .SurfaceConfigurationExtras },
				desiredMaximumFrameLatency = config.desiredMaximumFrameLatency,
			}
			raw_config.nextInChain = &extras.chain
		}
	}

	wgpu.SurfaceConfigure(self, &raw_config)
}

/* Removes the surface configuration. Destroys any textures produced while configured. */
SurfaceUnconfigure :: wgpu.SurfaceUnconfigure

/* Status of the received surface image. */
SurfaceStatus :: wgpu.SurfaceGetCurrentTextureStatus

/* Status of the received surface image. */
SurfaceGetCurrentTextureStatus :: wgpu.SurfaceGetCurrentTextureStatus

/*
Surface texture that can be rendered to. Result of a successful call to
`SurfaceGetCurrentTexture`.

This type is unique to the `wgpu-native`. In the WebGPU specification, the
[`GPUCanvasContext`](https://gpuweb.github.io/gpuweb/#canvas-context) provides a
texture without any additional information.
*/
SurfaceTexture :: struct {
	surface: Surface,
	texture: Texture,
	status:  SurfaceStatus,
}

/*
Returns the next texture to be presented by the swapchain for drawing.

In order to present the `SurfaceTexture` returned by this method,
first a `queue_submit` needs to be done with some work rendering to this texture.
Then `SurfacePresent` needs to be called.

If a `SurfaceTexture` referencing this surface is alive when the swapchain is recreated,
recreating the swapchain will panic.
*/
@(require_results)
SurfaceGetCurrentTexture :: proc "c" (self: Surface) -> (surfaceTexture: SurfaceTexture) {
	rawSurfaceTexture := wgpu.SurfaceGetCurrentTexture(self)
	surfaceTexture = {
		surface = self,
		texture = rawSurfaceTexture.texture,
		status  = rawSurfaceTexture.status,
	}
	return
}

/*
Schedule this texture to be presented on the owning surface.

Needs to be called after any work on the texture is scheduled via `QueueSubmit`.

**Platform dependent behavior**

On Wayland, `SurfacePresent` will attach a `wl_buffer` to the underlying
`wl_surface` and commit the new surface state. If it is desired to do things
such as request a frame callback, scale the surface using the viewporter or
synchronize other double buffered state, then these operations should be done
before the call to `SurfacePresent`.
*/
SurfacePresent :: wgpu.SurfacePresent

/*
Schedule this texture to be presented on the owning surface.

Needs to be called after any work on the texture is scheduled via `QueueSubmit`.

**Platform dependent behavior**

On Wayland, `SurfacePresent` will attach a `wl_buffer` to the underlying
`wl_surface` and commit the new surface state. If it is desired to do things
such as request a frame callback, scale the surface using the viewporter or
synchronize other double buffered state, then these operations should be done
before the call to `SurfacePresent`.
*/
SurfaceTexturePresent :: proc "c" (self: SurfaceTexture) {
	wgpu.SurfacePresent(self.surface)
}

/*
Release the `Texture` resources from this `SurfaceTexture`, use to decrease the
reference count.
*/
SurfaceTextureRelease :: proc "c" (self: SurfaceTexture) {
	wgpu.TextureRelease(self.texture)
}

/*
Safely releases the `SurfaceTexture` resources and invalidates the handle. The
procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
SurfaceTextureReleaseSafe :: #force_inline proc "c" (self: ^SurfaceTexture) {
	if self != nil && self.texture != nil {
		wgpu.TextureRelease(self.texture)
		self.texture = nil
	}
}

/* Sets a debug label for the given `Surface`. */
SurfaceSetLabel :: #force_inline proc "c" (self: Surface, label: string)  {
	wgpu.SurfaceSetLabel(self, label)
}

/* Increase the `Surface` reference count. */
SurfaceAddRef :: #force_inline proc "c" (self: Surface)  {
	wgpu.SurfaceAddRef(self)
}

/* Release the `Surface` resources, use to decrease the reference count. */
SurfaceRelease :: #force_inline proc "c" (self: Surface)  {
	wgpu.SurfaceRelease(self)
}

/*
Safely releases the `Surface` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
SurfaceReleaseSafe :: proc "c" (self: ^Surface) {
	if self != nil && self^ != nil {
		wgpu.SurfaceRelease(self^)
		self^ = nil
	}
}
