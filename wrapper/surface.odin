package wgpu

// Core
import "base:runtime"
import "core:mem"
import "core:slice"

// Package
import wgpu "../bindings"

// Handle to a presentable surface.
//
// A `Surface` represents a platform-specific surface (e.g. a window) onto which rendered images
// may be presented. A `Surface` may be created with `instance_create_surface`.
Surface :: struct {
	ptr:       Raw_Surface,
	config:    Surface_Configuration,
	_err_data: ^Error_Data,
}

Surface_Configuration_Extras :: struct {
	desired_maximum_frame_latency: bool,
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
	extras:       Surface_Configuration_Extras,
}

// Initializes `Surface` for presentation.
surface_configure :: proc(
	self: ^Surface,
	device: ^Device,
	config: ^Surface_Configuration,
	loc := #caller_location,
) -> (
	err: Error,
) {
	cfg := wgpu.Surface_Configuration {
		device = device.ptr,
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

	extras: wgpu.Surface_Configuration_Extras

	if config.extras.desired_maximum_frame_latency {
		extras.chain.next = nil
		extras.chain.stype = wgpu.SType(wgpu.Native_SType.Surface_Configuration_Extras)
		extras.desired_maximum_frame_latency = true
		cfg.next_in_chain = &extras.chain
	}

	set_and_reset_err_data(self._err_data, loc)

	wgpu.surface_configure(self.ptr, &cfg)

	if err = get_last_error(); err != nil {
		return
	}

	self._err_data = device._err_data

	return
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
	adapter: Raw_Adapter,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	caps: Surface_Capabilities,
	err: Error,
) {
	raw_caps: wgpu.Surface_Capabilities
	wgpu.surface_get_capabilities(ptr, adapter, &raw_caps)
	defer wgpu.surface_capabilities_free_members(raw_caps)

	if raw_caps.format_count == 0 &&
	   raw_caps.present_mode_count == 0 &&
	   raw_caps.alpha_mode_count == 0 {
		return
	}

	defer if err != nil {
		if len(caps.formats) > 0 do delete(caps.formats)
		if len(caps.alpha_modes) > 0 do delete(caps.alpha_modes)
		if len(caps.present_modes) > 0 do delete(caps.present_modes)
	}

	alloc_err: mem.Allocator_Error

	if raw_caps.format_count > 0 {
		formats_tmp := slice.from_ptr(raw_caps.formats, int(raw_caps.format_count))
		if caps.formats, alloc_err = make([]Texture_Format, raw_caps.format_count, allocator);
		   alloc_err != nil {
			err = alloc_err
			set_and_update_err_data(
				nil,
				.General,
				err,
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
			err = alloc_err
			set_and_update_err_data(
				nil,
				.General,
				err,
				"Failed to allocate present modes capabilities",
				loc,
			)
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
			err = alloc_err
			set_and_update_err_data(
				nil,
				.General,
				err,
				"Failed to allocate alpha modes capabilities",
				loc,
			)
			return
		}
		copy(caps.alpha_modes, alpha_modes_tmp)
	}

	return
}

surface_delete_capabilities :: proc(caps: ^Surface_Capabilities) {
	delete(caps.formats)
	delete(caps.present_modes)
	delete(caps.alpha_modes)
}

// Returns the next texture to be presented by the swapchain for drawing.
surface_get_current_texture :: proc(
	using self: ^Surface,
	loc := #caller_location,
) -> (
	surface_texture: Surface_Texture,
	err: Error,
) {
	set_and_reset_err_data(_err_data, loc)

	texture: wgpu.Surface_Texture
	wgpu.surface_get_current_texture(ptr, &texture)

	if err = get_last_error(); err != nil {
		if texture.texture != nil {
			wgpu.texture_release(texture.texture)
		}
		return
	}

	surface_texture = {
		texture = Texture {
			ptr = texture.texture,
			descriptor = {
				size = {config.width, config.height, 1},
				format = config.format,
				usage = config.usage,
				mip_level_count = 1,
				sample_count = 1,
				dimension = .D2,
			},
			_err_data = _err_data,
		},
		suboptimal = texture.suboptimal,
		status = texture.status,
	}

	return
}

// Returns the best format for the provided surface and adapter.
surface_get_preferred_format :: proc(
	using self: ^Surface,
	adapter: Raw_Adapter,
) -> Texture_Format {
	return wgpu.surface_get_preferred_format(ptr, adapter)
}

// Schedule this surface to be presented on the owning surface.
surface_present :: proc(using self: ^Surface) {
	wgpu.surface_present(ptr)
}

// Removes the surface configuration. Destroys any textures produced while configured.
surface_unconfigure :: proc(using self: ^Surface) {
	wgpu.surface_unconfigure(ptr)
}

// Return a default `Surface_Configuration` from `width` and `height` to use for the
// `Surface` with this adapter.
surface_get_default_config :: proc(
	self: ^Surface,
	adapter: Raw_Adapter,
	width, height: u32,
	loc := #caller_location,
) -> (
	config: Surface_Configuration,
	err: Error,
) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	caps := surface_get_capabilities(self, adapter, context.temp_allocator, loc) or_return

	config = {
		usage        = {.Render_Attachment},
		format       = caps.formats[0],
		width        = width,
		height       = height,
		present_mode = caps.present_modes[0],
	}

	return
}

// Increase the reference count.
surface_reference :: proc(using self: ^Surface) {
	wgpu.surface_reference(ptr)
}

// Release the `Surface`.
surface_release :: proc(using self: ^Surface) {
	wgpu.surface_release(ptr)
}

// Release the `Surface` and modify the raw pointer to `nil`.
surface_release_and_nil :: proc(using self: ^Surface) {
	if ptr == nil do return
	wgpu.surface_release(ptr)
	ptr = nil
}
