package tutorial5_textures_texture

// Core
import "core:bytes"
import "core:fmt"
import "core:image/png"

// Package
import wgpu "../../../../../wrapper"

Texture :: struct {
    handle:  wgpu.Texture,
    view:    wgpu.Texture_View,
    sampler: wgpu.Sampler,
}

texture_from_image :: proc(
    device: ^wgpu.Device,
    path: cstring,
) -> (
    texture: Texture,
    err: wgpu.Error_Type,
) {
    image, image_err := png.load_from_file(string(path))
    if image_err != nil {
        fmt.eprintf("ERROR when loading texture: %v\n", image_err)
        return {}, .Internal
    }
    defer png.destroy(image)

    size := wgpu.Extent_3D {
        width                 = cast(u32)image.width,
        height                = cast(u32)image.height,
        depth_or_array_layers = 1,
    }

    handle := device->create_texture(
        &wgpu.Texture_Descriptor{
            label = path,
            size = size,
            mip_level_count = 1,
            sample_count = 1,
            dimension = .D2,
            format = .Rgba8_Unorm_Srgb,
            usage = {.Texture_Binding, .Copy_Dst},
        },
    ) or_return
    defer if err != .No_Error do handle->release()

    device.queue->write_texture(
        &wgpu.Image_Copy_Texture{
            texture = &handle,
            mip_level = 0,
            origin = {},
            aspect = .All,
        },
        bytes.buffer_to_bytes(&image.pixels),
        &wgpu.Texture_Data_Layout{
            offset = 0,
            bytes_per_row = 4 * cast(u32)image.width,
            rows_per_image = cast(u32)image.height,
        },
        &size,
    ) or_return


    view := handle->create_view(nil) or_return
    defer if err != .No_Error do view->release()

    sampler_descriptor := wgpu.Default_Sampler_Descriptor
    sampler_descriptor.mag_filter = .Linear
    sampler := device->create_sampler(&sampler_descriptor) or_return
    defer if err != .No_Error do sampler->release()

    texture = {handle, view, sampler}

    return
}

texture_destroy :: proc(texture: ^Texture) {
    texture.sampler->release()
    texture.view->release()
    texture.handle->release()
}
