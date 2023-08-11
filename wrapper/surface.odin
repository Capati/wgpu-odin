package wgpu

// Core
import "core:fmt"
import "core:mem"
// import "core:runtime"

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
    ) -> Surface_Capabilities,
    get_default_config:   proc(
        self: ^Surface,
        adapter: Adapter,
        width, height: u32,
    ) -> Surface_Configuration,
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
) -> Surface_Capabilities {
    caps: wgpu.Surface_Capabilities = {}
    wgpu.surface_get_capabilities(ptr, adapter.ptr, &caps)

    if caps.format_count == 0 &&
       caps.present_mode_count == 0 &&
       caps.alpha_mode_count == 0 {
        return {}
    }

    if caps.format_count > 0 {
        formats, formats_alloc_err := mem.alloc(
            cast(int)caps.format_count * size_of(Texture_Format),
            allocator = allocator,
        )

        if formats_alloc_err != .None {
            fmt.panicf(
                "Failed to allocate memory for formats array: [%v]\n",
                formats_alloc_err,
            )
        }

        caps.formats = transmute(^Texture_Format)formats
    }

    if caps.present_mode_count > 0 {
        present_modes, present_modes_alloc_err := mem.alloc(
            cast(int)caps.present_mode_count * size_of(Present_Mode),
            allocator = allocator,
        )

        if present_modes_alloc_err != .None {
            fmt.panicf(
                "Failed to allocate memory for present modes array: [%v]\n",
                present_modes_alloc_err,
            )
        }

        caps.present_modes = transmute(^Present_Mode)present_modes
    }

    if caps.alpha_mode_count > 0 {
        alpha_modes, alpha_modes_alloc_err := mem.alloc(
            cast(int)caps.alpha_mode_count * size_of(Composite_Alpha_Mode),
            allocator = allocator,
        )

        if alpha_modes_alloc_err != .None {
            fmt.panicf(
                "Failed to allocate memory for alpha modes array: [%v]\n",
                alpha_modes_alloc_err,
            )
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

    return ret
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
) -> Surface_Configuration {
    caps := self->get_capabilities(adapter)

    defer {
        delete(caps.formats)
        delete(caps.present_modes)
        delete(caps.alpha_modes)
    }

    default_config: Surface_Configuration = {
        label = "Default SwapChain",
        usage = {.Render_Attachment},
        format = caps.formats[0],
        width = width,
        height = height,
        present_mode = caps.present_modes[0],
    }

    return default_config
}

surface_reference :: proc(using self: ^Surface) {
    wgpu.surface_reference(ptr)
}

// Release the surface and swapchain.
surface_release :: proc(using self: ^Surface) {
    wgpu.surface_release(ptr)
}

// @(private)
// _handle_current_texture_error :: proc "c" (
//     type: Error_Type,
//     message: cstring,
//     user_data: rawptr,
// ) {
//     if type == .No_Error {
//         return
//     }

//     context = runtime.default_context()

//     fmt.eprintf("Failed to get current texture [%v]: %s\n", type, message)

//     error := cast(^Get_Current_Texture_Error)user_data
//     error^ = .Failed_To_Acquire_Current_Texture
// }
