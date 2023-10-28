package wgpu

import wgpu "../bindings"

Surface_Texture :: struct {
    texture:      Texture,
    suboptimal:   bool,
    status:       wgpu.Surface_Get_Current_Texture_Status,
    using vtable: ^Surface_Texture_VTable,
}

@(private)
Surface_Texture_VTable :: struct {
    release: proc(self: ^Surface_Texture),
}

@(private)
default_surface_texture_vtable := Surface_Texture_VTable {
    release = surface_texture_release,
}

@(private)
default_surface_texture := Surface_Texture {
    vtable = &default_surface_texture_vtable,
}

surface_texture_release :: proc(using self: ^Surface_Texture) {
    texture->release()
}
