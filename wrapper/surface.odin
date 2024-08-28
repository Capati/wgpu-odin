package wgpu

// STD Library
import "base:runtime"
import "core:mem"
import "core:slice"

// The raw bindings
import wgpu "../bindings"

/*
Handle to a presentable surface.

A `Surface` represents a platform-specific surface (e.g. a window) onto which rendered images may
be presented. A `Surface` may be created with the function `instance_create_surface`.

This type is unique to the API of `wgpu-native`. In the WebGPU specification,
[`GPUCanvasContext`](https://gpuweb.github.io/gpuweb/#canvas-context)
serves a similar role.
*/
Surface :: wgpu.Surface

/*
Describes a `Surface`.

For use with `surface_configure`.

Corresponds to [WebGPU `GPUCanvasConfiguration`](
https://gpuweb.github.io/gpuweb/#canvas-configuration).
*/
Surface_Configuration :: struct {
	format                        : Texture_Format,
	usage                         : Texture_Usage_Flags,
	view_formats                  : []Texture_Format,
	alpha_mode                    : Composite_Alpha_Mode,
	width                         : u32,
	height                        : u32,
	present_mode                  : Present_Mode,
	desired_maximum_frame_latency : u32,
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
	device: Device,
	config: Surface_Configuration,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	raw_config := wgpu.Surface_Configuration {
		device = device,
	}

	raw_config.format = config.format
	raw_config.usage = config.usage
	raw_config.alpha_mode = config.alpha_mode
	raw_config.width = config.width
	raw_config.height = config.height
	raw_config.present_mode = config.present_mode

	view_format_count := len(config.view_formats)

	if view_format_count > 0 {
		raw_config.view_format_count = uint(view_format_count)
		raw_config.view_formats = raw_data(config.view_formats)
	} else {
		raw_config.view_format_count = 0
		raw_config.view_formats = nil
	}

	extras: wgpu.Surface_Configuration_Extras

	if config.desired_maximum_frame_latency > 0 {
		extras.stype = wgpu.SType(wgpu.Native_SType.Surface_Configuration_Extras)
		extras.desired_maximum_frame_latency = config.desired_maximum_frame_latency
		raw_config.next_in_chain = &extras.chain
	}

	_error_reset_data(loc)

	wgpu.surface_configure(self, &raw_config)

	return get_last_error() == nil
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
	raw_caps: wgpu.Surface_Capabilities

	wgpu.surface_get_capabilities(self, adapter, &raw_caps)
	defer wgpu.surface_capabilities_free_members(raw_caps)

	alloc_err: mem.Allocator_Error

	if raw_caps.format_count > 0 {
		formats_tmp := slice.from_ptr(raw_caps.formats, int(raw_caps.format_count))
		caps.formats, alloc_err = make([]Texture_Format, raw_caps.format_count, allocator)
		if alloc_err != nil {
			error_reset_and_update(
				alloc_err,
				"Failed to allocate formats capabilities",
				loc,
			)
			return
		}
		copy(caps.formats, formats_tmp)
	}

	if raw_caps.present_mode_count > 0 {
		present_modes_tmp := slice.from_ptr(
			raw_caps.present_modes,
			int(raw_caps.present_mode_count),
		)
		if caps.present_modes, alloc_err = make(
			[]Present_Mode,
			raw_caps.present_mode_count,
			allocator,
		); alloc_err != nil {
			error_reset_and_update(alloc_err, "Failed to allocate present modes capabilities", loc)
			return
		}
		copy(caps.present_modes, present_modes_tmp)
	}

	if raw_caps.alpha_mode_count > 0 {
		alpha_modes_tmp := slice.from_ptr(raw_caps.alpha_modes, int(raw_caps.alpha_mode_count))
		if caps.alpha_modes, alloc_err = make(
			[]Composite_Alpha_Mode,
			raw_caps.alpha_mode_count,
			allocator,
		); alloc_err != nil {
			error_reset_and_update(alloc_err, "Failed to allocate alpha modes capabilities", loc)
			return
		}
		copy(caps.alpha_modes, alpha_modes_tmp)
	}

	return caps, true
}

/*
Surface texture that can be rendered to.
Result of a successful call to `surface_get_current_texture`.

This type is unique to the `wgpu-native`. In the WebGPU specification,
the [`GPUCanvasContext`](https://gpuweb.github.io/gpuweb/#canvas-context) provides
a texture without any additional information.
*/
Surface_Texture :: struct {
	texture    : Texture,
	suboptimal : bool,
	status     : wgpu.Surface_Get_Current_Texture_Status,
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
	_error_reset_data(loc)

	texture: wgpu.Surface_Texture
	wgpu.surface_get_current_texture(self, &texture)

	if get_last_error() != nil {
		if texture.texture != nil {
			wgpu.texture_release(texture.texture)
		}
		return
	}

	surface_texture = {
		texture    = texture.texture,
		suboptimal = bool(texture.suboptimal),
		status     = texture.status,
	}

	return surface_texture, true
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
surface_present :: proc "contextless" (
	self: Surface,
	loc := #caller_location,
) -> (
	ok: bool,
) {
	_error_reset_data(loc)
	wgpu.surface_present(self)
	return get_last_error() == nil
}

/* Removes the surface configuration. Destroys any textures produced while configured. */
surface_unconfigure :: proc "contextless" (self: Surface) {
	wgpu.surface_unconfigure(self)
}

/*
Return a default `Surface_Configuration` from `width` and `height` to use for the `Surface` with
this adapter.

Returns `false` if the surface isn't supported by this adapter
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
	}

	return config, true
}

/* Increase the reference count. */
surface_reference :: wgpu.surface_reference

/* Release the `Surface` resources. */
surface_release :: wgpu.surface_release
