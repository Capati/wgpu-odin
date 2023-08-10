package wgpu

// Package
import wgpu "../bindings"

Swap_Chain :: struct {
    ptr:          WGPU_Swap_Chain,
    err_scope: ^Error_Scope,
    using vtable: ^Swap_Chain_VTable,
}

@(private)
Swap_Chain_VTable :: struct {
    get_current_texture_view: proc(self: ^Swap_Chain) -> (Texture_View, Error_Type),
    present:                  proc(self: ^Swap_Chain),
    reference:                proc(self: ^Swap_Chain),
    release:                  proc(self: ^Swap_Chain),
}

@(private)
default_swap_chain_vtable := Swap_Chain_VTable {
    get_current_texture_view = swap_chain_get_current_texture_view,
    present                  = swap_chain_present,
    reference                = swap_chain_reference,
    release                  = swap_chain_release,
}

@(private)
default_swap_chain := Swap_Chain {
    ptr    = nil,
    vtable = &default_swap_chain_vtable,
}

swap_chain_get_current_texture_view :: proc(
    using self: ^Swap_Chain,
) -> (
    Texture_View,
    Error_Type,
) {
    err_scope.info = #procedure

    texture_view_ptr := wgpu.swap_chain_get_current_texture_view(ptr)

    if err_scope.type != .No_Error {
        if texture_view_ptr != nil {
            wgpu.texture_view_release(texture_view_ptr)
        }
        return {}, err_scope.type
    }

    texture_view := default_texture_view
    texture_view.ptr = texture_view_ptr

    return texture_view, .No_Error
}

swap_chain_present :: proc(using self: ^Swap_Chain) {
    wgpu.swap_chain_present(ptr)
}

swap_chain_reference :: proc(using self: ^Swap_Chain) {
    wgpu.swap_chain_reference(ptr)
}

swap_chain_release :: proc(using self: ^Swap_Chain) {
    wgpu.swap_chain_release(ptr)
}
