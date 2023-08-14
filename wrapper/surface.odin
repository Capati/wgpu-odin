package wgpu

// Core
import "core:mem"

// Package
import wgpu "../bindings"

// Handle to a presentable surface.
Surface :: struct {
    ptr:          WGPU_Surface,
    using vtable: ^Surface_VTable,
}

@(private)
Surface_VTable :: struct {
    get_preferred_format: proc(self: ^Surface, adapter: ^Adapter) -> Texture_Format,
    get_capabilities:     proc(
        self: ^Surface,
        adapter: Adapter,
        allocator: mem.Allocator = context.allocator,
    ) -> (
        Surface_Capabilities,
        Error_Type,
    ),
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
    get_preferred_format = surface_get_preferred_format,
    get_capabilities     = surface_get_capabilities,
    get_default_config   = surface_get_default_config,
    reference            = surface_reference,
    release              = surface_release,
}

default_surface := Surface {
    ptr    = nil,
    vtable = &default_surface_vtable,
}

// Returns the best format for the provided surface and adapter.
surface_get_preferred_format :: proc(
    using self: ^Surface,
    adapter: ^Adapter,
) -> Texture_Format {
    return wgpu.surface_get_preferred_format(ptr, adapter.ptr)
}

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

    if caps.format_count > 0 {
        formats, formats_alloc_err := mem.alloc(
            cast(int)caps.format_count * size_of(Texture_Format),
            allocator = allocator,
        )

        if formats_alloc_err != .None {
            update_error_message("Failed to allocate memory for formats array")
            if formats_alloc_err == .Out_Of_Memory {
                return {}, .Out_Of_Memory
            }
            return {}, .Internal
        }

        caps.formats = transmute(^Texture_Format)formats
    }

    if caps.present_mode_count > 0 {
        present_modes, present_modes_alloc_err := mem.alloc(
            cast(int)caps.present_mode_count * size_of(Present_Mode),
            allocator = allocator,
        )

        if present_modes_alloc_err != .None {
            update_error_message("Failed to allocate memory for present modes array")
            if present_modes_alloc_err == .Out_Of_Memory {
                return {}, .Out_Of_Memory
            }
            return {}, .Internal
        }

        caps.present_modes = transmute(^Present_Mode)present_modes
    }

    if caps.alpha_mode_count > 0 {
        alpha_modes, alpha_modes_alloc_err := mem.alloc(
            cast(int)caps.alpha_mode_count * size_of(Composite_Alpha_Mode),
            allocator = allocator,
        )

        if alpha_modes_alloc_err != .None {
            update_error_message("Failed to allocate memory for alpha modes array")
            if alpha_modes_alloc_err == .Out_Of_Memory {
                return {}, .Out_Of_Memory
            }
            return {}, .Internal
        }

        caps.alpha_modes = transmute(^Composite_Alpha_Mode)alpha_modes
    }

    wgpu.surface_get_capabilities(ptr, adapter.ptr, &caps)

    ret := Surface_Capabilities{}

    if caps.format_count > 0 {
        ret.formats = caps.formats[:caps.format_count]
    }

    if caps.alpha_mode_count > 0 {
        ret.alpha_modes = caps.alpha_modes[:caps.alpha_mode_count]
    }

    if caps.present_mode_count > 0 {
        ret.present_modes = caps.present_modes[:caps.present_mode_count]
    }

    return ret, .No_Error
}

Get_Current_Texture_Error :: enum {
    No_Error,
    Failed_To_Acquire_Current_Texture,
}

// Return a default `Surface_Configuration` from `width` and `height` to use for the
// `Surface` with this adapter.
surface_get_default_config :: proc(
    using self: ^Surface,
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
        label = "Default SwapChain",
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
