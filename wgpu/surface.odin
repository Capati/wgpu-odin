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

Surface_Source_Android_Native_Window :: struct {
	chain:  Chained_Struct,
	window: rawptr,
}

Surface_Source_Metal_Layer :: struct {
	chain: Chained_Struct,
	layer: rawptr,
}

Surface_Source_Wayland_Surface :: struct {
	chain:   Chained_Struct,
	display: rawptr,
	surface: rawptr,
}

Surface_Source_Windows_HWND :: struct {
	chain:     Chained_Struct,
	hinstance: rawptr,
	hwnd:      rawptr,
}

Surface_Source_XBC_Window :: struct {
	chain:      Chained_Struct,
	connection: rawptr,
	window:     u32,
}

Surface_Source_Xlib_Window :: struct {
	chain:   Chained_Struct,
	display: rawptr,
	window:  u64,
}

/* Describes a surface target. */
Surface_Descriptor :: struct {
	label:  string,
	target: union {
		Surface_Source_Android_Native_Window,
		Surface_Source_Metal_Layer,
		Surface_Source_Wayland_Surface,
		Surface_Source_Windows_HWND,
		Surface_Source_XBC_Window,
		Surface_Source_Xlib_Window,
	},
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
	caps: Surface_Capabilities,
	ok: bool,
) #optional_ok {
	raw_caps: WGPU_Surface_Capabilities

	error_reset_data(loc)
	status := wgpuSurfaceGetCapabilities(self, adapter, &raw_caps)
	if has_error() {
		return
	}
	defer wgpuSurfaceCapabilitiesFreeMembers(raw_caps)

	if status != .Success {
		error_reset_and_update(Error_Type.Unknown, "Failed to get surface capabilities", loc)
		return
	}

	caps.allocator = allocator
	caps.usages = raw_caps.usages

	alloc_err: runtime.Allocator_Error

	if raw_caps.format_count > 0 {
		caps.formats, alloc_err = make([]Texture_Format, raw_caps.format_count, allocator)
		assert(alloc_err == nil, "Failed to allocate formats capabilities")
		temp := slice.from_ptr(raw_caps.formats, int(raw_caps.format_count))
		copy(caps.formats, temp)
	}

	if raw_caps.present_mode_count > 0 {
		caps.present_modes, alloc_err = make(
			[]Present_Mode,
			raw_caps.present_mode_count,
			allocator,
		)
		assert(alloc_err == nil, "Failed to allocate present modes capabilities")
		temp := slice.from_ptr(raw_caps.present_modes, int(raw_caps.present_mode_count))
		copy(caps.present_modes, temp)
	}

	if raw_caps.alpha_mode_count > 0 {
		caps.alpha_modes, alloc_err = make(
			[]Composite_Alpha_Mode,
			raw_caps.alpha_mode_count,
			allocator,
		)
		assert(alloc_err == nil, "Failed to allocate alpha modes capabilities")
		temp := slice.from_ptr(raw_caps.alpha_modes, int(raw_caps.alpha_mode_count))
		copy(caps.alpha_modes, temp)
	}

	return caps, true
}

@(private)
WGPU_Surface_Configuration_Extras :: struct {
	chain:                         Chained_Struct,
	desired_maximum_frame_latency: u32,
}

/*
Describes a `Surface`.

For use with `surface_configure`.

Corresponds to [WebGPU `GPUCanvasConfiguration`](
https://gpuweb.github.io/gpuweb/#canvas-configuration).
*/
Surface_Configuration :: struct {
	device:                        Device,
	format:                        Texture_Format,
	usage:                         Texture_Usages,
	width:                         u32,
	height:                        u32,
	view_formats:                  []Texture_Format,
	alpha_mode:                    Composite_Alpha_Mode,
	present_mode:                  Present_Mode,
	// Extras
	desired_maximum_frame_latency: u32,
}

/*
Return a default `Surface_Configuration` from `width` and `height` to use for the `Surface` with
this adapter.

Returns `false` if the surface isn't supported by this adapter.
*/
surface_get_default_config :: proc(
	self: Surface,
	adapter: Adapter,
	width, height: u32,
	loc := #caller_location,
) -> (
	config: Surface_Configuration,
	ok: bool,
) #optional_ok {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	caps := surface_get_capabilities(self, adapter, context.temp_allocator, loc) or_return

	config = {
		usage        = {.Render_Attachment},
		format       = caps.formats[0],
		width        = width,
		height       = height,
		present_mode = caps.present_modes[0],
		alpha_mode   = .Auto,
	}

	return config, true
}

/*
Initializes `Surface` for presentation.

**Panics**
- A old `Surface_Texture` is still alive referencing an old surface.
- Texture format requested is unsupported on the surface.
- `config.width` or `config.height` is zero.
*/
surface_configure :: proc "contextless" (
	self: Surface,
	config: Surface_Configuration,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	raw_config := WGPU_Surface_Configuration {
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

	extras: WGPU_Surface_Configuration_Extras
	if config.desired_maximum_frame_latency > 0 {
		extras = {
			chain = {stype = .Surface_Configuration_Extras},
			desired_maximum_frame_latency = config.desired_maximum_frame_latency,
		}
		raw_config.next_in_chain = &extras.chain
	}

	error_reset_data(loc)
	wgpuSurfaceConfigure(self, raw_config)
	return has_no_error()
}

/* Removes the surface configuration. Destroys any textures produced while configured. */
surface_unconfigure :: wgpuSurfaceUnconfigure

@(private)
WGPU_Surface_Texture :: struct {
	next_in_chain: ^Chained_Struct_Out,
	texture:       Texture,
	status:        Surface_Status,
}

/*
Surface texture that can be rendered to.
Result of a successful call to `surface_get_current_texture`.

This type is unique to the `wgpu-native`. In the WebGPU specification,
the [`GPUCanvasContext`](https://gpuweb.github.io/gpuweb/#canvas-context) provides
a texture without any additional information.
*/
Surface_Texture :: struct {
	surface: Surface,
	texture: Texture,
	status:  Surface_Status,
}

/*
Returns the next texture to be presented by the swapchain for drawing.

In order to present the `Surface_Texture` returned by this method,
first a `queue_submit` needs to be done with some work rendering to this texture.
Then `surface_present` needs to be called.

If a `Surface_Texture` referencing this surface is alive when the swapchain is recreated,
recreating the swapchain will panic.
*/
@(require_results)
surface_get_current_texture :: proc "contextless" (
	self: Surface,
	loc := #caller_location,
) -> (
	surface_texture: Surface_Texture,
	ok: bool,
) #optional_ok {
	surface_texture_raw: WGPU_Surface_Texture

	error_reset_data(loc)
	wgpuSurfaceGetCurrentTexture(self, &surface_texture_raw)
	if has_error() {
		if surface_texture_raw.texture != nil {
			wgpuTextureRelease(surface_texture_raw.texture)
		}
		return
	}

	surface_texture = {
		surface = self,
		texture = surface_texture_raw.texture,
		status  = surface_texture_raw.status,
	}

	return surface_texture, true
}

/*
Schedule this texture to be presented on the owning surface.

Needs to be called after any work on the texture is scheduled via [`Queue::submit`].

**Platform dependent behavior**

On Wayland, `surface_present` will attach a `wl_buffer` to the underlying `wl_surface` and commit
the new surface state. If it is desired to do things such as request a frame callback, scale the
surface using the viewporter or synchronize other double buffered state, then these operations
should be done before the call to `present`.
*/
surface_present :: proc "contextless" (self: Surface, loc := #caller_location) -> (ok: bool) {
	error_reset_data(loc)
	status := wgpuSurfacePresent(self)
	if has_error() {
		return
	}
	if status == .Error {
		error_reset_and_update(Error_Type.Unknown, "Failed to present", loc)
		return
	}
	return true
}

/*
Schedule this texture to be presented on the owning surface.

Needs to be called after any work on the texture is scheduled via [`Queue::submit`].

**Platform dependent behavior**

On Wayland, `present` will attach a `wl_buffer` to the underlying `wl_surface` and commit the new
surface state. If it is desired to do things such as request a frame callback, scale the surface
using the viewporter or synchronize other double buffered state, then these operations should be
done before the call to `present`.
*/
surface_texture_present :: proc "contextless" (self: Surface_Texture) {
	surface_present(self.surface)
}

/*
Release the `Texture` resources from this `Surface_Texture`, use to decrease the reference count.
*/
surface_texture_release :: proc "contextless" (self: Surface_Texture) {
	wgpuTextureRelease(self.texture)
}

/*
Safely releases the `Surface_Texture` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
surface_texture_release_safe :: #force_inline proc(self: ^Surface_Texture) {
	if self != nil && self.texture != nil {
		wgpuTextureRelease(self.texture)
		self.texture = nil
	}
}

/* Sets a debug label for the given `Surface`. */
@(disabled = !ODIN_DEBUG)
surface_set_label :: proc "contextless" (self: Surface, label: string) {
	c_label: String_View_Buffer
	wgpuSurfaceSetLabel(self, init_string_buffer(&c_label, label))
}

/* Increase the `Surface` reference count. */
surface_add_ref :: wgpuSurfaceAddRef

/* Release the `Surface` resources, use to decrease the reference count. */
surface_release :: wgpuSurfaceRelease

/*
Safely releases the `Surface` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
surface_release_safe :: #force_inline proc(self: ^Surface) {
	if self != nil && self^ != nil {
		wgpuSurfaceRelease(self^)
		self^ = nil
	}
}

@(private)
WGPU_Surface_Descriptor :: struct {
	next_in_chain: ^Chained_Struct,
	label:         String_View,
}
