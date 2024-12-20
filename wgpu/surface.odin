package wgpu

// Packages
import "base:runtime"
import "core:slice"

/*
Handle to a presentable surface.

A `Surface` represents a platform-specific surface (e.g. a window) onto which rendered images may
be presented. A `Surface` may be created with the function `instance_create_surface`.

This type is unique to the API of `wgpu-native`. In the WebGPU specification,
[`GPUCanvasContext`](https://gpuweb.github.io/gpuweb/#canvas-context)
serves a similar role.
*/
Surface :: distinct rawptr

/*
Describes a `Surface`.

For use with `surface_configure`.

Corresponds to [WebGPU `GPUCanvasConfiguration`](
https://gpuweb.github.io/gpuweb/#canvas-configuration).
*/
SurfaceConfiguration :: struct {
	device:                        Device,
	format:                        TextureFormat,
	usage:                         TextureUsage,
	width:                         u32,
	height:                        u32,
	view_formats:                  []TextureFormat,
	alpha_mode:                    CompositeAlphaMode,
	present_mode:                  PresentMode,
	// Extras
	desired_maximum_frame_latency: u32,
}

/*
Initializes `Surface` for presentation.

**Panics**
- A old `SurfaceTexture` is still alive referencing an old surface.
- Texture format requested is unsupported on the surface.
- `config.width` or `config.height` is zero.
*/
surface_configure :: proc "contextless" (
	self: Surface,
	config: SurfaceConfiguration,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	raw_config := WGPUSurfaceConfiguration {
		device       = config.device,
		format       = config.format,
		usage        = config.usage,
		width        = config.width,
		height       = config.height,
		alpha_mode   = config.alpha_mode,
		present_mode = config.present_mode,
	}

	if len(config.view_formats) > 0 {
		raw_config.view_format_count = len(config.view_formats)
		raw_config.view_formats = raw_data(config.view_formats)
	}

	extras: SurfaceConfigurationExtras
	if config.desired_maximum_frame_latency > 0 {
		extras = {
			chain = {stype = .SurfaceConfigurationExtras},
			desired_maximum_frame_latency = config.desired_maximum_frame_latency,
		}
		raw_config.next_in_chain = &extras.chain
	}

	error_reset_data(loc)
	wgpuSurfaceConfigure(self, raw_config)
	return has_no_error()
}

/*
Returns the capabilities of the surface when used with the given adapter.

Returns specified values if surface is incompatible with the adapter.
*/
@(require_results)
surface_get_capabilities :: proc(
	self: Surface,
	adapter: Adapter,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	caps: SurfaceCapabilities,
	ok: bool,
) #optional_ok {
	raw_caps: WGPUSurfaceCapabilities

	error_reset_data(loc)
	status := wgpuSurfaceGetCapabilities(self, adapter, &raw_caps)
	if has_error() {
		return
	}
	defer wgpuSurfaceCapabilitiesFreeMembers(raw_caps)

	if status != .Success {
		error_reset_and_update(ErrorType.Unknown, "Failed to get surface capabilities", loc)
		return
	}

	caps.allocator = allocator
	caps.usages = raw_caps.usages

	alloc_err: runtime.Allocator_Error

	if raw_caps.format_count > 0 {
		caps.formats, alloc_err = make([]TextureFormat, raw_caps.format_count, allocator)
		assert(alloc_err == nil, "Failed to allocate formats capabilities")
		temp := slice.from_ptr(raw_caps.formats, int(raw_caps.format_count))
		copy(caps.formats, temp)
	}

	if raw_caps.present_mode_count > 0 {
		caps.present_modes, alloc_err = make([]PresentMode, raw_caps.present_mode_count, allocator)
		assert(alloc_err == nil, "Failed to allocate present modes capabilities")
		temp := slice.from_ptr(raw_caps.present_modes, int(raw_caps.present_mode_count))
		copy(caps.present_modes, temp)
	}

	if raw_caps.alpha_mode_count > 0 {
		caps.alpha_modes, alloc_err = make(
			[]CompositeAlphaMode,
			raw_caps.alpha_mode_count,
			allocator,
		)
		assert(alloc_err == nil, "Failed to allocate alpha modes capabilities")
		temp := slice.from_ptr(raw_caps.alpha_modes, int(raw_caps.alpha_mode_count))
		copy(caps.alpha_modes, temp)
	}

	return caps, true
}

/*
Returns the next texture to be presented by the swapchain for drawing.

In order to present the `SurfaceTexture` returned by this method,
first a `queue_submit` needs to be done with some work rendering to this texture.
Then `surface_present` needs to be called.

If a `SurfaceTexture` referencing this surface is alive when the swapchain is recreated,
recreating the swapchain will panic.
*/
@(require_results)
surface_get_current_texture :: proc "contextless" (
	self: Surface,
	loc := #caller_location,
) -> (
	surface_texture: SurfaceTexture,
	ok: bool,
) #optional_ok {
	error_reset_data(loc)
	wgpuSurfaceGetCurrentTexture(self, &surface_texture)
	if has_error() {
		if surface_texture.texture != nil {
			wgpuTextureRelease(surface_texture.texture)
		}
		return
	}
	return surface_texture, true
}

/*
Schedule this texture to be presented on the owning surface.

Needs to be called after any work on the texture is scheduled via `queue_submit`.

**Platform dependent behavior**

On Wayland, `present` will attach a `wl_buffer` to the underlying `wl_surface` and commit the new
surface state. If it is desired to do things such as request a frame callback, scale the surface
 using the viewporter or synchronize other double buffered state, then these operations should be
 done before the call to `present`.
*/
surface_present :: proc(self: Surface, loc := #caller_location) -> (ok: bool) {
	error_reset_data(loc)
	status := wgpuSurfacePresent(self)
	if has_error() {
		return
	}
	if status == .Error {
		error_reset_and_update(ErrorType.Unknown, "Failed to present", loc)
		return
	}
	return true
}

/* Set debug label. */
@(disabled = !ODIN_DEBUG)
surface_set_label :: proc "contextless" (self: Surface, label: string) {
	c_label: StringViewBuffer
	wgpuSurfaceSetLabel(self, init_string_buffer(&c_label, label))
}

/* Removes the surface configuration. Destroys any textures produced while configured. */
surface_unconfigure :: proc "contextless" (self: Surface) {
	wgpuSurfaceUnconfigure(self)
}

/*
Return a default `SurfaceConfiguration` from `width` and `height` to use for the `Surface` with
this adapter.

Returns `false` if the surface isn't supported by this adapter.
*/
surface_get_default_config :: proc(
	self: Surface,
	adapter: Adapter,
	width, height: u32,
	loc := #caller_location,
) -> (
	config: SurfaceConfiguration,
	ok: bool,
) #optional_ok {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	caps := surface_get_capabilities(self, adapter, context.temp_allocator, loc) or_return

	config = {
		usage        = {.RenderAttachment},
		format       = caps.formats[0],
		width        = width,
		height       = height,
		present_mode = caps.present_modes[0],
		alpha_mode   = .Auto,
	}

	return config, true
}

/* Increase the reference count. */
surface_add_ref :: wgpuSurfaceAddRef

/* Release the `Surface` resources. */
surface_release :: wgpuSurfaceRelease
