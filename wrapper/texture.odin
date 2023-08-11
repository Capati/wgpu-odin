package wgpu

// Package
import wgpu "../bindings"

Texture :: struct {
    ptr:          WGPU_Texture,
    err_scope:    ^Error_Scope,
    using vtable: ^Texture_VTable,
}

@(private)
Texture_VTable :: struct {
    create_view:               proc(
        self: ^Texture,
        descriptor: ^Texture_View_Descriptor,
    ) -> (
        Texture_View,
        Error_Type,
    ),
    destroy:                   proc(self: ^Texture),
    get_depth_or_array_layers: proc(self: ^Texture) -> u32,
    get_dimension:             proc(self: ^Texture) -> Texture_Dimension,
    get_format:                proc(self: ^Texture) -> Texture_Format,
    get_height:                proc(self: ^Texture) -> u32,
    get_mip_level_count:       proc(self: ^Texture) -> u32,
    get_sample_count:          proc(self: ^Texture) -> u32,
    get_usage:                 proc(self: ^Texture) -> Texture_Usage,
    get_width:                 proc(self: ^Texture) -> u32,
    set_label:                 proc(self: ^Texture, label: cstring),
    reference:                 proc(self: ^Texture),
    release:                   proc(self: ^Texture),
}

@(private)
default_texture_vtable := Texture_VTable {
    create_view               = texture_create_view,
    destroy                   = texture_destroy,
    get_depth_or_array_layers = texture_get_depth_or_array_layers,
    get_dimension             = texture_get_dimension,
    get_format                = texture_get_format,
    get_height                = texture_get_height,
    get_mip_level_count       = texture_get_mip_level_count,
    get_sample_count          = texture_get_sample_count,
    get_usage                 = texture_get_usage,
    get_width                 = texture_get_width,
    set_label                 = texture_set_label,
    reference                 = texture_reference,
    release                   = texture_release,
}

@(private)
default_texture := Texture {
    ptr    = nil,
    vtable = &default_texture_vtable,
}

// Creates a view of this texture.
texture_create_view :: proc(
    using texture: ^Texture,
    descriptor: ^Texture_View_Descriptor,
) -> (
    Texture_View,
    Error_Type,
) {
    err_scope.type = .No_Error

    texture_view_ptr := wgpu.texture_create_view(ptr, descriptor)

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

// Destroy the associated native resources as soon as possible.
texture_destroy :: proc(using texture: ^Texture) {
    wgpu.texture_destroy(ptr)
}

// Returns the depth or layer count of this `Texture`.
texture_get_depth_or_array_layers :: proc(using texture: ^Texture) -> u32 {
    return wgpu.texture_get_depth_or_array_layers(ptr)
}

// Returns the dimension of this `Texture`.
texture_get_dimension :: proc(using texture: ^Texture) -> Texture_Dimension {
    return wgpu.texture_get_dimension(ptr)
}

// Returns the format of this `Texture`.
texture_get_format :: proc(using texture: ^Texture) -> Texture_Format {
    return wgpu.texture_get_format(ptr)
}

// Returns the height of this `Texture`.
texture_get_height :: proc(using texture: ^Texture) -> u32 {
    return wgpu.texture_get_height(ptr)
}

// Returns the `mip_level_count` of this `Texture`.
texture_get_mip_level_count :: proc(using texture: ^Texture) -> u32 {
    return wgpu.texture_get_mip_level_count(ptr)
}

// Returns the sample_count of this `Texture`.
texture_get_sample_count :: proc(using texture: ^Texture) -> u32 {
    return wgpu.texture_get_sample_count(ptr)
}

// Returns the allowed usages of this `Texture`.
texture_get_usage :: proc(using texture: ^Texture) -> Texture_Usage {
    return wgpu.texture_get_usage(ptr)
}

// Returns the width of this `Texture`.
texture_get_width :: proc(using texture: ^Texture) -> u32 {
    return wgpu.texture_get_width(ptr)
}

// Set a debug label for this `Texture`.
texture_set_label :: proc(using texture: ^Texture, label: cstring) {
    wgpu.texture_set_label(ptr, label)
}

texture_reference :: proc(using texture: ^Texture) {
    wgpu.texture_reference(ptr)
}

// Release the `Texture`.
texture_release :: proc(using texture: ^Texture) {
    wgpu.texture_release(ptr)
}
