package wgpu

// Core
import "core:mem"
import "core:runtime"
import "core:slice"

// Package
import wgpu "../bindings"

// Handle to a presentable surface.
Surface :: struct {
    ptr:          WGPU_Surface,
    config:       Surface_Configuration,
    err_data:     ^Error_Data,
    using vtable: ^Surface_VTable,
}

@(private)
Surface_VTable :: struct {
    configure:            proc(
        self: ^Surface,
        device: ^Device,
        config: ^Surface_Configuration,
    ) -> Error_Type,
    get_capabilities:     proc(
        self: ^Surface,
        adapter: Adapter,
        allocator: mem.Allocator = context.allocator,
    ) -> (
        Surface_Capabilities,
        Error_Type,
    ),
    get_current_texture:  proc(self: ^Surface) -> (Surface_Texture, Error_Type),
    get_preferred_format: proc(self: ^Surface, adapter: ^Adapter) -> Texture_Format,
    present:              proc(self: ^Surface),
    unconfigure:          proc(self: ^Surface),
    get_default_config:   proc(
        self: ^Surface,
        adapter: Adapter,
        width, height: u32,
    ) -> (
        Surface_Configuration,
        Error_Type,
    ),
    reference:            proc(self: ^Surface),
    release:              proc(self: ^Surface),
}

default_surface_vtable := Surface_VTable {
    configure            = surface_configure,
    get_capabilities     = surface_get_capabilities,
    get_current_texture  = surface_get_current_texture,
    get_preferred_format = surface_get_preferred_format,
    present              = surface_present,
    unconfigure          = surface_unconfigure,
    get_default_config   = surface_get_default_config,
    reference            = surface_reference,
    release              = surface_release,
}

default_surface := Surface {
    ptr    = nil,
    vtable = &default_surface_vtable,
}

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

    device.err_data.type = .No_Error

    wgpu.surface_configure(self.ptr, &cfg)

    if device.err_data.type != .No_Error {
        return device.err_data.type
    }

    self.err_data = device.err_data

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
    adapter: Adapter,
    allocator := context.allocator,
) -> (
    Surface_Capabilities,
    Error_Type,
) {
    caps: wgpu.Surface_Capabilities = {}
    wgpu.surface_get_capabilities(ptr, adapter.ptr, &caps)

    if caps.format_count == 0 &&
       caps.present_mode_count == 0 &&
       caps.alpha_mode_count == 0 {
        update_error_message("No compatible capabilities found with the given adapter")
        return {}, .Unknown
    }

    runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

    if caps.format_count > 0 {
        caps.formats =
        cast(^Texture_Format)(mem.alloc(
                cast(int)caps.format_count * size_of(Texture_Format),
                allocator = context.temp_allocator,
            ) or_else nil)

        if caps.formats == nil {
            update_error_message("Failed to allocate memory for formats array")
            return {}, .Out_Of_Memory
        }
    }

    if caps.present_mode_count > 0 {
        caps.present_modes =
        cast(^Present_Mode)(mem.alloc(
                cast(int)caps.present_mode_count * size_of(Present_Mode),
                allocator = context.temp_allocator,
            ) or_else nil)

        if caps.present_modes == nil {
            update_error_message("Failed to allocate memory for present modes array")
            return {}, .Out_Of_Memory
        }
    }

    if caps.alpha_mode_count > 0 {
        caps.alpha_modes =
        cast(^Composite_Alpha_Mode)(mem.alloc(
                cast(int)caps.alpha_mode_count * size_of(Composite_Alpha_Mode),
                allocator = context.temp_allocator,
            ) or_else nil)

        if caps.alpha_modes == nil {
            update_error_message("Failed to allocate memory for alpha modes array")
            return {}, .Out_Of_Memory
        }
    }

    wgpu.surface_get_capabilities(ptr, adapter.ptr, &caps)

    ret := Surface_Capabilities{}

    if caps.format_count > 0 {
        formats_tmp := slice.from_ptr(caps.formats, int(caps.format_count))
        ret.formats = make([]Texture_Format, caps.format_count, allocator)
        copy(ret.formats, formats_tmp)
    }

    if caps.present_mode_count > 0 {
        present_modes_tmp := slice.from_ptr(
            caps.present_modes,
            int(caps.present_mode_count),
        )
        ret.present_modes = make([]Present_Mode, caps.present_mode_count, allocator)
        copy(ret.present_modes, present_modes_tmp)
    }

    if caps.alpha_mode_count > 0 {
        alpha_modes_tmp := slice.from_ptr(caps.alpha_modes, int(caps.alpha_mode_count))
        ret.alpha_modes = make([]Composite_Alpha_Mode, caps.alpha_mode_count, allocator)
        copy(ret.alpha_modes, alpha_modes_tmp)
    }

    return ret, .No_Error
}

// Returns the next texture to be presented by the swapchain for drawing.
surface_get_current_texture :: proc(
    using self: ^Surface,
) -> (
    surface_texture: Surface_Texture,
    err: Error_Type,
) {
    err_data.type = .No_Error

    texture: wgpu.Surface_Texture
    wgpu.surface_get_current_texture(ptr, &texture)

    if err_data.type != .No_Error {
        wgpu.texture_release(texture.texture)
        return {}, err_data.type
    }

    tex := default_texture
    tex.ptr = texture.texture
    tex.descriptor = {
        size = {config.width, config.height, 1},
        format = config.format,
        usage = config.usage,
        mip_level_count = 1,
        sample_count = 1,
        dimension = .D2,
    }
    tex.err_data = err_data
    surface_texture = {
        texture    = tex,
        suboptimal = texture.suboptimal,
        status     = texture.status,
        vtable     = &default_surface_texture,
    }

    return surface_texture, .No_Error
}

// Returns the best format for the provided surface and adapter.
surface_get_preferred_format :: proc(
    using self: ^Surface,
    adapter: ^Adapter,
) -> Texture_Format {
    return wgpu.surface_get_preferred_format(ptr, adapter.ptr)
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
    adapter: Adapter,
    width, height: u32,
) -> (
    config: Surface_Configuration,
    err: Error_Type,
) {
    caps := self->get_capabilities(adapter) or_return

    defer {
        delete(caps.formats)
        delete(caps.present_modes)
        delete(caps.alpha_modes)
    }

    config = {
        usage = {.Render_Attachment},
        format = caps.formats[0],
        width = width,
        height = height,
        present_mode = caps.present_modes[0],
    }

    return
}

surface_reference :: proc(using self: ^Surface) {
    wgpu.surface_reference(ptr)
}

// Release the surface and swapchain.
surface_release :: proc(using self: ^Surface) {
    wgpu.surface_release(ptr)
}
