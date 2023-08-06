package wgpu

// Core
import "core:fmt"

// Package
// import wgpu "../bindings"

// Surface texture that can be rendered to. Result of a successful call to
// `surface->get_current_texture`.
Surface_Texture :: struct {
    chain:        Swap_Chain,
    view:         Texture_View,
    presented:    bool,
    using vtable: ^Surface_Texture_VTable,
}

@(private)
Surface_Texture_VTable :: struct {
    present: proc(self: ^Surface_Texture),
    release: proc(self: ^Surface_Texture),
}

@(private)
default_surface_texture_vtable := Surface_Texture_VTable {
    present = surface_texture_present,
    release = surface_texture_release,
}

@(private)
default_surface_texture := Surface_Texture {
    vtable = &default_surface_texture_vtable,
}

// Schedule this texture to be presented on the owning surface.
@(private)
surface_texture_present :: proc(using self: ^Surface_Texture) {
    if presented {
        fmt.print("WARNING: Surface texture already presented! Ignoring...\n")
        return
    }

    presented = true

    // At the end of the main loop, once the texture is filled in and the view released,
    // we can tell the swap chain to present the next texture (which depends on the
    // presentMode of the swap chain)
    chain->present()

    // The texture view is used only for a single frame, after which it is our
    // responsibility to destroy it:
    self->release()
}

@(private)
surface_texture_release :: proc(using self: ^Surface_Texture) {
    view->release()
}
