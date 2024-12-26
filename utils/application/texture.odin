#+vet !unused-imports
package application

// Packages
import "base:runtime"
import "core:fmt"
import "core:image"
import "core:image/png"
import "core:log"
import "core:math"
import "core:mem"
import "core:strings"

// Vendor
import stbi "vendor:stb/image"

// Local packages
import "./../../wgpu"

Texture :: struct {
	size:            wgpu.Extent3D,
	mip_level_count: u32,
	format:          wgpu.TextureFormat,
	dimension:       wgpu.TextureDimension,
	texture:         wgpu.Texture,
	view:            wgpu.TextureView,
	sampler:         wgpu.Sampler,
}

ColorSpace :: enum {
	Undefined,
	Srgb,
	Linear,
}

TextureLoadOptions :: struct {
	label:            string,
	flip_y:           bool,
	generate_mipmaps: bool,
	format:           wgpu.TextureFormat,
	usage:            wgpu.TextureUsages,
	address_mode:     wgpu.AddressMode,
	color_space:      ColorSpace,
}

TextureLoad :: struct {
	texture:         wgpu.Texture,
	width:           u32,
	height:          u32,
	depth:           u32,
	mip_level_count: u32,
	format:          wgpu.TextureFormat,
	dimension:       wgpu.TextureDimension,
}

ImageInfo :: struct {
	width, height: u32,
	channels:      int,
	depth:         int, // Channel depth in bits
	is_hdr:        bool,
}

ImageData :: struct {
	pixels:            []byte,
	bytes_per_channel: int,
	using info:        ImageInfo,
}

load_image_from_file :: proc(
	filename: string,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	out: ImageData,
	ok: bool,
) #optional_ok {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == context.temp_allocator)
	ta := context.temp_allocator

	img, img_err := image.load_from_file(filename, allocator = ta)
	if img_err == nil {
		out.width = u32(img.width)
		out.height = u32(img.height)
		out.channels = img.channels
		out.depth = img.depth

		pixels := wgpu.to_bytes(img.pixels)
		out.pixels = make([]byte, len(pixels), allocator)
		copy(out.pixels, pixels)

		return out, true
	}

	// Is this an unsupported format? If so, ignore the error to retry with stbi
	if img_err != .Unsupported_Format {
		log.errorf("Failed to load image [%v]: %s", img_err, filename)
		return
	}

	get_extension :: proc(filename: string) -> string {
		for i := len(filename) - 1; i >= 0; i -= 1 {
			if filename[i] == '.' {
				return filename[i:]
			}
		}
		return "unknown"
	}

	log.warnf(
		"Image package: unsupported format [%v], retrying with stb image...",
		get_extension(filename),
	)

	c_image_path := strings.clone_to_cstring(filename, ta)

	out.info = get_image_info_stbi(c_image_path, loc) or_return

	width, height, channels: i32
	raw_data := stbi.load(c_image_path, &width, &height, &channels, 0)
	out.bytes_per_channel = 1

	if raw_data == nil {
		wgpu.error_reset_and_update(
			.LoadImageFailed,
			fmt.tprintf("Failed to load image '%s': %s", filename, stbi.failure_reason()),
			loc,
		)
		return
	}

	out.width = u32(width)
	out.height = u32(height)
	out.channels = int(channels)

	// Determine bits per channel
	if out.info.is_hdr {
		out.depth = 32 // Assuming 32-bit float for HDR
	} else {
		out.depth = stbi.is_16_bit(c_image_path) ? 16 : 8
	}

	total_size := int(out.width * out.height * u32(out.channels))
	pixels := mem.slice_ptr(raw_data, total_size)
	out.pixels = make([]byte, total_size, allocator)
	copy(out.pixels, pixels)

	return out, true
}

LoadMethod :: enum {
	Default, // 8-bit channels
	Load_16,
	Load_F32,
}

image_info_determine_load_method :: proc(info: ImageInfo) -> LoadMethod {
	if info.is_hdr {
		return .Load_F32
	} else if info.depth == 16 {
		return .Load_16
	}
	return .Default
}

get_image_info_stbi :: proc(
	image_path: cstring,
	loc := #caller_location,
) -> (
	info: ImageInfo,
	ok: bool,
) #optional_ok {
	w, h, c: i32
	if stbi.info(image_path, &w, &h, &c) == 0 {
		runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
		wgpu.error_reset_and_update(
			.LoadImageFailed,
			fmt.tprintf(
				"Failed to get image info for '%s': %s",
				image_path,
				stbi.failure_reason(),
			),
			loc,
		)
		return
	}

	info.width, info.height, info.channels = u32(w), u32(h), int(c)
	info.is_hdr = stbi.is_hdr(image_path) != 0

	// Determine bits per channel
	if info.is_hdr {
		info.depth = 32 // Assuming 32-bit float for HDR
	} else {
		info.depth = stbi.is_16_bit(image_path) ? 16 : 8
	}

	return info, true
}

image_to_texture :: proc(
	queue: wgpu.Queue,
	texture: wgpu.Texture,
	data: []u8,
	size: wgpu.Extent3D,
	channels: u32,
) -> (
	ok: bool,
) {
	wgpu.queue_write_texture(
		queue,
		wgpu.texture_as_image_copy(texture),
		data,
		{
			offset = 0,
			bytes_per_row = size.width * channels * size_of(u8),
			rows_per_image = size.height,
		},
		size,
	) or_return

	return true
}

load_texture_from_file :: proc(
	filename: string,
	device: wgpu.Device,
	queue: wgpu.Queue,
	options: TextureLoadOptions = {},
	allocator := context.allocator,
) -> (
	ret: TextureLoad,
	ok: bool,
) #optional_ok {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == context.temp_allocator)
	img := load_image_from_file(filename, allocator) or_return

	width := u32(img.width)
	height := u32(img.height)

	mip_level_count: u32 = 1
	if options.generate_mipmaps {
		mip_level_count = calculate_mip_levels(width, height)
	}

	usage := options.usage
	if usage == {} {
		usage = {.CopyDst, .TextureBinding}
	}

	texture_size := wgpu.Extent3D {
		width                 = width,
		height                = height,
		depth_or_array_layers = 1,
	}

	format := options.format
	if format != .Undefined {
		format = texture_format_for_color_space(format, options.color_space)
	} else {
		format = .Rgba8Unorm
	}

	texture_descriptor := wgpu.TextureDescriptor {
		usage           = usage,
		dimension       = .D2,
		size            = texture_size,
		format          = format,
		mip_level_count = mip_level_count,
		sample_count    = 1,
	}

	texture := wgpu.device_create_texture(device, texture_descriptor) or_return
	defer if !ok {
		wgpu.release(texture)
	}

	// Convert image data if necessary
	image_data_convert(&img, true, context.temp_allocator) or_return

	image_to_texture(
		queue,
		texture,
		img.pixels,
		texture_descriptor.size,
		u32(img.channels),
	) or_return

	ret = {
		texture         = texture,
		width           = width,
		height          = height,
		depth           = texture_size.depth_or_array_layers,
		mip_level_count = mip_level_count,
		format          = format,
		dimension       = texture_descriptor.dimension,
	}

	return ret, true
}

calculate_mip_levels :: proc(#any_int width, height: int) -> u32 {
	max_dimension := u32(max(width, height))
	return u32(math.floor(math.log2(f64(max_dimension)))) + 1
}

create_texture :: proc(
	device: wgpu.Device,
	queue: wgpu.Queue,
	load: TextureLoad,
	options: TextureLoadOptions = {},
) -> (
	ret: Texture,
	ok: bool,
) #optional_ok {
	is_cubemap := load.depth == 6

	texture_view_descriptor := wgpu.TextureViewDescriptor {
		format            = load.format,
		dimension         = .Cube if is_cubemap else .D2,
		base_mip_level    = 0,
		mip_level_count   = load.mip_level_count,
		base_array_layer  = 0,
		array_layer_count = load.depth,
	}

	texture_view := wgpu.texture_create_view(load.texture, texture_view_descriptor) or_return
	defer if !ok {
		wgpu.release(texture_view)
	}

	is_size_power_of_2 :=
		math.is_power_of_two(int(load.width)) && math.is_power_of_two(int(load.height))

	mipmap_filter: wgpu.MipmapFilterMode =
		.Linear if is_size_power_of_2 && is_cubemap else .Nearest

	address_mode: wgpu.AddressMode =
		options.address_mode if options.address_mode != .Undefined else .ClampToEdge

	sampler_descriptor := wgpu.SamplerDescriptor {
		address_mode_u = address_mode,
		address_mode_v = address_mode,
		address_mode_w = address_mode,
		min_filter     = .Linear,
		mag_filter     = .Linear,
		mipmap_filter  = mipmap_filter,
		lod_min_clamp  = 0.0,
		lod_max_clamp  = f32(load.mip_level_count),
		max_anisotropy = 1,
	}

	sampler := wgpu.device_create_sampler(device, sampler_descriptor) or_return
	defer if !ok {
		wgpu.release(sampler)
	}

	ret = {
		size            = {load.width, load.height, load.depth},
		mip_level_count = load.mip_level_count,
		format          = load.format,
		dimension       = load.dimension,
		texture         = load.texture,
		view            = texture_view,
		sampler         = sampler,
	}

	return ret, true
}

create_texture_from_file :: proc(
	filename: string,
	device: wgpu.Device,
	queue: wgpu.Queue,
	options: TextureLoadOptions = {},
	allocator := context.allocator,
) -> (
	ret: Texture,
	ok: bool,
) #optional_ok {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == context.temp_allocator)
	load := load_texture_from_file(
		filename,
		device,
		queue,
		options,
		context.temp_allocator,
	) or_return
	defer if !ok {
		wgpu.release(load.texture)
	}
	return create_texture(device, queue, load, options)
}

texture_format_for_color_space :: proc "contextless" (
	format: wgpu.TextureFormat,
	color_space: ColorSpace,
) -> wgpu.TextureFormat {
	#partial switch color_space {
	case .Linear:
		return wgpu.texture_format_remove_srgb_suffix(format)
	case .Srgb:
		return wgpu.texture_format_add_srgb_suffix(format)
	case:
		return format
	}
}

create_cubemap_texture :: proc(
	device: wgpu.Device,
	queue: wgpu.Queue,
	image_paths: [6]string,
	options: TextureLoadOptions = {},
	loc := #caller_location,
) -> (
	out: Texture,
	ok: bool,
) #optional_ok {
	options := options

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	ta := context.temp_allocator

	// Get info of the first image
	first_img := load_image_from_file(image_paths[0], ta) or_return

	// Default texture usage if none is given
	if options.usage == {} {
		options.usage = {.TextureBinding, .CopyDst, .RenderAttachment}
	}

	// Determine the texture format based on the image info or use the preferred format
	format := options.format
	if format == .Undefined {
		format = image_info_texture_format(first_img.info)
	}

	// Create the cubemap texture
	texture_desc := wgpu.TextureDescriptor {
		label = options.label,
		size = {
			width = u32(first_img.width),
			height = u32(first_img.height),
			depth_or_array_layers = 6,
		},
		mip_level_count = 1,
		sample_count = 1,
		dimension = .D2,
		format = format,
		usage = options.usage,
	}
	out.texture = wgpu.device_create_texture(device, texture_desc) or_return
	defer if !ok {
		wgpu.release(out.texture)
	}

	// Calculate bytes per row, ensuring it meets the WGPU alignment requirements
	bytes_per_row := wgpu.texture_format_bytes_per_row(format, u32(first_img.width))

	image_properties_equal :: proc(img1, img2: ImageInfo) -> bool {
		if img1.width != img2.width {return false}
		if img1.height != img2.height {return false}
		if img1.channels != img2.channels {return false}
		if img1.depth != img2.depth {return false}
		return true
	}

	// Load and copy each face of the cubemap
	for i in 0 ..< 6 {
		// Check info of each face
		img := load_image_from_file(image_paths[i], ta) or_return

		if !image_properties_equal(img.info, first_img.info) {
			wgpu.error_reset_and_update(
				.Validation,
				fmt.tprintf("Cubemap face '%s' has different properties", image_paths[i]),
				loc,
			)
			return
		}

		// Copy the face image to the appropriate layer of the cubemap texture
		origin := wgpu.Origin3D{0, 0, u32(i)}

		// Prepare image data for upload
		image_copy_texture := wgpu.texture_as_image_copy(out.texture, origin)
		texture_data_layout := wgpu.TexelCopyBufferLayout {
			offset         = 0,
			bytes_per_row  = bytes_per_row,
			rows_per_image = u32(img.height),
		}

		// Convert image data if necessary
		image_data_convert(&img, true, ta) or_return

		wgpu.queue_write_texture(
			queue,
			image_copy_texture,
			img.pixels,
			texture_data_layout,
			{img.width, img.height, 1},
		) or_return
	}

	cube_view_descriptor := wgpu.TextureViewDescriptor {
		label             = "Cube Texture View",
		format            = wgpu.texture_format(out.texture), // Use the same format as the texture
		dimension         = .Cube,
		base_mip_level    = 0,
		mip_level_count   = 1, // Assume no mipmaps
		base_array_layer  = 0,
		array_layer_count = 6, // 6 faces of the cube
		aspect            = .All,
	}
	out.view = wgpu.texture_create_view(out.texture, cube_view_descriptor) or_return
	defer if !ok {
		wgpu.release(out.view)
	}

	// Create a sampler with linear filtering for smooth interpolation.
	sampler_descriptor := wgpu.SamplerDescriptor {
		address_mode_u = .Repeat,
		address_mode_v = .Repeat,
		address_mode_w = .Repeat,
		mag_filter     = .Linear,
		min_filter     = .Linear,
		mipmap_filter  = .Linear,
		lod_min_clamp  = 0.0,
		lod_max_clamp  = 1.0,
		compare        = .Undefined,
		max_anisotropy = 1,
	}

	out.sampler = wgpu.device_create_sampler(device, sampler_descriptor) or_return
	defer if !ok {
		wgpu.release(out.sampler)
	}

	return out, true
}

image_info_texture_format :: proc(info: ImageInfo) -> wgpu.TextureFormat {
	if info.is_hdr {
		switch info.channels {
		case 1:
			return .R32Float
		case 2:
			return .Rg32Float
		case 3, 4:
			return .Rgba32Float
		}
	} else if info.depth == 16 {
		switch info.channels {
		case 1:
			return .R16Uint
		case 2:
			return .Rg16Uint
		case 3, 4:
			return .Rgba16Uint
		}
	} else {
		switch info.channels {
		case 1:
			return .R8Unorm
		case 2:
			return .Rg8Unorm
		case 3, 4:
			return .Rgba8Unorm
		}
	}

	return .Rgba8Unorm // Default to RGBA8 if channels are unexpected
}

image_data_convert :: proc(
	img: ^ImageData,
	delete_old_pixels := true,
	allocator := context.allocator,
) -> (
	ok: bool,
) {
	RGB_CHANNELS :: 3
	RGBA_CHANNELS :: 4

	bytes_per_pixel := img.channels * img.bytes_per_channel

	new_pixels: []byte
	channels := img.channels

	// Convert RGB to RGBA
	if img.channels == RGB_CHANNELS {
		// Set the new channels
		channels = RGBA_CHANNELS

		new_bytes_per_pixel := RGBA_CHANNELS * img.bytes_per_channel
		dest_bytes_per_row := img.width * RGBA_CHANNELS
		new_pixels = make([]byte, int(dest_bytes_per_row * img.height), allocator)

		for y in 0 ..< img.height {
			for x in 0 ..< img.width {
				src_idx := int((y * img.width + x)) * bytes_per_pixel
				dst_idx := int(y * dest_bytes_per_row + x * u32(new_bytes_per_pixel))
				copy(new_pixels[dst_idx:], img.pixels[src_idx:src_idx + bytes_per_pixel])
				new_pixels[dst_idx + 3] = 255 // Full alpha for 8-bit
			}
		}
	}

	if len(new_pixels) > 0 {
		if delete_old_pixels {
			delete(img.pixels, allocator)
		}
		img.pixels = new_pixels
		img.channels = channels
	}

	return true
}

texture_release :: proc(self: Texture) {
	wgpu.release(self.sampler)
	wgpu.release(self.view)
	wgpu.release(self.texture)
}
