package wgpu

// Core
import "core:mem"
import "core:runtime"
import "core:slice"

// Package
import wgpu "../bindings"

// Handle to a presentable surface.
//
// A `Surface` represents a platform-specific surface (e.g. a window) onto which rendered images
// may be presented. A `Surface` may be created with `instance_create_surface`.
Surface :: struct {
	_ptr:      WGPU_Surface,
	_err_data: ^Error_Data,
	config:    Surface_Configuration,
}

// Describes a `Surface`.
//
// For use with `surface_configure`.
Surface_Configuration :: struct {
	format:       Texture_Format,
	usage:        Texture_Usage_Flags,
	view_formats: []Texture_Format,
	alpha_mode:   Composite_Alpha_Mode,
	width:        u32,
	height:       u32,
	present_mode: Present_Mode,
}

// Initializes `Surface` for presentation.
surface_configure :: proc(
	self: ^Surface,
	device: ^Device,
	config: ^Surface_Configuration,
) -> Error_Type {
	cfg := wgpu.Surface_Configuration {
		device = device._ptr,
	}

	if config != nil {
		cfg.format = config.format
		cfg.usage = config.usage
		cfg.alpha_mode = config.alpha_mode
		cfg.width = config.width
		cfg.height = config.height
		cfg.present_mode = config.present_mode

		view_format_count := cast(uint)len(config.view_formats)

		if view_format_count > 0 {
			cfg.view_format_count = view_format_count
			cfg.view_formats = raw_data(config.view_formats)
		} else {
			cfg.view_format_count = 0
			cfg.view_formats = nil
		}
	}

	self.config = config^

	device._err_data.type = .No_Error

	wgpu.surface_configure(self._ptr, &cfg)

	if device._err_data.type != .No_Error {
		return device._err_data.type
	}

	self._err_data = device._err_data

	return .No_Error
}

// Defines the capabilities of a given surface and adapter.
Surface_Capabilities :: struct {
	formats:       []Texture_Format,
	present_modes: []Present_Mode,
	alpha_modes:   []Composite_Alpha_Mode,
}

// Returns the capabilities of the surface when used with the given adapter.
surface_get_capabilities :: proc(
	using self: ^Surface,
	adapter: ^Adapter,
	allocator := context.allocator,
) -> (
	Surface_Capabilities,
	Error_Type,
) {
	caps: wgpu.Surface_Capabilities = {}
	wgpu.surface_get_capabilities(_ptr, adapter._ptr, &caps)

	if caps.format_count == 0 && caps.present_mode_count == 0 && caps.alpha_mode_count == 0 {
		update_error_message("No compatible capabilities found with the given adapter")
		return {}, .Unknown
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == context.temp_allocator)

	wgpu.surface_get_capabilities(_ptr, adapter._ptr, &caps)

	ret := Surface_Capabilities{}

	if caps.format_count > 0 {
		formats_tmp := slice.from_ptr(caps.formats, int(caps.format_count))
		ret.formats = make([]Texture_Format, caps.format_count, allocator)
		copy(ret.formats, formats_tmp)
	}

	if caps.present_mode_count > 0 {
		present_modes_tmp := slice.from_ptr(caps.present_modes, int(caps.present_mode_count))
		ret.present_modes = make([]Present_Mode, caps.present_mode_count, allocator)
		copy(ret.present_modes, present_modes_tmp)
	}

	if caps.alpha_mode_count > 0 {
		alpha_modes_tmp := slice.from_ptr(caps.alpha_modes, int(caps.alpha_mode_count))
		ret.alpha_modes = make([]Composite_Alpha_Mode, caps.alpha_mode_count, allocator)
		copy(ret.alpha_modes, alpha_modes_tmp)
	}

	wgpu.surface_capabilities_free_members(caps)

	return ret, .No_Error
}

surface_delete_capabilities :: proc(caps: ^Surface_Capabilities) {
	delete(caps.formats)
	delete(caps.present_modes)
	delete(caps.alpha_modes)
}

// Returns the next texture to be presented by the swapchain for drawing.
surface_get_current_texture :: proc(
	using self: ^Surface,
) -> (
	surface_texture: Surface_Texture,
	err: Error_Type,
) {
	_err_data.type = .No_Error

	texture: wgpu.Surface_Texture
	wgpu.surface_get_current_texture(_ptr, &texture)

	if _err_data.type != .No_Error {
		wgpu.texture_release(texture.texture)
		return {}, _err_data.type
	}

	surface_texture = {
		texture = Texture {
			_ptr = texture.texture,
			_err_data = _err_data,
			descriptor =  {
				size = {config.width, config.height, 1},
				format = config.format,
				usage = config.usage,
				mip_level_count = 1,
				sample_count = 1,
				dimension = .D2,
			},
		},
		suboptimal = texture.suboptimal,
		status = texture.status,
	}

	return surface_texture, .No_Error
}

// Returns the best format for the provided surface and adapter.
surface_get_preferred_format :: proc(using self: ^Surface, adapter: ^Adapter) -> Texture_Format {
	return wgpu.surface_get_preferred_format(_ptr, adapter._ptr)
}

// Schedule this surface to be presented on the owning surface.
surface_present :: proc(using self: ^Surface) {
	wgpu.surface_present(_ptr)
}

// Removes the surface configuration. Destroys any textures produced while configured.
surface_unconfigure :: proc(using self: ^Surface) {
	wgpu.surface_unconfigure(_ptr)
}

// Return a default `Surface_Configuration` from `width` and `height` to use for the
// `Surface` with this adapter.
surface_get_default_config :: proc(
	self: ^Surface,
	adapter: ^Adapter,
	width, height: u32,
) -> (
	config: Surface_Configuration,
	err: Error_Type,
) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	caps := surface_get_capabilities(self, adapter, context.temp_allocator) or_return

	config = {
		usage = {.Render_Attachment},
		format = caps.formats[0],
		width = width,
		height = height,
		present_mode = caps.present_modes[0],
	}

	return
}

// Increase the reference count.
surface_reference :: proc(using self: ^Surface) {
	wgpu.surface_reference(_ptr)
}

// Release the `Surface`.
surface_release :: proc(using self: ^Surface) {
	wgpu.surface_release(_ptr)
}
