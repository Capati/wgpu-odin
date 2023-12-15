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
	queue: ^wgpu.Queue,
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

	handle := wgpu.device_create_texture(
		device,
		&wgpu.Texture_Descriptor {
			label = path,
			size = size,
			mip_level_count = 1,
			sample_count = 1,
			dimension = .D2,
			format = .Rgba8_Unorm_Srgb,
			usage = {.Texture_Binding, .Copy_Dst},
		},
	) or_return
	defer if err != .No_Error do wgpu.texture_release(&handle)

	wgpu.queue_write_texture(
		queue,
		&wgpu.Image_Copy_Texture{texture = &handle, mip_level = 0, origin = {}, aspect = .All},
		wgpu.to_bytes(&image.pixels),
		&wgpu.Texture_Data_Layout {
			offset = 0,
			bytes_per_row = 4 * cast(u32)image.width,
			rows_per_image = cast(u32)image.height,
		},
		&size,
	) or_return

	view := wgpu.texture_create_view(&handle, nil) or_return
	defer if err != .No_Error do wgpu.texture_view_release(&view)

	sampler_descriptor := wgpu.Default_Sampler_Descriptor
	sampler_descriptor.mag_filter = .Linear
	sampler := wgpu.device_create_sampler(device, &sampler_descriptor) or_return
	defer if err != .No_Error do wgpu.sampler_release(&sampler)

	texture = {handle, view, sampler}

	return
}

texture_destroy :: proc(texture: ^Texture) {
	wgpu.sampler_release(&texture.sampler)
	wgpu.texture_view_release(&texture.view)
	wgpu.texture_release(&texture.handle)
}
