package tutorial5_textures_texture

// Package
import wgpu "../../../../../wrapper"

Texture_Data :: struct {
	handle:  wgpu.Texture,
	view:    wgpu.Texture_View,
	sampler: wgpu.Sampler,
}

texture_from_image :: proc(
	device: wgpu.Device,
	queue: wgpu.Queue,
	path: string,
) -> (
	texture: Texture_Data,
	err: wgpu.Error,
) {
	texture.handle = wgpu.queue_copy_image_to_texture(
		device,
		queue,
		path,
		{label = path},
	) or_return
	defer if err != nil do wgpu.texture_release(texture.handle)

	texture.view = wgpu.texture_create_view(texture.handle) or_return
	defer if err != nil do wgpu.texture_view_release(texture.view)

	sampler_descriptor := wgpu.DEFAULT_SAMPLER_DESCRIPTOR
	sampler_descriptor.mag_filter = .Linear
	texture.sampler = wgpu.device_create_sampler(device, sampler_descriptor) or_return

	return
}

texture_destroy :: proc(texture: Texture_Data) {
	wgpu.sampler_release(texture.sampler)
	wgpu.texture_view_release(texture.view)
	wgpu.texture_release(texture.handle)
}
